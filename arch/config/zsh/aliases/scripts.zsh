#   ______   ______  _______  ______ _______  ________  ______
#  /      \ /      \|       \|      \       \|        \/      \
# |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\\▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓\
# | ▓▓___\▓▓ ▓▓   \▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓__/ ▓▓  | ▓▓  | ▓▓___\▓▓
#  \▓▓    \| ▓▓     | ▓▓    ▓▓ | ▓▓ | ▓▓    ▓▓  | ▓▓   \▓▓    \ 
#  _\▓▓▓▓▓▓\ ▓▓   __| ▓▓▓▓▓▓▓\ | ▓▓ | ▓▓▓▓▓▓▓   | ▓▓   _\▓▓▓▓▓▓\
# |  \__| ▓▓ ▓▓__/  \ ▓▓  | ▓▓_| ▓▓_| ▓▓        | ▓▓  |  \__| ▓▓
#  \▓▓    ▓▓\▓▓    ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓        | ▓▓   \▓▓    ▓▓
#   \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓\▓▓         \▓▓    \▓▓▓▓▓▓ 

# ---------------------- #
# PERSONAL $HOME/scripts #
# ---------------------- #
quick() { sh $HOME/scripts/tmux/quick_launcher.sh }
H(){
    loc=$(pwd)
    eval "cd $configPath/tools && pipenv run python3 main.py $loc"
    cd $loc
}


# ------ #
# TIMERS #
# ------ #
stopwatch() {
    start=$(date +%s)
    while true; do
        time="$(( $(date +%s) - $start))"
        printf '%s\r' "$(date -u -r "$time" +%H:%M:%S)"
        sleep 1

        # say the amount of minutes passed after 15 minutes
        if [ $time -gt 900 ]; then
            if [ $(( $time % 900 )) -eq 0 ]; then
                say -v Whisper "$(( $time / 60 )) minutes passed"
            fi
        fi
    done
}
alias sw=stopwatch

countdown() {
    start="$(( $(date '+%s') + $1))"
    while [ $start -ge $(date +%s) ]; do
        time="$(( $start - $(date +%s) ))"
        printf '%s\r' "$(date -u -d "@$time" +%H:%M:%S)"
        sleep 1
    done
}

# ---------- #
# AI HELPERS #
# ---------- #
alias aI=aichat             # Regular ai chat
alias aiS='aichat -s'       # Regular ai chat with session
alias ai='aichat -r qa'     # Quick Answers
alias ais='aichat -s -r qa' # Quick Answers with session

# ------ #
# YT-DLP #
# ------ #
download_youtube_audio_with_timestamps() {
    $HOME/scripts/youtube.sh
}
alias dl=download_youtube_audio_with_timestamps
