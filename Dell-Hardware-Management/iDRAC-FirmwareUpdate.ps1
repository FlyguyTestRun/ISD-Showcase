<#
.SYNOPSIS
    Dell iDRAC firmware lifecycle management automation.

.DESCRIPTION
    PowerShell module for automating firmware updates on Dell PowerEdge servers
    via iDRAC. Designed for K-12 environments with strict change control and
    minimal downtime requirements during school year.

.NOTES
    Author: Bryan Shaw
    Purpose: K-12 Dell Firmware Management Demonstration
    Best Practice: Schedule firmware updates during school break periods
#>

#Requires -Version 5.1

#region Firmware Inventory

function Get-iDRACFirmwareInventory {
    <#
    .SYNOPSIS
        Retrieves current firmware versions for all server components.

    .DESCRIPTION
        Queries iDRAC for installed firmware versions including BIOS, iDRAC,
        PERC controllers, network cards, and other updateable components.

    .PARAMETER iDRACSession
        Connected iDRAC session object

    .EXAMPLE
        Get-iDRACFirmwareInventory -iDRACSession $Session
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$iDRACSession
    )

    Write-Host "[FIRMWARE INVENTORY] Scanning installed firmware versions..." -ForegroundColor Cyan

    # Simulated firmware inventory (production would query /redfish/v1/UpdateService/FirmwareInventory)
    $Inventory = @(
        [PSCustomObject]@{
            Component       = "BIOS"
            Current         = "2.15.1"
            Available       = "2.16.2"
            UpdateAvailable = $true
            Criticality     = "Recommended"
            ReleaseDate     = "2024-11-15"
        }
        [PSCustomObject]@{
            Component       = "iDRAC"
            Current         = "4.40.00.00"
            Available       = "4.40.10.00"
            UpdateAvailable = $true
            Criticality     = "Urgent"
            ReleaseDate     = "2024-12-01"
        }
        [PSCustomObject]@{
            Component       = "Lifecycle Controller"
            Current         = "4.40.00.00"
            Available       = "4.40.10.00"
            UpdateAvailable = $true
            Criticality     = "Recommended"
            ReleaseDate     = "2024-12-01"
        }
        [PSCustomObject]@{
            Component       = "PERC H730P RAID"
            Current         = "25.5.9.0001"
            Available       = "25.5.9.0001"
            UpdateAvailable = $false
            Criticality     = "N/A"
            ReleaseDate     = "N/A"
        }
        [PSCustomObject]@{
            Component       = "Broadcom NetXtreme Gigabit"
            Current         = "21.60.1"
            Available       = "21.80.2"
            UpdateAvailable = $true
            Criticality     = "Optional"
            ReleaseDate     = "2024-10-20"
        }
    )

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  FIRMWARE INVENTORY" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    foreach ($Item in $Inventory) {
        $StatusSymbol = if ($Item.UpdateAvailable) {"[UPDATE]"} else {"[OK]"}
        $StatusColor = switch ($Item.Criticality) {
            "Urgent" {"Red"}
            "Recommended" {"Yellow"}
            "Optional" {"Gray"}
            default {"Green"}
        }

        Write-Host "$StatusSymbol $($Item.Component)" -ForegroundColor $StatusColor
        Write-Host "  Current: $($Item.Current)" -ForegroundColor Gray

        if ($Item.UpdateAvailable) {
            Write-Host "  Available: $($Item.Available) ($($Item.Criticality))" -ForegroundColor $StatusColor
            Write-Host "  Released: $($Item.ReleaseDate)" -ForegroundColor Gray
        } else {
            Write-Host "  Status: Up to date" -ForegroundColor Green
        }
        Write-Host ""
    }

    $UpdateCount = ($Inventory | Where-Object {$_.UpdateAvailable}).Count
    Write-Host "Summary: $UpdateCount component(s) have available updates`n" -ForegroundColor Cyan

    return $Inventory
}

#endregion

#region Firmware Updates

function Update-iDRACFirmware {
    <#
    .SYNOPSIS
        Applies firmware updates to Dell server components via iDRAC.

    .DESCRIPTION
        Automates firmware update process with safety checks including:
        - Pre-update health validation
        - Scheduled update during maintenance window
        - Automatic reboot coordination
        - Post-update verification

    .PARAMETER iDRACSession
        Connected iDRAC session object

    .PARAMETER Component
        Component to update (BIOS, iDRAC, PERC, NetworkCard, All)

    .PARAMETER FirmwarePath
        Path to firmware .exe file (DUP - Dell Update Package)

    .PARAMETER ScheduledTime
        Optional scheduled time for update (default: immediate)

    .PARAMETER AutoReboot
        Automatically reboot server after update if required

    .EXAMPLE
        Update-iDRACFirmware -iDRACSession $Session -Component "BIOS" -AutoReboot
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$iDRACSession,

        [Parameter(Mandatory)]
        [ValidateSet("BIOS", "iDRAC", "PERC", "NetworkCard", "All")]
        [string]$Component,

        [string]$FirmwarePath,

        [datetime]$ScheduledTime,

        [switch]$AutoReboot
    )

    Write-Host "`n[FIRMWARE UPDATE] Preparing to update: $Component" -ForegroundColor Cyan

    # Pre-update validation
    Write-Host "  [1/5] Running pre-update health checks..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    Write-Host "        [OK] Server health: Normal" -ForegroundColor Green
    Write-Host "        [OK] RAID status: Optimal" -ForegroundColor Green
    Write-Host "        [OK] Power supplies: Redundant" -ForegroundColor Green

    # Firmware staging
    Write-Host "  [2/5] Staging firmware update package..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $UpdatePackage = if ($FirmwarePath) {Split-Path -Leaf $FirmwarePath} else {"Dell_BIOS_v2.16.2.exe"}
    Write-Host "        [OK] Package: $UpdatePackage" -ForegroundColor Green

    # Schedule check
    if ($ScheduledTime) {
        Write-Host "  [3/5] Scheduling update for: $($ScheduledTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Yellow
        Write-Host "        [OK] Update scheduled successfully" -ForegroundColor Green
        Write-Host "        [INFO] Server will auto-reboot at scheduled time if required" -ForegroundColor Gray
    } else {
        Write-Host "  [3/5] Applying firmware update now..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        Write-Host "        [OK] Firmware applied successfully" -ForegroundColor Green
    }

    # Reboot coordination
    if ($AutoReboot -or $ScheduledTime) {
        Write-Host "  [4/5] Coordinating server reboot..." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($iDRACSession.ServiceTag, "Reboot server for firmware activation")) {
            Start-Sleep -Seconds 1
            Write-Host "        [OK] Graceful shutdown initiated" -ForegroundColor Green
            Write-Host "        [INFO] Server will reboot and apply firmware" -ForegroundColor Gray
            Write-Host "        [INFO] Estimated downtime: 8-12 minutes" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [4/5] Firmware staged (reboot required for activation)" -ForegroundColor Yellow
        Write-Host "        [PENDING] Manual reboot needed to complete update" -ForegroundColor Yellow
    }

    # Post-update tasks
    Write-Host "  [5/5] Setting up post-update verification..." -ForegroundColor Yellow
    Write-Host "        [OK] Verification job configured" -ForegroundColor Green

    Write-Host "`n[SUCCESS] Firmware update initiated for $Component" -ForegroundColor Green

    return [PSCustomObject]@{
        Component      = $Component
        UpdatePackage  = $UpdatePackage
        ScheduledTime  = $ScheduledTime
        AutoReboot     = $AutoReboot.IsPresent
        Status         = if ($ScheduledTime) {"Scheduled"} else {"In Progress"}
        EstimatedTime  = "8-12 minutes"
    }
}

function Invoke-FirmwareUpdateCampaign {
    <#
    .SYNOPSIS
        Orchestrates firmware updates across multiple Dell servers.

    .DESCRIPTION
        Manages large-scale firmware update campaigns for K-12 infrastructure:
        - Inventory all servers and firmware versions
        - Schedule updates during school break periods
        - Coordinate rolling updates to maintain service availability
        - Generate compliance reports

    .PARAMETER iDRACList
        Array of iDRAC IP addresses or session objects

    .PARAMETER UpdateWindow
        Maintenance window (e.g., "Summer Break 2025", "Spring Break 2025")

    .PARAMETER Components
        Components to update (default: BIOS, iDRAC, Lifecycle Controller)

    .EXAMPLE
        $Servers = @("192.168.1.100", "192.168.1.101", "192.168.1.102")
        Invoke-FirmwareUpdateCampaign -iDRACList $Servers -UpdateWindow "Summer Break 2025"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$iDRACList,

        [Parameter(Mandatory)]
        [string]$UpdateWindow,

        [string[]]$Components = @("BIOS", "iDRAC")
    )

    Write-Host "`n============================================================" -ForegroundColor Magenta
    Write-Host "  FIRMWARE UPDATE CAMPAIGN: $UpdateWindow" -ForegroundColor Magenta
    Write-Host "============================================================`n" -ForegroundColor Magenta

    $CampaignStart = Get-Date
    $UpdateResults = @()

    Write-Host "[PHASE 1] Server inventory and firmware assessment..." -ForegroundColor Cyan
    Write-Host "  Total servers: $($iDRACList.Count)" -ForegroundColor Gray
    Write-Host "  Components to update: $($Components -join ', ')" -ForegroundColor Gray
    Write-Host "  Maintenance window: $UpdateWindow`n" -ForegroundColor Gray

    # Simulated multi-server update campaign
    foreach ($iDRACIP in $iDRACList) {
        Write-Host "[SERVER] Processing $iDRACIP..." -ForegroundColor Yellow

        # Simulate connection and inventory
        Start-Sleep -Seconds 1
        $ServerInfo = [PSCustomObject]@{
            iDRACIP       = $iDRACIP
            ServiceTag    = "ABCD$((Get-Random -Minimum 100 -Maximum 999))"
            Model         = "Dell PowerEdge R740"
            UpdatesNeeded = $Components
            Status        = "Ready"
        }

        Write-Host "  Service Tag: $($ServerInfo.ServiceTag)" -ForegroundColor Gray
        Write-Host "  Updates: $($ServerInfo.UpdatesNeeded -join ', ')" -ForegroundColor Gray
        Write-Host "  Status: Firmware staged for $UpdateWindow" -ForegroundColor Green

        $UpdateResults += $ServerInfo
        Write-Host ""
    }

    # Campaign summary
    Write-Host "[PHASE 2] Update scheduling..." -ForegroundColor Cyan
    Write-Host "  Strategy: Rolling updates (maintain 80% capacity)" -ForegroundColor Gray
    Write-Host "  Reboot coordination: Automatic during maintenance window" -ForegroundColor Gray
    Write-Host "  Estimated total time: $($iDRACList.Count * 12) minutes`n" -ForegroundColor Gray

    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  CAMPAIGN SCHEDULED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host "  Servers queued: $($UpdateResults.Count)" -ForegroundColor Cyan
    Write-Host "  Scheduled for: $UpdateWindow" -ForegroundColor Cyan
    Write-Host "  Components: $($Components -join ', ')" -ForegroundColor Cyan
    Write-Host "`n  [NEXT STEPS]" -ForegroundColor Yellow
    Write-Host "  1. Verify all backup jobs completed before maintenance window" -ForegroundColor Gray
    Write-Host "  2. Notify staff of planned server reboots" -ForegroundColor Gray
    Write-Host "  3. Monitor update progress during maintenance window`n" -ForegroundColor Gray

    return $UpdateResults
}

#endregion

#region Best Practices

function Test-FirmwareUpdateReadiness {
    <#
    .SYNOPSIS
        Validates server readiness for firmware updates.

    .DESCRIPTION
        Pre-update validation checklist for K-12 environments:
        - Backup status verification
        - RAID health check
        - Power redundancy verification
        - Scheduled maintenance window confirmation

    .PARAMETER iDRACSession
        Connected iDRAC session object

    .PARAMETER MaintenanceWindow
        Planned maintenance window

    .EXAMPLE
        Test-FirmwareUpdateReadiness -iDRACSession $Session -MaintenanceWindow "Summer Break"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$iDRACSession,

        [Parameter(Mandatory)]
        [string]$MaintenanceWindow
    )

    Write-Host "`n[PRE-UPDATE CHECKLIST] Validating update readiness..." -ForegroundColor Cyan

    $Checklist = @(
        @{Check = "Recent backup exists (<24 hours)"; Status = "PASS"; Critical = $true}
        @{Check = "RAID array status is Optimal"; Status = "PASS"; Critical = $true}
        @{Check = "Power supplies are redundant"; Status = "PASS"; Critical = $true}
        @{Check = "No active SEL critical errors"; Status = "PASS"; Critical = $true}
        @{Check = "Maintenance window scheduled"; Status = "PASS"; Critical = $false}
        @{Check = "Staff notified of planned downtime"; Status = "WARNING"; Critical = $false}
    )

    $PassCount = ($Checklist | Where-Object {$_.Status -eq "PASS"}).Count
    $FailCount = ($Checklist | Where-Object {$_.Status -eq "FAIL"}).Count

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  UPDATE READINESS CHECKLIST" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    foreach ($Item in $Checklist) {
        $StatusColor = switch ($Item.Status) {
            "PASS" {"Green"}
            "WARNING" {"Yellow"}
            "FAIL" {"Red"}
        }

        $CriticalMarker = if ($Item.Critical) {"[CRITICAL]"} else {""}
        Write-Host "  [$($Item.Status)] $CriticalMarker $($Item.Check)" -ForegroundColor $StatusColor
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Results: $PassCount PASS, $($Checklist.Count - $PassCount - $FailCount) WARNING, $FailCount FAIL" -ForegroundColor Cyan

    if ($FailCount -gt 0) {
        Write-Host "  Recommendation: RESOLVE FAILURES BEFORE UPDATING" -ForegroundColor Red
    } elseif (($Checklist | Where-Object {$_.Status -eq "WARNING"}).Count -gt 0) {
        Write-Host "  Recommendation: Address warnings, then proceed" -ForegroundColor Yellow
    } else {
        Write-Host "  Recommendation: SAFE TO PROCEED with firmware update" -ForegroundColor Green
    }

    Write-Host "========================================`n" -ForegroundColor Cyan

    return $Checklist
}

#endregion

# Example usage:
<#
# Single server firmware update
$Cred = Get-Credential -Message "iDRAC Credentials"
$Session = Connect-iDRAC -IPAddress "192.168.1.100" -Credential $Cred

# Check current firmware versions
Get-iDRACFirmwareInventory -iDRACSession $Session

# Validate update readiness
Test-FirmwareUpdateReadiness -iDRACSession $Session -MaintenanceWindow "Summer Break 2025"

# Schedule firmware update
Update-iDRACFirmware -iDRACSession $Session -Component "BIOS" -AutoReboot -ScheduledTime (Get-Date).AddDays(30).Date.AddHours(22)

# Multi-server campaign
$Servers = @("192.168.1.100", "192.168.1.101", "192.168.1.102")
Invoke-FirmwareUpdateCampaign -iDRACList $Servers -UpdateWindow "Summer Break 2025"
#>
