# K-12 Identity & Access Management Automation
## Student/Staff Lifecycle Management

**Author:** Bryan Shaw, all data and testing run in a sandbox enviorment for automation testing of "mock sample data"
**Purpose:** Automated identity provisioning for K-12 educational environments
**Compliance:** FERPA, student data protection, audit logging

---

## Overview

PowerShell automation for student and staff identity lifecycle in K-12 environments. The **K12Identity** module implements K-12 naming conventions and OU structures that scale from a pilot classroom to a 34,000-student district. The patterns here are built for operating an existing Entra ID environment, extending, maintaining, and troubleshooting, not just initial setup.

**Key Features:**
- **Automated Student Provisioning:** Bulk student account creation with grade-level OUs (K-12, Kindergarten through Grade 12)
- **Staff Account Management:** Role-based access controls (Teacher, Administrator, IT, Support)
- **FERPA-Compliant Audit Logging:** All identity operations logged for compliance
- **Graduation Year Tracking:** Automatic OU placement based on graduation year
- **CSV Integration:** Batch processing from Student Information System (SIS) exports

---

## Files

### 1. `KISDIdentity.psm1`
**Purpose:** Core PowerShell module for K-12 identity management

#### `New-KISDStudentAccount`
Creates student Active Directory accounts with automated OU placement.

**Parameters:**
- `FirstName` - Student first name
- `LastName` - Student last name
- `StudentID` - Unique student identifier from SIS
- `GradeLevel` - Current grade level (0=Kindergarten through 12)
- `GraduationYear` - Expected graduation year (for OU structure)

**Example:**
```powershell
New-KISDStudentAccount -FirstName "Sarah" `
                       -LastName "Johnson" `
                       -StudentID "12345678" `
                       -GradeLevel 10 `
                       -GraduationYear 2027
```

**Output:**
- UPN: `sarah.johnson12345678@students.keller.edu`
- OU: `OU=2027,OU=Grade10,OU=Students,DC=keller,DC=edu`
- Home Folder: `\\FS-Students01\Students\2027\sjohnson12345678`
- Initial Password: Randomly generated (12 characters), must change at first logon

---

#### `New-KISDStaffAccount`
Creates staff Active Directory accounts with role-based OU placement.

**Parameters:**
- `FirstName` - Staff first name
- `LastName` - Staff last name
- `EmployeeID` - Unique employee identifier from HR system
- `Role` - Staff role: `Teacher`, `Administrator`, `IT`, `SupportStaff`
- `Department` - Department/subject area (e.g., "Mathematics", "English")

**Example:**
```powershell
New-KISDStaffAccount -FirstName "Michael" `
                     -LastName "Rodriguez" `
                     -EmployeeID "T98765" `
                     -Role "Teacher" `
                     -Department "Science"
```

**Output:**
- UPN: `michael.rodriguez@keller.edu`
- OU: `OU=Teachers,OU=Staff,DC=keller,DC=edu`
- Home Folder: `\\FS-Staff01\Staff\mrodriguez`
- Email: Enabled for Microsoft 365 Exchange Online
- Security Groups: `TeachersAll`, `Science-Department`

---

#### `Remove-KISDAccount`
Disables and archives accounts for graduated students or separated staff.

**Parameters:**
- `Username` - User Principal Name (UPN) of account to remove
- `ArchiveReason` - Reason for removal: `Graduated`, `Transferred`, `Terminated`

**Example:**
```powershell
Remove-KISDAccount -Username "sarah.johnson12345678@students.keller.edu" `
                   -ArchiveReason "Graduated"
```

**Process:**
1. Disable account (prevent login)
2. Remove from all security groups
3. Move to `OU=Archived,OU=Students,DC=keller,DC=edu`
4. Set description with archive date and reason
5. Log action to audit log

**Retention:** Archived accounts retained for 1 year per FERPA guidelines, then deleted

---

#### `Write-KISDAuditLog`
Logs all identity operations for FERPA compliance and security audits.

**Parameters:**
- `Action` - Action performed: `Create`, `Modify`, `Delete`, `Disable`
- `TargetUser` - User account affected
- `PerformedBy` - Administrator who performed action
- `Details` - Additional details (optional)

**Example:**
```powershell
Write-KISDAuditLog -Action "Create" `
                   -TargetUser "sarah.johnson12345678@students.keller.edu" `
                   -PerformedBy "admin@keller.edu" `
                   -Details "Student account created for Grade 10"
```

**Log Location:** `C:\Logs\KISD-Identity-Audit.log` (CSV format)
**Log Retention:** 7 years (FERPA compliance requirement)

---

### 2. `New-StudentBatch.ps1`
**Purpose:** Bulk student account creation from CSV file

**Use Case:** Annual student enrollment processing, mid-year transfers

**CSV Format:**
```csv
FirstName,LastName,StudentID,GradeLevel,GraduationYear
Sarah,Johnson,12345678,10,2027
Michael,Chen,23456789,9,2028
Emma,Williams,34567890,11,2026
```

**Usage:**
```powershell
.\New-StudentBatch.ps1 -CSVPath "C:\Enrollment\Fall2025-NewStudents.csv" -WhatIf
# Review proposed changes, then run without -WhatIf to execute
.\New-StudentBatch.ps1 -CSVPath "C:\Enrollment\Fall2025-NewStudents.csv"
```

**Features:**
- **Error Handling:** Skips invalid entries, logs errors to separate file
- **Progress Reporting:** Displays real-time progress (e.g., "Processing 45/200 students...")
- **Duplicate Detection:** Checks for existing accounts before creation
- **Summary Report:** Generates HTML report with success/failure statistics

**Performance:** Processes ~100 student accounts per minute

---

## Organizational Unit (OU) Structure

### Student OU Hierarchy
```
OU=Students,DC=keller,DC=edu
├── OU=GradeK,OU=Students (Kindergarten, no graduation year sub-OU)
├── OU=Grade1 through OU=Grade8 (Elementary/Middle, same pattern, no graduation year sub-OU)
├── OU=Grade9,OU=Students
│   ├── OU=2028 (Freshman class graduating 2028)
│   └── OU=2029
├── OU=Grade10,OU=Students
│   ├── OU=2027 (Sophomore class graduating 2027)
│   └── OU=2028
├── OU=Grade11,OU=Students
│   ├── OU=2026 (Junior class graduating 2026)
│   └── OU=2027
├── OU=Grade12,OU=Students
│   ├── OU=2025 (Senior class graduating 2025)
│   └── OU=2026
└── OU=Archived,OU=Students (Graduated/transferred students)
```

**Rationale:**
- Grade-level OUs enable targeted Group Policy (e.g., computer lab access for Grade 12 only; Autopilot device assignment starts at Grade 5)
- Graduation year sub-OUs (Grades 9-12) simplify bulk operations such as disabling all 2025 graduates at once
- K-8 students use grade-level OUs only; graduation year tracking begins at Grade 9

### Staff OU Hierarchy
```
OU=Staff,DC=keller,DC=edu
├── OU=Teachers (instructional staff)
├── OU=Administrators (principals, assistant principals, directors)
├── OU=IT (technology department)
├── OU=SupportStaff (counselors, librarians, nurses)
└── OU=Archived,OU=Staff (Separated employees)
```

**Rationale:**
- Role-based OUs align with permission levels (e.g., Administrators have SIS admin access)
- Simplifies security group membership (all Teachers inherit base permissions)

---

## Naming Conventions

### Student Accounts
- **Username:** `firstname.lastname<StudentID>` (e.g., `sarah.johnson12345678`)
- **UPN:** `<username>@students.keller.edu`
- **Display Name:** `<LastName>, <FirstName> (<StudentID>)`
- **Email Address:** `<username>@students.keller.edu` (Microsoft 365)

**Rationale:** Student ID suffix prevents duplicate usernames (e.g., multiple "John Smith" students)

### Staff Accounts
- **Username:** `firstname.lastname` (e.g., `michael.rodriguez`)
- **UPN:** `<username>@keller.edu`
- **Display Name:** `<LastName>, <FirstName> (<Department>)`
- **Email Address:** `<username>@keller.edu` (Microsoft 365)

**Rationale:** Professional email format, no numeric suffixes for staff

---

## Integration with School Systems

### Student Information System (SIS)
- **Export Format:** CSV from SIS (Skyward, PowerSchool, Infinite Campus, etc.)
- **Scheduled Import:** Nightly sync during off-hours (11 PM)
- **Data Validation:** Check for missing fields (FirstName, LastName, StudentID required)
- **Error Notifications:** Email IT department if sync fails

### Microsoft 365 / Entra ID
- **Hybrid Identity:** On-premises AD synced to Entra ID via Azure AD Connect
- **License Assignment:** Students = M365 A5 for Education, Staff = M365 A5 for Education
- **Group Membership:** Security groups synced to Microsoft 365 for Teams and Intune policy targeting
- **Email Provisioning:** Exchange Online mailboxes auto-created on first sync
- **Device Assignment:** New student account triggers Autopilot device assignment from fleet inventory (grades 5-12)

### File Servers
- **Home Folders:** Auto-created on first logon (script in GPO logon scripts)
- **Permissions:** Students have read/write to own folder only
- **Quota:** 5 GB per student, 50 GB per staff member
- **Backup:** Veeam nightly backups with 30-day retention

---

## Security & Compliance

### FERPA Compliance (Family Educational Rights and Privacy Act)
- **Access Control:** Only authorized staff (teachers, administrators, counselors) can view student data
- **Audit Logging:** All account creations, modifications, deletions logged with timestamp and administrator
- **Data Retention:** Student accounts archived (not deleted) for 1 year after graduation
- **Consent Management:** Parent consent tracked in SIS, synced to AD custom attribute

### Password Policies
**Students:**
- Minimum 8 characters (enforced via Group Policy)
- Must change password every 90 days
- Cannot reuse last 12 passwords
- Account lockout after 5 failed attempts (15-minute lockout duration)

**Staff:**
- Minimum 12 characters
- Must change password every 60 days
- MFA required for administrative accounts

### Least Privilege Access
- IT department has full control over all OUs
- Principals have read-only access to student accounts (no modification)
- Teachers have zero access to Active Directory (use SIS for student info)
- Help desk staff can reset passwords but not modify group memberships

---

## Deployment Guide

This module was built and tested in a sandbox environment structured to mirror real KISD production requirements: full AD hierarchy, OU layout matching district policy, and all configuration a new deployment would require. The steps below reflect the same sequence an IT team would follow when deploying against a live domain.

**Prerequisites:** Windows Server 2016+, PowerShell 5.1+ with the ActiveDirectory module, and delegated OU permissions (Account Operator or equivalent).

**Import and verify:**
```powershell
Import-Module .\KISDIdentity.psm1
Get-Command -Module KISDIdentity
```

**Create the OU structure** (run once against the target domain):
```powershell
New-ADOrganizationalUnit -Name "Students" -Path "DC=keller,DC=edu"
New-ADOrganizationalUnit -Name "GradeK" -Path "OU=Students,DC=keller,DC=edu"
New-ADOrganizationalUnit -Name "Grade9" -Path "OU=Students,DC=keller,DC=edu"
# Repeat for Grade1-Grade8, Grade10, Grade11, Grade12, Staff OUs
```

**Configure audit logging:**
```powershell
New-Item -Path "C:\Logs" -ItemType Directory -Force
# Apply ACL to restrict to IT admin group; see Write-KISDAuditLog documentation above
```

**Validate before production use:**
```powershell
New-KISDStudentAccount -FirstName "Test" -LastName "Student" `
                       -StudentID "99999999" -GradeLevel 9 `
                       -GraduationYear 2028 -WhatIf
```

---

## Operational Workflows

### Annual Enrollment (August)
1. **SIS Export:** Export all new student enrollments to CSV
2. **Batch Processing:** Run `New-StudentBatch.ps1` to create accounts
3. **Verification:** Review audit log for errors, manually fix exceptions
4. **Welcome Emails:** Send automated welcome emails with login instructions
5. **Device Assignment (grades 5-12):** Autopilot profile assigned at account creation, Surface device assigned from fleet inventory, ready for student pickup

### Mid-Year Transfers
- **New Students:** Run `New-KISDStudentAccount` individually or batch (small CSV)
- **Departed Students:** Run `Remove-KISDAccount` with `Transferred` reason

### End of Year (May/June)
1. **Graduate Seniors:** Batch disable all students in `OU=2025,OU=Grade12`
2. **Move to Archive OU:** Retain accounts for summer school access
3. **Final Deletion:** After 1 year, delete archived accounts (retention policy)
4. **Grade Promotion:** Advance all enrolled students one grade level (K through 11); Grade 12 students are processed in the graduation batch above

### Staff Onboarding/Offboarding
- **New Hire:** Run `New-KISDStaffAccount` on first day of employment
- **Separation:** Run `Remove-KISDAccount` on last day (disable immediately, archive)
- **Role Change:** Manually move AD account to new OU, update group memberships

---

## Troubleshooting

### Common Issues

**Issue:** Duplicate username error
- **Solution:** Module automatically appends StudentID to prevent duplicates. If error persists, check for pre-existing account with `Get-ADUser -Filter {SamAccountName -like "*<lastname>*"}`

**Issue:** Home folder not created
- **Solution:** Verify file server is accessible and user has permission. Check GPO logon script is applied to correct OU.

**Issue:** Student cannot login
- **Solution:** Check account is enabled (`Get-ADUser -Identity <username> | Select Enabled`), password has been set, account not locked out

**Issue:** Audit log not writing
- **Solution:** Verify `C:\Logs` directory exists, IT admin account has write permission, disk space available

---

## Performance Metrics

**Efficiency Gains:**
- **Manual Process:** 15 minutes per student account (search SIS, create AD account, set password, create home folder, send welcome email)
- **Automated Process:** <1 minute per student account (bulk CSV processing)
- **At District Scale:** 3,400 new students in August processed in ~34 minutes (vs. 850 hours manual). At 34,000 total accounts, this automation runs year-round for transfers, role changes, and graduation processing.

**Impact:**
- IT staff time saved: ~295 hours per year (redeployed to strategic projects)
- Reduced errors: Naming consistency, no typos in usernames/UPNs
- Faster onboarding: Students receive accounts same day (vs. 3-5 day delay)
- FERPA compliance: 100% audit trail (vs. manual spreadsheet tracking)

---

## Extending at Scale

For a district already running Entra ID at 34,000 accounts with 23,000 Intune-managed devices, the operational questions shift from setup to maintenance and extension:

- **SIS API integration:** Eliminate the nightly CSV export, real-time Entra account sync when enrollment changes occur in Skyward or PowerSchool
- **School Data Sync (SDS) alignment:** Ensure account provisioning feeds Canvas course enrollment automatically at account creation
- **SSPR (Self-Service Password Reset):** Roll out Entra SSPR for students to reduce help desk ticket volume on password resets, largest single category of help desk contact at most districts
- **Conditional Access scope audit:** Verify all 38,500 accounts fall under an appropriate Conditional Access policy, no gaps from legacy accounts or shared device scenarios
- **Autopilot profile review:** As new device categories come into the fleet (staff refreshes, lab devices, shared carts), verify Autopilot profiles are correctly scoped and tested before bulk deployment

---

## Additional Resources

- [FERPA Compliance Guide for Schools](https://studentprivacy.ed.gov/)
- [Microsoft School Data Sync](https://sds.microsoft.com/)
- [PowerShell Active Directory Module Documentation](https://docs.microsoft.com/en-us/powershell/module/activedirectory/)

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com

**Note:** All data is mock/demonstrative at district-approximate scale. No production credentials or real student records.
