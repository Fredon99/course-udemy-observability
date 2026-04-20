#!/bin/bash

set -e

echo "Parando containers e removendo volumes..."

# Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "Erro: Docker ou Docker Compose não encontrado!"
    exit 1
fi

# Parar containers e remover volumes
docker compose down -v

# Remover diretório de volumes do Prometheus
if [ -d "./prometheus_volume_bind" ]; then
  echo "Removendo diretório de volumes do Prometheus..."
  rm -rf ./prometheus_volume_bind
fi

# Remover volume do Grafana criado pelo Docker (opcional)
echo "Removendo volumes residuais..."
docker volume rm grafana_volume_02_application 2>/dev/null || true

echo ""
echo "Shutdown concluído com sucesso!"
echo "Todos os containers foram parados, os volumes foram removidos e o diretório prometheus_volume_bind foi deletado."
