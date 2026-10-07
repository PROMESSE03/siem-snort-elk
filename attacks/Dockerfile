# =============================================================================
#  Attacker — conteneur outillé pour jouer les scénarios d'attaque du lab
# =============================================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nmap \
        hydra \
        iputils-ping \
        curl \
        iproute2 \
        netcat-openbsd \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /attacks
CMD ["sleep", "infinity"]
