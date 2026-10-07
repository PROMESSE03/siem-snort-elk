# 📘 Guide d'implémentation pas à pas

Ce guide monte la chaîne SIEM **maillon par maillon**, en vérifiant chaque étape
avant de passer à la suivante. C'est la bonne méthode pour comprendre le rôle de
chaque composant et savoir isoler un problème.

> Principe : la donnée circule dans ce sens →
> **Snort** (détecte) → **syslog-ng** (transporte) → **Elasticsearch** (stocke) →
> **Kibana** (montre) / **ElastAlert2** (alerte Slack).
> On construit donc d'abord le magasin (ES), puis on remonte vers le capteur.

---

## Étape 0 — Préparer la machine

**But :** réunir les prérequis avant de lancer quoi que ce soit.

```bash
# Docker + Compose v2 installés ?
docker --version && docker compose version

# Elasticsearch exige cette limite mémoire noyau (sinon il redémarre en boucle)
sudo sysctl -w vm.max_map_count=262144
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Récupérer le projet et configurer le webhook Slack
cd siem-lab
cp .env.example .env
nano .env            # coller votre SLACK_WEBHOOK_URL
```

**Comment créer le webhook Slack :** https://api.slack.com/apps → *Create New App* →
*Incoming Webhooks* → *Activate* → *Add New Webhook to Workspace* → choisir le canal →
copier l'URL `https://hooks.slack.com/services/...` dans `.env`.

✅ **Attendu :** `.env` contient une vraie URL Slack, `vm.max_map_count` = 262144.

---

## Étape 1 — Elasticsearch (le magasin)

**Rôle :** base de données qui indexe et stocke chaque alerte. Tout finit ici,
donc on le démarre en premier.

```bash
docker compose up -d elasticsearch

# Attendre ~30-60 s puis vérifier la santé du cluster
curl http://localhost:9200/_cluster/health?pretty
```

✅ **Attendu :** un JSON avec `"status" : "green"` (ou `"yellow"`, normal en mono-nœud).
❌ **Si ça redémarre en boucle :** `vm.max_map_count` trop bas (revoir l'étape 0) ou RAM insuffisante.

---

## Étape 2 — Le mapping d'index

**Rôle :** dire à Elasticsearch le *type* de chaque champ (`src_addr` = IP,
`@timestamp` = date, `sid` = mot-clé). Sans ça, Kibana ne peut pas filtrer par IP
ni tracer de courbe temporelle correcte.

```bash
curl -X PUT "http://localhost:9200/_index_template/snort-alerts" \
     -H 'Content-Type: application/json' \
     -d @kibana/es-index-template.json
```

✅ **Attendu :** `{"acknowledged":true}`.

---

## Étape 3 — Kibana (les yeux)

**Rôle :** interface web qui *lit* Elasticsearch. Ne produit aucune donnée.

```bash
docker compose up -d kibana
# Démarrage long (~90 s). Vérifier :
curl -s http://localhost:5601/api/status | grep -o '"level":"available"'
```

Puis importer la *data view* + le dashboard :

```bash
curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
     -H "kbn-xsrf: true" \
     --form file=@kibana/dashboard.ndjson
```

✅ **Attendu :** ouvrir http://localhost:5601 → *Dashboard* → « SIEM — Tableau de bord Snort »
existe (vide pour l'instant, c'est normal : aucune alerte n'a encore été générée).

---

## Étape 4 — syslog-ng (le facteur)

**Rôle :** lit le fichier d'alertes JSON de Snort et l'expédie vers Elasticsearch
via l'API `_bulk`. C'est le tuyau entre le capteur et le magasin (il remplace Logstash).

```bash
docker compose up -d syslog-ng
docker logs siem-syslog-ng          # doit démarrer sans erreur de config
```

✅ **Attendu :** pas d'erreur fatale dans les logs. (Il n'enverra rien tant que
Snort n'a pas écrit d'alerte — c'est l'étape suivante.)

---

## Étape 5 — Snort 3 (le capteur)

**Rôle :** écoute le trafic du réseau Docker, applique les règles de `local.rules`,
et écrit une ligne JSON par alerte dans `/var/log/snort/alert_json.txt`.
C'est ici que vivent tes 4 scénarios, chacun avec son SID.

```bash
docker compose up -d --build snort
docker logs siem-snort              # doit afficher "Commencing packet processing"
```

✅ **Attendu :** Snort démarre et écoute `eth0`.
🔎 **Comprendre les règles :** ouvre `snort/local.rules`. Chaque règle suit la forme
`alert <proto> <src> -> <dst> ( msg:"..."; <conditions>; sid:<num>; )`.
Le `detection_filter` (ex. « 20 SYN en 5 s ») évite de crier au scan dès le 1er paquet.

---

## Étape 6 — ElastAlert2 (la sentinelle)

**Rôle :** interroge Elasticsearch toutes les minutes ; si une règle correspond,
pousse une notification Slack. Lit les règles de `elastalert/rules/`.

```bash
docker compose up -d elastalert
docker logs -f siem-elastalert      # voir les requêtes passer
```

✅ **Attendu :** logs du type `Ran <règle> ... 0 matches` (0 pour l'instant, normal).
❌ **Pas de Slack plus tard :** vérifier `SLACK_WEBHOOK_URL` dans `.env` et ces logs.

---

## Étape 7 — La cible et l'attaquant

**Rôle :** `target` = victime (SSH + serveur web) ; `attacker` = boîte à outils
(nmap, hydra, ping, curl). Ils servent à générer du trafic malveillant réaliste.

```bash
docker compose up -d --build target attacker
docker compose ps                   # les 7 services doivent être "running"
```

✅ **Attendu :** 7 conteneurs actifs.

---

## Étape 8 — Jouer les attaques et suivre la donnée

On valide toute la chaîne, scénario par scénario.

```bash
# Scénario 1 : scan de ports
docker exec -it siem-attacker bash /attacks/01-nmap-scan.sh
```

Après CHAQUE attaque, suivre la donnée à travers les maillons :

```bash
# 1) Snort a-t-il détecté ?  (capteur)
docker exec siem-snort tail /var/log/snort/alert_json.txt

# 2) syslog-ng a-t-il transmis ?  (ES compte les alertes)
curl "http://localhost:9200/snort-alerts-*/_count?pretty"

# 3) Kibana le montre-t-il ?  -> rafraîchir le dashboard (http://localhost:5601)

# 4) Slack a-t-il reçu l'alerte ?  -> regarder le canal
```

Puis enchaîner les autres scénarios :

```bash
docker exec -it siem-attacker bash /attacks/02-ssh-bruteforce.sh
docker exec -it siem-attacker bash /attacks/03-ping-flood.sh
docker exec -it siem-attacker bash /attacks/04-sql-injection.sh
# ou tout d'un coup :
docker exec -it siem-attacker bash /attacks/run-all.sh
```

✅ **Attendu final :** le compteur ES augmente, le dashboard se remplit, Slack reçoit
les alertes critiques (brute-force, DoS, injection SQL).

**Table de correspondance pour le débogage :**

| Je vois... | ...mais pas... | Le problème est entre |
|------------|----------------|------------------------|
| rien dans `alert_json.txt` | — | Snort / les règles / l'interface réseau |
| des lignes JSON | ES compte 0 | syslog-ng → Elasticsearch |
| ES compte > 0 | rien dans Kibana | data view / plage de temps du dashboard |
| tout dans Kibana | pas de Slack | ElastAlert2 / webhook `.env` |

---

## Étape 9 — Arrêt

```bash
./scripts/teardown.sh            # arrête, conserve les données ES
./scripts/teardown.sh --purge    # supprime tout (volumes compris)
```

---

## 🧠 Ce qu'il faut retenir

- **Snort** décide *ce qui est une attaque* (les règles = l'intelligence du système).
- **syslog-ng** ne décide rien : il transporte fidèlement.
- **Elasticsearch** rend la donnée *cherchable*.
- **Kibana** la rend *compréhensible* (humain).
- **ElastAlert2** la rend *actionnable en temps réel* (Slack).

Chaque composant a une seule responsabilité — c'est ce qui rend la chaîne robuste
et débogable maillon par maillon.
