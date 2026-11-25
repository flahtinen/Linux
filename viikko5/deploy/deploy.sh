#!/usr/bin/env bash
set -euo pipefail

COMMIT_SHA="${1:?Commit SHA is required}"
REPO_DIR="/opt/viikko5/repo"
APP_DIR="/opt/viikko5/app"
VENV_DIR="/opt/viikko5/venv"

mkdir -p "$REPO_DIR" "$APP_DIR/viikko5"
rsync -a --no-g --no-o --no-t --delete --exclude '.git' ./ "$REPO_DIR/"
rsync -a --no-g --no-o --no-t --delete "$REPO_DIR/viikko5/" "$APP_DIR/viikko5/"

if [ ! -x "$VENV_DIR/bin/python" ]; then
    python3 -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r "$APP_DIR/viikko5/requirements.txt"

sudo cp "$REPO_DIR/viikko5/deploy/viikko5.service" /etc/systemd/system/viikko5.service
sudo systemctl daemon-reload

sudo mkdir -p /etc/nginx/snippets
sudo cp "$REPO_DIR/viikko5/deploy/viikko5-nginx.conf" /etc/nginx/snippets/viikko5.conf

DEFAULT_SITE="/etc/nginx/sites-available/default"
if ! grep -q "include /etc/nginx/snippets/viikko5.conf;" "$DEFAULT_SITE"; then
    sudo python3 - "$DEFAULT_SITE" <<'PY'
import sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    content = f.read()
target = "location / {"
snippet = "    include /etc/nginx/snippets/viikko5.conf;\n\n"
if target in content:
    content = content.replace(target, snippet + target, 1)
else:
    idx = content.rfind("}")
    if idx != -1:
        content = content[:idx] + "\n" + snippet + content[idx:]
with open(path, "w", encoding="utf-8") as f:
    f.write(content)
PY
fi

sudo nginx -t
sudo systemctl reload nginx

if sudo grep -q "^GIT_COMMIT_SHA=" /etc/viikko5/env; then
    sudo sed -i "s/^GIT_COMMIT_SHA=.*/GIT_COMMIT_SHA=${COMMIT_SHA}/" /etc/viikko5/env
else
    echo "GIT_COMMIT_SHA=${COMMIT_SHA}" | sudo tee -a /etc/viikko5/env >/dev/null
fi
sudo chown root:viikko5 /etc/viikko5/env
sudo chmod 640 /etc/viikko5/env

sudo chown -R viikko5:viikko5 "$APP_DIR" "$VENV_DIR" /run/viikko5

sudo systemctl restart viikko5.service
sudo systemctl is-active --quiet viikko5.service

for i in $(seq 1 15); do
  if [ -S /run/viikko5/gunicorn.sock ] && curl -fsS "http://127.0.0.1/viikko5/health" | grep -q "$COMMIT_SHA"; then
    break
  fi
  if [ "$i" -eq 15 ]; then
    echo "Health check failed after restart" >&2
    exit 1
  fi
  sleep 1
done
