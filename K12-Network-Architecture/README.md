# K-12 Network Segmentation & Security Architecture

PowerShell automation and architectural documentation for secure K-12 network design with VLAN segmentation, CIPA compliance, and student data protection.

---

## Overview

This folder contains network architecture documentation and automation scripts for implementing secure, compliant network infrastructure in K-12 educational environments. The design prioritizes:

- **Student Internet Safety** (CIPA compliance via DNS filtering and web content filtering)
- **Network Segmentation** (VLANs isolate student, staff, admin, IoT, and guest traffic)
- **FERPA Data Protection** (administrative systems isolated from student-accessible networks)
- **BYOD Support** (guest network with captive portal, isolated from internal resources)
- **Operational Efficiency** (automated DHCP configuration, documentation generation)

---

## Files

### 1. `Network-Segmentation-Design.md`
**Purpose:** Comprehensive network architecture design document

**Contents:**
- **VLAN Design:** 5-tier segmentation (Student, Staff, Admin, IoT, Guest)
- **Security Architecture:** Firewall rules, ACLs, inter-VLAN routing policies
- **CIPA Compliance:** DNS filtering, web proxy configuration, SafeSearch enforcement
- **DHCP Configuration:** Scope design with appropriate lease durations per network tier
- **Wireless Networks:** SSID mapping to VLANs with 802.1X authentication
- **Monitoring & Reporting:** NetFlow, SIEM integration, quarterly compliance reports

**Key Highlights:**
- Student VLAN isolated from building systems (prevents access to IP cameras, HVAC)
- Guest network has internet-only access (no internal resource access)
- Administrative servers on dedicated VLAN with restricted access
- IoT devices cannot initiate connections to other VLANs (security best practice)

---

### 2. `VLAN-Configuration-Template.ps1`
**Purpose:** PowerShell automation for DHCP and network documentation

**Functions:**
- `New-K12DHCPScopes` - Creates DHCP scopes for all 5 VLANs with appropriate DNS servers and lease durations
- `New-K12DHCPReservations` - Assigns static DHCP reservations for critical infrastructure (servers, printers, cameras)
- `Export-K12NetworkDocumentation` - Generates comprehensive network documentation in Markdown format

**Example Usage:**
```powershell
# Deploy complete K-12 DHCP configuration
New-K12DHCPScopes -DHCPServer "DC01.kisd.local"

# Create static reservations for servers and network devices
New-K12DHCPReservations -DHCPServer "DC01.kisd.local"

# Generate network documentation
Export-K12NetworkDocumentation -OutputPath "C:\Documentation\KISD-Network-Config.md"
```

---

## VLAN Architecture Summary

| VLAN | Name | Network | Purpose | Security Level |
|------|------|---------|---------|----------------|
| 10 | Student-Data | 10.10.10.0/24 | Student devices, classroom tech | High filtering (CIPA) |
| 20 | Staff-Data | 10.10.20.0/24 | Teacher/staff workstations | Moderate filtering |
| 30 | Admin-Servers | 10.10.30.0/24 | Domain controllers, SIS, file servers | Restricted access |
| 40 | IoT-Building | 10.10.40.0/24 | IP cameras, HVAC, access control | Isolated (no internet) |
| 50 | Guest-BYOD | 10.10.50.0/24 | Visitor devices, BYOD | Internet-only access |

---

## Security Controls

### Student Network (VLAN 10)
- **DNS Filtering:** All queries routed through Cisco Umbrella (CIPA-compliant categories blocked)
- **Web Content Filtering:** HTTPS inspection via Lightspeed Relay (blocks adult content, anonymizers)
- **SafeSearch Enforcement:** DNS-level enforcement on Google, Bing, YouTube
- **Device Isolation:** Students cannot access other students' devices (AP isolation enabled)
- **Firewall Rules:** Internet access allowed, admin VLAN access restricted to file servers only

### Staff Network (VLAN 20)
- **Domain Authentication:** 802.1X with Active Directory credentials (computer + user auth)
- **Less Restrictive Filtering:** Allows social media and educational research sites
- **Group Policy Enforcement:** Windows Defender, BitLocker encryption, automatic updates
- **Full Admin Access:** Staff can access all administrative servers (SIS, file servers, printers)

### Administrative Network (VLAN 30)
- **No Direct Internet:** Servers access internet only via explicit firewall rules (Windows Update, licensing)
- **Role-Based Access:** Only IT staff and service accounts can connect
- **Audit Logging:** All access logged for FERPA compliance and security audits
- **Static IP Addressing:** All servers use static IPs or DHCP reservations

### IoT Network (VLAN 40)
- **Complete Isolation:** IoT devices cannot initiate connections to any other VLAN
- **No Student/Staff Access:** Only IT administrators can access IoT management interfaces
- **Limited Internet:** Firmware updates only, no general internet browsing
- **Further Segmentation:** Cameras on separate subnet from HVAC (defense in depth)

### Guest Network (VLAN 50)
- **Captive Portal:** Web-based terms of use acceptance before internet access
- **Internet-Only:** Zero access to internal VLANs (student, staff, admin, IoT)
- **Bandwidth Throttling:** 5 Mbps per device to prevent abuse
- **Session Timeout:** 4-hour automatic disconnection

---

## CIPA Compliance Implementation

### Children's Internet Protection Act (CIPA) Requirements
Schools receiving E-Rate funding must:
1. **Block obscene content** (pornography, violent content)
2. **Block content harmful to minors** (drugs, weapons, hate speech)
3. **Monitor online activities** (logging and reporting)
4. **Educate students** about appropriate online behavior

### Technical Implementation
**DNS-Based Filtering (Primary):**
- Student VLAN DHCP provides filtered DNS servers (Cisco Umbrella, Cloudflare Gateway for Families)
- All DNS queries logged for compliance reporting
- SafeSearch enforced on all major search engines

**Web Proxy (Secondary):**
- Lightspeed Relay or similar HTTPS inspection proxy
- SSL/TLS decryption with trusted CA certificate (deployed via MDM)
- Category blocking: Adult content, gambling, weapons, anonymizers/VPNs

**Time-Based Policies:**
- Social media blocked during instructional hours (7 AM - 3 PM)
- YouTube restricted mode enforced, educational channels whitelisted
- After-hours relaxation for extracurricular activities

---

## Deployment Guide

### Prerequisites
- Windows Server with DHCP Server role installed
- Layer 3 switch with VLAN support and inter-VLAN routing
- Firewall with stateful packet inspection and application control
- DNS filtering service (Cisco Umbrella, Cloudflare Gateway, or similar)
- 802.1X authentication infrastructure (RADIUS server, typically Windows NPS)

### Step 1: Create VLANs on Core Switch
```cisco
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
```

### Step 2: Configure Layer 3 Interfaces (SVIs)
```cisco
interface Vlan10
 description Student Data Network
 ip address 10.10.10.1 255.255.255.0
 ip helper-address 10.10.30.10
```
(Repeat for all VLANs)

### Step 3: Deploy DHCP Scopes via PowerShell
```powershell
Import-Module .\VLAN-Configuration-Template.ps1
New-K12DHCPScopes -DHCPServer "DC01.kisd.local"
New-K12DHCPReservations -DHCPServer "DC01.kisd.local"
```

### Step 4: Configure Firewall Rules
- Implement inter-VLAN access control lists (ACLs)
- Configure NAT for internet access
- Enable HTTPS inspection for student VLAN
- Set up VPN for remote IT administration

### Step 5: Configure Wireless SSIDs
| SSID | VLAN | Authentication | Usage |
|------|------|----------------|-------|
| KISD-Student | 10 | 802.1X (AD) | District-issued student devices |
| KISD-Staff | 20 | 802.1X (Computer + User) | Staff laptops/desktops |
| KISD-Guest | 50 | Captive Portal | Visitors, parents, contractors |

### Step 6: Testing & Validation
- [ ] Verify students cannot access staff file shares
- [ ] Verify staff can access SIS database and file servers
- [ ] Verify guests cannot access any internal resources
- [ ] Verify IoT devices are isolated from other VLANs
- [ ] Test DNS filtering (attempt to access blocked categories)
- [ ] Validate 802.1X authentication on wireless networks

---

## Monitoring & Compliance

### Daily Monitoring
- DHCP lease exhaustion alerts (low available IPs in student VLAN)
- Firewall rule violation alerts (unauthorized access attempts)
- DNS filtering alerts (blocked content access attempts)

### Weekly Reports
- Bandwidth utilization per VLAN (identify capacity planning needs)
- Top blocked categories (CIPA compliance documentation)
- Security incidents (malware, intrusion attempts)

### Quarterly Compliance Reports (E-Rate Requirement)
- Total blocked requests by category
- Student internet usage statistics
- Policy violation incidents and remediation
- Network infrastructure changes and updates

---

## Troubleshooting

### Common Issues

**Students cannot access internet:**
- Check DNS server configuration in DHCP scope (should be filtered DNS)
- Verify firewall allows VLAN 10 → Internet (ports 80, 443)
- Check content filter status (Cisco Umbrella dashboard)

**Staff cannot access file servers:**
- Verify VLAN 20 → VLAN 30 firewall rules allow SMB (port 445)
- Check domain authentication (user must be in correct AD security groups)
- Verify DNS resolution for file server hostnames

**Guest network not working:**
- Check captive portal configuration (web server reachable?)
- Verify VLAN 50 firewall rules allow outbound internet only
- Test DHCP scope has available IPs (check lease status)

**IoT devices cannot communicate:**
- Verify VLAN 40 devices are on correct subnet
- Check firewall rules (IoT should be isolated from other VLANs)
- Confirm static IPs or DHCP reservations configured correctly

---

## Additional Resources

- [CIPA Compliance Guidelines (FCC)](https://www.fcc.gov/consumers/guides/childrens-internet-protection-act)
- [CoSN K-12 Network Security Framework](https://www.cosn.org/)
- [NIST Cybersecurity Framework for Education](https://www.nist.gov/cyberframework)
- [Cisco K-12 Network Design Guide](https://www.cisco.com/c/en/us/solutions/industries/education.html)

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com
**Purpose:** K-12 network architecture reference implementation
