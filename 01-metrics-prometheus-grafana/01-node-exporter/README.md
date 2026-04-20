# Prometheus + Node Exporter Setup

Stack de monitoramento com Prometheus e Node Exporter usando Docker Compose.

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
- Iniciar os containers com Docker Compose

O script `stop.sh` irá:
- Parar todos os containers
- Remover os volumes criados

### Opção 2: Manual

```bash
# 1. Criar diretório
mkdir -p ./prometheus_volume_bind

# 2. Copiar arquivo prometheus.yml
cp prometheus.yml ./prometheus_volume_bind/prometheus.yml

# 3. Iniciar containers
docker compose up -d

# 4. Parar containers e remover volumes
docker compose down -v
```

## Acessar os Serviços

- **Prometheus**: http://localhost:9090
- **Node Exporter**: http://localhost:9100/metrics

## Arquivo `prometheus.yml`

Localizado em: `./prometheus_volume_bind/prometheus.yml`

O arquivo é copiado automaticamente pelo script durante o setup. Você pode editar conforme necessário.

## Comandos Úteis

```bash
# Ver status dos containers
docker compose ps

# Ver logs
docker compose logs -f

# Ver logs de um serviço específico
docker compose logs -f prometheus
docker compose logs -f node-exporter

# Reiniciar containers
docker compose restart

# Rebuild da imagem
docker compose up -d --build
```

## Estrutura de Arquivos

```
.
├── compose.yaml                    # Configuração do Docker Compose
├── setup.sh                        # Script de inicialização automática
├── prometheus.yml                  # Configuração do Prometheus
├── README.md                       # Este arquivo
└── prometheus_volume_bind/         # Volume bind (criado automaticamente)
    └── prometheus.yml             # Cópia da configuração
```

## Recursos

- Docker Compose para orquestração
- Prometheus para coleta de métricas
- Node Exporter para métricas do sistema
- Volume bind para persistência de configuração

## Dicas

- Edite `prometheus.yml` para adicionar novos targets
- Adicione rules para alertas conforme necessário
- Os dados do Prometheus são armazenados em memória (pode ser persistido se necessário)
