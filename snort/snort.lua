-- =============================================================================
--  snort.lua — Configuration Snort 3 pour le lab SIEM
--  Sortie : alert_json (une ligne JSON par alerte) -> /var/log/snort
-- =============================================================================

---------------------------------------------------------------------
-- 1. Variables réseau (lues directement par le moteur de règles)
---------------------------------------------------------------------
HOME_NET = '172.28.0.0/24'
EXTERNAL_NET = 'any'

---------------------------------------------------------------------
-- 2. Inspecteurs de base (nécessaires aux options flow/http des règles)
---------------------------------------------------------------------
stream = { }
stream_tcp = { }
stream_udp = { }
stream_icmp = { }
http_inspect = { }

---------------------------------------------------------------------
-- 3. Chargement des règles personnalisées
---------------------------------------------------------------------
ips =
{
    rules = [[
        include /usr/local/etc/snort/rules/local.rules
    ]]
}

---------------------------------------------------------------------
-- 4. SORTIE : alert_json
--    Ce fichier (alert_json.txt) est lu par syslog-ng puis envoyé à ES.
---------------------------------------------------------------------
alert_json =
{
    file = true,
    limit = 100,
    fields = 'timestamp proto src_addr src_port dst_addr dst_port \
              msg sid rev gid priority class action dir iface'
}
