# Veeam Backup & Disaster Recovery Automation

PowerShell automation modules for K-12 educational data protection, disaster recovery testing, and compliance reporting.

---

## Overview

This folder contains PowerShell scripts designed to automate Veeam Backup & Replication management for school district infrastructure. The modules prioritize:

- **Educational Data Protection**: Student Information Systems (SIS), Learning Management Systems (LMS), and student records
- **After-Hours Backup Windows**: Scheduled during non-instructional hours (6 PM - 6 AM) to minimize impact
- **FERPA Compliance**: Audit logging and retention policies for student data protection
- **Disaster Recovery Readiness**: Automated DR testing aligned with school calendar break periods

---

## Files

### 1. `Veeam-BackupManagement.ps1`
**Purpose:** Core backup job management and monitoring module

**Functions:**
- `New-VeeamBackupJob` - Creates backup jobs with K-12 optimized settings (after-hours windows, 14-day retention)
- `Test-VeeamBackupIntegrity` - Verifies backup health, repository capacity, and restore point validity
- `Start-VeeamDRTest` - Orchestrates isolated DR testing without impacting production
- `Export-VeeamBackupReport` - Generates HTML/CSV compliance reports for IT leadership

**Use Cases:**
- Automating SIS database backup job creation
- Daily backup health monitoring with alerting
- Monthly compliance reporting for district audits

**Example:**
```powershell
# Create nightly SIS database backup job
New-VeeamBackupJob -JobName "SIS-Database-Nightly" `
                   -TargetVMs "SQL-SIS01" `
                   -Repository "Backup-Repo-01" `
                   -Schedule AfterHours `
                   -RetentionDays 14

# Verify backup integrity
Test-VeeamBackupIntegrity -JobName "SIS-Database-Nightly" -VerifyRestorePoints 7

# Generate monthly compliance report
Export-VeeamBackupReport -ReportPath "C:\Reports\Backup-Report-$(Get-Date -Format 'yyyy-MM').html" -Days 30
```

---

### 2. `Veeam-DRTesting.ps1`
**Purpose:** Comprehensive disaster recovery testing procedures

**Functions:**
- `Invoke-SISDatabaseDRTest` - Tests SQL Server SIS database recovery (RTO/RPO validation)
- `Invoke-DomainControllerDRTest` - Tests Active Directory domain controller recovery (non-authoritative restore)
- `Invoke-FileServerDRTest` - Tests student/staff file server recovery (home directories, permissions)
- `Start-ComprehensiveDRTest` - Orchestrates full DR test suite with consolidated reporting

**Use Cases:**
- Quarterly DR drills during school break periods (Thanksgiving, Spring Break, Summer)
- Validating recovery time objectives (RTO <30 minutes)
- Verifying data integrity after restore operations

**Example:**
```powershell
# Run comprehensive DR test suite
Start-ComprehensiveDRTest -OutputReportPath "C:\Reports\DR-Test-$(Get-Date -Format 'yyyy-MM-dd').html"

# Individual SIS database recovery test
Invoke-SISDatabaseDRTest -BackupAge 24 -IsolatedNetwork "DR-Test-VLAN100"

# Domain controller recovery test
Invoke-DomainControllerDRTest
```

---

## K-12 Specific Considerations

### Backup Windows
- **After-Hours Scheduling**: Backups run 6 PM - 6 AM (post-school day, pre-arrival)
- **Weekend Full Backups**: Saturday nights for minimal network impact
- **Summer Maintenance**: Extended maintenance windows during summer break for large-scale DR testing

### Retention Policies
- **SIS Database**: 14-day restore point retention (supports grade recovery, data audit requests)
- **Domain Controllers**: 7-day retention (rapid AD recovery, minimal storage overhead)
- **Student File Servers**: 30-day retention (supports "I deleted my homework" scenarios)

### Recovery Time Objectives (RTO)
- **Critical Systems** (SIS, DC): <30 minutes (minimize instructional disruption)
- **File Servers**: <2 hours (staff can use cached files temporarily)
- **Administrative Systems**: <4 hours (less time-sensitive)

### Recovery Point Objectives (RPO)
- **SIS Database**: <24 hours (nightly backups acceptable for most districts)
- **Transaction Log Backups**: Optional 4-hour RPO for large districts during enrollment periods
- **File Servers**: <24 hours (student work saved locally during school day)

---

## Requirements

**Software:**
- Veeam Backup & Replication 12+ (VBR 11 compatible with minor modifications)
- PowerShell 5.1 or later
- Veeam PowerShell snapin (`Add-PSSnapin VeeamPSSnapin`)

**Permissions:**
- Veeam Backup Administrator role
- vCenter/vSphere access (for VM restore operations)
- SQL Server permissions (for SIS database validation queries)

**Infrastructure:**
- Isolated test network/VLAN for DR testing (prevents IP conflicts with production)
- Veeam backup repository with sufficient capacity (recommend 3x source data size)

---

## Deployment Guide

### Step 1: Import Veeam Module
```powershell
# Import Veeam snapin (production environment)
Add-PSSnapin VeeamPSSnapin

# Import automation module
Import-Module .\Veeam-BackupManagement.ps1
```

### Step 2: Configure Backup Jobs
```powershell
# Create backup jobs for critical systems
$CriticalSystems = @(
    @{Name = "SIS-Database-Nightly"; VMs = @("SQL-SIS01"); Retention = 14}
    @{Name = "Domain-Controllers"; VMs = @("DC01", "DC02"); Retention = 7}
    @{Name = "File-Server-Students"; VMs = @("FS-Students01"); Retention = 30}
)

foreach ($System in $CriticalSystems) {
    New-VeeamBackupJob -JobName $System.Name `
                       -TargetVMs $System.VMs `
                       -Repository "Backup-Repo-01" `
                       -Schedule AfterHours `
                       -RetentionDays $System.Retention
}
```

### Step 3: Schedule Daily Health Checks
```powershell
# Create scheduled task for daily backup integrity checks
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\Scripts\Veeam-BackupManagement.ps1 -Command Test-VeeamBackupIntegrity"

$Trigger = New-ScheduledTaskTrigger -Daily -At "7:00 AM"

Register-ScheduledTask -TaskName "Veeam-Daily-Health-Check" `
                       -Action $Action `
                       -Trigger $Trigger `
                       -User "SYSTEM"
```

### Step 4: Schedule Quarterly DR Tests
```powershell
# Schedule DR tests during school break periods
# Recommended: Thanksgiving week, Spring Break week, Summer (June/July)

# Example: Spring Break DR test
Start-ComprehensiveDRTest -OutputReportPath "C:\Reports\DR-Test-SpringBreak-2025.html"
```

---

## Compliance & Reporting

### Monthly Backup Reports
Generated reports include:
- Job success rates (target: >95% success)
- Storage utilization and capacity planning
- Critical system backup recency (<24 hours for SIS)
- Failed job alerts with root cause analysis

### Quarterly DR Test Reports
DR test documentation includes:
- Recovery time validation (RTO metrics)
- Data loss assessment (RPO metrics)
- Application validation results (SIS login, AD auth, file access)
- Recommendations for infrastructure improvements

---

## Troubleshooting

### Common Issues

**Issue:** Backup job fails with "Insufficient storage space"
- **Solution:** Run `Test-VeeamBackupIntegrity` to check repository capacity. Consider enabling per-VM backup chains or adding repository storage.

**Issue:** DR test VM has IP conflict with production
- **Solution:** Verify isolated test network configuration. Use `IsolatedNetwork` parameter to specify test VLAN.

**Issue:** SIS database restore fails integrity check
- **Solution:** Check Veeam backup job logs for corruption during backup. Enable application-aware processing for SQL Server.

---

## Best Practices

1. **Test Restores Regularly**: "Backups are worthless if you can't restore" - validate quarterly
2. **Automate Reporting**: Schedule monthly compliance reports for proactive issue detection
3. **Align with School Calendar**: DR testing during break periods minimizes disruption
4. **Document Recovery Procedures**: Maintain runbooks for staff who may execute DR during emergencies
5. **Monitor Backup Windows**: Ensure jobs complete before school day begins (6 AM hard deadline)

---

## Additional Resources

- [Veeam PowerShell Reference](https://helpcenter.veeam.com/docs/backup/powershell/)
- [K-12 Data Protection Best Practices](https://www.cosn.org/)
- [FERPA Compliance Guidelines](https://studentprivacy.ed.gov/)

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com
**Purpose:** Demonstration of K-12 backup/DR automation expertise for Keller ISD Senior Systems Engineer position
