# ---- #
# NVIM #
# ---- #
# export XDG_RUNTIME_DIR=/run/user/$(id -u)


# ----------------------------------------------------------- #
# DISTRO PICKER - https://www.youtube.com/watch?v=LkHjJlSgKZY #
# ----------------------------------------------------------- #
function nvims() {
    opt_nvim_default="Nvim (default)"
    opt_lazy_starter="Lazy Vim (starter)"
    opt_lazy_wyze="Lazy Wyze ✨"
    opt_nvim_nude="Nvim (nude)"

    items=(
        "$opt_lazy_wyze"
        "$opt_nvim_default"
        "$opt_lazy_starter"
        "$opt_nvim_nude"
    )

    config=$(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)

    if [[ -z $config ]]; then return 0; fi
    if [[ $config == "$opt_nvim_default" ]]; then config=""; fi
    if [[ $config == "$opt_nvim_nude" ]]; then config="non_existing_name_so_it_fallsback"; fi

    if [[ $config == "$opt_lazy_starter" ]]; then config="nvim_distros/lazyvim"; fi
    if [[ $config == "$opt_lazy_wyze" ]]; then config="nvim_distros/lazywyze"; fi

    NVIM_APPNAME=$config nvim $@
}
alias ns=nvims

# DISTROS
lw() { 
    NVIM_APPNAME=nvim_distros/lazywyze nvim $* 
}
alias nvim-lazy-wyze="NVIM_APPNAME=nvim_distros/lazywyze nvim"

# KEYBINDS
# bindkey -s ^a "nvims\n"


# ------- #
# ALIASES #
# ------- #
neovim() { nvim $* }
alias n=neovim

neovim_find_string() {
    # nvim -c "Telescope grep_string" 
    nvim -c "FzfLua live_grep" 
}
alias F=neovim_find_string

neovim_find_files() {
    # nvim -c "Telescope find_files" 
    nvim -c "FzfLua files" 
}
alias f=neovim_find_files

neovim_find_oldfiles() { 
    # nvim -c "Telescope oldfiles" 
    nvim -c "FzfLua oldfiles" 
}
alias \r=neovim_find_oldfiles

neovim_compile_typescript() { 
    # nvim -c 'OverseerRun tscw' -c 'copen' -c 'wincmd k' -c 'FzfLua oldfiles' 
    nvim -c 'OverseerRun tscw' -c 'FzfLua oldfiles' 
}
alias nt=neovim_compile_typescript

neovim_debug_lua() { 
    nvim -c 'lua require"osv".launch({port=8086})' -c 'FzfLua oldfiles' 
}
alias nd=neovim_debug_lua

neovim_open_harpoon() {
    nvim -c 'lua require("harpoon.ui").toggle_quick_menu()'
}
alias fh=neovim_open_harpoon

neovim_open_dadbod_ui() {
    nvim -c 'DBUI'
}
alias db=neovim_open_dadbod_ui


# --
# KEYBINDS
# --
launch_neovim_keybind() {
    nvim -c "FzfLua oldfiles" 
}
zle     -N            launch_neovim_keybind
bindkey -M emacs '^n' launch_neovim_keybind
bindkey -M vicmd '^n' launch_neovim_keybind
bindkey -M viins '^n' launch_neovim_keybind
bindkey -M emacs '\en' launch_neovim_keybind
bindkey -M vicmd '\en' launch_neovim_keybind
bindkey -M viins '\en' launch_neovim_keybind
zle     -N            neovim_find_string
bindkey -M emacs '^f' neovim_find_string
bindkey -M vicmd '^f' neovim_find_string
bindkey -M viins '^f' neovim_find_string
bindkey -M emacs '\ef' neovim_find_string
bindkey -M vicmd '\ef' neovim_find_string
bindkey -M viins '\ef' neovim_find_string

# --
# TERM INPUT
# --
edit_terminal_input_with_nvim() {
    temp_file='/tmp/scratchpad_terminal_input.sh'
    nvim "$temp_file"

    if [[ -s "$temp_file" ]]; then
        command_input=$(<"$temp_file")

        # Execute the command with the content from the temporary file
        eval "$command_input"
    fi
}
zle     -N            edit_terminal_input_with_nvim
bindkey -M emacs '^o' edit_terminal_input_with_nvim
bindkey -M vicmd '^o' edit_terminal_input_with_nvim
bindkey -M viins '^o' edit_terminal_input_with_nvim
bindkey -M emacs '\eo' edit_terminal_input_with_nvim
bindkey -M vicmd '\eo' edit_terminal_input_with_nvim
bindkey -M viins '\eo' edit_terminal_input_with_nvim

