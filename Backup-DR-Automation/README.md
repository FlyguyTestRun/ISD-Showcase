# Veeam Backup & Disaster Recovery Automation

PowerShell automation for K-12 data protection, DR testing, and compliance reporting. The real operational record is in [LESSONS-LEARNED.md](./LESSONS-LEARNED.md), 8 documented failure scenarios with root cause and fix.

---

## Files

### `Veeam-BackupManagement.ps1`
Core backup job management and monitoring. Key functions:
- `New-VeeamBackupJob`: creates backup jobs with K-12 optimized settings (after-hours windows, tiered retention)
- `Test-VeeamBackupIntegrity`: verifies backup health, repository capacity, restore point validity
- `Start-VeeamDRTest`: orchestrates isolated DR testing without production impact
- `Export-VeeamBackupReport`: generates HTML/CSV compliance reports for IT leadership

### `Veeam-DRTesting.ps1`
DR test procedures aligned to school calendar break windows. Key functions:
- `Invoke-SISDatabaseDRTest`: SQL Server SIS database recovery validation (RTO/RPO)
- `Invoke-DomainControllerDRTest`: AD domain controller non-authoritative restore test
- `Invoke-FileServerDRTest`: student/staff home directory recovery with permission validation
- `Start-ComprehensiveDRTest`: full DR test suite with consolidated HTML report

### `Backup-DR-Architecture.md`
Infrastructure layout, site topology, and test execution timestamps. The DR test records here are the operational proof, not hypothetical.

### `LESSONS-LEARNED.md`
8 documented backup/DR failures with root cause and resolution. This is the file to read if you want to know how this work actually runs under pressure.

---

## K-12 Operational Constraints

### Backup Windows
School calendar drives everything. Backups run 6 PM to 6 AM, hard stop before first bell. Weekend full backups run Saturday nights. Summer break is the window for large-scale DR drills and infrastructure maintenance that can't touch instructional hours.

### Retention Tiers
| System | Retention | Rationale |
|--------|-----------|-----------|
| SIS Database | 14 days | Grade recovery, audit requests, enrollment corrections |
| Domain Controllers | 7 days | Rapid AD recovery, low storage overhead |
| Student File Servers | 30 days | Covers "I deleted my project" scenarios through grading windows |
| Administrative Systems | 14 days | Budget cycles, compliance documentation |

### Recovery Objectives
| System | RTO | RPO |
|--------|-----|-----|
| SIS, Domain Controllers | <30 min | <24 hrs |
| File Servers | <2 hrs | <24 hrs |
| Administrative Systems | <4 hrs | <24 hrs |

SIS and DC recovery targets are hard constraints, authentication failures during instructional hours have district-wide impact. At 23,000 managed Windows 11 devices authenticating against domain infrastructure, an AD outage during school hours is not a minor incident.

---

## Compliance Reporting

Monthly backup reports cover: job success rates (target >95%), storage utilization, critical system backup recency (<24 hours for SIS), and failed job root cause.

Quarterly DR test reports document: RTO validation, RPO assessment, application validation (SIS login, AD auth, file access), and infrastructure recommendations.

FERPA requires 7-year audit log retention for student data operations; backup job logs and DR test records fall under this requirement.

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com
