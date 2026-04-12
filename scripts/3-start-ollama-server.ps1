$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

$ollamaExe = Get-OllamaExe
$apiBase = Get-LocalApiBase

$env:OLLAMA_MODELS = [Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')
$env:OLLAMA_HOST = [Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'User')
$env:OLLAMA_CONTEXT_LENGTH = [Environment]::GetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', 'User')
$env:OLLAMA_KEEP_ALIVE = [Environment]::GetEnvironmentVariable('OLLAMA_KEEP_ALIVE', 'User')
$env:OLLAMA_NO_CLOUD = [Environment]::GetEnvironmentVariable('OLLAMA_NO_CLOUD', 'User')
$env:OLLAMA_FLASH_ATTENTION = [Environment]::GetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', 'User')

Get-Process 'ollama app' -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process ollama -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$proc = Start-Process -FilePath $ollamaExe -ArgumentList 'serve' -WindowStyle Hidden -PassThru

$healthy = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    try {
        Invoke-RestMethod -Uri "$apiBase/api/version" -Method GET | Out-Null
        $healthy = $true
        break
    } catch {
    }
}

if (-not $healthy) {
    throw "Ollama API did not become healthy on $apiBase"
}

Write-Host "Ollama PID: $($proc.Id)"
Write-Host "Local API: $apiBase"
Write-Host 'LAN URLs:'
foreach ($url in (Get-PreferredLanUrls)) {
    Write-Host "  $url"
}
Write-Host ''
& $ollamaExe ps
