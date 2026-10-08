import pytest
from app import app

@pytest.fixture
def client_app():
    with app.test_client() as client:
        with app.app_context():
            yield client

def test_health(client_app):
    res = client_app.get("/health")
    assert res.status_code == 200
    assert res.is_json
    assert res.get_json() == {"status": "ok"}

def test_hello(client_app):
    res = client_app.get("/hello")
    assert res.status_code == 200
    assert res.is_json
    assert res.get_json() == {"message": "Hello world"}

@pytest.mark.integration
def test_dbtest(client_app):
    res = client_app.get("/dbtest")
    assert res.status_code == 200
    assert res.is_json
    assert res.get_json() == {"db_connection": "successful"}

def test_dbtest_connection_failure(client_app, monkeypatch):
    import psycopg2

    def fail_connection(*args, **kwargs):
        raise psycopg2.OperationalError(
            "connection failed: internal host and credentials"
        )

    monkeypatch.setattr("app.psycopg2.connect", fail_connection)

    res = client_app.get("/dbtest")

    assert res.status_code == 500
    assert res.is_json
    assert res.get_json() == {"db_connection": "failed"}


@pytest.mark.parametrize(
    "result, expected_status, expected_body",
    [
        ((1,), 200, {"db_connection": "successful"}),
        (None, 500, {"db_connection": "failed"}),
    ],
)
def test_dbtest_query_result(
    client_app, monkeypatch, result, expected_status, expected_body
):
    from unittest.mock import MagicMock

    cursor = MagicMock(spec=["execute", "fetchone", "close"])
    cursor.fetchone.return_value = result
    connection = MagicMock(spec=["cursor", "close"])
    connection.cursor.return_value = cursor
    monkeypatch.setattr("app.psycopg2.connect", lambda **kwargs: connection)

    res = client_app.get("/dbtest")

    assert res.status_code == expected_status
    assert res.is_json
    assert res.get_json() == expected_body
    cursor.execute.assert_called_once_with("SELECT 1")
    cursor.close.assert_called_once_with()
    connection.close.assert_called_once_with()
