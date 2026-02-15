#!/usr/bin/env pwsh
# Batch student account creation from CSV

param(
    [Parameter(Mandatory)]
    [string]$CsvPath
)

Import-Module "$PSScriptRoot/../modules/KISDIdentity.psm1" -Force

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    exit 1
}

$students = Import-Csv $CsvPath
$results = @{
    Success = 0
    Failed = 0
    Accounts = @()
}

foreach ($student in $students) {
    try {
        $account = New-KISDStudentAccount `
            -StudentID $student.StudentID `
            -FirstName $student.FirstName `
            -LastName $student.LastName `
            -GradeLevel $student.GradeLevel `
            -GraduationYear $student.GraduationYear

        $results.Accounts += $account
        $results.Success++
    }
    catch {
        Write-Warning "Failed to create account for $($student.FirstName) $($student.LastName): $_"
        $results.Failed++
    }
}

Write-Host "`n=== Batch Processing Complete ===" -ForegroundColor Cyan
Write-Host "✓ Success: $($results.Success)" -ForegroundColor Green
Write-Host "✗ Failed: $($results.Failed)" -ForegroundColor Red

return $results
