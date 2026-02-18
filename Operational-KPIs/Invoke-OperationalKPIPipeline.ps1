#!/usr/bin/env pwsh
# Build consolidated KPI summaries and exception reports from operational datasets.

[CmdletBinding()]
param(
    [string]$InputPath = "$PSScriptRoot/sample-data",
    [string]$OutputPath = "$PSScriptRoot/output",
    [double]$MinChangeSuccessPercent = 95.0,
    [double]$MinBackupSLAPercent = 98.0,
    [double]$MinAvailabilityPercent = 99.5,
    [double]$MaxP1MTTRMinutes = 60.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Import-RequiredCsv {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Required file not found: $Path" }
    return Import-Csv -Path $Path
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$incidentCsv = Join-Path $InputPath 'incident-trends.csv'
$changeCsv   = Join-Path $InputPath 'change-success-rate.csv'
$backupCsv   = Join-Path $InputPath 'backup-sla-attainment.csv'
$networkCsv  = Join-Path $InputPath 'network-availability.csv'

$incidents = Import-RequiredCsv -Path $incidentCsv
$changes   = Import-RequiredCsv -Path $changeCsv
$backups   = Import-RequiredCsv -Path $backupCsv
$network   = Import-RequiredCsv -Path $networkCsv

# Normalize numeric fields
$incidents | ForEach-Object {
    $_.P1Incidents = [int]$_.P1Incidents
    $_.TotalIncidents = [int]$_.TotalIncidents
    $_.MTTRMinutes = [double]$_.MTTRMinutes
}
$changes | ForEach-Object { $_.ChangeSuccessRatePercent = [double]$_.ChangeSuccessRatePercent }
$backups | ForEach-Object { $_.BackupSLAAttainmentPercent = [double]$_.BackupSLAAttainmentPercent }
$network | ForEach-Object {
    $_.AvailabilityPercent = [double]$_.AvailabilityPercent
    $_.PacketLossPercent = [double]$_.PacketLossPercent
    $_.AvgLatencyMs = [double]$_.AvgLatencyMs
}

$summary = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('s')
    IncidentSummary = [pscustomobject]@{
        WeeksIncluded = ($incidents | Measure-Object).Count
        TotalIncidents = ($incidents | Measure-Object -Property TotalIncidents -Sum).Sum
        TotalP1Incidents = ($incidents | Measure-Object -Property P1Incidents -Sum).Sum
        AverageMTTRMinutes = [math]::Round(($incidents | Measure-Object -Property MTTRMinutes -Average).Average,2)
        MeetsTarget = [math]::Round(($incidents | Measure-Object -Property MTTRMinutes -Average).Average,2) -le $MaxP1MTTRMinutes
    }
    ChangeSummary = [pscustomobject]@{
        WeeksIncluded = ($changes | Measure-Object).Count
        AverageSuccessPercent = [math]::Round(($changes | Measure-Object -Property ChangeSuccessRatePercent -Average).Average,2)
        LowestSuccessPercent = [math]::Round(($changes | Measure-Object -Property ChangeSuccessRatePercent -Minimum).Minimum,2)
        MeetsTarget = [math]::Round(($changes | Measure-Object -Property ChangeSuccessRatePercent -Average).Average,2) -ge $MinChangeSuccessPercent
    }
    BackupSummary = [pscustomobject]@{
        WeeksIncluded = ($backups | Measure-Object).Count
        AverageSLAPercent = [math]::Round(($backups | Measure-Object -Property BackupSLAAttainmentPercent -Average).Average,2)
        LowestSLAPercent = [math]::Round(($backups | Measure-Object -Property BackupSLAAttainmentPercent -Minimum).Minimum,2)
        MeetsTarget = [math]::Round(($backups | Measure-Object -Property BackupSLAAttainmentPercent -Average).Average,2) -ge $MinBackupSLAPercent
    }
    NetworkSummary = [pscustomobject]@{
        RowsIncluded = ($network | Measure-Object).Count
        AverageAvailabilityPercent = [math]::Round(($network | Measure-Object -Property AvailabilityPercent -Average).Average,2)
        WorstAvailabilityPercent = [math]::Round(($network | Measure-Object -Property AvailabilityPercent -Minimum).Minimum,2)
        AveragePacketLossPercent = [math]::Round(($network | Measure-Object -Property PacketLossPercent -Average).Average,2)
        AverageLatencyMs = [math]::Round(($network | Measure-Object -Property AvgLatencyMs -Average).Average,2)
        MeetsTarget = [math]::Round(($network | Measure-Object -Property AvailabilityPercent -Average).Average,2) -ge $MinAvailabilityPercent
    }
}

$exceptions = @()
$exceptions += $changes | Where-Object { $_.ChangeSuccessRatePercent -lt $MinChangeSuccessPercent } | ForEach-Object {
    [pscustomobject]@{ Category='Change'; Date=$_.WeekStartDate; Value=$_.ChangeSuccessRatePercent; Threshold=$MinChangeSuccessPercent; Note='Change success below target' }
}
$exceptions += $backups | Where-Object { $_.BackupSLAAttainmentPercent -lt $MinBackupSLAPercent } | ForEach-Object {
    [pscustomobject]@{ Category='BackupSLA'; Date=$_.WeekStartDate; Value=$_.BackupSLAAttainmentPercent; Threshold=$MinBackupSLAPercent; Note='Backup SLA below target' }
}
$exceptions += $network | Where-Object { $_.AvailabilityPercent -lt $MinAvailabilityPercent } | ForEach-Object {
    [pscustomobject]@{ Category='NetworkAvailability'; Date=$_.WeekStartDate; Value=$_.AvailabilityPercent; Threshold=$MinAvailabilityPercent; Note="Availability below target ($($_.Campus))" }
}

$summaryPath = Join-Path $OutputPath 'kpi-summary.json'
$exceptionsPath = Join-Path $OutputPath 'kpi-exceptions.csv'

$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $summaryPath -Encoding utf8
$exceptions | Export-Csv -Path $exceptionsPath -NoTypeInformation

Write-Host "Summary written: $summaryPath" -ForegroundColor Green
Write-Host "Exceptions written: $exceptionsPath" -ForegroundColor Green
Write-Output $summary
