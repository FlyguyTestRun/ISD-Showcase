# VMware vSphere Integration for Disaster Recovery

## Overview

Veeam Backup & Replication integrates with VMware vSphere for application-consistent backups, instant VM recovery, and granular restore capabilities. This document covers VMware-specific configurations for K-12 disaster recovery implementations.

---

## vSphere Infrastructure Requirements

### Supported Platforms

**vCenter Server:**
- vCenter 8.0 U2, 8.0 U1, 8.0
- vCenter 7.0 U3, 7.0 U2, 7.0 U1, 7.0
- vCenter 6.7 U3 (legacy support)

**ESXi Hypervisor:**
- ESXi 8.0 U2, 8.0 U1, 8.0
- ESXi 7.0 U3, 7.0 U2, 7.0 U1, 7.0
- ESXi 6.7 U3 (legacy support)

**Storage:**
- vSAN 8.0, 7.0, 6.7
- FC/iSCSI SAN (EMC, NetApp, HPE, Dell)
- NFS datastores (NFSv3, NFSv4.1)
- Local VMFS datastores

### Network Connectivity

```
Veeam Backup Server ──┐
                      │
                      ├──> vCenter Server (HTTPS 443)
                      │    └──> VMware API (VM metadata, snapshots)
                      │
                      ├──> ESXi Hosts (HTTPS 902/443)
                      │    └──> Backup Proxy Traffic (NBD, NBDSSL, HotAdd)
                      │
                      └──> Backup Repository (SMB/NFS)
```

**Firewall Rules Required:**
- Veeam Server → vCenter: TCP 443 (HTTPS)
- Veeam Server → ESXi: TCP 902 (NBD/NBDSSL), TCP 443 (HTTPS)
- Veeam Proxy → ESXi: TCP 902 (Network Mode), Direct SCSI (HotAdd Mode)
- Veeam Proxy → Repository: TCP 445 (SMB) or TCP 2049 (NFS)

---

## Connecting Veeam to vCenter

### Add vCenter Server

```powershell
# Add vCenter to Veeam infrastructure
$vCenterServer = "vcenter.district.edu"
$vCenterUser = "veeam-backup@vsphere.local"  # Dedicated service account
$vCenterPassword = Read-Host -Prompt "Enter vCenter password" -AsSecureString

$Creds = New-Object System.Management.Automation.PSCredential($vCenterUser, $vCenterPassword)

Add-VBRvCenter `
    -Name $vCenterServer `
    -Credential $Creds `
    -Port 443 `
    -Description "K-12 School District vCenter Server"

# Verify connection
$vCenter = Get-VBRServer -Type VC | Where-Object {$_.Name -eq $vCenterServer}
if ($vCenter.IsAvailable) {
    Write-Host "vCenter connected successfully" -ForegroundColor Green
    Write-Host "  ESXi Hosts: $($vCenter.GetChildServers().Count)" -ForegroundColor Cyan
} else {
    Write-Warning "vCenter connection failed"
}
```

### Service Account Permissions

**Minimum Required vCenter Privileges:**

1. Create dedicated service account in vSphere:
   - User: `veeam-backup@vsphere.local`
   - Password policy: Non-expiring, complex password

2. Assign vCenter role:
   - Role Name: "Veeam Backup Administrator"
   - Permissions:

```
Datastore:
  - Browse datastore
  - Low level file operations
  - Update virtual machine files
  - Update virtual machine metadata

Virtual Machine > Change Configuration:
  - Add existing disk
  - Add new disk
  - Add or remove device
  - Advanced configuration
  - Change CPU count
  - Change Memory
  - Change Settings
  - Change resource
  - Modify device settings
  - Remove disk
  - Set annotation

Virtual Machine > Interaction:
  - Power off
  - Power on

Virtual Machine > Provisioning:
  - Allow disk access
  - Allow read-only disk access

Virtual Machine > Snapshot Management:
  - Create snapshot
  - Remove snapshot
  - Revert to snapshot

Resource:
  - Assign virtual machine to resource pool
```

**PowerCLI Configuration:**
```powershell
# Connect to vCenter with PowerCLI
Connect-VIServer -Server vcenter.district.edu -User veeam-backup@vsphere.local

# Create custom role
$privileges = @(
    'Datastore.Browse',
    'Datastore.FileManagement',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.EditDevice',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Provisioning.DiskAccess',
    'VirtualMachine.State.CreateSnapshot',
    'VirtualMachine.State.RemoveSnapshot',
    'Resource.AssignVMToPool'
)

New-VIRole -Name "Veeam Backup Administrator" -Privilege (Get-VIPrivilege -Id $privileges)

# Assign role to service account at vCenter level
New-VIPermission -Entity (Get-Folder -NoRecursion) -Principal "veeam-backup@vsphere.local" -Role "Veeam Backup Administrator" -Propagate:$true
```

---

## Backup Proxy Configuration

### Transport Modes

**Network Mode (NBD/NBDSSL):**
- Default mode, works in all environments
- Data transmitted over network from ESXi to proxy
- Recommended for: Mixed storage environments, encrypted VMs, small-scale deployments

**Virtual Appliance Mode (HotAdd):**
- Veeam proxy deployed as VM in same vCenter
- Attaches VM disks directly to proxy via SCSI bus
- Recommended for: Large-scale deployments, high-density backups, same datastore performance

**Direct SAN Mode:**
- Veeam proxy has direct FC/iSCSI SAN access
- Reads data directly from SAN LUNs
- Recommended for: SAN-based storage, maximum performance

### Deploy Backup Proxy

```powershell
# Deploy virtual backup proxy (HotAdd mode)
$vCenter = Get-VBRServer -Type VC -Name "vcenter.district.edu"
$ESXiHost = Get-VBRServer | Where-Object {$_.Type -eq "ESXi" -and $_.Name -eq "esxi01.district.edu"}
$Datastore = Find-VBRViDatastore -Server $ESXiHost -Name "Datastore-Production-01"

# Create proxy server
Add-VBRViProxy `
    -Name "Veeam-Proxy-01" `
    -Server $vCenter `
    -Description "Virtual backup proxy for HotAdd transport" `
    -FailoverToNetwork $true

# Configure transport modes
$Proxy = Get-VBRViProxy -Name "Veeam-Proxy-01"
Set-VBRViProxy -Proxy $Proxy -TransportMode Auto  # Auto-select between HotAdd and NBD

# Set concurrent task limit
Set-VBRViProxy -Proxy $Proxy -MaxTasksCount 4  # Adjust based on proxy resources (2 vCPU, 8 GB RAM = 4 tasks)
```

---

## VMware Snapshot Integration

### Changed Block Tracking (CBT)

**Enable CBT on VMs:**
```powershell
# Enable CBT for all production VMs
Get-VM | Where-Object {$_.Name -like "*SIS*" -or $_.Name -like "*DC*"} | ForEach-Object {
    $vm = $_
    $vmView = $vm | Get-View

    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.ChangeTrackingEnabled = $true

    $vmView.ReconfigVM($spec)
    Write-Host "CBT enabled for: $($vm.Name)" -ForegroundColor Green
}
```

**Benefits of CBT:**
- Incremental backups only transfer changed blocks (instead of full disks)
- Reduces backup time by 80-95% after initial full backup
- Minimizes storage repository growth
- Critical for large VMs (file servers, databases)

### Application-Consistent Snapshots

**VMware Tools Quiescing:**
```powershell
# Ensure VMware Tools installed and running
Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"} | Select-Object Name, @{N='ToolsStatus';E={$_.ExtensionData.Guest.ToolsStatus}}

# Identify VMs with outdated or missing tools
Get-VM | Where-Object {
    $_.ExtensionData.Guest.ToolsStatus -ne "toolsOk"
} | ForEach-Object {
    Write-Warning "$($_.Name): VMware Tools status = $($_.ExtensionData.Guest.ToolsStatus)"
}
```

**Veeam Guest Processing:**
```powershell
# Enable application-aware processing (uses VMware Tools + VSS)
$Job = Get-VBRJob -Name "SIS-Database-Nightly"
$JobOptions = $Job.GetOptions()

# Enable VMware Tools quiescing
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.ViApplicationQuiescing = $true

# Enable Microsoft VSS for SQL Server
$JobOptions.ViSourceOptions.VmAttributesOptions.ApplicationProcessingOptions.VssSplApplicationProcessing = $true

$Job.SetOptions($JobOptions)
```

---

## Instant VM Recovery

### Use Case: Emergency Recovery

**Scenario:** SIS database server suffers hardware failure during student enrollment period. Recovery must be completed within 30 minutes to minimize registration impact.

**Solution:** Instant VM Recovery runs VM directly from compressed backup file on repository, bypassing traditional restore time.

```powershell
# Get latest restore point
$RestorePoint = Get-VBRBackup |
    Where-Object {$_.JobName -eq "SIS-Database-Nightly"} |
    Get-VBRRestorePoint |
    Where-Object {$_.VMName -eq "SQL-SIS01"} |
    Sort-Object CreationTime -Descending |
    Select-Object -First 1

# Target ESXi host and datastore
$ESXiHost = Get-VBRServer -Type ESXi -Name "esxi02.district.edu"
$Datastore = Find-VBRViDatastore -Server $ESXiHost -Name "Datastore-Production-02"

# Start Instant VM Recovery
$InstantRecovery = Start-VBRInstantRecovery `
    -RestorePoint $RestorePoint `
    -Server $ESXiHost `
    -Datastore $Datastore `
    -VMName "SQL-SIS01-InstantRecovery" `
    -PowerOn `
    -Reason "Emergency: Hardware failure on primary SIS server"

Write-Host "Instant Recovery started - VM booting from backup repository" -ForegroundColor Cyan
Write-Host "  VM Name: SQL-SIS01-InstantRecovery" -ForegroundColor Gray
Write-Host "  Host: $($ESXiHost.Name)" -ForegroundColor Gray
Write-Host "  Running from: Backup Repository (temporary)" -ForegroundColor Yellow
Write-Host "`nNext Step: Perform Quick Migration to production storage within 96 hours" -ForegroundColor Yellow
```

### Quick Migration (Storage vMotion from Backup)

**After VM is running from backup repository, migrate to production storage:**

```powershell
# Quick Migration to production datastore
$InstantRecoveryVM = Get-VBRInstantRecovery | Where-Object {$_.VMName -eq "SQL-SIS01-InstantRecovery"}

# Target production datastore
$ProductionDatastore = Find-VBRViDatastore -Name "Datastore-Production-01"

# Start Storage vMotion
Publish-VBRBackupContent `
    -Session $InstantRecoveryVM `
    -TargetDatastore $ProductionDatastore `
    -Reason "Migrating instant recovery VM to production storage"

Write-Host "Quick Migration started - VM will be migrated to production datastore" -ForegroundColor Green
Write-Host "  This process runs in background and does not impact VM availability" -ForegroundColor Cyan
```

---

## vSphere Replication Integration

### SAN Snapshot Integration

**For SAN-based environments (NetApp, EMC, HPE):**

```powershell
# Add NetApp storage system to Veeam
$StorageSystem = "netapp-filer01.district.edu"
$StorageCreds = Get-Credential -Message "Enter NetApp admin credentials"

Add-VBRNetAppStorageSystem `
    -Server $StorageSystem `
    -Credentials $StorageCreds `
    -Description "NetApp FAS for SIS database storage"

# Create backup job from storage snapshots
$Job = Add-VBRViBackupJob -Name "SIS-Database-SAN-Snapshot" -Entity (Get-VBRServer | Get-VBRViEntity -Name "SQL-SIS01")

# Enable storage snapshot integration
$JobOptions = $Job.GetOptions()
$JobOptions.ViSourceOptions.UseStorageSnapshots = $true
$Job.SetOptions($JobOptions)
```

**Benefits:**
- Near-zero production impact (snapshots taken at SAN level)
- Faster backup completion (data read from snapshot, not live VM)
- Reduced VMware snapshot duration

---

## vSphere High Availability (HA) Considerations

### Protecting DR Test VMs

```powershell
# Disable HA restart for DR test VMs (prevent conflicts)
Connect-VIServer -Server vcenter.district.edu

$DRTestVMs = Get-VM | Where-Object {$_.Name -like "*-DRTest"}

foreach ($VM in $DRTestVMs) {
    Get-VMResourceConfiguration -VM $VM |
        Set-VMResourceConfiguration -HaRestartPriority Disabled

    Write-Host "HA disabled for: $($VM.Name)" -ForegroundColor Yellow
}
```

### HA Slot Size Calculation

**Account for instant recovery VMs in HA admission control:**

```powershell
# Get cluster configuration
$Cluster = Get-Cluster -Name "Production-Cluster"

# HA slot size calculation
$HAConfig = $Cluster.ExtensionData.Configuration.DasConfig

Write-Host "HA Admission Control:" -ForegroundColor Cyan
Write-Host "  Slot Size (vCPU): $($HAConfig.AdmissionControlPolicy.SlotPolicy.Cpu) MHz" -ForegroundColor Gray
Write-Host "  Slot Size (Memory): $($HAConfig.AdmissionControlPolicy.SlotPolicy.Memory) MB" -ForegroundColor Gray
Write-Host "  Failover Capacity: $($HAConfig.AdmissionControlPolicy.FailoverLevel) host failures" -ForegroundColor Gray

# Reserve capacity for instant recovery operations
# If you need to instantly recover a 4 vCPU, 16 GB VM, ensure cluster has spare capacity
```

---

## Monitoring vSphere Backup Performance

### Check Snapshot Duration

```powershell
# Long snapshot durations indicate performance issues
Get-VBRBackupSession |
    Where-Object {$_.EndTime -gt (Get-Date).AddHours(-24)} |
    Select-Object JobName, @{N='SnapshotDuration';E={$_.Progress.SnapshotDuration}}, Result |
    Where-Object {$_.SnapshotDuration.TotalMinutes -gt 15} |
    Format-Table -AutoSize

# Snapshots >15 minutes indicate:
# - Storage performance issues
# - High VM I/O preventing quiescing
# - Insufficient IOPS on datastore
```

### Backup Window Analysis

```powershell
# Analyze backup window utilization
$BackupSessions = Get-VBRBackupSession | Where-Object {$_.EndTime -gt (Get-Date).AddDays(-7)}

$BackupSessions | ForEach-Object {
    $StartHour = $_.CreationTime.Hour
    $EndHour = $_.EndTime.Hour

    $InSchoolHours = ($EndHour -ge 7 -and $EndHour -lt 18)

    [PSCustomObject]@{
        JobName = $_.JobName
        StartTime = $_.CreationTime.ToString("yyyy-MM-dd HH:mm")
        EndTime = $_.EndTime.ToString("yyyy-MM-dd HH:mm")
        Duration = $_.Progress.Duration
        CompletedInWindow = -not $InSchoolHours
    }
} | Where-Object {$_.CompletedInWindow -eq $false} |
Format-Table -AutoSize

# Flag jobs that ran past 6 AM
```

---

## Disaster Recovery to Hyper-V (Cross-Hypervisor Recovery)

### Export VM from Veeam to Hyper-V Format

```powershell
# In disaster scenario where vSphere infrastructure is unavailable,
# restore VMs to Hyper-V cluster

$RestorePoint = Get-VBRRestorePoint -Name "SQL-SIS01" | Select-Object -First 1

# Export VM in VHD format for Hyper-V import
Export-VBRBackupItem `
    -RestorePoint $RestorePoint `
    -TargetPath "\\hyper-v-host\E$\HyperV-VMs\" `
    -Format VHD `
    -Reason "Disaster scenario: Migrating critical VM from vSphere to Hyper-V"

Write-Host "VM exported in VHD format - can be imported into Hyper-V" -ForegroundColor Green
```

---

## Best Practices Summary

1. **Use HotAdd mode** for virtual proxies in same vCenter environment (50-100% faster than NBD)
2. **Enable Changed Block Tracking (CBT)** on all production VMs (reduces incremental backup time by 80%+)
3. **Limit snapshot duration** to <5 minutes (avoid performance impact on production storage)
4. **Dedicate backup proxy VMs** - don't co-locate proxies with production workloads
5. **Use Instant VM Recovery** for sub-30-minute RTOs (VM runs from backup while migrating to production)
6. **Test cross-hypervisor recovery** annually (ensure VMs can be restored to Hyper-V if vSphere unavailable)
7. **Monitor backup windows** - ensure jobs complete before 6 AM school start time
8. **Reserve HA capacity** - account for instant recovery VMs in HA slot size calculations
9. **Application-aware processing** - enable VSS for SQL, Exchange, AD (ensures consistent restore points)
10. **Service account security** - use dedicated veeam-backup@vsphere.local account with minimum required privileges
