#!/usr/bin/env bash

set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/notch-qs"
BIN_DIR="$HOME/.local/bin"
SERVICE_DIR="$HOME/.config/systemd/user"
CONFIG_DIR="$HOME/.config/notch-qs"

echo "Installing Notch-qs..."

if ! command -v quickshell >/dev/null 2>&1; then
    echo "Error: quickshell is not installed."
    exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
    echo "Error: cargo is not installed."
    exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Error: systemctl is not installed."
    exit 1
fi

mkdir -p "$BIN_DIR"
mkdir -p "$SERVICE_DIR"
mkdir -p "$CONFIG_DIR"

echo "Building Notch backend..."

cd "$ROOT/rust"
cargo build --release

if [ ! -f "$ROOT/rust/target/release/notch-backend" ]; then
    echo "Error: notch-backend binary was not built."
    exit 1
fi

echo "Installing files..."

rm -rf "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"

cp -r "$ROOT/config" "$INSTALL_DIR/"
cp -r "$ROOT/ui" "$INSTALL_DIR/"
cp "$ROOT/shell.qml" "$INSTALL_DIR/"

install -Dm755 \
    "$ROOT/rust/target/release/notch-backend" \
    "$BIN_DIR/notch-backend"

cat >"$BIN_DIR/notch-qs" <<'EOF'
#!/usr/bin/env bash

set -e

INSTALL_DIR="$HOME/.local/share/notch-qs"

cd "$INSTALL_DIR"

exec quickshell -p "$INSTALL_DIR"
EOF

chmod 755 "$BIN_DIR/notch-qs"

cat >"$SERVICE_DIR/notch-backend.service" <<'EOF'
[Unit]
Description=Notch Backend
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/notch-backend
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
EOF

if [ ! -f "$CONFIG_DIR/config.json" ]; then
    cp "$ROOT/config/default.json" "$CONFIG_DIR/config.json"
fi

systemctl --user daemon-reload
systemctl --user enable notch-backend.service
systemctl --user restart notch-backend.service

if ! systemctl --user is-active --quiet notch-backend.service; then
    echo
    echo "Error: notch-backend.service failed to start."
    echo
    systemctl --user status notch-backend.service --no-pager
    exit 1
fi

echo
echo "Notch-qs installed successfully."
echo
echo "Run:"
echo "  notch-qs"
echo
echo "Installed to:"
echo "  $INSTALL_DIR"
echo "  $BIN_DIR/notch-qs"
echo "  $BIN_DIR/notch-backend"
echo
echo "Backend:"
echo "  systemctl --user status notch-backend.service"
