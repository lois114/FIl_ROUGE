#!/usr/bin/env bash
# =====================================================================
# AquaLab — Stratégie de sauvegarde PostgreSQL (Axe 4)
# Règle 3-2-1 : ce script produit une sauvegarde chiffrée, horodatée,
# à répliquer ensuite sur un 2e support + 1 copie hors-site.
# A planifier via cron (ex. tous les jours à 23h00).
# =====================================================================
set -euo pipefail

# --- Paramètres ---
DB_NAME="aqualab"
DB_USER="dba_admin"
DB_HOST="localhost"
BACKUP_DIR="/var/backups/aqualab"
RETENTION_DAYS=30
GPG_RECIPIENT="sauvegarde@aqualab.fr"   # clé publique GPG pour le chiffrement
DATE="$(date +%Y%m%d_%H%M%S)"
FILE="${BACKUP_DIR}/aqualab_${DATE}.sql.gz"

mkdir -p "${BACKUP_DIR}"

# --- 1) Dump logique compressé ---
echo "[*] Sauvegarde de ${DB_NAME} ..."
pg_dump -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" --format=plain \
  | gzip > "${FILE}"

# --- 2) Chiffrement (confidentialité des sauvegardes) ---
gpg --yes --encrypt --recipient "${GPG_RECIPIENT}" "${FILE}"
rm -f "${FILE}"                       # on ne garde que la version chiffrée .gpg
echo "[*] Sauvegarde chiffrée : ${FILE}.gpg"

# --- 3) Rotation / rétention ---
find "${BACKUP_DIR}" -name 'aqualab_*.sql.gz.gpg' -mtime +${RETENTION_DAYS} -delete
echo "[*] Purge des sauvegardes de plus de ${RETENTION_DAYS} jours effectuée."

# --- 4) Réplication hors-site (à décommenter / adapter) ---
# rsync -avz "${BACKUP_DIR}/" backup@site-distant:/backups/aqualab/
# --- 5) Copie hors-ligne : extraction périodique sur support déconnecté ---

# --- Test de restauration (à exécuter régulièrement, ex. trimestriel) ---
# gpg --decrypt aqualab_<date>.sql.gz.gpg | gunzip | psql -U dba_admin -d aqualab_restore_test
echo "[*] Terminé. Penser au test de restauration trimestriel (RPO <= 1h, RTO <= 4h)."
