# Veeam Backup Automation Implementation Guide

## Prerequisites

**Software Requirements:**
- Veeam Backup & Replication 12.x (VBR 11.x compatible)
- PowerShell 5.1 or PowerShell 7.x
- Veeam PowerShell snapin installed (`Add-PSSnapin VeeamPSSnapin`)

**Infrastructure Requirements:**
- vCenter Server 7.0+ or ESXi 7.0+ with direct host connection
- Backup repository with 3x source data capacity
- Network connectivity: Veeam server → vCenter → ESXi hosts
- Credentials: vCenter admin, Veeam Backup Administrator role

**Permissions Required:**
- Veeam: Backup Administrator role
- vCenter: Administrator@vsphere.local or equivalent
- SQL Server: sysadmin role (for application-aware processing on SIS databases)

---

## Initial Setup

### 1. Install Veeam PowerShell Module

```powershell
# Verify Veeam installation path
$VeeamPath = "C:\Program Files\Veeam\Backup and Replication\Console"
if (Test-Path $VeeamPath) {
    Write-Host "Veeam installed at: $VeeamPath" -ForegroundColor Green
} else {
    Write-Warning "Veeam not found. Install Veeam B&R first."
    exit
}

# Load Veeam PSSnapin
Add-PSSnapin VeeamPSSnapin -ErrorAction Stop

# Verify module loaded
Get-Command -Module VeeamPSSnapin | Measure-Object
```

### 2. Connect to Veeam Backup Server

```powershell
# Connect to Veeam server (local or remote)
$VBRServer = "veeam01.district.edu"  # Use localhost for local execution
Connect-VBRServer -Server $VBRServer

# Verify connection
Get-VBRServerSession
```

### 3. Verify Infrastructure Connectivity

```powershell
# List connected vCenter/ESXi servers
Get-VBRServer | Where-Object {$_.Type -eq "VC" -or $_.Type -eq "ESXi"}

# List available backup repositories
Get-VBRBackupRepository | Select-Object Name, FriendlyPath, @{N='FreeGB';E={[Math]::Round($_.GetContainer().CachedFreeSpace/1GB, 2)}}

# List VMs available for backup
Get-VBRServer | Get-VBRViEntity -Type VM | Select-Object Name, Path
```

---

## Creating Backup Jobs

### Standard VM Backup Job

```powershell
# Define backup job parameters
$JobName = "SIS-Database-Nightly"
$VMNames = @("SQL-SIS01", "SQL-SIS02")  # Cluster nodes
$Repository = "Backup-Repo-01"
$RetentionDays = 14

# Get VM objects from vCenter
$VMObjects = Get-VBRServer | Get-VBRViEntity -Name $VMNames -Type VM

# Get backup repository object
$BackupRepo = Get-VBRBackupRepository -Name $Repository

# Create backup job
Add-VBRViBackupJob `
    -Name $JobName `
    -Entity $VMObjects `
    -BackupRepository $BackupRepo `
    -Description "SIS SQL Server cluster backup (14-day retention)"

# Configure retention policy
$Job = Get-VBRJob -Name $JobName
$JobOptions = $Job.GetOptions()
$JobOptions.BackupStorageOptions.RetainCycles = $RetentionDays
$Job.SetOptions($JobOptions)

Write-Host "Backup job '$JobName' created successfully" -ForegroundColor Green
```

### Application-Aware Backup (SQL Server)

```powershell
# Enable application-aware processing for SQL Server
$Job = Get-VBRJob -Name "SIS-Database-Nightly"
$JobOptions = $Job.GetOptions()

# Enable VSS integration
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.ViApplicationQuiescing = $true
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.VssSplApplicationProcessing = $true

# SQL Server credentials
$SQLCreds = Get-VBRCredentials -Name "SQL-Admin"
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.Credentials = $SQLCreds

# Transaction log handling
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.SqlBackupOptions.TransactionLogsProcessing = "TruncateOnlyOnSuccessJob"

$Job.SetOptions($JobOptions)
```

### Configure Backup Schedule

```powershell
# K-12 After-Hours Schedule (6 PM - 6 AM)
$Job = Get-VBRJob -Name "SIS-Database-Nightly"

# Daily at 10 PM
$ScheduleOptions = New-VBRDailyOptions -Type Everyday -At "22:00"

Set-VBRJobSchedule -Job $Job -Daily -At "22:00"

# Add backup window (prevent backup running during school hours)
$JobOptions = $Job.GetOptions()
$JobOptions.JobOptions.BackupWindowOptions.IsEnabled = $true
$JobOptions.JobOptions.BackupWindowOptions.BackupWindow = @"
<ScheduleOptions>
  <TimeOfDay>18:00</TimeOfDay>
  <EndTimeOfDay>06:00</EndTimeOfDay>
</ScheduleOptions>
"@
$Job.SetOptions($JobOptions)
```

---

## Backup Monitoring and Reporting

### Check Backup Job Status

```powershell
# Get all backup jobs and their last results
Get-VBRJob | Where-Object {$_.JobType -eq "Backup"} | ForEach-Object {
    $LastSession = $_ | Get-VBRBackupSession | Sort-Object EndTime -Descending | Select-Object -First 1

    [PSCustomObject]@{
        JobName = $_.Name
        LastRun = $LastSession.EndTime
        Result = $LastSession.Result
        Duration = $LastSession.Progress.Duration
        TotalSize = [Math]::Round($LastSession.Progress.ProcessedSize/1GB, 2)
    }
} | Format-Table -AutoSize
```

### Failed Backup Alert Script

```powershell
# Check for failed backups in last 24 hours
$FailedJobs = Get-VBRBackupSession |
    Where-Object {
        $_.EndTime -gt (Get-Date).AddHours(-24) -and
        $_.Result -ne "Success"
    }

if ($FailedJobs) {
    $AlertMessage = @"
BACKUP FAILURE ALERT
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm')

Failed Jobs:
$($FailedJobs | ForEach-Object {
    "- $($_.JobName): $($_.Result) - $($_.Info.Reason)"
} | Out-String)
"@

    # Send email alert (configure SMTP settings)
    Send-MailMessage `
        -To "it-alerts@district.edu" `
        -From "veeam@district.edu" `
        -Subject "VEEAM BACKUP FAILURE - Action Required" `
        -Body $AlertMessage `
        -SmtpServer "smtp.district.edu"
}
```

### Generate Weekly Backup Report

```powershell
# Backup report for last 7 days
$StartDate = (Get-Date).AddDays(-7)
$Sessions = Get-VBRBackupSession | Where-Object {$_.EndTime -gt $StartDate}

$Report = $Sessions | Group-Object Result | ForEach-Object {
    [PSCustomObject]@{
        Status = $_.Name
        Count = $_.Count
        Percentage = [Math]::Round(($_.Count / $Sessions.Count) * 100, 1)
    }
}

Write-Host "`nWeekly Backup Summary ($StartDate to $(Get-Date))" -ForegroundColor Cyan
$Report | Format-Table -AutoSize

# Critical systems check
$CriticalSystems = @("SQL-SIS01", "DC01", "DC02", "FS-Students01")
$CriticalSystems | ForEach-Object {
    $VM = $_
    $LastBackup = Get-VBRBackupSession |
        Where-Object {$_.JobName -like "*$VM*"} |
        Sort-Object EndTime -Descending |
        Select-Object -First 1

    $HoursAgo = ((Get-Date) - $LastBackup.EndTime).TotalHours
    $Status = if ($HoursAgo -lt 24) {"OK"} else {"WARNING"}

    Write-Host "$VM : Last backup $([Math]::Round($HoursAgo, 1)) hours ago [$Status]" -ForegroundColor $(if ($Status -eq "OK") {"Green"} else {"Yellow"})
}
```

---

## Disaster Recovery Testing

### Restore VM to Isolated Network

```powershell
# Get latest restore point
$VMName = "SQL-SIS01"
$RestorePoint = Get-VBRBackup |
    Where-Object {$_.JobName -like "*SIS*"} |
    Get-VBRRestorePoint |
    Where-Object {$_.VMName -eq $VMName} |
    Sort-Object CreationTime -Descending |
    Select-Object -First 1

# Define restore parameters
$ESXiHost = Get-VBRServer -Name "esxi01.district.edu"
$Datastore = Find-VBRViDatastore -Server $ESXiHost -Name "Datastore-DR-Test"
$VMFolder = Find-VBRViFolder -Server $ESXiHost -Name "DR-Testing"
$IsolatedNetwork = Find-VBRViNetwork -Server $ESXiHost -Name "DR-Test-VLAN100"

# Start restore
Start-VBRRestoreVM `
    -RestorePoint $RestorePoint `
    -Server $ESXiHost `
    -Datastore $Datastore `
    -VMFolder $VMFolder `
    -Suffix "-DRTest" `
    -PowerOn:$false `
    -Reason "Quarterly DR test - Q1 2025"

Write-Host "DR test VM created: $VMName-DRTest (powered off)" -ForegroundColor Green
Write-Host "Manually change network to $($IsolatedNetwork.Name) before powering on" -ForegroundColor Yellow
```

### Instant VM Recovery

```powershell
# Instant VM Recovery for emergency situations
$VMName = "DC01"
$RestorePoint = Get-VBRBackup |
    Where-Object {$_.JobName -like "*Domain-Controllers*"} |
    Get-VBRRestorePoint |
    Where-Object {$_.VMName -eq $VMName} |
    Sort-Object CreationTime -Descending |
    Select-Object -First 1

$ESXiHost = Get-VBRServer -Name "esxi02.district.edu"

# Start instant recovery (VM runs from backup)
Start-VBRInstantRecovery `
    -RestorePoint $RestorePoint `
    -Server $ESXiHost `
    -VMName "$VMName-InstantRecovery" `
    -PowerOn `
    -Reason "Emergency: Primary DC failure"

Write-Host "Instant recovery started - VM running from backup file" -ForegroundColor Cyan
Write-Host "Remember to perform Quick Migration to production storage within 24 hours" -ForegroundColor Yellow
```

### Verify SQL Database Integrity Post-Restore

```powershell
# After restoring SIS database server, verify database integrity
$SQLServer = "SQL-SIS01-DRTest"
$Database = "StudentDB"

# Run DBCC CHECKDB
$Query = @"
DBCC CHECKDB('$Database') WITH NO_INFOMSGS, ALL_ERRORMSGS
"@

Invoke-Sqlcmd -ServerInstance $SQLServer -Query $Query -QueryTimeout 600 |
    Where-Object {$_ -match "error|corruption"} |
    ForEach-Object {
        Write-Warning "Database integrity issue detected: $_"
    }

Write-Host "Database integrity check completed for $Database" -ForegroundColor Green
```

---

## Automation with Scheduled Tasks

### Daily Health Check Task

```powershell
# Create scheduled task for daily backup verification
$ScriptPath = "C:\Scripts\Veeam-DailyHealthCheck.ps1"

# Script content
$ScriptContent = @'
Add-PSSnapin VeeamPSSnapin
Connect-VBRServer -Server localhost

$FailedJobs = Get-VBRBackupSession |
    Where-Object {
        $_.EndTime -gt (Get-Date).AddHours(-24) -and
        $_.Result -ne "Success"
    }

if ($FailedJobs) {
    Send-MailMessage -To "it-team@district.edu" `
                     -From "veeam-alerts@district.edu" `
                     -Subject "Backup Failures Detected" `
                     -Body ($FailedJobs | Out-String) `
                     -SmtpServer "smtp.district.edu"
}

Disconnect-VBRServer
'@

$ScriptContent | Out-File -FilePath $ScriptPath -Encoding UTF8

# Create scheduled task
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File $ScriptPath"
$Trigger = New-ScheduledTaskTrigger -Daily -At "7:00 AM"
$Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount

Register-ScheduledTask `
    -TaskName "Veeam-DailyHealthCheck" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "Daily backup health monitoring and alerting"
```

---

## Troubleshooting Common Issues

### Issue: "Insufficient permissions to process VM"

**Cause:** Veeam service account lacks vCenter permissions

**Solution:**
```powershell
# Verify vCenter connection credentials
Get-VBRServer | Where-Object {$_.Type -eq "VC"} | Select-Object Name, Description

# Update credentials
$vCenter = Get-VBRServer -Name "vcenter.district.edu"
$NewCreds = Get-Credential -Message "Enter vCenter admin credentials"
Set-VBRServer -Server $vCenter -Credentials $NewCreds
```

### Issue: "Backup job exceeds backup window"

**Cause:** Backup job runs too long and overlaps school hours

**Solution:**
```powershell
# Check job duration history
$JobName = "File-Server-Students"
Get-VBRBackupSession |
    Where-Object {$_.JobName -eq $JobName} |
    Sort-Object EndTime -Descending |
    Select-Object -First 10 |
    Select-Object JobName, CreationTime, EndTime, @{N='Duration(min)';E={$_.Progress.Duration.TotalMinutes}}

# Consider:
# 1. Reduce retention points
# 2. Enable forever-forward incremental backup mode
# 3. Split large VMs into separate jobs
```

### Issue: "Application-aware processing failed"

**Cause:** SQL Server credentials invalid or VSS errors

**Solution:**
```powershell
# Test SQL credentials
$SQLCreds = Get-VBRCredentials -Name "SQL-Admin"
$TestConnection = Invoke-Sqlcmd -ServerInstance "SQL-SIS01" -Credential $SQLCreds -Query "SELECT @@VERSION"

if ($TestConnection) {
    Write-Host "SQL credentials valid" -ForegroundColor Green
} else {
    Write-Warning "SQL credentials invalid - update in Veeam credential manager"
}

# Fallback: Disable application-aware processing temporarily
$Job = Get-VBRJob -Name "SIS-Database-Nightly"
$JobOptions = $Job.GetOptions()
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.ViApplicationQuiescing = $false
$Job.SetOptions($JobOptions)
```

---

## Performance Optimization

### Enable WAN Acceleration

```powershell
# For remote site backups over WAN
$Job = Get-VBRJob -Name "RemoteSite-Backups"
$JobOptions = $Job.GetOptions()
$JobOptions.ViSourceOptions.WanAcceleration.IsEnabled = $true
$Job.SetOptions($JobOptions)
```

### Parallel Processing

```powershell
# Increase concurrent VM processing (requires adequate proxy resources)
$Job = Get-VBRJob -Name "SIS-Database-Nightly"
Set-VBRJobAdvancedBackupOptions -Job $Job -ParallelBackupCount 4
```

---

## Additional Resources

- [Veeam PowerShell Reference](https://helpcenter.veeam.com/docs/backup/powershell/)
- [Veeam Best Practices Guide](https://bp.veeam.com/)
- [K-12 Data Protection Strategies](https://www.cosn.org/)
