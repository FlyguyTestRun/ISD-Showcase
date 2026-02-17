# Hyper-V Integration for Disaster Recovery

## Overview

Veeam Backup & Replication supports Microsoft Hyper-V environments with checkpoint-based backups, ReFS integration, and Hyper-V Replica orchestration. This document covers Hyper-V-specific configurations for K-12 disaster recovery implementations.

---

## Hyper-V Infrastructure Requirements

### Supported Platforms

**Hyper-V Server:**
- Windows Server 2022 Datacenter/Standard
- Windows Server 2019 Datacenter/Standard
- Windows Server 2016 Datacenter/Standard
- Microsoft Hyper-V Server 2019/2016 (Free edition)

**Failover Clustering:**
- Windows Server Failover Clustering (WSFC) with Cluster Shared Volumes (CSV)
- Scale-Out File Server (SOFS) for SMB 3.x storage
- Storage Spaces Direct (S2D) hyper-converged configurations

**Storage:**
- ReFS (Resilient File System) with block cloning support
- SMB 3.x file shares (SOFS, NetApp, Dell EMC)
- CSV (Cluster Shared Volumes) on SAN or local storage
- iSCSI and FC SAN storage

### Network Connectivity

```
Veeam Backup Server ──┐
                      │
                      ├──> Hyper-V Host (WinRM 5985/5986)
                      │    └──> VM Checkpoint Management
                      │
                      ├──> SCVMM Server (Optional - HTTPS 8090)
                      │    └──> Centralized Management
                      │
                      └──> Backup Repository (SMB/iSCSI/FC)
```

**Firewall Rules Required:**
- Veeam Server → Hyper-V Host: TCP 5985 (WinRM HTTP), TCP 5986 (WinRM HTTPS)
- Veeam Server → SCVMM: TCP 8090 (HTTPS)
- Veeam Proxy → Hyper-V Host: TCP 6162 (Veeam Data Mover)
- Veeam Proxy → Repository: TCP 445 (SMB), TCP 3260 (iSCSI)

---

## Connecting Veeam to Hyper-V

### Add Standalone Hyper-V Host

```powershell
# Add standalone Hyper-V server to Veeam
$HyperVHost = "hyperv01.district.edu"
$HostCreds = Get-Credential -Message "Enter Hyper-V administrator credentials"

Add-VBRHvServer `
    -Name $HyperVHost `
    -Credential $HostCreds `
    -Description "K-12 Hyper-V Host - Building A"

# Verify connection
$HVHost = Get-VBRServer -Type HvServer | Where-Object {$_.Name -eq $HyperVHost}
if ($HVHost.IsAvailable) {
    Write-Host "Hyper-V host connected successfully" -ForegroundColor Green

    # List VMs
    $VMs = Get-VBRHvEntity -Server $HVHost -Type VM
    Write-Host "  Virtual Machines: $($VMs.Count)" -ForegroundColor Cyan
} else {
    Write-Warning "Hyper-V host connection failed"
}
```

### Add Hyper-V Failover Cluster

```powershell
# Add Hyper-V cluster (all nodes automatically discovered)
$ClusterName = "HV-Cluster-01.district.edu"
$ClusterCreds = Get-Credential -Message "Enter cluster administrator credentials"

Add-VBRHvCluster `
    -Name $ClusterName `
    -Credential $ClusterCreds `
    -Description "K-12 Production Hyper-V Cluster (3 nodes)"

# Verify cluster nodes
$Cluster = Get-VBRServer -Type HvCluster | Where-Object {$_.Name -eq $ClusterName}
$ClusterNodes = $Cluster.GetChildServers()

Write-Host "Hyper-V Cluster discovered:" -ForegroundColor Cyan
foreach ($Node in $ClusterNodes) {
    Write-Host "  - $($Node.Name) [$($Node.Info.OSVersion)]" -ForegroundColor Gray
}
```

### Add SCVMM (System Center Virtual Machine Manager)

```powershell
# For centralized management of multiple Hyper-V clusters
$SCVMM = "scvmm.district.edu"
$SCVMMCreds = Get-Credential -Message "Enter SCVMM administrator credentials"

Add-VBRHvCluster `
    -Name $SCVMM `
    -Credential $SCVMMCreds `
    -Type SCVMM `
    -Description "System Center VMM - Manages all district Hyper-V infrastructure"

# SCVMM automatically provides access to all managed Hyper-V hosts and clusters
```

---

## Hyper-V Backup Modes

### Production Checkpoint (Recommended)

**Uses VSS-based snapshots for application-consistent backups.**

```powershell
# Create backup job with production checkpoints
$Job = Add-VBRHvBackupJob -Name "SIS-Database-HyperV" -Entity (Get-VBRHvEntity -Name "SQL-SIS-HV01")

# Configure checkpoint settings
$JobOptions = $Job.GetOptions()
$JobOptions.HvSourceOptions.VmAttributesOptions.UseCheckpoints = $true
$JobOptions.HvSourceOptions.VmAttributesOptions.VssOptions.Enabled = $true
$JobOptions.HvSourceOptions.VmAttributesOptions.VssOptions.IgnoreErrors = $false

$Job.SetOptions($JobOptions)

Write-Host "Backup job configured for application-consistent backups (VSS)" -ForegroundColor Green
```

**Production Checkpoint Workflow:**
1. Veeam triggers Hyper-V to create production checkpoint (VSS snapshot)
2. VSS quiesces applications (SQL Server, Exchange, etc.)
3. Hyper-V creates AVHD/AVHDX differencing disk
4. Veeam backs up VM from checkpoint
5. Checkpoint automatically deleted after backup completes

### Standard Checkpoint (Crash-Consistent)

**Used when VSS not available or VM lacks Integration Services.**

```powershell
# Fallback to standard checkpoints
$JobOptions.HvSourceOptions.VmAttributesOptions.VssOptions.Enabled = $false
$Job.SetOptions($JobOptions)
```

---

## ReFS Integration and Fast Cloning

### ReFS Block Cloning Benefits

**When backup repository uses ReFS (Windows Server 2016+):**
- Synthetic full backups complete in seconds (block-level cloning instead of full copy)
- Per-VM backup chains reduce storage overhead
- Instant restore operations (clone blocks from backup to production)

### Configure ReFS Repository

```powershell
# Add ReFS-formatted backup repository
$RepoPath = "R:\VeeamBackups"  # ReFS volume

Add-VBRBackupRepository `
    -Name "Backup-Repo-ReFS" `
    -Folder $RepoPath `
    -Type Windows `
    -Server (Get-VBRServer -Type Windows -Name "backup-server01.district.edu")

# Enable per-VM backup files (required for ReFS fast cloning)
$Repo = Get-VBRBackupRepository -Name "Backup-Repo-ReFS"
Set-VBRBackupRepository -Repository $Repo -PerVMBackupFiles $true
```

### Synthetic Full Backup with ReFS

```powershell
# Create backup job with weekly synthetic full
$Job = Get-VBRJob -Name "SIS-Database-HyperV"
$JobOptions = $Job.GetOptions()

# Enable synthetic full backups
$JobOptions.BackupStorageOptions.EnableFullBackup = $true
$JobOptions.BackupStorageOptions.BackupIsAttached = $false

# Schedule synthetic full weekly (Saturday nights)
$JobOptions.ScheduleOptions.OptionsDaily.Type = "Everyday"
$JobOptions.ScheduleOptions.OptionsPeriod.FullPeriod = 7  # Days

$Job.SetOptions($JobOptions)

Write-Host "Synthetic full backups configured - leveraging ReFS block cloning" -ForegroundColor Green
Write-Host "  Synthetic fulls complete in <5 minutes (vs hours for traditional full)" -ForegroundColor Cyan
```

---

## Hyper-V Replica Integration

### Veeam + Hyper-V Replica Combined Solution

**Architecture:**
```
Primary Site                           DR Site
┌──────────────────────┐              ┌──────────────────────┐
│ Hyper-V Production   │              │ Hyper-V DR Cluster   │
│ - SQL-SIS-HV01       │──Replica──>  │ - SQL-SIS-HV01-DR    │
│                      │  (5 min RPO) │   (Powered Off)      │
└──────────────────────┘              └──────────────────────┘
         │                                      │
         │ Veeam Backup                         │ Veeam Backup
         ▼                                      ▼
  Backup Repository                     Offsite Repository
```

**Benefits:**
- Hyper-V Replica provides near-continuous replication (5-15 minute RPO)
- Veeam provides backup retention and long-term recovery
- Combined RTO <10 minutes for critical systems

### Configure Hyper-V Replica

```powershell
# On primary Hyper-V host
$PrimaryVM = "SQL-SIS-HV01"
$ReplicaServer = "hyperv-dr01.district.edu"

Enable-VMReplication `
    -VMName $PrimaryVM `
    -ReplicaServerName $ReplicaServer `
    -ReplicaServerPort 443 `
    -AuthenticationType Kerberos `
    -ReplicationFrequencySec 300 `  # 5 minutes
    -CompressionEnabled $true `
    -RecoveryHistory 24  # 24 recovery points

# Start initial replication
Start-VMInitialReplication -VMName $PrimaryVM

Write-Host "Hyper-V Replica enabled for $PrimaryVM" -ForegroundColor Green
Write-Host "  Replica Server: $ReplicaServer" -ForegroundColor Gray
Write-Host "  RPO: 5 minutes | Recovery Points: 24" -ForegroundColor Gray
```

### Monitor Hyper-V Replica Health

```powershell
# Check replication health
Get-VMReplication |
    Where-Object {$_.State -ne "Replicating"} |
    Select-Object VMName, State, Health, LastReplicationTime |
    Format-Table -AutoSize

# Failover test (quarterly DR drill)
$VM = "SQL-SIS-HV01"
Start-VMFailover -VMName "$VM-DR" -AsTest -Confirm:$false

Write-Host "Test failover started for $VM" -ForegroundColor Cyan
Write-Host "Replica VM will boot from checkpoint for testing" -ForegroundColor Gray
Write-Host "Production VM remains unaffected" -ForegroundColor Green

# After testing, stop test failover
Stop-VMFailover -VMName "$VM-DR"
```

---

## Hyper-V Instant Recovery

### On-Host Instant Recovery

**Run VM directly from compressed backup on Veeam repository.**

```powershell
# Get latest restore point
$RestorePoint = Get-VBRBackup |
    Where-Object {$_.JobName -eq "SIS-Database-HyperV"} |
    Get-VBRRestorePoint |
    Where-Object {$_.VMName -eq "SQL-SIS-HV01"} |
    Sort-Object CreationTime -Descending |
    Select-Object -First 1

# Start instant recovery on production Hyper-V host
$HyperVHost = Get-VBRServer -Type HvServer -Name "hyperv01.district.edu"

Start-VBRHvInstantRecovery `
    -RestorePoint $RestorePoint `
    -Server $HyperVHost `
    -VMName "SQL-SIS-HV01-InstantRecovery" `
    -PowerOn `
    -Reason "Emergency recovery: Primary SIS database server failure"

Write-Host "Instant Recovery initiated" -ForegroundColor Cyan
Write-Host "  VM booting from backup repository (ETA: 2-3 minutes)" -ForegroundColor Gray
Write-Host "  Network connectivity: Disabled by default (enable manually after verification)" -ForegroundColor Yellow
```

### Quick Migration to Production Storage

```powershell
# After instant recovery VM is running, migrate to CSV
$InstantRecoveryVM = Get-VBRHvInstantRecovery | Where-Object {$_.VMName -eq "SQL-SIS-HV01-InstantRecovery"}

# Target CSV path
$CSVPath = "C:\ClusterStorage\Volume1\"

# Publish VM to production storage
Publish-VBRHvBackupContent `
    -Session $InstantRecoveryVM `
    -TargetPath $CSVPath `
    -Reason "Migrating instant recovery VM to production CSV"

Write-Host "Quick Migration started - VM migrating to production storage" -ForegroundColor Green
Write-Host "  VM remains online during migration (no downtime)" -ForegroundColor Cyan
Write-Host "  Migration time estimate: 20-45 minutes for 500 GB VM" -ForegroundColor Gray
```

---

## Application Item-Level Restore

### SQL Server Database Restore

**Restore individual SQL databases without recovering entire VM.**

```powershell
# Get restore point with SQL databases
$RestorePoint = Get-VBRApplicationRestorePoint |
    Where-Object {$_.VMName -eq "SQL-SIS-HV01" -and $_.Type -eq "SqlDatabase"} |
    Sort-Object CreationTime -Descending |
    Select-Object -First 1

# Get list of databases
$Databases = Get-VBRApplicationRestoreDatabase -RestorePoint $RestorePoint

Write-Host "Available databases for restore:" -ForegroundColor Cyan
$Databases | Select-Object Name, SizeMB | Format-Table

# Restore specific database
$DBName = "StudentDB"
$TargetServer = "SQL-SIS-HV01.district.edu"

Start-VESQLRestoreDatabase `
    -RestorePoint $RestorePoint `
    -DatabaseName $DBName `
    -Server $TargetServer `
    -Instance "MSSQLSERVER" `
    -TargetDatabaseName "StudentDB_Restored_$(Get-Date -Format 'yyyyMMdd')" `
    -Reason "Recover student grade data from 2 weeks ago for audit"

Write-Host "SQL database restore started" -ForegroundColor Green
Write-Host "  Restored as: StudentDB_Restored_$(Get-Date -Format 'yyyyMMdd')" -ForegroundColor Gray
Write-Host "  Production database remains online" -ForegroundColor Cyan
```

### Active Directory Object Restore

**Restore deleted user accounts, OUs, or group memberships.**

```powershell
# Get AD restore point
$RestorePoint = Get-VBRApplicationRestorePoint |
    Where-Object {$_.VMName -eq "DC01-HyperV" -and $_.Type -eq "ActiveDirectory"} |
    Sort-Object CreationTime -Descending |
    Select-Object -First 1

# Search for deleted user object
$DeletedUser = "student12345"

Start-VBRExplorer ActiveDirectory -RestorePoint $RestorePoint

# Use Veeam Explorer for Active Directory GUI to:
# 1. Browse deleted objects in Deleted Items container
# 2. Select specific user account
# 3. Restore to production AD (attributes, group memberships preserved)
```

---

## Integration with Windows Admin Center (WAC)

### Monitor Backups from WAC

**Veeam plugin for Windows Admin Center provides centralized visibility.**

```powershell
# Install Veeam extension in WAC (PowerShell on WAC server)
Import-Module "$env:ProgramFiles\Windows Admin Center\PowerShell\Modules\ExtensionTools"

Add-WAExtension -ExtensionId "veeam.backup-management" -Force

Write-Host "Veeam extension added to Windows Admin Center" -ForegroundColor Green
Write-Host "Access: https://wac.district.edu/ > [Hyper-V Host] > Tools > Veeam Backup" -ForegroundColor Cyan
```

---

## Performance Optimization

### Parallel Processing

```powershell
# Configure concurrent VM processing
$Job = Get-VBRJob -Name "SIS-Database-HyperV"
Set-VBRJobAdvancedBackupOptions -Job $Job -ParallelBackupCount 2  # Adjust based on host resources

# Throttle network bandwidth during school hours
$JobOptions = $Job.GetOptions()
$JobOptions.HvSourceOptions.BackupNetworkOptions.IsEnabled = $true
$JobOptions.HvSourceOptions.BackupNetworkOptions.ThrottlingSpeed = 50  # Mbps during school
$Job.SetOptions($JobOptions)
```

### Storage Optimization

```powershell
# Enable Veeam inline deduplication and compression
$Job = Get-VBRJob -Name "File-Server-HyperV"
Set-VBRJobAdvancedStorageOptions -Job $Job `
    -CompressionLevel 5 `  # 0=None, 9=Extreme (5=Optimal balance)
    -StorageOptimization Dedupe  # Dedupe | LAN | WAN
```

---

## Disaster Recovery to Azure (Hybrid Cloud DR)

### Backup Copy to Azure Blob Storage

```powershell
# Add Azure Blob storage as backup repository
$AzureAccount = "veeambackups"
$AzureContainer = "kisd-dr-backups"
$AzureKey = Read-Host -Prompt "Enter Azure storage account key" -AsSecureString

Add-VBRAzureBlobStorageRepository `
    -Name "Azure-DR-Repository" `
    -AzureAccount $AzureAccount `
    -AzureKey $AzureKey `
    -Container $AzureContainer `
    -Description "Offsite DR backups in Azure West US 2"

# Create backup copy job to Azure
Add-VBRBackupCopyJob `
    -Name "SIS-Database-Azure-Copy" `
    -BackupJob (Get-VBRJob -Name "SIS-Database-HyperV") `
    -Repository (Get-VBRBackupRepository -Name "Azure-DR-Repository") `
    -ScheduleType "AfterNewBackup"

Write-Host "Backup copy to Azure configured" -ForegroundColor Green
Write-Host "  Retention: 30 days in Azure Blob (offsite protection)" -ForegroundColor Cyan
```

---

## Hyper-V vs. VMware Decision Matrix

| Feature | Hyper-V | VMware vSphere |
|---------|---------|----------------|
| Licensing Cost | Included with Windows Server | Requires vSphere licenses |
| Integration | Native Windows integration | Best for heterogeneous environments |
| ReFS Fast Cloning | ✅ Yes (Windows Server 2016+) | ❌ No (VMFS) |
| Live Migration | ✅ Yes (no shared storage required) | ✅ Yes (vMotion) |
| HA/Clustering | Windows Failover Clustering | vSphere HA |
| Management | Windows Admin Center / SCVMM | vCenter Server |
| Backup Performance | Similar (with proper tuning) | Similar (with proper tuning) |
| **K-12 Recommendation** | **Cost-effective for Microsoft-heavy environments** | **Better for mixed OS environments** |

---

## Best Practices Summary

1. **Use production checkpoints** for all application-aware backups (SQL, Exchange, AD)
2. **Deploy ReFS repositories** to leverage synthetic full fast cloning (10x faster)
3. **Combine Hyper-V Replica + Veeam** for sub-10-minute RTO on critical systems
4. **Enable per-VM backup chains** on ReFS for faster instant recovery
5. **Configure CSV as preferred path** for backup operations on clustered Hyper-V
6. **Monitor checkpoint removal** - ensure checkpoints deleted within 30 minutes of backup completion
7. **Test instant recovery quarterly** during school breaks (validate <30-minute RTO)
8. **Leverage Azure Blob for offsite** - cost-effective cloud tier for disaster recovery
9. **Application item-level restore** reduces recovery time (restore individual databases vs full VMs)
10. **Windows Admin Center integration** provides unified management console for Hyper-V + Veeam

---

## Troubleshooting Common Issues

### Issue: "Checkpoint creation failed"

**Cause:** Hyper-V snapshot timeout (VM has heavy I/O during backup window)

**Solution:**
```powershell
# Increase VSS timeout (default 10 minutes)
$Job = Get-VBRJob -Name "SIS-Database-HyperV"
$JobOptions = $Job.GetOptions()
$JobOptions.HvSourceOptions.VmAttributesOptions.VssOptions.VssSnapshotOptions.ApplicationQuiescenceTimeoutSeconds = 1800  # 30 minutes
$Job.SetOptions($JobOptions)
```

### Issue: "Instant recovery VM has network conflict"

**Cause:** VM booted with same IP as production

**Solution:**
```powershell
# Disable network adapter automatically on instant recovery
$InstantRecoveryOptions = Get-VBRHvInstantRecoveryOptions
$InstantRecoveryOptions.DisableNetworkAdapter = $true
Set-VBRHvInstantRecoveryOptions -Options $InstantRecoveryOptions
```

### Issue: "Synthetic full backup takes hours (not leveraging ReFS)"

**Cause:** Repository not using ReFS or per-VM backup chains disabled

**Solution:**
```powershell
# Verify repository file system
$Repo = Get-VBRBackupRepository -Name "Backup-Repo-01"
if ($Repo.Path -notmatch "R:\\") {
    Write-Warning "Repository not on ReFS volume - fast cloning unavailable"
    Write-Host "Migrate repository to ReFS-formatted volume for 10-100x faster synthetic fulls" -ForegroundColor Yellow
}

# Verify per-VM chains enabled
if (-not $Repo.PerVMBackupFiles) {
    Set-VBRBackupRepository -Repository $Repo -PerVMBackupFiles $true
    Write-Host "Per-VM backup chains enabled" -ForegroundColor Green
}
```
