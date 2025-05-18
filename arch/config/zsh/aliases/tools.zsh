#  ________  ______   ______  __        ______
# |        \/      \ /      \|  \      /      \
#  \▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓     |  ▓▓▓▓▓▓\
#    | ▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓     | ▓▓___\▓▓
#    | ▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓      \▓▓    \
#    | ▓▓  | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓      _\▓▓▓▓▓▓\
#    | ▓▓  | ▓▓__/ ▓▓ ▓▓__/ ▓▓ ▓▓_____|  \__| ▓▓
#    | ▓▓   \▓▓    ▓▓\▓▓    ▓▓ ▓▓     \\▓▓    ▓▓
#     \▓▓    \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓ \▓▓▓▓▓▓ 

# ---------------------- #
# SNIPS https://snips.sh #
# ---------------------- #
open_ssh_snips(){
    ssh snips.sh
}
alias sn=open_ssh_snips
alias snip=open_ssh_snips


# ----------------------- #
# SENDIT http://sendit.sh #
# ----------------------- #
send_files(){
    ssh sendit.zip < $*
}
alias send="send_files"


# ------------------------------------------ #
# MODS https://github.com/charmbracelet/mods #
# ------------------------------------------ #
mods_improve_code(){
    mods -f "what are your thoughts on improving this code?" < $1  | glow
}
alias mimp="mods_improve_code"
alias mimprove="mods_improve_code"

mods_answer_in_glow(){
    mods "$*" | glow
}
alias mchat="mods_answer_in_glow"


# --------------------------------------- #
# EXA https://github.com/ogham/exa#readme #
# --------------------------------------- #
L()  { exa --icons $* }
Lt() { exa --icons --tree --level=$* }
Ll() { exa --icons --header --long --group --git }
La() { exa --icons --header --long --group --git --sort=name --all }


# ---- #
# TMUX #
# ---- #
run_cmd_in_all_tmux_panes() {
	tmux run "tmux list-panes -a -F '##{session_name}:##{window_index}.##{pane_index}' | xargs -I PANE tmux send-keys -t PANE '$*' ENTER" 
}


# ------------------------------------- #
# h-m-m https://github.com/nadrad/h-m-m #
# ------------------------------------- #
hacker_mind_map() {
    h-m-m $*
}
alias hmm="hacker_mind_map"
alias mm="hacker_mind_map"

# -------------------------------------------------------- #
# GO SPOTIFY CLI https://github.com/Envoy49/go-spotify-cli #
# -------------------------------------------------------- #
go_spotify_cli() {
    go-spotify-cli $*
}
spotify_volume_limit() {
    local volume=$1
    if [[ $volume -gt 30 ]]; then
        echo "Volume limited to 30%"
        go-spotify-cli volume -v 30
    else
        go-spotify-cli volume -v $volume
    fi
}
alias spt=go_spotify_cli

alias S=go_spotify_cli
alias Svol="go-spotify-cli volume -v "
alias Snext="go-spotify-cli next"
alias Sprev="go-spotify-cli previous"
alias Splay="go-spotify-cli play"
alias Spause="go-spotify-cli pause"
alias Ssaved="go-spotify-cli saved"
alias Sdevice="go-spotify-cli device"

alias s=go_spotify_cli
alias s0="go-spotify-cli pause"
alias s1="go-spotify-cli play"
alias sn="go-spotify-cli next"
alias sp="go-spotify-cli previous"
alias sv="spotify_volume_limit"
alias ss="go-spotify-cli saved"



# ----- #
# OTHER #
# ----- #
alias lines=tokei # TOKEI https://github.com/XAMPPRocky/tokei
