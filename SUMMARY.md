# Keller-ISD-Showcase Repository Summary

Targeted demonstration for Keller ISD Senior Systems Engineer position, I recreated this from training modules for teaching industry standard protocols. Sean this repository is a demonstration of understanding based on the best practices it would need to be tailored to district specified protocols (I know these are standards the district is already implementing). 

Thank you for your time and I look forward to discussing further. 

~Bryan.

---


**Repository Structure:**
```
Keller-ISD-Showcase/
├── README.md (Main portfolio overview)
├── About.md (Professional bio)
├── SUMMARY.md (This file)
├── Test-Syntax.ps1 (Validation script)
├── K12-Identity-Management/
│   ├── KISDIdentity.psm1 (161 lines)
│   ├── New-StudentBatch.ps1 (46 lines)
│   └── README.md (26 KB)
├── Backup-DR-Automation/
│   ├── Veeam-BackupManagement.ps1 (250 lines)
│   ├── Veeam-DRTesting.ps1 (420 lines)
│   └── README.md (18 KB)
├── Dell-Hardware-Management/
│   ├── iDRAC-HealthCheck.ps1 (380 lines)
│   ├── iDRAC-FirmwareUpdate.ps1 (350 lines)
│   └── README.md (15 KB)
└── K12-Network-Architecture/
    ├── KISD-Network-Segmentation.md (25 KB)
    ├── VLAN-Configuration-Template.ps1 (280 lines)
    └── README.md (12 KB)
```

## Repository Contents

### Main README.md
Professional overview highlighting:
- KISD Identity Management Automation
- Veeam Backup & DR Automation
- Dell iDRAC Hardware Management
- K-12 Network Segmentation
- Contact information and credentials

### 1. K12-Identity-Management/
Keller ISD-specific student/staff automation

**Files:**
- `KISDIdentity.psm1` - PowerShell module with Keller ISD naming conventions (`students.keller.edu`)
- `New-StudentBatch.ps1` - Batch student account creation from CSV
- `README.md` - Comprehensive documentation (26 KB)

**Highlights:**
- Grade-level OUs (9-12) with graduation year tracking
- FERPA-compliant audit logging

---

### 2. Backup-DR-Automation/

**Files:**
- `Veeam-BackupManagement.ps1` - Backup job automation, health checks, reporting (250 lines)
- `Veeam-DRTesting.ps1` - Comprehensive DR testing procedures (420 lines)
- `README.md` - K-12 backup/DR best practices (18 KB)

**Highlights:**
- K-12-optimized backup windows
- SIS database protection strategies
- RTO/RPO calculations for educational environments
- Summer break maintenance scheduling

---

### 3. Dell-Hardware-Management/
Dell iDRAC automation

**Files:**
- `iDRAC-HealthCheck.ps1` - Server health monitoring via iDRAC REST API (380 lines)
- `iDRAC-FirmwareUpdate.ps1` - Firmware lifecycle automation (350 lines)
- `README.md` - Enterprise server management guide (15 KB)

**Highlights:**
- Out-of-band management for remote campuses
- Proactive health monitoring (power, thermal, RAID status)
- Firmware update campaigns during school breaks
- K-12 maintenance windows (minimize instructional disruption)

---

### 4. K12-Network-Architecture/
Network segmentation and CIPA compliance expertise

**Files:**
- `KISD-Network-Segmentation.md` - Complete network architecture design (25 KB)
- `VLAN-Configuration-Template.ps1` - Automated DHCP/VLAN deployment (280 lines)
- `README.md` - Security architecture documentation (12 KB)

**Highlights:**
- 5-tier VLAN segmentation (Student, Staff, Admin, IoT, Guest)
- CIPA compliance implementation (DNS filtering, web proxy)
- Student internet safety (SafeSearch enforcement, content filtering)
- FERPA data protection (administrative systems isolated)

---

### 5. About.md
Professional biography including:
- 22+ years Microsoft infrastructure experience
- Current certifications (AZ-104, MD-102, AZ-800/801)
- CoreSkills4AI platform engineering work
- K-12 domain expertise
- Contact information

---




---

**NEXT ACTION:** Upload to GitHub and wait 3-5 days before sending email to Sean Ducar
