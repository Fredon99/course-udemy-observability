#!/bin/bash

set -e

echo "Iniciando setup do stack de Prometheus + Alloy + Tempo + Grafana..."

# 1. Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "Erro: Docker ou Docker Compose não encontrado! Por favor, instale primeiro."
    exit 1
fi

# 2. Criar arquivo .env se não existir
echo "Verificando arquivo de ambiente..."
if [ ! -f ".env" ]; then
  echo "Criando arquivo .env com versões estáveis pinadas..."
  cat > .env << 'EOF'
# ============================================
# PROMETHEUS CONFIGURATION
# ============================================
PROMETHEUS_IMAGE=prom/prometheus:v2.51.0
PROMETHEUS_PORT=9090

# ============================================
# LOKI CONFIGURATION
# ============================================
LOKI_IMAGE=grafana/loki:3.7.1
LOKI_PORT=3100

# ============================================
# ALLOY CONFIGURATION
# ============================================
ALLOY_IMAGE=grafana/alloy:v1.14.2
ALLOY_HTTP_PORT=8081
ALLOY_OTLP_GRPC_PORT=4317
ALLOY_OTLP_HTTP_PORT=4318

# ============================================
# TEMPO CONFIGURATION
# ============================================
TEMPO_IMAGE=grafana/tempo:2.4.1
TEMPO_HTTP_PORT=3200
TEMPO_OTLP_PORT=4317

# ============================================
# GRAFANA CONFIGURATION
# ============================================
GRAFANA_IMAGE=grafana/grafana-oss:12.4.2
GRAFANA_PORT=3000
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false

# ============================================
# ORDER SERVICE CONFIGURATION
# ============================================
ORDER_SERVICE_IMAGE=order-service:1.0
ORDER_SERVICE_PORT=8080

# ============================================
# MINIO CONFIGURATION (S3 Storage for Tempo)
# ============================================
MINIO_IMAGE=minio/minio:RELEASE.2025-09-07T16-13-09Z
MINIO_MC_IMAGE=minio/mc:RELEASE.2025-08-13T08-35-41Z
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=admin123
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_BUCKET_NAME=tempo
MINIO_ACCESS_KEY=admin
MINIO_SECRET_KEY=admin123
MINIO_ENDPOINT=minio:9000
EOF
  echo "✓ Arquivo .env criado com versões estáveis"
else
  echo "✓ Arquivo .env já existe"
fi

# 3. Criar diretórios de volumes e arquivos necessários
echo "Criando diretórios de volumes..."
mkdir -p ./prometheus_volume
mkdir -p ./alloy_etc
mkdir -p ./alloy_log
mkdir -p ./grafana/provisioning/datasources
mkdir -p ./grafana/provisioning/dashboards

echo "Criando arquivo de log inicial..."
touch ./alloy_log/test.log

# 4. Copiar configuração do Alloy
echo "Configurando Alloy..."
if [ -f "./config.alloy" ]; then
  cp ./config.alloy ./alloy_etc/config.alloy
  echo "✓ Configuração do Alloy copiada"
else
  echo "Erro: arquivo config.alloy não encontrado!"
  exit 1
fi

# 5. Iniciar os containers
echo "Iniciando containers com Docker Compose..."
docker compose up -d


# 6. Aguardar serviços ficarem prontos
echo "Aguardando serviços ficarem prontos..."
sleep 15

# 7. Iniciar gerador de logs em background
echo "Iniciando gerador de logs em background..."
python3 ./log-generator.py --config ./directories.txt --interval 30 > /tmp/log-generator.log 2>&1 &
LOG_GEN_PID=$!
echo "✓ Gerador de logs iniciado (PID: $LOG_GEN_PID)"
echo "  Ver logs: tail -f /tmp/log-generator.log"

# 8. Feedback final
echo ""
echo "Setup concluído com sucesso!"
echo ""
echo "Serviços rodando:"
echo "  - Prometheus: http://localhost:9090"
echo "  - Alloy:    http://localhost:8081"
echo "  - Tempo:    http://localhost:3200"
echo "  - Minio:    http://localhost:9000 (admin/admin123)"
echo "  - Minio Console: http://localhost:9001 (admin/admin123)"
echo "  - Loki:     http://localhost:3100"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo ""
echo "Para parar o stack: ./stop.sh"
echo "Ver logs dos containers: docker compose logs -f"
echo "  - Ver logs do Grafana: docker compose logs -f grafana"
echo "  - Ver logs do Alloy: docker compose logs -f alloy"
echo "  - Ver logs do Tempo: docker compose logs -f tempo"
echo "  - Ver logs do Prometheus: docker compose logs -f prometheus"
echo "  - Parar containers: docker compose down"