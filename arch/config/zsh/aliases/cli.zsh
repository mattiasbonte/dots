# ------------ #
# CLI COMMANDS #
# ------------ #

# --
# history
# --
h() { gum filter < $HISTFILE }

# --
# refresh
# --
R() {
    source $HOME/.zshrc
    clear
}

# --
# get ip
# --
getip() {
    myIp=$(curl -s https://api.ipify.org)
    if [[ "$OSTYPE" == "darwin"* ]]; then echo $myIp | pbcopy; fi
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then echo $myIp | xclip -selection clipboard; fi
    echo $myIp
}

# --
# weather
# --
get_weather_forcast() {
    curl wttr.in/$1
}
alias weather='get_weather_forcast'
alias wttr='get_weather_forcast'

# --
# stargazer (gh stars)
# --
alias star=stargazer

# --
# create dir cd
# --
take() {
    mkdir -p "$1"
    cd "$1"
}

# --
# notifications
# --
send_telegram_notification(){
    notifyme -t "alert" -m "$*"
}
alias notify='send_telegram_notification'
alias msg='send_telegram_notification'

# --
# kite size
# --
function what_kite_size_to_use {
    # INFO: set weight
    weight_kg="79"
    ws_knots="$1"

    if [ -z "$ws_knots" ]; then
        ws_knots=$(gum input --header "Windspeed (knots)" --placeholder "20")
    fi
    if [ -z "$ws_knots" ]; then
        echo "Please provide a windspeed in knots"
        return 1
    fi

    # FORMULA weight / windspeedknots x 2,5
    ws_kmh=$(echo "scale=2; $ws_knots * 1.852" | bc)
    kite_size=$(echo "scale=2; $weight_kg / $ws_knots * 2.5" | bc)
    echo "For a windspeed of $ws_kmh km/h (or $ws_knots knots) and a weight of $weight_kg kg, you should use a kite of $kite_size m²"
}
alias kite="what_kite_size_to_use"

# --
# supabase
# --
# local_project_supabase() {
#     if ! command -v ./node_modules/.bin/supabase &> /dev/null
#     then
#         echo "please install supabase cli in your project"
#         echo "https://supabase.io/docs/guides/cli"
#         return 1
#     fi
#
#     ./node_modules/.bin/supabase $*
# }
# alias supabase='local_project_supabase'
# alias sb='local_project_supabase'

