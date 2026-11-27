#!/usr/bin/env bash
set -euo pipefail

declare -a labels=() commands=()
add() {
    labels+=("$1")
    commands+=("$2")
}

for tool in sysup checkallupdates clean mirror-update; do
    [[ -x $HOME/.local/bin/$tool ]] || continue
    case $tool in
        sysup) title='更新系统' ;;
        checkallupdates) title='查看待更新软件' ;;
        clean) title='系统清理' ;;
        mirror-update) title='更新镜像源' ;;
    esac
    add "$title ($tool)" "$HOME/.local/bin/$tool"
done

if systemctl is-active --quiet NetworkManager; then
    if command -v impala >/dev/null && systemctl is-active --quiet iwd; then
        add '联网工具 (impala)' impala
    elif command -v nmtui >/dev/null; then
        add '联网工具 (nmtui)' nmtui
    fi
fi
(("${#labels[@]}")) || exit 0
# fuzzel returns the selected line's zero-based index.
index=$(printf '%s\n' "${labels[@]}" | fuzzel --dmenu --index -p '维护 > ') || exit 0
[[ $index =~ ^[0-9]+$ ]] && (( index < ${#commands[@]} )) || exit 0
exec kitty --single-instance --class command-center --title "${labels[index]}" \
    bash -c '"$1"; result=$?; printf "\n按任意键退出…"; read -rsn 1; exit "$result"' _ "${commands[index]}"
