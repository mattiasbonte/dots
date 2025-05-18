# --------------------------------------- #
# NNN https://github.com/jarun/nnn#readme #
# --------------------------------------- #
nnn_no_cd() {
    nnn
}

nnn_cd_on_quit() {
    if [[ "${NNNLVL:-0}" -ge 1 ]]; then
        echo "nnn is already running"
        return
    fi

    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    \nnn "$@"

    if [ -f "$NNN_TMPFILE" ]; then
            . "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
    fi
}
# alias e="nnn_cd_on_quit"
# alias ls="nnn_cd_on_quit -d"

nnn_with_sudo_edit(){
    sudo -E nnn
}
alias E=nnn_with_sudo_edit
alias eso=nnn_with_sudo_edit


# ls picker
els() {
	ls -alh $(nnn -iaAQH -p -)
}

# Preview Tui
ep(){
	nnn -aAQH -P p
}

# Preview Tabbed
eP(){
	nnn -aAQH -P P
}

# Preview simple (no dependencies)
es () {
    # Block nesting of nnn in subshells
    if [ -n "$NNNLVL" ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to see.
    # To cd on quit only on ^G, remove the "export" and set NNN_TMPFILE *exactly* as this:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # This will create a fifo where all nnn selections will be written to
    NNN_FIFO="$(mktemp --suffix=-nnn -u)"
    export NNN_FIFO
    (umask 077; mkfifo "$NNN_FIFO")

    # Preview command
    preview_cmd="$HOME/.config/nnn/scripts/preview_cmd.sh"

    # Use `tmux` split as preview
    if [ -e "${TMUX%%,*}" ]; then
        tmux split-window -e "NNN_FIFO=$NNN_FIFO" -dh "$preview_cmd"

    # Use `xterm` as a preview window
    elif (which xterm &> /dev/null); then
        xterm -e "$preview_cmd" &

    # Unable to find a program to use as a preview window
    else
        echo "unable to open preview, please install tmux or xterm"
    fi

    nnn -iaAQ "$@"

    rm -f "$NNN_FIFO"
}
