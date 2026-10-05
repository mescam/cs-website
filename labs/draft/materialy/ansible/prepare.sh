#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
umask 077
mkdir -p .lab
if [[ ! -f .lab/id_ed25519 ]]; then
  ssh-keygen -q -t ed25519 -N '' -C zsr-ansible -f .lab/id_ed25519
elif [[ ! -f .lab/id_ed25519.pub ]]; then
  ssh-keygen -y -f .lab/id_ed25519 > .lab/id_ed25519.pub
fi
printf 'Klucz środowiska gotowy. Następnie: vagrant up\n'
