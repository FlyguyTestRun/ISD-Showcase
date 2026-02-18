#!/usr/bin/env pwsh
# Capture Microsoft 365 service health incidents/advisories.

param(
    [switch]$DemoMode,
    [string]$ExportPath
)

function Get-DemoHealth {
    @(
        [pscustomobject]@{ Workload='Exchange Online'; Status='serviceDegradation'; IncidentId='EX123456'; Updated=(Get-Date).AddHours(-3) }
        [pscustomobject]@{ Workload='Teams'; Status='serviceOperational'; IncidentId='N/A'; Updated=(Get-Date).AddHours(-1) }
        [pscustomobject]@{ Workload='SharePoint Online'; Status='serviceRestored'; IncidentId='SP234567'; Updated=(Get-Date).AddHours(-8) }
    )
}

if ($DemoMode) {
    $health = Get-DemoHealth
} else {
    # Expected Graph scopes: ServiceHealth.Read.All
    # Connect-MgGraph -Scopes "ServiceHealth.Read.All"
    # $health = Get-MgAdminServiceAnnouncementIssue -All | Select-Object ...
    throw "Non-demo mode requires Microsoft Graph connection and tenant access. Use -DemoMode for safe demonstration."
}

$health

if ($ExportPath) {
    $health | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported service health snapshot to $ExportPath" -ForegroundColor Green
}
