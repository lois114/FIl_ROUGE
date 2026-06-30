# Captures d'écran — Observabilité (Axe 6)

Images du dashboard Grafana « AquaLab — Observabilité », générées par le
moteur de rendu Grafana (service `renderer` du `docker-compose.yml`).

| Fichier | Contenu |
|---|---|
| `grafana-dashboard-complet.png` | Vue complète des 8 panneaux (requêtes, cibles UP, CPU, mémoire, débit par endpoint, état des cibles) |
| `panel-debit-requetes.png` | Débit de requêtes par endpoint (req/s) |
| `panel-cibles-up.png` | Table d'état des cibles Prometheus (node, app, prometheus) |
| `panel-cpu.png` | Charge CPU dans le temps |
| `neo4j-graphe-complet.png` | Graphe de traçabilité complet Neo4j (98 nœuds, 176 relations), coloré par type |
| `neo4j-chaine-tracabilite.png` | Chaîne d'un échantillon (Client→Site→Échantillon→Analyse→Résultat) + séparation des tâches (A_SAISI / A_VALIDE) |
| `adminer-postgres.png` | PostgreSQL : volume par table + extrait de `resultat` (conformité, séparation des tâches) |
| `mongo-express-logs.png` | MongoDB : extrait des journaux + détection brute-force + répartition par niveau |

## Régénérer les captures

Avec la stack démarrée (`docker compose up -d`) :

```bash
AUTH="admin:ChangeMeGrafana_2026"
# Dashboard complet
curl -u "$AUTH" "http://localhost:3000/render/d/aqualab-obs/aqualab-observabilite?orgId=1&from=now-30m&to=now&width=1600&height=850&theme=dark&kiosk=true" -o screenshots/grafana-dashboard-complet.png
# Un panneau précis (panelId visible dans l'URL du panneau)
curl -u "$AUTH" "http://localhost:3000/render/d-solo/aqualab-obs/aqualab-observabilite?orgId=1&panelId=5&width=900&height=450&theme=dark" -o screenshots/panel-debit-requetes.png
```
