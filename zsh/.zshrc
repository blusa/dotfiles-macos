# -----------------------------
# Keybindings
# -----------------------------
bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# Increase nesting limit so Starship + vi-mode can both wrap zle widgets
typeset -g FUNCNEST=5000

# Debian llama distinto a bat y fd
command -v batcat >/dev/null && alias bat='batcat'
if command -v fd >/dev/null; then _FD=fd
elif command -v fdfind >/dev/null; then _FD=fdfind; alias fd='fdfind'
fi

# FZF, zoxide, direnv inits (guardeados: no rompen si falta la herramienta)
command -v fzf >/dev/null && eval "$(fzf --zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init --cmd cd zsh)"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# fzf: fd respeta .gitignore; preview con bat en Ctrl+T
if [ -n "$_FD" ]; then
    export FZF_DEFAULT_COMMAND="$_FD --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$_FD --type d --hidden --follow --exclude .git"
fi
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {} 2>/dev/null || ls {}'"

# -----------------------------
# Zinit Setup
# -----------------------------
export ZINIT_HOME="${HOME}/.zinit/bin"

if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Path updates
# -----------------------------
[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"

# -----------------------------
# Zinit Plugins
# -----------------------------
# Load completions first
autoload -Uz compinit && compinit


# Plugin loading
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# OMZ snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# Replay previous working directory
zinit cdreplay -q

# -----------------------------
# fzf-tab Styles
# -----------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --icons $realpath 2>/dev/null || ls $realpath'

eval "$(starship init zsh)"

# -----------------------------
# History Settings
# -----------------------------
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# -----------------------------
# Aliases
# -----------------------------
alias ls='eza --icons --group-directories-first -h'
alias ll='eza --icons --group-directories-first -lh'
alias lt='eza --icons --tree --level=2'
alias cat='bat'
alias lg='lazygit'
alias ld='lazydocker'
command -v brew >/dev/null && alias upup='brew upgrade --greedy && brew upgrade --cask --greedy'

# yazi: al salir te deja en el último directorio navegado
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
# -----------------------------
# Terminal-specific Integration
# -----------------------------
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

[ -d /opt/homebrew/opt/openjdk@21/bin ] && export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# ---
# Tmuxinator setup
# ---
export EDITOR='nvim'
export NVM_DIR="$HOME/.nvm"
# nvm: brew en macOS, install script en Linux
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# opencode
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f ~/.expo-token.env ] && source ~/.expo-token.env  # EXPO_TOKEN fuera de dotfiles
