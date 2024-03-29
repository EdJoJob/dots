#!/usr/bin/env bash

# from https://raw.githubusercontent.com/kmARC/dotfiles/master/bin/mutt_helpers.sh

set -Eeuo pipefail

trap "echo Error in: \${FUNCNAME:-top level}, line \${LINENO}" ERR

function _query_keychain() {
  local service="$1"
  local account="$2"
  if [[ $(uname) == "Darwin"* ]]; then
    security find-generic-password -w -s "$service" -a "$account"
  else
    secret-tool lookup "$service" "$account"
  fi
}

function save_pass() {
    local kind=$1
    local from=$2
    if [[ $(uname) == "Darwin"* ]]; then
        echo "Account User"
        security add-generic-password -U -s "${kind}-username" -a "$from" -l "${kind}-user-${from}" -w
        echo "Account Password"
        security add-generic-password -U -s "${kind}-pass" -a "$from" -l "${kind}-pass-${from}" -w
    else
        echo "Account User"
        secret-tool store -l "${kind}-user-${from}" "${kind}-username" "$from"
        echo "Account Password"
        secret-tool store -l "${kind}-pass-${from}" "${kind}-pass" "$from"
    fi
}

function mailboxes() {
  local from=$1
  echo -n "'=INBOX' "
  find "$HOME/.mutt/$from" -type d -name cur ! -wholename '*INBOX*' | sort | sed "s#\(.*\)/\(.*\)/cur#'=\2' #g" | tr -d '\n'
}

function smtp_pass() {
  local kind="$1"
  local from="$2"
  _query_keychain "$kind"-pass "$from"
}

function query_command() {
  local kind="$1"
  local from="$2"
  local query="$3"
  local pass
  local username
  if [[ "$kind" == "owa" ]]; then
    pass=$(smtp_pass "$kind" "$from")
    username=$(my_username "$kind" "$from")
    echo ""
    ldapsearch -H ldap://localhost:1389 \
               -x \
               -D"$username" \
               -w"$pass" \
               -b 'ou=people' \
               "(|(sn=$query*)(mail=$query*)(givenName=$query*))" \
               'mail' \
               'title' \
      | awk -F': ' \
            '/^uid/{uid=$2; getline; mail=$2; getline; title=$2; printf("%s\t%s\t%s\n",tolower(mail),uid,title)}'
  else
    khard email -a "$from" -p "$query"
  fi
}

function my_username() {
  local kind="$1"
  local from="$2"
  if [[ "$kind" == "owa" ]]; then
    _query_keychain "$kind"-username "$from"
  else
    echo "$from"
  fi
}

$1 "${@:2}"
