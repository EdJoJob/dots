#!/usr/bin/env zsh
# ~/.claude/statusline.sh
# Two-line Claude Code statusline, styled after the adam2 zsh theme
# (~/dots/zsh/zsh_theme). Runs under zsh and emits its output through
# `print -P`, so zsh prompt escapes (%F{}, %B, %{..%}) are expanded natively.
#
# Session data comes from the JSON on stdin
# (schema: https://code.claude.com/docs/en/statusline). The git segment is the
# REAL zsh-git-prompt `git_super_status` — byte-identical to the interactive
# prompt (branch, upstream, ahead/behind, staged/changed/untracked, stash,
# clean, merge/rebase/bisect). aws/venv/nvm mirror the theme's $RPROMPT_CMDS.
#
#   line 1:  <workdir>  [model|effort|⚡][venv][git]
#   line 2:  <context-bar> NN% NNk  [agent][#pr]
#
# Box segments carry no internal/inter-segment padding; whitespace precedes a
# run only. Set CC_STATUSLINE_DEBUG=/path to dump the raw stdin payload.

emulate -L zsh
# prompt_percent enables %-escapes; NO prompt_subst (would execute $(...) /
# backticks embedded in paths or branch names during print -P).
setopt prompt_percent no_prompt_subst no_prompt_bang

input="$(cat)"
[[ -n ${CC_STATUSLINE_DEBUG:-} ]] && print -r -- "$input" > "$CC_STATUSLINE_DEBUG" 2>/dev/null
jqf() { print -r -- "$input" | jq -r "$1 // empty" 2>/dev/null }
pq()  { print -rn -- "${1//\%/%%}" }   # escape literal % for prompt expansion

# --- prompt-escape colours (mirror zsh_theme_vars) -------------------------
RST='%b%f'
OB='%B%F{black}[%b%f'; CB='%B%F{black}]%b%f'; SEP='%B%F{black}|%b%f'
C_DIR='%F{green}'; C_MODEL='%F{12}'; C_EFFORT='%F{245}'; C_FAST='%B%F{yellow}'
C_AWS='%F{214}'; C_VENV='%F{27}'; C_NVM='%F{112}'
C_AGENT='%F{213}'; C_PR='%F{39}'; C_DIM='%F{240}'

# theme env indicator: [|value]  (PREFIX '[' + SEPARATOR '|' + colour + SUFFIX ']')
envseg() { print -rn -- "%B%F{black}[|%b%f${2}$(pq "$1")${RST}%B%F{black}]%b%f" }

# =====================  LINE 1  ============================================
cwd="$(jqf '.workspace.current_dir')"; [[ -z $cwd ]] && cwd="$(jqf '.cwd')"; [[ -z $cwd ]] && cwd="$PWD"
disp="$cwd"; [[ $disp == $HOME* ]] && disp="~${disp#$HOME}"
L1="${C_DIR}$(pq "$disp")${RST}"

run=""  # continuous run of box-wrapped segments (no inter-segment padding)

# model segment: [model|effort|⚡]
model="$(jqf '.model.display_name')"
effort="$(jqf '.effort.level')"
fast="$(jqf '.fast_mode')"
if [[ -n $model ]]; then
  mseg="${C_MODEL}$(pq "$model")${RST}"
  [[ -n $effort ]] && mseg+="${SEP}${C_EFFORT}$(pq "$effort")${RST}"
  [[ $fast == true ]] && mseg+="${SEP}${C_FAST}⚡${RST}"
  run+="${OB}${mseg}${CB}"
fi

# aws-profile / in-virtualenv / nvm-version (env vars, mirrors $RPROMPT_CMDS)
[[ -n ${AWS_PROFILE:-} ]] && run+="$(envseg "$AWS_PROFILE" "$C_AWS")"
if [[ -n ${VIRTUAL_ENV:-} ]]; then
  venv="${VIRTUAL_ENV:t}"; [[ $venv == env ]] && venv="${VIRTUAL_ENV:h:t}"
  run+="$(envseg "$venv" "$C_VENV")"
fi

# git: the real zsh-git-prompt git_super_status, expanded via print -P.
# Refresh vars first (the interactive prompt does this in a precmd hook).
gitseg=""
gpdir=""; for c in ~/.zi/plugins/*zsh-git-prompt*/zshrc.sh; do [[ -f $c ]] && gpdir="$c"; done
if [[ -n $gpdir ]] && builtin cd -q "$cwd" 2>/dev/null; then
  source "$gpdir" 2>/dev/null
  [[ -f ~/dots/zsh/zsh_theme_vars ]] && source ~/dots/zsh/zsh_theme_vars 2>/dev/null
  update_current_git_vars 2>/dev/null
  gitseg="$(git_super_status 2>/dev/null)"   # already contains prompt escapes
fi
run+="$gitseg"

[[ -n $run ]] && L1+="  ${run}"

# =====================  LINE 2  ============================================
# context usage bar: solid used portion (green→yellow→red) + dotted remainder,
# followed by the percentage and the absolute context occupancy in k-tokens.
pct="$(jqf '.context_window.used_percentage')"
tot="$(jqf '.context_window.total_input_tokens')"
size="$(jqf '.context_window.context_window_size')"
pct="${pct%%.*}"; tot="${tot%%.*}"; size="${size%%.*}"   # ints only; <-> = all digits
[[ $pct  == <-> ]] || pct=""
[[ $tot  == <-> ]] || tot=""
[[ $size == <-> && $size != 0 ]] || size=""
[[ -z $pct && -n $tot && -n $size ]] && pct=$(( tot * 100 / size ))
[[ -z $pct ]] && pct=0
(( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
W=12
filled=$(( pct * W / 100 )); empty=$(( W - filled ))
if   (( pct >= 85 )); then barcol='%B%F{red}'
elif (( pct >= 60 )); then barcol='%B%F{yellow}'
else barcol='%B%F{green}'; fi
bar="${barcol}${(l:filled::█:):-}${C_DIM}${(l:empty::░:):-}${RST}"
L2="ctx:${bar} ${barcol}${pct}%%${RST}"

# k-tokens: absolute occupancy (input + cache_creation + cache_read, per the
# statusline schema). Rendered only when reported, never derived from the
# already-rounded percentage, so the figure is never fabricated precision.
if [[ -n $tot ]]; then
  if (( tot >= 1000000 )); then ktok="$(printf '%.1fM' $(( tot / 1000000.0 )))"
  else                          ktok="$(( (tot + 500) / 1000 ))k"; fi
  L2+=" ${C_DIM}${ktok}${RST}"
fi

# boxed run: [agent][#pr]  (no padding within/between; whitespace only before)
brun=""
agent="$(jqf '.agent.name')"
[[ -n $agent ]] && brun+="${OB}${C_AGENT}$(pq "$agent")${RST}${CB}"
pr_num="$(jqf '.pr.number')"; pr_url="$(jqf '.pr.url')"
if [[ -n $pr_num ]]; then
  if [[ -n $pr_url ]]; then
    link="%{\e]8;;$(pq "$pr_url")\a%}#${pr_num}%{\e]8;;\a%}"
    brun+="${OB}${C_PR}${link}${RST}${CB}"
  else
    brun+="${OB}${C_PR}#${pr_num}${RST}${CB}"
  fi
fi
[[ -n $brun ]] && L2+="  ${brun}"

# Sourcing the git-prompt plugin turns PROMPT_SUBST back on; disable it again
# so print -P does NOT run $(...) / backticks embedded in paths or branch names.
setopt no_prompt_subst
print -nP -- "$L1 $L2"
# print -nP -- "$L2"
