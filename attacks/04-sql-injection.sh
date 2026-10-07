#!/bin/bash
# =============================================================================
#  Scénario 4 — Injection SQL (web)
#  Déclenche les SID 1000030/1000031/1000032 côté Snort.
# =============================================================================
TARGET="${1:-172.28.0.40}"
BASE="http://${TARGET}/index.php"

echo "[*] Scénario 4 : injections SQL sur ${BASE}"

echo "    -> UNION SELECT (SID 1000030)"
curl -s -G "${BASE}" --data-urlencode "id=1 union select username,password from users" -o /dev/null

echo "    -> OR 1=1 (SID 1000031)"
curl -s -G "${BASE}" --data-urlencode "id=1 or 1=1" -o /dev/null

echo "    -> Commentaire SQL (SID 1000032)"
curl -s -G "${BASE}" --data-urlencode "id=admin'--" -o /dev/null

echo "[+] Scénario 4 terminé."
