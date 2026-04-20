#!/bin/bash

set -e

echo "Iniciando setup do stack de Loki + Promtail + Grafana..."

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
# Loki Configuration
LOKI_VERSION=3.7.1

# Promtail Configuration
PROMTAIL_VERSION=3.6.8

# Grafana Configuration
GRAFANA_VERSION=12.4.2
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
mkdir -p ./promtail_log
mkdir -p ./promtail_etc
mkdir -p ./grafana/provisioning/datasources
mkdir -p ./grafana/provisioning/dashboards

echo "Criando arquivo de log inicial..."
touch ./promtail_log/loki.log

# 4. Copiar configuração do Promtail
echo "Configurando Promtail..."
if [ -f "./config.yml" ]; then
  cp ./config.yml ./promtail_etc/config.yml
  echo "✓ Configuração do Promtail copiada"
else
  echo "Erro: arquivo config.yml não encontrado!"
  exit 1
fi

# 5. Iniciar os containers
echo "Iniciando containers com Docker Compose..."
docker compose up -d

# 6. Aguardar serviços ficarem prontos
echo "Aguardando serviços ficarem prontos..."
sleep 5

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
echo "  - Loki:    http://localhost:3100"
echo "  - Promtail: http://localhost:9080"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo ""
echo "Arquivos de log:"
echo "  - Logs de aplicação: ./promtail_log/loki.log"
echo "  - Logs do Promtail: ./promtail_etc/config.yml"
echo ""
echo "Para parar o stack: ./stop.sh"
echo "Para parar apenas o gerador de logs: kill $LOG_GEN_PID"
echo "Ver logs dos containers: docker compose logs -f"
echo "  - Ver logs do Grafana: docker compose logs -f grafana"
echo "  - Parar containers: docker compose down"
echo "  - Rebuild imagem: docker compose up -d --build"