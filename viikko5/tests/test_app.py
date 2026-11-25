from unittest.mock import patch
from viikko5.app import app


def test_health_returns_commit_sha(monkeypatch):
    monkeypatch.setenv("GIT_COMMIT_SHA", "abc123def456")
    client = app.test_client()
    resp = client.get("/viikko5/health")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok", "commit": "abc123def456"}


def test_index_loads_empty_history():
    with patch("viikko5.app.fetch_history", return_value=[]):
        client = app.test_client()
        resp = client.get("/viikko5/")
        assert resp.status_code == 200
        assert b"Viikko 5: Paikallinen LLM-chat" in resp.data


def test_chat_endpoint_saves_and_replies():
    saved = []

    def fake_save(session_id, role, content):
        saved.append((session_id, role, content))

    def fake_history(session_id):
        return [{"role": "user", "content": "Moi"}]

    with patch("viikko5.app.save_message", side_effect=fake_save), \
         patch("viikko5.app.fetch_history", side_effect=fake_history), \
         patch(
             "viikko5.app.ask_ollama",
             return_value="Hei! Miten voin auttaa?",
         ):
        client = app.test_client()
        resp = client.post("/viikko5/api/chat", json={"message": "Moi"})
        assert resp.status_code == 200
        assert resp.get_json() == {"reply": "Hei! Miten voin auttaa?"}
        assert len(saved) == 2
        assert saved[0][1] == "user"
        assert saved[1][1] == "assistant"


def test_chat_rejects_empty_message():
    client = app.test_client()
    resp = client.post("/viikko5/api/chat", json={"message": "   "})
    assert resp.status_code == 400
