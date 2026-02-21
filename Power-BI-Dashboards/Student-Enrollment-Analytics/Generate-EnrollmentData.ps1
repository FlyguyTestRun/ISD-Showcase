#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates synthetic student enrollment and identity analytics data

.DESCRIPTION
    Creates four CSV datasets for a professional K-12 enrollment analytics dashboard:
    1. student-enrollment-trends.csv   - Daily K-12 enrollment totals by grade
    2. campus-enrollment.csv           - Per-campus enrollment by grade band
    3. account-provisioning.csv        - Daily provisioning velocity and SLA metrics
    4. device-assignment.csv           - Autopilot device assignment by campus/grade band

    Data is calibrated to a 34,000-student K-12 district:
    ~2,200-2,400 per elementary grade (24 campuses), ~2,600-2,700 per middle grade (7 campuses),
    ~2,450-2,580 per high school grade (4 campuses).

    IMPORTANT: GradeSort (0-12 integer) is the sort key. GradeLabel is the display string.
    Use GradeSort for all numeric operations and sorting in Power BI. Relate GradeLabel
    to GradeSort via the Grades dimension table in the data model.

.EXAMPLE
    .\Generate-EnrollmentData.ps1
    Generates all four sample data files in the sample-data folder
#>

$OutputPath = "$PSScriptRoot/sample-data"

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host ""
Write-Host "=== Generating Student Enrollment Analytics Data ===" -ForegroundColor Cyan

# ------------------------------------------------------------------
# Grade reference table
# GradeSort: 0 = Kindergarten, 1-12 = grades 1-12
# All Power BI sorting and numeric ops should use GradeSort
# ------------------------------------------------------------------
$gradeRef = @(
    @{Sort=0;  Label="K";  Band="Elementary"; BasePop=2200}
    @{Sort=1;  Label="1";  Band="Elementary"; BasePop=2350}
    @{Sort=2;  Label="2";  Band="Elementary"; BasePop=2400}
    @{Sort=3;  Label="3";  Band="Elementary"; BasePop=2380}
    @{Sort=4;  Label="4";  Band="Elementary"; BasePop=2360}
    @{Sort=5;  Label="5";  Band="Elementary"; BasePop=2320}
    @{Sort=6;  Label="6";  Band="Middle";     BasePop=2650}
    @{Sort=7;  Label="7";  Band="Middle";     BasePop=2630}
    @{Sort=8;  Label="8";  Band="Middle";     BasePop=2600}
    @{Sort=9;  Label="9";  Band="High School"; BasePop=2580}
    @{Sort=10; Label="10"; Band="High School"; BasePop=2540}
    @{Sort=11; Label="11"; Band="High School"; BasePop=2500}
    @{Sort=12; Label="12"; Band="High School"; BasePop=2450}
)

# Campus reference
$campuses = @(
    @{Name="Keller HS";          Band="High School"; Capacity=2800}
    @{Name="Timber Creek HS";    Band="High School"; Capacity=2700}
    @{Name="Central HS";         Band="High School"; Capacity=2600}
    @{Name="Foster HS";          Band="High School"; Capacity=2500}
    @{Name="Indian Springs MS";  Band="Middle";      Capacity=1200}
    @{Name="Hillwood MS";        Band="Middle";      Capacity=1150}
    @{Name="Trinity Springs MS"; Band="Middle";      Capacity=1100}
    @{Name="Bear Creek MS";      Band="Middle";      Capacity=1050}
    @{Name="Timberview MS";      Band="Middle";      Capacity=1000}
    @{Name="Ridgeview MS";       Band="Middle";      Capacity=980}
    @{Name="Shady Grove Elem";   Band="Elementary";  Capacity=800}
    @{Name="Parkwood Elem";      Band="Elementary";  Capacity=780}
    @{Name="Willowbrook Elem";   Band="Elementary";  Capacity=760}
    @{Name="Willis Lane Elem";   Band="Elementary";  Capacity=750}
    @{Name="Florence Elem";      Band="Elementary";  Capacity=740}
    @{Name="Basswood Elem";      Band="Elementary";  Capacity=730}
    @{Name="Parkview Elem";      Band="Elementary";  Capacity=720}
    @{Name="Liberty Elem";       Band="Elementary";  Capacity=710}
    @{Name="North Star Elem";    Band="Elementary";  Capacity=700}
    @{Name="Ridgeview Elem";     Band="Elementary";  Capacity=690}
    @{Name="Hidden Lakes Elem";  Band="Elementary";  Capacity=680}
    @{Name="Bluebonnet Elem";    Band="Elementary";  Capacity=670}
)

$startDate = (Get-Date).AddDays(-365)

# ------------------------------------------------------------------
# 1. STUDENT ENROLLMENT TRENDS  (daily, by grade)
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[1/4] Generating student enrollment trends by grade..." -ForegroundColor Yellow

$enrollmentData = @()

for ($i = 0; $i -lt 365; $i++) {
    $date  = $startDate.AddDays($i)
    $month = $date.Month

    $seasonalFactor = if ($month -in 8, 9) { 1.05 }
                     elseif ($month -in 5, 6) { 0.97 }
                     else { 1.0 }

    foreach ($g in $gradeRef) {
        $enrolled = [Math]::Round($g.BasePop * $seasonalFactor + (Get-Random -Minimum -20 -Maximum 20))
        $isHS = $g.Band -eq "High School"
        $isMS = $g.Band -eq "Middle"

        $newAccounts = if ($month -in 8, 9) {
            if ($isHS) { Get-Random -Minimum 40 -Maximum 80 }
            elseif ($isMS) { Get-Random -Minimum 30 -Maximum 60 }
            else { Get-Random -Minimum 20 -Maximum 45 }
        } elseif ($month -eq 1) {
            Get-Random -Minimum 3 -Maximum 15
        } else {
            Get-Random -Minimum 0 -Maximum 6
        }

        $deprovisioned = if ($month -in 5, 6 -and $g.Sort -eq 12) {
            Get-Random -Minimum 80 -Maximum 200
        } elseif ($month -in 12, 1, 6, 7) {
            Get-Random -Minimum 1 -Maximum 6
        } else {
            Get-Random -Minimum 0 -Maximum 3
        }

        $gradYear = if ($g.Sort -ge 9) { (Get-Date).Year + (12 - $g.Sort) + 1 } else { $null }

        $enrollmentData += [PSCustomObject]@{
            Date                  = $date.ToString("yyyy-MM-dd")
            GradeSort             = $g.Sort
            GradeLabel            = $g.Label
            GradeBand             = $g.Band
            GraduationYear        = $gradYear
            TotalEnrolled         = $enrolled
            NewAccountsCreated    = $newAccounts
            AccountsDeprovisioned = $deprovisioned
            ActiveAccounts        = $enrolled - (Get-Random -Minimum 0 -Maximum 5)
            PasswordResets        = Get-Random -Minimum 0 -Maximum 12
            FERPAComplianceRate   = [Math]::Round(98 + (Get-Random -Minimum 0 -Maximum 200) / 100, 2)
            AuditLogEntries       = $newAccounts + $deprovisioned + (Get-Random -Minimum 5 -Maximum 30)
        }
    }
}

$enrollmentData | Export-Csv -Path "$OutputPath/student-enrollment-trends.csv" -NoTypeInformation
Write-Host "[OK] student-enrollment-trends.csv ($($enrollmentData.Count) records, 365 days x 13 grades)" -ForegroundColor Green

# ------------------------------------------------------------------
# 2. CAMPUS ENROLLMENT  (weekly, by campus + grade band)
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[2/4] Generating campus enrollment data..." -ForegroundColor Yellow

$campusData = @()
$campusStartDate = (Get-Date).AddDays(-365)

# Generate weekly snapshots
for ($week = 0; $week -lt 52; $week++) {
    $date      = $campusStartDate.AddDays($week * 7)
    $month     = $date.Month
    $schoolWeek = $month -notin @(6, 7)  # June/July = summer

    $seasonalFactor = if ($month -in 8, 9) { 1.04 }
                     elseif ($month -in 5, 6) { 0.96 }
                     elseif (-not $schoolWeek) { 0.85 }
                     else { 1.0 }

    foreach ($campus in $campuses) {
        $baseEnrolled = [Math]::Round($campus.Capacity * 0.88 * $seasonalFactor + (Get-Random -Minimum -30 -Maximum 30))
        $utilPct      = [Math]::Round(($baseEnrolled / $campus.Capacity) * 100, 1)

        $campusData += [PSCustomObject]@{
            WeekStartDate      = $date.ToString("yyyy-MM-dd")
            Campus             = $campus.Name
            GradeBand          = $campus.Band
            Capacity           = $campus.Capacity
            TotalEnrolled      = [Math]::Max(0, $baseEnrolled)
            CapacityUtilPct    = [Math]::Min(100, [Math]::Max(0, $utilPct))
            NewTransfersIn     = if ($month -in 8, 9) { Get-Random -Minimum 5 -Maximum 25 } else { Get-Random -Minimum 0 -Maximum 5 }
            TransfersOut       = if ($month -in 5, 6) { Get-Random -Minimum 3 -Maximum 15 } else { Get-Random -Minimum 0 -Maximum 3 }
            ActiveAccountsPct  = [Math]::Round(97 + (Get-Random -Minimum 0 -Maximum 300) / 100, 1)
        }
    }
}

$campusData | Export-Csv -Path "$OutputPath/campus-enrollment.csv" -NoTypeInformation
Write-Host "[OK] campus-enrollment.csv ($($campusData.Count) records, 52 weeks x 22 campuses)" -ForegroundColor Green

# ------------------------------------------------------------------
# 3. ACCOUNT PROVISIONING SLA  (daily)
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] Generating account provisioning SLA data..." -ForegroundColor Yellow

$provisioningData = @()

for ($i = 0; $i -lt 365; $i++) {
    $date  = $startDate.AddDays($i)
    $month = $date.Month
    $dow   = [int]$date.DayOfWeek  # 0=Sunday, 6=Saturday

    $isWeekday = $dow -ge 1 -and $dow -le 5
    $isAugust  = $month -in 8, 9
    $isSummer  = $month -in 6, 7

    # Provisioning volume scales with school calendar
    $newStudentAccounts = if ($isAugust -and $isWeekday) {
        Get-Random -Minimum 200 -Maximum 600    # August surge: batch SIS imports
    } elseif ($month -eq 1 -and $isWeekday) {
        Get-Random -Minimum 30 -Maximum 90      # January transfers
    } elseif ($isSummer) {
        Get-Random -Minimum 5 -Maximum 20       # Summer maintenance
    } elseif ($isWeekday) {
        Get-Random -Minimum 5 -Maximum 40
    } else { 0 }

    $newStaffAccounts = if ($isAugust -and $isWeekday) {
        Get-Random -Minimum 10 -Maximum 35
    } elseif ($isWeekday) {
        Get-Random -Minimum 0 -Maximum 8
    } else { 0 }

    $disabledAccounts = if ($month -in 5, 6 -and $isWeekday) {
        Get-Random -Minimum 80 -Maximum 250     # Graduation processing
    } elseif ($isWeekday) {
        Get-Random -Minimum 0 -Maximum 15
    } else { 0 }

    # Provisioning time in minutes (under load during August)
    $avgProvTimeMins = if ($isAugust) {
        Get-Random -Minimum 8 -Maximum 25       # Slower under batch load
    } else {
        Get-Random -Minimum 2 -Maximum 8        # Normal: near-instant
    }

    $totalActivity = $newStudentAccounts + $newStaffAccounts + $disabledAccounts

    $provisioningData += [PSCustomObject]@{
        Date                    = $date.ToString("yyyy-MM-dd")
        DayOfWeek               = $date.ToString("ddd")
        Month                   = $date.ToString("MMM")
        NewStudentAccounts      = $newStudentAccounts
        NewStaffAccounts        = $newStaffAccounts
        AccountsDisabled        = $disabledAccounts
        TotalProvisioningEvents = $totalActivity
        AvgProvisioningTimeMins = $avgProvTimeMins
        SLAMet                  = if ($avgProvTimeMins -le 15) { "Yes" } else { "No" }
        PasswordResetsTotal     = if ($isWeekday) { Get-Random -Minimum 20 -Maximum 150 } else { 0 }
        SISExportErrors         = if ($isAugust -and $isWeekday) { Get-Random -Minimum 0 -Maximum 8 } else { 0 }
        AuditLogCompletePct     = [Math]::Round(98.5 + (Get-Random -Minimum 0 -Maximum 150) / 100, 2)
    }
}

$provisioningData | Export-Csv -Path "$OutputPath/account-provisioning.csv" -NoTypeInformation
Write-Host "[OK] account-provisioning.csv ($($provisioningData.Count) records, 365 days)" -ForegroundColor Green

# ------------------------------------------------------------------
# 4. DEVICE ASSIGNMENT (AUTOPILOT)  (weekly, by campus)
# ------------------------------------------------------------------
Write-Host ""
Write-Host "[4/4] Generating Autopilot device assignment data..." -ForegroundColor Yellow

$deviceData = @()
$deviceStartDate = (Get-Date).AddDays(-365)

# Device assignment only applies to grades 5-12 (Autopilot fleet)
$deviceCampuses = $campuses | Where-Object { $_.Band -in @("Middle", "High School") }
# Also include grade 5 elementary
$grade5Campuses = $campuses | Where-Object { $_.Band -eq "Elementary" } | Select-Object -First 8

$allDeviceCampuses = @($deviceCampuses) + @($grade5Campuses)

for ($week = 0; $week -lt 52; $week++) {
    $date  = $deviceStartDate.AddDays($week * 7)
    $month = $date.Month
    $isAugust = $month -in 8, 9

    foreach ($campus in $allDeviceCampuses) {
        # Fleet size estimate based on campus band
        $fleetSize = switch ($campus.Band) {
            "High School" { [Math]::Round($campus.Capacity * 0.95) }   # ~95% HS have devices
            "Middle"      { [Math]::Round($campus.Capacity * 0.90) }   # ~90% MS have devices
            "Elementary"  { [Math]::Round($campus.Capacity * 0.15) }   # Grade 5 only
            default       { 0 }
        }

        $assignedPct = if ($isAugust) {
            Get-Random -Minimum 85 -Maximum 96    # August: new devices being assigned
        } else {
            Get-Random -Minimum 95 -Maximum 99    # Normal ops: near-complete
        }

        $assigned   = [Math]::Round($fleetSize * ($assignedPct / 100))
        $pending    = [Math]::Round($fleetSize * (Get-Random -Minimum 1 -Maximum 4) / 100)
        $unassigned = $fleetSize - $assigned - $pending

        $autopilotSuccess = if ($isAugust) {
            Get-Random -Minimum 92 -Maximum 98
        } else {
            Get-Random -Minimum 97 -Maximum 100
        }

        $deviceData += [PSCustomObject]@{
            WeekStartDate            = $date.ToString("yyyy-MM-dd")
            Campus                   = $campus.Name
            GradeBand                = $campus.Band
            FleetSize                = $fleetSize
            DevicesAssigned          = [Math]::Max(0, $assigned)
            DevicesPendingAssignment = [Math]::Max(0, $pending)
            DevicesUnassigned        = [Math]::Max(0, $unassigned)
            AssignmentCompletePct    = $assignedPct
            AutopilotSuccessRatePct  = $autopilotSuccess
            DevicesNotSeenIn7Days    = [Math]::Round($fleetSize * (Get-Random -Minimum 1 -Maximum 5) / 100)
            DevicesNotSeenIn30Days   = [Math]::Round($fleetSize * (Get-Random -Minimum 1 -Maximum 2) / 100)
        }
    }
}

$deviceData | Export-Csv -Path "$OutputPath/device-assignment.csv" -NoTypeInformation
Write-Host "[OK] device-assignment.csv ($($deviceData.Count) records, 52 weeks x $(($allDeviceCampuses).Count) campuses)" -ForegroundColor Green

# ------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------
Write-Host ""
Write-Host "=== Data Generation Complete ===" -ForegroundColor Cyan
Write-Host "Output Directory: $OutputPath" -ForegroundColor White
Write-Host ""

# Enrollment total sanity check
$latestDate = ($enrollmentData | Sort-Object Date | Select-Object -Last 13)
$totalEnroll = ($latestDate | Measure-Object -Property TotalEnrolled -Sum).Sum
Write-Host "District enrollment (latest day, all grades): $totalEnroll students" -ForegroundColor White
Write-Host ""

Write-Host "Files created:" -ForegroundColor White
Get-ChildItem -Path $OutputPath -Filter *.csv | ForEach-Object {
    $size = [Math]::Round($_.Length / 1KB, 2)
    Write-Host "  - $($_.Name) ($size KB)" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Power BI data model note:" -ForegroundColor Yellow
Write-Host "  Use GradeSort (0-12 integer) for sorting and numeric operations." -ForegroundColor Gray
Write-Host "  Use GradeLabel ('K','1'...'12') for display." -ForegroundColor Gray
Write-Host "  Relate all tables on Date column. Campus is a shared dimension." -ForegroundColor Gray
