# VenomOS default .bashrc

# Prompt: green user@host, red path
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;31m\]\w\[\033[00m\]\$ '

# Color support
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Network shortcuts
alias myip='curl -s https://api.ipify.org && echo'
alias ports='ss -tulnp'
alias connections='ss -tp'

# Quick navigation
alias tools='cd /opt/venomOS/tools'
alias ai='cd /opt/venomOS/ai'

# VenomOS tools in PATH
export PATH="$PATH:/opt/venomOS/bin"

# Python virtual env auto-activate if present
if [ -f "$HOME/.venv/bin/activate" ]; then
    source "$HOME/.venv/bin/activate"
fi

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# Welcome message
if [ -t 1 ]; then
    if command -v fastfetch &>/dev/null; then
        fastfetch
    else
        echo ""
        echo "  VenomOS — Intelligence. Precision. Persistence."
        echo "  Type 'venom-help' for available tools."
        echo ""
    fi
fi
