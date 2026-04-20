#!/bin/bash

set -e

echo "Parando stack de monitoramento..."

# Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "Erro: Docker ou Docker Compose não encontrado!"
    exit 1
fi

# 1. Parar gerador de logs (se estiver rodando)
echo "Parando gerador de logs..."
pkill -f "python3 ./log-generator.py" 2>/dev/null || true
sleep 1

# 2. Parar containers e remover volumes
echo "Parando e removendo containers..."
docker compose down -v

# 3. Limpar diretórios de volume (opcional - comentar se quiser preservar dados)
echo "Limpando diretórios de volume..."
if [ -d "./alloy_log" ]; then
  rm -rf ./alloy_log
  echo "  ✓ Diretório alloy_log removido"
fi

echo "Limpando diretórios de volume..."
if [ -d "./alloy_etc" ]; then
  rm -rf ./alloy_etc
  echo "  ✓ Diretório alloy_etc removido"
fi

if [ -d "./prometheus_volume" ]; then
  rm -rf ./prometheus_volume
  echo "  ✓ Diretório prometheus_volume removido"
fi

# 3. Remover volumes residuais do Grafana
echo "Removendo volumes residuais..."
docker volume rm alloy_log_02 alloy_etc_02 prometheus_volume_alloy_02 2>/dev/null || true

# 5. Limpar arquivo de log do gerador
if [ -f "/tmp/log-generator.log" ]; then
  rm /tmp/log-generator.log
fi

echo ""
echo "✅ Shutdown concluído com sucesso!"
echo "Todos os containers foram parados e volumes foram removidos."
