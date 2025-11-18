#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Retrieves the public IP address using multiple reliable sources with retry logic and fallbacks.

.DESCRIPTION
    This script attempts to get the public IP address from multiple reliable sources in order:
    1. ipify.org (primary)
    2. httpbin.org (fallback 1)
    3. icanhazip.com (fallback 2)
    4. ifconfig.me (fallback 3)
    5. api64.ipify.org (fallback 4)
    
    Each source is tried with retry logic before moving to the next fallback.
    If all external sources fail, it attempts to detect the public IP via reverse DNS.

.OUTPUTS
    JSON object with public_ip field containing the detected IP address.
#>

param(
    [int]$MaxRetries = 3,
    [int]$TimeoutSeconds = 15,
    [int]$RetryDelaySeconds = 2
)

# Define multiple reliable public IP services
$ipSources = @(
    @{
        Name = "ipify.org"
        Url = "https://api.ipify.org?format=json"
        Parser = { param($response) 
            try { 
                ($response | ConvertFrom-Json).ip 
            } catch { 
                # Fallback: try to extract from plain text
                if ($response -match '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b') {
                    $matches[0]
                } else {
                    $null
                }
            }
        }
    },
    @{
        Name = "httpbin.org"
        Url = "https://httpbin.org/ip"
        Parser = { param($response) 
            try {
                ($response | ConvertFrom-Json).origin.Split(',')[0].Trim()
            } catch {
                # Try to extract IP from plain text response
                if ($response -match '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b') {
                    $matches[0]
                } else {
                    $null
                }
            }
        }
    },
    @{
        Name = "icanhazip.com"
        Url = "https://icanhazip.com"
        Parser = { param($response) 
            $ip = $response.Trim()
            if ($ip -match '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b') {
                $matches[0]
            } else {
                $null
            }
        }
    },
    @{
        Name = "ifconfig.me"
        Url = "https://ifconfig.me/ip"
        Parser = { param($response) 
            $ip = $response.Trim()
            if ($ip -match '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b') {
                $matches[0]
            } else {
                $null
            }
        }
    },
    @{
        Name = "ipify64.org"
        Url = "https://api64.ipify.org?format=json"
        Parser = { param($response) 
            try { 
                ($response | ConvertFrom-Json).ip 
            } catch { 
                # Fallback: try to extract from plain text
                if ($response -match '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b') {
                    $matches[0]
                } else {
                    $null
                }
            }
        }
    }
)

function Test-ValidIPAddress {
    param([string]$IPAddress)
    
    if ([string]::IsNullOrWhiteSpace($IPAddress)) {
        return $false
    }
    
    # Enhanced IPv4 validation with range checks
    if ($IPAddress -match '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
        # Additional checks for valid public IP ranges (exclude private/reserved ranges)
        $octets = $IPAddress.Split('.')
        $firstOctet = [int]$octets[0]
        $secondOctet = [int]$octets[1]
        
        # Exclude private IP ranges and other reserved ranges
        $isPrivate = ($firstOctet -eq 10) -or 
                    (($firstOctet -eq 172) -and ($secondOctet -ge 16) -and ($secondOctet -le 31)) -or
                    (($firstOctet -eq 192) -and ($secondOctet -eq 168)) -or
                    ($firstOctet -eq 127) -or  # Loopback
                    ($firstOctet -eq 169 -and $secondOctet -eq 254) -or  # Link-local
                    ($firstOctet -ge 224)  # Multicast and reserved
        
        return -not $isPrivate
    }
    
    return $false
}

function Get-PublicIPFromSource {
    param(
        [hashtable]$Source,
        [int]$MaxRetries,
        [int]$TimeoutSeconds,
        [int]$RetryDelaySeconds
    )
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            # Create web client with proper error handling and user agent
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell-PublicIP-Detector/1.0")
            
            try {
                $response = $webClient.DownloadString($Source.Url)
                $ipAddress = & $Source.Parser $response
                
                if (Test-ValidIPAddress -IPAddress $ipAddress) {
                    return $ipAddress
                } else {
                }
            } finally {
                $webClient.Dispose()
            }
        } catch {
            
            if ($attempt -lt $MaxRetries) {
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }
    
    return $null
}

function Get-PublicIPFallback {
    <#
    .SYNOPSIS
    Last resort method to detect public IP using DNS resolution techniques
    #>
    
    try {
        # Try to resolve opendns resolver and get the response
        $dnsResult = Resolve-DnsName -Name "myip.opendns.com" -Server "208.67.222.222" -Type "A" -ErrorAction Stop
        if ($dnsResult -and $dnsResult.IPAddress) {
            $ip = $dnsResult.IPAddress
            if (Test-ValidIPAddress -IPAddress $ip) {
                return $ip
            }
        }
    } catch {
    }
    
    # If DNS method fails, return a safe fallback
    return "0.0.0.0"
}

# Main execution
$detectedIP = $null
$usedSource = $null

foreach ($source in $ipSources) {
    $detectedIP = Get-PublicIPFromSource -Source $source -MaxRetries $MaxRetries -TimeoutSeconds $TimeoutSeconds -RetryDelaySeconds $RetryDelaySeconds
    
    if ($detectedIP) {
        $usedSource = $source.Name
        break
    }
}

# If all HTTP sources failed, try DNS fallback
if (-not $detectedIP) {
    $detectedIP = Get-PublicIPFallback
    $usedSource = "dns_fallback"
}

if ($detectedIP -and $detectedIP -ne "0.0.0.0") {
    $output = @{
        "public_ip" = $detectedIP
        "source" = $usedSource
        "timestamp" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
        "status" = "success"
    } | ConvertTo-Json -Compress
    
    Write-Output $output
} else {
    # Return a response that Terraform can handle gracefully
    $output = @{
        "public_ip" = "0.0.0.0"
        "source" = "failed"
        "error" = "All IP detection sources failed"
        "timestamp" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
        "status" = "failed"
    } | ConvertTo-Json -Compress
    
    Write-Output $output
    # Don't exit with error code in Terraform context - let Terraform handle the failed response
    exit 0
}