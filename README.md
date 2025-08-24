# 📡 Local Monitoring Stack for Kubernetes (Prometheus + Grafana + Kafka)

Welcome! 👋
This project sets up a local monitoring stack based on Prometheus, Grafana, and Kafka (with Kafka UI), using Helm charts and persistent volumes for durability.

Whether you're experimenting with Kubernetes, developing custom controllers, or just want to see your cluster's activity in real time — this guide has got you covered.
By the end, you'll have a working environment where:

Prometheus collects metrics from your apps and infrastructure 🧲

Grafana helps you visualize those metrics with beautiful dashboards 📊

Kafka acts as a telemetry backbone, and Kafka-UI lets you explore the events flowing through it 🔄

This setup runs entirely on your local machine, making it ideal for testing and development — no cloud account or external services required!

---

## 🚀 What You’ll Get

Once deployed, your local monitoring stack will include:

✅ A Prometheus instance, scraping metrics on port 30090

✅ A Grafana dashboard, accessible at localhost:30095

✅ A Kafka broker with persistent volumes

✅ Kafka UI at localhost:30096 to inspect topics and messages

✅ A health check script to ensure everything is up and running

---

## 📦 Prometheus + Grafana

We’ll use the official Helm charts from Bitnami and Prometheus Community, with a few tweaks for local development and persistence. See values files for config details.

## 🧱 Kafka + Kafka UI

This section helps you install Kafka with Zookeeper in plaintext mode, along with a lightweight UI to browse topics and messages.

- Runs in namespace: kafka
- Persistent Volumes enabled
- Kafka-UI is deployed as ClusterIP (access via port-forward)

Persistent volumes are enabled so your topics and messages stick around across Minikube restarts.

Because of Kafka is a complicated Tool to install/config, I chose to install it with kubectl manifest.

### Usage

1. Deploy Kafka and Kafka UI: (If you want to install alone)

```bash
./install.sh kafka
```

## 🌐 External Kafka Access (Local Testing)

In order to send messages to Kafka from outside Minikube (e.g., from your local machine) without having to run the client inside the cluster, I added an **external listener** configuration and a dedicated `Service` for external access.

### Kafka Broker Configuration

The following listeners were configured:

```yaml
- name: KAFKA_CFG_LISTENERS
  value: "PLAINTEXT://:9092,CONTROLLER://:9093,EXTERNAL://:9094"
- name: KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP
  value: "CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT,PLAINTEXT:PLAINTEXT"
- name: KAFKA_CFG_ADVERTISED_LISTENERS
  value: "PLAINTEXT://kafka-serv-internal.kafka.svc.cluster.local:9092,EXTERNAL://127.0.0.1:9094"

```

- Internal traffic inside the cluster uses kafka-serv-internal:9092.
- External traffic from the host machine uses 127.0.0.1:9094.

### External Service

An external service was added to expose the broker outside Minikube:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-serv-external
  namespace: kafka
spec:
  type: LoadBalancer
  # For Linux users, you can switch to NodePort if preferred:
  # type: NodePort
  ports:
    - port: 9094
      targetPort: 9094
      # nodePort: 30096
  selector:
    app: kafka

```

- On macOS, using LoadBalancer is the simplest way to connect to Kafka externally.
- On Linux, you may uncomment the NodePort section for direct node access instead.

### Option 1.- MacOS Instructions

Start the tunnel to expose LoadBalancer services:

```bash

minikube tunnel
```

- Verify the external IP assigned to the service:

```bash

kubectl get svc -n kafka

# Example output:

NAME                  TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kafka-serv-external   LoadBalancer   10.106.37.143    127.0.0.1     9094:30096/TCP   21h
kafka-serv-internal   ClusterIP      10.102.170.18    <none>        9092/TCP         21h
kafka-ui              ClusterIP      10.105.208.183   <none>        8080/TCP         21h
zookeeper             ClusterIP      10.106.213.78    <none>        2181/TCP         21h

```

- Use the external broker address in your environment:

```bash

KAFKA_BROKER=127.0.0.1:9094
```

### Option 2 – Linux (NodePort)

On Linux, you can expose Kafka via a NodePort without using minikube tunnel.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka-serv-external
  namespace: kafka
spec:
  type: NodePort
  ports:
    - port: 9094
      targetPort: 9094
      nodePort: 30096
  selector:
    app: kafka
```

Steps:

Verify the Minikube node IP:

```bash
minikube ip

Example output:

192.168.49.2
```

Connect to Kafka using:

```bash
KAFKA_BROKER=192.168.49.2:30096
```

### To Test local - messages to kafka

- Script Python to test local messages to kafka: kafka-test-local.py

```bash
❯ python3 kafka-test-local.py --broker 127.0.0.1:9094 --topic test
✅ Message delivered to test [0]
```

### ⚠️ Pending work

- Add support for TLS + authentication (SASL) for production-like environments.

---

## 🧱 Folder Structure

```bash
monitoring/
├── deploy-all.sh # Script to install all components
├── kafka-zookeeper/ # kafka manifests
│ ├── kafka.yaml
│ └── kafka-secretstore-externalsecret.yaml
└── monitoring-values/ # Helm values for each component
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

---

## 🎯 Verify Your Setup

Let’s make sure everything is working! You’ll check that Prometheus, Grafana, Kafka, and Kafka UI are all running and accessible via NodePorts.

## 🔍 Accessing Tools from Host (Minikube + Docker on macOS)

- By default, services exposed via NodePort in Minikube may not be directly accessible from your host when using the Docker driver on macOS. This is due to networking limitations: the NodePort is exposed inside the Minikube VM/container, not on your host machine's network.

### Get the name of the tools pods

```bash
❯ kubectl get svc -n monitoring
NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
grafana                               NodePort    10.102.51.68     <none>         80:30095/TCP                 29m
prometheus-alertmanager               ClusterIP   10.103.180.130   <none>         9093/TCP                     46m
prometheus-alertmanager-headless      ClusterIP   None             <none>         9093/TCP                     46m
prometheus-kube-state-metrics         ClusterIP   10.102.171.116   <none>         8080/TCP                     46m
prometheus-prometheus-node-exporter   ClusterIP   10.97.14.115     <none>         9100/TCP                     46m
prometheus-prometheus-pushgateway     ClusterIP   10.101.189.12    <none>         9091/TCP                     46m
prometheus-server                     NodePort    10.104.67.195    <none>         80:30090/TCP                 46m
```

```bash
❯ kubectl get svc -n kafka
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kafka-serv-external   NodePort    10.106.37.143    <none>        9094:30096/TCP   16h
kafka-serv-internal   ClusterIP   10.102.170.18    <none>        9092/TCP         16h
kafka-ui              ClusterIP   10.105.208.183   <none>        8080/TCP         16h
zookeeper             ClusterIP   10.106.213.78    <none>        2181/TCP         16h

❯ kubectl get pods -n kafka
NAME                        READY   STATUS    RESTARTS      AGE
kafka-5ccc5c57cd-nnngm      1/1     Running   4 (88m ago)   16h
kafka-ui-78cff74b58-hs66l   1/1     Running   4 (88m ago)   16h
zookeeper-fcb9f5df7-t29lz   1/1     Running   4 (88m ago)   16h

```

### Example

```bash
kubectl get svc -n monitoring grafana

NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
grafana   NodePort   10.102.51.68   <none>        80:30095/TCP   34m


kubectl get svc -n monitoring prometheus-server

NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
prometheus   NodePort   10.98.27.101   <none>        9090:31090/TCP   45m

```

```bash
# ⚠️ IP may change on restart (check again)
minikube ip
192.168.49.2
```

- ***You might expect `curl <http://192.168.49.2:30095>` to work, but it doesn't respond.***

### 🧪 Option 1: minikube service (Temporary)

```bash
# Grafana
minikube service grafana -n monitoring

# Prometheus
minikube service prometheus-server -n monitoring

# Kafka-ui
minikube service kafka-ui -n kafka

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

- ***NOTE: Yopu have to stop the temporary proxy with ctrl-c before stop minikube, and execute again on restart***

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

## 🔄 Stopping and Restarting Minikube Safely

***♻️ Minikube Lifecycle (Shutdown / Restart)***

To safely shut down and restart your monitoring stack without losing data or encountering errors:

### ✅ Stop Minikube

- Use minikube stop instead of deleting the cluster:
  - This safely shuts down the VM/container.
  - PVCs and all service configurations remain intact.

```bash
minikube stop
```

### ✅ Start Again Later

- This restores the full state, including your deployed services, PVCs, and Helm releases.
  - All NodePorts and persistent data remain available.

```bash
minikube start
```

***⚠️ Do Not Use***

- ❌ This deletes all volumes, pods, secrets, configs — use only if you want a clean reset.

```bash
minikube delete
```

### 🧪 Check Status

```bash
kubectl get pods -n monitoring
```

- If pods don't come up correctly (e.g., CrashLoopBackOff), you may need to:
  - Reapply deploy-all.sh
  - Re-check Minikube disk availability with:

    ```bash
    minikube ssh
    df -h
    ```

### 🔒 Persistent Volumes & Restarting Notes

| Component  | Persistent? | How It's Stored           | Notes                                                             |
| ---------- | ----------- | ------------------------- | ----------------------------------------------------------------- |
| Prometheus | ✅           | PVC → HostPath on VM      | Config & scraped metrics preserved across reboots                 |
| Grafana    | ✅           | PVC (grafana-pvc)         | Dashboards, settings are saved                                    |
| Kafka      | ✅           | PVC per broker/controller | Topic data survives restart. Must wait for all brokers to rejoin. |
| Kafka-UI   | ❌           | Ephemeral                 | Will restart fresh; doesn't affect Kafka state                    |

### 🔁 Optional: Restart deploy-all.sh (if needed)

- You can safely re-run the script to reapply Helm charts and PVCs:
  - 💡 Helm is idempotent — it will upgrade existing releases without data loss if PVCs exist.

```bash
./deploy-all.sh
```

### 📁 Tip: Back Up Persistent Data (Optional)

- To snapshot your PVCs before restarting or for backup purposes:

```bash
kubectl get pvc -n monitoring
```

- For example:

```bash
kubectl cp monitoring/prometheus-server-0:/opt/bitnami/prometheus/data ./backup-prometheus-data
```

## 🧠 Final Tip: Automate Health Checks (Optional)

To quickly check if your monitoring stack is up and running, you can either:

### ***✅ Option A: Use the health check script (recommended)***

- Run the provided script to verify key components like Prometheus, Grafana, Kafka and Kafka-UI:

```bash
./check-health.sh
```

- Response

```bash
❯ ./check-health.sh

⏳ Checking health of monitoring components in namespace: monitoring
🔍 grafana (deployment)...
deployment "grafana" successfully rolled out
✅ grafana is healthy
🔍 prometheus-server (deployment)...
deployment "prometheus-server" successfully rolled out
✅ prometheus-server is healthy

⏳ Checking health of Kafka components in namespace: kafka
🔍 kafka-ui (deployment)...
deployment "kafka-ui" successfully rolled out
✅ kafka-ui is healthy
🔍 kafka (deployment)...
deployment "kafka" successfully rolled out
✅ kafka is healthy
🔍 zookeeper (deployment)...
deployment "zookeeper" successfully rolled out
✅ zookeeper is healthy

ℹ️  Bootstrap interno de Kafka (si existe el Service):
   kafka-serv-internal.kafka.svc.cluster.local:9092

✅ Health check completed.
```

- If components are not found or in a bad state, the script will print warnings accordingly.
- You can edit the script to match the names of your deployments or statefulsets, depending on your YAMLs.

### ***🔍 Option B: Check manually with kubectl***

If you prefer manual inspection or want to verify specific resources:

- List all pods in the monitoring namespace:

```bash
kubectl get pods -n monitoring
```

- You should see something like:

```bash
NAME                                                READY   STATUS    RESTARTS        AGE
grafana-57554dd88-rc8z4                             1/1     Running   0               3h11m
prometheus-alertmanager-0                           1/1     Running   1 (4h59m ago)   24h
prometheus-kube-state-metrics-7f796b7d44-89mjd      1/1     Running   1 (4h59m ago)   24h
prometheus-prometheus-node-exporter-cltc4           1/1     Running   1 (4h59m ago)   24h
prometheus-prometheus-pushgateway-d4f8cb767-nwtn9   1/1     Running   1 (4h59m ago)   24h
prometheus-server-79798b4ff6-7g55g                  2/2     Running   2 (4h59m ago)   24h
...
```

- Check services and their ports:

```bash
kubectl get svc -n monitoring
```

- Look for NodePort services exposing the UIs:

```bash
NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP    PORT(S)                      AGE
grafana                               NodePort    10.104.174.27    <none>         80:30095/TCP                 3h11m
prometheus-alertmanager               ClusterIP   10.103.180.130   <none>         9093/TCP                     24h
prometheus-alertmanager-headless      ClusterIP   None             <none>         9093/TCP                     24h
prometheus-kube-state-metrics         ClusterIP   10.102.171.116   <none>         8080/TCP                     24h
prometheus-prometheus-node-exporter   ClusterIP   10.97.14.115     <none>         9100/TCP                     24h
prometheus-prometheus-pushgateway     ClusterIP   10.101.189.12    <none>         9091/TCP                     24h
prometheus-server                     NodePort    10.104.67.195    <none>         80:30090/TCP                 24h
```

- Then, access the dashboards using `http://<minikube-ip>:<nodeport>`. For example:
  - Grafana: <http://localhost:30095>
  - Prometheus: <http://localhost:30090>
  - Kafka UI: <http://localhost:30096>

- **Use minikube ip to get your cluster IP if needed.**

## Create the Topics (events, metrics)

- Execute these commands to create the topics: metrics, events (You can do it also by kafka-ui)

```bash
kubectl -n kafka exec -it deploy/kafka-client -- \
  kafka-topics.sh --create --topic metrics --bootstrap-server kafka-serv:9092

kubectl -n kafka exec -it deploy/kafka-client -- \
  kafka-topics.sh --create --topic events --bootstrap-server kafka-serv:9092

# example response:

```bash
Defaulted container "kafka" out of: kafka, prepare-config (init)
Created topic metrics.
Defaulted container "kafka" out of: kafka, prepare-config (init)
Created topic events.
```

- Verify in the kafka-ui / Topics
