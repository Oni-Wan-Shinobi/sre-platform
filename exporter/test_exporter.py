import pytest
from unittest.mock import patch, MagicMock
from exporter import app, fetch_metrics, n8n_up, n8n_workflows_total, n8n_workflows_active


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_healthz(client):
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_metrics_endpoint(client):
    with patch("exporter.fetch_metrics"):
        r = client.get("/metrics")
        assert r.status_code == 200
        assert b"n8n_up" in r.data


def test_fetch_metrics_n8n_up():
    mock_response = MagicMock()
    mock_response.status_code = 200

    with patch("requests.get", return_value=mock_response):
        fetch_metrics()
        assert n8n_up._value.get() == 1


def test_fetch_metrics_n8n_down():
    with patch("requests.get", side_effect=Exception("connection refused")):
        fetch_metrics()
        assert n8n_up._value.get() == 0


def test_fetch_metrics_workflows():
    def mock_get(url, **kwargs):
        m = MagicMock()
        if "healthz" in url:
            m.status_code = 200
        elif "workflows" in url:
            m.status_code = 200
            m.json.return_value = {
                "data": [
                    {"id": "1", "active": True},
                    {"id": "2", "active": False},
                ]
            }
        elif "executions" in url:
            m.status_code = 200
            m.json.return_value = {"count": 5}
        return m

    with patch("requests.get", side_effect=mock_get):
        fetch_metrics()
        assert n8n_workflows_total._value.get() == 2
        assert n8n_workflows_active._value.get() == 1
