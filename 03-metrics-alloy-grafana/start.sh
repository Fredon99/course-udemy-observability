#!/bin/bash

set -e

echo "Iniciando setup do stack de Prometheus + Alloy + Grafana..."

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
# Prometheus Version
PROMETHEUS_VERSION=v2.51.0

# Node Exporter Version
NODE_EXPORTER_VERSION=v1.8.0

# Grafana Version
GRAFANA_VERSION=12.4.2

# Grafana Configuration
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false
EOF
  echo "✓ Arquivo .env criado com versões estáveis"
else
  echo "✓ Arquivo .env já existe"
fi

# 3. Criar diretórios de volumes e arquivos necessários
echo "Criando diretórios de volumes..."
mkdir -p ./prometheus_volume
mkdir -p ./alloy_volume
mkdir -p ./grafana/provisioning/datasources
mkdir -p ./grafana/provisioning/dashboards

# 4. Copiar configuração do Alloy
echo "Configurando Alloy..."
if [ -f "./config.alloy" ]; then
  cp ./config.alloy ./alloy_volume/config.alloy
  echo "✓ Configuração do Alloy copiada"
else
  echo "Erro: arquivo config.alloy não encontrado!"
  exit 1
fi

# 5. Iniciar os containers
echo "Iniciando containers com Docker Compose..."
docker compose up -d

# 6. Feedback final
echo ""
echo "Setup concluído com sucesso!"
echo ""
echo "Serviços rodando:"
echo "  - Prometheus: http://localhost:9090"
echo "  - Alloy:    http://localhost:8081"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo ""
echo "Para parar o stack: ./stop.sh"
echo "Ver logs dos containers: docker compose logs -f"
echo "  - Ver logs do Grafana: docker compose logs -f grafana"
echo "  - Ver logs do Alloy: docker compose logs -f alloy"
echo "  - Ver logs do Prometheus: docker compose logs -f prometheus"
echo "  - Parar containers: docker compose down"