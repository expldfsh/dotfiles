set fish_greeting ""
fish_add_path ~/.local/bin
set -gx EDITOR nvim
set -gx VISUAL nvim

if status is-interactive
    starship init fish | source
    bind \el forward-char
end
zoxide init fish --cmd cd | source

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function cat --wraps bat
	command bat --theme="base16" $argv
end

function ls --wraps eza
	command eza --icons=auto $argv
end

function lt --wraps eza
	command eza --icons=auto --tree $argv
end

function la --wraps eza
	command eza -la --icons=auto $argv
end

# grub
abbr grub 'LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 sudo grub-mkconfig -o /boot/grub/grub.cfg'
# fa运行fastfetch
abbr fa fastfetch
abbr reboot 'systemctl reboot'
function sl 
	command sl | lolcat	
end
function 滚
	sysup 
end
function raw
	command ~/.config/scripts/random-anime-wallpaper.sh $argv
end
