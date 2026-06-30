# AquaLab — Axes 4 & 6 : BDD/NoSQL & DevOps

Dépôt du prototype technique pour le fil rouge cybersécurité (laboratoire AquaLab).

## Contenu

```
axes4-6-bdd-devops/
├── bdd/
│   ├── 01_schema.sql        # Modèle de données LIMS (PostgreSQL)
│   ├── 02_roles_dcl.sql     # Contrôle d'accès : rôles + GRANT/REVOKE
│   ├── 03_backup.sh         # Sauvegarde chiffrée 3-2-1 (cron)
│   └── 04_mongodb_logs.js   # Base NoSQL MongoDB pour les logs
├── app/                     # Mini-API d'exemple (Flask) pour la CI/CD
│   ├── app.py
│   ├── requirements.txt
│   └── test_app.py
├── Dockerfile               # Image conteneurisée (non-root, healthcheck)
├── docker-compose.yml       # App + PostgreSQL + MongoDB + Adminer
└── .github/
    ├── workflows/ci-cd.yml  # Pipeline : tests, Gitleaks, Trivy, déploiement
    ├── workflows/codeql.yml # SAST (analyse de code)
    └── dependabot.yml       # Veille vulnérabilités des dépendances
```

## Démarrage rapide (sur la VM)

```bash
# 1) Lancer la stack (PostgreSQL initialise le schéma + les rôles automatiquement)
docker compose up -d

# 2) Charger la base de logs MongoDB
docker exec -i aqualab-mongo mongosh < bdd/04_mongodb_logs.js

# 3) Accès
#   API        : http://IP:8000/health   (métriques : http://IP:8000/metrics)
#   Adminer    : http://IP:8083   (Système: PostgreSQL, Serveur: postgres, BDD: aqualab)
#   Prometheus : http://IP:9090
#   Grafana    : http://IP:3000   (admin / ChangeMeGrafana_2026)
```

## Observabilité (Prometheus + Grafana)

L'API expose ses métriques sur `/metrics` ; Prometheus les collecte (ainsi que les métriques
système via node-exporter) et Grafana les affiche. Dans Grafana : ajouter la source de données
Prometheus (`http://prometheus:9090`), puis importer le dashboard **Node Exporter Full** (ID 1860).

## Sécurité dans le pipeline (Axe 6)

| Outil | Rôle | Où |
|-------|------|-----|
| Gitleaks | détecte les secrets commités | job `secrets-scan` |
| Trivy | scanne l'image Docker (CVE) | job `build-and-scan` |
| CodeQL | analyse statique du code (SAST) | workflow `codeql.yml` |
| Dependabot | failles des dépendances (SCA) | `dependabot.yml` |

> Pensez à changer tous les mots de passe `ChangeMe..._2026` avant toute mise en service.
