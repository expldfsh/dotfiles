"""Install the Linux home-directory overlay (regular files only)."""
import argparse
import datetime
import filecmp
import os
import re
import shutil
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parent
home = Path.home().resolve()
wall_name = "FCD2D539E2FA1A71D3E156BE3D2E4DE1-Picsart-AiImageEnhancer.png"

system_apps = Path("/usr/share/applications")


def mapping(vmware):
    for folder in (".config", ".local", ".vim"):
        for path in sorted((root / folder).rglob("*")):
            if path.is_file():
                yield path, home / path.relative_to(root)
    for name in (".bashrc", ".vimrc", ".gtkrc-2.0"):
        yield root / name, home / name
    if vmware:
        yield root / "profiles/vmware/output.kdl", home / ".config/niri/output.kdl"
    for name in (root / "seeds/wallpapers.txt").read_text().splitlines():
        yield root.parent / "wallpaper" / name, home / "Pictures/Wallpapers" / name
    for name in (root / "seeds/hidden-launchers.txt").read_text().splitlines():
        source = system_apps / name
        if source.is_file():
            yield source, home / ".local/share/applications" / name
    yield root / "seeds/hyprlock-colors.conf", home / ".cache/matugen/hypr/colors.conf"

def hide_from_launcher(source, workdir):
    desktop = source.read_text()
    section = re.search(r"(?ms)^\[Desktop Entry\][^\n]*\n(.*?)(?=^\[|\Z)", desktop)
    if section is None:
        raise ValueError(f"Missing Desktop Entry: {source}")
    body = re.sub(r"(?m)^NoDisplay=[^\n]*\n?", "", section[1])
    text = desktop[:section.start(1)] + "NoDisplay=true\n" + body + desktop[section.end(1):]
    generated = workdir / source.name
    generated.write_text(text)
    return generated


def thunar_menu(source, names, workdir):
    original = source.read_bytes()
    tree = ET.fromstring(original)
    if tree.tag != "actions":
        raise ValueError(f"Unexpected Thunar menu: {source}")
    known = {action.findtext("unique-id") for action in tree.findall("action")}
    additions = []
    for name in sorted(set(names)):
        fragment = root / "optional-tools/thunar" / (name + ".xml")
        if fragment.is_file():
            action = ET.parse(fragment).getroot()
            if action.findtext("unique-id") not in known:
                additions.append(ET.tostring(action, encoding="utf-8").strip())
    if not additions:
        return source
    # Append to the existing XML so the user's actions, comments and order survive.
    head, close, tail = original.rpartition(b"</actions>")
    if not close:
        if not list(tree) and tree.tag == "actions":
            head, close, tail = b"<actions>", b"</actions>", b"\\n"
        else:
            raise ValueError(f"Cannot append to Thunar menu: {source}")
    path = workdir / "thunar-with-tools.xml"
    path.write_bytes(head.rstrip() + b"\\n" + b"\\n".join(additions) + b"\\n" + close + tail)
    shutil.copymode(source, path)
    return path


def install_files(pairs, replace, workdir):
    backup = None
    copied = same = 0
    skipped = []
    for src, dst in pairs:
        if src == root / ".config/Thunar/uca.xml":
            names = [f.stem for f in (root / "optional-tools/thunar").glob("*.xml")
                     if os.access(home / ".local/bin" / f.stem, os.X_OK)]
            src = thunar_menu(src, names, workdir)
        if src.parent == system_apps:
            src = hide_from_launcher(src, workdir)
        if not src.is_file() or src.is_symlink():
            raise ValueError(f"Unexpected source: {src}")
        if dst.parent.resolve() != dst.parent or dst.is_symlink() or (dst.exists() and not dst.is_file()):
            skipped.append(dst)
            continue
        if dst.exists():
            if filecmp.cmp(src, dst, shallow=False) and os.access(src, os.X_OK) == os.access(dst, os.X_OK):
                same += 1
                continue
            if not replace:
                skipped.append(dst)
                continue
            if backup is None:
                state = home / ".local/state/dotfiles-backups"
                state.mkdir(parents=True, exist_ok=True)
                backup = Path(tempfile.mkdtemp(prefix=datetime.date.today().isoformat()+"-", dir=state))
                print("Backup:", backup)
            original = backup / dst.relative_to(home)
            original.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(dst, original)
        dst.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(prefix=".dotfiles-", dir=dst.parent)
        os.close(fd)
        try:
            shutil.copy2(src, tmp)
            os.replace(tmp, dst)
        finally:
            Path(tmp).unlink(missing_ok=True)
        copied += 1
    print(f"Installed {copied}, identical {same}, kept {len(skipped)} existing paths")
    for dst in skipped:
        print("Kept:", dst)
    

def install(vmware, replace, workdir):
    install_files(mapping(vmware), replace, workdir)
    wallpaper_link = home / ".cache/.current_wallpaper"
    if not os.path.lexists(wallpaper_link):
        wallpaper_link.symlink_to(home / "Pictures/Wallpapers" / wall_name)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vmware", action="store_true")
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--plan", action="store_true")
    args = parser.parse_args()
    if args.plan:
        for src, dst in mapping(args.vmware):
            label = src.relative_to(root.parent) if src.is_relative_to(root.parent) else f"{src} (NoDisplay)"
            print(f"{label} -> ~/{dst.relative_to(home)}")
        print("Current wallpaper link -> ~/.cache/.current_wallpaper (if missing)")
    else:
        with tempfile.TemporaryDirectory(prefix="dotfiles-launchers-") as work:
            install(args.vmware, args.replace, Path(work))
