#!/usr/bin/env bash

set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VISUALIZER_ROOT="$HOME/Projects/audio-visualizer"
INSTALL_DIR="$HOME/.local/share/notch-qs"
BIN_DIR="$HOME/.local/bin"

echo "Installing Notch-qs..."

if ! command -v quickshell >/dev/null 2>&1; then
    echo "Error: quickshell is not installed."
    exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
    echo "Error: cargo is not installed."
    exit 1
fi

if [ ! -d "$VISUALIZER_ROOT" ]; then
    echo "Error: audio-visualizer not found at:"
    echo "$VISUALIZER_ROOT"
    exit 1
fi

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$HOME/.cache"

echo "Building audio visualizer..."
cd "$VISUALIZER_ROOT"
cargo build --release

echo "Building Notch backend..."
cd "$ROOT/rust"
cargo build --release

echo "Installing files..."

rm -rf "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
cp -r "$ROOT/config" "$INSTALL_DIR/"
cp -r "$ROOT/ui" "$INSTALL_DIR/"
cp "$ROOT/shell.qml" "$INSTALL_DIR/"

cp "$VISUALIZER_ROOT/target/release/audio-visualizer" \
    "$BIN_DIR/audio-visualizer"

cp "$ROOT/rust/target/release/notch-backend" \
    "$BIN_DIR/notch-backend"

cat >"$BIN_DIR/notch-qs" <<'EOF'
#!/usr/bin/env bash

set -e

INSTALL_DIR="$HOME/.local/share/notch-qs"
SOCKET="/tmp/audio-visualizer.sock"
VIS_PID=""
QS_PID=""

cleanup() {
    trap - EXIT INT TERM

    if [ -n "$QS_PID" ] && kill -0 "$QS_PID" 2>/dev/null; then
        kill "$QS_PID" 2>/dev/null || true
        wait "$QS_PID" 2>/dev/null || true
    fi

    if [ -n "$VIS_PID" ] && kill -0 "$VIS_PID" 2>/dev/null; then
        kill "$VIS_PID" 2>/dev/null || true
        wait "$VIS_PID" 2>/dev/null || true
    fi

    rm -f "$SOCKET"
}

trap cleanup EXIT INT TERM

mkdir -p "$HOME/.cache"

audio-visualizer > "$HOME/.cache/notch-qs-audio.log" 2>&1 &
VIS_PID=$!

for _ in {1..50}; do
    if [ -S "$SOCKET" ]; then
        break
    fi

    if ! kill -0 "$VIS_PID" 2>/dev/null; then
        echo "Error: audio visualizer failed to start."
        exit 1
    fi

    sleep 0.1
done

if [ ! -S "$SOCKET" ]; then
    echo "Error: audio visualizer socket was not created."
    exit 1
fi

cd "$INSTALL_DIR"

quickshell -p "$INSTALL_DIR" &
QS_PID=$!

wait "$QS_PID"
EOF

chmod +x "$BIN_DIR/notch-qs"
chmod +x "$BIN_DIR/audio-visualizer"
chmod +x "$BIN_DIR/notch-backend"

mkdir -p "$HOME/.config/notch-qs"

if [ ! -f "$HOME/.config/notch-qs/config.json" ]; then
    cp "$ROOT/config/default.json" \
        "$HOME/.config/notch-qs/config.json"
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
