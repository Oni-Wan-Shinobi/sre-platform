# Runbooks

Operational playbooks for the SRE Platform. Each runbook is linked from a Prometheus alert.

---

## RB-01 — n8n is down

**Alert:** `N8nSLOBreach`
**Severity:** Critical
**SLO impact:** Yes — error rate above 0.5%

### Symptoms
- https://n8n.YOUR_DOMAIN returns 502/503
- Telegram alert: N8nSLOBreach firing

### Investigation

```bash
kubectl get pods -n default | grep n8n
kubectl describe pod -n default -l app.kubernetes.io/name=n8n
kubectl logs -n default -l app.kubernetes.io/name=n8n --tail=50
```

### Resolution

```bash
kubectl rollout restart deployment/n8n -n default
kubectl get pvc -n default
kubectl get events -n default --sort-by='.lastTimestamp' | tail -20
```

### Escalation
If not resolved in 15 min — check node health (RB-05).

---

## RB-02 — PostgreSQL is down

**Alert:** `PostgresPodDown`
**Severity:** Critical
**SLO impact:** Yes — n8n depends on postgres

### Symptoms
- n8n shows database connection errors
- postgres-0 pod not in Running state

### Investigation

```bash
kubectl get pods -n default | grep postgres
kubectl describe pod postgres-0 -n default
kubectl logs postgres-0 -n default --tail=50
```

### Resolution

```bash
kubectl delete pod postgres-0 -n default
kubectl get pvc -n default
kubectl exec -it postgres-0 -n default -- psql -U postgres -c '\l'
```

### Escalation
If PVC is lost — restore from backup.

---

## RB-03 — Node is down

**Alert:** `NodeDown`
**Severity:** Critical
**SLO impact:** Yes — pods will be evicted or Pending

### Symptoms
- Node shows NotReady in kubectl
- Multiple pods evicted or stuck Pending

### Investigation

```bash
kubectl get nodes
kubectl describe node <node-name>
ssh root@<node-ip>
systemctl status k3s
journalctl -u k3s -n 50
df -h && free -m
```

### Resolution

```bash
# On master node
systemctl restart k3s

# On worker node
systemctl restart k3s-agent
```

---

## RB-04 — High CPU usage

**Alert:** `HighCPUUsage`
**Severity:** Warning
**SLO impact:** Possible degradation

### Investigation

```bash
kubectl top nodes
kubectl top pods -A --sort-by=cpu
```

### Resolution

```bash
# Identify and restart the heavy pod
kubectl rollout restart deployment/<name> -n <namespace>

# Or scale down temporarily
kubectl scale deployment/<name> --replicas=0 -n <namespace>
```

---

## RB-05 — High memory usage

**Alert:** `HighMemoryUsage`
**Severity:** Warning
**SLO impact:** Possible OOMKill of pods

### Investigation

```bash
kubectl top nodes
kubectl top pods -A --sort-by=memory
```

### Resolution

```bash
kubectl rollout restart deployment/<name> -n <namespace>
```

---

## RB-06 — Disk space low

**Alert:** `DiskSpaceLow`
**Severity:** Warning
**SLO impact:** Possible pod failures if disk fills up

### Investigation

```bash
ssh root@<node-ip>
df -h
du -sh /var/lib/rancher/k3s/*
du -sh /var/log/*
```

### Resolution

```bash
# Clean up unused Docker images
docker system prune -f

# Clean up old k3s logs
journalctl --vacuum-time=3d

# Check and resize PVCs if needed
kubectl get pvc -A
```

---

## RB-07 — TLS certificate expiring

**Severity:** Warning
**SLO impact:** HTTPS will break after expiry

### Investigation

```bash
kubectl get certificates -A
kubectl describe certificate <name> -n <namespace>
```

### Resolution

```bash
# Force cert-manager to renew
kubectl delete secret <tls-secret-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

---

## RB-08 — fail2ban banned wrong IP

**Severity:** Critical
**SLO impact:** Operator locked out of server

### Resolution

```bash
ssh root@<server-ip>
fail2ban-client set sshd unbanip <your-ip>
grep ignoreip /etc/fail2ban/jail.local
```

---

## RB-09 — Loki is down

**Severity:** Warning
**SLO impact:** No — logs collection stops but metrics continue

### Investigation

```bash
kubectl get pods -n monitoring | grep loki
kubectl logs loki-0 -n monitoring --tail=50
```

### Resolution

```bash
kubectl rollout restart statefulset/loki -n monitoring
```

---

## RB-10 — Grafana is down

**Severity:** Warning
**SLO impact:** Partial — metrics collected, dashboards unavailable

### Investigation

```bash
kubectl get pods -n monitoring | grep grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50
```

### Resolution

```bash
kubectl rollout restart deployment/monitoring-grafana -n monitoring
```
