# Arch / Niri

面向已安装、可联网的 x86_64 Arch。请在新的 `Arch Base` 完整克隆里以有 sudo 权限的普通用户执行。基础系统负责 EFI、GRUB 和 ext4。克隆的主机名、SSH 身份和 GitHub 登录由机器所有者单独配置。

从仓库根目录运行：

```bash
bash linux/install.sh --plan --dev
bash linux/install.sh --dev
bash linux/install.sh --check --dev
```

`--dev` 增加编译和调试工具。VMware 自动选择 `profiles/vmware/output.kdl`，为 Virtual-1 指定 1080p。其他机器使用 Niri 的输出自动探测，也可显式选择 `--generic` 或 `--vmware`。开机进入 tty1 的 Ly，选 Niri 并输入普通用户密码。安装器会关闭已有的 Ly 自动登录设置，并保留修改前的 config.ini。安装脚本需要交互式 sudo；AUR 软件按 paru 的正常流程审阅、构建。脚本不自动重启。

## 文件与重跑行为

`.config/`、`.local/`、`.vim/` 及 `.bashrc`、`.vimrc`、`.gtkrc-2.0`按用户家目录结构存放。`deploy.py` 复制文件，让 Matugen 能在家目录生成配色，仓库工作树不会因此变脏。默认部署缺失文件，列出并保留已存在且内容不同的文件。`--replace-config` 会先把冲突的普通文件备份到 `~/.local/state/dotfiles-backups/` 再覆盖；自定义软链接会保留并报告。安装器还会设置多伦多时区、系统英文和桌面中文 UTF-8 locale、GTK 字体和主题、Fish 登录 shell，以及下次启动的 NetworkManager、sshd 和 Ly。已有系统请先用 `--plan` 阅读范围。

17 张轮换壁纸按 `seeds/wallpapers.txt` 从仓库根目录 `wallpaper/` 部署。初次登录后 Waypaper 按现有桌面的规则随机选图。Waypaper 调用 awww 设置桌面和总览背景，随后通过 `.config/scripts/` 和 Matugen 为 Waybar、Niri、GTK、Fcitx5、Fuzzel、Mako、Cava、Yazi 等着色。`seeds/` 包含初始锁屏色和图标重绘脚本。Niri 使用 Breeze 光标。GTK 应用沿用 Adwaita 光标；深浅色主题、文件图标、Thunar 的图标视图和缩略图均随桌面部署。Fuzzel 的隐藏清单只应用于已安装的桌面入口，保留对应版本的启动命令和 MIME 信息。Kitty 保留独立主题。本地 Kitty 显示 `f`，SSH 登录显示 `ff`。剪贴板使用 Fuzzel、cliphist 和 wl-clipboard。

## 软件来源

- `packages/arch.txt`：基础桌面、字体、输入法、终端和编辑器。直接依赖显式列出，库由 pacman 解析。
- `packages/extra-sources.txt`：首先安装 Shorin 的 Niri 分支，再安装 nirius、Waypaper 和两项 Rime 数据。已配置的软件源优先，其他包由 AUR 提供。没有可用的 paru 时，从已配仓库或官方 AUR 的 paru 仓库引导安装。无需添加 Shorin 软件源。
- `packages/expldfsh-lolcat/PKGBUILD` 固定 [expldfsh/lolcat 的源码提交](https://github.com/expldfsh/lolcat/tree/f32fcbb0b0361a88fe350bfd0939871b6c8ae71e)，校验 SHA-256 后只编译 `lolcat`。安装到 `/usr/bin/lolcat`，归本地包 `expldfsh-lolcat` 管理。构建使用临时目录，退出时清理。更新此固定版本后可单独运行 `bash linux/install-lolcat.sh`；在已有机器上，pacman 会提示处理与官方 Ruby 版的冲突。验证用 `lolcat --version`，末尾应显示 `patched by expldfsh`。若系统已有同名手动安装，使用 `type -a lolcat` 查看命令优先级。
- `packages/dev.txt`：Clang、CMake、Ninja、Rust、GDB、Node.js、Tree-sitter 等开发工具。Neovim 首次使用时由 lazy.nvim 下载插件；经典 Vim 带有 vim-plug，使用 `:PlugInstall` 安装 .vimrc 中选择的插件。VimTeX 的 Sioyek 和 TeX 工具链按使用需要另装。
- 配置和包清单不含 SSH 身份、令牌、Rime 词频、浏览器用户资料、历史记录或图片缓存。

## 日常维护

| 命令 | 作用 |
| --- | --- |
| `sysup --check` | 运行 checkupdates、paru 查询和已安装 Flatpak 的用户级及系统级查询。显示版本和分阶段结果。 |
| `sysup` | 先执行完整仓库升级 `sudo pacman -Syu`，再以普通用户执行 `paru -Sua --devel`；存在 Flatpak 时分别更新两个范围的应用和运行时。保留原生命令的提示、构建输出和确认。 |
| `sysup --news`、`sysup --no-flatpak` | 前者只看 Arch 公告，后者在本次升级中跳过 Flatpak。 |
| `clean --dry-run`、`clean` | 预览或清理。paccache 每个包保留最近三个缓存版本，可用 `--keep N` 更改。列出孤包；如已安装 Flatpak，由其识别并清理未使用的运行时。预览中列出的已装运行时可能仍在使用。 |
| `clean --orphans`、`clean --journal` | 前者由 pacman 显示待删包并确认，后者额外清理 14 天前的归档日志。日常模式保留开发缓存和项目。 |
| `mirror-update --dry-run`、`mirror-update` | 用 Reflector 对 24 小时内同步的 HTTPS 镜像测速，默认加拿大和美国。预览只打印；正式写入前在 /etc/pacman.d 下备份旧清单并输出路径，再原子替换。支持 `--country CA` 和 `--worldwide`。 |

仓库事务失败时 sysup 停止升级。AUR 构建失败会标出失败阶段、继续独立的 Flatpak 更新，最终返回非零。更新、清理和选源可从 Waybar 的维护菜单打开。选择安装 checkallupdates 后，菜单会多出查看更新的入口。Flatpak 按需自行安装，后续 sysup 和 clean 会自动识别。

## 常用和按需小工具

默认部署三个 Shorin 通用工具。`preview` 在终端预览文件或目录，也接到了 Thunar 右键菜单；`procusage` 查看进程或应用的资源占用；`timer` 倒计时或设置提醒。桌面同时提供 `matugen-update` 重新生成配色和 `niri-display-settings` 调整显示器。

在完成桌面安装后，可从仓库根目录按名称追加工具。例如只安装软件包降级和媒体信息功能：

```bash
python3 linux/tools.py --list
python3 linux/tools.py --plan pacd media-info
python3 linux/tools.py pacd media-info
```

| 可选命令 | 作用 |
| --- | --- |
| `pacd` | 出现回归时交互降级软件包，按需安装 downgrade |
| `lsi` | 在终端以网格看一批图片，按需安装 timg |
| `checkallupdates` | 用 fzf 浏览仓库、AUR 和 Flatpak 更新，回车可运行 sysup |
| `media-info`、`compressvideos`、`video2gif` | 查看媒体信息、压缩视频、把视频转成 GIF；复用 FFmpeg |
| `getown` | 获取指定文件或目录的所有权 |
| `change-grub-theme` | 手动切换引导菜单主题 |

可选脚本存放在 `optional-tools/`。安装器只处理点名的脚本及其缺失依赖；适用的 Thunar 右键项在选择后追加，并在合并前备份原菜单。日常虚拟机配置已排除电池阈值、AI 模型查询、KVM 管理和 Btrfs 存读档。

## 来源与验收

桌面布局、主题模板以及部分 Fish 和桌面脚本源自 [Shorin Niri](https://github.com/SHORiN-KiWATA/shorin-niri)，发行时的本机软件包版本为 `shorin-niri-git r262.85fc245-1`；布局对照的合成器为 `niri-shorin-fork-git 26.04.r493.g4109fc7-1`。安装器使用软件源当时提供的版本。GTK 主题来自 [adw-gtk3](https://github.com/lassekongo83/adw-gtk3)，见 `licenses/`；vim-plug 和 Neovim 配置保留其内含声明。第三方壁纸和资源保留各自的权利归属。

在 Shorin 项目中，只有 `niri-shorin-fork-git` 被安装为软件包并由包管理器更新。桌面配置和本地工具由本仓库维护。通用工具来自 [shorin-contrib 的固定版本](https://github.com/SHORiN-KiWATA/shorin-contrib/tree/bae65b88dc9e7d36a5eefce422a33fa877bf997f)，软件包元数据标为 GPL3，随附文本见 `licenses/shorin-contrib-GPL-3.0.txt`。`checkallupdates` 接入本地 sysup；sysup、clean 和 mirror-update 为本仓库实现。显示设置界面来自 [niri-display-settings](https://github.com/SHORiN-KiWATA/niri-display-settings/tree/5f76b3f)，只部署 Python 源码、桌面入口和图标，MIT 许可见 `licenses/niri-display-settings-MIT`。独立复制的工具随 dotfiles 提交更新。

这里复现当前正在使用的 Niri 桌面。备用 Win11 顶栏、截录屏、AI、护眼和 Btrfs 项目按已选范围排除。输入法使用 Arch 官方 Fcitx5 搭配迁移的 Rime 方案和主题。GPU 渲染器由 mpv 自动选择。

在新的克隆首次登录后，检查网格总览、Super+T、SSH 登录、换壁纸后顶栏与图标变色、剪贴板、两个 Rime 拼音方案、音量和锁屏。静态校验无法替代这次图形会话测试。
