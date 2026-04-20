# Observability Stack — Logs, Metrics, Distributed Tracing

Stack completo de observabilidade com coleta de métricas (Prometheus), logs (Loki), traces distribuídos (Tempo) e visualização (Grafana). Inclui dois serviços de exemplo (OrderService e PaymentService) que demonstram distributed tracing end-to-end com propagação de contexto.

## Arquitetura

```
┌────────────────┐   HTTP GET /call-payment-service   ┌─────────────────┐
│  Order Service │ ──────────────────────────────────► │ Payment Service │
│   Port: 8080   │   (traceparent header propagado)    │   Port: 8085    │
└───────┬────────┘                                     └────────┬────────┘
        │                                                       │
        └──────────────────┬────────────────────────────────────┘
                           │ OTLP gRPC (4317)
                           ▼
              ┌────────────────────────┐
              │         Alloy          │
              │  (Coletor/Processador) │
              │       Port: 8081       │
              └────┬──────────┬────────┘
                   │          │
        remote_write│          │ OTLP push (traces)
                   ▼          ▼
        ┌──────────────┐  ┌──────────────────────────┐
        │  Prometheus  │  │          Tempo            │
        │  Port: 9090  │  │  (Trace Backend + MinIO)  │
        └──────┬───────┘  │       Port: 3200          │
               │          │  metrics_generator:        │
               ◄──────────│  service-graphs +          │
               │          │  span-metrics              │
               │          └────────────────────────────┘
               │
        ┌──────┴───────────────────────────┐
        │             Grafana              │
        │  (Metrics + Logs + Traces +      │
        │   Service Map)  Port: 3000       │
        └──────────────────────────────────┘
```

### Componentes

| Serviço | Imagem | Função |
|---------|--------|--------|
| **Order Service** | `order-service:2.0` | Serviço .NET 8 que gera métricas, logs e traces. Chama o Payment Service |
| **Payment Service** | `payment-service:1.0` | Serviço .NET 8 que recebe chamadas e age como span filho no trace |
| **Alloy** | `grafana/alloy:v1.14.2` | Coletor OpenTelemetry: recebe OTLP, envia métricas → Prometheus, logs → Loki, traces → Tempo |
| **Prometheus** | `prom/prometheus:v2.51.0` | Armazena métricas TSDB; recebe remote_write do Alloy e do Tempo metrics_generator |
| **Loki** | `grafana/loki:3.7.1` | Armazena logs |
| **Tempo** | `grafana/tempo:2.4.1` | Armazena traces; gera métricas de service graph via `metrics_generator` |
| **MinIO** | `minio/minio` | Armazenamento S3 para o backend do Tempo |
| **Grafana** | `grafana/grafana-oss:12.4.2` | Visualização: dashboards, Service Map, trace viewer |

---

## Como Usar

### Pré-requisitos
- Docker e Docker Compose instalados

### Iniciar o stack
```bash
chmod +x start.sh stop.sh
./start.sh
```

### Parar o stack
```bash
./stop.sh
```

### Acessar serviços

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | `admin` / `admin` |
| Prometheus | http://localhost:9090 | — |
| Alloy UI | http://localhost:8081 | — |
| Loki | http://localhost:3100/ready | — |
| Tempo | http://localhost:3200/ready | — |
| MinIO Console | http://localhost:9001 | `admin` / `admin123` |
| Order Service | http://localhost:8080 | — |
| Payment Service | http://localhost:8085 | — |

---

## Distributed Tracing

### Fluxo de um trace end-to-end

```
GET http://localhost:8080/call-payment-service
  └─ [Making HTTP Call] span (OrderService, SpanKind.Client)
       └─ [HTTP GET http://payment-service:8080] span (propagação automática via AddHttpClientInstrumentation)
            └─ [PaymentProcessing] span (PaymentService, SpanKind.Server — lê traceparent do header)
```

### Como a propagação funciona

- **OrderService** usa `AddHttpClientInstrumentation()` do OpenTelemetry SDK, que injeta automaticamente o header `traceparent` em toda chamada `HttpClient.SendAsync()`
- **PaymentService** usa `SimpleTextMapPropagator` para ler o header `traceparent` e criar o span filho com o mesmo `traceId`
- Todos os spans são exportados para o **Alloy** via OTLP gRPC (porta 4317), que os encaminha para o **Tempo**

### Endpoints disponíveis

**Order Service** (`http://localhost:8080`):
- `GET /` — retorna "OK", incrementa contador `otel_order`
- `GET /call-payment-service` — chama o Payment Service com propagação de contexto de trace

**Payment Service** (`http://localhost:8085`):
- `GET /` — simula processamento de pagamento, cria span filho linkado ao trace do Order Service

### Ver traces no Grafana
1. Acesse Grafana → **Explore**
2. Selecione datasource **Tempo**
3. Faça uma busca por `service.name = "Order Service"` ou use a aba **Search**
4. Clique em um trace para ver o waterfall completo

---

## Service Map (Grafo de Serviços)

O **Service Map** mostra visualmente as dependências entre serviços com métricas de latência e taxa de erros em tempo real.

### Como funciona

O `metrics_generator` do Tempo analisa os spans recebidos e emite métricas para o Prometheus:
- `traces_service_graph_request_total` — total de requisições entre serviços
- `traces_service_graph_request_duration_seconds` — histograma de latência
- `traces_spanmetrics_*` — métricas por operação

O Grafana consulta essas métricas diretamente do Prometheus usando o datasource Tempo como ponto de entrada.

### Ver o Service Map
1. Acesse Grafana → **Explore**
2. Selecione datasource **Tempo**
3. Clique na aba **Service Map**

---

## Configuração

### Variáveis de ambiente (`.env`)

```env
# Portas
PROMETHEUS_PORT=9090
LOKI_PORT=3100
ALLOY_HTTP_PORT=8081
ALLOY_OTLP_GRPC_PORT=4317
ALLOY_OTLP_HTTP_PORT=4318
TEMPO_HTTP_PORT=3200
GRAFANA_PORT=3000
ORDER_SERVICE_PORT=8080
PAYMENT_SERVICE_PORT=8085

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin

# MinIO (storage do Tempo)
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=admin123
MINIO_BUCKET_NAME=tempo
```

### Alloy (`alloy_etc/config.alloy`)

- Recebe OTLP gRPC (4317) e HTTP (4318)
- Envia métricas → Prometheus via remote_write
- Envia logs → Loki
- Envia traces → Tempo via OTLP HTTP

### Tempo (`tempo.yaml`)

- Backend de storage: MinIO (S3 compatível)
- `metrics_generator` habilitado com processors `service-graphs` e `span-metrics`
- Retenção de traces: 24h
- Remote write das métricas geradas → Prometheus

### Grafana (provisionamento automático)

Datasources provisionados em `grafana/provisioning/datasources/`:
- **Prometheus** (`uid: prometheus`) — métricas e service map
- **Tempo** — traces, com `serviceMap` linkado ao Prometheus
- **Loki** — logs

Dashboards provisionados em `grafana/provisioning/dashboards/json/`:
- `logs-dashboard.json` — visualização de logs
- `opentelemetry-total-order.json` — métricas do Order Service

---

## Volumes

| Volume | Montagem | Propósito |
|--------|----------|-----------|
| `prometheus_volume/` | `/etc/prometheus` | Configuração do Prometheus |
| `alloy_etc/` | `/etc/alloy` | `config.alloy` |
| `alloy_log/` | `/var/log` | Logs consumidos pelo Alloy |
| `grafana_volume` | `/var/lib/grafana` | Dados do Grafana (Docker managed) |

---

## Troubleshooting

### Ver logs de um serviço
```bash
docker compose logs -f tempo
docker compose logs -f alloy
docker compose logs -f order-service
docker compose logs -f payment-service
```

### Verificar saúde dos serviços
```bash
curl http://localhost:9090/-/ready    # Prometheus
curl http://localhost:8081/ready      # Alloy
curl http://localhost:3100/ready      # Loki
curl http://localhost:3200/ready      # Tempo
curl http://localhost:3000/api/health # Grafana
```

### Traces não aparecem no Tempo
1. Confirmar que Order Service está rodando: `docker compose logs -f order-service`
2. Confirmar que Alloy está encaminhando: `docker compose logs -f alloy`
3. Verificar que Tempo está saudável: `curl http://localhost:3200/ready`
4. MinIO deve estar com o bucket `tempo` criado (feito automaticamente pelo `minio-init`)

### Service Map não aparece
1. Confirmar que Tempo está inicializado com `metrics_generator` habilitado
2. Fazer algumas requisições para gerar spans: `curl http://localhost:8080/call-payment-service`
3. Aguardar ~15s para as métricas chegarem ao Prometheus
4. Verificar métricas no Prometheus: buscar por `traces_service_graph_request_total`

### Limpar tudo e recomeçar
```bash
docker compose down -v
./start.sh
```


