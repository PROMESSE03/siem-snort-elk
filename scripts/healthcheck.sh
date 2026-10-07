#!/bin/bash
# =============================================================================
#  healthcheck.sh — vérifie l'état de chaque composant de la chaîne
# =============================================================================
cd "$(dirname "$0")/.."

echo "=== État des conteneurs ==="
docker compose ps

echo
echo "=== Elasticsearch ==="
curl -s http://localhost:9200/_cluster/health?pretty || echo "  injoignable"

echo
echo "=== Index d'alertes Snort ==="
curl -s "http://localhost:9200/_cat/indices/snort-alerts-*?v" || echo "  aucun index"

echo
echo "=== Nombre d'alertes indexées ==="
curl -s "http://localhost:9200/snort-alerts-*/_count?pretty" || true

echo
echo "=== Logs récents ElastAlert2 (10 lignes) ==="
docker logs --tail 10 siem-elastalert 2>/dev/null || echo "  conteneur absent"
