#!/usr/bin/env bash
# Arch x86_64, run as an ordinary user with sudo.
set -euo pipefail
cd -- "$(dirname -- "$0")"
root=$PWD
mode=install
dev=0
autologin=0
profile=auto
deploy_flags=()
for arg in "$@"; do
    case "$arg" in
        --plan) mode=plan ;;
        --check) mode=check ;;
        --dev) dev=1 ;;
        --autologin) autologin=1 ;;
        --replace-config) deploy_flags+=(--replace) ;;
        --vmware) profile=vmware ;;
        --generic) profile=generic ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done
if [[ $profile == auto ]]; then
    if [[ $(systemd-detect-virt --vm 2>/dev/null || true) == vmware ]]; then profile=vmware; else profile=generic; fi
fi
if [[ $profile == vmware ]]; then deploy_flags+=(--vmware); fi
mapfile -t official < packages/arch.txt
mapfile -t extra < packages/extra-sources.txt
if (( dev )); then mapfile -t more < packages/dev.txt; official+=("${more[@]}"); fi
if [[ $mode == plan ]]; then
    printf 'Profile: %s; dev: %s; Ly autologin: %s\nOfficial: %s\nRepository or AUR: paru %s\n' "$profile" "$dev" "$autologin" "${official[*]}" "${extra[*]}"
    echo 'Deploy .config, .local, .vim, shell dotfiles, wallpaper and lockscreen colors; enable NetworkManager, sshd and Ly for next boot.'
    if command -v python3 >/dev/null; then
        python3 "$root/deploy.py" --plan "${deploy_flags[@]}"
    else
        # A fresh Arch Base clone may not have Python until the package step.
        echo 'Files relative to the home directory:'
        find .config .local .vim -type f | LC_ALL=C sort
        printf '%s\n' .bashrc .vimrc 'Pictures/Wallpapers (initial wallpaper)' '.cache/.current_wallpaper' '.cache/matugen/hypr/colors.conf'
        if [[ $profile == vmware ]]; then echo '.config/niri/output.kdl (VMware)'; fi
    fi
    echo 'Set Toronto timezone, en_US.UTF-8, GTK theme/fonts and Fish as login shell; no automatic reboot.'
    exit 0
fi
check() {
    local cfg=$1
    niri validate --config "$cfg/niri/config.kdl"
    fish -n "$cfg/fish/config.fish"
    for f in "$cfg"/fish/{functions,conf.d}/*.fish; do fish -n "$f"; done
    [[ -r /usr/share/wayland-sessions/niri.desktop && -s /usr/share/rime-data/rime_ice.schema.yaml && -s /usr/share/rime-data/double_pinyin_flypy.schema.yaml ]]
    fish -c 'functions -q f; and functions -q ff; and functions -q fwatch' || return 1
    [[ -x $HOME/.local/bin/clipboard-menu && -x $HOME/.local/bin/sysup ]]
    [[ $(fc-match -f '%{family[0]}' 'monospace:lang=en:charset=0041') == FiraCode* ]]
    [[ $(fc-match -f '%{family[0]}' 'sans-serif:lang=zh-cn:charset=4e2d') == *CJK* ]]
}
if [[ $mode == check ]]; then
    pacman -Q -- "${official[@]}" "${extra[@]}" paru >/dev/null
    check "$HOME/.config"
    echo 'Installed configuration OK.'
    exit 0
fi
[[ $EUID != 0 && -f /etc/arch-release && $(uname -m) == x86_64 ]] || { echo 'Use a normal user on Arch x86_64.' >&2; exit 1; }
sudo -v
sudo pacman -Syu --needed -- "${official[@]}"
if ! command -v paru >/dev/null; then
    if pacman -Si paru >/dev/null 2>&1; then sudo pacman -S --needed paru
    else
        build=$(mktemp -d)
        trap 'rm -rf -- "$build"' EXIT
        git clone https://aur.archlinux.org/paru.git "$build/paru"
        (cd "$build/paru" && makepkg -si --needed)
    fi
fi
# Install the selected compositor before nirius resolves its "niri" dependency.
paru -S --needed -- "${extra[0]}"
paru -S --needed -- "${extra[@]:1}"
niri validate --config "$root/.config/niri/config.kdl"
python3 "$root/deploy.py" "${deploy_flags[@]}"
check "$HOME/.config"
sudo timedatectl set-timezone America/Toronto
if ! locale -a | grep -Fxi 'en_US.utf8' >/dev/null; then
    sudo sed -i -E 's/^#[[:space:]]*(en_US\.UTF-8 UTF-8)[[:space:]]*$/\1/' /etc/locale.gen
    sudo locale-gen
fi
sudo localectl set-locale LANG=en_US.UTF-8
if [[ $(getent passwd "$(id -un)" | cut -d: -f7) != /usr/bin/fish ]]; then sudo usermod -s /usr/bin/fish "$(id -un)"; fi
for setting in 'gtk-theme:adw-gtk3-dark' 'cursor-theme:Adwaita' 'font-name:FiraCode Nerd Font 11' 'document-font-name:FiraCode Nerd Font 11' 'monospace-font-name:FiraCode Nerd Font Mono 11'; do
    dbus-run-session -- gsettings set org.gnome.desktop.interface "${setting%%:*}" "${setting#*:}"
done
# Materialize first-login icon colors from the bundled seed; subsequent wallpapers use Matugen.
dbus-run-session -- bash "$root/seeds/recoloricons.sh"
sudo systemctl enable NetworkManager.service sshd.service ly@tty1.service
if (( autologin )); then
    for key in auto_login_user auto_login_session; do grep -Eq "^$key[[:space:]]*=" /etc/ly/config.ini || { echo "Unsupported Ly config: $key"; exit 1; }; done
    sudo cp --no-clobber /etc/ly/config.ini /etc/ly/config.ini.before-dotfiles
    sudo sed -i -E -e "s/^auto_login_user[[:space:]]*=.*/auto_login_user = $(id -un)/" -e 's/^auto_login_session[[:space:]]*=.*/auto_login_session = niri/' /etc/ly/config.ini
fi
echo 'Ready for the next boot. In Ly select Niri.'
