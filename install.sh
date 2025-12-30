#!/bin/bash
set -e

echo "🚀 Auth Panel installer starting..."

# ===== CONFIG =====
PANEL_DIR="/opt/auth-panel"
SERVICE_FILE="/etc/systemd/system/auth-panel.service"
TAR_NAME="mokarrambijoy-2025-12-21.tar.gz"

# ===== CHECK ROOT =====
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

# ===== CLEAN OLD =====
echo "🧹 Cleaning old install..."
systemctl stop auth-panel 2>/dev/null || true
rm -rf $PANEL_DIR
mkdir -p $PANEL_DIR

# ===== CHECK TAR =====
if [ ! -f "$TAR_NAME" ]; then
  echo "❌ $TAR_NAME not found in current directory"
  echo "➡️ Put the tar.gz file in same folder and run again"
  exit 1
fi

# ===== EXTRACT =====
echo "📦 Extracting panel..."
tar -xzf $TAR_NAME -C $PANEL_DIR --strip-components=1
chown -R ubuntu:ubuntu $PANEL_DIR

# ===== PYTHON ENV =====
echo "🐍 Setting up Python venv..."
cd $PANEL_DIR
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install flask gunicorn

# ===== SYSTEMD SERVICE =====
echo "⚙️ Creating systemd service..."
cat > $SERVICE_FILE <<EOF
[Unit]
Description=Auth Panel
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/opt/auth-panel
ExecStart=/opt/auth-panel/venv/bin/gunicorn -b 0.0.0.0:8181 app:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ===== START SERVICE =====
systemctl daemon-reload
systemctl reset-failed auth-panel
systemctl enable auth-panel
systemctl restart auth-panel

echo "✅ AUTH PANEL INSTALLED & RUNNING"
echo "🌐 Open: http://SERVER_IP:8181"