#  ________ ________ ________       ______   ______  __    __ ________ ______  ______
# |        \        \        \     /      \ /      \|  \  |  \        \      \/      \
# | ▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓    |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓\ | ▓▓ ▓▓▓▓▓▓▓▓\▓▓▓▓▓▓  ▓▓▓▓▓▓\
# | ▓▓__       /  ▓▓| ▓▓__        | ▓▓   \▓▓ ▓▓  | ▓▓ ▓▓▓\| ▓▓ ▓▓__     | ▓▓ | ▓▓ __\▓▓
# | ▓▓  \     /  ▓▓ | ▓▓  \       | ▓▓     | ▓▓  | ▓▓ ▓▓▓▓\ ▓▓ ▓▓  \    | ▓▓ | ▓▓|    \
# | ▓▓▓▓▓    /  ▓▓  | ▓▓▓▓▓       | ▓▓   __| ▓▓  | ▓▓ ▓▓\▓▓ ▓▓ ▓▓▓▓▓    | ▓▓ | ▓▓ \▓▓▓▓
# | ▓▓      /  ▓▓___| ▓▓          | ▓▓__/  \ ▓▓__/ ▓▓ ▓▓ \▓▓▓▓ ▓▓      _| ▓▓_| ▓▓__| ▓▓
# | ▓▓     |  ▓▓    \ ▓▓           \▓▓    ▓▓\▓▓    ▓▓ ▓▓  \▓▓▓ ▓▓     |   ▓▓ \\▓▓    ▓▓
#  \▓▓      \▓▓▓▓▓▓▓▓\▓▓            \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓      \▓▓▓▓▓▓ \▓▓▓▓▓▓ 

# ------------------------------------------------- #
# SETTINGS https://github.com/junegunn/fzf#settings #
# ------------------------------------------------- #

# INFO: reason for the split it so that the theme switcher can be used

# ---------------------------------------------------------------- #
# VARS: https://github.com/junegunn/fzf/blob/master/man/man1/fzf.1 #
# ---------------------------------------------------------------- #
other_default_opts="
\--border
\--margin=1
\--reverse
\--info=inline
\--height 100%
\--preview-window=hidden
\--bind ctrl-h:toggle-preview
\--bind ctrl-u:preview-half-page-up
\--bind ctrl-d:preview-half-page-down
\--bind ctrl-l:clear-query
\--bind ctrl-t:toggle-preview-wrap
\--bind ctrl-s:toggle-sort
"
# \--color=fg:#e0def4,hl:#eb6f92,fg+:#f6c177,bg+:#191724,hl+:#eb6f92,info:#9ccfd8,prompt:#f6c177,pointer:#c4a7e7,marker:#ebbcba,spinner:#eb6f92,header:#ebbcba
# \--preview-window=hidden:wrap:down:50%

export FZF_DEFAULT_OPTS="$other_default_opts"

# find hidden files and folders and ignore node_modules and .git
# https://github.com/junegunn/fzf/issues/337 INFO: wft still havent figured it out how to find hidden files lol
# export FZF_DEFAULT_COMMAND="rg --files --follow --no-ignore-vcs --hidden -g '!{**/node_modules/*,**/.git/*}'"


# ------------------------------------------------------------------- #
# FZF-TAB-CONFIG https://github.com/Aloxaf/fzf-tab/wiki/Configuration #
# ------------------------------------------------------------------- #
# use tmux popup instead of fzf
# zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# INFO: this should be 4 when --border is active, otherwise 2 is enough
zstyle ':fzf-tab:complete:*' fzf-pad 4

# Trigger keys, "/" to continue, "Enter" cd into selection, "Space" to confirm.
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' fzf-bindings 'space:accept'
zstyle ':fzf-tab:*' accept-line enter

# Preview
zstyle ':fzf-tab:complete:*' fzf-preview 'exa -1 --color=always --icons $realpath'
# zstyle ':fzf-tab:complete:*' fzf-preview 'exa -1 --color=always --icons --header --long $realpath'
