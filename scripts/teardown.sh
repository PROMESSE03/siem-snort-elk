#!/bin/bash
# =============================================================================
#  teardown.sh — arrête et nettoie la chaîne SIEM
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

PURGE="${1:-}"

echo "[*] Arrêt des conteneurs..."
if [ "$PURGE" = "--purge" ]; then
    echo "    (--purge : suppression des volumes et données)"
    docker compose down -v
else
    docker compose down
    echo "    Les volumes (données ES) sont conservés."
    echo "    Pour tout supprimer : ./scripts/teardown.sh --purge"
fi
echo "[+] Terminé."
