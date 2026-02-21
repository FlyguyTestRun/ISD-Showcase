#!/usr/bin/env pwsh
# Build campus-level capacity summary from DHCP and device inventory datasets.

[CmdletBinding()]
param(
    [string]$DhcpCsv = "$PSScriptRoot/../Power-BI-Dashboards/Network-Infrastructure-Monitoring/sample-data/dhcp-scope-utilization.csv",
    [string]$DeviceCsv = "$PSScriptRoot/../Power-BI-Dashboards/Network-Infrastructure-Monitoring/sample-data/network-device-inventory.csv",
    [string]$OutputPath = "$PSScriptRoot/output"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

foreach ($f in @($DhcpCsv,$DeviceCsv)) {
    if (-not (Test-Path $f)) { throw "Input CSV not found: $f" }
}
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$dhcp = Import-Csv $DhcpCsv
$devices = Import-Csv $DeviceCsv

$campusSummary = $devices |
    Group-Object Campus |
    ForEach-Object {
        $campus = $_.Name
        $group = $_.Group
        $totalDevices = ($group | Measure-Object).Count
        $critical = ($group | Where-Object HealthStatus -eq 'Critical' | Measure-Object).Count
        $warning = ($group | Where-Object HealthStatus -eq 'Warning' | Measure-Object).Count
        $healthy = ($group | Where-Object HealthStatus -eq 'Healthy' | Measure-Object).Count

        [pscustomobject]@{
            Campus = $campus
            TotalDevices = $totalDevices
            HealthyDevices = $healthy
            WarningDevices = $warning
            CriticalDevices = $critical
            HealthyPercent = if ($totalDevices -eq 0) { 0 } else { [math]::Round(($healthy / $totalDevices) * 100, 2) }
        }
    }

$dhcpSummary = $dhcp |
    Group-Object ScopeName |
    ForEach-Object {
        $avgUtil = ($_.Group | Measure-Object -Property UtilizationPercent -Average).Average
        $maxUtil = ($_.Group | Measure-Object -Property UtilizationPercent -Maximum).Maximum
        [pscustomobject]@{
            ScopeName = $_.Name
            AverageUtilizationPercent = [math]::Round([double]$avgUtil,2)
            PeakUtilizationPercent = [math]::Round([double]$maxUtil,2)
        }
    }

$campusPath = Join-Path $OutputPath 'campus-device-capacity.csv'
$dhcpPath = Join-Path $OutputPath 'dhcp-capacity-summary.csv'

$campusSummary | Sort-Object Campus | Export-Csv -Path $campusPath -NoTypeInformation
$dhcpSummary | Sort-Object ScopeName | Export-Csv -Path $dhcpPath -NoTypeInformation

Write-Host "Campus capacity report: $campusPath" -ForegroundColor Green
Write-Host "DHCP capacity report: $dhcpPath" -ForegroundColor Green

[pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('s')
    CampusReport = $campusPath
    DhcpReport = $dhcpPath
}
