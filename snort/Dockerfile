# =============================================================================
#  Snort 3 — image de détection pour le lab SIEM
# =============================================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Snort 3 est packagé dans Ubuntu 22.04+ (snort3)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        snort3 \
        iproute2 \
        iputils-ping \
        tcpdump \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Répertoires attendus
RUN mkdir -p /usr/local/etc/snort/rules /var/log/snort

# Vérifie que le binaire répond (build-time sanity check)
RUN snort --version || true

WORKDIR /usr/local/etc/snort

# Le réseau Docker doit être prêt avant que Snort attache l'interface.
# La commande réelle est fournie par docker-compose (command:).
CMD ["snort", "--version"]
