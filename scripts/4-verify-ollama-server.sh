#!/bin/bash
# macOS equivalent of 4-verify-ollama-server.ps1
set -e

LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")
LOCAL="http://localhost:11434"
LAN="http://${LAN_IP}:11434"

echo "=== Ollama Server Verification ==="
echo ""

echo "[Local /api/tags]"
curl -sf "$LOCAL/api/tags" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(' -', m['name']) for m in d.get('models',[])] or print('  (no models)')"

echo ""
echo "[LAN /api/tags] ($LAN)"
curl -sf "$LAN/api/tags" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(' -', m['name']) for m in d.get('models',[])] or print('  (no models)')"

echo ""
echo "[Loaded models]"
/opt/homebrew/opt/ollama/bin/ollama ps

echo ""
echo "LAN URL: $LAN"
