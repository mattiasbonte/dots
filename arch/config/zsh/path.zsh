# ----- #
# PATHS #
# ----- #
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/.local/bin

export PATH=$PATH:$HOME/.local/share/neovim/bin
export PATH=$PATH:$HOME/.local/share/bob/nvim-bin

export PATH=$PATH:$HOME/.nvm
export PATH=$PATH:$HOME/.bun/bin
export PATH=$PATH:$HOME/.cargo/bin

export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:/usr/local/go/bin

export PNPM_HOME="/home/wise/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
