# Stack Prometheus + Alloy + Loki + Grafana

Stack de observabilidade completo com coleta de métricas (Prometheus), logs (Loki), processamento de dados (Alloy) e visualização (Grafana). Inclui uma aplicação Order Service que gera traces e métricas.

## Arquitetura

```
┌────────────────────────────────────────────────────────────┐
│                    Order Service                           │
│              (Gera métricas e traces)                      │
│                    Port: 8080                              │
└──────────────────┬─────────────────────────────────────────┘
                   │ OTLP gRPC (4317) / HTTP (4318)
                   ▼
    ┌──────────────────────────────┐
    │         Alloy                │
    │  (Coleta e Processor)        │
    │     Port: 8081               │
    └──┬─────────────────────────┬─┘
       │                         │
       │ remote_write            │ push
       ▼                         ▼
 ┌──────────────┐         ┌──────────────┐
 │  Prometheus  │         │    Loki      │
 │   (TSDB)     │         │  (Log DB)    │
 │  Port: 9090  │         │ Port: 3100   │
 └──────┬───────┘         └──────┬───────┘
        │                        │
        └────────────┬───────────┘
                     │ query
                     ▼
            ┌──────────────────┐
            │     Grafana      │
            │ (Visualização)   │
            │   Port: 3000     │
            └──────────────────┘
```

## Como Usar

### Pré-requisitos
- Docker e Docker Compose instalados
- Arquivo `.env` (será criado automaticamente)
- Arquivo `config.alloy` configurado
- Volumes: `prometheus_volume/`, `alloy_etc/`, `alloy_log/`

### Iniciar o Stack
```bash
chmod +x start.sh stop.sh
./start.sh
```

### Acessar Serviços
- **Grafana**: http://localhost:3000
  - Usuário: `admin` (padrão)
  - Senha: configurável via `.env` (`GF_SECURITY_ADMIN_PASSWORD`)
  - Dashboards pré-configurados na seção de provisioning
- **Prometheus**: http://localhost:9090
  - Targets: http://localhost:9090/targets
  - Expressões: http://localhost:9090/graph
- **Loki**: http://localhost:3100/ready
  - Verificação de saúde
- **Alloy**: http://localhost:8081/ready
  - Verificação de saúde
  - Receptores: OTLP gRPC (4317), HTTP (4318)
- **Order Service**: http://localhost:8080
  - Aplicação de exemplo gerando métricas e traces

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
docker compose logs -f loki
docker compose logs -f order-service
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
# Versões dos serviços
PROMETHEUS_VERSION=v2.51.0
LOKI_VERSION=3.7.1
GRAFANA_VERSION=12.4.2

# Configuração do Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false
```

### Configuração do Alloy (`config.alloy`)
O Alloy atua como coletor e processador de dados:
- **Receptor OTLP**: Recebe métricas e traces do Order Service via gRPC (4317) e HTTP (4318)
- **Processador Batch**: Agrupa dados antes do envio
- **Exportador Prometheus**: Envia métricas para o Prometheus via remote write
- **Exportador Loki**: Envia logs para o Loki

Edite o arquivo `config.alloy` para:
- Ajustar endpoints de scrape
- Modificar regras de processamento
- Adicionar novos exportadores

### Configuração do Prometheus (`prometheus_volume/prometheus.yml`)
- Scrape interval: 15s
- Remote write para Alloy
- Targets configurados automaticamente

### Configuração do Grafana
#### Datasources
- **Prometheus**: Conectado automaticamente (localhost:9090)
- **Loki**: Conectado automaticamente (localhost:3100)

Mais datasources podem ser adicionados em `grafana/provisioning/datasources/`

#### Dashboards
Dashboards pré-provisionados estão em:
- `grafana/provisioning/dashboards/json/logs-dashboard.json`

Novos dashboards podem ser adicionados à pasta `json/` e referenciados em `dashboards.yml`

## Volumes

Os seguintes volumes armazenam dados persistentes:

- **prometheus_volume**: Dados do Prometheus e configuração
- **alloy_etc**: Configuração do Alloy (inclui `config.alloy`)
- **alloy_log**: Logs do Alloy
- **grafana_volume**: Data stores do Grafana (usuários, dashboards, etc)

Os dados são salvos em diretórios locais na raiz do projeto para facilitar backup e restore.

## Order Service

A aplicação Order Service é um serviço de exemplo que:
- Expõe um endpoint HTTP na porta 8080
- Gera métricas customizadas (contador de pedidos)
- Envia os dados ao Alloy via OTLP
- Gera traces automaticamente das requisições HTTP

### Endpoints
- `GET /` - Retorna "OK" e incrementa o contador de pedidos

### Variáveis de Configuração (appsettings.json)
```json
{
  "OtelMetricCollector:Host": "http://alloy:4317",
  "OtelTraceCollector:Host": "http://alloy:4317"
}
```

## Fluxo de Dados

1. **Order Service** gera métricas e traces
2. **Alloy** (OTLP receiver) coleta esses dados via gRPC/HTTP
3. **Alloy** (processor) agrupa os dados em batches
4. **Prometheus** recebe as métricas via remote write
5. **Loki** recebe os logs
6. **Grafana** consulta Prometheus e Loki para exibir dashboards e alertas

## Troubleshooting

### Containers não iniciam
```bash
# Verificar se há erros
docker compose logs -f

# Limpar volumes e reconstruir
docker compose down -v
docker compose up -d
```

### "Port already in use"
```bash
# Encontrar processo usando a porta (exemplo: 3000)
lsof -i :3000

# Ou alterar a porta no docker-compose.yaml
```

### Métricas/Logs não aparecem no Grafana
1. Verificar se Order Service está rodando: `docker compose logs -f order-service`
2. Verificar conectividade do Alloy: `docker compose logs -f alloy`
3. Confirmar que Datasources estão configuradas no Grafana
4. Verificar se os dados foram coletados: http://localhost:9090/graph (Prometheus)

### Alloy não inicia
- Verificar sintaxe do `config.alloy`
- Confirmar que os volumes estão montados corretamente
- Verificar logs: `docker compose logs -f alloy`

## Notas Importantes

- Os dados persistem nos volumes mesmo após parar os containers
- Para uma limpeza completa: `docker compose down -v`
- O arquivo `.env` é criado automaticamente pelo `start.sh` com versões estáveis
- Grafana usa provisioning automático para datasources e dashboards
- A senha do Grafana pode ser alterada via `.env` antes de iniciar o stack

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
