# Dell iDRAC Hardware Management Automation

PowerShell automation for Dell PowerEdge server management via iDRAC REST API, optimized for educational infrastructure with minimal downtime requirements.

---

## Overview

This folder contains PowerShell modules for automating Dell server hardware management tasks including health monitoring, firmware lifecycle management, and proactive maintenance. Designed specifically for school district IT environments where:

- **Downtime must occur during non-instructional hours** (after hours 6 PM, weekends, breaks)
- **Hardware failures impact student learning** (SIS, file servers, domain controllers)
- **Firmware updates require careful change control** (aligned with school calendar)
- **Remote server management is critical** (distributed campuses, limited on-site staff)

---

## Files

### 1. `iDRAC-HealthCheck.ps1`
**Purpose:** Server health monitoring and hardware diagnostics

**Functions:**
- `Connect-iDRAC` - Establishes authenticated REST API session to iDRAC interface
- `Get-iDRACServerHealth` - Comprehensive hardware health check (power, thermal, storage, network)
- `Test-iDRACConnectivity` - Network connectivity validation for remote management
- `Export-iDRACHardwareLogs` - System Event Log (SEL) export for failure analysis
- `Start-iDRACMaintenanceMode` - Prepares server for scheduled maintenance during breaks

**Example:**
```powershell
# Connect to iDRAC
$Cred = Get-Credential -Message "iDRAC Username/Password (root/calvin or custom)"
$Session = Connect-iDRAC -IPAddress "192.168.100.50" -Credential $Cred

# Check server health
$Health = Get-iDRACServerHealth -iDRACSession $Session

# Export hardware logs for troubleshooting
Export-iDRACHardwareLogs -iDRACSession $Session -OutputPath "C:\Logs\Server01-SEL.csv"

# Prepare for summer maintenance
Start-iDRACMaintenanceMode -iDRACSession $Session -MaintenanceWindow "Summer Break 2025"
```

---

###2. `iDRAC-FirmwareUpdate.ps1`
**Purpose:** Firmware lifecycle management and update automation

**Functions:**
- `Get-iDRACFirmwareInventory` - Scans installed firmware versions and available updates
- `Update-iDRACFirmware` - Applies firmware updates with reboot coordination
- `Invoke-FirmwareUpdateCampaign` - Orchestrates multi-server firmware update campaigns
- `Test-FirmwareUpdateReadiness` - Pre-update validation checklist (backups, RAID, power)

**Example:**
```powershell
# Inventory current firmware
Get-iDRACFirmwareInventory -iDRACSession $Session

# Validate server is ready for firmware update
Test-FirmwareUpdateReadiness -iDRACSession $Session -MaintenanceWindow "Spring Break"

# Schedule BIOS update for spring break (auto-reboot at 10 PM)
Update-iDRACFirmware -iDRACSession $Session `
                     -Component "BIOS" `
                     -ScheduledTime (Get-Date "2025-03-15 22:00") `
                     -AutoReboot

# Multi-server firmware campaign
$Servers = @("192.168.100.50", "192.168.100.51", "192.168.100.52")
Invoke-FirmwareUpdateCampaign -iDRACList $Servers `
                               -UpdateWindow "Summer Break 2025" `
                               -Components @("BIOS", "iDRAC", "PERC")
```

---

## K-12 Specific Considerations

### Maintenance Windows
**School Year (August - May):**
- **Emergency maintenance only** during instructional hours (8 AM - 3 PM)
- **Preferred window:** 6 PM - 10 PM (after-hours, staff available for escalation)
- **Weekend mornings:** Saturday/Sunday 6 AM - 12 PM (minimal building access issues)

**School Break Periods (Preferred):**
- **Thanksgiving Week:** Light maintenance (1-2 hour downtime acceptable)
- **Winter Break (Dec 20 - Jan 5):** Major firmware updates, hardware replacements
- **Spring Break (March):** BIOS/iDRAC updates, RAID controller firmware
- **Summer Break (June - July):** Comprehensive infrastructure upgrades, server replacements

### Hardware Criticality Tiers

**Tier 1 - Critical (RTO <30 minutes):**
- Student Information System (SIS) database servers
- Domain controllers (authentication for student/staff logins)
- Primary file servers (student home directories)

**Tier 2 - Important (RTO <4 hours):**
- Print servers
- Application servers (library systems, cafeteria POS)
- Secondary file servers

**Tier 3 - Standard (RTO <24 hours):**
- Administrative workload servers
- Test/dev environments

### Firmware Update Strategy
- **Quarterly inventory** of all server firmware versions
- **Annual updates** during summer break for non-critical firmware
- **As-needed updates** for critical security patches (coordinated with Veeam backups)
- **Rolling updates** for clustered servers (maintain 80% capacity during updates)

---

## Dell iDRAC REST API Overview

### API Endpoints (Redfish Standard)
- **System Info:** `/redfish/v1/Systems/System.Embedded.1`
- **Power Control:** `/redfish/v1/Systems/System.Embedded.1/Actions/ComputerSystem.Reset`
- **Firmware Inventory:** `/redfish/v1/UpdateService/FirmwareInventory`
- **System Event Log:** `/redfish/v1/Managers/iDRAC.Embedded.1/Logs/Sel`
- **Health Status:** `/redfish/v1/Chassis/System.Embedded.1`

### Authentication
- **Basic Auth:** Username/Password (default: root/calvin, change in production)
- **Session Token:** Persistent session for multiple API calls
- **HTTPS:** Port 443 (TLS 1.2+ required for security)

### Common iDRAC IP Addressing
- **Dedicated NIC:** Separate physical port for out-of-band management
- **Typical Range:** 192.168.100.x or 10.x.x.x (isolated management VLAN)
- **DNS Naming:** Convention: `<servername>-idrac.district.local`

---

## Requirements

**Software:**
- PowerShell 5.1 or later (Windows Server 2016+, Windows 10+)
- Network connectivity to iDRAC interface (HTTPS port 443)
- Dell iDRAC 8 or iDRAC 9 (Redfish API support)

**Permissions:**
- iDRAC Administrator role (for firmware updates and power control)
- iDRAC Operator role (for read-only health monitoring)

**Infrastructure:**
- Management VLAN with access to all iDRAC interfaces
- DNS records for iDRAC hostnames (optional but recommended)
- Firewall rules allowing HTTPS (443) to iDRAC subnet

---

## Deployment Guide

### Step 1: Configure iDRAC Network Settings
```powershell
# Verify iDRAC connectivity
Test-iDRACConnectivity -IPAddress "192.168.100.50"

# If successful, proceed with authentication test
$Cred = Get-Credential
$Session = Connect-iDRAC -IPAddress "192.168.100.50" -Credential $Cred
```

### Step 2: Baseline Server Health
```powershell
# Run initial health check on all servers
$Servers = @("192.168.100.50", "192.168.100.51", "192.168.100.52")

foreach ($ServerIP in $Servers) {
    $Session = Connect-iDRAC -IPAddress $ServerIP -Credential $Cred
    $Health = Get-iDRACServerHealth -iDRACSession $Session

    # Export baseline logs
    Export-iDRACHardwareLogs -iDRACSession $Session `
        -OutputPath "C:\Baselines\$ServerIP-$(Get-Date -Format 'yyyyMMdd').csv"
}
```

### Step 3: Schedule Automated Health Checks
```powershell
# Create daily health check script
$ScriptBlock = {
    Import-Module C:\Scripts\iDRAC-HealthCheck.ps1
    $Cred = Get-Credential # Use encrypted credential file in production
    $Session = Connect-iDRAC -IPAddress "192.168.100.50" -Credential $Cred
    $Health = Get-iDRACServerHealth -iDRACSession $Session

    # Email alerts if critical issues detected
    if ($Health.OverallStatus -ne "Healthy") {
        Send-MailMessage -To "it-alerts@district.edu" `
            -Subject "Server Health Alert: $($Session.ServerModel)" `
            -Body "Critical hardware issue detected. Check iDRAC for details."
    }
}

# Schedule as Windows Task (daily at 6 AM)
$Trigger = New-ScheduledTaskTrigger -Daily -At "6:00 AM"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Daily-Health-Check.ps1"
Register-ScheduledTask -TaskName "iDRAC-Daily-Health-Check" -Trigger $Trigger -Action $Action -User "SYSTEM"
```

### Step 4: Plan Firmware Update Campaign
```powershell
# Inventory all servers before summer break
$Servers = @("192.168.100.50", "192.168.100.51", "192.168.100.52")
$Inventory = @()

foreach ($ServerIP in $Servers) {
    $Session = Connect-iDRAC -IPAddress $ServerIP -Credential $Cred
    $FirmwareStatus = Get-iDRACFirmwareInventory -iDRACSession $Session
    $Inventory += [PSCustomObject]@{
        Server   = $ServerIP
        Firmware = $FirmwareStatus
    }
}

# Export for change management approval
$Inventory | Export-Csv -Path "C:\Reports\Summer-Firmware-Plan.csv" -NoTypeInformation
```

---

## Monitoring & Alerting

### Proactive Health Monitoring
Monitor these metrics daily (automated via scheduled task):
- **Power supply status** (redundancy critical for uptime)
- **Fan speeds** (early warning for thermal issues)
- **CPU/memory temperatures** (prevent thermal throttling during peak usage)
- **RAID array health** (catch disk failures before data loss)
- **System Event Log** (critical/warning events requiring attention)

### Alert Thresholds
| Component | Warning | Critical |
|-----------|---------|----------|
| Power Supply | Single PSU failure | Both PSUs failed |
| Fans | 1 fan below minimum RPM | 2+ fans failed |
| Temperature | >75°C CPU/ambient | >85°C CPU/ambient |
| RAID | Single disk degraded | Array offline/failed |
| Memory | ECC correctable errors | ECC uncorrectable errors |

---

## Troubleshooting

### Common Issues

**Issue:** Cannot connect to iDRAC (timeout or refused)
- **Solution:** Verify network connectivity with `Test-iDRACConnectivity`. Check firewall rules, VLAN routing, and iDRAC IP configuration.

**Issue:** Firmware update fails with "Job already in queue"
- **Solution:** Query existing jobs with iDRAC web interface. Clear completed jobs or wait for in-progress jobs to finish.

**Issue:** Server doesn't reboot after firmware staging
- **Solution:** Verify AutoReboot parameter was set. Manually trigger reboot via iDRAC or schedule reboot during maintenance window.

**Issue:** Health check reports fan failures but fans are running
- **Solution:** Export SEL logs to identify intermittent sensor issues. May require BMC (iDRAC) reset or firmware update.

---

## Security Considerations

**iDRAC Access Control:**
- Change default root/calvin password immediately
- Use unique, complex passwords per server (password manager recommended)
- Restrict iDRAC access to management VLAN only
- Disable unused protocols (Telnet, SNMPv1/v2)
- Enable TLS 1.2+ only (disable SSLv3, TLS 1.0/1.1)

**Audit Logging:**
- Enable iDRAC audit logging for all administrative actions
- Export logs to centralized SIEM (Security Information and Event Management)
- Review logs quarterly for unauthorized access attempts

---

## Additional Resources

- [Dell iDRAC REST API Guide](https://www.dell.com/support/kbdoc/en-us/000177100/support-for-integrated-dell-remote-access-controller-idrac)
- [Redfish API Specification](https://www.dmtf.org/standards/redfish)
- [Dell PowerEdge Firmware Update Best Practices](https://www.dell.com/support/home/en-us/drivers/firmware)

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com
