#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIGURACIÓN =====
BACKUP_DIR="/home/backup/gitlab"
RETENTION_DAYS=7
KEEP_LATEST=3
DATE_STR=$(date +'%Y%m%d-%H%M%S')
BACKUP_FILE="${BACKUP_DIR}/backup-gitlab-${DATE_STR}.tar.gz"

# Ruta típica de backups GitLab Omnibus/Source
DEFAULT_BACKUP_PATH="/var/opt/gitlab/backups"
GITLAB_BACKUP_PATH="${GITLAB_BACKUP_PATH:-${DEFAULT_BACKUP_PATH}}"

mkdir -p "${BACKUP_DIR}"
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
error_exit() { log "❌ ERROR: $*"; exit 1; }

log "🚀 Iniciando backup oficial GitLab..."

# 1. EJECUTAR BACKUP OFICIAL GITLAB
log "📦 Ejecutando 'gitlab-backup create'..."
cd /opt/gitlab || cd /home/git  # Adaptar según instalación

# Para Omnibus GitLab (recomendado)
if command -v gitlab-backup >/dev/null 2>&1; then
    BACKUP_CMD="sudo gitlab-backup create"
    log "✅ Detectado Omnibus GitLab, usando gitlab-backup"
else
    # Para instalación source
    BACKUP_CMD="sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production"
    log "✅ Detectada instalación source, usando rake task"
fi

# Crear backup oficial (incluye DB + repos + uploads + artifacts)
TEMP_BACKUP=$(sudo $BACKUP_CMD STRATEGY=copy SKIP=remote | grep -oP 'Creating backup archive \K[^ ]+' || error_exit "Fallo en backup oficial")

[ -f "${GITLAB_BACKUP_PATH}/${TEMP_BACKUP}" ] || error_exit "Archivo backup no encontrado: ${GITLAB_BACKUP_PATH}/${TEMP_BACKUP}"

log "✅ Backup oficial creado: ${TEMP_BACKUP}"

# 2. MOVER Y RENOMBRAR A FORMATO REQUERIDO
sudo cp "${GITLAB_BACKUP_PATH}/${TEMP_BACKUP}" "${BACKUP_FILE}"
sudo chown $(whoami):$(whoami) "${BACKUP_FILE}"
sudo rm -f "${GITLAB_BACKUP_PATH}/${TEMP_BACKUP}"  # Limpiar temporal de GitLab

log "📁 Backup movido a: ${BACKUP_FILE}"
log "💾 Tamaño: $(du -sh "${BACKUP_FILE}" | cut -f1)"

# 3. LIMPIEZA AUTOMÁTICA
log "🧹 Limpieza backups obsoletos..."
find "${BACKUP_DIR}" -name "backup-gitlab-*.tar.gz" -mtime +${RETENTION_DAYS} -delete

# Mantener solo los 3 más recientes
ls -1t "${BACKUP_DIR}"/backup-gitlab-*.tar.gz 2>/dev/null | tail -n +$((KEEP_LATEST + 1)) | xargs -r rm -f

# Estadísticas finales
TOTAL_BACKUPS=$(ls -1 "${BACKUP_DIR}"/backup-gitlab-*.tar.gz 2>/dev/null | wc -l)
log "✅ PROCESO COMPLETADO"
log "📊 Backups actuales: ${TOTAL_BACKUPS}"
log "📁 Ubicación: ${BACKUP_DIR}"
log "💾 Último backup: ${BACKUP_FILE} ($(du -sh "${BACKUP_FILE}" | cut -f1))"
