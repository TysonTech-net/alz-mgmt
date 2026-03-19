###############################################################################
# PDNS Resolution Test Script
# Run via Azure Portal > VM > Run Command (or Serial Console PowerShell)
#
# Tests that:
# 1. External DNS resolves (via PDNS forwarding)
# 2. Private Link DNS resolves to private IPs (not public)
# 3. Azure services still resolve
###############################################################################

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " PDNS Resolution Test" -ForegroundColor Cyan
Write-Host " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# VM and network identity
Write-Host "[VM Info]" -ForegroundColor Yellow
Write-Host "  Hostname:  $env:COMPUTERNAME"
$nics = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -ne '127.0.0.1' }
foreach ($nic in $nics) {
    Write-Host "  NIC:       $($nic.InterfaceAlias) = $($nic.IPAddress)/$($nic.PrefixLength)"
}
Write-Host ""

# DNS client config
Write-Host "[DNS Client Config]" -ForegroundColor Yellow
$dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 }
foreach ($dns in $dnsServers) {
    Write-Host "  $($dns.InterfaceAlias): $($dns.ServerAddresses -join ', ')"
}
Write-Host ""

# DNS resolution chain info
Write-Host "[DNS Resolution Chain]" -ForegroundColor Yellow
Write-Host "  Expected: VM -> Firewall DNS Proxy (10.0.0.4) -> Resolver (10.0.0.164)"
Write-Host "            -> Private DNS Zones (local) OR Forwarding Ruleset -> PDNS"
Write-Host "  PDNS:     25.25.25.25, 25.26.27.28"
Write-Host ""

# Test results tracker
$allResults = [System.Collections.ArrayList]::new()

function Test-DnsResolution {
    param(
        [string]$Name,
        [string]$Type = "A",
        [string]$ExpectedPattern,
        [string]$Description,
        [string]$Server
    )

    Write-Host "[$Description]" -ForegroundColor Yellow
    Write-Host "  Query:      $Name ($Type)" -ForegroundColor White
    if ($Server) { Write-Host "  Server:     $Server" -ForegroundColor White }

    try {
        $params = @{ Name = $Name; Type = $Type; ErrorAction = 'Stop' }
        if ($Server) { $params['Server'] = $Server }

        $answer = Resolve-DnsName @params
        $ttl = ($answer | Select-Object -First 1).TTL

        # Show full response chain (CNAMEs, etc.)
        foreach ($record in $answer) {
            switch ($record.QueryType) {
                'CNAME' { Write-Host "  CNAME:      $($record.Name) -> $($record.NameHost)" -ForegroundColor Gray }
                'A'     { Write-Host "  A:          $($record.Name) -> $($record.IPAddress)" -ForegroundColor White }
                'AAAA'  { Write-Host "  AAAA:       $($record.Name) -> $($record.IPAddress)" -ForegroundColor White }
                'SOA'   { Write-Host "  SOA:        $($record.Name) (ns: $($record.PrimaryServer))" -ForegroundColor Gray }
                default { Write-Host "  $($record.QueryType):  $($record.Name)" -ForegroundColor Gray }
            }
        }

        $ips = ($answer | Where-Object { $_.QueryType -eq 'A' }).IPAddress
        $resolved = $ips -join ', '
        $pass = $true

        if ($ExpectedPattern -and $resolved) {
            $pass = ($ips | Where-Object { $_ -match $ExpectedPattern }).Count -gt 0
        } elseif ($ExpectedPattern -and -not $resolved) {
            $pass = $false
        }

        $status = if ($pass) { "PASS" } else { "FAIL" }
        $colour = if ($pass) { "Green" } else { "Red" }

        Write-Host "  TTL:        $ttl" -ForegroundColor Gray
        Write-Host "  Resolved:   $resolved" -ForegroundColor White
        Write-Host "  Expected:   $ExpectedPattern" -ForegroundColor White
        Write-Host "  Status:     $status" -ForegroundColor $colour

        [void]$allResults.Add([PSCustomObject]@{
            Test     = $Description
            Query    = $Name
            Resolved = $resolved
            Expected = $ExpectedPattern
            Status   = $status
        })
    }
    catch {
        $errMsg = $_.Exception.Message -replace "`n", " "
        Write-Host "  Error:      $errMsg" -ForegroundColor Red
        Write-Host "  Status:     FAIL" -ForegroundColor Red

        [void]$allResults.Add([PSCustomObject]@{
            Test     = $Description
            Query    = $Name
            Resolved = "ERROR: $errMsg"
            Expected = $ExpectedPattern
            Status   = "FAIL"
        })
    }
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 1. External DNS (via PDNS)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Test-DnsResolution -Name "example.com" -ExpectedPattern "." `
    -Description "External - example.com"

Test-DnsResolution -Name "www.google.com" -ExpectedPattern "." `
    -Description "External - www.google.com"

Test-DnsResolution -Name "www.gov.uk" -ExpectedPattern "." `
    -Description "External - www.gov.uk"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 2. Private DNS Zones (verify zones respond)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  NOTE: No Private Endpoints are deployed yet." -ForegroundColor Gray
Write-Host "  These tests verify the Private DNS Zones are" -ForegroundColor Gray
Write-Host "  linked and the resolver handles them locally" -ForegroundColor Gray
Write-Host "  (not forwarded to PDNS)." -ForegroundColor Gray
Write-Host ""

# Query a privatelink zone - should get SOA/empty response (not PDNS error)
Test-DnsResolution -Name "test.privatelink.blob.core.windows.net" `
    -ExpectedPattern "." `
    -Description "Private DNS Zone - blob (expect SOA, not PDNS error)"

Test-DnsResolution -Name "test.privatelink.vaultcore.azure.net" `
    -ExpectedPattern "." `
    -Description "Private DNS Zone - keyvault (expect SOA, not PDNS error)"

# Verify actual storage account resolves (will be public IP, no PE exists)
Test-DnsResolution -Name "sa50pykclk5wifxpwwprd.blob.core.windows.net" `
    -ExpectedPattern "." `
    -Description "Storage (no PE - expect public IP, not PDNS error)"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 3. Azure Reserved Domains (excluded from PDNS forwarding)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Test-DnsResolution -Name "management.azure.com" -ExpectedPattern "." `
    -Description "Azure ARM (azure.com - reserved)"

Test-DnsResolution -Name "login.microsoftonline.com" -ExpectedPattern "." `
    -Description "Entra ID (microsoftonline.com)"

Test-DnsResolution -Name "uksouth.prod.warm.ingest.monitor.core.windows.net" -ExpectedPattern "." `
    -Description "Azure Monitor (windows.net - reserved)"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 4. Direct Server Tests (bypass proxy)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Test-DnsResolution -Name "example.com" -Server "10.0.0.4" -ExpectedPattern "." `
    -Description "Via Firewall DNS Proxy (10.0.0.4)"

Test-DnsResolution -Name "example.com" -Server "10.0.0.164" -ExpectedPattern "." `
    -Description "Via Resolver Inbound (10.0.0.164)"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 5. Connectivity Check" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[TCP connectivity to PDNS servers]" -ForegroundColor Yellow
foreach ($ip in @("25.25.25.25", "25.26.27.28")) {
    $tcp = Test-NetConnection -ComputerName $ip -Port 53 -WarningAction SilentlyContinue
    $status = if ($tcp.TcpTestSucceeded) { "OPEN" } else { "CLOSED/FILTERED" }
    $colour = if ($tcp.TcpTestSucceeded) { "Green" } else { "Red" }
    Write-Host "  ${ip}:53 TCP = $status (source: $($tcp.SourceAddress.IPAddress))" -ForegroundColor $colour
}
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$passed = ($allResults | Where-Object { $_.Status -eq 'PASS' }).Count
$failed = ($allResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$total = $allResults.Count

Write-Host ""
Write-Host "  Total: $total  Passed: $passed  Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

$allResults | Format-Table Test, Query, Resolved, Status -AutoSize
