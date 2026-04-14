#!/bin/bash
# macOS equivalent of 3-start-ollama-server.ps1
set -e

PLIST="$HOME/Library/LaunchAgents/com.ollama.server.plist"

# Unload if already running
launchctl unload "$PLIST" 2>/dev/null || true
sleep 1

launchctl load "$PLIST"

# Wait for healthy
for i in $(seq 1 30); do
    sleep 0.5
    if curl -sf http://localhost:11434/api/version > /dev/null 2>&1; then
        echo "Ollama is up."
        break
    fi
done

LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")
echo "Local API : http://localhost:11434"
echo "LAN API   : http://${LAN_IP}:11434"
echo ""
/opt/homebrew/opt/ollama/bin/ollama ps
