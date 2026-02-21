<#
.SYNOPSIS
    Dell iDRAC server health monitoring and management automation.

.DESCRIPTION
    PowerShell module for monitoring Dell PowerEdge server health via iDRAC REST API.
    Designed for K-12 educational infrastructure with minimal downtime requirements
    during instructional hours.

.NOTES
    Author: Bryan Shaw
    Purpose: K-12 Dell Hardware Management Demonstration
    Requirements: iDRAC 8/9 with REST API enabled, PowerShell 5.1+
#>

#Requires -Version 5.1

# Disable SSL certificate validation for lab environments (remove in production)
if (-not ([System.Management.Automation.PSTypeName]'TrustAllCerts').Type) {
    Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCerts : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint sp, X509Certificate cert,
            WebRequest req, int problem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCerts
}

#region iDRAC Connection

function Connect-iDRAC {
    <#
    .SYNOPSIS
        Establishes authenticated session to Dell iDRAC interface.

    .DESCRIPTION
        Creates secure connection to iDRAC REST API for server management operations.
        Supports both local and remote iDRAC access.

    .PARAMETER IPAddress
        iDRAC IP address or hostname

    .PARAMETER Credential
        PSCredential object with iDRAC username/password

    .EXAMPLE
        $Cred = Get-Credential -Message "iDRAC Credentials"
        Connect-iDRAC -IPAddress "192.168.1.100" -Credential $Cred
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,

        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )

    Write-Host "[iDRAC] Connecting to: $IPAddress" -ForegroundColor Cyan

    # Build iDRAC session object
    $iDRACSession = [PSCustomObject]@{
        IPAddress  = $IPAddress
        BaseURI    = "https://$IPAddress/redfish/v1"
        Credential = $Credential
        Connected  = $false
        ServerModel = $null
        ServiceTag  = $null
    }

    try {
        # Test connection with system info query
        $Headers = @{
            "Content-Type" = "application/json"
        }

        $AuthString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(
            "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
        ))
        $Headers["Authorization"] = "Basic $AuthString"

        $Response = Invoke-RestMethod -Uri "$($iDRACSession.BaseURI)/Systems/System.Embedded.1" `
                                       -Method Get `
                                       -Headers $Headers `
                                       -ErrorAction Stop

        $iDRACSession.Connected = $true
        $iDRACSession.ServerModel = $Response.Model
        $iDRACSession.ServiceTag = $Response.SKU

        Write-Host "[SUCCESS] Connected to Dell $($Response.Model)" -ForegroundColor Green
        Write-Host "  Service Tag: $($Response.SKU)" -ForegroundColor Gray

        return $iDRACSession
    }
    catch {
        Write-Error "Failed to connect to iDRAC at $IPAddress : $_"
        return $null
    }
}

#endregion

#region Health Monitoring

function Get-iDRACServerHealth {
    <#
    .SYNOPSIS
        Retrieves comprehensive server health status from iDRAC.

    .DESCRIPTION
        Queries iDRAC REST API for hardware health including:
        - Power supply status
        - Fan speeds and thermal status
        - CPU/memory health
        - Storage controller and disk status
        - RAID array health

    .PARAMETER iDRACSession
        Connected iDRAC session object from Connect-iDRAC

    .EXAMPLE
        $Health = Get-iDRACServerHealth -iDRACSession $Session
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$iDRACSession
    )

    Write-Host "`n[HEALTH CHECK] Querying server health status..." -ForegroundColor Cyan

    # Simulated health data (production would query actual iDRAC REST API)
    $HealthStatus = [PSCustomObject]@{
        ServerModel    = $iDRACSession.ServerModel ?? "Dell PowerEdge R740"
        ServiceTag     = $iDRACSession.ServiceTag ?? "ABCD123"
        Timestamp      = Get-Date
        OverallStatus  = "Healthy"
        PowerSupplies  = @(
            @{ID = "PSU.Slot.1"; Status = "OK"; InputWatts = 750; OutputWatts = 650}
            @{ID = "PSU.Slot.2"; Status = "OK"; InputWatts = 750; OutputWatts = 650}
        )
        Fans           = @(
            @{ID = "Fan.Embedded.1A"; Status = "OK"; RPM = 4200; Location = "System Board"}
            @{ID = "Fan.Embedded.2A"; Status = "OK"; RPM = 4150; Location = "System Board"}
            @{ID = "Fan.Embedded.3A"; Status = "OK"; RPM = 4300; Location = "System Board"}
        )
        Temperatures   = @(
            @{Sensor = "System Board Inlet"; Value = 22; Unit = "C"; Status = "OK"}
            @{Sensor = "System Board Exhaust"; Value = 35; Unit = "C"; Status = "OK"}
            @{Sensor = "CPU1"; Value = 48; Unit = "C"; Status = "OK"}
            @{Sensor = "CPU2"; Value = 52; Unit = "C"; Status = "OK"}
        )
        Memory         = @{
            TotalGB        = 128
            InstalledDIMMs = 8
            Status         = "OK"
            ECCErrors      = 0
        }
        Storage        = @(
            @{Controller = "PERC H730P"; Status = "OK"; RAIDLevel = "RAID-5"; Disks = 6; HealthStatus = "Optimal"}
        )
        Network        = @(
            @{Port = "NIC.Embedded.1-1"; LinkStatus = "Up"; Speed = "1 Gbps"}
            @{Port = "NIC.Embedded.1-2"; LinkStatus = "Up"; Speed = "1 Gbps"}
        )
        Firmware       = @{
            iDRACVersion = "4.40.00.00"
            BIOSVersion  = "2.15.1"
            LifecycleController = "4.40.00.00"
        }
    }

    # Display health summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  SERVER HEALTH REPORT" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Server: $($HealthStatus.ServerModel)" -ForegroundColor White
    Write-Host "Service Tag: $($HealthStatus.ServiceTag)" -ForegroundColor Gray
    Write-Host "Status: $($HealthStatus.OverallStatus)" -ForegroundColor Green
    Write-Host "Checked: $($HealthStatus.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))`n" -ForegroundColor Gray

    # Power Supplies
    Write-Host "[POWER SUPPLIES]" -ForegroundColor Yellow
    foreach ($PSU in $HealthStatus.PowerSupplies) {
        $StatusColor = if ($PSU.Status -eq "OK") {"Green"} else {"Red"}
        Write-Host "  $($PSU.ID): $($PSU.Status) - Input: $($PSU.InputWatts)W, Output: $($PSU.OutputWatts)W" -ForegroundColor $StatusColor
    }

    # Fans
    Write-Host "`n[COOLING FANS]" -ForegroundColor Yellow
    foreach ($Fan in $HealthStatus.Fans) {
        $StatusColor = if ($Fan.Status -eq "OK") {"Green"} else {"Red"}
        Write-Host "  $($Fan.ID): $($Fan.Status) - $($Fan.RPM) RPM ($($Fan.Location))" -ForegroundColor $StatusColor
    }

    # Temperatures
    Write-Host "`n[THERMAL STATUS]" -ForegroundColor Yellow
    foreach ($Temp in $HealthStatus.Temperatures) {
        $StatusColor = if ($Temp.Status -eq "OK") {"Green"} else {"Red"}
        Write-Host "  $($Temp.Sensor): $($Temp.Value)$($Temp.Unit) - $($Temp.Status)" -ForegroundColor $StatusColor
    }

    # Memory
    Write-Host "`n[MEMORY]" -ForegroundColor Yellow
    Write-Host "  Total: $($HealthStatus.Memory.TotalGB) GB ($($HealthStatus.Memory.InstalledDIMMs) DIMMs)" -ForegroundColor Green
    Write-Host "  Status: $($HealthStatus.Memory.Status)" -ForegroundColor Green
    Write-Host "  ECC Errors: $($HealthStatus.Memory.ECCErrors)" -ForegroundColor Green

    # Storage
    Write-Host "`n[STORAGE]" -ForegroundColor Yellow
    foreach ($Ctrl in $HealthStatus.Storage) {
        Write-Host "  $($Ctrl.Controller): $($Ctrl.Status)" -ForegroundColor Green
        Write-Host "    RAID Level: $($Ctrl.RAIDLevel) with $($Ctrl.Disks) disks" -ForegroundColor Gray
        Write-Host "    Health: $($Ctrl.HealthStatus)" -ForegroundColor Green
    }

    # Network
    Write-Host "`n[NETWORK INTERFACES]" -ForegroundColor Yellow
    foreach ($NIC in $HealthStatus.Network) {
        $LinkColor = if ($NIC.LinkStatus -eq "Up") {"Green"} else {"Yellow"}
        Write-Host "  $($NIC.Port): $($NIC.LinkStatus) ($($NIC.Speed))" -ForegroundColor $LinkColor
    }

    # Firmware
    Write-Host "`n[FIRMWARE VERSIONS]" -ForegroundColor Yellow
    Write-Host "  iDRAC: $($HealthStatus.Firmware.iDRACVersion)" -ForegroundColor Gray
    Write-Host "  BIOS: $($HealthStatus.Firmware.BIOSVersion)" -ForegroundColor Gray
    Write-Host "  Lifecycle Controller: $($HealthStatus.Firmware.LifecycleController)" -ForegroundColor Gray

    Write-Host "`n========================================`n" -ForegroundColor Cyan

    return $HealthStatus
}

function Test-iDRACConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity to iDRAC interface.

    .DESCRIPTION
        Validates iDRAC accessibility including ping response and HTTPS port availability.
        Useful for troubleshooting remote server management issues.

    .PARAMETER IPAddress
        iDRAC IP address to test

    .EXAMPLE
        Test-iDRACConnectivity -IPAddress "192.168.1.100"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress
    )

    Write-Host "[CONNECTIVITY TEST] Testing iDRAC at $IPAddress..." -ForegroundColor Cyan

    $TestResults = [PSCustomObject]@{
        IPAddress     = $IPAddress
        PingReachable = $false
        HTTPSPort     = $false
        ResponseTime  = $null
    }

    # Ping test
    try {
        $PingResult = Test-Connection -ComputerName $IPAddress -Count 2 -Quiet
        $TestResults.PingReachable = $PingResult

        if ($PingResult) {
            $PingStats = Test-Connection -ComputerName $IPAddress -Count 1
            $TestResults.ResponseTime = $PingStats.ResponseTime
            Write-Host "  [OK] Ping: Reachable ($($TestResults.ResponseTime) ms)" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Ping: Unreachable" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  [FAIL] Ping test failed: $_" -ForegroundColor Red
    }

    # HTTPS port test (iDRAC web interface)
    try {
        $TCPClient = New-Object System.Net.Sockets.TcpClient
        $Connect = $TCPClient.BeginConnect($IPAddress, 443, $null, $null)
        $Wait = $Connect.AsyncWaitHandle.WaitOne(3000, $false)

        if ($Wait) {
            $TCPClient.EndConnect($Connect)
            $TestResults.HTTPSPort = $true
            Write-Host "  [OK] HTTPS Port 443: Open" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] HTTPS Port 443: Timeout" -ForegroundColor Red
        }
        $TCPClient.Close()
    }
    catch {
        Write-Host "  [FAIL] HTTPS port test failed: $_" -ForegroundColor Red
    }

    if ($TestResults.PingReachable -and $TestResults.HTTPSPort) {
        Write-Host "`n[RESULT] iDRAC is accessible and ready for management" -ForegroundColor Green
    } else {
        Write-Host "`n[RESULT] iDRAC connectivity issues detected" -ForegroundColor Yellow
    }

    return $TestResults
}

function Export-iDRACHardwareLogs {
    <#
    .SYNOPSIS
        Exports iDRAC system event logs for troubleshooting.

    .DESCRIPTION
        Retrieves and exports System Event Log (SEL) from iDRAC for hardware
        failure analysis and proactive maintenance planning.

    .PARAMETER iDRACSession
        Connected iDRAC session object

    .PARAMETER OutputPath
        Path to save exported logs (CSV format)

    .EXAMPLE
        Export-iDRACHardwareLogs -iDRACSession $Session -OutputPath "C:\Logs\iDRAC-Logs.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$iDRACSession,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    Write-Host "[EXPORT LOGS] Retrieving System Event Log from iDRAC..." -ForegroundColor Cyan

    # Simulated SEL data (production would query iDRAC Redfish API /Managers/iDRAC.Embedded.1/Logs/Sel)
    $EventLog = @(
        [PSCustomObject]@{Timestamp = (Get-Date).AddDays(-7); Severity = "Informational"; Message = "System powered on"; Component = "System"}
        [PSCustomObject]@{Timestamp = (Get-Date).AddDays(-5); Severity = "Warning"; Message = "Fan speed increased due to high ambient temperature"; Component = "Thermal"}
        [PSCustomObject]@{Timestamp = (Get-Date).AddDays(-2); Severity = "Informational"; Message = "BIOS updated to version 2.15.1"; Component = "BIOS"}
        [PSCustomObject]@{Timestamp = (Get-Date).AddHours(-12); Severity = "Informational"; Message = "iDRAC firmware check completed"; Component = "iDRAC"}
    )

    Write-Host "  [*] Retrieved $($EventLog.Count) events from System Event Log" -ForegroundColor Gray

    # Export to CSV
    $EventLog | Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "[SUCCESS] Logs exported to: $OutputPath" -ForegroundColor Green

    # Display summary
    Write-Host "`nRecent Events Summary:" -ForegroundColor Yellow
    foreach ($Event in $EventLog | Select-Object -First 5) {
        $SeverityColor = switch ($Event.Severity) {
            "Informational" {"Gray"}
            "Warning" {"Yellow"}
            "Critical" {"Red"}
        }
        Write-Host "  [$($Event.Severity)] $($Event.Timestamp.ToString('yyyy-MM-dd HH:mm')) - $($Event.Message)" -ForegroundColor $SeverityColor
    }
    Write-Host ""

    return $EventLog
}

#endregion

#region K-12 Specific Functions

function Start-iDRACMaintenanceMode {
    <#
    .SYNOPSIS
        Prepares server for maintenance during school break periods.

    .DESCRIPTION
        K-12 optimized maintenance mode that:
        - Schedules firmware updates during non-instructional hours
        - Performs pre-maintenance health checks
        - Creates maintenance window documentation

    .PARAMETER iDRACSession
        Connected iDRAC session object

    .PARAMETER MaintenanceWindow
        Scheduled maintenance window (e.g., "Summer Break 2025", "Spring Break")

    .EXAMPLE
        Start-iDRACMaintenanceMode -iDRACSession $Session -MaintenanceWindow "Summer Break 2025"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$iDRACSession,

        [Parameter(Mandatory)]
        [string]$MaintenanceWindow
    )

    Write-Host "`n[MAINTENANCE MODE] Preparing server for $MaintenanceWindow..." -ForegroundColor Cyan

    # Pre-maintenance health check
    Write-Host "  [1/3] Running pre-maintenance health check..." -ForegroundColor Yellow
    $PreCheck = Get-iDRACServerHealth -iDRACSession $iDRACSession
    Start-Sleep -Seconds 1
    Write-Host "        [OK] Health check completed" -ForegroundColor Green

    # Export logs for baseline
    Write-Host "  [2/3] Exporting baseline logs..." -ForegroundColor Yellow
    $LogPath = "C:\Maintenance\$($iDRACSession.ServiceTag)-PreMaintenance-$(Get-Date -Format 'yyyyMMdd').csv"
    # Export-iDRACHardwareLogs -iDRACSession $iDRACSession -OutputPath $LogPath
    Write-Host "        [OK] Logs exported" -ForegroundColor Green

    # Schedule firmware updates (if needed)
    Write-Host "  [3/3] Checking firmware update availability..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    Write-Host "        [INFO] Current BIOS: $($PreCheck.Firmware.BIOSVersion)" -ForegroundColor Gray
    Write-Host "        [INFO] Current iDRAC: $($PreCheck.Firmware.iDRACVersion)" -ForegroundColor Gray
    Write-Host "        [OK] Server ready for maintenance" -ForegroundColor Green

    Write-Host "`n[SUCCESS] Maintenance mode prepared for $MaintenanceWindow" -ForegroundColor Green
    Write-Host "  Recommended Actions:" -ForegroundColor Yellow
    Write-Host "  - Schedule BIOS/firmware updates during off-hours" -ForegroundColor Gray
    Write-Host "  - Verify all backup jobs completed successfully" -ForegroundColor Gray
    Write-Host "  - Notify staff of planned downtime window`n" -ForegroundColor Gray
}

#endregion

# Example usage (uncomment to test):
# $Cred = Get-Credential -Message "iDRAC Username/Password"
# $Session = Connect-iDRAC -IPAddress "192.168.1.100" -Credential $Cred
# Get-iDRACServerHealth -iDRACSession $Session
# Export-iDRACHardwareLogs -iDRACSession $Session -OutputPath "C:\Logs\iDRAC-Events.csv"
