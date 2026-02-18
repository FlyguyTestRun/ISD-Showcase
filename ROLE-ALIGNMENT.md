# Role Alignment: Senior Systems Engineer + Senior Network Engineer

This document maps repository artifacts to capability areas commonly expected for senior systems and senior network roles in K-12 technology organizations.

## 1) Senior Systems Engineer Alignment

| Capability | Evidence in Repo |
|---|---|
| Identity lifecycle and AD operations | `K12-Identity-Management/` |
| Enterprise Microsoft operations context | `Microsoft-2026-Integrations.md` |
| Backup/DR process rigor | `Backup-DR-Automation/` |
| Server health and lifecycle management | `Dell-Hardware-Management/` |
| KPI reporting and service visibility | `Power-BI-Dashboards/` |
| Documentation and runbook quality | `README.md`, `HOW-TO-*`, `LESSONS-LEARNED.md` |

## 2) Senior Network Engineer Alignment

| Capability | Evidence in Repo |
|---|---|
| Segmentation architecture | `K12-Network-Architecture/KISD-Network-Segmentation.md` |
| VLAN + DHCP operational templates | `K12-Network-Architecture/VLAN-Configuration-Template.ps1` |
| Network compliance framing (FERPA/CIPA) | `K12-Network-Architecture/README.md` |
| Network observability concepts | `Power-BI-Dashboards/Network-Infrastructure-Monitoring/` |
| Cross-functional documentation | `K12-Network-Architecture/README.md` and architecture docs |

## 3) Senior-Level Team Impact Signals

- Repeatable workflows via scripts + sample data
- Knowledge-transfer-focused documentation
- Operational baselines that can be handed to support teams
- Practical use of KPI dashboards for leadership communication

## 4) Recommended Interview Talking Structure

1. **Problem:** Operational pain point (manual process, reliability risk, visibility gap)
2. **Approach:** Architecture + automation + documentation pattern
3. **Result:** Time saved, risk reduced, better service consistency
4. **Team Impact:** How juniors/support staff can execute and maintain the solution
