#!/bin/bash

set -e

echo "Parando stack de monitoramento..."

# Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "Erro: Docker ou Docker Compose não encontrado!"
    exit 1
fi

# 1. Parar containers e remover volumes
echo "Parando e removendo containers..."
docker compose down -v

# 2. Limpar diretórios de volume (opcional - comentar se quiser preservar dados)
echo "Limpando diretórios de volume..."
if [ -d "./alloy_volume" ]; then
  rm -rf ./alloy_volume
  echo "  ✓ Diretório alloy_volume removido"
fi

if [ -d "./prometheus_volume" ]; then
  rm -rf ./prometheus_volume
  echo "  ✓ Diretório prometheus_volume removido"
fi

# 3. Remover volumes residuais do Grafana
echo "Removendo volumes residuais..."
docker volume rm grafana_volume_alloy_01 alloy_volume_alloy_01 prometheus_volume_alloy_01 2>/dev/null || true

echo ""
echo "✅ Shutdown concluído com sucesso!"
echo "Todos os containers foram parados e volumes foram removidos."
