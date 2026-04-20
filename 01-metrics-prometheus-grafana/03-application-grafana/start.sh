#!/bin/bash

set -e

echo "Iniciando setup do stack de monitoramento + ShoeHub Application..."

# 1. Criar diretório de volumes
echo "Criando diretório de volumes..."
mkdir -p ./prometheus_volume_bind

# 2. Copiar arquivo prometheus.yml
if [ -f "./prometheus.yml" ]; then
  echo "Copiando arquivo prometheus.yml..."
  cp ./prometheus.yml ./prometheus_volume_bind/prometheus.yml
else
  echo "Erro: arquivo prometheus.yml não encontrado no diretório atual!"
  exit 1
fi

# 2.5. Criar diretórios de provisioning do Grafana (já estão em git, mas certifica)
echo "Garantindo diretórios de provisioning do Grafana..."
mkdir -p ./grafana/provisioning/datasources
mkdir -p ./grafana/provisioning/dashboards

# 3. Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null && ! command -v docker &> /dev/null; then
    echo "Erro: Docker ou Docker Compose não encontrado! Por favor, instale primeiro."
    exit 1
fi

# 4. Iniciar os containers (fará build automático se necessário)
echo "Construindo imagem da aplicação e iniciando containers com Docker Compose..."
docker compose up -d

# 5. Feedback final
echo ""
echo "Setup concluído com sucesso!"
echo ""
echo "Serviços rodando:"
echo "  - ShoeHub Application: http://localhost:8080"
echo "  - Prometheus: http://localhost:9090"
echo "  - Node Exporter: http://localhost:9100"
echo "  - Grafana: http://localhost:3000 (admin/admin)"
echo ""
echo "Grafana provisioning:"
echo "  - Data Source (Prometheus): Configurado automaticamente ✓"
echo "  - Dashboard (ShoeHub): Carregado automaticamente ✓"
echo ""
echo "Comandos úteis:"
echo "  - Ver logs: docker compose logs -f"
echo "  - Ver logs do Grafana: docker compose logs -f grafana"
echo "  - Parar containers: docker compose down"
echo "  - Rebuild imagem: docker compose up -d --build"