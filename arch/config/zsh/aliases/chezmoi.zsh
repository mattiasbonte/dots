chezmoi_add_to_source(){ chezmoi add $* }
alias chad='chezmoi_add_to_source'

chezmoi_init_configuration(){ chezmoi init }
alias chin='chezmoi_init_configuration'

chezmoi_apply(){ 
    export BW_SESSION=$(bw unlock --raw)
    chezmoi apply 
}
alias chap='chezmoi_apply'

chezmoi_show_data(){ chezmoi data | jq }
alias chsd='chezmoi_show_data'

chezmoi_test_template(){ chezmoi execute-template $* }
alias chet='chezmoi_test_template'

chezmoi_unlock_bitwarden_vault(){ 
    export BW_SESSION=$(bw unlock --raw) 
    bw sync
}
chbw='chezmoi_unlock_bitwarden_vault'
