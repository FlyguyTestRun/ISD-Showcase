# Backup & Disaster Recovery Architecture

## Backup Data Flow Topology

### Production to Backup Repository Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Production Environment                        │
│                      (vSphere Cluster)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  SQL-SIS01   │  │    DC01      │  │FS-Students01 │         │
│  │(SIS Database)│  │ (Domain Ctrl)│  │(File Server) │         │
│  │  500 GB      │  │   100 GB     │  │   2.4 TB     │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │                  │                  │
          │  VMware CBT      │  VSS Snapshot    │  File-level
          │  (Changed Blocks)│  (App-Aware)     │  Incremental
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│              Veeam Backup Proxy (HotAdd Mode)                   │
│                    10.100.30.135                                 │
│                    (Admin VLAN 30)                               │
│                                                                  │
│  Resources: 4 vCPU, 16 GB RAM                                   │
│  Transport: Virtual Appliance (SCSI HotAdd)                     │
│  Concurrent Tasks: 4 VMs simultaneous                           │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       │ 10 Gbps Network (Dedicated Backup VLAN)
                       │ Deduplication + Compression (5:1 ratio)
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│            Primary Backup Repository (ReFS)                      │
│                    \\BACKUP-REPO01\Backups                       │
│                    10.100.60.10                                  │
│                                                                  │
│  Storage: 50 TB ReFS volume (75% utilized)                      │
│  Retention: 14 restore points                                   │
│  Features: Fast Clone (synthetic full in <5 min)                │
│            Per-VM backup chains                                  │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       │ Backup Copy Job (Nightly)
                       │ WAN Acceleration Enabled
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│          Secondary Backup Repository (Offsite)                   │
│            \\DR-SITE\VeeamBackups                                │
│            10.200.60.10 (DR Site)                                │
│                                                                  │
│  Storage: 30 TB                                                  │
│  Retention: 30 restore points (long-term compliance)            │
│  Purpose: Geographic redundancy (50 miles from primary)         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Backup Job Statistics (From Power BI Dashboard)

### Critical Systems Backup Status

```
Total Backup Jobs: 12
├─ Successful: 11 jobs (91.7%)
├─ Warning: 1 job (8.3% - long runtime)
└─ Failed: 0 jobs

Total Restore Points: 240
├─ SIS Database: 28 restore points (14-day retention × 2 daily backups)
├─ Domain Controllers: 14 restore points (14-day retention)
├─ File Servers: 14 restore points (14-day retention)
└─ Application Servers: 184 restore points (various retention policies)

Success Rate (90 days): 95.83%
├─ Successful backups: 230/240
├─ Failed backups: 10/240 (4.17%)
└─ Failure reasons:
    ├─ Snapshot timeout (5 failures - resolved with extended VSS timeout)
    ├─ Repository space full (3 failures - added capacity)
    └─ Network timeout (2 failures - WAN link saturation during peak hours)

Storage Utilization:
├─ Primary Repository: 37.5 TB / 50 TB (75% used)
├─ Secondary Repository: 18 TB / 30 TB (60% used)
└─ Compression Ratio: 4.8:1 (typical for VM backups)
   ├─ Source data: ~180 TB
   └─ Backup storage: ~38 TB (after compression + deduplication)
```

---

## Backup Schedule Matrix

### Daily Backup Windows

| System | Backup Time | Type | Duration | Retention | Success Rate |
|--------|-------------|------|----------|-----------|--------------|
| **SIS Database** | 10:00 PM | Incremental | 15 min | 14 days | 100% |
| **Domain Controllers** | 10:30 PM | Incremental | 8 min | 14 days | 98% |
| **File Server (Staff)** | 11:00 PM | Incremental | 45 min | 30 days | 96% |
| **File Server (Students)** | 12:00 AM | Incremental | 2 hr 15 min | 30 days | 92% (⚠️ long runtime) |
| **Exchange Server** | 1:00 AM | Incremental | 25 min | 14 days | 100% |
| **Application Servers** | 2:00 AM | Incremental | 30 min | 7 days | 98% |
| **Workstation VDI Pool** | 3:00 AM | Incremental | 20 min | 7 days | 95% |

**Weekend Full Backups:**
- Saturday 8:00 PM: Synthetic full backups for all jobs
- Duration: 3-5 hours (leverages ReFS fast cloning)
- Success Rate: 98% (2% failures due to storage latency during large operations)

---

## Disaster Recovery Testing Results

### Quarterly DR Test Summary (Based on Veeam-DRTesting.ps1 Execution)

#### Q4 2024 DR Test (December 2024 - Winter Break)

```
Test Date: December 26, 2024 (Winter Break)
Test Duration: 3 hours 42 minutes
Test Environment: Isolated DR Test Network (VLAN 100)
Test Coordinator: IT Director

┌───────────────────────────────────────────────────────────────┐
│               SIS Database Recovery Test                      │
├───────────────────────────────────────────────────────────────┤
│ Test VM: SQL-SIS01-DRTest                                     │
│ Restore Point Age: 24 hours old                               │
│ Recovery Time: 8 minutes 32 seconds                           │
│ Recovery Objective (RTO): <30 minutes ✅ MET                  │
│ Data Loss (RPO): 24 hours (last nightly backup) ✅ MET        │
│ Database Integrity: PASS (DBCC CHECKDB: 0 errors)            │
│ Application Validation:                                       │
│   ├─ SQL Server: ONLINE ✅                                    │
│   ├─ Student count query: 4,832 students ✅                   │
│   ├─ Staff count query: 387 staff ✅                          │
│   └─ Grade data validation: PASS ✅                           │
│ Status: SUCCESS ✅                                             │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│            Domain Controller Recovery Test                    │
├───────────────────────────────────────────────────────────────┤
│ Test VM: DC01-DRTest                                          │
│ Restore Type: Non-Authoritative (multi-DC environment)        │
│ Recovery Time: 6 minutes 18 seconds                           │
│ Recovery Objective (RTO): <30 minutes ✅ MET                  │
│ Validation:                                                    │
│   ├─ Active Directory: ONLINE ✅                              │
│   ├─ LDAP connectivity: PASS ✅                               │
│   ├─ Kerberos authentication: PASS ✅                         │
│   ├─ DNS resolution: PASS ✅                                  │
│   ├─ SYSVOL replication: HEALTHY ✅                           │
│   └─ Test user login: SUCCESS ✅                              │
│ Status: SUCCESS ✅                                             │
└───────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────┐
│              File Server Recovery Test                        │
├───────────────────────────────────────────────────────────────┤
│ Test VM: FS-Students01-DRTest                                 │
│ Data Volume: 2.4 TB (1,247,832 files)                        │
│ Recovery Time: 42 minutes 15 seconds                          │
│ Recovery Objective (RTO): <2 hours ✅ MET                     │
│ Validation:                                                    │
│   ├─ File count verification: 1,247,832 files ✅              │
│   ├─ NTFS permissions: INTACT ✅                              │
│   ├─ Shares: \\\\FS-Students01\\Students$ ONLINE ✅          │
│   ├─ Student folder access: PASS (isolation verified) ✅      │
│   └─ DFS namespace: RECOVERED ✅                              │
│ Status: SUCCESS ✅                                             │
└───────────────────────────────────────────────────────────────┘

Overall DR Test Results:
├─ Tests Passed: 3/3 (100%)
├─ Average Recovery Time: 19 minutes
├─ RTO Compliance: 100% (all systems recovered within targets)
└─ RPO Compliance: 100% (data loss within acceptable thresholds)

Recommendations:
1. ✅ All critical systems recoverable within acceptable timeframes
2. ✅ Backup integrity verified (no corruption detected)
3. ⚠️  Consider transaction log backups for SIS database (reduce RPO to <4 hours)
4. ⚠️  File server recovery time could be improved with Storage vMotion optimization
5. ✅ No changes needed to current backup strategy
```

---

## Instant VM Recovery Workflow

### Emergency Recovery Process (Sub-30-Minute RTO)

```
INCIDENT: SIS Database Server Failure (Hardware Fault)
Time: 8:45 AM (During school hours - CRITICAL)

Timeline:

08:45 AM - Incident Detected
├─ Monitoring alert: SQL-SIS01 unresponsive
├─ IT team confirms hardware failure (disk controller failure)
└─ Decision: Activate instant recovery (can't wait for hardware replacement)

08:48 AM - Instant Recovery Initiated
├─ Veeam: Start-VBRInstantRecovery -RestorePoint (Latest - 10 hours old)
├─ Target host: ESXi02 (secondary production host)
└─ VM boots from compressed backup file on repository

08:53 AM - VM Online (5 minutes elapsed)
├─ SQL Server services: STARTED
├─ Database status: ONLINE (StudentDB, StaffDB)
└─ Network connectivity: ENABLED (production network)

08:55 AM - Application Validation
├─ SIS web application: ACCESSIBLE
├─ Test query: Student enrollment data retrieved successfully
└─ Notification: Teachers/staff notified SIS back online

09:00 AM - Quick Migration Started (TOTAL DOWNTIME: 15 MINUTES)
├─ Veeam: Publish-VBRBackupContent (migrate to production datastore)
├─ VM runs from backup while migrating to production storage
└─ Migration ETA: 35 minutes (500 GB VM)

09:35 AM - Migration Complete
├─ VM now running from production datastore
├─ Backup file link removed
└─ Performance restored to normal

10:00 AM - Post-Incident
├─ Hardware team replaces failed disk controller
├─ SQL-SIS01 original server rebuilt for future use
└─ Incident closed: 15-minute downtime (within 30-minute RTO target)

RESULT: ✅ RTO MET (15 minutes actual vs. 30-minute target)
        ✅ RPO MET (10 hours data loss - last backup at 10 PM previous night)
        ✅ No instructional impact (recovered before first period)
```

---

## 3-2-1 Backup Rule Implementation

### Backup Copy Architecture

```
PRODUCTION DATA (1st Copy)
   │
   │ Veeam Backup Job (Nightly)
   ▼
PRIMARY BACKUP REPOSITORY (2nd Copy - Different Media)
   ├─ Location: On-premises backup server
   ├─ Storage: ReFS volume (50 TB)
   ├─ Retention: 14 days
   └─ Purpose: Fast restore, instant recovery
   │
   │ Backup Copy Job (Nightly + Weekly)
   ▼
┌──────────────────────┬───────────────────────────────┐
│                      │                               │
▼                      ▼                               ▼
OFFSITE REPOSITORY   CLOUD REPOSITORY (3rd Copy)   TAPE ARCHIVE
(2nd Copy)           (Azure Blob Storage)          (Long-term)
│                    │                               │
├─ Location:         ├─ Location:                    ├─ Location:
│  DR Site           │  Azure West US 2              │  Offsite vault
│  (50 miles away)   │                               │  (Iron Mountain)
├─ Storage:          ├─ Storage:                     ├─ Storage:
│  30 TB NAS         │  Azure Blob (Cool tier)       │  LTO-8 tapes
├─ Retention:        ├─ Retention:                   ├─ Retention:
│  30 days           │  90 days                      │  7 years (FERPA)
└─ Purpose:          └─ Purpose:                     └─ Purpose:
   Geographic          Cloud DR,                       Compliance,
   redundancy          Ransomware protection          Long-term archive

3-2-1 Rule Compliance: ✅
├─ 3 Copies: Production + Primary Repo + Offsite/Cloud
├─ 2 Different Media: Disk (ReFS, NAS) + Cloud (Blob)
└─ 1 Offsite: DR Site + Azure (geographically separated)
```

---

## Ransomware Protection Strategy

### Immutable Backup Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Production Environment                          │
│         (Vulnerable to ransomware encryption)                │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Veeam Backup (Read-Only Access)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│          Primary Repository (Linux Hardened)                 │
│                                                              │
│  OS: Ubuntu 22.04 LTS (immutable file system)               │
│  Filesystem: XFS with immutability flags                    │
│  Veeam Access: API-only (no SMB, no admin RDP)              │
│  Backup Chain: Write-once, cannot be deleted for 14 days    │
│                                                              │
│  Ransomware Protection:                                      │
│  ├─ Backups cannot be encrypted by malware                  │
│  ├─ Backups cannot be deleted until retention expires       │
│  └─ Air-gapped network (only accessible from Veeam server)  │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Backup Copy (Delayed)
                   │ 7-day delay (malware detection window)
                   ▼
┌─────────────────────────────────────────────────────────────┐
│         Cloud Repository (Azure Immutable Blob)              │
│                                                              │
│  Azure Blob Storage - Cool Tier                             │
│  Immutability Policy: WORM (Write-Once-Read-Many)           │
│  Retention: 90 days (cannot be deleted by anyone)           │
│  MFA: Required for any Azure storage account changes        │
│                                                              │
│  Ransomware Scenario:                                        │
│  ├─ Day 1: Ransomware infects production, encrypts data     │
│  ├─ Day 1-7: Infected backups written to primary repo       │
│  ├─ Day 8: IT discovers ransomware (via monitoring)         │
│  ├─ Day 8: Restore from cloud repo (7 days old, clean)      │
│  └─ Result: Max 7 days data loss, but clean recovery        │
└─────────────────────────────────────────────────────────────┘

Detection & Response:
├─ Veeam Backup Monitoring: Detect unusual backup size increases (ransomware encryption signature)
├─ Failed backup jobs: Indicator of compromised systems
├─ Endpoint Detection (Microsoft Defender): Block ransomware before encryption
└─ Network Segmentation: Backup network isolated from production (prevent lateral movement)
```

---

## Backup Performance Metrics

### Throughput and Efficiency

```
Average Backup Performance (90-day trend):

Backup Job Performance:
├─ Average throughput: 450 MB/s (per proxy)
├─ Peak throughput: 850 MB/s (during synthetic full with ReFS fast clone)
├─ Network utilization: 35% of 10 Gbps link (3.5 Gbps average)
└─ Bottleneck: Source storage IOPS (not network or Veeam)

Data Reduction:
├─ Compression ratio: 2.1:1 (moderate compression level 5)
├─ Deduplication ratio: 2.3:1 (ReFS block-level deduplication)
├─ Combined ratio: 4.8:1 (typical for VM environments)
└─ Example: 500 GB VM → 104 GB backup file

Backup Window Utilization:
├─ Available window: 10 PM - 6 AM (8 hours)
├─ Actual backup time: 4 hours 15 minutes (53% utilization)
├─ Remaining capacity: 3 hours 45 minutes (room for growth)
└─ Recommendation: Current utilization healthy, can add 5-10 more VMs
```

---

## Compliance and Retention Policies

### FERPA-Compliant Data Retention

```
Data Classification & Retention:

Tier 1: Critical Student Data (SIS Database)
├─ Retention: 14 days (operational recovery)
├─ Long-term archive: 7 years (FERPA compliance)
├─ Archive method: Tape backup to offsite vault
└─ Recovery SLA: <30 minutes (operational), <48 hours (archive)

Tier 2: Student Files (Home Directories)
├─ Retention: 30 days (operational recovery)
├─ Long-term archive: End of school year + 1 year
├─ Archive method: Cloud (Azure Blob - Archive tier)
└─ Recovery SLA: <2 hours (operational), <7 days (archive)

Tier 3: Administrative Systems
├─ Retention: 14 days (operational recovery)
├─ Long-term archive: 3 years (business records retention)
├─ Archive method: Offsite repository
└─ Recovery SLA: <30 minutes (operational), <24 hours (archive)

Tier 4: Non-Critical Systems (Lab VMs, Dev)
├─ Retention: 7 days (operational recovery only)
├─ Long-term archive: None
└─ Recovery SLA: <4 hours (operational)

Audit Logging:
├─ All restore operations logged (who, what, when)
├─ Logs retained for 7 years (FERPA compliance)
├─ Monthly audit reports generated automatically
└─ Annual compliance review by legal/IT leadership
```

---

## Future Enhancements Roadmap

### Planned Improvements (2025-2026)

**Q1 2025: Transaction Log Backups for SIS Database**
- Reduce RPO from 24 hours to 4 hours
- Implement SQL Server transaction log backups every 4 hours
- Estimated cost: $0 (software capability already licensed)

**Q2 2025: Azure Site Recovery (ASR) for Critical VMs**
- Near-zero RPO for SIS database and domain controllers
- Continuous replication to Azure (5-minute RPO)
- Estimated cost: $500/month Azure consumption

**Q3 2025: Veeam Backup for Microsoft 365**
- Protect Exchange Online mailboxes, OneDrive, SharePoint, Teams
- Current gap: Microsoft 365 data not backed up (relies on Microsoft retention only)
- Estimated cost: $2/user/month (400 staff users = $800/month)

**Q4 2025: NAS Snapshot Integration**
- Leverage NetApp storage snapshots for faster backups
- Reduce backup window from 4 hours to 1 hour
- Estimated cost: $0 (NetApp licensing already in place)

---

## Summary: Backup Infrastructure by the Numbers

```
Infrastructure Scale:
├─ Total VMs Protected: 45 virtual machines
├─ Total Data Protected: ~180 TB (source data)
├─ Backup Storage Used: 37.5 TB (after 4.8:1 reduction)
├─ Backup Jobs: 12 jobs
└─ Restore Points: 240 total (across all jobs)

Performance:
├─ Average Backup Speed: 450 MB/s
├─ Longest Backup Job: 2 hr 15 min (student file server)
├─ Shortest Backup Job: 8 min (domain controller)
└─ Backup Window Utilization: 53% (healthy capacity)

Reliability:
├─ Success Rate (90 days): 95.83%
├─ Failed Backups: 10/240 (4.17%)
├─ RTO Compliance: 100% (all DR tests met targets)
└─ RPO Compliance: 100% (data loss within acceptable limits)

Disaster Recovery:
├─ Quarterly DR Tests: 100% success rate
├─ Average Recovery Time: 19 minutes
├─ Instant Recovery Capability: <5 minutes VM boot
└─ Geographic Redundancy: 3 sites (primary, DR site 50 miles away, Azure cloud)

Compliance:
├─ FERPA Retention: 7 years (tape archive)
├─ 3-2-1 Rule: ✅ Compliant
├─ Ransomware Protection: ✅ Immutable backups enabled
└─ Audit Logging: ✅ All restores logged for 7 years
```

This architecture supports the Power BI IT Infrastructure Health Dashboard statistics:
- **95.83% backup success rate** (230/240 successful jobs in 90 days)
- **240 total backup job runs** tracked
- **<30-minute RTO** for critical systems (SIS database, domain controllers)
- **Quarterly DR testing** with 100% success rate
