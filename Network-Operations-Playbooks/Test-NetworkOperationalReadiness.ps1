#!/usr/bin/env pwsh
# Validate network KPI readiness against operational thresholds.

[CmdletBinding()]
param(
    [string]$NetworkKpiCsv = "$PSScriptRoot/../Operational-KPIs/sample-data/network-availability.csv",
    [double]$MinAvailabilityPercent = 99.5,
    [double]$MaxLatencyMs = 60,
    [double]$MaxPacketLossPercent = 1.5,
    [string]$OutputPath = "$PSScriptRoot/output"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $NetworkKpiCsv)) {
    throw "Network KPI CSV not found: $NetworkKpiCsv"
}
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$data = Import-Csv $NetworkKpiCsv | ForEach-Object {
    [pscustomobject]@{
        WeekStartDate = $_.WeekStartDate
        Campus = $_.Campus
        AvailabilityPercent = [double]$_.AvailabilityPercent
        AvgLatencyMs = [double]$_.AvgLatencyMs
        PacketLossPercent = [double]$_.PacketLossPercent
        OutageMinutes = [double]$_.OutageMinutes
    }
}

$results = $data | ForEach-Object {
    $passAvailability = $_.AvailabilityPercent -ge $MinAvailabilityPercent
    $passLatency = $_.AvgLatencyMs -le $MaxLatencyMs
    $passLoss = $_.PacketLossPercent -le $MaxPacketLossPercent
    [pscustomobject]@{
        WeekStartDate = $_.WeekStartDate
        Campus = $_.Campus
        AvailabilityPercent = $_.AvailabilityPercent
        AvgLatencyMs = $_.AvgLatencyMs
        PacketLossPercent = $_.PacketLossPercent
        ReadinessStatus = if ($passAvailability -and $passLatency -and $passLoss) { 'Pass' } else { 'Fail' }
        FailingChecks = @(
            if (-not $passAvailability) { 'Availability' }
            if (-not $passLatency) { 'Latency' }
            if (-not $passLoss) { 'PacketLoss' }
        ) -join ';'
    }
}

$summary = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('s')
    TotalRows = ($results | Measure-Object).Count
    PassCount = ($results | Where-Object ReadinessStatus -eq 'Pass' | Measure-Object).Count
    FailCount = ($results | Where-Object ReadinessStatus -eq 'Fail' | Measure-Object).Count
    AvailabilityThreshold = $MinAvailabilityPercent
    LatencyThresholdMs = $MaxLatencyMs
    PacketLossThresholdPercent = $MaxPacketLossPercent
}

$detailPath = Join-Path $OutputPath 'network-readiness-detail.csv'
$summaryPath = Join-Path $OutputPath 'network-readiness-summary.json'

$results | Export-Csv -Path $detailPath -NoTypeInformation
$summary | ConvertTo-Json -Depth 4 | Out-File -FilePath $summaryPath -Encoding utf8

Write-Host "Network readiness detail: $detailPath" -ForegroundColor Green
Write-Host "Network readiness summary: $summaryPath" -ForegroundColor Green
Write-Output $summary
