#!/usr/bin/env pwsh
# Check Autopilot device provisioning status for recent enrollments.

param(
    [switch]$DemoMode,
    [string]$ExportPath
)

function Get-DemoAutopilotStatus {
    @(
        [pscustomobject]@{ DeviceName='KISD-LT-23841'; SerialNumber='ABC123'; Profile='KISD-Student-Win11'; ProvisioningStatus='Success'; EnrollmentDate=(Get-Date).AddDays(-1); AccountLinked=$true }
        [pscustomobject]@{ DeviceName='KISD-LT-23842'; SerialNumber='ABC124'; Profile='KISD-Student-Win11'; ProvisioningStatus='Failed'; EnrollmentDate=(Get-Date).AddDays(-1); AccountLinked=$false }
        [pscustomobject]@{ DeviceName='KISD-LT-23843'; SerialNumber='ABC125'; Profile='KISD-Staff-Win11'; ProvisioningStatus='Success'; EnrollmentDate=(Get-Date).AddDays(-2); AccountLinked=$true }
        [pscustomobject]@{ DeviceName='KISD-LT-23844'; SerialNumber='ABC126'; Profile=''; ProvisioningStatus='ProfilePending'; EnrollmentDate=(Get-Date).AddHours(-4); AccountLinked=$false }
        [pscustomobject]@{ DeviceName='KISD-LT-23845'; SerialNumber='ABC127'; Profile='KISD-Student-Win11'; ProvisioningStatus='InProgress'; EnrollmentDate=(Get-Date).AddHours(-1); AccountLinked=$true }
    )
}

if ($DemoMode) {
    $devices = Get-DemoAutopilotStatus
} else {
    # Expected Graph scopes: DeviceManagementManagedDevices.Read.All, Device.Read.All
    # Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","Device.Read.All"
    # $devices = Get-MgDeviceManagementManagedDevice -All -Filter "enrollmentProfileName ne null" | ...
    throw "Non-demo mode requires Microsoft Graph connection and tenant access. Use -DemoMode for safe demonstration."
}

$summary = $devices |
    Group-Object ProvisioningStatus |
    ForEach-Object {
        [pscustomobject]@{
            ProvisioningStatus = $_.Name
            DeviceCount        = $_.Count
        }
    }

$failedOrPending = $devices | Where-Object { $_.ProvisioningStatus -in @('Failed', 'ProfilePending') }
$unlinked        = $devices | Where-Object { -not $_.AccountLinked }

$summary

if ($failedOrPending) {
    Write-Host "`nDevices requiring attention:" -ForegroundColor Yellow
    $failedOrPending | Format-Table DeviceName, SerialNumber, ProvisioningStatus, EnrollmentDate -AutoSize
}

if ($ExportPath) {
    $devices | Export-Csv -Path $ExportPath -NoTypeInformation
    Write-Host "Exported Autopilot status to $ExportPath" -ForegroundColor Green
}
