#!/usr/bin/env bash

set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/notch-qs"
BIN_DIR="$HOME/.local/bin"
SERVICE_DIR="$HOME/.config/systemd/user"

echo "Installing Notch-qs..."

if ! command -v quickshell >/dev/null 2>&1; then
    echo "Error: quickshell is not installed."
    exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
    echo "Error: cargo is not installed."
    exit 1
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$SERVICE_DIR"
mkdir -p "$HOME/.cache"

echo "Building Notch backend..."
cd "$ROOT/rust"
cargo build --release

echo "Installing files..."

rm -rf "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
cp -r "$ROOT/config" "$INSTALL_DIR/"
cp -r "$ROOT/ui" "$INSTALL_DIR/"
cp "$ROOT/shell.qml" "$INSTALL_DIR/"

cp "$ROOT/rust/target/release/notch-backend" \
    "$BIN_DIR/notch-backend"

cat >"$BIN_DIR/notch-qs" <<'EOF'
#!/usr/bin/env bash

set -e

INSTALL_DIR="$HOME/.local/share/notch-qs"

cd "$INSTALL_DIR"

exec quickshell -p "$INSTALL_DIR"
EOF

chmod +x "$BIN_DIR/notch-qs"
chmod +x "$BIN_DIR/notch-backend"

cat >"$SERVICE_DIR/notch-backend.service" <<'EOF'
[Unit]
Description=Notch Backend

[Service]
ExecStart=%h/.local/bin/notch-backend
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
EOF

mkdir -p "$HOME/.config/notch-qs"

if [ ! -f "$HOME/.config/notch-qs/config.json" ]; then
    cp "$ROOT/config/default.json" \
        "$HOME/.config/notch-qs/config.json"
fi

systemctl --user daemon-reload
systemctl --user enable notch-backend.service
systemctl --user restart notch-backend.service

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
