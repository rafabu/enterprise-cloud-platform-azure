#!/usr/bin/env pwsh

# Method 1: Use Azure Instance Metadata Service (works in Azure VMs)
try {
    $headers = @{ "Metadata" = "true" }
    $uri = "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2021-02-01&format=text"
    $privateIP = Invoke-RestMethod -Uri $uri -Headers $headers -TimeoutSec 5
} catch {
    # Fallback: Cross-platform .NET method
    try {
        # Get the local IP by connecting to a remote address (doesn't actually send data)
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect("8.8.8.8", 53)  # Connect to Google DNS
        $privateIP = $udpClient.Client.LocalEndPoint.Address.ToString()
        $udpClient.Close()
    } catch {
        # Second fallback: Get first non-loopback network adapter IP (Windows-specific)
        try {
            $privateIP = (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp,Manual -ErrorAction Stop | 
                Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.IPAddress -notlike "169.254.*" } | 
                Select-Object -First 1).IPAddress
        } catch {
            # If Get-NetIPAddress fails (Linux/Mac), use alternative method
            $privateIP = $null
        }
        
        if (-not $privateIP) {
            # Third fallback: Pure .NET DNS method (cross-platform)
            $privateIP = ([System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) |
                Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.IPAddressToString -ne '127.0.0.1' } |
                Select-Object -First 1).IPAddressToString
        }
    }
}

$output = @{"local_ip" = $privateIP } | ConvertTo-Json
Write-Output $output