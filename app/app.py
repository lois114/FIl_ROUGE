"""AquaLab — mini-API portail de résultats (exemple pour le pipeline DevOps).
Application volontairement minimale : sert à démontrer build/test/scan dans la CI/CD.
"""
import os
from flask import Flask, jsonify, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# La configuration sensible vient de variables d'environnement (jamais en dur dans le code)
DB_HOST = os.environ.get("DB_HOST", "postgres")
DB_NAME = os.environ.get("DB_NAME", "aqualab")

# Métrique exposée à Prometheus (observabilité - axe 6)
REQUESTS = Counter("aqualab_requests_total", "Nombre de requêtes par endpoint", ["endpoint"])


@app.get("/health")
def health():
    """Sonde de disponibilité (utilisée par Docker healthcheck et la supervision)."""
    REQUESTS.labels(endpoint="health").inc()
    return jsonify(status="ok"), 200


@app.get("/api/resultats/<int:echantillon_id>")
def resultats(echantillon_id: int):
    """Stub : renverrait les résultats validés d'un échantillon depuis PostgreSQL."""
    REQUESTS.labels(endpoint="resultats").inc()
    return jsonify(echantillon_id=echantillon_id, resultats=[]), 200


@app.get("/metrics")
def metrics():
    """Endpoint scrapé par Prometheus (puis visualisé dans Grafana)."""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    # 0.0.0.0 pour être joignable dans le conteneur ; debug désactivé (sécurité)
    app.run(host="0.0.0.0", port=8000, debug=False)
