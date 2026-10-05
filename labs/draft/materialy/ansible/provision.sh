#!/usr/bin/env bash
set -euo pipefail
role=${1:?Podaj rolę maszyny}
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python3 sudo openssh-server curl
if ! id student >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash student
fi
install -d -m 0700 -o student -g student /home/student/.ssh
install -m 0600 -o student -g student /tmp/zsr-key.pub /home/student/.ssh/authorized_keys
printf 'student ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/zsr-student
chmod 0440 /etc/sudoers.d/zsr-student
visudo -cf /etc/sudoers.d/zsr-student
if [[ "$role" == control ]]; then
  apt-get install -y ansible nano
  install -m 0600 -o student -g student /tmp/zsr-key /home/student/.ssh/id_ed25519
  install -d -m 0755 -o student -g student /home/student/zsr-ansible
  # Usunięcie wyłącznie kopii klucza w katalogu transferowym VM.
  rm -f /tmp/zsr-key
fi
rm -f /tmp/zsr-key.pub
