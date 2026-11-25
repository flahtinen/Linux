import os
import uuid
from flask import Flask, jsonify, render_template, request, session
import pymysql
import requests

app = Flask(__name__, static_url_path="/viikko5/static")
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-secret-change-in-prod")


def get_db_connection():
    return pymysql.connect(
        host=os.environ.get("DB_HOST", "127.0.0.1"),
        port=int(os.environ.get("DB_PORT", "3306")),
        user=os.environ.get("DB_USER", "viikko5_user"),
        password=os.environ.get("DB_PASSWORD", ""),
        database=os.environ.get("DB_NAME", "viikko5_chat"),
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )


def get_session_id():
    if "chat_session_id" not in session:
        session["chat_session_id"] = str(uuid.uuid4())
    return session["chat_session_id"]


def fetch_history(session_id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT role, content, created_at FROM messages "
                "WHERE session_id = %s ORDER BY id ASC",
                (session_id,),
            )
            return cur.fetchall()
    finally:
        conn.close()


def save_message(session_id, role, content):
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO messages (session_id, role, content) VALUES (%s, %s, %s)",
                (session_id, role, content),
            )
    finally:
        conn.close()


def ask_ollama(messages):
    ollama_url = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434")
    model = os.environ.get("OLLAMA_MODEL", "llama3.2:1b")
    payload = {
        "model": model,
        "messages": [{"role": m["role"], "content": m["content"]} for m in messages],
        "stream": False,
    }
    resp = requests.post(f"{ollama_url}/api/chat", json=payload, timeout=120)
    resp.raise_for_status()
    data = resp.json()
    return data.get("message", {}).get("content", "").strip()


@app.route("/viikko5/")
def index():
    sid = get_session_id()
    try:
        history = fetch_history(sid)
    except Exception:
        history = []
    return render_template("index.html", history=history)


@app.route("/viikko5/api/chat", methods=["POST"])
def chat_api():
    data = request.get_json(silent=True) or {}
    user_msg = (data.get("message") or "").strip()
    if not user_msg:
        return jsonify({"error": "Viesti ei voi olla tyhja."}), 400

    sid = get_session_id()
    save_message(sid, "user", user_msg)
    history = fetch_history(sid)

    try:
        reply = ask_ollama(history)
    except Exception as exc:
        return jsonify({"error": f"Mallipalvelimen virhe: {exc}"}), 502

    save_message(sid, "assistant", reply)
    return jsonify({"reply": reply})


@app.route("/viikko5/health")
def health():
    commit_sha = os.environ.get("GIT_COMMIT_SHA", "unknown")
    return jsonify({"status": "ok", "commit": commit_sha})


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5005)
