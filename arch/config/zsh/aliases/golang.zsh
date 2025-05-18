# ------ #
# GOLANG #
# ------ #
go_mod_init() {
    # format go mod init <hosting>/<username>/<projecname>
    # format go mod init github.com/username/reponame
    go mod init $1
    go mod tidy
    go mod vendor
}
alias goin='go_init'

go_run_main(){
    go run main.go $@
}
alias gor='go_run_main'

alias got='go mod tidy'
alias goT'go test'

alias gob='go build'
alias goi='go install'
alias goc='go clean'
alias goh='go help'

