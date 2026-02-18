# K-12 Systems Engineering Portfolio

This repository demonstrates enterprise Microsoft systems engineering, network architecture, infrastructure automation, and operational analytics for K-12 district environments.

It is designed as a practical, hands-on showcase for **Systems Engineering** and **Networking** responsibilities: stable operations, secure architecture, proactive monitoring, documentation quality, and cross-team enablement. *This repository was built from a CoreSkills training module for enteprise systems migration from full SaaS to hybrid SaaS/PaaS implementations.

## Reasoning for the Module

As a consultant I have migrated several stakeholders to hybrid systems architecture when they reached a growth point that created a cost saving return. Building applications and cost saving ROIs within 3-6 months of execution. This module was built to help guide mid size market companies to cost saving alterntatives.

---

## What This Portfolio Demonstrates

### Systems Engineering Implementation
- Microsoft 365 + Entra ID + Intune-aligned operations
- Windows Server / Active Directory automation and lifecycle management
- Veeam backup/DR operational runbooks and validation patterns
- Dell PowerEdge/iDRAC health and firmware lifecycle automation
- KPI-driven operations reporting with Graphana and Power BI automated dashboards

### With Network Architecture Depth
- VLAN segmentation with network security design
- CIPA/FERPA-aware policy architecture and access boundaries
- DHCP scope planning, network documentation automation, and health reporting
- Multi-campus network monitoring concepts for capacity and reliability

### Leadership & Mentoring
- Step-by-step implementation guides and runbooks
- Lessons learned and operational guardrails
- Repeatable demos using synthetic sample data
- Documentation intended for onboarding and support handoff

---

## Portfolio Sections

### [Identity Management Automation](./K12-Identity-Management/)
PowerShell-based student/staff lifecycle management with automated provisioning patterns and FERPA-compliant logging.

**Highlights**
- Grade-level OU design (9–12) and graduation-year tracking
- Role-based account provisioning for staff personas
- Batch onboarding from CSV (SIS export ready)
- Auditability and operational consistency

---

### [Dashboards for IT Operations](./Power-BI-Dashboards/)
Automated Power BI dashboards that visualize infrastructure health, enrollment/account trends, and network utilization.

**Highlights**
- IT health metrics (AD, backup success, endpoint compliance)
- Enrollment and identity lifecycle visibility
- Network device and DHCP utilization monitoring
- Leadership-friendly KPI reporting models

---

### Backup & DR Automation](./Backup-DR-Automation/)
Operational scripts and runbooks for backup management, DR readiness checks, and environment recovery planning.

---

### [Hardware Management](./Dell-Hardware-Management/)
iDRAC REST API automation for proactive server health checks and firmware maintenance workflow support.

---

### [Network Segmentation Architecture](./K12-Network-Architecture/)
Secure network architecture and automation templates for student/staff/admin/IoT/guest segmentation.

---

## Role Alignment Snapshot

| Job Capability Area | Portfolio Evidence |
|---|---|
| Active Directory / Identity lifecycle | `K12-Identity-Management/` |
| Microsoft platform operations + reporting | `Power-BI-Dashboards/`, `Microsoft-2026-Integrations.md` |
| Backup, DR, recovery validation | `Backup-DR-Automation/` |
| Server platform lifecycle (Dell) | `Dell-Hardware-Management/` |
| Network architecture, segmentation, compliance | `K12-Network-Architecture/` |
| Team enablement / mentoring evidence | `HOW-TO-*`, `LESSONS-LEARNED.md`, architectural docs |

---

## Technical Focus Areas

**Microsoft Infrastructure:** M365, Entra ID, Intune, Windows Server, ADDS, DNS, DHCP, hybrid identity patterns.

**Network Architecture:** VLAN segmentation, ACL strategy, CIPA controls, K-12 security zoning, multi-campus operational visibility.

**Automation & Scripting:** PowerShell modules and runbooks, API-based workflows, repeatable data generation, implementation templates.

**Operational Analytics:** Power BI dashboards, KPI framing, trend analysis, compliance and service health reporting.

---

## Professional Profile

**Bryan Shaw**  
22+ years enterprise IT experience | Microsoft Certified (AZ-104, MD-102) | AZ-800/801 in progress

I focus on building reliable systems, reducing manual workload through automation, and creating clear documentation that helps teams operate consistently under real-world constraints.

**Contact**
- 📧 BryanJShaw@gmail.com
- 📞 817-653-5656
- 🔗 [LinkedIn](https://www.linkedin.com/in/bryan-shaw-45a23124/)
- 💻 [GitHub Portfolio](https://github.com/FlyguyTestRun/)

---

## Repository Structure

```text
ISD-Showcase/
├── K12-Identity-Management/        # Student/staff identity automation (PowerShell)
├── Power-BI-Dashboards/            # IT operations analytics and dashboards
├── Backup-DR-Automation/           # Veeam backup orchestration + DR testing
├── Dell-Hardware-Management/       # iDRAC health and firmware management
├── K12-Network-Architecture/       # K-12 segmentation and security architecture
├── ROLE-ALIGNMENT.md               # Systems vs Network requirement mapping
├── TRAINING-ENABLEMENT.md          # Mentoring and onboarding-focused artifacts
├── About.md                        # Detailed background and experience
└── SUMMARY.md                      # Executive portfolio summary
```

---

**Note:** All content is demonstrative and excludes production credentials, confidential data, and proprietary client IP.
