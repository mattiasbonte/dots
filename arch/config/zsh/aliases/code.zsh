#   ______   ______  _______  ________
#  /      \ /      \|       \|        \
# |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓
# | ▓▓   \▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓__
# | ▓▓     | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓  \
# | ▓▓   __| ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓▓▓▓
# | ▓▓__/  \ ▓▓__/ ▓▓ ▓▓__/ ▓▓ ▓▓_____
#  \▓▓    ▓▓\▓▓    ▓▓ ▓▓    ▓▓ ▓▓     \
#   \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓

# ------ #
# BASICS #
# ------ #
alias kp="$HOME/scripts/kill_port.sh"

resume_suspended_process(){ fg }
zle     -N            resume_suspended_process
bindkey -M emacs '^z' resume_suspended_process
bindkey -M vicmd '^z' resume_suspended_process
bindkey -M viins '^z' resume_suspended_process
bindkey -M emacs '\ez' resume_suspended_process
bindkey -M vicmd '\ez' resume_suspended_process
bindkey -M viins '\ez' resume_suspended_process

# ---- #
# HURL #
# ---- #
hurl_inline_request() {
    # identical to `curl`
    echo $1 | hurl
}
alias hu='hurl_inline_request'
alias hur='hurl_inline_request'



# ---- #
# MAKE #
# ---- #
mr() { make run $* }
mb() { make build $* }
mt() { make test $* }


# -------------------- #
# NPM, PNPM, BUN, YARN #
# -------------------- #

# --
# Sends a system notification.
# --
send_system_notifyme() {
    msg="$1"
    name="$(basename `pwd`)"

    if command -v notifyme &> /dev/null; then
        notifyme -s -m "$name: $msg"
    else
        echo "$1"
    fi
}

# --
# Sends a phone notification.
# --
send_phone_notifyme() {
    msg="$1"
    name="$(basename `pwd`)"

    if command -v notifyme &> /dev/null; then
        notifyme -p -m "$name: $msg"
    else
        echo "$1"
    fi
}


# --
# Tries to find the project's package manager.
# --
get_packager_name() {
    packager_name=""
    if [ -f ./pnpm-lock.yaml ]; then
        packager_name="pnpm"
    elif [ -f ./yarn.lock ]; then
        packager_name="yarn"
    elif [ -f ./package-lock.json ]; then
        packager_name="npm"
    elif [ -f ./bun.lockb ]; then
        packager_name="bun"
    else
        echo "No lockfile found. Are you in the root of a project?"
    fi

    if [ ! -f ./package.json ]; then
        echo "No package.json found. Are you in the root of the project?"
        return 1
    fi

    echo $packager_name
}

# --
# Tries to install the project's packages.
# --
install_local_packages() {
    packager_name="$(get_packager_name)"

    echo "🚀 Execute: $packager_name install"
    eval "($packager_name install && send_system_notifyme 'packages installed') || send_system_notifyme 'install failed'"
}

# --
# Tries to update the project's packages.
# --
update_local_packages() {
    packager_name="$(get_packager_name)"

    if [ "$packager_name" = "pnpm" ]; then
        cmd="$packager_name update --latest"
    else
        cmd="$packager_name update"
    fi

    echo "🚀 Execute: $cmd"
    eval "($cmd && send_system_notifyme 'packages updated') || send_system_notifyme 'package update failed'"
}

# --
# Tries to run the project's dev server script.
# --
start_local_dev_server() {
    packager_name="$(get_packager_name)"

    if [ ! -d ./node_modules ]; then
        echo "No node_modules found. Installing packages..."
        install_local_packages
    fi

    dev_script=""

    # possible commands
    dev_command=$(cat ./package.json | jq -r '.scripts.dev')
    start_command=$(cat ./package.json | jq -r '.scripts.start')
    if [ "$dev_command" != "null" ]; then
        dev_script="dev"
    elif [ "$start_command" != "null" ]; then
        dev_script="start"
    else
        echo "No dev server script found in the 'package.json'."
        return 1
    fi

    dev_command="$packager_name run $dev_script"
    echo "🚀 Execute: $dev_command"
    eval "$dev_command || send_system_notifyme 'dev server died'"
}

# --
# Tries to run the project's test script.
# --
run_local_tests() {
    packager_name="$(get_packager_name)"

    if [ ! -d ./node_modules ]; then
        echo "No node_modules found. Installing packages..."
        install_local_packages
    fi

    test_script=""

    # possible commands
    test_command=$(cat ./package.json | jq -r '.scripts.test')
    if [ "$test_command" != "null" ]; then
        test_script="test"
    else
        echo "No test script found in the 'package.json'."
        return 1
    fi

    test_command="$packager_name run $test_script"
    echo "🚀 Execute: $test_command"
    eval "$test_command || send_system_notifyme 'tests failed'"
}

# --
# Tries to run the package.json `check` script, if no script is found, runs the tsc command
# --
run_local_checks() {
    packager_name="$(get_packager_name)"

    if [ ! -d ./node_modules ]; then
        echo "No node_modules found. Installing packages..."
        install_local_packages
    fi

    check_script=""

    # possible commands
    check_command=$(cat ./package.json | jq -r '.scripts.check')
    if [ "$check_command" != "null" ]; then
        check_script="check"
    else
        echo "No check script found in the 'package.json'."
        echo "Trying to run 'tsc' instead..."
        eval "./node_modules/.bin/tsc"
        return 0
    fi

    check_command="$packager_name run $check_script"
    echo "🚀 Execute: $check_command"
    eval "$check_command || send_system_notifyme 'checks failed'"
}

run_local_chore() {
    local env="dev"
    while getopts "p" opt; do
        case $opt in
            p) env="prod" ;;
        esac
    done
    shift $((OPTIND-1))

    packager_name="$(get_packager_name)"

    if [ ! -d ./node_modules ]; then
        echo "No node_modules found. Installing packages..."
        install_local_packages
    fi

    chore_script="${env}:chore"
    chore_command=$(cat ./package.json | jq -r ".scripts.\"${chore_script}\"")

    if [ "$chore_command" = "null" ]; then
        echo "No ${chore_script} script found in the 'package.json'."
        return 1
    fi

    chore_command="$packager_name run $chore_script"
    echo "🚀 Execute: $chore_command"
    eval "$chore_command && send_phone_notifyme '👷 chore done' || send_phone_notifyme '👷 chore failed'"
}

# --
# Tries to run migrations
# --
run_local_migrations() {
    packager_name="$(get_packager_name)"

    if [ ! -d ./node_modules ]; then
        echo "No node_modules found. Installing packages..."
        install_local_packages
    fi

    migration_script=""

    # possible commands
    migration_command=$(cat ./package.json | jq -r '.scripts."dev:migrate"')
    if [ "$migration_command" != "null" ]; then
        migration_script="dev:migrate"
    else
        echo "No migrate script found in the 'package.json'."
        return 1
    fi

    migration_command="$packager_name run $migration_script"
    echo "🚀 Execute: $migration_command"
    eval "$migration_command || send_system_notifyme 'migrations failed'"
}


# Aliases
alias dev=start_local_dev_server
alias in=install_local_packages
alias up=update_local_packages
alias tst=run_local_tests
alias chk=run_local_checks
alias check=run_local_checks
alias chore=run_local_chore
alias chorep="run_local_chore -p"
alias mig=run_local_migrations
alias migrate=run_local_migrations
alias phone=send_phone_notifyme

# ------ #
# WINTRO #
# ------ #



# -------- #
# SUPABASE #
# -------- #
run_local_project_supabase() {
    if [ ! -f ./node_modules/.bin/supabase ]; then
        echo "No supabase command found in node_modules. Please run 'npm install -D supabase' first."
        return 1
    fi

    ./node_modules/.bin/supabase $*
}
alias sb=run_local_project_supabase
