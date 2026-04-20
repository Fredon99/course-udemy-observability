# Stack Prometheus + Alloy + Grafana

Stack de observabilidade com Prometheus para coleta de métricas, Alloy para processamento de dados e Grafana para visualização.

## Arquitetura

```
┌──────────────────────┐
│  Node Exporter       │
│  (Métricas do Host)  │
│  Port: 9100          │
└──────────┬───────────┘
           │ scrape
           ▼
┌──────────────────────┐
│  Prometheus          │
│  (TSDB)              │
│  Port: 9090          │
└──────────┬───────────┘
           │ push/query
           ▼
┌──────────────────────┐
│  Alloy               │
│  (Processador)       │
│  Port: 8081          │
└──────────┬───────────┘
           │ query
           ▼
┌──────────────────────┐
│  Grafana             │
│  (Visualização)      │
│  Port: 3000          │
└──────────────────────┘
```

## Como Usar

### Pré-requisitos
- Docker e Docker Compose instalados
- Arquivo `config.alloy` configurado
- Volumes: `prometheus_volume/`, `alloy_volume/`

### Iniciar o Stack
```bash
chmod +x start.sh stop.sh
./start.sh
```

### Acessar Serviços
- **Grafana**: http://localhost:3000
  - Usuário: `admin` (padrão)
  - Senha: configurável via `.env` (`GF_SECURITY_ADMIN_PASSWORD`)
- **Prometheus**: http://localhost:9090
  - Targets: http://localhost:9090/targets
  - Expressões: http://localhost:9090/graph
- **Node Exporter**: http://localhost:9100/metrics
- **Alloy**: http://localhost:8081/ready

### Monitorar Containers
```bash
# Ver logs em tempo real
docker compose logs -f

# Ver status dos containers
docker compose ps

# Ver logs de um serviço específico
docker compose logs -f prometheus
docker compose logs -f grafana
docker compose logs -f alloy
```

### Parar o Stack
```bash
./stop.sh
```
Ou se necessário
```bash
sudo ./stop.sh
```

## Configuração

### Variáveis de Ambiente (.env)
```env
PROMETHEUS_VERSION=latest
NODE_EXPORTER_VERSION=latest
GRAFANA_VERSION=latest
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false
```

### Configuração do Alloy
Edite o arquivo `config.alloy` para:
- Definir endpoints de scrape
- Configurar processamento de métricas
- Definir exportadores de dados

## Volumes

| Volume | Montagem | Propósito |
|--------|----------|-----------|
| `prometheus_volume` | `/etc/prometheus` | Configuração e dados do Prometheus |
| `alloy_volume` | `/etc/alloy` | Configuração do Alloy |
| `grafana_volume` | `/var/lib/grafana` | Dados e dashboards do Grafana |

## Troubleshooting

```bash
# Verificar saúde dos serviços
curl http://localhost:9090/-/ready      # Prometheus
curl http://localhost:8081/ready        # Alloy
curl http://localhost:3000/api/health   # Grafana

# Limpar volumes (ATENÇÃO: deleta dados)
docker compose down -v

# Reconstruir containers
docker compose up -d --force-recreate
```

## Datasources Grafana

O Prometheus é configurado automaticamente como datasource no Grafana. Acesse:
- **Settings** → **Data Sources** → **Prometheus**
- URL: `http://prometheus:9090`
