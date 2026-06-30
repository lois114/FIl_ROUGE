# AquaLab — image de la mini-API (Axe 6 : conteneurisation sécurisée)
# Bonnes pratiques : image officielle légère, version figée, utilisateur non-root,
# dépendances installées proprement, healthcheck.
FROM python:3.12-slim

# Empêche Python d'écrire des .pyc et force le flush des logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Installer les dépendances d'abord (cache de build)
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code
COPY app/ .

# Créer et utiliser un utilisateur non privilégié (sécurité)
RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 8000

# Sonde de disponibilité du conteneur
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0) if urllib.request.urlopen('http://localhost:8000/health').status==200 else sys.exit(1)"

CMD ["python", "app.py"]
