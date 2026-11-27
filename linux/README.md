# Arch / Niri

面向已安装、可联网的 x86_64 Arch。请在新的 `Arch Base` 完整克隆里以有 sudo 权限的普通用户执行。基础系统负责 EFI、GRUB 和 ext4。克隆的主机名、SSH 身份和 GitHub 登录由机器所有者单独配置。

从仓库根目录运行：

```bash
bash linux/install.sh --plan --dev
bash linux/install.sh --dev
bash linux/install.sh --check --dev
```

`--dev` 增加编译和调试工具。VMware 自动选择 `profiles/vmware/output.kdl`，为 Virtual-1 指定 1080p。其他机器使用 Niri 的输出自动探测，也可显式选择 `--generic` 或 `--vmware`。Ly 默认显示登录界面，`--autologin` 在下一次启动时自动进入当前用户的 Niri 会话。安装脚本需要交互式 sudo；AUR 软件按 paru 的正常流程审阅、构建。脚本不自动重启。

## 文件与重跑行为

`.config/`、`.local/`、`.vim/` 和两个 shell/editor 点文件按用户家目录结构存放。`deploy.py` 复制文件，让 Matugen 能在家目录生成配色，仓库工作树不会因此变脏。默认部署缺失文件，列出并保留已存在且内容不同的文件。`--replace-config` 会先把冲突的普通文件备份到 `~/.local/state/dotfiles-backups/` 再覆盖；自定义软链接会保留并报告。安装器还会设置多伦多时区、英文 UTF-8 locale、GTK 字体和主题、Fish 登录 shell，以及下次启动的 NetworkManager、sshd 和 Ly。已有系统请先用 `--plan` 阅读范围。

默认壁纸复用仓库根目录 `wallpaper/` 中的图片。Waypaper 调用 awww 设置桌面和总览背景，随后通过 `.config/scripts/` 和 Matugen 为 Waybar、Niri、GTK、Fcitx5、Fuzzel、Mako、Cava、Yazi 等着色。`seeds/` 包含初始锁屏色和图标重绘脚本。Kitty 保留独立主题。本地 Kitty 显示 `f`，SSH 登录显示 `ff`。剪贴板使用 Fuzzel、cliphist 和 wl-clipboard；`sysup` 调用 paru 更新仓库包和 AUR 包。

## 软件来源

- `packages/arch.txt`：基础桌面、字体、输入法、终端和编辑器。直接依赖显式列出，库由 pacman 解析。
- `packages/extra-sources.txt`：首先安装 Shorin 的 Niri 分支，再安装 nirius、Waypaper 和两项 Rime 数据。已配置的软件源优先，其他包由 AUR 提供。没有可用的 paru 时，从已配仓库或官方 AUR 的 paru 仓库引导安装。无需添加 Shorin 软件源。
- `packages/dev.txt`：Clang、CMake、Ninja、Rust、GDB、Node.js、Tree-sitter 等开发工具。Neovim 首次使用时由 lazy.nvim 下载插件；经典 Vim 带有 vim-plug，使用 `:PlugInstall` 安装 .vimrc 中选择的插件。VimTeX 的 Sioyek 和 TeX 工具链按使用需要另装。
- 配置和包清单不含 SSH 身份、令牌、Rime 词频、浏览器用户资料、历史记录或图片缓存。

## 来源与验收

桌面布局、主题模板以及部分 Fish 和桌面脚本源自 [Shorin Niri](https://github.com/SHORiN-KiWATA/shorin-niri)，发行时的本机软件包版本为 `shorin-niri-git r262.85fc245-1`；布局对照的合成器为 `niri-shorin-fork-git 26.04.r493.g4109fc7-1`。安装器使用软件源当时提供的版本。GTK 主题来自 [adw-gtk3](https://github.com/lassekongo83/adw-gtk3)，见 `licenses/`；vim-plug 和 Neovim 配置保留其内含声明。第三方壁纸和资源保留各自的权利归属。

在新的克隆首次登录后，检查网格总览、Super+T、SSH 登录、换壁纸后顶栏与图标变色、剪贴板、两个 Rime 拼音方案、音量和锁屏。静态校验无法替代这次图形会话测试。
