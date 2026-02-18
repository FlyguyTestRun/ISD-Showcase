#!/usr/bin/env pwsh
# Generate synthetic operations KPI data for systems + network reporting demos.

param(
    [string]$OutputPath = "$PSScriptRoot/sample-data",
    [int]$Weeks = 12
)

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$today = Get-Date
$weekStarts = 0..($Weeks - 1) | ForEach-Object { $today.Date.AddDays(-7 * $_) } | Sort-Object

# incident-trends.csv
$incidentRows = foreach ($d in $weekStarts) {
    $p1 = Get-Random -Minimum 1 -Maximum 5
    $p2 = Get-Random -Minimum 6 -Maximum 15
    $p3 = Get-Random -Minimum 10 -Maximum 30
    $total = $p1 + $p2 + $p3
    $mttr = [math]::Round((Get-Random -Minimum 35 -Maximum 95) + (Get-Random -Minimum 0 -Maximum 100) / 100, 2)
    [pscustomobject]@{
        WeekStartDate = $d.ToString('yyyy-MM-dd')
        P1Incidents = $p1
        P2Incidents = $p2
        P3Incidents = $p3
        TotalIncidents = $total
        MTTRMinutes = $mttr
    }
}
$incidentRows | Export-Csv -Path (Join-Path $OutputPath 'incident-trends.csv') -NoTypeInformation

# change-success-rate.csv
$changeRows = foreach ($d in $weekStarts) {
    $scheduled = Get-Random -Minimum 8 -Maximum 18
    $rollbacks = Get-Random -Minimum 0 -Maximum 2
    $failed = Get-Random -Minimum 0 -Maximum 2
    $successful = [math]::Max(0, $scheduled - $rollbacks - $failed)
    $rate = if ($scheduled -eq 0) { 100 } else { [math]::Round(($successful / $scheduled) * 100, 2) }
    [pscustomobject]@{
        WeekStartDate = $d.ToString('yyyy-MM-dd')
        ScheduledChanges = $scheduled
        SuccessfulChanges = $successful
        RollbackChanges = $rollbacks
        FailedChanges = $failed
        ChangeSuccessRatePercent = $rate
    }
}
$changeRows | Export-Csv -Path (Join-Path $OutputPath 'change-success-rate.csv') -NoTypeInformation

# backup-sla-attainment.csv
$backupRows = foreach ($d in $weekStarts) {
    $jobs = Get-Random -Minimum 120 -Maximum 180
    $failed = Get-Random -Minimum 1 -Maximum 8
    $completed = [math]::Max(0, $jobs - $failed)
    $sla = [math]::Round(($completed / $jobs) * 100, 2)
    [pscustomobject]@{
        WeekStartDate = $d.ToString('yyyy-MM-dd')
        TotalBackupJobs = $jobs
        FailedBackupJobs = $failed
        CompletedBackupJobs = $completed
        BackupSLAAttainmentPercent = $sla
    }
}
$backupRows | Export-Csv -Path (Join-Path $OutputPath 'backup-sla-attainment.csv') -NoTypeInformation

# network-availability.csv
$campuses = @('Central-Office','High-School','Middle-School','Elementary-School')
$networkRows = foreach ($d in $weekStarts) {
    foreach ($campus in $campuses) {
        $avail = [math]::Round((Get-Random -Minimum 9950 -Maximum 10000) / 100, 2)
        $latency = [math]::Round((Get-Random -Minimum 8 -Maximum 22) + (Get-Random -Minimum 0 -Maximum 100) / 100, 2)
        $loss = [math]::Round((Get-Random -Minimum 0 -Maximum 80) / 100, 2)
        $outage = [math]::Round((100 - $avail) * 10, 2)
        [pscustomobject]@{
            WeekStartDate = $d.ToString('yyyy-MM-dd')
            Campus = $campus
            AvailabilityPercent = $avail
            AvgLatencyMs = $latency
            PacketLossPercent = $loss
            OutageMinutes = $outage
        }
    }
}
$networkRows | Export-Csv -Path (Join-Path $OutputPath 'network-availability.csv') -NoTypeInformation

Write-Host "Operational KPI data generated in: $OutputPath" -ForegroundColor Green
