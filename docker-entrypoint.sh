#!/bin/sh
# Entrypoint da imagem Asterisk com sshd.
# Inicia o openssh-server e delega ao entrypoint original da imagem base
# (docker-asterisk), preservando o comportamento padrão do Asterisk.

set -eu

# --- Configuração do sshd ---

# Host keys (geradas na primeira subida)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  ssh-keygen -A >/dev/null 2>&1 || true
fi

# Usuário pbxctl: senha definida por env PBXCTL_PASSWORD
if [ -n "${PBXCTL_PASSWORD:-}" ]; then
  echo "pbxctl:${PBXCTL_PASSWORD}" | chpasswd
fi

# Chaves autorizadas via env PBXCTL_AUTHORIZED_KEYS (base64)
if [ -n "${PBXCTL_AUTHORIZED_KEYS:-}" ]; then
  echo "${PBXCTL_AUTHORIZED_KEYS}" | base64 -d > /home/pbxctl/.ssh/authorized_keys 2>/dev/null || \
    echo "${PBXCTL_AUTHORIZED_KEYS}" > /home/pbxctl/.ssh/authorized_keys
  chown -R pbxctl:pbxctl /home/pbxctl/.ssh
  chmod 700 /home/pbxctl/.ssh
  chmod 600 /home/pbxctl/.ssh/authorized_keys
fi

# Acesso de escrita do pbxctl em /etc/asterisk (para apply de configuração)
if [ -d /etc/asterisk ]; then
  chown -R :asterisk /etc/asterisk 2>/dev/null || true
  chmod -R g+rw /etc/asterisk 2>/dev/null || true
  chmod g+s /etc/asterisk 2>/dev/null || true
fi

# --- sshd ---
/usr/sbin/sshd || service ssh start || true

# --- Delega ao entrypoint da imagem base ---
BASE_ENTRYPOINT=""
for p in /docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh; do
  if [ -x "$p" ]; then
    BASE_ENTRYPOINT="$p"
    break
  fi
done

if [ -n "$BASE_ENTRYPOINT" ]; then
  exec "$BASE_ENTRYPOINT" "$@"
fi

# Fallback: roda o Asterisk diretamente no foreground
exec asterisk -f "$@"