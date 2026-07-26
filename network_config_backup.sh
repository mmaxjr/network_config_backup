#!/usr/bin/env bash
#
# network_config_backup.sh
# Conecta via SSH em uma lista de switches/roteadores, extrai a
# configuração atual e salva com timestamp, mantendo histórico
# de versões para cada dispositivo.
#
# Uso: ./network_config_backup.sh
# Preencha o arquivo devices.txt com: host;usuario;comando;senha(opcional)
#
# Autenticação:
#   - Se a coluna "senha" for deixada em branco, o script usa autenticação
#     por CHAVE SSH (recomendado — mais seguro, nada de senha em arquivo).
#   - Se a coluna "senha" for preenchida, o script usa o utilitário
#     "sshpass" para autenticar com usuário/senha automaticamente.
#     Use isso só quando o dispositivo não suporta chave (switches mais
#     simples, por exemplo) e proteja bem o arquivo devices.txt (chmod 600).

set -uo pipefail

# ================== CONFIG ==================
DEVICES_FILE="./devices.txt"          # lista de dispositivos (host;usuario;comando;senha)
BACKUP_DIR="./backups"                # pasta onde os backups serão salvos
SSH_TIMEOUT=10                         # timeout de conexão SSH (segundos)
DIAS_RETENCAO=30                       # dias para manter backups antigos
LOG_FILE="./network_config_backup.log"
# ==============================================
# Formato esperado de devices.txt (um por linha):
# 192.168.1.1;admin;show running-config
# switch-core.empresa.com;netadmin;display current-configuration
#
# Com senha (usa sshpass), 4ª coluna opcional:
# 192.168.1.2;admin;show running-config;MinhaSenh@123
# ==============================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"

if [ ! -f "$DEVICES_FILE" ]; then
    log "Arquivo $DEVICES_FILE não encontrado. Crie a lista de dispositivos primeiro."
    exit 1
fi

# Aviso de permissão do arquivo, já que ele pode conter senhas em texto puro
PERMISSOES=$(stat -c "%a" "$DEVICES_FILE" 2>/dev/null || stat -f "%Lp" "$DEVICES_FILE" 2>/dev/null)
if [ "$PERMISSOES" != "600" ]; then
    log "⚠️  Aviso: $DEVICES_FILE não está com permissão 600. Rode: chmod 600 $DEVICES_FILE"
fi

log "===== Iniciando backup de configurações ====="
DATA=$(date '+%Y-%m-%d_%H-%M')
SUCESSOS=0
FALHAS=0

while IFS=';' read -r host usuario comando senha; do
    [ -z "$host" ] && continue
    [[ "$host" =~ ^#.*$ ]] && continue  # ignora linhas comentadas

    DEST_DIR="$BACKUP_DIR/$host"
    mkdir -p "$DEST_DIR"
    ARQUIVO="$DEST_DIR/${host}_${DATA}.txt"

    log "Conectando em $host como $usuario..."

    SSH_OK=false
    if [ -n "${senha:-}" ]; then
        # Autenticação por senha via sshpass
        if ! command -v sshpass &> /dev/null; then
            log "❌ 'sshpass' não instalado. Instale (apt install sshpass) ou use chave SSH."
            FALHAS=$((FALHAS + 1))
            continue
        fi
        if sshpass -p "$senha" ssh -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=no \
            "${usuario}@${host}" "$comando" > "$ARQUIVO" 2>/dev/null; then
            SSH_OK=true
        fi
    else
        # Autenticação por chave SSH (padrão, recomendado)
        if ssh -o ConnectTimeout="$SSH_TIMEOUT" -o StrictHostKeyChecking=no \
            -o BatchMode=yes "${usuario}@${host}" "$comando" > "$ARQUIVO" 2>/dev/null; then
            SSH_OK=true
        fi
    fi

    if [ "$SSH_OK" = true ]; then
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
