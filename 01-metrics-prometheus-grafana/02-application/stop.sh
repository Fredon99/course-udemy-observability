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

# Remover diretório de volumes
if [ -d "./prometheus_volume_bind" ]; then
  echo "Removendo diretório de volumes..."
  rm -rf ./prometheus_volume_bind
fi

echo ""
echo "Shutdown concluído com sucesso!"
echo "Todos os containers foram parados, os volumes foram removidos e o diretório prometheus_volume_bind foi deletado."
