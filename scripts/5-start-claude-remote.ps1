param(
    [Parameter(Mandatory = $true)][string]$ServerUrl,
    [string]$Model = 'gemma4:e4b',
    [string]$AuthToken = 'ollama'
)

$ErrorActionPreference = 'Stop'

$claude = Get-Command claude -ErrorAction Stop

$env:ANTHROPIC_BASE_URL = $ServerUrl.TrimEnd('/')
$env:ANTHROPIC_AUTH_TOKEN = $AuthToken
$env:ANTHROPIC_CUSTOM_MODEL_OPTION = $Model
$env:ANTHROPIC_CUSTOM_MODEL_OPTION_NAME = "Remote $Model via Ollama"
$env:ANTHROPIC_CUSTOM_MODEL_OPTION_DESCRIPTION = "Ollama backend at $($env:ANTHROPIC_BASE_URL)"

Write-Host "Claude Code backend: $($env:ANTHROPIC_BASE_URL)"
Write-Host "Model: $Model"

& $claude.Source --model $Model
