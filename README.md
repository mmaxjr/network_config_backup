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
- Opcional: `sshpass` instalado, apenas se for usar autenticação por senha
- Comando de exibição de configuração compatível com o fabricante (Cisco, Huawei, MikroTik, etc.)

## Autenticação

O script suporta dois modos, por dispositivo:

- **Chave SSH (recomendado)** — deixe a 4ª coluna do `devices.txt` em branco. O script conecta usando a chave SSH do usuário, sem nenhuma senha armazenada.
- **Usuário/senha** — preencha a 4ª coluna com a senha. O script usa o utilitário `sshpass` para autenticar automaticamente. Use apenas quando o dispositivo não suportar chave (comum em switches mais simples).

⚠️ Se usar senha no arquivo, proteja-o com `chmod 600 devices.txt` — o script avisa no log se a permissão estiver diferente disso. Sempre que possível, prefira chave SSH.

## Configuração

Crie o arquivo `devices.txt` no mesmo formato:

```
192.168.1.1;admin;show running-config
switch-core.empresa.com;netadmin;display current-configuration
192.168.1.2;admin;show running-config;MinhaSenh@123
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
