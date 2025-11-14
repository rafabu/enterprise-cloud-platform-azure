# try {
#     $privateIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias `
#         (Get-NetIPConfiguration | Where-Object { $_.IPv4Address -and -not $_.NetAdapter.Status -eq "Disconnected" } |
#             Select-Object -First 1 -ExpandProperty InterfaceAlias) |
#         Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' } |
#         Select-Object -First 1 -ExpandProperty IPAddress)
# }
# catch {
#     # Write-output "Get-NetIPAddress failed, falling back to .net method"
# }
# if (-not $privateIP) {

# Cross-platform fallback using .NET
$privateIP = ([System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) |
    Where-Object { $_.AddressFamily -eq 'InterNetwork' -and $_.IPAddressToString -ne '127.0.0.1' } |
    Select-Object -First 1).IPAddressToString
# }
$output = @{"local_ip" = $privateIP } | ConvertTo-JSON
Write-Output $output