<#
.SYNOPSIS
    Automated VLAN and DHCP configuration for K-12 network segmentation.

.DESCRIPTION
    PowerShell automation for deploying K-12 network segmentation including:
    - DHCP scope creation (Student, Staff, Admin, IoT, Guest VLANs)
    - DNS server configuration per VLAN
    - DHCP reservations for critical devices (servers, printers)
    - Network documentation generation

.NOTES
    Author: Bryan Shaw
    Purpose: K-12 Network Architecture Demonstration
    Target: K-12 Campus Network Deployment
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Modules DhcpServer

#region VLAN Configuration

function New-K12DHCPScopes {
    <#
    .SYNOPSIS
        Creates DHCP scopes for all K-12 network VLANs.

    .DESCRIPTION
        Automates DHCP scope creation for Student, Staff, Admin, IoT, and Guest networks
        with appropriate DNS servers, lease durations, and security policies.

    .PARAMETER DHCPServer
        DHCP server hostname or IP address

    .EXAMPLE
        New-K12DHCPScopes -DHCPServer "DC01.kisd.local"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DHCPServer
    )

    Write-Host "`n[DHCP CONFIGURATION] Creating K-12 network DHCP scopes..." -ForegroundColor Cyan

    # VLAN Configuration Table
    $VLANConfig = @(
        @{
            Name          = "Student-Data"
            VLAN          = 10
            Network       = "10.10.10.0"
            StartRange    = "10.10.10.50"
            EndRange      = "10.10.10.250"
            SubnetMask    = "255.255.255.0"
            Gateway       = "10.10.10.1"
            DNSServers    = @("10.10.10.2", "10.10.30.10")  # Filtered DNS + AD DNS
            LeaseDuration = "08:00:00"  # 8-hour lease (school day)
            Description   = "Student devices and classroom technology"
        }
        @{
            Name          = "Staff-Data"
            VLAN          = 20
            Network       = "10.10.20.0"
            StartRange    = "10.10.20.50"
            EndRange      = "10.10.20.200"
            SubnetMask    = "255.255.255.0"
            Gateway       = "10.10.20.1"
            DNSServers    = @("10.10.30.10", "10.10.30.11")  # AD DNS (redundant DCs)
            LeaseDuration = "1.00:00:00"  # 24-hour lease
            Description   = "Teacher and staff workstations"
        }
        @{
            Name          = "Admin-Servers"
            VLAN          = 30
            Network       = "10.10.30.0"
            StartRange    = "10.10.30.100"  # Smaller range (most servers use static IPs)
            EndRange      = "10.10.30.150"
            SubnetMask    = "255.255.255.0"
            Gateway       = "10.10.30.1"
            DNSServers    = @("10.10.30.10", "10.10.30.11")  # Internal DNS only
            LeaseDuration = "7.00:00:00"  # 7-day lease (rare DHCP usage)
            Description   = "Administrative and server network (mostly static IPs)"
        }
        @{
            Name          = "IoT-Building"
            VLAN          = 40
            Network       = "10.10.40.0"
            StartRange    = "10.10.40.50"
            EndRange      = "10.10.40.200"
            SubnetMask    = "255.255.255.0"
            Gateway       = "10.10.40.1"
            DNSServers    = @("10.10.30.10")  # Minimal DNS (IoT devices rarely need it)
            LeaseDuration = "30.00:00:00"  # 30-day lease (stable IoT infrastructure)
            Description   = "IP cameras, HVAC, door access control"
        }
        @{
            Name          = "Guest-BYOD"
            VLAN          = 50
            Network       = "10.10.50.0"
            StartRange    = "10.10.50.10"
            EndRange      = "10.10.50.240"
            SubnetMask    = "255.255.255.0"
            Gateway       = "10.10.50.1"
            DNSServers    = @("8.8.8.8", "1.1.1.1")  # Public DNS (no internal access)
            LeaseDuration = "04:00:00"  # 4-hour lease (auto-disconnect guests)
            Description   = "Guest and BYOD devices (isolated from internal networks)"
        }
    )

    foreach ($VLAN in $VLANConfig) {
        Write-Host "`n[VLAN $($VLAN.VLAN)] Creating scope: $($VLAN.Name)" -ForegroundColor Yellow

        if ($PSCmdlet.ShouldProcess($VLAN.Name, "Create DHCP scope")) {
            try {
                # Create DHCP scope
                Add-DhcpServerv4Scope -ComputerName $DHCPServer `
                                      -Name $VLAN.Name `
                                      -StartRange $VLAN.StartRange `
                                      -EndRange $VLAN.EndRange `
                                      -SubnetMask $VLAN.SubnetMask `
                                      -Description $VLAN.Description `
                                      -LeaseDuration $VLAN.LeaseDuration `
                                      -State Active `
                                      -ErrorAction Stop

                Write-Host "  [OK] Scope created: $($VLAN.Network)" -ForegroundColor Green

                # Configure scope options (Gateway, DNS)
                Set-DhcpServerv4OptionValue -ComputerName $DHCPServer `
                                            -ScopeId $VLAN.Network `
                                            -Router $VLAN.Gateway `
                                            -DnsServer $VLAN.DNSServers `
                                            -ErrorAction Stop

                Write-Host "  [OK] Options configured:" -ForegroundColor Green
                Write-Host "       Gateway: $($VLAN.Gateway)" -ForegroundColor Gray
                Write-Host "       DNS: $($VLAN.DNSServers -join ', ')" -ForegroundColor Gray
                Write-Host "       Lease: $($VLAN.LeaseDuration)" -ForegroundColor Gray
            }
            catch {
                Write-Warning "Failed to create scope $($VLAN.Name): $_"
            }
        }
    }

    Write-Host "`n[SUCCESS] DHCP scope configuration completed`n" -ForegroundColor Green
}

function New-K12DHCPReservations {
    <#
    .SYNOPSIS
        Creates DHCP reservations for critical infrastructure devices.

    .DESCRIPTION
        Assigns static DHCP reservations for servers, printers, and network devices
        to ensure consistent IP addressing without manual static IP configuration.

    .PARAMETER DHCPServer
        DHCP server hostname or IP address

    .EXAMPLE
        New-K12DHCPReservations -DHCPServer "DC01.kisd.local"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DHCPServer
    )

    Write-Host "`n[DHCP RESERVATIONS] Creating static reservations for critical devices..." -ForegroundColor Cyan

    # Critical device reservations
    $Reservations = @(
        # Admin/Server VLAN (VLAN 30)
        @{ScopeId = "10.10.30.0"; IPAddress = "10.10.30.10"; MAC = "00-1A-2B-3C-4D-10"; Name = "DC01"; Description = "Primary Domain Controller"}
        @{ScopeId = "10.10.30.0"; IPAddress = "10.10.30.11"; MAC = "00-1A-2B-3C-4D-11"; Name = "DC02"; Description = "Secondary Domain Controller"}
        @{ScopeId = "10.10.30.0"; IPAddress = "10.10.30.20"; MAC = "00-1A-2B-3C-4D-20"; Name = "SIS-DB01"; Description = "Student Information System Database"}
        @{ScopeId = "10.10.30.0"; IPAddress = "10.10.30.30"; MAC = "00-1A-2B-3C-4D-30"; Name = "FS-Students01"; Description = "Student File Server"}
        @{ScopeId = "10.10.30.0"; IPAddress = "10.10.30.40"; MAC = "00-1A-2B-3C-4D-40"; Name = "Veeam-Backup01"; Description = "Backup Server"}

        # Staff VLAN (VLAN 20) - Printers
        @{ScopeId = "10.10.20.0"; IPAddress = "10.10.20.210"; MAC = "00-1A-2B-3C-4D-51"; Name = "Printer-Office01"; Description = "Main Office Printer"}
        @{ScopeId = "10.10.20.0"; IPAddress = "10.10.20.211"; MAC = "00-1A-2B-3C-4D-52"; Name = "Printer-Staff01"; Description = "Staff Lounge Printer"}

        # Student VLAN (VLAN 10) - Classroom Printers
        @{ScopeId = "10.10.10.0"; IPAddress = "10.10.10.240"; MAC = "00-1A-2B-3C-4D-61"; Name = "Printer-Room101"; Description = "Classroom 101 Printer"}
        @{ScopeId = "10.10.10.0"; IPAddress = "10.10.10.241"; MAC = "00-1A-2B-3C-4D-62"; Name = "Printer-Room102"; Description = "Classroom 102 Printer"}

        # IoT VLAN (VLAN 40) - Security Cameras
        @{ScopeId = "10.10.40.0"; IPAddress = "10.10.40.100"; MAC = "00-1A-2B-3C-4D-71"; Name = "Camera-FrontDoor"; Description = "Front Entrance Camera"}
        @{ScopeId = "10.10.40.0"; IPAddress = "10.10.40.101"; MAC = "00-1A-2B-3C-4D-72"; Name = "Camera-Parking"; Description = "Parking Lot Camera"}
    )

    foreach ($Reservation in $Reservations) {
        if ($PSCmdlet.ShouldProcess($Reservation.Name, "Create DHCP reservation")) {
            try {
                Add-DhcpServerv4Reservation -ComputerName $DHCPServer `
                                            -ScopeId $Reservation.ScopeId `
                                            -IPAddress $Reservation.IPAddress `
                                            -ClientId $Reservation.MAC `
                                            -Name $Reservation.Name `
                                            -Description $Reservation.Description `
                                            -ErrorAction Stop

                Write-Host "  [OK] $($Reservation.Name): $($Reservation.IPAddress) ($($Reservation.MAC))" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to create reservation for $($Reservation.Name): $_"
            }
        }
    }

    Write-Host "`n[SUCCESS] DHCP reservations created`n" -ForegroundColor Green
}

#endregion

#region Network Documentation

function Export-K12NetworkDocumentation {
    <#
    .SYNOPSIS
        Generates comprehensive network documentation for K-12 infrastructure.

    .DESCRIPTION
        Creates documentation including:
        - VLAN IP addressing table
        - DHCP scope summary
        - Critical device inventory
        - Network diagram (Markdown format)

    .PARAMETER OutputPath
        Path to save documentation file

    .EXAMPLE
        Export-K12NetworkDocumentation -OutputPath "C:\Documentation\Network-Config.md"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    Write-Host "[DOCUMENTATION] Generating network configuration documentation..." -ForegroundColor Cyan

    $Documentation = @"
# K-12 District Network Configuration Documentation
**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## VLAN Summary

| VLAN | Name | Network | Gateway | DHCP Range | Purpose |
|------|------|---------|---------|------------|---------|
| 10 | Student-Data | 10.10.10.0/24 | 10.10.10.1 | 10.10.10.50-250 | Student devices, classroom tech |
| 20 | Staff-Data | 10.10.20.0/24 | 10.10.20.1 | 10.10.20.50-200 | Teacher/staff workstations |
| 30 | Admin-Servers | 10.10.30.0/24 | 10.10.30.1 | 10.10.30.100-150 | Domain controllers, servers |
| 40 | IoT-Building | 10.10.40.0/24 | 10.10.40.1 | 10.10.40.50-200 | IP cameras, HVAC, access control |
| 50 | Guest-BYOD | 10.10.50.0/24 | 10.10.50.1 | 10.10.50.10-240 | Guest/visitor devices |

## Critical Infrastructure

### Domain Controllers
- **DC01:** 10.10.30.10 (Primary DC, DNS, DHCP)
- **DC02:** 10.10.30.11 (Secondary DC, DNS, DHCP failover)

### Servers
- **SIS-DB01:** 10.10.30.20 (Student Information System Database)
- **FS-Students01:** 10.10.30.30 (Student File Server - H: drives)
- **Veeam-Backup01:** 10.10.30.40 (Backup & DR server)

### Network Infrastructure
- **Core Switch:** 10.10.30.2 (Layer 3 routing, inter-VLAN)
- **Firewall:** 10.10.30.3 (Internet gateway, CIPA filtering)

## Security Policies

### VLAN Isolation Rules
1. **Student VLAN (10)** → Can access: Internet (filtered), Admin VLAN (file servers only)
2. **Staff VLAN (20)** → Can access: Internet, Admin VLAN (full), Student VLAN (management)
3. **Admin VLAN (30)** → Can access: Internet (limited), all VLANs (management)
4. **IoT VLAN (40)** → CANNOT access other VLANs (isolated), limited internet
5. **Guest VLAN (50)** → Can access: Internet only (no internal networks)

### DNS Filtering
- **Student VLAN:** Cisco Umbrella (CIPA-compliant filtering)
- **Staff VLAN:** Internal AD DNS (less restrictive)
- **Guest VLAN:** Public DNS (8.8.8.8, 1.1.1.1)

## Maintenance Contacts
- **Network Administrator:** IT Department (it@kisd.edu)
- **ISP Support:** [ISP Name] - [Phone Number]
- **Equipment Vendor:** Cisco TAC / Dell Support

---

*This documentation was auto-generated via PowerShell automation*
"@

    $Documentation | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "[SUCCESS] Documentation saved to: $OutputPath" -ForegroundColor Green

    return $OutputPath
}

#endregion

# Example usage:
<#
# Deploy complete K-12 DHCP configuration
New-K12DHCPScopes -DHCPServer "DC01.kisd.local"
New-K12DHCPReservations -DHCPServer "DC01.kisd.local"

# Generate documentation
Export-K12NetworkDocumentation -OutputPath "C:\Documentation\KISD-Network-Config.md"
#>
