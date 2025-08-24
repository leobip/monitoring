#!/bin/bash
set -euo pipefail

TOOL="${1:-}"

function add_repos() {
  echo "📦 Adding Helm repositories..."
  helm repo add bitnami https://charts.bitnami.com/bitnami || true
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
  helm repo add grafana https://grafana.github.io/helm-charts || true
  helm repo update
}

function install_kafka_zookeeper() {
  echo "🚀 Installing Kafka + Zookeeper & Kafka-UI from manifest..."
  kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f kafka-zookeeper/kafka.yaml
  echo "✅ Kafka installed in namespace 'kafka'"
}

function uninstall_kafka_zookeeper() {
  echo "🗑️ Uninstalling Kafka + Zookeeper & Kafka-UI..."
  kubectl delete -n kafka -f kafka-zookeeper/kafka.yaml --ignore-not-found
  kubectl delete namespace kafka --ignore-not-found
  echo "✅ Kafka uninstalled"
}

function install_prometheus() {
  echo "📊 Installing Prometheus with Helm..."
  helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --values values/prometheus-values.yaml
  echo "✅ Prometheus installed in namespace 'monitoring'"
}

function uninstall_prometheus() {
  echo "🗑️ Uninstalling Prometheus..."
  helm uninstall prometheus -n monitoring || true
  echo "✅ Prometheus uninstalled"
}

function install_grafana() {
  echo "📈 Installing Grafana with Helm..."
  helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    --values values/grafana-values.yaml
  echo "✅ Grafana installed in namespace 'monitoring'"
}

function uninstall_grafana() {
  echo "🗑️ Uninstalling Grafana..."
  helm uninstall grafana -n monitoring || true
  echo "✅ Grafana uninstalled"
}

function install_all() {
  install_kafka_zookeeper
  install_prometheus
  install_grafana
}

function uninstall_all() {
  uninstall_kafka_zookeeper
  uninstall_prometheus
  uninstall_grafana
}

echo "🔍 Ensuring 'monitoring' namespace exists..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

add_repos

# If no param → show menu
if [[ -z "$TOOL" ]]; then
  echo "Select:"
  echo "1) Install Kafka"
  echo "2) Install Prometheus"
  echo "3) Install Grafana"
  echo "4) Install ALL"
  echo "5) Unistall Kafka"
  echo "6) Unistall Prometheus"
  echo "7) Unistall Grafana"
  echo "8) Unistall ALL"
  echo "9) Exit"
  read -rp "Select number: " CHOICE

  case "$CHOICE" in
    1) install_kafka_zookeeper ;;
    2) install_prometheus ;;
    3) install_grafana ;;
    4) install_all ;;
    5) uninstall_kafka_zookeeper ;;
    6) uninstall_prometheus ;;
    7) uninstall_grafana ;;
    8) uninstall_all ;;
    9) echo "👋 Exiting..."; exit 0 ;;
    *) echo "❌ Opción inválida"; exit 1 ;;
  esac
  exit 0
fi

# CLI options
case "$TOOL" in
  kafka) install_kafka_zookeeper ;;
  prometheus) install_prometheus ;;
  grafana) install_grafana ;;
  all) install_all ;;
  uninstall-kafka) uninstall_kafka_zookeeper ;;
  uninstall-prometheus) uninstall_prometheus ;;
  uninstall-grafana) uninstall_grafana ;;
  uninstall-all) uninstall_all ;;
  *)
    echo "❌ Unknown tool: $TOOL"
    echo "Usage: $0 [kafka|prometheus|grafana|all|uninstall-kafka|uninstall-prometheus|uninstall-grafana|uninstall-all]"
    exit 1
    ;;
esac

echo "✅ Operation completed!"
