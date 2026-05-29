import os
import requests
from flask import Flask, Response
from prometheus_client import generate_latest, Gauge, CONTENT_TYPE_LATEST

app = Flask(__name__)

N8N_URL = os.environ.get("N8N_URL", "http://n8n:5678")
N8N_API_KEY = os.environ.get("N8N_API_KEY", "")

# Metrics
n8n_up = Gauge("n8n_up", "n8n is reachable")
n8n_workflows_total = Gauge("n8n_workflows_total", "Total number of workflows")
n8n_workflows_active = Gauge("n8n_workflows_active", "Number of active workflows")
n8n_executions_total = Gauge("n8n_executions_total", "Total executions", ["status"])


def fetch_metrics():
    headers = {"X-N8N-API-KEY": N8N_API_KEY}
    try:
        # Check n8n health
        r = requests.get(f"{N8N_URL}/healthz", timeout=5)
        n8n_up.set(1 if r.status_code == 200 else 0)
    except Exception:
        n8n_up.set(0)
        return

    try:
        # Workflows
        r = requests.get(f"{N8N_URL}/api/v1/workflows", headers=headers, timeout=5)
        if r.status_code == 200:
            data = r.json().get("data", [])
            n8n_workflows_total.set(len(data))
            n8n_workflows_active.set(sum(1 for w in data if w.get("active")))
    except Exception:
        pass

    try:
        # Executions
        for status in ["success", "error", "waiting"]:
            r = requests.get(
                f"{N8N_URL}/api/v1/executions",
                headers=headers,
                params={"status": status, "limit": 1},
                timeout=5
            )
            if r.status_code == 200:
                count = r.json().get("count", 0)
                n8n_executions_total.labels(status=status).set(count)
    except Exception:
        pass


@app.route("/metrics")
def metrics():
    fetch_metrics()
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.route("/healthz")
def health():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9101)
