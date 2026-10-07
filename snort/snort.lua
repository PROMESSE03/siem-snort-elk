-- =============================================================================
--  snort.lua — Configuration Snort 3 pour le lab SIEM (lecture de captures .pcap)
--  Sortie : alert_json (une ligne JSON par alerte) -> /var/log/snort
-- =============================================================================

---------------------------------------------------------------------
-- Variables réseau pour les règles ($HOME_NET / $EXTERNAL_NET)
---------------------------------------------------------------------
HOME_NET = '172.28.0.0/24'
EXTERNAL_NET = 'any'

---------------------------------------------------------------------
-- Réassemblage TCP de base
---------------------------------------------------------------------
stream = { }
stream_tcp = { }

---------------------------------------------------------------------
-- Règles + déclaration des variables réseau
---------------------------------------------------------------------
ips =
{
    variables =
    {
        nets =
        {
            HOME_NET = '172.28.0.0/24',
            EXTERNAL_NET = 'any'
        }
    },
    rules = [[
        include /usr/local/etc/snort/rules/local.rules
    ]]
}

---------------------------------------------------------------------
-- Sortie JSON (lue par syslog-ng puis envoyée à Elasticsearch)
---------------------------------------------------------------------
alert_json =
{
    file = true,
    limit = 100,
    fields = 'timestamp proto src_addr src_port dst_addr dst_port msg sid rev gid priority class action dir iface'
}
