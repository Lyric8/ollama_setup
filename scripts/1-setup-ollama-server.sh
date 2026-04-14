#!/bin/bash
# macOS equivalent of 1-setup-ollama-server.ps1
set -e

MODELS_PATH="${1:-$HOME/OllamaModels}"
LISTEN_HOST="${2:-0.0.0.0:11434}"
CONTEXT_LENGTH="${3:-65536}"
KEEP_ALIVE="${4:-10m}"

mkdir -p "$MODELS_PATH"

PLIST="$HOME/Library/LaunchAgents/com.ollama.server.plist"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/opt/ollama/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>${LISTEN_HOST}</string>
        <key>OLLAMA_MODELS</key>
        <string>${MODELS_PATH}</string>
        <key>OLLAMA_CONTEXT_LENGTH</key>
        <string>${CONTEXT_LENGTH}</string>
        <key>OLLAMA_KEEP_ALIVE</key>
        <string>${KEEP_ALIVE}</string>
        <key>OLLAMA_NO_CLOUD</key>
        <string>1</string>
        <key>OLLAMA_FLASH_ATTENTION</key>
        <string>1</string>
        <key>OLLAMA_KV_CACHE_TYPE</key>
        <string>q8_0</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${MODELS_PATH}/ollama.log</string>
    <key>StandardErrorPath</key>
    <string>${MODELS_PATH}/ollama-error.log</string>
</dict>
</plist>
EOF

echo "OLLAMA_HOST       = $LISTEN_HOST"
echo "OLLAMA_MODELS     = $MODELS_PATH"
echo "OLLAMA_CONTEXT    = $CONTEXT_LENGTH"
echo "OLLAMA_KEEP_ALIVE = $KEEP_ALIVE"
echo "Plist written to: $PLIST"
