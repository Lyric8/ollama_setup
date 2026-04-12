param(
    [string]$ModelPath = 'D:\OllamaModels',
    [string]$ListenHost = '0.0.0.0:11434',
    [int]$ContextLength = 65536,
    [string]$KeepAlive = '10m',
    [string]$NoCloud = '1',
    [string]$FlashAttention = '1'
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path $ModelPath | Out-Null

[System.Environment]::SetEnvironmentVariable('OLLAMA_MODELS', $ModelPath, 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_HOST', $ListenHost, 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH', "$ContextLength", 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_KEEP_ALIVE', $KeepAlive, 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_NO_CLOUD', $NoCloud, 'User')
[System.Environment]::SetEnvironmentVariable('OLLAMA_FLASH_ATTENTION', $FlashAttention, 'User')

$env:OLLAMA_MODELS = $ModelPath
$env:OLLAMA_HOST = $ListenHost
$env:OLLAMA_CONTEXT_LENGTH = "$ContextLength"
$env:OLLAMA_KEEP_ALIVE = $KeepAlive
$env:OLLAMA_NO_CLOUD = $NoCloud
$env:OLLAMA_FLASH_ATTENTION = $FlashAttention

[pscustomobject]@{
    OLLAMA_MODELS = $env:OLLAMA_MODELS
    OLLAMA_HOST = $env:OLLAMA_HOST
    OLLAMA_CONTEXT_LENGTH = $env:OLLAMA_CONTEXT_LENGTH
    OLLAMA_KEEP_ALIVE = $env:OLLAMA_KEEP_ALIVE
    OLLAMA_NO_CLOUD = $env:OLLAMA_NO_CLOUD
    OLLAMA_FLASH_ATTENTION = $env:OLLAMA_FLASH_ATTENTION
} | Format-List
