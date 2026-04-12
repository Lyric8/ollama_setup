param(
    [string]$BindHost = '127.0.0.1',
    [int]$Port = 18080
)

$ErrorActionPreference = 'Stop'

$apiFile = Join-Path $PSScriptRoot '..\api\gemma_agent_api.py'
if (-not (Test-Path $apiFile)) {
    throw "API file not found: $apiFile"
}

if (-not $env:OLLAMA_BASE_URL) { $env:OLLAMA_BASE_URL = 'http://127.0.0.1:11434' }
if (-not $env:GEMMA_DEFAULT_MODEL) { $env:GEMMA_DEFAULT_MODEL = 'gemma4:e4b' }
if (-not $env:GEMMA_DEFAULT_NUM_CTX) { $env:GEMMA_DEFAULT_NUM_CTX = '4096' }
if (-not $env:GEMMA_DEFAULT_MAX_TOKENS) { $env:GEMMA_DEFAULT_MAX_TOKENS = '256' }
if (-not $env:GEMMA_DEFAULT_TEMPERATURE) { $env:GEMMA_DEFAULT_TEMPERATURE = '0.2' }

Write-Host "Starting Gemma Agent API on http://${BindHost}:$Port"
Write-Host "Ollama backend: $($env:OLLAMA_BASE_URL)"
Write-Host "Default model: $($env:GEMMA_DEFAULT_MODEL)"

& python -m uvicorn gemma_agent_api:app --app-dir (Join-Path $PSScriptRoot '..\api') --host $BindHost --port $Port
