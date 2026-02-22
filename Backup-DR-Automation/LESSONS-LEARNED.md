# Lessons Learned: Backup & DR for Enterprise Environments

## Backup Job Configuration

### Mistake: Default 7-Day Retention Too Short

**What Happened:**
Configured database backups with default 7-day retention. Three weeks later, created request to recover data from "two weeks ago" for an audit investigation.

**Impact:**
Unable to fulfill data recovery request. Restore point had already been deleted per retention policy. Solution found in archived structure.

**Solution:**
- Required minimum 30-day retention period.
- SIS databases: 30-day retention recommended for grade audits and FERPA compliance
- Document retention policies in writing and obtain approval from legal compliance teams
- Implement separate retention tiers: Critical systems (30 days), Standard systems (14 days), Non-critical (7 days)

**Code Fix for Sandbox Creation Failure:**
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

### Mistake: Backup Jobs Running During Unusual Office Hours

**What Happened:**
Large file server backup job configured to run at 2 AM, but unusual trial team hours created a backup retention problem during "high-stakes" trial, back-up took hours to complete. Degraded users access and network performance and slow file access.

**Impact:**
- Our trial team experienced slow logons (when returning at 4am to continue time sensitve work for morning court time and file access was limited via our VPN during the critical morning hours
- Overwhelmed with performance and time constraints this required immidiate address 
- Trial team and partners demanded explanation for technology failures and poor oversight

**Solution:**
- Calculated backup duration through the night and coordinated full backup delay with network administrator for 2TB file server
- Set backup window delays during key trial times, established new back up timeframe outside of the standard window for integration and consulting with IT teams for future solutions to legal setting challenges
- For jobs that may exceed window, configure job to terminate at 4 AM giving time for early morning trial team prep
- Split large VMs across multiple smaller jobs for better control and implemented a coordinated check with IT networking teams to monitor key trial days (outside of norm considerations)

---

### Mistake: No Application-Aware Processing for SQL Servers

**What Happened:**
Backed up SQL Server as standard VM backup without application-aware processing. During DR test, restored VM but SQL databases in "RECOVERY PENDING" state. Database administrator had to manually recover databases, extending recovery time from 15 minutes to 2+ hours.

**Impact:**
- Failed to meet 30-minute RTO target
- Firm questioned consulting practice
- Required re-engineering of backup jobs and re-testing in sandbox enviorment

**Solution:**
- Always test in sandbox venv first!
- enable VSS application-aware processing for SQL Servers
- Provide SQL credentials with sysadmin role for transaction log backups
- Configure transaction log truncation after successful backup
- Test restores regularly - don't discover problems during actual disasters!

---

## Disaster Recovery Testing

### Mistake: DR Test VMs on Production Network

**What Happened:**
Restored virtual domain controller from backup to test recovery procedures. Restored DC powered on with same hostname and IP as production DC, causing DNS conflicts, authentication failures, and USN rollback corruption in Active Directory.

**Impact:**
- Took down production and authentication for 45 minutes during peak trial prep hours
- Our trial team was unable to login and prep during our sunday night arrival
- Required emergency demotion of corrupted DC and metadata cleanup
- Trial attorney questioned competency

**Solution:**
- I was in a hurry to get our VPN/"War Room" office online, discussed with Law Firm solution to allow me to arrive a day earlier for more set up time
- ALWAYS use isolated test network (separate VLAN or vSwitch) for DR testing
- Power on restored VMs in disconnected state, manually change network adapter before first boot
- Use naming conventions: Production "DC01", DR test "DC01-DRTest"
- Create ADR system for documentation and future failure recovery
- Document DR test procedures step-by-step to prevent shortcuts

---

### Mistake: Assuming Backups Are Valid Without Testing

**What Happened:**
Backup jobs showed green checkmarks for 6 months. Never performed actual restore tests. When my local trial "war room" server suffered catastrophic hardware failure (it would get packed up and moved per trial location), discovered backups were currupted from old trial data sets - application-aware processing had been failing silently. Lost months of crucially important impeachment clips I had stored on my internal server and left my back-up hard drives at home. Although these were always returned to the firm at the end of trial the data never got backed up internally.

**Impact:**
- Delayed our trial prep, required my wife intervention to accomplish required files and walk through a FTP file share eventually snail mailing me backups
- My back up hard disks had to be overnighted to trial team
- To protect the risk of failure in shipment walk her through backing up to my home desktop (2TB store) for data protection procedures before mailing


**Solution:**
- This demanded IT department restructuring at firm to store all trial data after the completion of trial
- I took lead on coordinating this with office staff and built automation scripts for trial technicians to follow
- Schedule quarterly archive and data retention policies
- Perform full restore validation, not just restore critical to trial files (no persumptions are guesses on sensitive datasets)
- Verify application data integrity post-restore (built test quiries for paralegal teams to run at the end of trials)

**Example of Prevention Strategy Script Built:**
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
I would store all backups for recovery and future trials with the same Law Firms and these backups stored on single NAS device in my posession would not be backed or coordinated with internal IT teams. Resulting in late night calls of "Hey Bryan you have the deposition of... our do you have the deck I build for X trial". Rarely would attorneys deliver the trial data back to the law firm so the trial backup repository became me.

**Impact:**
- Late night calls from trial teams to retrieve data from previous trials
- Several times without knowledge rebuilding work already completed by other trial teams
- Poor comunication led to work redundancy
- Lawsuits taking longer and requiring higher work demand
- Multi-million dollar rebuild efforts in many cases

**Solution:**
- Implement 3-2-1 backup rule: 3 copies, 2 different locations, led the coordination effort between IT department and trial attorneys, 1 offsite (mine the last fail safe)
- Veeam Backup Copy jobs to secondary repository in different locations (in the early days seperate offices, since cloud backups)
- Cloud tier became critical for data retention and multiple trial teams around the county recently using (AWS S3, Azure Blob, less google etc.)
- Annual disaster recovery tabletop exercises including "total loss" scenarios

---

### Mistake: No WAN Acceleration for Remote Sites

**What Happened:**
Configured for remote access and WAN at key sensitive trial with defense council working on the same floor as client (connected via 100 Mbps WAN link). Network link was required to be taken down heavy traffic spikes and threat monitoring led attorneys concern to using Wi-Fi, required take down of WAN and set up VLAN config for exact IP protocols, making internet unusable for clients with no CAT5 connection (more modern computers with USB-C clients did not have dongles for internet access. Complained of requirements to work on "war room". Tight concerns of data hacks lead to me purchasing a "bug sweeper" for scanning our hotel "war room" nightly.

**Impact:**
- Remote work (our normal SOP was not an option) creating headaches for fileshare and data transfer without VPN access network functionality reduced for trial duration. No court room WAN was allowed
- My normal setup was reduced to a sneaker network and physically delivering nightly file updates throughout the hotel
- Compliance auditing (via attorneys) finding for inadequate data protection

**Solution:**
- Learned protocols and validated firewall settings
- Learned early 2000s corporate espinoge tactics and how to explain to client security protocols without fear
- Backup to local repository, then replication via physical delivery
- Learned network monitoring dashboards to showcase system integrity, monitored network utilization during operations via the dashboards and shared them with trial teams
- NEVER again said in dinner conversation "well nothing is every 100% secure" (learned quite a bit with that growing pain) 

---

## Monitoring and Alerting

### Mistake: No Automated Failure Notifications

**What Happened:**
Backup administrator left organization. Assumed backups were still being stored after trial ended. Nine months later, discovered relatively new client with botique firm was not backing up trial data and system was not automated or self-managing. 

**Impact:**
- Client lost ability to recover key trial data for future trial needs
- this was for a new client and would have saved hours of repetitive work
- unavailable I had no quick solution to help them recover the data

**Solution:**
- Implemented email alerting for firms managing partner of all backup job failures
- Daily health check reports delivered to IT admin (no full scope IT infrastructure used by client)
- Monthly summary reports to partners
- Escalation procedures: consecutive failures = call me

---

## These are the real-world failures that have lead me to implement redundant system cross checks in my practice.

### I design a ARD retention policy for failures so I will not repeat mistakes and learned to implement the following in my IT career.

1. **Retention Policies:** Document and obtain approval in writing.
2. **Backup Windows:** Always configure END time, not just start time. Terminate jobs that exceed window and consider the working enviorment.
3. **Application-Aware Processing:** Required for SQL, Exchange, Active Directory. Test transaction log handling.
4. **DR Testing Isolation:** Dedicated test networks, DO NOT rush, take time TEST, separate VLANs, manual network assignment before power-on.
5. **Regular Restore Validation:** Quarterly full DR tests, monthly automated spot checks and use validation loops in script design.
6. **Offsite Protection:** 3-2-1 rule - never rely on single copy in single location. (avoids late night calls and being the gatekeeper)
7. **WAN Optimization:** Enable WAN acceleration and throttling for remote sites.
8. **Automated Alerting:** Email notifications for all failures, weekly summary reports.
9. **Calendar Awareness:** Schedule resource-intensive operations during downtime, holiday breaks (full backups, DR tests).
10. **Documentation:** Runbooks for common procedures, escalation paths for failures.
