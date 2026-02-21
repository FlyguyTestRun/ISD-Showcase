# K-12 Network Segmentation and Security Architecture

Network segmentation design and DHCP automation for a multi-campus K-12 district. The architecture follows the segmentation model common across large Texas ISDs: separate VLANs for students, staff, administrative systems, IoT/building controls, and guest/BYOD, with CIPA-compliant filtering on student traffic.

---

## VLAN Design

| VLAN | Name | Network | Purpose | Filtering |
|------|------|---------|---------|-----------|
| 10 | Student-Data | 10.10.10.0/24 | Student devices, classroom tech | CIPA-compliant (Umbrella or equivalent) |
| 20 | Staff-Data | 10.10.20.0/24 | Teacher and staff workstations | Standard policy filtering |
| 30 | Admin-Servers | 10.10.30.0/24 | Domain controllers, SIS, file servers | Restricted access only |
| 40 | IoT-Building | 10.10.40.0/24 | Cameras, HVAC, access control | Isolated, no lateral movement |
| 50 | Guest-BYOD | 10.10.50.0/24 | Visitor devices, personal devices | Internet-only, captive portal |

Five-tier segmentation handles the two compliance requirements that matter in K-12: CIPA on student internet access and FERPA isolation for systems handling student records.

---

## Security Controls by Segment

**Student (VLAN 10)**
- DNS filtering via Cisco Umbrella or comparable service (CIPA required categories blocked)
- HTTPS inspection proxy for content enforcement (Lightspeed or equivalent)
- SafeSearch enforcement at DNS level for Google, Bing, YouTube
- AP client isolation prevents device-to-device traffic on student wireless
- Access to admin VLAN restricted to specific file server shares only

**Staff (VLAN 20)**
- 802.1X authentication against Entra ID or on-prem AD via NPS/RADIUS
- Group Policy enforces Defender, BitLocker, and patch compliance on domain-joined devices
- In a Meraki environment, staff SSID maps to VLAN 20 with 802.1X configured at the MR AP level
- Aruba ClearPass handles the same function in Aruba deployments; Cisco ISE in ISE-based environments

**Admin Servers (VLAN 30)**
- No direct internet access; outbound filtered to Windows Update, licensing, and approved services only
- IT staff and service accounts only; role-based access enforced through AD group membership
- All access logged for FERPA audit compliance
- Static IP or DHCP reservation for all servers

**IoT/Building (VLAN 40)**
- No outbound internet except firmware update endpoints
- Cameras on a separate subnet from HVAC within the IoT range (defense in depth)
- IT administrative access only; no student or staff device access to this segment

**Guest/BYOD (VLAN 50)**
- Captive portal with terms of use before internet access
- Zero routing to any internal VLAN
- Per-device bandwidth cap (5 Mbps) and session timeout (4 hours)

---

## Wireless Architecture

Wireless SSIDs map directly to VLANs. In Meraki-managed deployments this is configured per SSID in the Meraki dashboard with VLAN tagging at the MR level. Aruba and traditional Cisco WLC deployments follow the same logical model with platform-specific configuration.

| SSID | VLAN | Auth | Notes |
|------|------|------|-------|
| KISD-Student | 10 | 802.1X or MAB | District-managed student devices |
| KISD-Staff | 20 | 802.1X (user + computer) | Domain-joined staff devices |
| KISD-Guest | 50 | Captive portal | Visitors, parents, contractors |

At KISD scale (850+ access points across 40+ campuses), wireless controller health and AP client counts are tracked in the Network Infrastructure Monitoring dashboard.

---

## CIPA Compliance

Schools receiving E-Rate funding must block obscene and harmful content, log internet activity, and educate students on appropriate use. The technical implementation here addresses the blocking and logging requirements:

- Student VLAN DHCP assigns filtered DNS (Cisco Umbrella, Cloudflare Gateway, or district-managed DNS with RPZ)
- All DNS queries logged; category blocking enforced at DNS and proxy layers
- Time-based policies lock social media during instructional hours
- YouTube restricted mode enforced via DNS-level header injection or proxy policy

FERPA compliance is handled through VLAN isolation: SIS databases and student records systems sit on VLAN 30, unreachable from student or guest segments without explicit firewall permit rules.

---

## Automation Script

`VLAN-Configuration-Template.ps1` handles DHCP scope deployment and network documentation generation via PowerShell:

- `New-K12DHCPScopes` creates scopes for all five VLANs with appropriate lease durations and DNS server assignments
- `New-K12DHCPReservations` creates static DHCP reservations for servers, printers, and network devices
- `Export-K12NetworkDocumentation` generates a Markdown documentation file from current DHCP configuration

The scripts target Windows Server DHCP and are built for repeatability across campuses. New campus onboarding runs the same scripts with campus-specific parameters.

---

## Monitoring

Daily: DHCP lease exhaustion alerts on student VLAN, firewall rule violation alerts, DNS filtering alert volume.

Weekly: Bandwidth utilization per VLAN, top blocked content categories (CIPA documentation), security incident summary.

Quarterly: E-Rate compliance report covering blocked requests by category, policy violations and remediation, infrastructure change log.

Network device health and uptime tracked in [Network-Infrastructure-Monitoring dashboard](../Power-BI-Dashboards/Network-Infrastructure-Monitoring/).

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com
