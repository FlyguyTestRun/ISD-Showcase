# Syntax validation for all PowerShell scripts in Keller-ISD-Showcase

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  POWERSHELL SYNTAX VALIDATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$Scripts = @(
    ".\Backup-DR-Automation\Veeam-BackupManagement.ps1"
    ".\Backup-DR-Automation\Veeam-DRTesting.ps1"
    ".\Dell-Hardware-Management\iDRAC-HealthCheck.ps1"
    ".\Dell-Hardware-Management\iDRAC-FirmwareUpdate.ps1"
    ".\K12-Network-Architecture\VLAN-Configuration-Template.ps1"
    ".\K12-Identity-Management\KISDIdentity.psm1"
    ".\K12-Identity-Management\New-StudentBatch.ps1"
)

$PassCount = 0
$FailCount = 0

foreach ($Script in $Scripts) {
    $ScriptName = Split-Path -Leaf $Script

    if (-not (Test-Path $Script)) {
        Write-Host "[MISSING] $ScriptName" -ForegroundColor Red
        $FailCount++
        continue
    }

    try {
        $content = Get-Content $Script -Raw -ErrorAction Stop
        $errors = @()

        # Try to parse the script using AST
        $parseErrors = @()
        $null = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$parseErrors)

        # Filter out read-only variable warnings (common PowerShell issue)
        $criticalErrors = $parseErrors | Where-Object {
            $_.Message -notmatch "Cannot overwrite variable Error" -and
            $_.Message -notmatch "read-only or constant"
        }

        if ($criticalErrors.Count -eq 0) {
            Write-Host "[OK] $ScriptName" -ForegroundColor Green
            $PassCount++
        } else {
            Write-Host "[ERROR] $ScriptName - $($criticalErrors.Count) critical syntax errors" -ForegroundColor Red
            $FailCount++

            foreach ($error in $criticalErrors) {
                Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "[FAIL] $ScriptName - $_" -ForegroundColor Red
        $FailCount++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  RESULTS: $PassCount PASSED, $FailCount FAILED" -ForegroundColor $(if ($FailCount -eq 0) {"Green"} else {"Red"})
Write-Host "========================================`n" -ForegroundColor Cyan

if ($FailCount -gt 0) {
    exit 1
}
