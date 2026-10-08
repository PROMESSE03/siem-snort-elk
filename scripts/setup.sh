#!/bin/bash
# =============================================================================
#  setup.sh — démarre toute la chaîne SIEM et charge la config Kibana
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo "  Déploiement de la chaîne SIEM"
echo "============================================================"

# --- 1. Vérification du fichier .env ----------------------------------------
if [ ! -f .env ]; then
    echo "[!] Fichier .env manquant."
    echo "    Copie de .env.example -> .env"
    cp .env.example .env
    echo "    >>> Éditez .env pour renseigner SLACK_WEBHOOK_URL, puis relancez."
    exit 1
fi

# --- 2. Build + démarrage ----------------------------------------------------
echo "[*] Construction et démarrage des conteneurs..."
docker compose up -d --build

# --- 3. Attente d'Elasticsearch ---------------------------------------------
echo "[*] Attente d'Elasticsearch (http://localhost:9200)..."
until curl -s http://localhost:9200/_cluster/health >/dev/null 2>&1; do
    printf '.'; sleep 3
done
echo " OK"

# --- 4. Création du template d'index ----------------------------------------
echo "[*] Application du template d'index Elasticsearch..."
curl -s -X PUT "http://localhost:9200/_index_template/snort-alerts" \
     -H 'Content-Type: application/json' \
     -d @kibana/es-index-template.json >/dev/null && echo "    template appliqué."

# --- 5. Attente de Kibana ----------------------------------------------------
echo "[*] Attente de Kibana (http://localhost:5601)..."
until curl -s http://localhost:5601/api/status | grep -q '"level":"available"' 2>/dev/null; do
    printf '.'; sleep 5
done
echo " OK"

# --- 6. Import du dashboard Kibana ------------------------------------------
echo "[*] Import de la data view et du dashboard Kibana..."
curl -s -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
     -H "kbn-xsrf: true" \
     --form file=@kibana/dashboard.ndjson >/dev/null && echo "    dashboard importé."

echo "============================================================"
echo "  Chaîne SIEM prête."
echo "    - Kibana    : http://localhost:5601  (Dashboard « SIEM — Tableau de bord Snort »)"
echo "    - ES        : http://localhost:9200"
echo "  Pour jouer les attaques :"
echo "    docker exec -it siem-attacker bash /attacks/run-all.sh"
echo "============================================================"
