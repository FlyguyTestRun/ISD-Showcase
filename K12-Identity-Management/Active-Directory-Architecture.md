# Active Directory Architecture for K-12 School Districts

## Domain Structure

### Domain Hierarchy

```
district.edu (Forest Root Domain)
│
├── students.district.edu (Child Domain - Student Accounts)
│   └── Azure AD Connect Sync → Azure AD (students@district.edu)
│
└── admin.district.edu (Resource Domain - Servers/Workstations)
    └── Azure AD Connect Sync → Azure AD (staff@district.edu)

Forest Functional Level: Windows Server 2016
Domain Functional Level: Windows Server 2016
```

**Domain Separation Rationale:**
- **students.district.edu**: Separate domain for 2,000+ student accounts (simplified management, different GPO requirements)
- **admin.district.edu**: Servers and administrative resources (tighter security controls)
- **Trust Relationship**: Two-way transitive trust (staff can authenticate to student resources for management)

---

## Organizational Unit (OU) Structure

### Students OU (students.district.edu)

```
students.district.edu
│
├── Students
│   ├── Freshmen-Class2028
│   │   ├── [1,200 student accounts]
│   │   └── GPO: Student-Freshmen-Policies
│   ├── Sophomores-Class2027
│   │   ├── [800 student accounts]
│   │   └── GPO: Student-Sophomore-Policies
│   ├── Juniors-Class2026
│   │   ├── [600 student accounts]
│   │   └── GPO: Student-Junior-Policies
│   └── Seniors-Class2025
│       ├── [400 student accounts]
│       └── GPO: Student-Senior-Policies
│
├── Groups
│   ├── Security Groups
│   │   ├── SG-Students-All (3,000 members)
│   │   ├── SG-Students-Freshmen (1,200 members)
│   │   ├── SG-Students-Sophomores (800 members)
│   │   ├── SG-Students-Juniors (600 members)
│   │   └── SG-Students-Seniors (400 members)
│   └── Distribution Groups
│       ├── DL-Students-All@district.edu
│       └── DL-Class-2025@district.edu (seniors only)
│
└── Service Accounts
    ├── svc-studentimport (SIS data sync)
    └── svc-chromebooksync (Google Admin Console sync)

Total Student Accounts: 3,000
```

**Grade-Level OU Automation:**
```powershell
# Automatic OU promotion (move sophomores → juniors on August 1st)
$PromotionDate = Get-Date "2025-08-01"
if ((Get-Date) -ge $PromotionDate) {
    # Move Juniors → Seniors OU
    Get-ADUser -Filter * -SearchBase "OU=Juniors-Class2026,OU=Students,DC=students,DC=district,DC=edu" |
        Move-ADObject -TargetPath "OU=Seniors-Class2025,OU=Students,DC=students,DC=district,DC=edu"

    # Update graduation year attribute
    Get-ADUser -Filter * -SearchBase "OU=Seniors-Class2025,OU=Students,DC=students,DC=district,DC=edu" |
        Set-ADUser -Replace @{extensionAttribute1 = "2025"}
}
```

---

### Staff OU (district.edu)

```
district.edu
│
├── Staff
│   ├── Teachers
│   │   ├── Elementary
│   │   │   ├── [120 teacher accounts]
│   │   │   └── GPO: Teachers-Elementary-Policies
│   │   ├── MiddleSchool
│   │   │   ├── [80 teacher accounts]
│   │   │   └── GPO: Teachers-MiddleSchool-Policies
│   │   └── HighSchool
│   │       ├── [150 teacher accounts]
│   │       └── GPO: Teachers-HighSchool-Policies
│   │
│   ├── Administrators
│   │   ├── Principals (5 accounts)
│   │   ├── AssistantPrincipals (10 accounts)
│   │   └── CentralOffice (15 accounts)
│   │   └── GPO: Admin-Policies (elevated privileges)
│   │
│   ├── IT-Staff
│   │   ├── IT-Admins (5 accounts - Domain Admins)
│   │   ├── IT-Support (15 accounts - Help Desk)
│   │   └── IT-NetworkAdmins (3 accounts - Network infrastructure)
│   │   └── GPO: IT-Staff-Policies (admin workstation restrictions)
│   │
│   ├── Support-Staff
│   │   ├── Counselors (20 accounts)
│   │   ├── Librarians (8 accounts)
│   │   ├── Nurses (6 accounts)
│   │   └── Secretaries (25 accounts)
│   │   └── GPO: Support-Staff-Policies
│   │
│   └── Substitutes
│       ├── [50 substitute teacher accounts]
│       └── GPO: Substitute-Policies (restricted access)
│
├── Servers
│   ├── DomainControllers
│   │   ├── DC01 (Primary DC)
│   │   └── DC02 (Secondary DC)
│   ├── FileServers
│   │   ├── FS-Students01 (student home directories)
│   │   └── FS-Staff01 (staff home directories)
│   ├── ApplicationServers
│   │   ├── SQL-SIS01 (Student Information System)
│   │   └── APP-Canvas01 (Canvas LMS)
│   └── InfrastructureServers
│       ├── VEEAM01 (Backup server)
│       └── SCCM01 (Endpoint management)
│
├── Workstations
│   ├── Staff-Laptops
│   │   └── [350 computer accounts]
│   ├── Staff-Desktops
│   │   └── [200 computer accounts]
│   └── Admin-Workstations
│       └── [25 computer accounts]
│       └── GPO: Privileged Access Workstation (PAW) policies
│
└── Groups
    ├── Security Groups
    │   ├── SG-Teachers-All (350 members)
    │   ├── SG-IT-Admins (5 members - Domain Admins)
    │   ├── SG-File-Server-Access (380 members)
    │   └── SG-VPN-Users (25 members - remote access)
    └── Distribution Groups
        ├── DL-AllStaff@district.edu (400 members)
        ├── DL-Teachers@district.edu (350 members)
        └── DL-IT-Department@district.edu (20 members)

Total Staff Accounts: 400
```

---

## Group Policy Objects (GPOs)

### Student GPOs

#### GPO: Student-Base-Policies
**Applied to:** All Students OUs
**Settings:**
```
Computer Configuration:
├─ Windows Update: Automatic updates during school breaks only
├─ Power Management: Prevent shutdown during school hours (7 AM - 4 PM)
├─ Firewall: Enable Windows Firewall, block P2P apps
├─ Software Restriction: Block installation of unauthorized apps
└─ Drive Mappings:
    └─ H: → \\FS-Students01\Students\%username% (home directory)

User Configuration:
├─ Desktop: Lock desktop wallpaper (district branding)
├─ Start Menu: Hide Control Panel, Settings, Command Prompt
├─ Internet Explorer/Edge: Proxy settings (web filtering)
├─ Microsoft Edge: Force Google Safe Search, YouTube Restricted Mode
├─ OneDrive: Known Folder Move (Desktop, Documents → OneDrive)
└─ Folder Redirection:
    ├─ Documents → H:\Documents
    ├─ Desktop → H:\Desktop
    └─ Downloads → H:\Downloads
```

#### GPO: Student-Chromebook-Policies
**Applied to:** Chromebook-managed student accounts (Google Admin Console sync)
**Settings:**
```
Chromebook Policies (via Google Admin Console, synced with Azure AD):
├─ Force sign-in to managed account (no guest mode)
├─ Restrict extensions to approved whitelist (Google Classroom, Canvas)
├─ Disable developer mode
├─ Enable SafeSearch (Google, Bing, YouTube)
└─ Session timeout: 30 minutes of inactivity
```

---

### Staff GPOs

#### GPO: Staff-Base-Policies
**Applied to:** All Staff OUs
**Settings:**
```
Computer Configuration:
├─ Windows Update: Automatic updates on weekends
├─ BitLocker: Enforce full-disk encryption (TPM required)
├─ Firewall: Enable Windows Firewall
├─ Software Installation: Deploy Microsoft Office 365, Adobe Acrobat Reader
└─ Drive Mappings:
    ├─ H: → \\FS-Staff01\Staff\%username% (home directory)
    ├─ S: → \\FS-Staff01\Shared (department shared folders)
    └─ T: → \\FS-Students01\TeacherAccess (read-only student data access)

User Configuration:
├─ Desktop: Allow customization
├─ Start Menu: Full access (no restrictions for staff)
├─ Internet Explorer/Edge: No proxy (minimal filtering for staff)
├─ Outlook: Autodiscover settings (Exchange Online)
├─ OneDrive for Business: Automatic provisioning
└─ Folder Redirection:
    ├─ Documents → H:\Documents
    ├─ Desktop → H:\Desktop
    └─ Favorites → H:\Favorites
```

#### GPO: IT-Admin-Policies
**Applied to:** IT-Staff OU
**Settings:**
```
Computer Configuration:
├─ Privileged Access Workstation (PAW) hardening:
    ├─ Disable USB storage (prevent malware introduction)
    ├─ Application whitelisting (only approved IT tools)
    ├─ Credential Guard enabled
    └─ Windows Defender Application Control (WDAC)

User Configuration:
├─ UAC: Always prompt for elevation (prevent silent privilege escalation)
├─ PowerShell: Transcript logging enabled (all commands logged)
├─ Remote Desktop: Restricted to jump box only (10.100.30.200)
└─ MFA: Required for all admin actions (Azure AD Conditional Access)
```

---

## Azure AD Connect Synchronization

### Hybrid Identity Architecture

```
On-Premises AD (district.edu)          Azure Active Directory (Cloud)
┌────────────────────────┐             ┌─────────────────────────────┐
│  Domain Controllers    │             │  Azure AD Tenant            │
│  - DC01, DC02          │             │  district.onmicrosoft.com   │
│  - 3,400 user accounts │             │                             │
└──────────┬─────────────┘             └────────────┬────────────────┘
           │                                        │
           │  Azure AD Connect Server               │
           │  (Sync every 30 minutes)               │
           └───────────►AADConnect◄─────────────────┘
                       10.100.30.145

Synchronization Flow:
1. On-prem AD changes (new student, password reset) → detected by AAD Connect
2. AAD Connect syncs changes to Azure AD within 30 minutes
3. Azure AD provisions user in Microsoft 365 (Exchange, OneDrive, Teams)
4. User can authenticate with same credentials on-prem and cloud
```

### Azure AD Connect Configuration

```powershell
# Install Azure AD Connect (one-time setup)
# Download from: https://www.microsoft.com/en-us/download/details.aspx?id=47594

# Configure sync scope (only sync specific OUs)
Set-ADSyncScheduler -SyncCycleEnabled $true -CustomizedSyncCycleInterval 00:30:00

# Filter: Only sync active students and staff (exclude disabled accounts)
$FilterRule = New-ADSyncRule `
    -Name "In from AD - User AccountEnabled Filter" `
    -Description "Only sync enabled accounts" `
    -Direction Inbound `
    -Precedence 50 `
    -SourceObjectType user `
    -TargetObjectType person `
    -Filter {userAccountControl -bor 2}  # Filter out disabled accounts

# Attribute mapping
# On-prem AD → Azure AD
# - sAMAccountName → userPrincipalName
# - mail → mail
# - extensionAttribute1 (graduation year) → extensionAttribute1
# - memberOf (group memberships) → synced to Azure AD groups
```

---

## FERPA Compliance Controls

### Audit Logging

**Track all student data access:**

```powershell
# Enable Advanced Audit Policy (all domain controllers)
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Access" /success:enable /failure:enable
auditpol /set /subcategory:"Logon" /success:enable /failure:enable

# Forward logs to SIEM (Splunk/ELK)
$LogForwardingServer = "10.100.30.150"  # SIEM server
wevtutil set-log Security /ms:1073741824  # 1 GB log size
wevtutil set-log Security /rt:true  # Real-time forwarding
```

**FERPA Audit Report (Monthly):**

```powershell
# Generate report of student data access
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4663  # Object Access
    StartTime = (Get-Date).AddDays(-30)
} | Where-Object {
    $_.Message -like "*Students*"  # Student OU access
} | Select-Object TimeCreated, @{N='User';E={$_.Properties[1].Value}}, @{N='ObjectAccessed';E={$_.Properties[6].Value}} |
Export-Csv "C:\Reports\FERPA-Audit-$(Get-Date -Format 'yyyy-MM').csv" -NoTypeInformation

Write-Host "FERPA audit report generated" -ForegroundColor Green
```

---

## Password Policies

### Fine-Grained Password Policies (FGPP)

**Students:**
```powershell
# Student password policy (relaxed for usability)
New-ADFineGrainedPasswordPolicy `
    -Name "StudentPasswordPolicy" `
    -Precedence 10 `
    -MinPasswordLength 8 `
    -PasswordHistoryCount 5 `
    -MaxPasswordAge 90.00:00:00 `  # 90 days
    -MinPasswordAge 1.00:00:00 `   # 1 day
    -LockoutThreshold 10 `          # 10 failed attempts (students forget passwords often)
    -LockoutDuration 00:15:00 `     # 15-minute lockout
    -ComplexityEnabled $true

# Apply to all students
Add-ADFineGrainedPasswordPolicySubject -Identity "StudentPasswordPolicy" -Subjects "SG-Students-All"
```

**Staff:**
```powershell
# Staff password policy (stricter for security)
New-ADFineGrainedPasswordPolicy `
    -Name "StaffPasswordPolicy" `
    -Precedence 5 `
    -MinPasswordLength 12 `
    -PasswordHistoryCount 12 `
    -MaxPasswordAge 60.00:00:00 `   # 60 days
    -MinPasswordAge 1.00:00:00 `
    -LockoutThreshold 5 `           # 5 failed attempts
    -LockoutDuration 00:30:00 `     # 30-minute lockout
    -ComplexityEnabled $true

Add-ADFineGrainedPasswordPolicySubject -Identity "StaffPasswordPolicy" -Subjects "SG-Staff-All"
```

**IT Administrators:**
```powershell
# IT admin password policy (strictest)
New-ADFineGrainedPasswordPolicy `
    -Name "ITAdminPasswordPolicy" `
    -Precedence 1 `
    -MinPasswordLength 16 `
    -PasswordHistoryCount 24 `
    -MaxPasswordAge 30.00:00:00 `   # 30 days
    -MinPasswordAge 1.00:00:00 `
    -LockoutThreshold 3 `           # 3 failed attempts (security-focused)
    -LockoutDuration 01:00:00 `     # 1-hour lockout
    -ComplexityEnabled $true

Add-ADFineGrainedPasswordPolicySubject -Identity "ITAdminPasswordPolicy" -Subjects "SG-IT-Admins"
```

---

## Disaster Recovery for Active Directory

### Domain Controller Backup Strategy

**Veeam Backup Schedule:**
```
Backup Job: "Domain-Controllers-Nightly"
├─ VMs: DC01, DC02
├─ Schedule: Daily at 10 PM
├─ Retention: 14 restore points
├─ Application-Aware: Yes (VSS for AD database)
└─ Recovery Testing: Quarterly (restore to isolated network)
```

**System State Backup (Alternative/Supplemental):**
```powershell
# Windows Server Backup for AD system state
wbadmin start systemstatebackup -backupTarget:E: -quiet

# Schedule daily system state backups
$Action = New-ScheduledTaskAction -Execute "wbadmin" -Argument "start systemstatebackup -backupTarget:E: -quiet"
$Trigger = New-ScheduledTaskTrigger -Daily -At "11:00 PM"
Register-ScheduledTask -TaskName "AD-SystemState-Backup" -Action $Action -Trigger $Trigger
```

### AD Restore Procedures

**Non-Authoritative Restore (Most Common):**
```powershell
# Scenario: Single DC failure, other DCs still online
# 1. Restore VM from Veeam backup
# 2. Boot to DSRM (Directory Services Restore Mode)
bcdedit /set safeboot dsrepair
Restart-Computer

# 3. Perform non-authoritative restore
wbadmin start systemstaterecovery -version:01/15/2025-22:00 -backupTarget:E:

# 4. Reboot to normal mode (inbound replication from other DCs will update restored DC)
bcdedit /deletevalue safeboot
Restart-Computer
```

**Authoritative Restore (Rare - Deleted OU Recovery):**
```powershell
# Scenario: Accidentally deleted OU needs restoration
# After non-authoritative restore:
ntdsutil
activate instance ntds
authoritative restore
restore subtree "OU=Seniors-Class2025,OU=Students,DC=students,DC=district,DC=edu"
quit
quit

# Reboot (restored objects will replicate to other DCs as authoritative)
```

---

## Domain Controller Replication Topology

### Multi-Site Replication

```
Site: CentralOffice (10.100.x.x)
├─ DC01 (Primary DC)
│   ├─ FSMO Roles: Schema Master, Domain Naming Master, PDC Emulator, RID Master, Infrastructure Master
│   └─ Replication Partners: DC02, DC03
└─ DC02 (Secondary DC)
    └─ Replication Partners: DC01, DC03

Site: HighSchool (10.100.x.x - same network, different building)
└─ DC03 (Read-Only DC - for fast local authentication)
    ├─ Password Replication Policy: Allow Teachers, Deny Students
    └─ Replication Partners: DC01, DC02

Replication Schedule:
├─ Intra-site (CentralOffice ↔ HighSchool): Every 15 minutes
└─ Inter-site: Not applicable (single AD site)
```

**Check Replication Health:**
```powershell
# Verify replication status
repadmin /replsummary

# Test replication between DCs
repadmin /syncall /AdeP

# Check for replication errors
Get-ADReplicationFailure -Target DC01, DC02, DC03
```

---

## Integration with SIS (Student Information System)

### Automated Student Account Provisioning

**Data Flow:**
```
SIS Database (SQL Server)
   │
   │ Nightly Export (midnight)
   ▼
CSV File: \\FS-Staff01\SISExport\Students.csv
   │
   │ Scheduled Task (12:30 AM)
   ▼
PowerShell Script: Import-SISStudents.ps1
   │
   │ Create/Update/Disable Accounts
   ▼
Active Directory (students.district.edu)
   │
   │ Azure AD Connect Sync (every 30 min)
   ▼
Azure AD / Microsoft 365
```

**PowerShell Integration Script:**
```powershell
# Import-SISStudents.ps1 (Scheduled nightly)
$SISExport = Import-Csv "\\FS-Staff01\SISExport\Students.csv"

foreach ($Student in $SISExport) {
    $GradYear = $Student.GraduationYear
    $OU = "OU=Class$GradYear,OU=Students,DC=students,DC=district,DC=edu"

    # Check if account exists
    $ExistingUser = Get-ADUser -Filter "EmployeeID -eq '$($Student.StudentID)'" -ErrorAction SilentlyContinue

    if (-not $ExistingUser) {
        # Create new student account
        New-ADUser `
            -Name "$($Student.LastName), $($Student.FirstName)" `
            -GivenName $Student.FirstName `
            -Surname $Student.LastName `
            -SamAccountName $Student.Username `
            -UserPrincipalName "$($Student.Username)@students.district.edu" `
            -EmployeeID $Student.StudentID `
            -Path $OU `
            -AccountPassword (ConvertTo-SecureString "Welcome2025!" -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Host "Created: $($Student.Username)" -ForegroundColor Green
    } else {
        # Update existing account (enrollment status changed, etc.)
        if ($Student.EnrollmentStatus -eq "Withdrawn") {
            Disable-ADAccount -Identity $ExistingUser
            Write-Host "Disabled: $($Student.Username) (withdrawn)" -ForegroundColor Yellow
        }
    }
}
```

---

## Summary Statistics (Matches Power BI Dashboard)

**Active Directory Health Metrics:**
```
Total User Accounts: 3,400
├─ Students: 3,000 (88.2%)
└─ Staff: 400 (11.8%)

Account Status:
├─ Enabled: 3,250 (95.6%)
├─ Disabled: 150 (4.4% - graduated seniors, withdrawn students, former staff)
└─ Locked Out: 12 (0.4% - password failures)

Password Expiration (Next 14 days):
├─ Students: 45 accounts expiring
├─ Staff: 18 accounts expiring
└─ Automated Email Reminders: Sent 7 days before expiration

Group Memberships:
├─ Security Groups: 85 groups
├─ Distribution Groups: 42 groups
└─ Average memberships per user: 4.2 groups

Azure AD Sync Status:
├─ Last Sync: 15 minutes ago
├─ Sync Errors: 0
├─ Pending Syncs: 3 accounts (new students added in last 20 minutes)
└─ Cloud-Only Accounts: 15 (external vendors, Azure-only service accounts)
```

---

This Active Directory architecture supports the Power BI IT Infrastructure Health Dashboard statistics:
- **2,450 user accounts monitored** (students + staff)
- **Password expiration tracking** for proactive notifications
- **FERPA-compliant audit logging** for all student data access
- **90 days of historical trending** via integration with monitoring systems
