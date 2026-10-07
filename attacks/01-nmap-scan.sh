#!/bin/bash
# =============================================================================
#  Scénario 1 — Scan de ports (Nmap)
#  Déclenche les SID 1000001/1000002/1000003 côté Snort.
# =============================================================================
TARGET="${1:-172.28.0.40}"

echo "[*] Scénario 1 : scan de ports Nmap sur ${TARGET}"

echo "    -> Scan SYN rapide (détection SID 1000001)"
nmap -sS -T4 -p 1-1000 "${TARGET}"

echo "    -> Scan NULL furtif (détection SID 1000002)"
nmap -sN -T4 -p 1-200 "${TARGET}"

echo "    -> Scan XMAS (détection SID 1000003)"
nmap -sX -T4 -p 1-200 "${TARGET}"

echo "[+] Scénario 1 terminé."
