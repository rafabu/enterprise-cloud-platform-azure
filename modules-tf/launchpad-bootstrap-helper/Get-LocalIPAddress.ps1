# Cross-platform using .NET
$privateIP = ([System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) |
    Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.IPAddressToString -ne '127.0.0.1' } |
    Select-Object -First 1).IPAddressToString
# }
$output = @{"local_ip" = $privateIP } | ConvertTo-JSON
Write-Output $output