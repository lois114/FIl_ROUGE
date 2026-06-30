# Captures d'écran — Observabilité (Axe 6)

Images du dashboard Grafana « AquaLab — Observabilité », générées par le
moteur de rendu Grafana (service `renderer` du `docker-compose.yml`).

| Fichier | Contenu |
|---|---|
| `grafana-dashboard-complet.png` | Vue complète des 8 panneaux (requêtes, cibles UP, CPU, mémoire, débit par endpoint, état des cibles) |
| `panel-debit-requetes.png` | Débit de requêtes par endpoint (req/s) |
| `panel-cibles-up.png` | Table d'état des cibles Prometheus (node, app, prometheus) |
| `panel-cpu.png` | Charge CPU dans le temps |

## Régénérer les captures

Avec la stack démarrée (`docker compose up -d`) :

```bash
AUTH="admin:ChangeMeGrafana_2026"
# Dashboard complet
curl -u "$AUTH" "http://localhost:3000/render/d/aqualab-obs/aqualab-observabilite?orgId=1&from=now-30m&to=now&width=1600&height=850&theme=dark&kiosk=true" -o screenshots/grafana-dashboard-complet.png
# Un panneau précis (panelId visible dans l'URL du panneau)
curl -u "$AUTH" "http://localhost:3000/render/d-solo/aqualab-obs/aqualab-observabilite?orgId=1&panelId=5&width=900&height=450&theme=dark" -o screenshots/panel-debit-requetes.png
```
