#!/bin/bash
# =============================================================================
#  Scénario 3 — Déni de service (Ping flood / ICMP)
#  Déclenche le SID 1000020 côté Snort.
# =============================================================================
TARGET="${1:-172.28.0.40}"

echo "[*] Scénario 3 : ping flood ICMP sur ${TARGET}"
echo "    -> Envoi de 300 paquets ICMP en rafale"

# -f flood (nécessite NET_RAW, fourni au conteneur attacker)
# -c nombre de paquets
ping -f -c 300 "${TARGET}" || ping -i 0.01 -c 300 "${TARGET}"

echo "[+] Scénario 3 terminé."
