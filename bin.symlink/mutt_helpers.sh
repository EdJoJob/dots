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
  khard email -a "$from" -p "$query"
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
