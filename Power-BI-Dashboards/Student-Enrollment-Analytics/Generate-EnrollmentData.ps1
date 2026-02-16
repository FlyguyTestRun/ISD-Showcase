#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates synthetic student enrollment data for analytics dashboard

.DESCRIPTION
    Creates realistic CSV datasets for student enrollment trends, account provisioning
    velocity, and FERPA compliance metrics for K-12 identity management.

.EXAMPLE
    .\Generate-EnrollmentData.ps1
    Generates student enrollment sample data
#>

$OutputPath = "$PSScriptRoot/sample-data"

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "
=== Generating Student Enrollment Sample Data ===" -ForegroundColor Cyan

# Student Enrollment Trends
Write-Host "
[1/1] Generating enrollment trends data..." -ForegroundColor Yellow

$enrollmentData = @()
$startDate = (Get-Date).AddDays(-365)

# Base enrollment by grade
$baseEnrollment = @{
    9 = 625
    10 = 610
    11 = 595
    12 = 580
}

for ($i = 0; $i -lt 365; $i++) {
    $date = $startDate.AddDays($i)
    $month = $date.Month

    # Enrollment changes by season
    $seasonalFactor = if ($month -in 8,9) { 1.05 }  # New school year
                     elseif ($month -in 5,6) { 0.97 }  # End of year (graduations)
                     else { 1.0 }

    foreach ($grade in 9..12) {
        $base = $baseEnrollment[$grade]
        $enrolled = [Math]::Round($base * $seasonalFactor + (Get-Random -Minimum -15 -Maximum 15))

        # Provisioning activity
        $newAccounts = if ($month -in 8,9) { Get-Random -Minimum 3 -Maximum 12 }
                      elseif ($month -in 1) { Get-Random -Minimum 1 -Maximum 5 }
                      else { Get-Random -Minimum 0 -Maximum 3 }

        $deprovisioned = if ($month -in 5,6 -and $grade -eq 12) { Get-Random -Minimum 5 -Maximum 15 }
                        elseif ($month -in 12,1,6,7) { Get-Random -Minimum 1 -Maximum 4 }
                        else { Get-Random -Minimum 0 -Maximum 2 }

        $enrollmentData += [PSCustomObject]@{
            Date = $date.ToString("yyyy-MM-dd")
            GradeLevel = $grade
            GraduationYear = (Get-Date).Year + (12 - $grade) + 1
            TotalEnrolled = $enrolled
            NewAccountsCreated = $newAccounts
            AccountsDeprovisioned = $deprovisioned
            ActiveAccounts = $enrolled - (Get-Random -Minimum 0 -Maximum 5)
            PasswordResets = Get-Random -Minimum 0 -Maximum 8
            FERPAComplianceRate = Get-Random -Minimum 98 -Maximum 100
            AuditLogEntries = $newAccounts + $deprovisioned + (Get-Random -Minimum 5 -Maximum 25)
        }
    }
}

$enrollmentData | Export-Csv -Path "$OutputPath/student-enrollment-trends.csv" -NoTypeInformation
Write-Host "[OK] Created: student-enrollment-trends.csv (365 days, $($enrollmentData.Count) records)" -ForegroundColor Green

# Summary stats
$totalStudents = ($enrollmentData | Where-Object { $_.Date -eq (Get-Date).ToString("yyyy-MM-dd") } | Measure-Object -Property TotalEnrolled -Sum).Sum
$avgNewAccountsPerDay = [Math]::Round(($enrollmentData | Measure-Object -Property NewAccountsCreated -Average).Average, 1)

Write-Host "
=== Data Generation Complete ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputPath" -ForegroundColor White
Write-Host "
Summary Statistics:" -ForegroundColor White
Write-Host "  - Current Total Enrollment: $totalStudents students" -ForegroundColor Gray
Write-Host "  - Avg New Accounts/Day: $avgNewAccountsPerDay" -ForegroundColor Gray

Write-Host "
Files created:" -ForegroundColor White
Get-ChildItem -Path $OutputPath -Filter *.csv | ForEach-Object {
    $size = [Math]::Round($_.Length / 1KB, 2)
    Write-Host "  - $($_.Name) ($size KB)" -ForegroundColor Gray
}
