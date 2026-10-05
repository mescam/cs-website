#!/usr/bin/env bash
# Pobranie kluczy hostów przez uwierzytelnione połączenie Vagranta.
set -euo pipefail
cd -- "$(dirname -- "$0")"
umask 077
mkdir -p .lab
: > .lab/known_hosts
for target in node-1 node-2; do
  case "$target" in
    node-1) address=192.168.56.11 ;;
    node-2) address=192.168.56.12 ;;
  esac
  host_key=$(vagrant ssh "$target" -c 'cat /etc/ssh/ssh_host_ed25519_key.pub' 2>/dev/null | tr -d '\r')
  if [[ "$host_key" != ssh-ed25519\ * ]]; then
    printf 'Nie udało się odczytać klucza %s\n' "$target" >&2
    exit 1
  fi
  printf '%s,%s %s\n' "$target" "$address" "$host_key" >> .lab/known_hosts
done
vagrant ssh control -c 'sudo -u student tee /home/student/.ssh/known_hosts >/dev/null' < .lab/known_hosts
printf 'Zaufane klucze obu węzłów zapisane na control.\n'
