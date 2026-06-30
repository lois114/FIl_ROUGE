# AquaLab — Axes 4 & 6 : BDD/NoSQL & DevOps

Dépôt du prototype technique pour le fil rouge cybersécurité (laboratoire AquaLab).

Le projet illustre **trois paradigmes de bases de données** et une chaîne **DevOps**
complète (conteneurisation, CI/CD, sécurité, observabilité), avec des **données fictives**
chargées automatiquement.

## Trois paradigmes de bases (Axe 4)

| Paradigme | Moteur | Usage dans AquaLab | Interface web |
|-----------|--------|--------------------|---------------|
| Relationnel | **PostgreSQL** | Données métier du LIMS (échantillons, analyses, résultats) | Adminer — `:8083` |
| Document | **MongoDB** | Journaux applicatifs et de sécurité (volumineux, semi-structurés) | mongo-express — `:8084` |
| Graphe | **Neo4j** | Traçabilité / chaîne de validation, séparation des tâches | Neo4j Browser — `:7474` |

## Contenu

```
axes4-6-bdd-devops/
├── bdd/
│   ├── 01_schema.sql          # Modèle de données LIMS (PostgreSQL)
│   ├── 02_roles_dcl.sql       # Contrôle d'accès : rôles + GRANT/REVOKE (séparation des tâches)
│   ├── 03_backup.sh           # Sauvegarde chiffrée 3-2-1 (cron)
│   ├── 03_seed.sql            # Données fictives PostgreSQL (auto au démarrage)
│   ├── 04_mongodb_logs.js     # Base NoSQL MongoDB : schéma + requêtes de référence
│   ├── 05_seed_logs.js        # ~200 logs fictifs MongoDB (auto au démarrage)
│   └── 06_neo4j_graph.cypher  # Graphe de traçabilité Neo4j + requêtes Cypher
├── app/                       # Mini-API d'exemple (Flask) pour la CI/CD
│   ├── app.py                 # /health, /api/resultats, /metrics (Prometheus)
│   ├── requirements.txt
│   └── test_app.py
├── monitoring/
│   ├── prometheus.yml         # Cibles : app, node-exporter, prometheus
│   └── grafana/               # Provisioning auto : datasource + dashboard
├── screenshots/               # Captures (Grafana, Neo4j, PostgreSQL, MongoDB)
├── Dockerfile                 # Image conteneurisée (non-root, healthcheck)
├── docker-compose.yml         # Stack complète (10 services, voir ci-dessous)
└── .github/
    ├── workflows/ci-cd.yml    # Pipeline : tests, Gitleaks, Trivy, déploiement
    ├── workflows/codeql.yml   # SAST (analyse de code)
    └── dependabot.yml         # Veille vulnérabilités des dépendances
```

**Services `docker-compose`** : `app`, `postgres`, `mongo`, `neo4j`, `adminer`,
`mongo-express`, `prometheus`, `node-exporter`, `grafana`, `renderer`.

## Démarrage rapide (sur la VM)

```bash
# 1) Lancer toute la stack
docker compose up -d
#    → PostgreSQL : schéma + rôles + données fictives (01, 02, 03_seed.sql) chargés automatiquement
#    → MongoDB    : ~200 logs fictifs (05_seed_logs.js) chargés automatiquement
#    → Grafana    : datasource Prometheus + dashboard chargés automatiquement (provisioning)

# 2) Charger le graphe Neo4j (Neo4j n'a pas de dossier d'init automatique)
docker exec -i aqualab-neo4j cypher-shell -u neo4j -p ChangeMeNeo4j_2026 < bdd/06_neo4j_graph.cypher
```

## Accès aux interfaces

| Service | URL | Identifiants |
|---------|-----|--------------|
| API AquaLab | `http://IP:8000/health` · `/metrics` | — |
| Adminer (PostgreSQL) | `http://IP:8083` | Système PostgreSQL · Serveur `postgres` · BDD `aqualab` · `postgres` / `ChangeMePg_2026` — **schéma `lims`** |
| mongo-express (MongoDB) | `http://IP:8084` | `admin` / `ChangeMeMongo_2026` → base `aqualab_logs` |
| Neo4j Browser (graphe) | `http://IP:7474` | `neo4j` / `ChangeMeNeo4j_2026` (Bolt `:7687`) |
| Prometheus | `http://IP:9090` | — |
| Grafana | `http://IP:3000` | `admin` / `ChangeMeGrafana_2026` |

## Observabilité (Prometheus + Grafana)

L'API expose ses métriques sur `/metrics` ; Prometheus les collecte (ainsi que les métriques
système via **node-exporter**). Grafana est **provisionné automatiquement** : la source de données
Prometheus et le dashboard **« AquaLab — Observabilité »** sont disponibles dès le démarrage,
sans configuration manuelle.

Le service `renderer` (grafana-image-renderer) permet l'export PNG/PDF des dashboards
(voir `screenshots/README.md` pour régénérer les captures).

## Sécurité dans le pipeline (Axe 6)

| Outil | Rôle | Où |
|-------|------|-----|
| Gitleaks | détecte les secrets commités | job `secrets-scan` |
| Trivy | scanne l'image Docker (CVE), via l'image officielle `aquasec/trivy` | job `build-and-scan` |
| CodeQL | analyse statique du code (SAST) | workflow `codeql.yml` |
| Dependabot | failles des dépendances (SCA) | `dependabot.yml` |

## Sécurité des données (Axe 4)

- **Moindre privilège** : chaque profil métier (technicien, validateur, commercial…) reçoit
  le strict nécessaire via `GRANT`/`REVOKE` (`02_roles_dcl.sql`).
- **Séparation des tâches** : un résultat ne peut pas être validé par son saisisseur —
  garanti par la contrainte `chk_validation_separee` (PostgreSQL) et visible dans le graphe Neo4j
  (relations `A_SAISI` ≠ `A_VALIDE`).
- **Bases non exposées** : PostgreSQL et MongoDB ne publient pas leurs ports vers l'hôte
  (accès via Adminer / mongo-express / conteneurs uniquement).

