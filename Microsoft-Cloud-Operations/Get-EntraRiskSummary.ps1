#!/usr/bin/env pwsh
# Summarize Entra identity risk signals for operations reporting.

param(
    [switch]$DemoMode,
    [string]$ExportPath
)

function Get-DemoData {
    @(
        [pscustomobject]@{ Date=(Get-Date).AddDays(-2).Date; RiskLevel='high'; EventType='anonymousIP'; Count=3 }
        [pscustomobject]@{ Date=(Get-Date).AddDays(-1).Date; RiskLevel='medium'; EventType='impossibleTravel'; Count=5 }
        [pscustomobject]@{ Date=(Get-Date).Date; RiskLevel='low'; EventType='newCountry'; Count=4 }
    )
}

if ($DemoMode) {
    $events = Get-DemoData
} else {
    # Expected Graph scopes: IdentityRiskEvent.Read.All, AuditLog.Read.All
    # Connect-MgGraph -Scopes "IdentityRiskEvent.Read.All","AuditLog.Read.All"
    # $events = Get-MgIdentityProtectionRiskDetection -All | Select-Object ...
    throw "Non-demo mode requires Microsoft Graph connection and tenant access. Use -DemoMode for safe demonstration."
}

$summary = $events |
    Group-Object RiskLevel |
    ForEach-Object {
        [pscustomobject]@{
            RiskLevel = $_.Name
            TotalEvents = ($_.Group | Measure-Object Count -Sum).Sum
        }
    }

$summary

if ($ExportPath) {
    $summary | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported risk summary to $ExportPath" -ForegroundColor Green
}
