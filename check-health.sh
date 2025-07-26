#!/bin/bash
# check-health.sh

NAMESPACE="monitoring"
echo "⏳ Checking health of monitoring components in namespace: $NAMESPACE"

# Check Deployments
for deploy in "prometheus-server" "grafana" "kafka-ui"; do
  echo "🔍 $deploy..."
  if kubectl rollout status deployment "$deploy" -n "$NAMESPACE" --timeout=10s; then
    echo "✅ $deploy is healthy"
  else
    echo "⚠️  $deploy not ready"
  fi
done

# Check Kafka StatefulSet
echo "🔍 kafka-controller..."
if kubectl rollout status statefulset kafka-controller -n "$NAMESPACE" --timeout=10s; then
  echo "✅ kafka-controller is healthy"
else
  echo "⚠️  kafka-controller not ready"
fi

echo "✅ Health check completed."
