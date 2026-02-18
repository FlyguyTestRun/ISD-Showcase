#!/usr/bin/env pwsh
# Generate Intune compliance status snapshot for reporting.

param(
    [switch]$DemoMode,
    [string]$ExportPath
)

function Get-DemoDevices {
    @(
        [pscustomobject]@{ Device='LT-001'; ComplianceState='compliant'; Platform='Windows'; LastSync=(Get-Date).AddHours(-2) }
        [pscustomobject]@{ Device='LT-002'; ComplianceState='noncompliant'; Platform='Windows'; LastSync=(Get-Date).AddHours(-6) }
        [pscustomobject]@{ Device='IPAD-012'; ComplianceState='compliant'; Platform='iOS'; LastSync=(Get-Date).AddHours(-3) }
        [pscustomobject]@{ Device='LT-099'; ComplianceState='unknown'; Platform='Windows'; LastSync=(Get-Date).AddDays(-2) }
    )
}

if ($DemoMode) {
    $devices = Get-DemoDevices
} else {
    # Expected Graph scopes: DeviceManagementManagedDevices.Read.All
    # Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
    # $devices = Get-MgDeviceManagementManagedDevice -All | Select-Object ...
    throw "Non-demo mode requires Microsoft Graph connection and tenant access. Use -DemoMode for safe demonstration."
}

$summary = $devices |
    Group-Object ComplianceState |
    ForEach-Object {
        [pscustomobject]@{
            ComplianceState = $_.Name
            DeviceCount = $_.Count
        }
    }

$summary

if ($ExportPath) {
    $summary | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported compliance snapshot to $ExportPath" -ForegroundColor Green
}
