# ---------------------------------------------------------------------------
#  ~/.zshrc — Catppuccin Mocha rice
#  Plugins in ~/.zsh/plugins (install.sh clones them)
# ---------------------------------------------------------------------------

export PATH="$HOME/.local/bin:$PATH"

# ---- history --------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY HIST_REDUCE_BLANKS HIST_IGNORE_SPACE

# ---- completion -----------------------------------------------------------
# The static build ships its completion functions under share/zsh/<ver>/functions
# (static zsh builds keep completions in ~/.local/opt/zsh; harmless if absent)
[[ -d $HOME/.local/opt/zsh/share/zsh ]] && fpath=($HOME/.local/opt/zsh/share/zsh/*/functions(N) $fpath)
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ---- options --------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS CORRECT
unsetopt BEEP

# ---- keybindings ----------------------------------------------------------
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~' delete-char

# ---- Catppuccin Mocha palette (truecolor) ----------------------------------
CTP_BASE=$'%{\033[38;2;30;30;46m%}'
CTP_TEXT=$'%{\033[38;2;205;214;244m%}'
CTP_SUBTEXT=$'%{\033[38;2;166;173;200m%}'
CTP_MAUVE=$'%{\033[38;2;203;166;247m%}'
CTP_LAVENDER=$'%{\033[38;2;180;190;254m%}'
CTP_BLUE=$'%{\033[38;2;137;180;250m%}'
CTP_SAPPHIRE=$'%{\033[38;2;116;199;236m%}'
CTP_TEAL=$'%{\033[38;2;148;226;213m%}'
CTP_GREEN=$'%{\033[38;2;166;227;161m%}'
CTP_YELLOW=$'%{\033[38;2;249;226;175m%}'
CTP_PEACH=$'%{\033[38;2;250;179;135m%}'
CTP_RED=$'%{\033[38;2;243;139;168m%}'
CTP_PINK=$'%{\033[38;2;245;194;231m%}'
CTP_RESET=$'%{\033[0m%}'

# ---- git segment ----------------------------------------------------------
git_prompt_info() {
  local branch
  branch=$(git symbolic-ref --short -q HEAD 2>/dev/null) || return
  local color=$CTP_GREEN mark=""
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    color=$CTP_YELLOW
    mark=" ${CTP_RED}✱${CTP_RESET}"
  fi
  print -n " ${CTP_SUBTEXT}on ${color}${branch}${CTP_RESET}${mark}"
}

# ---- prompt ---------------------------------------------------------------
setopt PROMPT_SUBST
PROMPT="${CTP_MAUVE}╭─${CTP_RESET} ${CTP_MAUVE}%n${CTP_RESET}${CTP_SUBTEXT}@${CTP_RESET}${CTP_LAVENDER}%m${CTP_RESET} ${CTP_SUBTEXT}in${CTP_RESET} ${CTP_BLUE}%~${CTP_RESET}"
PROMPT+='$(git_prompt_info)'
PROMPT+=$'\n'"${CTP_MAUVE}╰─${CTP_GREEN}❯${CTP_RESET} "
RPROMPT=""

# ---- aliases --------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias free='free -h'

export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"

# ---- plugins --------------------------------------------------------------
[[ -r "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -r "$HOME/.zsh/plugins/catppuccin-zsh-syntax-highlighting/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]] && source "$HOME/.zsh/plugins/catppuccin-zsh-syntax-highlighting/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh"

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=148,226,213'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

[[ -d $HOME/.spicetify ]] && export PATH="$PATH:$HOME/.spicetify"

# Starship prompt (Catppuccin Mocha, ~/.config/starship.toml); falls back to the prompt above
command -v starship >/dev/null && eval "$(starship init zsh)"

# System info on new terminal windows
[[ -o interactive && $SHLVL -le 2 ]] && command -v fastfetch >/dev/null && fastfetch
