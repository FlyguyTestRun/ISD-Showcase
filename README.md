# K-12 Systems Engineering Portfolio

Engineering portfolio calibrated to the ISD's operating environment: estimated: 34,000 students, 23,000 Windows 11 devices managed via Autopilot and Intune, Entra ID at full district scale, M365 A5, and Canvas as the learning management system. API integrations and automations are a huge strength of mine and a main function of how I create dashboards for clients, excited to assist in these integrations with Power BI Pro. The focus of this repo is for demonstrative purpose of familiarity of operational needs and depth of identity lifecycle, network segmentation, backup and DR under calendar constraints, and KPI dashboards built for leadership review as a sample showcase of live direct reporting metrics for the presentation purpose of this repo they are backed up to .PNG and .PDF files not live, the files are stored within the repo and can be opened into Power BI to see the automations of this sandbox environment.

---

## Dashboards

Four operational KPI dashboards covering enrollment trends, identity provisioning velocity, Autopilot device deployment, and campus capacity. Built at KISD-approximate scale (34,000 students, 23,000 managed devices, 22+ campuses).

[Full PDF export](./Power-BI-Dashboards/Dashboards/KISD-Dashboards.pdf) | [Power-BI-Dashboards/](./Power-BI-Dashboards/) for data model and additional dashboards

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

---

## Lessons Learned

[Backup-DR-Automation/LESSONS-LEARNED.md](./Backup-DR-Automation/LESSONS-LEARNED.md): 8 documented operational failures with root cause and fix for each. Retention misconfiguration, backup jobs overrunning into school hours, DR testing on a live network, six months of silent backup failures. The things that actually go wrong in production environments.

---

## Professional Profile

**Bryan Shaw** | AZ-104, MD-102 | AZ-800/801
BryanJShaw@gmail.com | 817-653-5656 | [LinkedIn](https://www.linkedin.com/in/bryan-shaw-45a23124/) | [GitHub](https://github.com/FlyguyTestRun/) | [About](./About.md)

24+ years in enterprise Microsoft infrastructure across legal technology, professional services, and education-aligned operations. Full background and skills profile: [About.md](./About.md).

---

## Note on Mock Data

All data is demonstrative at district-approximate scale (34,000 students, 23,000 managed devices, multi-campus). No production credentials, real district data, or proprietary client information.
