# K-12 Systems Engineering Portfolio

24+ years in Microsoft infrastructure — legal technology, professional services, and education-aligned consulting. The patterns in this repo came from real enterprise operational work: identity lifecycle management, network segmentation, backup and DR under school-calendar constraints, and KPI reporting built for leadership review. This portfolio is calibrated to district's current stack and scale — 34,000 students, 23,000 Windows 11 devices managed via Autopilot and Intune, Entra ID at full district scale, M365 A5, and Canvas as the LMS.

The focus is operating and extending what's already built — not designing from scratch.

---

## What's Here

| Section | What it covers |
|---------|----------------|
| [K12-Identity-Management/](./K12-Identity-Management/) | Entra ID + PowerShell identity ops at district scale |
| [Backup-DR-Automation/](./Backup-DR-Automation/) | Veeam automation, DR architecture, and 8 real failure post-mortems |
| [Microsoft-Cloud-Operations/](./Microsoft-Cloud-Operations/) | Operational scripts: Entra risk, Intune compliance, M365 service health, Autopilot status |
| [Power-BI-Dashboards/](./Power-BI-Dashboards/) | KPI dashboards scaled to district profile |
| [K12-Network-Architecture/](./K12-Network-Architecture/) | Multi-campus VLAN segmentation and security architecture |
| [Dell-Hardware-Management/](./Dell-Hardware-Management/) | iDRAC/Redfish server health and firmware lifecycle automation |
| [Network-Operations-Playbooks/](./Network-Operations-Playbooks/) | Change window, RCA, and monitoring baseline templates |
| [Mentoring-Case-Studies.md](./Mentoring-Case-Studies.md) | Real mentoring scenarios with operational specifics |

**Dashboard Exports (PDF — click filename, then Download to view)**
- [KISD Dashboards — All 4 Pages](./Power-BI-Dashboards/Dashboards/KISD-Dashboards.pdf) — Enrollment, Provisioning, Device Assignment, Campus Capacity
- [IT Infrastructure Health](./Power-BI-Dashboards/IT-Infrastructure-Health/IT-Infrastructure-Dashboard.pdf)
- [Network Infrastructure Monitoring](./Power-BI-Dashboards/Network-Infrastructure-Monitoring/Network-Infrastructure-Dashboard.pdf)
- [Student Enrollment Analytics](./Power-BI-Dashboards/Student-Enrollment-Analytics/Student-Enrollment-Dashboard.pdf)

---

## Lessons Learned

[Backup-DR-Automation/LESSONS-LEARNED.md](./Backup-DR-Automation/LESSONS-LEARNED.md) — 8 documented operational failures (retention misconfiguration, backup jobs running during school hours, DR testing on a live network, 6 months of silent backup failures) with the root cause and fix for each, the things that go wrong in real environments.

---

## Professional Profile

**Bryan Shaw** | AZ-104, MD-102 | AZ-800/801
BryanJShaw@gmail.com | 817-653-5656 | [LinkedIn](https://www.linkedin.com/in/bryan-shaw-45a23124/) | [GitHub](https://github.com/FlyguyTestRun/)

My background is in enterprise Microsoft infrastructure across legal SEG, SGPB  & Lanier Law firms (Dallas) technology (AGP, AO1, Trial IT & CoreSkills) and professional services. The K-12 operational patterns in this portfolio (past MISD work @ performance art center via A01) mirror the identity lifecycle design, FERPA/CIPA compliance controls, enrollment-cycle automation were developed through consulting projects (both legal and at Mansfield) mirroring ISD infrastructure directly aligned with educational technology environments. The same engineering discipline that protects sensitive client data in legal operations translates directly to protocols protecting student data at scale.

---

## Note on Mock Data

All data is demonstrative at district-approximate scale (34,000 students, 23,000 managed devices, multi-campus). No production credentials, real district data, or proprietary client information.

---

