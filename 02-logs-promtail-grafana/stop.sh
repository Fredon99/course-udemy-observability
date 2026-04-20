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

# 3. Limpar diretórios de volume (opcional - comentar se quiser preservar logs)
echo "Limpando diretórios de volume..."
if [ -d "./promtail_log" ]; then
  rm -rf ./promtail_log
  echo "  ✓ Diretório promtail_log removido"
fi

if [ -d "./promtail_etc" ]; then
  rm -rf ./promtail_etc
  echo "  ✓ Diretório promtail_etc removido"
fi

# 4. Remover volumes residuais do Grafana
echo "Removendo volumes residuais..."
docker volume rm grafana_volume_loki 2>/dev/null || true

# 5. Limpar arquivo de log do gerador
if [ -f "/tmp/log-generator.log" ]; then
  rm /tmp/log-generator.log
fi

echo ""
echo "✅ Shutdown concluído com sucesso!"
echo "Todos os containers foram parados e volumes foram removidos."
