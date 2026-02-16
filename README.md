# K-12 Systems Engineering

This repository demonstrates enterprise Microsoft infrastructure administration, PowerShell automation, data analytics, and educational technology suitable for K-12 school district environments.

---

## Featured Capabilities

### [K-12 Identity Management Automation](./K12-Identity-Management/)
PowerShell-based student/staff lifecycle management system with automated Azure AD and on-premises Active Directory provisioning:

- **Automated account provisioning** with grade-level and role-based organizational units
- **Grade-level OU structure** for students (9-12) with automatic graduation year tracking
- **Role-based staff access controls** (Teacher, Administrator, IT, Support Staff)
- **FERPA-compliant audit logging** for all identity lifecycle operations
- **Batch student onboarding** from CSV data sources (SIS integration ready)
- **Password policy enforcement** and account security controls

**Impact:** Reduces account provisioning time to under 1 minute per account, ensures naming consistency across hybrid AD environments, maintains compliance audit trails for educational data governance.

---

### [Power BI Dashboards for IT Operations](./Power-BI-Dashboards/)
Data visualization and analytics dashboards for IT infrastructure monitoring and capacity planning:

- **IT Infrastructure Health Dashboard** - Active Directory metrics, backup success rates, endpoint compliance tracking
- **Student Enrollment Analytics** - Enrollment trends, account provisioning velocity, FERPA compliance metrics
- **Network Infrastructure Monitoring** - DHCP utilization, device inventory (439+ devices), campus connectivity

**Impact:** Provides leadership visibility into technology operations, enables proactive issue detection, supports data-driven capacity planning, and automates compliance reporting.

---

### [Veeam Backup & DR Automation](./Backup-DR-Automation/)
PowerShell runbooks for educational data protection:

- SIS database backup management with K-12 optimized schedules
- Disaster recovery testing procedures with RTO/RPO validation
- Automated backup health checks and reporting
- School calendar-aligned maintenance windows

**Impact:** Ensures data protection for critical educational systems, reduces manual backup verification time, provides automated alerting for backup failures.

---

### [Dell iDRAC Hardware Management](./Dell-Hardware-Management/)
Enterprise server health monitoring and firmware lifecycle automation:

- REST API integration for Dell PowerEdge servers
- Proactive hardware health monitoring (power, thermal, storage, RAID)
- Automated firmware update orchestration
- Maintenance scheduling designed for minimal instructional impact

**Impact:** Reduces server downtime through proactive monitoring, automates firmware lifecycle management, enables out-of-band management for remote campuses.

---

### [K-12 Network Segmentation Architecture](./K12-Network-Architecture/)
Security architecture for educational environments:

- 5-tier VLAN design (Student, Staff, Admin, IoT, Guest)
- CIPA-compliant DNS filtering and content controls
- BYOD policies and secure student device management
- Network segmentation for FERPA data protection

**Impact:** Ensures student internet safety compliance, isolates administrative systems, supports secure BYOD programs, provides foundation for network capacity planning.

---

## Technical Expertise

**Microsoft Enterprise Infrastructure:**
- Microsoft 365 (Exchange Online, SharePoint Online, Teams, OneDrive)
- Azure Active Directory / Entra ID (Conditional Access, MFA, RBAC)
- Intune endpoint management (Autopilot, compliance policies, application deployment)
- Windows Server (ADDS, DNS, DHCP, File Services, Failover Clustering)
- Virtualization (VMware vSphere, Hyper-V, HCI planning)

**Data Analytics & Visualization:**
- Power BI (dashboards, DAX measures, data modeling, scheduled refresh)
- Operational analytics for IT infrastructure monitoring
- Compliance reporting and audit trail visualization
- Capacity planning and trend analysis

**Automation & Scripting:**
- PowerShell (modules, DSC, remoting, workflow automation, REST API integration)
- Python (system administration, data processing, API integration)
- Infrastructure-as-Code patterns for enterprise deployments
- Automated data collection and reporting pipelines

**Educational Technology:**
- K-12 identity and access management
- FERPA compliance and student data protection
- SIS/LMS integration patterns
- Educational network security (CIPA, COPPA, student internet safety)

---

## About

**Bryan Shaw**
22+ years enterprise IT experience | Microsoft Certified (AZ-104, MD-102, AZ-800/801) | K-12 technology specialist

Experienced systems engineer with expertise in Microsoft enterprise infrastructure, PowerShell automation, data analytics, and educational technology. Background includes designing secure, scalable systems for professional services, legal technology, and consulting in sever sectors and secure data environments. Proven ability to reduce operational overhead through automation while maintaining security, compliance, and reliability.

**Contact:**
📧 BryanJShaw@gmail.com
📞 817-653-5656
🔗 [LinkedIn](https://www.linkedin.com/in/bryan-shaw-45a23124/)
💻 [GitHub Portfolio](https://github.com/FlyguyTestRun/)

---

## Repository Organization

```
ISD-Showcase/
├── K12-Identity-Management/        # Student/staff identity automation (PowerShell)
├── Power-BI-Dashboards/            # IT operations analytics and visualization
├── Backup-DR-Automation/           # Veeam backup management & DR testing
├── Dell-Hardware-Management/       # iDRAC server health monitoring
├── K12-Network-Architecture/       # Network security & VLAN segmentation
├── About.md                        # Detailed professional background
└── SUMMARY.md                      # Repository overview and highlights
```

---

**Note:** All materials in this repository represent technical demonstrations and reference implementations. No production credentials, proprietary business logic, or confidential data are included.
