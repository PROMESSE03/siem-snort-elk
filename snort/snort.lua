-- =============================================================================
--  snort.lua — Configuration Snort 3 pour le lab SIEM
--  Sortie : alert_json (une ligne JSON par alerte) -> /var/log/snort
-- =============================================================================

---------------------------------------------------------------------
-- 1. Variables réseau globales
---------------------------------------------------------------------
HOME_NET = '172.28.0.0/24'
EXTERNAL_NET = 'any'

---------------------------------------------------------------------
-- 2. Inspecteurs
--    stream + stream_tcp : réassemblage TCP (nécessaire à http_inspect)
--    http_inspect        : analyse HTTP (pour les règles d'injection SQL)
---------------------------------------------------------------------
stream = { }
stream_tcp = { }
http_inspect = { }

---------------------------------------------------------------------
-- 3. Binder : associe le trafic du port 80 à l'inspecteur HTTP
--    (sans ça, les règles http_uri ne s'attachent pas)
---------------------------------------------------------------------
binder =
{
    { when = { proto = 'tcp', ports = '80' }, use = { type = 'http_inspect' } }
}

---------------------------------------------------------------------
-- 4. Règles + déclaration des variables $HOME_NET / $EXTERNAL_NET
--    (c'est ICI que Snort 3 les rend utilisables dans les règles)
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
-- 5. Sortie JSON (lue par syslog-ng puis envoyée à Elasticsearch)
---------------------------------------------------------------------
alert_json =
{
    file = true,
    limit = 100,
    fields = 'timestamp proto src_addr src_port dst_addr dst_port msg sid rev gid priority class action dir iface'
}
