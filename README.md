# 📡 Local Monitoring Stack for Kubernetes (Prometheus + Grafana + Kafka)

This guide describes how to install a local monitoring environment using **Prometheus**, **Grafana**, and **Kafka**, with persistent volumes and Helm charts.

This setup is useful for developing and testing kuebernetes operators that expose metrics or produce telemetry events.

---

## 🧱 Folder Structure

```bash
monitoring/
├── deploy-all.sh # Script to install all components
├── pv/ # Persistent volume manifests
│ ├── kafka-pv.yaml
│ ├── prometheus-pv.yaml
│ └── grafana-pv.yaml
└── values/ # Helm values for each component
  ├── kafka-values.yaml
  ├── prometheus-values.yaml
  └── grafana-values.yaml
```

---

## 🛠️ Prerequisites

Make sure you have the following installed:

- [Minikube](https://minikube.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

> This setup assumes you're running Kubernetes locally with Minikube.

---

## 🚀 Installation

### 1.– Start Minikube

```bash
minikube start --memory=4g --cpus=2
```

### 2.- Add Helm repositories

- This step is added in the script: Just uncomment de section

### 3.- Run the install script

```bash
cd monitoring
chmod +x deploy-all.sh
./deploy-all.sh
```

- This script will:
  - Create a monitoring namespace.
  - Apply persistent volumes from pv/.
## 📋 Access to Monitoring Tools

| Tool         | External Access (NodePort)                                                                                                                                                                                                                                   | Internal Access (Cluster DNS)                                                                                                                            | Important Notes                                                                                                                                                                                                                                                 |
|--------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Grafana**  | [http://192.168.49.2:30095](http://192.168.49.2:30095)                                                                                                                                                                                                      | `grafana.monitoring.svc.cluster.local`                                                                                                                   | - User: `admin` <br> - Get password:<br> `kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" \| base64 --decode`                                                                                                                      |
| **Kafka**    | See ports with:<br>`kubectl get svc -n monitoring -l "app.kubernetes.io/instance=kafka,app.kubernetes.io/component=kafka,pod" -o jsonpath='{.items[*].spec.ports[0].nodePort}'`                                                                              | - Client: `kafka.monitoring.svc.cluster.local:9092`<br>- Brokers: `kafka-controller-0/1/2.kafka-controller-headless.monitoring.svc.cluster.local:9092`   | - KRaft enabled<br>- EXTERNAL listener enabled<br>- Run a client with:<br>`kubectl run kafka-client --rm -it --image docker.io/bitnami/kafka:4.0.0-debian-12-r8 -n monitoring -- bash`                                                                           |
| **Prometheus**| Run:<br>`export NODE_PORT=$(kubectl get svc -n monitoring prometheus-server -o jsonpath="{.spec.ports[0].nodePort}")`<br>`export NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}")`<br>`echo http://$NODE_IP:$NODE_PORT` | `prometheus-server.monitoring.svc.cluster.local`                                                                                                         | - Server and AlertManager available<br>- AlertManager: port-forward:<br>`kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093`<br>- PushGateway: port-forward:<br>`kubectl port-forward -n monitoring svc/prometheus-prometheus-pushgateway 9091` |

✅ Additional Notes

- Minikube IP: 192.168.49.2 (verify with minikube ip if needed)
- Namespace: monitoring
- PVCs applied: grafana-pvc, kafka-pv, prometheus-pvc

## 🔍 Accessing Tools from Host (Minikube + Docker on macOS)

- By default, services exposed via NodePort in Minikube may not be directly accessible from your host when using the Docker driver on macOS. This is due to networking limitations: the NodePort is exposed inside the Minikube VM/container, not on your host machine's network.

### Get the name of the tools pods

```bash
❯ kubectl get svc -n monitoring
NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
grafana                               NodePort    10.102.51.68     <none>         80:30095/TCP                 29m
kafka                                 ClusterIP   10.100.118.216   <none>         9092/TCP,9095/TCP            46m
kafka-controller-0-external           NodePort    10.109.227.109   192.168.49.2   9094:30092/TCP               46m
kafka-controller-1-external           NodePort    10.97.149.130    192.168.49.2   9094:30093/TCP               46m
kafka-controller-2-external           NodePort    10.99.194.34     192.168.49.2   9094:30094/TCP               46m
kafka-controller-headless             ClusterIP   None             <none>         9094/TCP,9092/TCP,9093/TCP   46m
kafka-jmx-metrics                     ClusterIP   10.99.29.148     <none>         5556/TCP                     46m
prometheus-alertmanager               ClusterIP   10.103.180.130   <none>         9093/TCP                     46m
prometheus-alertmanager-headless      ClusterIP   None             <none>         9093/TCP                     46m
prometheus-kube-state-metrics         ClusterIP   10.102.171.116   <none>         8080/TCP                     46m
prometheus-prometheus-node-exporter   ClusterIP   10.97.14.115     <none>         9100/TCP                     46m
prometheus-prometheus-pushgateway     ClusterIP   10.101.189.12    <none>         9091/TCP                     46m
prometheus-server                     NodePort    10.104.67.195    <none>         80:30090/TCP                 46m
```

### Example

```bash
kubectl get svc -n monitoring grafana

NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
grafana   NodePort   10.102.51.68   <none>        80:30095/TCP   34m


kubectl get svc -n monitoring prometheus-server

NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
prometheus   NodePort   10.98.27.101   <none>        9090:31090/TCP   45m


kubectl get svc -n monitoring kafka-ui

NAME       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
kafka-ui   NodePort   10.96.220.89   <none>        8080:30096/TCP   19m

```

```bash
minikube ip
192.168.49.2
```

- ***You might expect curl http://192.168.49.2:30095 to work, but it doesn't respond.***

### 🧪 Option 1: minikube service (Temporary)

```bash
# Grafana
minikube service grafana -n monitoring

# Prometheus
minikube service prometheus-server -n monitoring

# Kafka-ui
minikube service kafka-ui -n monitoring

```

- This opens a temporary proxy and shows a localhost URL like:

```psql
# Grafana
|------------|---------|-------------|---------------------------|
| NAMESPACE  |  NAME   | TARGET PORT |            URL            |
|------------|---------|-------------|---------------------------|
| monitoring | grafana | service/80  | http://192.168.49.2:30095 |
|------------|---------|-------------|---------------------------|
🏃  Starting tunnel for service grafana.
|------------|---------|-------------|------------------------|
| NAMESPACE  |  NAME   | TARGET PORT |          URL           |
|------------|---------|-------------|------------------------|
| monitoring | grafana |             | http://127.0.0.1:56851 |
|------------|---------|-------------|------------------------|
🎉  Opening service monitoring/grafana in default browser...
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.


# Prometheus
|------------|-------------------|-------------|---------------------------|
| NAMESPACE  |       NAME        | TARGET PORT |            URL            |
|------------|-------------------|-------------|---------------------------|
| monitoring | prometheus-server | http/80     | http://192.168.49.2:30090 |
|------------|-------------------|-------------|---------------------------|
🏃  Starting tunnel for service prometheus-server.
|------------|-------------------|-------------|------------------------|
| NAMESPACE  |       NAME        | TARGET PORT |          URL           |
|------------|-------------------|-------------|------------------------|
| monitoring | prometheus-server |             | http://127.0.0.1:56409 |
|------------|-------------------|-------------|------------------------|
🎉  Opening service monitoring/prometheus-server in default browser...
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it.


# kafka
|------------|----------|-------------|---------------------------|
| NAMESPACE  |   NAME   | TARGET PORT |            URL            |
|------------|----------|-------------|---------------------------|
| monitoring | kafka-ui | http/8080   | http://192.168.49.2:30096 |
|------------|----------|-------------|---------------------------|
🏃  Starting tunnel for service kafka-ui.
|------------|----------|-------------|------------------------|
| NAMESPACE  |   NAME   | TARGET PORT |          URL           |
|------------|----------|-------------|------------------------|
| monitoring | kafka-ui |             | http://127.0.0.1:64903 |
|------------|----------|-------------|------------------------|

```

- ✅ Works immediately, opens browser
  - ❗ Needs terminal to stay open (as it runs a local tunnel)
  - ❗ Not script-friendly or persistent

### persistent

🛠 Option 2: kubectl port-forward (Persistent while running)

- You can forward the Grafana service to a local port
  - With Lens, Openlens, K9s, etc
  - Or via kubectl cmd in terminal

```bash
kubectl port-forward -n monitoring svc/grafana 30095:80

kubectl port-forward -n monitoring svc/prometheus 9090:9090

kubectl port-forward svc/kafka-ui 8080:8080 -n monitoring


```

- Then visit (In this example):

```bash
# grafana
http://localhost:30095

# prometheus
http://localhost:9090

# kafka
http://localhost:9093

```

- **Login**
  - *Grafana:*
    - user: admin
    - password: admin***

- ✅ Works reliably
  - ❗ Still requires the terminal to stay open
  - ❗ Better suited for dev workflows, or when using tools like Lens/K9s which manage this automatically

### 🛡 Option 3: minikube tunnel (Recommended for real external access)

- Only if you define type: as LoadBalancer instead of NodePort

```bash
minikube tunnel
```

- Exposes NodePort and LoadBalancer services to your macOS host.
- Runs in background (but requires admin privileges).
- Makes the minikube ip + NodePort combination work:

```bash
curl http://192.168.49.2:30095
...
```

- **✅ Best if you want persistent access via actual cluster IP**
- **⚠️ You’ll need to keep the tunnel running in a terminal**

### Summary

| Method                 | Persistent | Scriptable | Requires open terminal | Notes                           |
| ---------------------- | ---------- | ---------- | ---------------------- | ------------------------------- |
| `minikube service`     | ❌          | ❌          | ✅                      | Great for quick UI testing      |
| `kubectl port-forward` | ❌          | ✅          | ✅                      | Ideal during dev/debug          |
| `minikube tunnel`      | ✅          | ✅          | ✅ (background)         | Best for stable external access |

### Tools Summary

| Service        | Method             | Persistent | Host Access | Notes                                 |
| -------------- | ------------------ | ---------- | ----------- | ------------------------------------- |
| **Grafana**    | `minikube service` | ❌          | ✅           | UI test only                          |
|                | `kubectl port-fwd` | ❌          | ✅           | Dev access                            |
|                | `minikube tunnel`  | ✅          | ✅           | Needed for NodePort from host         |
| **Prometheus** | Same as above      | Same       | Same        | Accessible at port 9090               |
| **Kafka**      | `port-fwd 9093`    | ❌          | ✅ (TLS)     | For testing with TLS listener         |
|                | `minikube tunnel`  | ✅          | ✅           | Needed for TLS access from host tools |
