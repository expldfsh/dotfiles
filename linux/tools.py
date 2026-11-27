#!/usr/bin/env python3
"""Install individual optional tools after the Arch desktop is set up."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
import deploy

# Tool name, official packages, extra packages, description.
tools = {
    "checkallupdates": (["fzf", "pacman-contrib"], [], "用 fzf 浏览更新，回车可启动 sysup"),
    "pacd": (["fzf"], ["downgrade"], "交互选择要降级的软件包"),
    "lsi": ([], ["timg"], "在终端并排浏览多张图片"),
    "media-info": (["ffmpeg"], [], "查看编码、分辨率和音轨"),
    "compressvideos": (["ffmpeg"], [], "批量压缩现有视频"),
    "video2gif": (["ffmpeg"], [], "把视频片段转为 GIF"),
    "getown": (["sudo"], [], "取得指定文件或目录的所有权"),
    "change-grub-theme": (["grub", "git"], [], "手动切换 GRUB 启动菜单主题"),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="列出所有可选命令")
    parser.add_argument("--plan", action="store_true", help="只显示所选工具与依赖")
    parser.add_argument("--replace-config", action="store_true", help="备份并替换冲突的普通文件")
    parser.add_argument("names", nargs="*", metavar="TOOL")
    args = parser.parse_args()
    if args.list or not args.names:
        for name, (native, extra, description) in tools.items():
            print(f"{name:<19} {description}  [{', '.join(native + extra)}]")
        return
    names = list(dict.fromkeys(args.names))
    unknown = set(names) - tools.keys()
    if unknown:
        parser.error("未知工具：" + ", ".join(sorted(unknown)))

    native = sorted({p for n in names for p in tools[n][0]})
    extra = sorted({p for n in names for p in tools[n][1]})
    sources = deploy.root / "optional-tools"
    pairs = [(sources / "bin" / name, deploy.home / ".local/bin" / name) for name in names]
    actions = [name for name in names if (sources / "thunar" / (name + ".xml")).is_file()]
    print("所选命令：" + "、".join(names))
    print("官方包：" + (", ".join(native) or "无"))
    print("额外来源：" + (", ".join(extra) or "无"))
    if actions:
        print("Thunar 右键入口：" + ", ".join(actions))
    if args.plan:
        return
    if os.geteuid() == 0 or not Path("/etc/arch-release").is_file():
        parser.exit(1, "请在完成桌面安装后，以 Arch 普通用户运行。\n")

    def missing(packages):
        return [p for p in packages if subprocess.run(
            ["pacman", "-Q", "--", p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        ).returncode != 0]

    native, extra = missing(native), missing(extra)
    if extra:
        if not shutil.which("paru"):
            parser.exit(1, "所选工具需要 paru，请先完成 linux/install.sh。\n")
        subprocess.run(["paru", "-Syu", "--needed", "--", *native, *extra], check=True)
    elif native:
        subprocess.run(["sudo", "pacman", "-Syu", "--needed", "--", *native], check=True)

    with tempfile.TemporaryDirectory(prefix="dotfiles-tools-") as directory:
        work = Path(directory)
        deploy.install_files(pairs, args.replace_config, work)
        available = [dest.name for _, dest in pairs if os.access(dest, os.X_OK)]
        if not set(actions).intersection(available):
            return
        menu = deploy.home / ".config/Thunar/uca.xml"
        if menu.parent.resolve() != menu.parent or menu.is_symlink() or (menu.exists() and not menu.is_file()):
            print("保留自定义 Thunar 路径：" + str(menu))
            return
        source = menu if menu.exists() else deploy.root / ".config/Thunar/uca.xml"
        merged = deploy.thunar_menu(source, available, work)
        if merged != source:
            # Only the new action IDs were appended. Preserve a backup of the original menu.
            deploy.install_files([(merged, menu)], True, work)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
