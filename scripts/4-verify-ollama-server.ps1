param(
    [string]$ExpectedModel = ''
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

$ollamaExe = Get-OllamaExe
$localApiBase = Get-LocalApiBase
$checks = @()

$checks += [pscustomobject]@{
    Check = 'User env OLLAMA_MODELS'
    Result = [Environment]::GetEnvironmentVariable('OLLAMA_MODELS', 'User')
}
$checks += [pscustomobject]@{
    Check = 'User env OLLAMA_HOST'
    Result = [Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'User')
}
$checks += [pscustomobject]@{
    Check = 'Local /api/tags'
    Result = ((Invoke-RestMethod -Uri "$localApiBase/api/tags" -Method GET).models | ForEach-Object { $_.name }) -join ', '
}
$checks += [pscustomobject]@{
    Check = 'Local /v1/models'
    Result = ((Invoke-RestMethod -Uri "$localApiBase/v1/models" -Method GET).data | ForEach-Object { $_.id }) -join ', '
}

foreach ($url in (Get-PreferredLanUrls)) {
    $checks += [pscustomobject]@{
        Check = "LAN /api/tags ($url)"
        Result = ((Invoke-RestMethod -Uri "$url/api/tags" -Method GET).models | ForEach-Object { $_.name }) -join ', '
    }
    $checks += [pscustomobject]@{
        Check = "LAN /v1/models ($url)"
        Result = ((Invoke-RestMethod -Uri "$url/v1/models" -Method GET).data | ForEach-Object { $_.id }) -join ', '
    }
}

$checks += [pscustomobject]@{
    Check = 'Loaded models'
    Result = (& $ollamaExe ps | Select-Object -Skip 1) -join ' | '
}

$checks | Format-Table -AutoSize

if ($ExpectedModel) {
    $visible = (Invoke-RestMethod -Uri "$localApiBase/v1/models" -Method GET).data | ForEach-Object { $_.id }
    if ($ExpectedModel -notin $visible) {
        throw "Expected model '$ExpectedModel' not found in Ollama model list."
    }
}
