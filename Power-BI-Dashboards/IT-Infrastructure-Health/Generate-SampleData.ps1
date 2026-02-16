#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates synthetic data for IT Infrastructure Health Dashboard

.DESCRIPTION
    Creates realistic CSV datasets for Active Directory health, Veeam backup status,
    and endpoint compliance metrics to demonstrate Power BI dashboard capabilities.

.EXAMPLE
    .\Generate-SampleData.ps1
    Generates all sample data files in the sample-data folder
#>

$OutputPath = "$PSScriptRoot/sample-data"

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host ""
Write-Host "=== Generating IT Infrastructure Sample Data ===" -ForegroundColor Cyan

# 1. Active Directory Health Metrics
Write-Host ""
Write-Host "[1/3] Generating Active Directory health data..." -ForegroundColor Yellow

$adData = @()
$startDate = (Get-Date).AddDays(-90)

for ($i = 0; $i -lt 90; $i++) {
    $date = $startDate.AddDays($i)
    $adData += [PSCustomObject]@{
        Date = $date.ToString("yyyy-MM-dd")
        TotalUsers = 2450 + (Get-Random -Minimum -50 -Maximum 50)
        ActiveUsers = 2380 + (Get-Random -Minimum -30 -Maximum 30)
        DisabledUsers = 70 + (Get-Random -Minimum -10 -Maximum 10)
        PasswordExpiring7Days = Get-Random -Minimum 15 -Maximum 45
        PasswordExpiring30Days = Get-Random -Minimum 120 -Maximum 180
        StaleAccounts90Days = Get-Random -Minimum 25 -Maximum 55
        LockedAccounts = Get-Random -Minimum 0 -Maximum 8
        ComputerObjects = 1850 + (Get-Random -Minimum -20 -Maximum 20)
        StaleComputers90Days = Get-Random -Minimum 45 -Maximum 85
    }
}

$adData | Export-Csv -Path "$OutputPath/active-directory-health.csv" -NoTypeInformation
Write-Host "[OK] Created: active-directory-health.csv (90 days, $($adData.Count) records)" -ForegroundColor Green

# 2. Veeam Backup Job Status
Write-Host ""
Write-Host "[2/3] Generating Veeam backup job data..." -ForegroundColor Yellow

$backupJobs = @(
    "SIS-Database-Daily", "FileServer-Staff-Daily", "FileServer-Students-Daily",
    "DomainControllers-Daily", "Exchange-Online-Archive", "Canvas-LMS-Backup",
    "Hyper-V-Hosts-Daily", "PrintServer-Daily"
)

$backupData = @()

for ($i = 0; $i -lt 30; $i++) {
    $date = (Get-Date).AddDays(-$i)

    foreach ($job in $backupJobs) {
        # Success rate: 95% success, 4% warning, 1% failure
        $rand = Get-Random -Minimum 1 -Maximum 100
        $status = if ($rand -le 95) { "Success" }
                  elseif ($rand -le 99) { "Warning" }
                  else { "Failed" }

        $baseSize = switch -Wildcard ($job) {
            "*Students*" { 150 }
            "*Staff*" { 85 }
            "*SIS*" { 120 }
            "*Exchange*" { 65 }
            "*Canvas*" { 35 }
            "*DC*" { 25 }
            "*Hyper-V*" { 95 }
            default { 20 }
        }

        $backupData += [PSCustomObject]@{
            Date = $date.ToString("yyyy-MM-dd")
            JobName = $job
            Status = $status
            Duration = Get-Random -Minimum 15 -Maximum 120
            DataSizeGB = $baseSize + (Get-Random -Minimum -10 -Maximum 10)
            SuccessRate = if ($status -eq "Success") { 100 }
                         elseif ($status -eq "Warning") { Get-Random -Minimum 85 -Maximum 99 }
                         else { 0 }
        }
    }
}

$backupData | Export-Csv -Path "$OutputPath/backup-job-status.csv" -NoTypeInformation
Write-Host "[OK] Created: backup-job-status.csv (30 days, $($backupData.Count) records)" -ForegroundColor Green

# 3. Endpoint Compliance Status
Write-Host ""
Write-Host "[3/3] Generating endpoint compliance data..." -ForegroundColor Yellow

$complianceData = @()

for ($i = 0; $i -lt 90; $i++) {
    $date = $startDate.AddDays($i)
    $totalDevices = 1850

    $compliant = [Math]::Round($totalDevices * (Get-Random -Minimum 0.88 -Maximum 0.94))
    $nonCompliant = [Math]::Round($totalDevices * (Get-Random -Minimum 0.04 -Maximum 0.08))
    $unknown = $totalDevices - $compliant - $nonCompliant

    $complianceData += [PSCustomObject]@{
        Date = $date.ToString("yyyy-MM-dd")
        TotalDevices = $totalDevices
        Compliant = $compliant
        NonCompliant = $nonCompliant
        Unknown = $unknown
        CompliancePercent = [Math]::Round(($compliant / $totalDevices) * 100, 2)
        BitLockerEncrypted = [Math]::Round($totalDevices * (Get-Random -Minimum 0.92 -Maximum 0.98))
        AntivirusUpToDate = [Math]::Round($totalDevices * (Get-Random -Minimum 0.95 -Maximum 0.99))
        OSPatchCompliant = [Math]::Round($totalDevices * (Get-Random -Minimum 0.85 -Maximum 0.93))
        PasswordPolicyCompliant = [Math]::Round($totalDevices * (Get-Random -Minimum 0.96 -Maximum 0.99))
    }
}

$complianceData | Export-Csv -Path "$OutputPath/endpoint-compliance.csv" -NoTypeInformation
Write-Host "[OK] Created: endpoint-compliance.csv (90 days, $($complianceData.Count) records)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Data Generation Complete ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputPath" -ForegroundColor White
Write-Host ""
Write-Host "Files created:" -ForegroundColor White
Get-ChildItem -Path $OutputPath -Filter *.csv | ForEach-Object {
    $size = [Math]::Round($_.Length / 1KB, 2)
    Write-Host "  - $($_.Name) - $size KB" -ForegroundColor Gray
}
