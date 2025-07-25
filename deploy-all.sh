#!/bin/bash
set -euo pipefail

echo "📦 Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts || true
helm repo update

echo "🔍 Ensuring 'monitoring' namespace exists..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "🔧 Applying PersistentVolumeClaims (PVCs)..."
kubectl apply -f pv/

echo "🚀 Installing Kafka..."
helm upgrade --install kafka bitnami/kafka \
  --namespace monitoring \
  --values values/kafka-values.yaml

echo "📦 Installing Kafka UI..."
helm upgrade --install kafka-ui kafka-ui/kafka-ui \
  --namespace monitoring \
  --values values/kafka-ui-values.yaml

echo "📊 Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values values/prometheus-values.yaml

echo "📈 Installing Grafana..."
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values values/grafana-values.yaml

echo "✅ All tools installed successfully!"
echo "🔗 Access Grafana at: http://localhost:30093 (default user/pass: admin / admin)"
