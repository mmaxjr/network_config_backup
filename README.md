# Backup Automatizado de Configurações de Rede

Script em Bash que conecta via SSH em uma lista de switches/roteadores, extrai a configuração atual e salva com timestamp, mantendo histórico de versões por dispositivo.

## O que faz

- Lê uma lista de dispositivos (host, usuário, comando) de `devices.txt`
- Conecta via SSH em cada um e executa o comando de exibição de configuração
- Salva o resultado em uma pasta por dispositivo, com data/hora no nome do arquivo
- Remove backups mais antigos que o período de retenção configurado
- Registra sucessos e falhas em log

## Requisitos

- Bash, OpenSSH client
- Acesso SSH configurado (chave ou usuário/senha) nos dispositivos
- Comando de exibição de configuração compatível com o fabricante (Cisco, Huawei, MikroTik, etc.)

## Configuração

Crie o arquivo `devices.txt` no mesmo formato:

```
192.168.1.1;admin;show running-config
switch-core.empresa.com;netadmin;display current-configuration
```

Ajuste `BACKUP_DIR`, `SSH_TIMEOUT` e `DIAS_RETENCAO` no início do script conforme necessário.

## Como usar

```bash
chmod +x network_config_backup.sh
./network_config_backup.sh
```

Pode ser agendado via cron para rodar diariamente:

```bash
0 2 * * * /caminho/network_config_backup.sh
```

---
Feito por [Marcos Max](https://github.com/mmaxjr)
