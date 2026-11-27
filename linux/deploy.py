"""Install the Linux home-directory overlay (regular files only)."""
import argparse
import datetime
import filecmp
import os
import shutil
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parent
home = Path.home().resolve()
wall_name = "FCD2D539E2FA1A71D3E156BE3D2E4DE1-Picsart-AiImageEnhancer.png"

def mapping(vmware):
    for folder in (".config", ".local", ".vim"):
        for path in sorted((root / folder).rglob("*")):
            if path.is_file():
                yield path, home / path.relative_to(root)
    for name in (".bashrc", ".vimrc"):
        yield root / name, home / name
    if vmware:
        yield root / "profiles/vmware/output.kdl", home / ".config/niri/output.kdl"
    yield root.parent / "wallpaper" / wall_name, home / "Pictures/Wallpapers" / wall_name
    yield root / "seeds/hyprlock-colors.conf", home / ".cache/matugen/hypr/colors.conf"

def install(vmware, replace):
    backup = None
    copied = same = 0
    skipped = []
    for src, dst in mapping(vmware):
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
            print(f"{src.relative_to(root.parent)} -> ~/{dst.relative_to(home)}")
        print("Current wallpaper link -> ~/.cache/.current_wallpaper (if missing)")
    else:
        install(args.vmware, args.replace)
