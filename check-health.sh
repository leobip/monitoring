#!/bin/bash
# check-health.sh

set -euo pipefail

rollout_wait() {
  local ns="$1" kind="$2" name="$3" timeout="${4:-30s}"
  echo "🔍 ${name} (${kind})..."
  if kubectl get "$kind" "$name" -n "$ns" >/dev/null 2>&1; then
    if kubectl rollout status "$kind/$name" -n "$ns" --timeout="$timeout"; then
      echo "✅ $name is healthy"
    else
      echo "⚠️  $name not ready"
    fi
  else
    echo "⚠️  $kind/$name not found"
  fi
}

# ---------- MONITORING ----------
MON_NS="monitoring"
echo "⏳ Checking health of monitoring components in namespace: $MON_NS"
rollout_wait "$MON_NS" deployment grafana 20s

# Prometheus chart suele crear 'prometheus-server' como Deployment
rollout_wait "$MON_NS" deployment prometheus-server 30s

# ---------- KAFKA ----------
KAFKA_NS="kafka"
echo -e "\n⏳ Checking health of Kafka components in namespace: $KAFKA_NS"

# kafka-ui es Deployment en tu manifiesto
rollout_wait "$KAFKA_NS" deployment kafka-ui 30s

# Kafka y Zookeeper: autodetectar si son Deployment o StatefulSet
detect_kind() {
  local ns="$1" base="$2"
  if kubectl get deployment "$base" -n "$ns" >/dev/null 2>&1; then
    echo "deployment"
  elif kubectl get statefulset "$base" -n "$ns" >/dev/null 2>&1; then
    echo "statefulset"
  else
    echo ""  # no existe
  fi
}

KAFKA_KIND="$(detect_kind "$KAFKA_NS" kafka)"
if [[ -n "$KAFKA_KIND" ]]; then
  rollout_wait "$KAFKA_NS" "$KAFKA_KIND" kafka 45s
else
  echo "⚠️  Kafka resource not found (neither Deployment nor StatefulSet named 'kafka')"
fi

ZK_KIND="$(detect_kind "$KAFKA_NS" zookeeper)"
if [[ -n "$ZK_KIND" ]]; then
  rollout_wait "$KAFKA_NS" "$ZK_KIND" zookeeper 45s
else
  echo "⚠️  Zookeeper resource not found (neither Deployment nor StatefulSet named 'zookeeper')"
fi

# ---------- INFO ÚTIL ----------
echo -e "\nℹ️  Bootstrap interno de Kafka (si existe el Service):"
if kubectl get svc kafka-serv-internal -n "$KAFKA_NS" >/dev/null 2>&1; then
  HOST="kafka-serv-internal.${KAFKA_NS}.svc.cluster.local"
  PORT="$(kubectl get svc kafka-serv-internal -n "$KAFKA_NS" -o jsonpath='{.spec.ports[0].port}')"
  echo "   ${HOST}:${PORT}"
else
  echo "   Service kafka-serv-internal no encontrado"
fi

echo -e "\n✅ Health check completed."
