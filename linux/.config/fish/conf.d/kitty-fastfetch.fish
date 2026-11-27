# Display Shorin image fastfetch once per local Kitty window.
if status is-interactive; and set -q KITTY_WINDOW_ID; and not set -q SSH_TTY
    set -l window "$KITTY_PID:$KITTY_WINDOW_ID"
    if not contains -- "$window" $EXPLDFSH_FF_WINDOW; and type -q f
        set -gx EXPLDFSH_FF_WINDOW "$window"
        f
    end
end
