#!/usr/bin/env pwsh
# Cross-platform using .NET
# $privateIP = ([System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) |
#     Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.IPAddressToString -ne '127.0.0.1' } |
#     Select-Object -First 1).IPAddressToString
# # }
# $output = @{"local_ip" = $privateIP } | ConvertTo-JSON
# Write-Output $output


# Method 1: Use Azure Instance Metadata Service
try {
    $headers = @{ "Metadata" = "true" }
    $uri = "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2021-02-01&format=text"
    $privateIP = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 5
} catch {
    # Fallback: Parse ip route output
    $routeOutput = & ip route get 8.8.8.8
    $privateIP = ($routeOutput | Select-String "src (\d+\.\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value })
    
    if (-not $privateIP) {
        # Second fallback: Get first non-loopback IP
        $privateIP = (& hostname -I).Split()[0]
    }
}

$output = @{"local_ip" = $privateIP } | ConvertTo-Json
Write-Output $output