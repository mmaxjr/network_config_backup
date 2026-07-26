#!/usr/bin/env bash
#
# network_config_backup.sh
# Conecta via SSH em uma lista de switches/roteadores, extrai a
# configuração atual e salva com timestamp, mantendo histórico
# de versões para cada dispositivo.
#
# Uso: ./network_config_backup.sh
# Preencha o arquivo devices.txt com: host;usuario;comando

set -uo pipefail

# ================== CONFIG ==================
DEVICES_FILE="./devices.txt"          # lista de dispositivos (host;usuario;comando)
BACKUP_DIR="./backups"                # pasta onde os backups serão salvos
SSH_TIMEOUT=10                         # timeout de conexão SSH (segundos)
DIAS_RETENCAO=30                       # dias para manter backups antigos
LOG_FILE="./network_config_backup.log"
# ==============================================
# Formato esperado de devices.txt (um por linha):
# 192.168.1.1;admin;show running-config
# switch-core.empresa.com;netadmin;display current-configuration
# ==============================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"

if [ ! -f "$DEVICES_FILE" ]; then
    log "Arquivo $DEVICES_FILE não encontrado. Crie a lista de dispositivos primeiro."
    exit 1
fi

log "===== Iniciando backup de configurações ====="
DATA=$(date '+%Y-%m-%d_%H-%M')
SUCESSOS=0
FALHAS=0

while IFS=';' read -r host usuario comando; do
    [ -z "$host" ] && continue
    [[ "$host" =~ ^#.*$ ]] && continue  # ignora linhas comentadas

    DEST_DIR="$BACKUP_DIR/$host"
    mkdir -p "$DEST_DIR"
    ARQUIVO="$DEST_DIR/${host}_${DATA}.txt"

    log "Conectando em $host como $usuario..."

    if ssh -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=no \
        "${usuario}@${host}" "$comando" > "$ARQUIVO" 2>/dev/null; then

        if [ -s "$ARQUIVO" ]; then
            log "✅ Backup de $host salvo em $ARQUIVO"
            SUCESSOS=$((SUCESSOS + 1))
        else
            log "⚠️  Backup de $host veio vazio. Verifique o comando/permissões."
            rm -f "$ARQUIVO"
            FALHAS=$((FALHAS + 1))
        fi
    else
        log "❌ Falha ao conectar/executar comando em $host"
        rm -f "$ARQUIVO"
        FALHAS=$((FALHAS + 1))
    fi
done < "$DEVICES_FILE"

# Limpeza de backups antigos
log "Removendo backups com mais de $DIAS_RETENCAO dias..."
find "$BACKUP_DIR" -type f -name "*.txt" -mtime +"$DIAS_RETENCAO" -delete

log "===== Backup concluído: $SUCESSOS sucesso(s), $FALHAS falha(s) ====="
