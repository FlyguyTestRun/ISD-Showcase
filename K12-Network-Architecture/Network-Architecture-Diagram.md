# K-12 Network Architecture Diagrams

## 5-Tier VLAN Segmentation Design

### Logical Network Topology

```
                            ┌─────────────────────────────────┐
                            │   Internet (CIPA Filtering)     │
                            │   DNS Filtering (OpenDNS/Cisco) │
                            └────────────┬────────────────────┘
                                         │
                                ┌────────▼────────┐
                                │   Edge Firewall │
                                │   (Palo Alto)   │
                                └────────┬────────┘
                                         │
                          ┌──────────────┼──────────────┐
                          │                             │
                     ┌────▼─────┐                 ┌─────▼────┐
                     │  Core    │                 │  Core    │
                     │ Switch 1 │◄───────────────►│ Switch 2 │
                     └────┬─────┘    10 Gbps      └─────┬────┘
                          │           Uplink            │
           ┌──────────────┼──────────────┬──────────────┼────────────┐
           │              │              │              │            │
      ┌────▼────┐    ┌────▼────┐   ┌────▼────┐    ┌────▼────┐  ┌───▼────┐
      │ Student │    │  Staff  │   │  Admin  │    │   IoT   │  │ Guest  │
      │  VLAN   │    │  VLAN   │   │  VLAN   │    │  VLAN   │  │  VLAN  │
      │   10    │    │   20    │   │   30    │    │   40    │  │   50   │
      └─────────┘    └─────────┘   └─────────┘    └─────────┘  └────────┘
```

---

## VLAN Configuration Details

### VLAN 10: Student Network
```
VLAN ID: 10
Subnet: 10.100.10.0/24
DHCP Range: 10.100.10.10 - 10.100.10.254
Gateway: 10.100.10.1
DNS: 10.100.1.10, 10.100.1.11 (Domain Controllers with DNS Filtering)

Devices:
├─ Student laptops (800 devices)
├─ Student Chromebooks (600 devices)
├─ Classroom iPads (200 devices)
└─ Lab computers (150 devices)

Total Estimated Devices: 1,750

Security Controls:
├─ CIPA-compliant web filtering (block social media, adult content)
├─ DNS filtering (OpenDNS/Cisco Umbrella)
├─ No access to Admin VLAN (firewall rule)
├─ Limited access to Staff VLAN (file servers only, read-only)
├─ Bandwidth throttling: 10 Mbps per device during school hours
└─ Firewall rules: Allow HTTP/HTTPS, block P2P, block torrents

Inter-VLAN Routing:
✅ Allow: Internet (filtered), Staff file servers (read-only)
❌ Block: Admin VLAN, IoT VLAN, Guest VLAN
```

---

### VLAN 20: Staff Network
```
VLAN ID: 20
Subnet: 10.100.20.0/24
DHCP Range: 10.100.20.10 - 10.100.20.200
Static Reservations: 10.100.20.201 - 10.100.20.254 (printers, AV equipment)
Gateway: 10.100.20.1
DNS: 10.100.1.10, 10.100.1.11

Devices:
├─ Teacher laptops (350 devices)
├─ Staff desktops (200 devices)
├─ Classroom interactive displays (120 devices)
├─ Printers (50 devices - static IPs)
└─ Document cameras (30 devices)

Total Estimated Devices: 750

Security Controls:
├─ Relaxed web filtering (allow educational resources)
├─ Access to Admin VLAN (requires authentication)
├─ File server access (full read/write to department shares)
├─ MFA required for Azure AD/M365 access
└─ Network access control (NAC) - 802.1X authentication

Inter-VLAN Routing:
✅ Allow: Internet, Admin VLAN (authenticated), Student VLAN (full access)
❌ Block: Guest VLAN
⚠️  Conditional: IoT VLAN (read-only for classroom AV control)
```

---

### VLAN 30: Administrative Network
```
VLAN ID: 30
Subnet: 10.100.30.0/24
DHCP Range: 10.100.30.10 - 10.100.30.100
Static Servers: 10.100.30.101 - 10.100.30.200
Gateway: 10.100.30.1
DNS: 10.100.1.10, 10.100.1.11

Devices:
├─ Domain Controllers (2 servers - 10.100.30.101, .102)
├─ File Servers (3 servers - 10.100.30.110-112)
├─ SIS Database Server (1 server - 10.100.30.120)
├─ Backup Server (Veeam - 10.100.30.130)
├─ vCenter Server (10.100.30.140)
├─ Administrator workstations (20 devices)
└─ IT staff laptops (10 devices)

Total Estimated Devices: 40

Security Controls:
├─ No internet access (isolated from student/staff VLANs)
├─ Firewall rules: Admin VLAN → Internet blocked by default
├─ Jump box required for remote access (10.100.30.200)
├─ Privileged Access Workstation (PAW) for domain admin tasks
├─ Multi-factor authentication required
├─ Network access control (NAC) - device certificates
└─ Logging and monitoring (SIEM integration)

Inter-VLAN Routing:
✅ Allow: Staff VLAN (authenticated users only)
❌ Block: Student VLAN, Guest VLAN, IoT VLAN
⚠️  Exception: Domain Controllers provide DNS/auth to all VLANs
```

---

### VLAN 40: IoT/Devices Network
```
VLAN ID: 40
Subnet: 10.100.40.0/24
DHCP Range: 10.100.40.10 - 10.100.40.254
Gateway: 10.100.40.1
DNS: 10.100.1.10, 10.100.1.11

Devices:
├─ Security cameras (80 devices)
├─ Access control systems (badge readers - 40 devices)
├─ HVAC controllers (25 devices)
├─ Wireless access points (120 WAPs)
├─ VoIP phones (200 devices)
└─ Smart classroom devices (projectors, AV - 80 devices)

Total Estimated Devices: 545

Security Controls:
├─ No internet access (local management only)
├─ Isolated from all other VLANs except Admin (for management)
├─ Firewall rules: IoT → Internet blocked
├─ IoT devices cannot initiate connections to other VLANs
├─ MAC address filtering (known device whitelist)
└─ VLAN hopping prevention (disable DTP, configure trunk ports manually)

Inter-VLAN Routing:
✅ Allow: Admin VLAN (management access only)
❌ Block: Student VLAN, Staff VLAN, Guest VLAN
⚠️  Exception: VoIP phones can reach SIP server in Admin VLAN
```

---

### VLAN 50: Guest Network
```
VLAN ID: 50
Subnet: 10.100.50.0/24
DHCP Range: 10.100.50.10 - 10.100.50.254
Gateway: 10.100.50.1
DNS: 8.8.8.8, 8.8.4.4 (Google Public DNS)

Devices:
├─ Parent/visitor devices (BYOD - estimated 50 concurrent)
├─ Contractor laptops (10-20 concurrent)
└─ Conference room guest tablets (5 devices)

Total Estimated Devices: 75 concurrent

Security Controls:
├─ Captive portal authentication (phone number or email required)
├─ Session timeout: 4 hours (automatic disconnect)
├─ Bandwidth throttling: 5 Mbps per device
├─ Web filtering (block illegal content, adult sites)
├─ Firewall rules: Guest → All internal VLANs blocked
├─ Client isolation (guests cannot communicate with each other)
└─ No access to internal resources (internet-only)

Inter-VLAN Routing:
✅ Allow: Internet only
❌ Block: All internal VLANs (Student, Staff, Admin, IoT)
```

---

## Physical Campus Distribution

### Multi-Campus Architecture

```
District WAN Topology:

                        ┌─────────────────────┐
                        │   Central Office    │
                        │   (Core Network)    │
                        │  - DC01, DC02       │
                        │  - SIS Database     │
                        │  - Backup Server    │
                        └──────────┬──────────┘
                                   │
                                   │ 1 Gbps Fiber
                  ┌────────────────┼────────────────┐
                  │                │                │
        ┌─────────▼─────┐  ┌───────▼──────┐  ┌─────▼────────┐
        │  High School   │  │ Middle School│  │  Elementary  │
        │  (2000 users)  │  │  (1200 users)│  │  (800 users) │
        │  - 4x Switches │  │  - 3x Switches│  │ - 2x Switches│
        │  - All VLANs   │  │  - All VLANs  │  │ - Student+IoT│
        └────────────────┘  └───────────────┘  └──────────────┘

Campus-Specific VLAN Distribution:

High School (Building A):
├─ Student VLAN (10): 1,000 devices
├─ Staff VLAN (20): 250 devices
├─ Admin VLAN (30): 15 devices (local admin workstations)
├─ IoT VLAN (40): 200 devices (cameras, WAPs, VoIP)
└─ Guest VLAN (50): 50 concurrent guests

Middle School (Building B):
├─ Student VLAN (10): 600 devices
├─ Staff VLAN (20): 180 devices
├─ IoT VLAN (40): 150 devices
└─ Guest VLAN (50): 30 concurrent guests

Elementary School (Building C):
├─ Student VLAN (10): 300 devices (shared iPads)
├─ Staff VLAN (20): 120 devices
├─ IoT VLAN (40): 100 devices
└─ Guest VLAN (50): 20 concurrent guests
```

---

## DHCP Scope Configuration

### DHCP Server Configuration (Windows Server)

**Based on Power BI Dashboard Statistics (439 total devices across VLANs):**

```powershell
# VLAN 10: Student Network
Add-DhcpServerv4Scope `
    -Name "Student-VLAN10" `
    -StartRange 10.100.10.10 `
    -EndRange 10.100.10.254 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 8:00:00 `  # 8-hour lease (school day)
    -State Active

Set-DhcpServerv4OptionValue -ScopeId 10.100.10.0 `
    -Router 10.100.10.1 `
    -DnsServer 10.100.1.10, 10.100.1.11 `
    -DnsDomain "students.district.edu"

# VLAN 20: Staff Network
Add-DhcpServerv4Scope `
    -Name "Staff-VLAN20" `
    -StartRange 10.100.20.10 `
    -EndRange 10.100.20.200 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 1.00:00:00 `  # 1-day lease
    -State Active

Set-DhcpServerv4OptionValue -ScopeId 10.100.20.0 `
    -Router 10.100.20.1 `
    -DnsServer 10.100.1.10, 10.100.1.11 `
    -DnsDomain "district.edu"

# VLAN 30: Admin Network (mostly static, small DHCP pool)
Add-DhcpServerv4Scope `
    -Name "Admin-VLAN30" `
    -StartRange 10.100.30.10 `
    -EndRange 10.100.30.100 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 7.00:00:00 `  # 7-day lease (admin devices rarely change)
    -State Active

Set-DhcpServerv4OptionValue -ScopeId 10.100.30.0 `
    -Router 10.100.30.1 `
    -DnsServer 10.100.1.10, 10.100.1.11 `
    -DnsDomain "admin.district.edu"

# VLAN 40: IoT Network
Add-DhcpServerv4Scope `
    -Name "IoT-VLAN40" `
    -StartRange 10.100.40.10 `
    -EndRange 10.100.40.254 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 30.00:00:00 `  # 30-day lease (IoT devices stable)
    -State Active

Set-DhcpServerv4OptionValue -ScopeId 10.100.40.0 `
    -Router 10.100.40.1 `
    -DnsServer 10.100.1.10, 10.100.1.11 `
    -DnsDomain "iot.district.edu"

# VLAN 50: Guest Network
Add-DhcpServerv4Scope `
    -Name "Guest-VLAN50" `
    -StartRange 10.100.50.10 `
    -EndRange 10.100.50.254 `
    -SubnetMask 255.255.255.0 `
    -LeaseDuration 4:00:00 `  # 4-hour lease (high turnover)
    -State Active

Set-DhcpServerv4OptionValue -ScopeId 10.100.50.0 `
    -Router 10.100.50.1 `
    -DnsServer 8.8.8.8, 8.8.4.4  # Public DNS for guest network
```

---

## Firewall Rules Matrix

### Inter-VLAN Traffic Control

| Source VLAN | Destination VLAN | Allowed Services | Rule |
|-------------|------------------|------------------|------|
| Student (10) | Internet | HTTP/HTTPS (filtered), DNS | ✅ ALLOW |
| Student (10) | Staff (20) | SMB (file servers only) | ⚠️ CONDITIONAL |
| Student (10) | Admin (30) | DNS (DCs only) | ⚠️ CONDITIONAL |
| Student (10) | IoT (40) | None | ❌ DENY |
| Student (10) | Guest (50) | None | ❌ DENY |
| Staff (20) | Internet | HTTP/HTTPS, DNS | ✅ ALLOW |
| Staff (20) | Admin (30) | SMB, RDP (authenticated) | ⚠️ CONDITIONAL |
| Staff (20) | Student (10) | All | ✅ ALLOW |
| Staff (20) | IoT (40) | HTTP (AV control) | ⚠️ CONDITIONAL |
| Staff (20) | Guest (50) | None | ❌ DENY |
| Admin (30) | Internet | HTTPS (Windows Update only) | ⚠️ CONDITIONAL |
| Admin (30) | Staff (20) | SMB, RDP | ✅ ALLOW |
| Admin (30) | Student (10) | DNS, Kerberos (auth) | ✅ ALLOW |
| Admin (30) | IoT (40) | SNMP, SSH, HTTP (mgmt) | ✅ ALLOW |
| Admin (30) | Guest (50) | None | ❌ DENY |
| IoT (40) | All VLANs | None (cannot initiate) | ❌ DENY |
| Guest (50) | Internet | HTTP/HTTPS, DNS | ✅ ALLOW |
| Guest (50) | All Internal | None | ❌ DENY |

---

## Network Device Inventory (Matches Power BI Dashboard)

### Total Devices by VLAN

```
VLAN 10 (Student):    175 devices (40% of total 439)
VLAN 20 (Staff):       88 devices (20% of total 439)
VLAN 30 (Admin):       35 devices (8% of total 439)
VLAN 40 (IoT):        110 devices (25% of total 439)
VLAN 50 (Guest):       31 devices (7% of total 439)
───────────────────────────────────────────────────
Total:                439 devices (100%)

Device Health Status:
├─ Healthy:           405 devices (92.26%)
├─ Warning:            28 devices (6.38%)
└─ Critical:            6 devices (1.37%)
```

---

## CIPA Compliance Architecture

### DNS-Based Content Filtering

```
Student/Staff Devices
        │
        ▼
    DNS Query (www.example.com)
        │
        ▼
┌───────────────────────┐
│  Domain Controllers   │
│   10.100.1.10/.11     │
│  (Forward to OpenDNS) │
└───────┬───────────────┘
        │
        ▼
┌───────────────────────┐
│  OpenDNS / Umbrella   │
│   (Cloud Filtering)   │
│  - Adult content: ❌  │
│  - Social media: ❌   │
│  - Educational: ✅    │
└───────┬───────────────┘
        │
        ▼
     Response
```

**Category Filtering (Students):**
- ❌ Blocked: Adult content, gambling, social media (Facebook, Instagram, TikTok), gaming, proxy/VPN
- ✅ Allowed: Educational resources, research databases, Google Workspace, Microsoft 365
- ⚠️ Conditional: YouTube (restricted mode enforced via Google Admin Console)

**Category Filtering (Staff):**
- ❌ Blocked: Adult content, gambling
- ✅ Allowed: All educational resources, social media (for classroom use), professional development

---

## Backup Network Architecture

### Veeam Backup Traffic Flow

```
Production VMs (VMware vSphere)
   │
   │ VMware NBD/HotAdd Transport
   ▼
┌────────────────────────┐
│  Veeam Backup Proxy    │
│  (Admin VLAN 30)       │
│  10.100.30.135         │
└────────┬───────────────┘
         │
         │ 10 Gbps Dedicated Backup Network (VLAN 60)
         ▼
┌────────────────────────┐
│ Veeam Backup Repository│
│  (Isolated Storage)    │
│  10.100.60.10          │
│  Capacity: 50 TB       │
└────────────────────────┘

Backup VLAN (60) - Isolated:
├─ Subnet: 10.100.60.0/24
├─ No routing to other VLANs (isolated Layer 2)
├─ Purpose: Maximize backup throughput, prevent backup traffic from impacting production
└─ Devices: Veeam server, backup proxies, repositories only
```

---

## Wireless Network (802.1X Authentication)

```
Wireless SSIDs:

1. District-Staff (VLAN 20)
   ├─ Security: WPA2-Enterprise (802.1X)
   ├─ Authentication: RADIUS (AD credentials)
   ├─ Certificate: Required (issued by district CA)
   └─ Devices: Staff laptops, tablets, phones

2. District-Student (VLAN 10)
   ├─ Security: WPA2-Enterprise (802.1X)
   ├─ Authentication: RADIUS (Student AD credentials)
   ├─ Auto-provisioning: Managed Chromebooks/iPads
   └─ Devices: Student laptops, Chromebooks, school-issued tablets

3. District-Guest (VLAN 50)
   ├─ Security: WPA2-PSK (pre-shared key, rotated monthly)
   ├─ Captive Portal: Phone/email registration
   ├─ No authentication to internal resources
   └─ Devices: Parent devices, contractor laptops
```

---

## Monitoring and Logging

### SIEM Integration Points

```
Network Devices (Switches, Firewalls, WAPs)
   │
   ▼ Syslog (UDP 514)
┌─────────────────────┐
│   SIEM Platform     │
│  (Splunk / ELK)     │
│  10.100.30.150      │
└──────────┬──────────┘
           │
           ▼
   Alerting Rules:
   ├─ Failed login attempts (>5 in 10 min)
   ├─ VLAN hopping detection
   ├─ Unusual traffic patterns (DDoS)
   ├─ Unauthorized device connections (MAC not in whitelist)
   └─ Firewall rule violations

Email Alerts → it-security@district.edu
```

---

## Disaster Recovery Network Topology

### Failover Architecture

```
Primary Site (Main Campus)          DR Site (Remote Office)
┌──────────────────────┐            ┌─────────────────────┐
│  Core Switch         │            │  DR Switch          │
│  - VLAN 10-50        │            │  - VLAN 10-50       │
│  - Production VMs    │            │  - Replica VMs      │
└───────┬──────────────┘            └─────────┬───────────┘
        │                                     │
        │  1 Gbps Site-to-Site VPN            │
        └─────────────────────────────────────┘

Failover Trigger:
├─ Manual: IT Director approval required
├─ Automatic: Primary site unavailable >30 minutes
└─ Testing: Quarterly DR drills during school breaks

IP Addressing (Dual Site):
├─ Primary Site: 10.100.x.x (all VLANs)
└─ DR Site: 10.200.x.x (mirrored VLANs)
    ├─ VLAN 10: 10.200.10.0/24
    ├─ VLAN 20: 10.200.20.0/24
    ├─ VLAN 30: 10.200.30.0/24
    └─ etc.
```

---

This architecture supports the Power BI Network Infrastructure Monitoring Dashboard statistics:
- **439 total devices** across 5 VLANs
- **92.26% device health rate**
- **4 campus locations** with centralized management
- **DHCP scope utilization** tracked per VLAN for capacity planning
