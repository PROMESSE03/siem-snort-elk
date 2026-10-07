# 🛡️ Chaîne SIEM — Détection d'intrusions

**Système de détection d'anomalies basé sur un IDS/IPS et la pile Elasticsearch / Kibana**

Projet de laboratoire mettant en place une chaîne complète de **détection, collecte, visualisation et notification** des événements de sécurité à partir de scénarios d'attaques simulées.

---

## 📋 Table des matières

1. [Architecture](#-architecture)
2. [Technologies](#-technologies)
3. [Prérequis](#-prérequis)
4. [Démarrage rapide](#-démarrage-rapide)
5. [Scénarios d'attaque](#-scénarios-dattaque)
6. [Visualisation dans Kibana](#-visualisation-dans-kibana)
7. [Alertes Slack](#-alertes-slack)
8. [Structure du projet](#-structure-du-projet)
9. [Dépannage](#-dépannage)
10. [Pistes d'amélioration](#-pistes-daméliration)
11. [Avertissement](#-avertissement)

---

## 🏗 Architecture

```
┌──────────────┐   trafic    ┌──────────────┐   alert_json    ┌──────────────┐
│  ATTACKER    │────────────▶│   SNORT 3    │────────────────▶│  syslog-ng   │
│ nmap, hydra  │   réseau    │   IDS/IPS    │  (fichier JSON) │  collecte &  │
│ ping, curl   │  172.28.0/24│  détection   │                 │   parsing    │
└──────────────┘             └──────────────┘                 └──────┬───────┘
       │                            ▲                                 │ HTTP _bulk
       │ attaque                    │ observe                         ▼
       ▼                            │                          ┌──────────────┐
┌──────────────┐                    │                          │ELASTICSEARCH │
│   TARGET     │────────────────────┘                          │ indexation & │
│ SSH + Apache │                                               │  recherche   │
└──────────────┘                                               └──────┬───────┘
                                                                      │
                                        ┌─────────────────────────────┼──────────┐
                                        ▼                             ▼          
                                 ┌──────────────┐             ┌──────────────┐
                                 │ ELASTALERT2  │             │   KIBANA     │
                                 │  règles →    │             │ dashboards & │
                                 │   Slack      │             │ exploration  │
                                 └──────┬───────┘             └──────────────┘
                                        │ webhook
                                        ▼
                                 ┌──────────────┐
                                 │    SLACK     │
                                 │ alertes temps│
                                 │     réel     │
                                 └──────────────┘
```

**Flux de données :**

| Étape | Composant | Rôle |
|-------|-----------|------|
| 1 | **Snort 3** | Analyse le trafic réseau, applique les règles, écrit une alerte JSON par événement |
| 2 | **syslog-ng** | Lit le fichier d'alertes, parse le JSON, envoie vers Elasticsearch (API `_bulk`) |
| 3 | **Elasticsearch** | Indexe les alertes (`snort-alerts-AAAA.MM.JJ`), permet la recherche |
| 4 | **Kibana** | Visualise les alertes dans des dashboards personnalisés |
| 5 | **ElastAlert2** | Interroge ES toutes les minutes et pousse les alertes critiques vers Slack |

> **Pourquoi pas Logstash ?** La destination `elasticsearch-http()` de syslog-ng envoie directement en JSON vers l'API `_bulk` : un composant de moins à maintenir.

> **Pourquoi ElastAlert2 et non le connecteur Slack de Kibana ?** Le connecteur natif de Kibana nécessite une licence commerciale. ElastAlert2 est open-source et couvre parfaitement le besoin.

---

## 🧰 Technologies

| Outil | Version | Rôle |
|-------|---------|------|
| Snort | 3.x | IDS/IPS — détection des intrusions |
| syslog-ng | 4.8 | Collecte et transport des logs |
| Elasticsearch | 8.15.3 | Indexation et recherche |
| Kibana | 8.15.3 | Visualisation et dashboards |
| ElastAlert2 | 2.21 | Moteur d'alerte → Slack |
| Docker Compose | v2 | Orchestration de l'ensemble |

---

## ✅ Prérequis

- **Docker** et **Docker Compose v2** installés
- **4 Go de RAM** disponibles au minimum (Elasticsearch en réclame une bonne part)
- Un **webhook entrant Slack** ([créer une app Slack](https://api.slack.com/messaging/webhooks))
- Sous Linux, augmenter la limite mémoire pour Elasticsearch :

```bash
sudo sysctl -w vm.max_map_count=262144
# Pour rendre permanent :
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
```

---

## 🚀 Démarrage rapide

```bash
# 1. Configurer le webhook Slack
cp .env.example .env
nano .env          # renseigner SLACK_WEBHOOK_URL

# 2. Démarrer toute la chaîne (build + up + config Kibana automatique)
./scripts/setup.sh

# 3. Jouer les 4 scénarios d'attaque
docker exec -it siem-attacker bash /attacks/run-all.sh

# 4. Observer les résultats
#    - Kibana : http://localhost:5601  -> Dashboard « SIEM — Tableau de bord Snort »
#    - Slack  : votre canal configuré

# 5. Vérifier l'état à tout moment
./scripts/healthcheck.sh

# 6. Tout arrêter
./scripts/teardown.sh            # conserve les données
./scripts/teardown.sh --purge    # supprime tout
```

---

## ⚔️ Scénarios d'attaque

Chaque scénario est associé à une ou plusieurs règles Snort identifiables par leur **SID**.

| # | Scénario | Outil | SID Snort | Règle ElastAlert |
|---|----------|-------|-----------|------------------|
| 1 | **Scan de ports** | `nmap` | 1000001-1000003 | `01-nmap-scan.yaml` |
| 2 | **Brute-force SSH** | `hydra` | 1000010 | `02-ssh-bruteforce.yaml` |
| 3 | **Déni de service ICMP** | `ping -f` | 1000020 | `03-ping-flood.yaml` |
| 4 | **Injection SQL** | `curl` | 1000030-1000032 | `04-sql-injection.yaml` |

**Jouer un scénario isolé :**

```bash
docker exec -it siem-attacker bash /attacks/01-nmap-scan.sh
docker exec -it siem-attacker bash /attacks/02-ssh-bruteforce.sh
docker exec -it siem-attacker bash /attacks/03-ping-flood.sh
docker exec -it siem-attacker bash /attacks/04-sql-injection.sh
```

La cible par défaut est `172.28.0.40` (conteneur `target`). On peut passer une autre IP en argument.

---

## 📊 Visualisation dans Kibana

Le dashboard **« SIEM — Tableau de bord Snort »** est importé automatiquement et contient :

- **Alertes dans le temps** — histogramme temporel des détections
- **Alertes par type** — répartition par signature
- **Top IP sources attaquantes** — tableau des sources les plus actives
- **Répartition par priorité** — proportion d'alertes critiques / moyennes

**Explorer les données brutes :** Kibana → *Discover* → data view `snort-alerts-*`.

Exemples de requêtes KQL :

```
snort.sid : 1000010                         # uniquement le brute-force SSH
snort.priority <= 1                          # alertes critiques
snort.src_addr : "172.28.0.30"               # tout ce qui vient de l'attaquant
snort.msg : *Injection*                      # toutes les injections SQL
```

---

## 🔔 Alertes Slack

Dès qu'une règle ElastAlert2 correspond, un message structuré est posté dans Slack :

```
🚨 Attaque — Brute-force SSH
Type       : Brute-force SSH (force brute sur le port 22)
Source     : 172.28.0.30
Occurrences: 8 tentatives detectees
Gravite    : CRITIQUE
```

Les règles appliquent un **anti-spam** (`realert`) pour éviter d'inonder le canal :
une même source ne redéclenche pas d'alerte avant quelques minutes.

---

## 📁 Structure du projet

```
siem-lab/
├── docker-compose.yml          # orchestration des 7 services
├── .env.example                # gabarit de configuration (webhook Slack)
├── README.md
│
├── snort/
│   ├── Dockerfile              # image Snort 3
│   ├── snort.lua               # config Snort (sortie alert_json)
│   └── local.rules             # règles custom des 4 scénarios
│
├── syslog-ng/
│   └── syslog-ng.conf          # collecte JSON → Elasticsearch
│
├── elastalert/
│   ├── config.yaml             # config globale ElastAlert2
│   └── rules/                  # 1 règle d'alerte Slack par scénario
│       ├── 01-nmap-scan.yaml
│       ├── 02-ssh-bruteforce.yaml
│       ├── 03-ping-flood.yaml
│       └── 04-sql-injection.yaml
│
├── kibana/
│   ├── es-index-template.json  # mapping des champs (ip, dates, keyword…)
│   └── dashboard.ndjson        # data view + dashboard importables
│
├── attacks/
│   ├── Dockerfile              # conteneur attaquant (nmap, hydra…)
│   ├── Dockerfile.target       # cible vulnérable (SSH + Apache)
│   ├── vuln-app/index.php      # page web pour les tests d'injection SQL
│   ├── 01-nmap-scan.sh
│   ├── 02-ssh-bruteforce.sh
│   ├── 03-ping-flood.sh
│   ├── 04-sql-injection.sh
│   └── run-all.sh              # joue les 4 scénarios à la suite
│
└── scripts/
    ├── setup.sh                # build + démarrage + config Kibana
    ├── teardown.sh             # arrêt / nettoyage
    └── healthcheck.sh          # état de la chaîne
```

---

## 🔧 Dépannage

| Symptôme | Cause probable | Solution |
|----------|----------------|----------|
| Elasticsearch redémarre en boucle | `vm.max_map_count` trop bas | `sudo sysctl -w vm.max_map_count=262144` |
| Aucune alerte dans Kibana | Snort ne voit pas le trafic | Vérifier `docker logs siem-snort` ; l'interface doit être `eth0` |
| Index `snort-alerts-*` vide | syslog-ng n'envoie rien | `docker logs siem-syslog-ng` ; vérifier que `/var/log/snort/alert_json.txt` existe |
| Pas d'alerte Slack | Webhook erroné | Vérifier `.env` et `docker logs siem-elastalert` |
| Kibana « not ready » | Démarrage long | Patienter ~90 s ; `./scripts/healthcheck.sh` |

**Commandes utiles :**

```bash
docker compose ps                        # état des services
docker logs -f siem-snort                # flux Snort en direct
docker exec siem-snort cat /var/log/snort/alert_json.txt | tail   # alertes brutes
curl 'http://localhost:9200/snort-alerts-*/_count?pretty'         # nb d'alertes indexées
```

---

## 🚀 Pistes d'amélioration

- **Mode IPS** : passer Snort en `inline` + action `reject` pour bloquer le trafic (voir `snort.lua`, variable `ips.mode`).
- **Enrichissement GeoIP** : ajouter la géolocalisation des IP sources dans syslog-ng.
- **Règles communautaires** : intégrer les rulesets officiels Snort (Talos) en plus des règles custom.
- **Sécurité ES** : activer `xpack.security` (TLS + authentification) pour un déploiement réaliste.
- **Corrélation** : règles ElastAlert2 de type `spike` ou `new_term` pour détecter des comportements anormaux plutôt que des signatures.
- **Rétention** : politique ILM (Index Lifecycle Management) pour purger les vieux index.

---

## ⚠️ Avertissement

Cet environnement est conçu **exclusivement à des fins pédagogiques**, dans un réseau Docker isolé. La cible contient des identifiants volontairement faibles et une application vulnérable. **Ne jamais exposer ce lab sur Internet ni utiliser les outils d'attaque contre des systèmes dont vous n'êtes pas propriétaire** — c'est illégal.

---

*Projet réalisé dans le cadre d'un travail de maîtrise en informatique — UQAC.*
