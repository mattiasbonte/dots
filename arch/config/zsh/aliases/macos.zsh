noSleep() {
    # prevent macbook from sleeping
    caffeinate -i -s
}
alias nosleep=noSleep
alias wake=noSleep


# ----- #
# YABAI #
# ----- #
restartYabai() {
    brew services restart yabai
    brew services restart skhd
}
alias ry=restartYabai

# ---- #
# BREW #
# ---- #
brewUpdate() {
    brew update
    brew upgrade
    brew cleanup
}
brewInstall() {
    brew install $*
    brew cleanup
}
brewReinstall() {
    brew reinstall $*
    brew cleanup
}
brewUninstall() {
    brew uninstall $*
    brew cleanup
}
brewInstallCask() {
    brew install --cask $*
    brew cleanup
}
brewUninstallCask() {
    brew uninstall --cask $*
    brew cleanup
}
brewDoctor() {
    brew doctor
    brew missing
}
brewCleanup() {
    brew cleanup
}

alias brin=brewInstall
alias brun=brewUninstall
alias brre=brewReinstall
alias brinc=brewInstallCask
alias brunc=brewUninstallCask

alias B=brewUpdate
alias brup=brewUpdate
alias brdo=brewDoctor
alias brcl=brewCleanup

# ---- #
# NVIM #
# ---- #
rmviews() { rm -rf $HOME/.local/state/nvim/view }
alias rmv=rmviews
