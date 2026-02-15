# Keller ISD Systems Engineering Portfolio

This repository demonstrates technical capabilities directly relevant to the **Senior Systems Engineer (Microsoft)** position at Keller ISD, including enterprise Microsoft infrastructure administration, PowerShell automation, backup/disaster recovery, hardware management, and K-12 educational technology integration.

---

## Featured: KISD Identity Management Automation

I developed a PowerShell-based student/staff lifecycle management system using Keller ISD naming conventions (`students.keller.edu`), including:

- **Automated Azure AD/on-premises AD account provisioning** with grade-level and role-based organizational units
- **Grade-level OU structure** for students (9-12) with automatic graduation year tracking
- **Role-based staff access controls** (Teacher, Administrator, IT, Support Staff)
- **FERPA-compliant audit logging** for all identity lifecycle operations
- **Batch student onboarding** from CSV data sources (SIS integration ready)
- **Password policy enforcement** and account security controls

**Impact:** Reduces account provisioning time from 15 minutes to <1 minute per account, ensures naming consistency across hybrid AD environments, maintains compliance audit trails for educational data governance.

**[View KISDIdentity Module →](./K12-Identity-Management/)**

---

## Additional Technical Showcases

### [Veeam Backup & DR Automation](./Backup-DR-Automation/)
PowerShell runbooks for educational data protection, including SIS database backup management, disaster recovery testing procedures, and RTO/RPO strategies aligned with school operational calendars.

### [Dell iDRAC Hardware Management](./Dell-Hardware-Management/)
Enterprise server health monitoring and firmware lifecycle automation using Dell iDRAC REST API, designed for minimal downtime during instructional hours.

### [K-12 Network Segmentation](./K12-Network-Architecture/)
Security architecture for school environments with VLAN isolation, CIPA-compliant DNS filtering, and BYOD policies for student/staff devices.

---

## Technical Expertise

**Microsoft Enterprise Infrastructure:**
- Microsoft 365 (Exchange Online, SharePoint Online, Teams, OneDrive)
- Azure Active Directory / Entra ID (Conditional Access, MFA, RBAC)
- Intune endpoint management (Autopilot, compliance policies, application deployment)
- Windows Server (ADDS, DNS, DHCP, File Services, Failover Clustering)
- Virtualization (VMware vSphere, Hyper-V, HCI planning)

**Automation & Scripting:**
- PowerShell (modules, DSC, remoting, workflow automation)
- Python (system administration, API integration)
- Infrastructure-as-Code patterns for enterprise deployments

**Educational Technology:**
- K-12 identity and access management
- FERPA compliance and student data protection
- SIS/LMS integration patterns
- Educational network security (CIPA, COPPA, student internet safety)

---

## About

**Bryan Shaw**
22+ years enterprise IT experience | Microsoft Certified (AZ-104, pursuing AZ-800/801) | K-12 technology specialist

Experienced systems engineer with deep expertise in Microsoft enterprise infrastructure, PowerShell automation, and educational technology. Background includes designing secure, scalable systems for professional services, legal technology, and K-12 educational environments. Proven ability to reduce operational overhead through automation while maintaining security, compliance, and reliability.

**Contact:**
📧 BryanJShaw@gmail.com
📞 817-653-5656
🔗 [LinkedIn](https://www.linkedin.com/in/bryan-shaw-45a23124/)
💻 [GitHub Portfolio](https://github.com/FlyguyTestRun/)

---

## Repository Organization

```
Keller-ISD-Showcase/
├── K12-Identity-Management/     # KISD student/staff automation (PowerShell)
├── Backup-DR-Automation/        # Veeam backup management & DR testing
├── Dell-Hardware-Management/    # iDRAC server health monitoring
├── K12-Network-Architecture/    # Network security & VLAN segmentation
└── About.md                     # Detailed professional background
```

---

**Note:** All materials in this repository represent technical demonstrations and reference implementations. No production credentials, proprietary business logic, or confidential data are included.
