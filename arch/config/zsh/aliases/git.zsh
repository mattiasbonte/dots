# --- #
# GIT #
# --- #
gw(){ git worktree $* }
gitprune(){
    git branch --v | grep "\[gone\]" | awk '{print $1}' | xargs git branch -D
    git fetch -p
}

git_conventional_commit() {
    $HOME/git/conventional_commit_helper.sh
}
alias gcc='git_conventional_commit'
alias gcm='git_conventional_commit'
alias coco='git_conventional_commit'

# pull push
alias gP='git push'

alias gp='git pull'
git_fetch_pull_rebase() {
    git fetch
    git pull --rebase --autostash
}
alias gpr=git_fetch_pull_rebase

# stash
alias gsl='git stash list'
alias gsp='git stash pop'
alias gsa='git stash apply'
alias gsd='git stash drop'
alias gss='git stash save'
alias gsh='git stash show'
# alias gsc='git stash clear'


