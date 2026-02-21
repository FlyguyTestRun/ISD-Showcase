#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates synthetic data for IT Infrastructure Health Dashboard

.DESCRIPTION
    Creates realistic CSV datasets for Active Directory health, Veeam backup status,
    and endpoint compliance metrics to demonstrate Power BI dashboard capabilities.
    Data is calibrated to a 34,000-student district scale: ~38,500 total accounts,
    23,000 Intune-managed Windows 11 devices.

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

# 1. Active Directory / Entra ID Health Metrics
# Scale: 34,000 students + 4,500 staff = ~38,500 total accounts
Write-Host ""
Write-Host "[1/3] Generating Active Directory health data..." -ForegroundColor Yellow

$adData = @()
$startDate = (Get-Date).AddDays(-90)

for ($i = 0; $i -lt 90; $i++) {
    $date = $startDate.AddDays($i)
    $adData += [PSCustomObject]@{
        Date                  = $date.ToString("yyyy-MM-dd")
        TotalUsers            = 38500 + (Get-Random -Minimum -200 -Maximum 200)
        ActiveUsers           = 37600 + (Get-Random -Minimum -150 -Maximum 150)
        DisabledUsers         = 900 + (Get-Random -Minimum -50 -Maximum 50)
        PasswordExpiring7Days = Get-Random -Minimum 500 -Maximum 800
        PasswordExpiring30Days = Get-Random -Minimum 2000 -Maximum 3000
        StaleAccounts90Days   = Get-Random -Minimum 150 -Maximum 350
        LockedAccounts        = Get-Random -Minimum 0 -Maximum 40
        ComputerObjects       = 23000 + (Get-Random -Minimum -100 -Maximum 100)
        StaleComputers90Days  = Get-Random -Minimum 100 -Maximum 230
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
            "*Staff*"    { 85 }
            "*SIS*"      { 120 }
            "*Exchange*" { 65 }
            "*Canvas*"   { 35 }
            "*DC*"       { 25 }
            "*Hyper-V*"  { 95 }
            default      { 20 }
        }

        $backupData += [PSCustomObject]@{
            Date        = $date.ToString("yyyy-MM-dd")
            JobName     = $job
            Status      = $status
            Duration    = Get-Random -Minimum 15 -Maximum 120
            DataSizeGB  = $baseSize + (Get-Random -Minimum -10 -Maximum 10)
            SuccessRate = if ($status -eq "Success") { 100 }
                         elseif ($status -eq "Warning") { Get-Random -Minimum 85 -Maximum 99 }
                         else { 0 }
        }
    }
}

$backupData | Export-Csv -Path "$OutputPath/backup-job-status.csv" -NoTypeInformation
Write-Host "[OK] Created: backup-job-status.csv (30 days, $($backupData.Count) records)" -ForegroundColor Green

# 3. Intune Endpoint Compliance Status
# Scale: 23,000 Windows 11 devices (Surface, grades 5-12 + staff)
Write-Host ""
Write-Host "[3/3] Generating endpoint compliance data..." -ForegroundColor Yellow

$complianceData = @()

for ($i = 0; $i -lt 90; $i++) {
    $date = $startDate.AddDays($i)
    $totalDevices = 23000

    $compliant    = [Math]::Round($totalDevices * (Get-Random -Minimum 0.88 -Maximum 0.94))
    $nonCompliant = [Math]::Round($totalDevices * (Get-Random -Minimum 0.04 -Maximum 0.08))
    $unknown      = $totalDevices - $compliant - $nonCompliant

    $complianceData += [PSCustomObject]@{
        Date                    = $date.ToString("yyyy-MM-dd")
        TotalDevices            = $totalDevices
        Compliant               = $compliant
        NonCompliant            = $nonCompliant
        Unknown                 = $unknown
        CompliancePercent       = [Math]::Round(($compliant / $totalDevices) * 100, 2)
        BitLockerEncrypted      = [Math]::Round($totalDevices * (Get-Random -Minimum 0.92 -Maximum 0.98))
        AntivirusUpToDate       = [Math]::Round($totalDevices * (Get-Random -Minimum 0.95 -Maximum 0.99))
        OSPatchCompliant        = [Math]::Round($totalDevices * (Get-Random -Minimum 0.85 -Maximum 0.93))
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
