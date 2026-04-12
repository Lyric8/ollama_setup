param(
    [string]$RemoteSubnet
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"

$ruleName = 'Ollama LAN 11434'
$port = Get-OllamaPort

if (-not $RemoteSubnet) {
    $preferred = Get-PreferredIPv4Addresses | Select-Object -First 1
    if (-not $preferred) {
        throw 'Could not detect a preferred IPv4 adapter. Pass -RemoteSubnet explicitly.'
    }

    $RemoteSubnet = ConvertTo-NetworkCidr -IPAddress $preferred.IPAddress -PrefixLength $preferred.PrefixLength
}

$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Remove-NetFirewallRule -DisplayName $ruleName | Out-Null
}

New-NetFirewallRule `
    -DisplayName $ruleName `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort $port `
    -Profile Private `
    -RemoteAddress $RemoteSubnet | Out-Null

[pscustomobject]@{
    Rule = $ruleName
    Port = $port
    RemoteSubnet = $RemoteSubnet
} | Format-List
