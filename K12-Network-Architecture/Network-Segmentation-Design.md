# K-12 Network Segmentation Architecture
## Secure VLAN Design for Educational Environments

**Author:** Bryan Shaw
**Target Environment:** K-12 School District Campus Network
**Compliance:** CIPA, COPPA, FERPA, NIST Cybersecurity Framework
**Last Updated:** February 2025

---

## Executive Summary

This document outlines a secure network segmentation strategy for K-12 educational environments using VLANs (Virtual Local Area Networks), firewall policies, and DNS filtering to:

- **Protect student data** (FERPA compliance)
- **Enforce internet safety** (CIPA compliance)
- **Isolate IoT devices** (security best practice)
- **Support BYOD** (Bring Your Own Device) without compromising network security
- **Enable granular access controls** for different user populations (students, staff, guests, admin)

---

## Network Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        INTERNET                                     │
│                    (Filtered via CIPA-compliant DNS/Proxy)          │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │   FIREWALL    │
                    │  (Layer 3/7)  │
                    │  Rules Below  │
                    └───────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        │         CORE SWITCH (Layer 3)         │
        │   Routing Between VLANs / ACLs        │
        └───┬───────┬───────┬───────┬───────┬───┘
            │       │       │       │       │
    ┌───────┴──┐ ┌─┴────┐ ┌┴─────┐ ┌┴────┐ ┌┴──────┐
    │ VLAN 10  │ │VLAN  │ │VLAN  │ │VLAN │ │ VLAN  │
    │ Student  │ │  20  │ │  30  │ │  40 │ │  50   │
    │  Data    │ │Staff │ │Admin │ │ IoT │ │ Guest │
    └──────────┘ └──────┘ └──────┘ └─────┘ └───────┘
```

---

## VLAN Design

### VLAN 10 - Student Data Network
**Purpose:** Student devices, classroom technology, student-facing services

**IP Range:** `10.10.10.0/24` (10.10.10.1 - 10.10.10.254)
**Default Gateway:** 10.10.10.1
**DHCP Scope:** 10.10.10.50 - 10.10.10.250
**DNS Servers:** Internal (filtered), Google SafeSearch enforced

**Allowed Devices:**
- Student laptops/tablets (district-issued)
- Chromebooks (managed via Google Workspace)
- Interactive whiteboards (Promethean, SMART Board)
- Classroom printers

**Security Controls:**
- **CIPA Filtering:** All HTTP/HTTPS traffic routed through content filter (blocks adult content, social media during school hours)
- **SafeSearch Enforced:** DNS-level enforcement of Google/Bing SafeSearch
- **Device Authentication:** 802.1X (username/password) or MAC address filtering
- **Isolation:** Students cannot access other students' devices (private VLAN or AP isolation)

**Firewall Rules (Outbound):**
```
ALLOW   VLAN 10 → Internet (Ports 80, 443) via Content Filter
ALLOW   VLAN 10 → VLAN 30 (Admin - SIS server, file servers) [restricted]
DENY    VLAN 10 → VLAN 20 (Staff) - no access to staff resources
DENY    VLAN 10 → VLAN 40 (IoT) - prevent student access to cameras/HVAC
```

---

### VLAN 20 - Staff Data Network
**Purpose:** Teacher/staff workstations, administrative computers, staff-facing applications

**IP Range:** `10.10.20.0/24` (10.10.20.1 - 10.10.20.254)
**Default Gateway:** 10.10.20.1
**DHCP Scope:** 10.10.20.50 - 10.10.20.200
**DNS Servers:** Internal Active Directory DNS

**Allowed Devices:**
- Teacher workstations (Windows 10/11 domain-joined)
- Staff laptops (district-issued, managed via Intune)
- Administrative desktops
- Networked printers (staff areas)

**Security Controls:**
- **Domain Authentication:** Active Directory 802.1X (computer + user authentication)
- **Less Restrictive Filtering:** Content filter allows educational research, social media for professional development
- **Group Policy:** Windows Defender, BitLocker encryption, automatic updates enforced
- **File Server Access:** Staff home directories (H: drive), shared resources

**Firewall Rules (Outbound):**
```
ALLOW   VLAN 20 → Internet (All ports except blocked exploits)
ALLOW   VLAN 20 → VLAN 30 (Admin - full access to SIS, domain controllers, file servers)
ALLOW   VLAN 20 → VLAN 10 (Student - for classroom management software, grade entry)
DENY    VLAN 20 → VLAN 40 (IoT - except authorized IT staff)
```

---

### VLAN 30 - Administrative / Server Network
**Purpose:** Domain controllers, SIS database servers, file servers, critical infrastructure

**IP Range:** `10.10.30.0/24` (10.10.30.1 - 10.10.30.254)
**Static IPs:** All servers use static addressing
**Default Gateway:** 10.10.30.1
**DNS Servers:** Internal (10.10.30.10, 10.10.30.11 - redundant DCs)

**Devices:**
- Domain controllers (DC01, DC02)
- Student Information System (SIS) database server
- File servers (student/staff home directories)
- Print servers
- DHCP/DNS servers
- Backup servers (Veeam)

**Security Controls:**
- **No Direct Internet Access:** Servers only access internet via explicit firewall rules (Windows Update, license activation)
- **Role-Based Access:** Only IT staff and authorized service accounts can connect
- **Audit Logging:** All access logged for FERPA compliance
- **Backup Isolation:** Veeam backup server on separate VLAN 30 subnet (10.10.30.128/25)

**Firewall Rules (Inbound):**
```
ALLOW   VLAN 10 → VLAN 30 (Port 445 - SMB file access for student H: drives)
ALLOW   VLAN 10 → VLAN 30 (Port 3389 - RDP, only for IT-managed student remote access)
ALLOW   VLAN 20 → VLAN 30 (All ports - staff need full server access)
DENY    VLAN 50 (Guest) → VLAN 30 - no guest access to internal resources
```

---

### VLAN 40 - IoT / Building Systems Network
**Purpose:** IP cameras, HVAC systems, door access control, security systems

**IP Range:** `10.10.40.0/24` (10.10.40.1 - 10.10.40.254)
**DHCP Scope:** 10.10.40.50 - 10.10.40.200
**Default Gateway:** 10.10.40.1

**Devices:**
- IP security cameras (Axis, Hikvision)
- HVAC controllers (Trane, Johnson Controls)
- Door access control (Raptor, Verkada)
- Digital signage (Brightsign)
- Wireless access points (management VLAN)

**Security Controls:**
- **Network Isolation:** IoT devices CANNOT initiate connections to other VLANs
- **No Internet Access (Default):** Most IoT devices don't need internet; allow only for firmware updates
- **Segmentation:** Further segment by device type if possible (VLAN 41 = cameras, VLAN 42 = HVAC)

**Firewall Rules:**
```
ALLOW   VLAN 20 (IT Staff) → VLAN 40 - for camera viewing, system management
DENY    VLAN 10 (Student) → VLAN 40 - students cannot access building systems
DENY    VLAN 40 → ALL other VLANs - IoT devices can't pivot to attack other networks
```

---

### VLAN 50 - Guest / BYOD Network
**Purpose:** Parent devices (open house, conferences), contractor laptops, student personal devices (phones)

**IP Range:** `10.10.50.0/24` (10.10.50.1 - 10.10.50.254)
**DHCP Scope:** 10.10.50.10 - 10.10.50.240
**Default Gateway:** 10.10.50.1
**DNS Servers:** Public DNS (Google 8.8.8.8, Cloudflare 1.1.1.1)

**Allowed Devices:**
- Parent/visitor smartphones during events
- Contractor laptops (short-term access)
- Student personal phones (if BYOD policy allows)

**Security Controls:**
- **Captive Portal:** Web-based authentication (accept terms of use before internet access)
- **Internet-Only Access:** No access to any internal VLANs (student/staff/admin networks)
- **Bandwidth Throttling:** Limit to 5 Mbps per device to prevent abuse
- **Session Timeout:** 4-hour automatic disconnection, re-authentication required

**Firewall Rules:**
```
ALLOW   VLAN 50 → Internet (Ports 80, 443, 53 - basic web browsing)
DENY    VLAN 50 → VLAN 10, 20, 30, 40 - complete isolation from internal networks
```

---

## Inter-VLAN Routing & Access Control Lists (ACLs)

### Core Switch Configuration (Cisco Example)

```cisco
! VLAN Creation
vlan 10
 name Student-Data
vlan 20
 name Staff-Data
vlan 30
 name Admin-Servers
vlan 40
 name IoT-Building
vlan 50
 name Guest-BYOD

! Layer 3 Interfaces (SVIs - Switched Virtual Interfaces)
interface Vlan10
 description Student Data Network
 ip address 10.10.10.1 255.255.255.0
 ip helper-address 10.10.30.20  ! DHCP server in Admin VLAN

interface Vlan20
 description Staff Data Network
 ip address 10.10.20.1 255.255.255.0
 ip helper-address 10.10.30.20

interface Vlan30
 description Admin / Server Network
 ip address 10.10.30.1 255.255.255.0

interface Vlan40
 description IoT / Building Systems
 ip address 10.10.40.1 255.255.255.0
 ip helper-address 10.10.30.20

interface Vlan50
 description Guest / BYOD
 ip address 10.10.50.1 255.255.255.0
 ip helper-address 10.10.30.20

! ACLs (Access Control Lists)
! Block students from accessing IoT network
access-list 110 deny ip 10.10.10.0 0.0.0.255 10.10.40.0 0.0.0.255
access-list 110 permit ip 10.10.10.0 0.0.0.255 any

! Block guests from accessing any internal VLANs
access-list 150 deny ip 10.10.50.0 0.0.0.255 10.10.0.0 0.0.255.255
access-list 150 permit ip 10.10.50.0 0.0.0.255 any

! Apply ACLs to VLANs
interface Vlan10
 ip access-group 110 in

interface Vlan50
 ip access-group 150 in
```

---

## DNS Filtering & CIPA Compliance

### CIPA Requirements (Children's Internet Protection Act)
Schools receiving E-Rate funding must:
1. Block/filter access to obscene content, child pornography
2. Block/filter access to content harmful to minors
3. Monitor online activities of minors
4. Educate students about appropriate online behavior

### Implementation Strategy

**Option 1: DNS-Based Filtering (Cisco Umbrella, Cloudflare Gateway)**
- Student VLAN DHCP provides filtered DNS servers (10.10.10.2 - internal DNS forwarder to Umbrella)
- All DNS queries logged for compliance reporting
- Enforce SafeSearch on Google/Bing/YouTube

**Option 2: Web Proxy (Squid, Lightspeed, Securly)**
- Transparent HTTP/HTTPS proxy intercepts all web traffic from student VLAN
- SSL inspection with trusted CA certificate (deployed via Group Policy/MDM)
- Category blocking: Adult content, gambling, weapons, drugs, anonymizers (VPNs)

**Option 3: Firewall Application Control (Palo Alto, Fortinet)**
- Layer 7 firewall inspects application traffic (not just port 80/443)
- Blocks social media during school hours (7 AM - 3 PM), allows after-hours
- Granular YouTube filtering (allow educational channels, block entertainment)

### Recommended Configuration
- **Filtering Service:** Cisco Umbrella (DNS filtering) + Lightspeed Relay (HTTPS inspection)
- **Student VLAN:** All traffic → Lightspeed Relay → Cisco Umbrella DNS → Internet
- **Staff VLAN:** Less restrictive filtering (allows social media for professional development)
- **Guest VLAN:** Basic filtering (blocks illegal content, malware, phishing)

---

## DHCP Configuration

### DHCP Scopes (Windows Server DHCP)

```powershell
# VLAN 10 - Student Data
Add-DhcpServerv4Scope -Name "Student-Data" `
                      -StartRange 10.10.10.50 `
                      -EndRange 10.10.10.250 `
                      -SubnetMask 255.255.255.0 `
                      -LeaseDuration 8:00:00

Set-DhcpServerv4OptionValue -ScopeId 10.10.10.0 `
                            -DnsServer 10.10.10.2 `  # Filtered DNS
                            -Router 10.10.10.1

# VLAN 20 - Staff Data
Add-DhcpServerv4Scope -Name "Staff-Data" `
                      -StartRange 10.10.20.50 `
                      -EndRange 10.10.20.200 `
                      -SubnetMask 255.255.255.0 `
                      -LeaseDuration 24:00:00

Set-DhcpServerv4OptionValue -ScopeId 10.10.20.0 `
                            -DnsServer 10.10.30.10,10.10.30.11 `  # AD DNS
                            -Router 10.10.20.1

# VLAN 50 - Guest
Add-DhcpServerv4Scope -Name "Guest-BYOD" `
                      -StartRange 10.10.50.10 `
                      -EndRange 10.10.50.240 `
                      -SubnetMask 255.255.255.0 `
                      -LeaseDuration 4:00:00  # 4-hour timeout

Set-DhcpServerv4OptionValue -ScopeId 10.10.50.0 `
                            -DnsServer 8.8.8.8,1.1.1.1 `  # Public DNS
                            -Router 10.10.50.1
```

---

## Wireless Network Configuration

### SSID Design

| SSID Name | VLAN | Security | Target Users |
|-----------|------|----------|--------------|
| KISD-Student | 10 | WPA2-Enterprise (802.1X) | District-issued student devices |
| KISD-Staff | 20 | WPA2-Enterprise (802.1X + computer auth) | Staff laptops/desktops |
| KISD-Guest | 50 | Captive Portal (web-based) | Visitors, parents, contractors |
| KISD-BYOD | 50 | WPA2-PSK (pre-shared key, rotated quarterly) | Student personal phones |

### 802.1X Authentication (RADIUS)
- **RADIUS Server:** Windows NPS (Network Policy Server) on domain controller
- **Student Auth:** Username/Password (Active Directory student accounts)
- **Staff Auth:** Computer certificate + user credentials (stronger security)
- **Certificate Authority:** Internal CA for issuing device certificates

---

## Monitoring & Compliance Reporting

### Network Traffic Monitoring
- **NetFlow/sFlow:** Export from core switch to SolarWinds/PRTG for bandwidth analysis
- **SIEM Integration:** Send firewall logs to Splunk/Graylog for security event correlation
- **DNS Query Logging:** Cisco Umbrella reports for CIPA compliance audits

### Quarterly Reports (Required for E-Rate)
1. **CIPA Compliance Report:** Blocked category statistics, policy violation incidents
2. **Bandwidth Utilization:** Per-VLAN traffic analysis, identify capacity planning needs
3. **Security Incidents:** Malware blocks, intrusion attempts, policy violations
4. **Guest Network Usage:** Number of sessions, peak usage times, bandwidth consumption

---

## Disaster Recovery & Business Continuity

### Network Redundancy
- **Core Switch:** Dual switches in VSS (Virtual Switching System) or stacking
- **Firewall:** Active/standby HA (High Availability) pair with sub-second failover
- **DHCP/DNS:** Redundant servers on VLAN 30 (DC01, DC02)
- **Internet Connectivity:** Dual ISP links with automatic failover

### Backup Procedures
- **Configuration Backups:** Daily automated backups of switch/firewall configs to TFTP/FTP server
- **Change Management:** Document all VLAN/ACL changes with approval workflow
- **Disaster Recovery Plan:** Procedures for restoring network from backup configs within 2 hours

---

## Implementation Checklist

- [ ] Create VLANs 10, 20, 30, 40, 50 on core switch
- [ ] Configure Layer 3 SVI interfaces with IP addresses and DHCP helper-addresses
- [ ] Configure DHCP scopes on Windows Server DHCP
- [ ] Implement ACLs to restrict inter-VLAN traffic
- [ ] Configure DNS filtering (Cisco Umbrella or equivalent)
- [ ] Set up RADIUS server (Windows NPS) for 802.1X authentication
- [ ] Configure wireless SSIDs mapped to appropriate VLANs
- [ ] Test connectivity and access controls from each VLAN
- [ ] Deploy captive portal for guest network
- [ ] Configure firewall rules for internet access and inter-VLAN routing
- [ ] Enable logging and monitoring (NetFlow, SIEM integration)
- [ ] Document network topology and IP addressing scheme
- [ ] Train IT staff on VLAN troubleshooting and policy modifications

---

## Conclusion

This network segmentation design provides:
- **Security:** Isolation of student, staff, admin, IoT, and guest traffic
- **Compliance:** CIPA, FERPA, COPPA requirements met through filtering and access controls
- **Scalability:** VLAN structure supports growth and new device types
- **Manageability:** Centralized authentication (Active Directory) and monitoring
- **Performance:** Reduced broadcast domains, optimized traffic flows

**Next Steps:**
1. Review with district network team for site-specific customization
2. Conduct proof-of-concept in lab environment before production deployment
3. Schedule phased rollout during summer break to minimize disruption

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com
