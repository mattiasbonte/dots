# ------------------------------------------ #
# LAZYTOOLS https://github.com/jesseduffield #
# ------------------------------------------ #
launch_lazygit() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

    lazygit --use-config-file=$HOME/.config/lazygit/config.yml,$HOME/.config/lazygit/themes/tokyonight/night.yml "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
        cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
        rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}
alias lazygit=launch_lazygit
alias lz=launch_lazygit
alias lg=launch_lazygit

# ctrl-g | esc-ctrl-g
zle     -N            launch_lazygit
bindkey -M emacs '^g' launch_lazygit
bindkey -M vicmd '^g' launch_lazygit
bindkey -M viins '^g' launch_lazygit
bindkey -M emacs '\e^g' launch_lazygit
bindkey -M vicmd '\e^g' launch_lazygit
bindkey -M viins '\e^g' launch_lazygit

launch_lazydocker() { lazydocker }
alias lzd=launch_lazydocker
alias ld=launch_lazydocker
zle     -N            launch_lazydocker
# bindkey -M emacs '\ed' launch_lazydocker
# bindkey -M vicmd '\ed' launch_lazydocker
# bindkey -M viins '\ed' launch_lazydocker

launch_lazysql() { lazysql }
alias lzs=launch_lazysql
alias lzq=launch_lazysql
