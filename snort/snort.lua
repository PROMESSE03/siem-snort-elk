-- =============================================================================
--  snort.lua — Configuration Snort 3 pour le lab SIEM
--  Sortie : alert_json (une ligne JSON par alerte) -> /var/log/snort
-- =============================================================================

---------------------------------------------------------------------
-- 1. Variables réseau
---------------------------------------------------------------------
HOME_NET = '172.28.0.0/24'
EXTERNAL_NET = '!$HOME_NET'

---------------------------------------------------------------------
-- 2. Chargement des règles
---------------------------------------------------------------------
ips =
{
    -- Mode IDS (détection seule). Pour de l'IPS, voir README (inline + reject).
    mode = tap,
    variables = default_variables,

    rules = [[
        include /usr/local/etc/snort/rules/local.rules
    ]]
}

---------------------------------------------------------------------
-- 3. Décodeurs et inspecteurs de base
---------------------------------------------------------------------
stream = { }
stream_tcp = { }
stream_udp = { }
stream_icmp = { }

http_inspect = { }

-- Normalisation pour que les règles http_uri fonctionnent
normalizer =
{
    tcp = { ips = true }
}

---------------------------------------------------------------------
-- 4. SORTIE : alert_json
--    Ce fichier est lu par syslog-ng puis envoyé vers Elasticsearch.
---------------------------------------------------------------------
alert_json =
{
    file = true,              -- écrit dans alert_json.txt
    limit = 100,              -- rotation à 100 Mo
    fields = 'timestamp seconds action class b64_data dir \
              dst_addr dst_ap dst_port eth_dst eth_len eth_src eth_type \
              gid icmp_code icmp_id icmp_seq icmp_type iface ip_id ip_len \
              msg mpls pkt_gen pkt_len pkt_num priority proto rev rule \
              service sid src_addr src_ap src_port target tcp_ack tcp_flags \
              tcp_len tcp_seq tcp_win tos ttl udp_len vlan'
}

-- On conserve aussi un flux console lisible pour le debug
alert_fast =
{
    file = true
}
