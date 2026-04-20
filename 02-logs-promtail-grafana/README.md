# Stack Loki + Promtail + Grafana

## Como Usar

### Iniciar o Stack
```bash
chmod +x start.sh stop.sh
./start.sh
```

**Isso vai automaticamente:**
1. Criar `.env` com valores padrão
2. Criar diretórios necessários
3. Copiar configuração do Promtail
4. Iniciar containers (Loki, Promtail, Grafana)
5. Iniciar gerador de logs em background (loop contínuo)

### Acessar Serviços
- **Grafana**: http://localhost:3000 (admin/admin)
- **Loki**: http://localhost:3100
- **Promtail**: http://localhost:9080

### Monitorar Gerador de Logs
```bash
# Ver logs do gerador em tempo real
tail -f /tmp/log-generator.log

# Ver logs dos containers
docker compose logs -f

# Parar só o gerador de logs
pkill -f "python3 ./log-generator.py"
```

### Parar o Stack Completo
```bash
./stop.sh
```

## Arquitetura

```
┌─────────────────────────────────┐
│   Log Generator (Python)        │
│   - Loop contínuo               │
│   - Escreve em promtail_log/    │
└────────────┬────────────────────┘
             │ (escreve logs)
             ▼
┌─────────────────────────────────┐
│   Promtail Container            │
│   - Lê /var/log/loki.log        │
│   - Envia para Loki             │
└────────────┬────────────────────┘
             │ (push logs)
             ▼
┌─────────────────────────────────┐
│   Loki Container                │
│   - Armazena logs               │
│   - Exposto em :3100            │
└────────────┬────────────────────┘
             │ (query via API)
             ▼
┌─────────────────────────────────┐
│   Grafana Container             │
│   - Visualiza logs              │
│   - Exposto em :3000 (admin)    │
└─────────────────────────────────┘
```

## Customização

### Mudar Intervalo de Geração de Logs
Editar `start.sh` linha que roda log-generator:
```bash
python3 ./log-generator.py --config ./directories.txt --interval 10  # 10 segundos
```

### Mudar Versões das Imagens
Editar `.env`:
```env
LOKI_VERSION=3.0
PROMTAIL_VERSION=3.0
GRAFANA_VERSION=latest
```

### Adicionar Mais Arquivos de Log
Editar `directories.txt`:
```
./promtail_log/loki.log
./promtail_log/app.log
./promtail_log/error.log
```

## Logs e Debugging

```bash
# Ver saúde dos containers
docker compose ps

# Inspecionar logs de um serviço
docker compose logs loki
docker compose logs promtail
docker compose logs grafana

# Ver arquivo de configuração do Promtail
cat ./promtail_etc/config.yml

# Ver logs gerados
tail -f ./promtail_log/loki.log
```
