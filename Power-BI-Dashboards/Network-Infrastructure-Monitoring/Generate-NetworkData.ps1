#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates synthetic network infrastructure monitoring data

.DESCRIPTION
    Creates realistic CSV datasets for DHCP scope utilization, network device inventory,
    and campus connectivity metrics for K-12 network monitoring.

.EXAMPLE
    .\Generate-NetworkData.ps1
    Generates network monitoring sample data
#>

$OutputPath = "$PSScriptRoot/sample-data"

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "
=== Generating Network Infrastructure Sample Data ===" -ForegroundColor Cyan

# 1. DHCP Scope Utilization
Write-Host "
[1/2] Generating DHCP scope utilization data..." -ForegroundColor Yellow

$vlanScopes = @(
    @{Name="Student-VLAN"; Network="10.100.0.0/16"; Size=65534; Campus="All"; BaseUtil=0.65}
    @{Name="Staff-VLAN"; Network="10.101.0.0/16"; Size=65534; Campus="All"; BaseUtil=0.25}
    @{Name="Admin-VLAN"; Network="10.102.0.0/24"; Size=254; Campus="Main"; BaseUtil=0.75}
    @{Name="IoT-VLAN"; Network="10.103.0.0/16"; Size=65534; Campus="All"; BaseUtil=0.35}
    @{Name="Guest-VLAN"; Network="10.104.0.0/16"; Size=65534; Campus="All"; BaseUtil=0.15}
)

$dhcpData = @()
$startDate = (Get-Date).AddDays(-30)

for ($i = 0; $i -lt 30; $i++) {
    $date = $startDate.AddDays($i)
    $dayOfWeek = $date.DayOfWeek

    # Utilization varies by day (higher on weekdays)
    $weekdayFactor = if ($dayOfWeek -in 'Monday','Tuesday','Wednesday','Thursday','Friday') { 1.0 }
                     elseif ($dayOfWeek -eq 'Saturday') { 0.3 }
                     else { 0.2 }

    foreach ($scope in $vlanScopes) {
        $utilization = $scope.BaseUtil * $weekdayFactor + ((Get-Random -Minimum -5 -Maximum 5) / 100)
        $utilization = [Math]::Max(0.05, [Math]::Min(0.95, $utilization))  # Keep between 5% and 95%

        $addressesUsed = [Math]::Round($scope.Size * $utilization)
        $addressesAvailable = $scope.Size - $addressesUsed

        $dhcpData += [PSCustomObject]@{
            Date = $date.ToString("yyyy-MM-dd")
            ScopeName = $scope.Name
            Network = $scope.Network
            Campus = $scope.Campus
            TotalAddresses = $scope.Size
            AddressesUsed = $addressesUsed
            AddressesAvailable = $addressesAvailable
            UtilizationPercent = [Math]::Round($utilization * 100, 2)
            LeaseRate = Get-Random -Minimum 50 -Maximum 200
            ExpiringLeases24h = Get-Random -Minimum 10 -Maximum 100
        }
    }
}

$dhcpData | Export-Csv -Path "$OutputPath/dhcp-scope-utilization.csv" -NoTypeInformation
Write-Host "[OK] Created: dhcp-scope-utilization.csv (30 days, $($dhcpData.Count) records)" -ForegroundColor Green

# 2. Network Device Inventory
Write-Host "
[2/2] Generating network device inventory..." -ForegroundColor Yellow

$campuses = @("Main Campus", "North Campus", "South Campus", "East Campus")
$deviceTypes = @(
    @{Type="Core Switch"; Count=4; Model="Cisco Catalyst 9500"}
    @{Type="Distribution Switch"; Count=12; Model="Cisco Catalyst 9300"}
    @{Type="Access Switch"; Count=85; Model="Cisco Catalyst 9200"}
    @{Type="Wireless Controller"; Count=4; Model="Cisco 9800"}
    @{Type="Access Point"; Count=320; Model="Cisco Catalyst 9120AXI"}
    @{Type="Firewall"; Count=6; Model="Palo Alto PA-5220"}
    @{Type="Router"; Count=8; Model="Cisco ISR 4451"}
)

$deviceData = @()
$deviceId = 1

foreach ($deviceType in $deviceTypes) {
    for ($i = 1; $i -le $deviceType.Count; $i++) {
        $campus = $campuses[(Get-Random -Minimum 0 -Maximum $campuses.Count)]

        # Health status: 90% healthy, 8% warning, 2% critical
        $healthRand = Get-Random -Minimum 1 -Maximum 100
        $health = if ($healthRand -le 90) { "Healthy" }
                 elseif ($healthRand -le 98) { "Warning" }
                 else { "Critical" }

        $uptime = Get-Random -Minimum 1 -Maximum 365

        $deviceData += [PSCustomObject]@{
            DeviceID = "NET-{0:D4}" -f $deviceId
            DeviceType = $deviceType.Type
            Model = $deviceType.Model
            Location = $campus
            HealthStatus = $health
            UptimeDays = $uptime
            FirmwareVersion = "17.{0}.{1}" -f (Get-Random -Minimum 6 -Maximum 9), (Get-Random -Minimum 1 -Maximum 5)
            LastSeen = (Get-Date).AddHours(-(Get-Random -Minimum 0 -Maximum 24)).ToString("yyyy-MM-dd HH:mm:ss")
            CPUUtilization = Get-Random -Minimum 10 -Maximum 75
            MemoryUtilization = Get-Random -Minimum 20 -Maximum 80
            PortUtilization = if ($deviceType.Type -like "*Switch") { Get-Random -Minimum 40 -Maximum 90 } else { 0 }
        }
        $deviceId++
    }
}

$deviceData | Export-Csv -Path "$OutputPath/network-device-inventory.csv" -NoTypeInformation
Write-Host "[OK] Created: network-device-inventory.csv ($($deviceData.Count) devices)" -ForegroundColor Green

# Summary
$healthySummary = ($deviceData | Where-Object { $_.HealthStatus -eq "Healthy" }).Count
$warningSummary = ($deviceData | Where-Object { $_.HealthStatus -eq "Warning" }).Count
$criticalSummary = ($deviceData | Where-Object { $_.HealthStatus -eq "Critical" }).Count

Write-Host "
=== Data Generation Complete ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputPath" -ForegroundColor White
Write-Host "
Device Health Summary:" -ForegroundColor White
Write-Host "  - Healthy: $healthySummary devices" -ForegroundColor Green
Write-Host "  - Warning: $warningSummary devices" -ForegroundColor Yellow
Write-Host "  - Critical: $criticalSummary devices" -ForegroundColor Red

Write-Host "
Files created:" -ForegroundColor White
Get-ChildItem -Path $OutputPath -Filter *.csv | ForEach-Object {
    $size = [Math]::Round($_.Length / 1KB, 2)
    Write-Host "  - $($_.Name) ($size KB)" -ForegroundColor Gray
}
