# vim: fdm=marker
# zmodload zsh/zprof
PROFILE_STARTUP=false
if [[ "$PROFILE_STARTUP" == true ]]; then
    # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
    PS4=$'%D{%M%S%.} %N:%i> '
    exec 3>&2 2>$HOME/tmp/startlog.$$
    setopt xtrace prompt_subst
fi
fpath=($HOME/.zfunc $fpath)
# Default Path -------------------------{{{
path=(
    /usr/local/bin
    /usr/local/sbin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    ${HOME}/.fzf/bin
    ${HOME}/.local/bin
    ${HOME}/.bin
)
if [[ $OSTYPE == darwin* ]]; then
    path=(/opt/homebrew/bin $path)
fi
# -U: dedupe the PATH-tied array, keeping the first (highest-priority) copy of
#     each directory so re-sourced/nested shells don't bloat $PATH.
typeset -U path
export path
# }}}
# zenv ---------------------------------{{{
DISABLE_AUTO_UPDATE='true'
skip_global_compinit=1
# -A: associative array (hash); required before key assignment like ZI[BIN_DIR]
typeset -A ZI
ZI[BIN_DIR]="${HOME}/.zi/bin"
if [[ ! -f ${HOME}/.zi/bin/zi.zsh ]]; then
    command mkdir -p "${HOME}/.zi" && command git clone --depth 1 https://github.com/z-shell/zi.git "${HOME}/.zi/bin"
fi
source "${ZI[BIN_DIR]}/zi.zsh"

export USER_SSH=/tmp/u${UID}-ssh
mkdir -p $USER_SSH/github
chmod go-rwx $USER_SSH

autoload -Uz _zi
(( ${+_comps} )) && _comps[zi]=_zi

# Per-environment config loaded early for tmux automation first-command use
[ -f ~/.local_zshrc ] && source ~/.local_zshrc

# Minimal prompt for instant first-command availability
# Full theme replaces this on the second precmd (after first prompt renders)
PS1=$'%{\e(0%}└─%{\e(B%}[%?]%{\e(0%}─%{\e(B%}> '

# inlined from OMZL::completion.zsh {{{
zmodload -i zsh/complist

WORDCHARS=''

unsetopt menu_complete   # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu         # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end

bindkey -M menuselect '^o' accept-and-infer-next-history
zstyle ':completion:*:*:*:*:*' menu select

# case insensitive, partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are usable
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/zsh

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
        clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
        gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
        ldap lp mail mailman mailnull man messagebus mldonkey mysql nagios \
        named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
        operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
        rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
        usbmux uucp vcsa wwwrun xfs '_*'

# ... unless we really want to.
zstyle '*' single-ignored show

# automatically load bash completion functions
autoload -U +X bashcompinit && bashcompinit
# }}}

# direnv stays EAGER: tmux automation runs its first command before the
# first prompt renders, and that command relies on the direnv hook.
zinit from"gh-r" \
    mv"direnv* -> direnv" \
    atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' \
    pick"direnv" src="zhook.zsh" \
    as"program" \
    for \
    direnv/direnv

zinit as"command" lucid from"gh-r" for \
    id-as"usage" \
    atpull"%atclone" \
    jdx/usage
    #atload='eval "$(mise activate zsh)"' \

zinit as"command" wait'0' lucid from"gh-r" for \
    id-as"mise" mv"mise* -> mise" \
    atclone"./mise* completion zsh > _mise" \
    atpull"%atclone" \
    atload'eval "$(mise activate zsh)"' \
    jdx/mise

zinit lucid wait for \
    agkozak/zhooks

#}}}
# Common Directories -------------------{{{
dots=~/dots
hash -d dots=$dots
if [[ $OSTYPE == darwin* ]]; then
    hash -d itermscripts=~/Library/Application\ Support/iTerm2/Scripts
fi
hash -d zettel=~/vaults/zettel
#}}}
# Plugins Settings ---------------------{{{
# zsh-syntax-highlighting {{{
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
export ZSH_HIGHLIGHT_HIGHLIGHTERS
# -A: associative array the syntax-highlighting plugin reads, keyed by style name
typeset -A ZSH_HIGHLIGHT_STYLES
# }}}
#}}}
# zsh core settings --------------------{{{
# editor {{{
# bind UP and DOWN arrow keys
autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd v edit-command-line
bindkey -M vicmd q push-line
#}}}

# history {{{
HISTFILE=${HISTFILE:-"$HOME/.zsh_history"}
SAVEHIST=999999999
HISTSIZE=999999999

alias history='fc -il 1'

# man zshoptions
setopt append_history
setopt extended_history # have timestamps
setopt inc_append_history_time
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_fcntl_lock
setopt hist_no_store
setopt hist_ignore_space
setopt hist_lex_words
setopt hist_verify
setopt interactive_comments

unsetopt share_history

# }}}

setopt extendedglob
setopt multios              # redirect to multiple streams: echo >file1 >file2
setopt long_list_jobs       # verbose job notifications

# colors (was OMZL::theme-and-appearance.zsh)
autoload -U colors && colors
setopt prompt_subst

# paste safety (was OMZL::misc.zsh)
autoload -Uz url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

# directory navigation (was OMZL::directories.zsh)
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus
#}}}
# PATH ---------------------------------{{{
export XDG_CONFIG_HOME=$HOME/.config
#}}}
# Colors -------------------------------{{{
zinit ice atclone'dircolors -b ~/.dir_colors > clrs.zsh' \
    atpull'%atclone' pick"clrs.zsh" nocompile'!'
zinit light trapd00r/LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Use gnu's ls so don't need these lscolors
if [[ $OSTYPE == darwin* && -n $LSCOLORS ]]; then
  unset LSCOLORS
fi

#}}}
# Add tools {{{
# }}}
# Other files --------------------------{{{
source $HOME/.aliases.zsh

# Defer full theme until after first prompt renders (second precmd)
# Post-increment: (( 0++ )) is falsy on first call, truthy on second
# -g: global so it persists across precmd firings; -i: integer for (( ++ )).
typeset -gi _PROMPT_INIT=0
_init_full_prompt() {
    if (( _PROMPT_INIT++ )); then
        add-zsh-hook -d precmd _init_full_prompt
        source ~/.zsh_theme
        source ~/.zsh_fzf
        before_command  # Render full prompt immediately in this precmd
        # Ensure iterm2_precmd runs last so it decorates the PS1 set by before_command
        if (( ${+functions[iterm2_precmd]} )); then
            add-zsh-hook -d precmd iterm2_precmd
            precmd_functions+=( iterm2_precmd )
        fi
        unset _PROMPT_INIT
        unfunction _init_full_prompt
    fi
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _init_full_prompt
#}}}


# Tmux detection -----------------------{{{

fixssh() {
    if (( $+commands[tmux] )); then
    for key in SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT MACOS_MODE; do
        if (tmux show-environment | grep "^${key}" > /dev/null); then
            value=`tmux show-environment | grep "^${key}" | sed -e "s/^[A-Z_]*=//"`
            export ${key}="${value}"
        fi
    done
    fi
}

export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=yes
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

if [[ -n $TMUX ]]; then
    fixssh
fi
#}}}
# SSH Detection ------------------------{{{
export GPG_TTY=$TTY
if [[ -n "$SSH_CONNECTION" ]] ;then
    export PINENTRY_USER_DATA="USE_CURSES=1"
fi
# }}}

zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
        z-shell/F-Sy-H \
    as"completion" \
        zsh-users/zsh-completions \
        srijanshetty/zsh-pandoc-completion

# gitstatusd binary fetched from GitHub releases (checksummed) on first load
zinit ice wait'!' lucid atload'source ~/.zsh_theme_vars'
zinit load romkatv/gitstatus

# 1password-cli plugins ----------------{{{
# From https://1password.community/discussion/138575/zsh-plugin-aliases-break-completion-for-the-command-run-by-the-plugin
if (( $+commands[op] )); then
    function __my_op_plugin_run() {
        _op_plugin_run

        for ((i = 2; i < CURRENT; i++)); do
            if [[ ${words[i]} == -- ]]; then
                shift $i words
                ((CURRENT -= i))
                _normal
                return
            fi
        done

    }

    # Defer op completion loading until after first prompt
    zinit ice wait lucid id-as'op-completion' \
        atload'eval "$(op completion zsh | sed -E "s/^( +)_op_plugin_run/\1__my_op_plugin_run/")"'
    zinit snippet /dev/null
fi
# }}}


if [[ "$PROFILE_STARTUP" == true ]]; then
    unsetopt xtrace
    exec 2>&3 3>&-
fi
# zprof
