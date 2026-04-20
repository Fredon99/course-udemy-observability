# Observabilidade Moderna: OpenTelemetry, Prometheus e Grafana Alloy

---

# 🧠 Visão Geral

Hoje existem **duas gerações de observabilidade** convivendo:

1. **Stack clássica Prometheus**
2. **Stack moderna baseada em OpenTelemetry**

O ponto principal:

> Observabilidade moderna deixou de ser ferramentas isoladas e virou **um pipeline de telemetria**.

---

# 📦 Componentes Fundamentais

## 🔹 OpenTelemetry (OTEL)

**OpenTelemetry** é um **padrão aberto** para gerar telemetria.

Ele define:

* APIs
* SDKs
* Formato de dados
* Protocolo OTLP

A aplicação passa a gerar:

```
Metrics
Logs
Traces
```

---

## 🔹 Exporters

⚠️ **Exporter NÃO é uma ferramenta separada.**

Exporter = **mecanismo de envio de dados**.

Normalmente vive:

* dentro da aplicação
* ou dentro do Collector

### Exemplos

```
OTLP Exporter
Prometheus Exporter
Jaeger Exporter
Zipkin Exporter
Datadog Exporter
```

---

## 🔹 Collector (O coração da arquitetura moderna)

O Collector recebe, processa e encaminha telemetria.

Pipeline padrão OTEL:

```
Receivers → Processors → Exporters
```

Funções:

* agregação
* sampling
* transformação
* roteamento
* desacoplamento do backend

---

# 🚀 O que é Grafana Alloy?

**Grafana Alloy** é um agente unificado criado pela Grafana Labs.

Ele combina:

```
OpenTelemetry Collector
+ Prometheus Agent
+ Promtail
+ pipeline unificado de observabilidade
```

👉 Alloy **é um Collector**, não um exporter.

---

# 🏗️ Stack Prometheus Clássica

Modelo histórico.

## Arquitetura

```
Application
     │
     └── /metrics endpoint
            │
            ▼
      Prometheus (SCRAPE / PULL)
            │
            ▼
          Grafana
```

## Características

✅ Pull model
✅ Simples
✅ Muito estável
❌ Métricas apenas
❌ Logs e traces separados
❌ Forte acoplamento

---

## Fluxo real

```
node_exporter
cadvisor
app exporter
        ↓
     Prometheus
        ↓
      TSDB
        ↓
      Grafana
```

---

# 🌎 Stack Moderna OpenTelemetry + Alloy

A arquitetura mudou completamente.

## Arquitetura Moderna

```
Application
   │
   └── OTEL SDK
         │
         └── OTLP Exporter
                 │
                 ▼
        Grafana Alloy / OTEL Collector
          │        │        │
          │        │        │
          ▼        ▼        ▼
     Prometheus    Loki     Tempo
      (metrics)    (logs)   (traces)
           │
           ▼
         Grafana
```

---

## Papel de cada componente

| Componente     | Função            |
| -------------- | ----------------- |
| App + OTEL SDK | gera telemetria   |
| Exporter       | envia dados       |
| Alloy          | coleta e processa |
| Prometheus     | armazena métricas |
| Loki           | logs              |
| Tempo          | traces            |
| Grafana        | visualização      |

---

# 🔥 Mudança Conceitual Mais Importante

Antes:

```
Ferramentas separadas
```

Agora:

```
Pipeline de Telemetria
```

O **Collector virou o centro da arquitetura**.

---

# 🧩 Modelos de Coleta

## 1️⃣ Pull Model (Prometheus)

```
Prometheus → scrape → Application
```

Características:

* Prometheus inicia conexão
* precisa descobrir targets
* depende de endpoints `/metrics`

---

## 2️⃣ Push Model (OpenTelemetry)

```
Application → OTLP → Collector
```

Características:

* aplicação envia dados
* independente de backend
* cloud-native
* funciona atrás de NAT / serverless

---

# ⭐ Insight Profissional

OpenTelemetry desacopla:

```
Instrumentação  ≠  Backend Observability
```

Você instrumenta **uma vez** e decide depois:

* Grafana
* Prometheus
* Datadog
* New Relic
* Elastic
* Honeycomb

---

# 🚀 O que o Alloy pode substituir

Alloy pode substituir:

* Promtail
* OTEL Collector
* Prometheus Agent
* vários sidecars de observabilidade

---

# 🏢 Arquitetura usada por empresas modernas

```
Apps → OpenTelemetry → Collector → Observability Backend
```

Esse é exatamente o modelo usado por:

* Datadog
* New Relic
* Grafana Cloud
* Honeycomb

---

# 🎯 Regra Mental Definitiva

```
Application generates telemetry
Collector controls telemetry
Backend stores telemetry
Grafana visualizes telemetry
```

---

# 🧠 Frase nível Senior DevOps

> OpenTelemetry standardizes telemetry generation while collectors such as Alloy decouple instrumentation from observability backends like Prometheus, Loki, Tempo or Datadog.

---

# 📊 Comparação Final

| Aspecto        | Prometheus Clássico | OpenTelemetry Moderno |
| -------------- | ------------------- | --------------------- |
| Coleta         | Pull                | Push                  |
| Métricas       | ✅                   | ✅                     |
| Logs           | ❌                   | ✅                     |
| Traces         | ❌                   | ✅                     |
| Escalabilidade | Média               | Alta                  |
| Cloud Native   | Parcial             | Total                 |
| Vendor lock    | Médio               | Baixo                 |

---

# ✅ Resumo Final

```
Prometheus = Metrics backend + scraper
Alloy       = Telemetry collector
OpenTelemetry = Telemetry standard
Grafana     = Visualization
```

---
