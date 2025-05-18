#  ________ ________ ________      __    __ ________ __       _______  ________ _______   ______
# |        \        \        \    |  \  |  \        \  \     |       \|        \       \ /      \
# | ▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓    | ▓▓  | ▓▓ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\
# | ▓▓__       /  ▓▓| ▓▓__        | ▓▓__| ▓▓ ▓▓__   | ▓▓     | ▓▓__/ ▓▓ ▓▓__   | ▓▓__| ▓▓ ▓▓___\▓▓
# | ▓▓  \     /  ▓▓ | ▓▓  \       | ▓▓    ▓▓ ▓▓  \  | ▓▓     | ▓▓    ▓▓ ▓▓  \  | ▓▓    ▓▓\▓▓    \
# | ▓▓▓▓▓    /  ▓▓  | ▓▓▓▓▓       | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓  | ▓▓     | ▓▓▓▓▓▓▓| ▓▓▓▓▓  | ▓▓▓▓▓▓▓\_\▓▓▓▓▓▓\
# | ▓▓      /  ▓▓___| ▓▓          | ▓▓  | ▓▓ ▓▓_____| ▓▓_____| ▓▓     | ▓▓_____| ▓▓  | ▓▓  \__| ▓▓
# | ▓▓     |  ▓▓    \ ▓▓          | ▓▓  | ▓▓ ▓▓     \ ▓▓     \ ▓▓     | ▓▓     \ ▓▓  | ▓▓\▓▓    ▓▓
#  \▓▓      \▓▓▓▓▓▓▓▓\▓▓           \▓▓   \▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓      \▓▓▓▓▓▓▓▓\▓▓   \▓▓ \▓▓▓▓▓▓ 


# ff -> find local file
# fd -> find local directory
# Ff -> find global file
# Fd -> find global directory
# fif -> find pattern inside local file

# fb -> find and checkout git branch
# fc -> find and checkout git commit
# fs -> find in git stash C-d C-b

# fk -> find and kill process
# fh -> find in command history
# fpod -> kubernetes pod search


# --------- #
# VARIABLES #
# --------- #
local EDITOR='nvim'


# ---------------------------------------------------------------------------- #
# OPEN GLOBAL FILE https://github.com/junegunn/fzf/wiki/examples#opening-files #
# ---------------------------------------------------------------------------- #
# fuzzy cd - global - ex: "fD this that and_this"
fzf_find_global_dir() {
	local file
	if [[ "$OSTYPE" == "darwin"* ]]; then
		file="$(locate -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1)"
	else
		file="$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1)"
	fi

	if [[ -n $file ]]; then
		if [[ -d $file ]]; then
			cd -- $file
			# $EDITOR -- $file
		else
			cd -- ${file:h}
			# $EDITOR -- $file
		fi
	fi
}
alias Fd=fzf_find_global_dir


# ----------------- #
# FIND GLOBAL FILES #
# ----------------- #
fzf_find_global_files() {
	local files

	files=(${(f)"$(locate -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1 -m)"})

	if [[ -n $files ]]; then
		$EDITOR -- $files
		print -l $files[1]
	fi
}
alias Ff=fzf_find_global_files


# ------------------------------------------------------------------------------- #
# FIND LOCAL DIR https://github.com/junegunn/fzf/wiki/examples#changing-directory #
# ------------------------------------------------------------------------------- #
fzf_find_local_dir() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}
# hidden
fzf_find_hidden_local_dir() {
	local dir
	dir=$(find ${1:-.} -type d 2> /dev/null | fzf +m) && cd "$dir"
}

# aliases
alias fd=fzf_find_hidden_local_dir


# ---------------- #
# FIND LOCAL FILES #
# ---------------- #
# multiselect - open in explorer ( C-o ), open in editor ( C-e )
fzf_find_local_files() {
	IFS=$'\n' out=("$(fzf-tmux --query="$1" --exit-0 --expect=ctrl-o,ctrl-e)")
	key=$(head -1 <<< "$out")
	file=$(head -2 <<< "$out" | tail -1)

	if [ -n "$file" ]; then
		if [[ "$OSTYPE" == "linux-gnu"* ]]; then
			[ "$key" = ctrl-e ] && ${EDITOR:-$EDITOR} "$file" || nnn_cd_on_quit "$file"
		fi
		if [[ "$OSTYPE" == "darwin"* ]]; then
			[ "$key" = ctrl-e ] && ${EDITOR:-$EDITOR} "$file" || nnn_cd_on_quit "$file"
		fi
	fi
}
alias ff=fzf_find_local_files
alias d=fzf_find_local_files
# INFO: this doesn't work, I assume because of tmux tab... it opens and closes instantly
# zle     -N            fzf_find_local_files
# bindkey -M emacs '^p' fzf_find_local_files
# bindkey -M vicmd '^p' fzf_find_local_files
# bindkey -M viins '^p' fzf_find_local_files


# ----------------------- #
# FIND INSIDE LOCAL FILES #
# ----------------------- #
fzf_find_inside_local_files() {
	# tool can be rg (https://github.com/BurntSushi/ripgrep) | rga (https://github.com/phiresky/ripgrep-all)
	tool="rg"

    if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
    local file
    file="$($tool --max-count=1 --ignore-case --files-with-matches --no-messages "$*" | fzf-tmux -p +m --preview="$tool --ignore-case --pretty --context 10 '"$*"' {}")" && echo "opening $file with $EDITOR" && $EDITOR "$file" || return 1;
}
alias fif=fzf_find_inside_local_files


# --------------------- #
# FIND AND KILL PROCESS #
# --------------------- #
fzf_find_and_kill_process() {
    local pid 
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi  

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi  
}
alias fkill=fzf_find_and_kill_process
zle     -N             fzf_find_and_kill_process
bindkey -M emacs '\eK' fzf_find_and_kill_process
bindkey -M vicmd '\eK' fzf_find_and_kill_process
bindkey -M viins '\eK' fzf_find_and_kill_process

# Fuzzy systemctl
fsys() { source $HOME/scripts/fuzzy-sys.zsh }


# ---------- #
# KUBERNETES #
# ---------- #
# Fuzzy pod explorer
fzf_kubernetes_pod_explorer() {
  FZF_DEFAULT_COMMAND="kubectl get pods --all-namespaces" \
    fzf --info=inline --layout=reverse --header-lines=1 \
        --prompt "$(kubectl config current-context | sed 's/-context$//')> " \
        --header $'╱ Enter (kubectl exec) ╱ CTRL-O (open log in editor) ╱ CTRL-R (reload) ╱\n\n' \
        --bind 'ctrl-/:change-preview-window(80%,border-bottom|hidden|)' \
        --bind 'enter:execute:kubectl exec -it --namespace {1} {2} -- bash > /dev/tty' \
        --bind 'ctrl-o:execute:${EDITOR:-vim} <(kubectl logs --all-containers --namespace {1} {2}) > /dev/tty' \
        --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
        --preview-window up:follow \
        --preview 'kubectl logs --follow --all-containers --tail=10000 --namespace {1} {2}' "$@"
}
alias fpod=fzf_kubernetes_pod_explorer
alias fpods=fzf_kubernetes_pod_explorer


# ---------------------------------------------------------------------------- #
# GIT - several git listing functionalities, handy for finding git information #
# ---------------------------------------------------------------------------- #
# Check if git repo
is_in_git_repo() {
	git rev-parse HEAD > /dev/null 2>&1
}

# Fzf popup settings + toggle binding
fzf-down() {
  fzf --height 100% --min-height 30 --bind ctrl-/:toggle-preview "$@"
  # Tmux popup
  # fzf-tmux -p --height 100% --min-height 20 --bind ctrl-/:toggle-preview "$@"
}

# List git status files
fgs() {
  is_in_git_repo || return
  git -c color.status=always status --short |
  fzf-down -m --ansi --nth 2..,.. \
    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1})' |
  cut -c4- | sed 's/.* -> //'
}

# List branches
fzf_list_branches() {
  is_in_git_repo || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}
alias fgb=fzf_list_branches

# List stashes
fgz() {
  is_in_git_repo || return
  git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
  cut -d: -f1
}

# List commit hashes
fgh() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always' |
  grep -o "[a-f0-9]\{7,\}"
}

# List remotes
fr() {
  is_in_git_repo || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  fzf-down --tac \
    --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" {1}' |
  cut -d$'\t' -f1
}

# List tags
ft() {
  is_in_git_repo || return
  git tag --sort -version:refname |
  fzf-down --multi --preview-window right:70% \
    --preview 'git show --color=always {}'
}

# -------- #
# BRANCHES #
# -------- #
fzf_branch_tags_local_remote() {
    # Create a unique name starting with TMP_FZF_
    local tmp_name=$(mktemp -u TMP_FZF_XXXXXX)
    local tags branches target

	git fetch -q

	branches=$(
		git --no-pager branch --all \
		--format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
		| sed '/^$/d'
	) || return

	tags=$(
		git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}'
	) || return

	target=$(
		(echo "$branches"; echo "$tags") |
		fzf --no-hscroll --no-multi -n 2 \
		--ansi
	) || return

    # If there are changes both staged or unstaged, stash them and use the tmp_name
    if [[ -n $(git status --porcelain) ]]; then
        git stash save -u -k -q $tmp_name
    fi

	# checkout the branch as local branch without origin/ prefix
    # if the branch is a local branch, checkout the branch
    # if the branch is a tag, checkout the tag
    if [[ $target == *"tag"* ]]; then
        git checkout $(echo $target | awk '{print $2}')
    # if the branch is a remote branch, checkout the branch as local branch
    elif [[ $target == *"origin"* ]]; then
        git checkout -b $(echo $target | awk '{print $2}') $(echo $target | awk '{print $2}')
    else
        git checkout $(echo $target | awk '{print $2}')
    fi

    # Pop the stash if there is one with the tmp_name
    if [[ -n $(git stash list | grep $tmp_name) ]]; then
        git stash pop -q
    fi
}
alias fb=fzf_branch_tags_local_remote

# ------- #
# COMMITS #
# ------- #
fzf_commit_with_preview() {
	local commit

	git fetch -q

	alias glNoGraph='git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" "$@"'
	_gitLogLineToHash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
	_viewGitLogLine="$_gitLogLineToHash | xargs -I % sh -c 'git show --color=always % | delta'"

	commit=$(
		glNoGraph | fzf --no-sort --reverse --tiebreak=index --no-multi --preview-window right:66% --ansi --preview="$_viewGitLogLine" 
	) && git checkout $(echo "$commit" | sed "s/ .*//")
}
fzf_commit_hash() {
	local commits commit

	commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
	commit=$(echo "$commits" | fzf --tac +s +m -e --ansi --reverse) &&
	echo -n $(echo "$commit" | sed "s/ .*//")
}
alias fc=fzf_commit_with_preview
alias fch=fzf_commit_hash

# ------- #
# STASHES #
# ------- #
fzf_stash() {
	# CR  -> show stash content
	# C-d -> show diff against current HEAD
	# C-b -> checkout as branch, easier merging
	local out q k sha

	while out=$(
		git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
		fzf --ansi --no-sort --query="$q" --print-query \
		--expect=ctrl-d,ctrl-b);
	do
		mapfile -t out <<< "$out"
		q="${out[0]}"
		k="${out[1]}"
		sha="${out[-1]}"
		sha="${sha%% *}"
		[[ -z "$sha" ]] && continue
		if [[ "$k" == 'ctrl-d' ]]; then
			git diff $sha
		elif [[ "$k" == 'ctrl-b' ]]; then
			git stash branch "stash-$sha" $sha
		break;
		else
			git stash show -p $sha
		fi
	done
}
alias fs=fzf_stash

