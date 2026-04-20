# Observability Stack: Prometheus + Node Exporter + ShoeHub Application

Stack completo de observabilidade com Prometheus (métricas), Node Exporter (métricas do sistema) e aplicação ShoeHub (ASP.NET Core com instrumentação Prometheus).

## Quick Start

### Opção 1: Automático (Recomendado)

Iniciar:
```bash
./start.sh
```

Parar:
```bash
./stop.sh
```

O script `start.sh` irá:
- Criar o diretório `prometheus_volume_bind`
- Copiar o arquivo `prometheus.yml`
- Fazer build da imagem da aplicação ShoeHub
- Iniciar todos os containers com Docker Compose

O script `stop.sh` irá:
- Parar todos os containers
- Remover os volumes criados

### Opção 2: Manual

```bash
# 1. Criar diretório
mkdir -p ./prometheus_volume_bind

# 2. Copiar arquivo prometheus.yml
cp prometheus.yml ./prometheus_volume_bind/prometheus.yml

# 3. Fazer build e iniciar containers
docker compose up -d --build

# 4. Parar containers e remover volumes
docker compose down -v
```

## Acessar os Serviços

- **ShoeHub Application**: http://localhost:8080
- **Prometheus**: http://localhost:9090
- **Node Exporter**: http://localhost:9100/metrics

## Arquivo `prometheus.yml`

Localizado em: `./prometheus_volume_bind/prometheus.yml`

O arquivo é copiado automaticamente pelo script durante o setup. Você pode editar conforme necessário.

## ShoeHub Application

Aplicação ASP.NET Core que gera métricas de vendas de sapatos, integrada com Prometheus:
- Linguagem: C#
- Framework: ASP.NET Core 9.0
- Métricas: prometheus-net
- Logging: Serilog

A imagem é construída automaticamente do Dockerfile quando você executa `docker compose up`.

## Comandos Úteis

```bash
# Ver status dos containers
docker compose ps

# Ver logs (todos os serviços)
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f prometheus
docker compose logs -f node-exporter
docker compose logs -f shoehub

# Reiniciar containers
docker compose restart

# Reconstruir imagem da aplicação e iniciar
docker compose up -d --build

# Reconstruir imagem sem cache (garante build completo)
docker compose up -d --build --no-cache
```

## Estrutura de Arquivos

```
.
├── docker-compose.yaml             # Configuração do Docker Compose (com build automático)
├── setup.sh                        # Script de inicialização automática
├── prometheus.yml                  # Configuração do Prometheus
├── README.md                       # Este arquivo
├── ShoeHubV2/                      # Aplicação ASP.NET Core
│   ├── Dockerfile                  # Build da aplicação
│   ├── Program.cs                  # Código principal
│   ├── ShoeHubV2.csproj            # Definição do projeto
│   ├── appsettings.json            # Configurações
│   └── Properties/                 # (opcional para desenvolvimento local)
└── prometheus_volume_bind/         # Volume bind (criado automaticamente)
    └── prometheus.yml             # Cópia da configuração
```

## Recursos

- Docker Compose para orquestração de containers
- **Prometheus** para coleta e armazenamento de métricas
- **Node Exporter** para métricas do sistema
- **ShoeHub Application** (ASP.NET Core 9.0) com instrumentação Prometheus
- Volume bind para persistência de configuração do Prometheus
- Network compartilhada entre todos os serviços

## Dicas

- Edite `prometheus.yml` para adicionar novos targets de scraping
- Adicione rules para alertas conforme necessário
- Os dados do Prometheus são armazenados em memória (pode ser persistido se necessário)
- Se modificar o código da ShoeHub, execute `docker compose up -d --build` para reconstruir
- Use `docker compose logs -f shoehub` para debugar a aplicação
- As métricas da ShoeHub estão disponíveis em `/metrics` quando a aplicação está rodando
