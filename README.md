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

This section helps you install Kafka in plaintext mode, along with a lightweight UI to browse topics and messages.

Persistent volumes are enabled so your topics and messages stick around across Minikube restarts.

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
  ├── kafka-ui-values.yaml
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
🔍 prometheus-server...
deployment "prometheus-server" successfully rolled out
✅ prometheus-server is healthy
🔍 grafana...
deployment "grafana" successfully rolled out
✅ grafana is healthy
🔍 kafka-ui...
deployment "kafka-ui" successfully rolled out
✅ kafka-ui is healthy
🔍 kafka-controller...
statefulset rolling update complete 3 pods at revision kafka-controller-98bc6557b...
✅ kafka-controller is healthy
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
kafka-controller-0                                  1/1     Running   0               175m
kafka-controller-1                                  1/1     Running   0               175m
kafka-controller-2                                  1/1     Running   0               175m
kafka-ui-5448964747-ds2bd                           1/1     Running   0               171m
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
kafka                                 ClusterIP   10.106.201.77    <none>         9092/TCP,9095/TCP            175m
kafka-controller-0-external           NodePort    10.105.143.201   192.168.49.2   9094:30092/TCP               175m
kafka-controller-1-external           NodePort    10.101.82.105    192.168.49.2   9094:30093/TCP               175m
kafka-controller-2-external           NodePort    10.97.107.152    192.168.49.2   9094:30094/TCP               175m
kafka-controller-headless             ClusterIP   None             <none>         9094/TCP,9092/TCP,9093/TCP   175m
kafka-ui                              NodePort    10.100.56.227    <none>         8080:30096/TCP               171m
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
❯ kubectl exec -n monitoring kafka-controller-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic metrics --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092
kubectl exec -n monitoring kafka-controller-0 -- /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic events --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092

# example response:

```bash
Defaulted container "kafka" out of: kafka, prepare-config (init)
Created topic metrics.
Defaulted container "kafka" out of: kafka, prepare-config (init)
Created topic events.
```

- Verify in the kafka-ui / Topics
