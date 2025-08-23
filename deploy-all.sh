#!/bin/bash
set -euo pipefail

TOOL="${1:-all}"

function add_repos() {
  echo "📦 Adding Helm repositories..."
  helm repo add bitnami https://charts.bitnami.com/bitnami || true
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
  helm repo add grafana https://grafana.github.io/helm-charts || true
  helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts || true
  helm repo update
}

function install_kafka_zookeeper() {
  echo "🚀 Installing Kafka from manifest..."
  kubectl apply -f kafka-zookeeper/kafka.yaml
}

# function install_helm_kafka() {
#   echo "🚀 Installing Helm Kafka..."
#   helm upgrade --install kafka bitnami/kafka \
#   --namespace monitoring \
#   --values values/kafka-values.yaml
# }

# function install_kafka_ui() {
#   echo "📦 Installing Kafka UI..."
#   helm upgrade --install kafka-ui kafka-ui/kafka-ui \
#     --namespace monitoring \
#     --values values/kafka-ui-values.yaml
# }

function install_prometheus() {
  echo "📊 Installing Prometheus..."
  helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --values values/prometheus-values.yaml
}

function install_grafana() {
  echo "📈 Installing Grafana..."
  helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    --values values/grafana-values.yaml
}


echo "🔍 Ensuring 'monitoring' namespace exists..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

add_repos

case "$TOOL" in
  kafka) install_kafka_zookeeper ;;
  #kafka-helm) install_helm_kafka ;;
  #kafka-ui) install_kafka_ui ;;
  prometheus) install_prometheus ;;
  grafana) install_grafana ;;
  all)
    install_kafka_zookeeper
    # install_helm_kafka
    # install_kafka_ui
    install_prometheus
    install_grafana
    ;;
  *)
    echo "❌ Unknown tool: $TOOL"
    echo "Usage: $0 [all|kafka|kafka-ui|prometheus|grafana]"
    exit 1
    ;;
esac

echo "✅ Installation completed!"

