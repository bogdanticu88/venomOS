# VenomOS zshrc

# Path
export PATH="$PATH:/opt/venomOS/bin"
export VENOM_TOOLS="/opt/venomOS/tools"

# Prompt — green user, red path, clean
PROMPT='%F{green}%n@venomOS%f %F{red}%~%f %# '
RPROMPT='%F{240}%T%f'

# Aliases
alias ls='eza --color=auto --group-directories-first'
alias ll='eza -alh --color=auto --group-directories-first'
alias la='eza -a --color=auto'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ports='ss -tulnp'
alias myip='curl -s https://api.ipify.org && echo'
alias torip='torsocks curl -s https://api.ipify.org && echo'
alias tools='cd /opt/venomOS/tools'

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

# Key bindings
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Auto-start tmux on TTY login
if [ -t 1 ] && [ -z "$TMUX" ] && [ "$TERM" != "screen" ]; then
    tmux new-session -A -s venom
fi

# Welcome (shown outside tmux only)
if [ -t 1 ] && [ -z "$TMUX" ]; then
    fastfetch 2>/dev/null || true
    echo ""
    echo "  Run 'venom-help' for available tools."
    echo ""
fi
