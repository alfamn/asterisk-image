# Imagem Asterisk para o SaaS Ideal — adiciona openssh-server para o
# backend IdealPBX aplicar configurações (preview/apply/rollback) via SSH.
# Base: andrius/asterisk (mesma estrutura do docker-asterisk oficial).
FROM andrius/asterisk:22.10.1_debian-trixie

LABEL org.opencontainers.image.source="https://github.com/alfamn/asterisk-image"
LABEL org.opencontainers.image.description="Asterisk 22.10.1 com openssh-server para o IdealPBX"

# openssh-server + sudo (o usuário pbxctl escreve em /etc/asterisk)
RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server \
        sudo \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd \
    && mkdir -p /home/pbxctl/.ssh

# Usuário dedicado para o backend aplicar configurações
RUN useradd -m -s /bin/bash -G asterisk pbxctl \
    && echo "pbxctl ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/pbxctl \
    && chmod 440 /etc/sudoers.d/pbxctl

COPY docker-entrypoint.sh /usr/local/bin/issabel-sshd-entrypoint.sh
RUN chmod +x /usr/local/bin/issabel-sshd-entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/issabel-sshd-entrypoint.sh"]
CMD ["-f"]