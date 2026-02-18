#!/usr/bin/env pwsh
# Orchestrate cloud operations snapshots and export consolidated outputs.

[CmdletBinding()]
param(
    [switch]$DemoMode,
    [string]$OutputPath = "$PSScriptRoot/output"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$entraScript = Join-Path $PSScriptRoot 'Get-EntraRiskSummary.ps1'
$intuneScript = Join-Path $PSScriptRoot 'Get-IntuneComplianceSnapshot.ps1'
$m365Script = Join-Path $PSScriptRoot 'Get-M365ServiceHealthSnapshot.ps1'

foreach ($s in @($entraScript,$intuneScript,$m365Script)) {
    if (-not (Test-Path $s)) { throw "Missing required script: $s" }
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

$entraOut = Join-Path $OutputPath "entra-risk-$ts.csv"
$intuneOut = Join-Path $OutputPath "intune-compliance-$ts.csv"
$m365Out = Join-Path $OutputPath "m365-health-$ts.csv"

$entraSummary = & $entraScript -DemoMode:$DemoMode -ExportPath $entraOut
$intuneSummary = & $intuneScript -DemoMode:$DemoMode -ExportPath $intuneOut
$m365Health = & $m365Script -DemoMode:$DemoMode -ExportPath $m365Out

$consolidated = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('s')
    Mode = if ($DemoMode) { 'Demo' } else { 'Connected' }
    EntraRiskLevels = $entraSummary
    IntuneCompliance = $intuneSummary
    M365ServiceHealth = $m365Health
}

$jsonPath = Join-Path $OutputPath "cloudops-snapshot-$ts.json"
$consolidated | ConvertTo-Json -Depth 7 | Out-File -FilePath $jsonPath -Encoding utf8

Write-Host "Cloud ops snapshot created:" -ForegroundColor Green
Write-Host "  $entraOut"
Write-Host "  $intuneOut"
Write-Host "  $m365Out"
Write-Host "  $jsonPath"

Write-Output $consolidated
