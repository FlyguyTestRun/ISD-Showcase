# Lessons Learned: Backup & DR for K-12 Environments

## Backup Job Configuration

### Mistake: Default 7-Day Retention Too Short

**What Happened:**
Configured SIS database backups with default 7-day retention. Three weeks later, received request from administration to recover student grade data from "two weeks ago" for an audit investigation.

**Impact:**
Unable to fulfill data recovery request. Restore point had already been deleted per retention policy.

**Solution:**
- K-12 environments require minimum 14-day retention (covers two full school weeks)
- SIS databases: 30-day retention recommended for grade audits and FERPA compliance
- Document retention policies in writing and obtain approval from legal/compliance teams
- Implement separate retention tiers: Critical systems (30 days), Standard systems (14 days), Non-critical (7 days)

**Code Fix:**
```powershell
# Don't use defaults
# Bad:
Add-VBRViBackupJob -Name "SIS-Database" -Entity $VM -BackupRepository $Repo

# Good: Explicitly set retention
Add-VBRViBackupJob -Name "SIS-Database" -Entity $VM -BackupRepository $Repo
$Job = Get-VBRJob -Name "SIS-Database"
$JobOptions = $Job.GetOptions()
$JobOptions.BackupStorageOptions.RetainCycles = 30  # 30 restore points
$Job.SetOptions($JobOptions)
```

---

### Mistake: Backup Jobs Running During School Hours

**What Happened:**
Large file server backup job configured to run at 2 AM, but job took 6+ hours to complete. Users arrived at 7:30 AM to severely degraded network performance and slow file access.

**Impact:**
- 200+ staff members experienced slow logons and file access during critical morning hours
- Help desk overwhelmed with performance complaints
- Principal demanded explanation for technology failures

**Solution:**
- Calculate backup duration: Initial full backup took 8 hours for 2TB file server
- Set backup window END time, not just start time
- For jobs that may exceed window, configure job to terminate at 6 AM
- Split large VMs across multiple smaller jobs for better control

**Code Fix:**
```powershell
# Add backup window enforcement
$Job = Get-VBRJob -Name "File-Server-Students"
$JobOptions = $Job.GetOptions()
$JobOptions.JobOptions.BackupWindowOptions.IsEnabled = $true
$JobOptions.JobOptions.BackupWindowOptions.BackupWindow = @"
<ScheduleOptions>
  <TimeOfDay>18:00</TimeOfDay>
  <EndTimeOfDay>06:00</EndTimeOfDay>
  <StopJob>true</StopJob>
</ScheduleOptions>
"@
$Job.SetOptions($JobOptions)
```

---

### Mistake: No Application-Aware Processing for SQL Servers

**What Happened:**
Backed up SIS SQL Server as standard VM backup without application-aware processing. During DR test, restored VM but SQL databases in "RECOVERY PENDING" state. Database administrator had to manually recover databases, extending recovery time from 15 minutes to 2+ hours.

**Impact:**
- DR test failed to meet 30-minute RTO target
- Audit committee questioned DR readiness
- Required re-engineering of backup jobs and re-testing

**Solution:**
- Always enable VSS application-aware processing for SQL Servers
- Provide SQL credentials with sysadmin role for transaction log backups
- Configure transaction log truncation after successful backup
- Test restores regularly - don't discover problems during actual disasters

**Code Fix:**
```powershell
# Enable application-aware processing
$Job = Get-VBRJob -Name "SIS-Database"
$JobOptions = $Job.GetOptions()
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.ViApplicationQuiescing = $true
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.VssSplApplicationProcessing = $true

# Add SQL credentials
$SQLCreds = Get-VBRCredentials -Name "SQL-BackupAccount"
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.Credentials = $SQLCreds
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.SqlBackupOptions.TransactionLogsProcessing = "TruncateOnlyOnSuccessJob"

$Job.SetOptions($JobOptions)
```

---

## Disaster Recovery Testing

### Mistake: DR Test VMs on Production Network

**What Happened:**
Restored domain controller from backup to test recovery procedures. Restored DC powered on with same hostname and IP as production DC, causing DNS conflicts, authentication failures, and USN rollback corruption in Active Directory.

**Impact:**
- Took down production authentication for 45 minutes during school hours
- 3,000+ students/staff unable to log in
- Required emergency demotion of corrupted DC and metadata cleanup
- District leadership questioned IT competency

**Solution:**
- ALWAYS use isolated test network (separate VLAN or vSwitch) for DR testing
- Power on restored VMs in disconnected state, manually change network adapter before first boot
- Use naming conventions: Production "DC01", DR test "DC01-DRTest"
- Document DR test procedures step-by-step to prevent shortcuts

**Code Fix:**
```powershell
# Always specify isolated network for DR tests
$RestorePoint = Get-VBRRestorePoint -Name "DC01" | Select-Object -First 1
$IsolatedNetwork = Find-VBRViNetwork -Name "DR-Test-VLAN100"

Start-VBRRestoreVM `
    -RestorePoint $RestorePoint `
    -VMName "DC01-DRTest" `
    -PowerOn:$false `  # Critical: don't power on automatically
    -Reason "Quarterly DR test - isolated network required"

# Manually verify network isolation before powering on
```

---

### Mistake: Assuming Backups Are Valid Without Testing

**What Happened:**
Backup jobs showed green checkmarks for 6 months. Never performed actual restore tests. When SIS database server suffered catastrophic hardware failure, discovered backups were incomplete - application-aware processing had been failing silently. Lost 14 days of student enrollment changes during August registration period.

**Impact:**
- Manual reconstruction of 200+ student enrollment records from paper forms
- Parents furious about lost registrations
- Board of Education inquiry into data protection procedures
- Superintendent demanded IT department restructuring

**Solution:**
- Schedule quarterly DR tests during school break periods (Thanksgiving, Spring Break, Summer)
- Perform full restore validation, not just restore job execution
- Verify application data integrity post-restore (run test queries)
- Document test results with screenshots and validation evidence
- Failures in backup logs are warnings, not acceptable states

**Prevention Strategy:**
```powershell
# Automated monthly restore test
$LastRestoreTest = Get-ChildItem "C:\DR-Tests\" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$DaysSinceTest = ((Get-Date) - $LastRestoreTest.LastWriteTime).TotalDays

if ($DaysSinceTest -gt 30) {
    Send-MailMessage `
        -To "it-director@district.edu" `
        -Subject "DR TEST OVERDUE - Action Required" `
        -Body "Last DR test was $([Math]::Round($DaysSinceTest)) days ago. Quarterly testing required."
}
```

---

## Infrastructure Design

### Mistake: Single Backup Repository Without Offsite Copy

**What Happened:**
All backups stored on single NAS device in school district data center. Building suffered water damage from sprinkler malfunction during summer. Backup repository destroyed along with all production servers.

**Impact:**
- Total data loss for district - 6 years of student records unrecoverable
- District forced to rebuild from outdated paper records
- Lawsuits from parents regarding lost IEP documentation
- Multi-million dollar recovery effort

**Solution:**
- Implement 3-2-1 backup rule: 3 copies, 2 different media types, 1 offsite
- Veeam Backup Copy jobs to secondary repository in different building
- Cloud tier for critical data (AWS S3, Azure Blob, etc.)
- Annual disaster recovery tabletop exercises including "total loss" scenarios

**Code Fix:**
```powershell
# Create backup copy job to offsite repository
$PrimaryBackup = Get-VBRBackup -Name "SIS-Database"
$OffsiteRepo = Get-VBRBackupRepository -Name "Offsite-Repository-AWS"

Add-VBRBackupCopyJob `
    -Name "SIS-Database-Offsite-Copy" `
    -BackupJob $(Get-VBRJob -Name "SIS-Database") `
    -Repository $OffsiteRepo `
    -Description "Offsite copy for disaster recovery"
```

---

### Mistake: No WAN Acceleration for Remote School Sites

**What Happened:**
Configured backup jobs for remote elementary school (connected via 100 Mbps WAN link). Backups of file servers saturated network link, making internet unusable for students. Teachers complained distance learning video calls dropped constantly during backup windows.

**Impact:**
- Remote site backups disabled to restore network functionality
- Remote site left unprotected for 3 months while designing solution
- Compliance audit finding for inadequate data protection

**Solution:**
- Enable Veeam WAN Acceleration for all remote site backups
- Configure bandwidth throttling rules (use max 30% of available WAN during school hours)
- Consider backup to local repository, then replicate overnight
- Monitor network utilization during backup operations

**Code Fix:**
```powershell
# Enable WAN acceleration and throttling
$Job = Get-VBRJob -Name "RemoteSite-ElementarySchool"
$JobOptions = $Job.GetOptions()

# Enable WAN acceleration
$JobOptions.ViSourceOptions.WanAcceleration.IsEnabled = $true

# Limit to 30 Mbps during school hours (9 AM - 4 PM)
$JobOptions.ViSourceOptions.BackupJobNetworkOptions.TrafficThrottlingOptions.IsEnabled = $true
$JobOptions.ViSourceOptions.BackupJobNetworkOptions.TrafficThrottlingOptions.TrafficThrottlingSpeedLimit = 30  # Mbps
$JobOptions.ViSourceOptions.BackupJobNetworkOptions.TrafficThrottlingOptions.TrafficThrottlingUnit = "MbitPerSec"

$Job.SetOptions($JobOptions)
```

---

## Monitoring and Alerting

### Mistake: No Automated Failure Notifications

**What Happened:**
Backup administrator left organization. Replacement assumed backups were automated and self-managing. Three months later, discovered 15 backup jobs failing nightly with "insufficient disk space" errors. Lost ability to recover any systems to point in time before disk filled up.

**Impact:**
- Backup repository at 100% capacity for 90 days
- Lost 3 months of recovery points for all systems
- Discovered during attempted restore of accidentally deleted files - files unrecoverable

**Solution:**
- Implement email alerting for all backup job failures
- Daily health check reports delivered to IT team
- Weekly summary reports to IT leadership
- Escalation procedures: 3 consecutive failures = page on-call engineer

**Code Fix:**
```powershell
# Automated daily failure check with email alerts
$FailedJobs = Get-VBRBackupSession |
    Where-Object {
        $_.EndTime -gt (Get-Date).AddHours(-24) -and
        $_.Result -ne "Success"
    }

if ($FailedJobs) {
    $Body = @"
The following backup jobs failed in the last 24 hours:

$($FailedJobs | Format-Table JobName, Result, @{N='FailureMessage';E={$_.Info.Reason}} | Out-String)

Action Required: Investigate failures immediately.
"@

    Send-MailMessage `
        -To "it-team@district.edu", "it-director@district.edu" `
        -From "veeam-alerts@district.edu" `
        -Subject "BACKUP FAILURE ALERT - $(($FailedJobs | Measure-Object).Count) Jobs Failed" `
        -Body $Body `
        -SmtpServer "smtp.district.edu" `
        -Priority High
}
```

---

## Best Practices Summary

1. **Retention Policies:** Document and obtain approval in writing. 14-day minimum for K-12 systems.
2. **Backup Windows:** Always configure END time, not just start time. Terminate jobs that exceed window.
3. **Application-Aware Processing:** Required for SQL, Exchange, Active Directory. Test transaction log handling.
4. **DR Testing Isolation:** Dedicated test network, separate VLANs, manual network assignment before power-on.
5. **Regular Restore Validation:** Quarterly full DR tests, monthly automated spot checks.
6. **Offsite Protection:** 3-2-1 rule - never rely on single copy in single location.
7. **WAN Optimization:** Enable WAN acceleration and throttling for remote sites.
8. **Automated Alerting:** Email notifications for all failures, weekly summary reports.
9. **School Calendar Awareness:** Schedule resource-intensive operations during breaks (full backups, DR tests).
10. **Documentation:** Runbooks for common procedures, escalation paths for failures.
