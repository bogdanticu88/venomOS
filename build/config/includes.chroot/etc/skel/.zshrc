# VenomOS default .zshrc

# Prompt: red skull indicator, green user@host, path
PROMPT='%F{green}%n@%m%f:%F{red}%~%f%# '
RPROMPT='%F{240}%T%f'

# VenomOS tools in PATH
export PATH="$PATH:/opt/venomOS/bin"
export VENOM_TOOLS="/opt/venomOS/tools"
export VENOM_AI="/opt/venomOS/ai"

# Aliases
alias ls='ls --color=auto'
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias myip='curl -s https://api.ipify.org && echo'
alias ports='ss -tulnp'
alias connections='ss -tp'
alias tools='cd /opt/venomOS/tools'
alias ai='cd /opt/venomOS/ai'

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

# Key bindings
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Welcome
if [[ -t 1 ]]; then
    if command -v fastfetch &>/dev/null; then
        fastfetch
    else
        echo ""
        echo "  VenomOS — Intelligence. Precision. Persistence."
        echo "  Type 'venom-help' for available tools."
        echo ""
    fi
fi
