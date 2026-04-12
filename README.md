# Ollama Remote Setup

Windows-first scripts for running Ollama as a LAN-accessible model server and connecting to it from Claude Code on another machine.

This repo is designed for the workflow you described:

- one machine runs Ollama and Gemma models
- another machine runs Claude Code or other CLI tools
- the client points to the server over the LAN

## Server quick start

Assumptions:

- Ollama is already installed on the server machine
- the Gemma model is already downloaded, or you will download it after setup
- you want other machines on the LAN to reach `http://SERVER_IP:11434`

Run these scripts on the server machine in order:

1. `scripts\1-setup-ollama-server.ps1`
2. `scripts\2-open-ollama-firewall.ps1` in an elevated PowerShell window
3. `scripts\3-start-ollama-server.ps1`
4. `scripts\4-verify-ollama-server.ps1`

Default settings:

- `OLLAMA_MODELS=D:\OllamaModels`
- `OLLAMA_HOST=0.0.0.0:11434`
- `OLLAMA_CONTEXT_LENGTH=65536`
- `OLLAMA_KEEP_ALIVE=10m`

If the server is dedicated to Ollama and you want models to stay loaded, re-run setup with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\1-setup-ollama-server.ps1 -KeepAlive "-1"
```

## Download models

After setup, use Ollama normally:

```powershell
ollama pull gemma4:e4b
ollama pull gemma4:26b
```

Recommended starting point on a strong workstation:

- `gemma4:e4b` for lighter usage
- `gemma4:26b` if the machine has enough GPU memory and you want a stronger coding model

## Client quick start

On the client machine, start Claude Code against the remote Ollama server:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\5-start-claude-remote.ps1 -ServerUrl http://SERVER_IP:11434 -Model gemma4:e4b
```

That script sets:

- `ANTHROPIC_BASE_URL`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_CUSTOM_MODEL_OPTION`

Then launches:

```powershell
claude --model gemma4:e4b
```

## Optional wrapper API

If you want a simpler agent-facing API on top of Ollama, use:

- `api\gemma_agent_api.py`
- `scripts\6-start-gemma-agent-api.ps1`

That wrapper exposes:

- `GET /health`
- `GET /models`
- `POST /ask`
- `POST /chat`

## Notes

- The firewall script requires admin privileges.
- `Claude Code` only sends requests. Model load and unload behavior is still controlled by Ollama.
- If you want to unload a model manually:

```powershell
ollama stop gemma4:e4b
```
