#!/usr/bin/env pwsh

# Read JSON from stdin (Terraform external data source protocol)
$jsonInput = [Console]::In.ReadToEnd() | ConvertFrom-Json

$fqdn = $jsonInput.fqdn
$ips = $jsonInput.ips | ConvertFrom-Json

# Verify the FQDN resolves to the private endpoint IP
$resolvedIps = [System.Net.Dns]::GetHostAddresses($fqdn) | Select-Object -ExpandProperty IPAddressToString
$fqdnResolutionSuccess = $ips | Where-Object { $_ } | ForEach-Object { $resolvedIps -contains $_ } | Where-Object { $_ } | Select-Object -First 1

$output = @{
    "fqdn"                    = $fqdn;
    "ips"                     = $ips | ConvertTo-Json;
    "fqdn_resolution_success" = if ($fqdnResolutionSuccess) { "true" } else { "false" }
} | ConvertTo-Json

Write-Output $output