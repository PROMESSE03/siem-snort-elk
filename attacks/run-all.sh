#!/bin/bash
# =============================================================================
#  Joue les 4 scénarios d'attaque à la suite, avec une pause entre chacun
#  pour laisser le temps aux alertes de remonter dans Kibana/Slack.
# =============================================================================
TARGET="${1:-172.28.0.40}"
HERE="$(dirname "$0")"

echo "============================================================"
echo "  Lancement des 4 scénarios d'attaque  — cible ${TARGET}"
echo "============================================================"

bash "${HERE}/01-nmap-scan.sh"     "${TARGET}"; sleep 10
bash "${HERE}/02-ssh-bruteforce.sh" "${TARGET}"; sleep 10
bash "${HERE}/03-ping-flood.sh"    "${TARGET}"; sleep 10
bash "${HERE}/04-sql-injection.sh" "${TARGET}"; sleep 5

echo "============================================================"
echo "  Tous les scénarios ont été joués."
echo "  -> Vérifiez Kibana  : http://localhost:5601"
echo "  -> Vérifiez Slack   : canal configuré"
echo "============================================================"
