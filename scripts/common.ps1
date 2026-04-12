$ErrorActionPreference = 'Stop'

function Get-OllamaExe {
    $command = Get-Command ollama -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
    if (Test-Path $candidate) {
        return $candidate
    }

    throw 'Ollama executable not found. Install Ollama first.'
}

function Get-OllamaPort {
    $hostValue = [Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'User')
    if (-not $hostValue) { $hostValue = '0.0.0.0:11434' }

    $match = [regex]::Match($hostValue, ':(\d+)$')
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }

    return 11434
}

function Get-LocalApiBase {
    $port = Get-OllamaPort
    return "http://127.0.0.1:$port"
}

function Get-PreferredIPv4Addresses {
    $excludePatterns = 'VMware|Tailscale|vEthernet|Hyper-V|Loopback|Bluetooth|Virtual'

    $addresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*' -and
            $_.PrefixOrigin -ne 'WellKnown' -and
            $_.InterfaceAlias -notmatch $excludePatterns
        } |
        Sort-Object InterfaceMetric, SkipAsSource, PrefixLength

    return $addresses
}

function Get-PreferredLanUrls {
    $port = Get-OllamaPort
    $urls = @()

    foreach ($item in (Get-PreferredIPv4Addresses)) {
        $urls += "http://$($item.IPAddress):$port"
    }

    return $urls | Select-Object -Unique
}

function ConvertTo-NetworkCidr {
    param(
        [Parameter(Mandatory = $true)][string]$IPAddress,
        [Parameter(Mandatory = $true)][int]$PrefixLength
    )

    $ipBytes = ([System.Net.IPAddress]::Parse($IPAddress)).GetAddressBytes()
    [array]::Reverse($ipBytes)
    $ipInt = [BitConverter]::ToUInt32($ipBytes, 0)

    $maskInt = [uint32]0
    for ($i = 0; $i -lt $PrefixLength; $i++) {
        $maskInt = $maskInt -bor ([uint32]1 -shl (31 - $i))
    }

    $networkInt = $ipInt -band $maskInt
    $networkBytes = [BitConverter]::GetBytes($networkInt)
    [array]::Reverse($networkBytes)
    $networkIp = ([System.Net.IPAddress]::new($networkBytes)).ToString()

    return "$networkIp/$PrefixLength"
}
