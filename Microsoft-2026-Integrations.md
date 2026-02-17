# Microsoft 365 & Azure Integration for K-12 Districts (2026)

## Overview

This document showcases enterprise Microsoft integrations relevant to K-12 school districts undergoing Google Workspace to Microsoft 365 migrations, including OneDrive data migration, Azure Active Directory (Entra ID) identity management, and Intune device administration.

---

## OneDrive Migration from Google Drive

### Migration Context (2026)

**Typical K-12 Migration Scenario:**
- **Source:** Google Drive (Google Workspace for Education)
- **Target:** Microsoft OneDrive for Business (Microsoft 365 A3/A5)
- **Timeline:** 18-24 month phased migration
- **Data Volume:** 5-50 TB district-wide (varies by district size)

**Key Challenges:**
1. Preserve file ownership and sharing permissions
2. Minimize disruption during school year
3. Educate staff/students on new platform
4. Handle incompatible file types (Google Docs → Office formats)
5. Maintain regulatory compliance (FERPA, COPPA)

### Migration Planning

**Phased Approach:**
```
Phase 1: Pilot (Summer 2025)
├─ IT Department (20 users)
├─ Validate migration process
└─ Refine runbooks

Phase 2: Administrative Staff (Fall 2025)
├─ Central office (50 users)
├─ Building administrators (25 users)
└─ Support staff (100 users)

Phase 3: Teachers (Spring 2026)
├─ Elementary teachers (200 users)
├─ Secondary teachers (150 users)
└─ Instructional coaches (25 users)

Phase 4: Students (Summer 2026)
├─ Graduating seniors (500 users) - archive Google Drive
├─ Grades 9-11 (1,500 users) - full migration
└─ Future incoming students - OneDrive only
```

### Migration Tools

#### ShareGate Migrate

**PowerShell automation for bulk user migrations:**

```powershell
# Install ShareGate PowerShell module
Install-Module -Name Sharegate -Force

# Connect to source (Google Drive) and target (OneDrive)
$GoogleSource = Connect-Site -Browser -DisplayName "Google Drive - Staff"
$OneDriveTarget = Connect-Site -Url "https://district-my.sharepoint.com" -Browser

# Import user mapping CSV
$UserMapping = Import-Csv "C:\Migrations\UserMapping.csv"  # Columns: GoogleEmail, OneDriveUPN

foreach ($User in $UserMapping) {
    Write-Host "Migrating: $($User.GoogleEmail) → $($User.OneDriveUPN)" -ForegroundColor Cyan

    # Copy user's Google Drive to OneDrive
    $CopySettings = New-CopySettings -OnContentItemExists IncrementalUpdate

    Copy-Content `
        -SourceSite $GoogleSource `
        -DestinationSite $OneDriveTarget `
        -SourceUser $User.GoogleEmail `
        -DestinationUser $User.OneDriveUPN `
        -CopySettings $CopySettings

    Write-Host "  Migration completed for $($User.OneDriveUPN)" -ForegroundColor Green
}
```

#### Microsoft SharePoint Migration Tool (SPMT)

**Free Microsoft tool for Google Drive → OneDrive:**

```powershell
# Install SPMT (one-time setup)
# Download from: https://aka.ms/spmt

# Bulk migration using CSV
$MigrationCSV = @"
Source,SourceDocLib,TargetWeb,TargetDocLib
https://drive.google.com/drive/folders/ABC123,My Drive,https://district-my.sharepoint.com/personal/teacher1_district_edu,Documents
https://drive.google.com/drive/folders/DEF456,My Drive,https://district-my.sharepoint.com/personal/teacher2_district_edu,Documents
"@

$MigrationCSV | Out-File "C:\Migrations\SPMT-Bulk.csv"

# Run SPMT in command-line mode
Start-Process "C:\Program Files\SharePoint Migration Tool\SPMT.exe" -ArgumentList @(
    "/mode", "csv",
    "/input", "C:\Migrations\SPMT-Bulk.csv",
    "/output", "C:\Migrations\Logs\"
)
```

---

### Post-Migration Automation

#### OneDrive Provisioning Script

**Pre-provision OneDrive for all users before migration:**

```powershell
# Connect to SharePoint Online
$AdminUrl = "https://district-admin.sharepoint.com"
Connect-SPOService -Url $AdminUrl

# Get all licensed users
$Users = Get-MgUser -Filter "assignedLicenses/`$count ne 0" -All

foreach ($User in $Users) {
    $OneDriveUrl = "https://district-my.sharepoint.com/personal/$($User.UserPrincipalName.Replace('@','_').Replace('.','_'))"

    # Request OneDrive provisioning
    Request-SPOPersonalSite -UserEmails $User.UserPrincipalName -NoWait

    Write-Host "OneDrive provisioning requested for: $($User.DisplayName)" -ForegroundColor Gray
}

Write-Host "`nOneDrive provisioning queued for $($Users.Count) users" -ForegroundColor Green
Write-Host "Provisioning completes within 24 hours" -ForegroundColor Cyan
```

#### Storage Quota Management

```powershell
# Set OneDrive storage quotas based on role
$StudentQuota = 5120   # 5 GB for students
$StaffQuota = 102400   # 100 GB for staff/teachers

# Apply student quotas
$Students = Get-MgUser -Filter "jobTitle eq 'Student'" -All
foreach ($Student in $Students) {
    Set-SPOSite -Identity $Student.OneDriveUrl -StorageQuota $StudentQuota
}

# Apply staff quotas
$Staff = Get-MgUser -Filter "jobTitle ne 'Student'" -All
foreach ($StaffMember in $Staff) {
    Set-SPOSite -Identity $StaffMember.OneDriveUrl -StorageQuota $StaffQuota
}
```

---

## Azure Active Directory (Entra ID) Identity Management

### Conditional Access Policies

**Enforce MFA for all staff, restrict student access to district-owned devices:**

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "User.Read.All", "Group.Read.All"

# Create group-based Conditional Access policy
$StaffGroup = Get-MgGroup -Filter "displayName eq 'All-Staff'"

$CAPolicy = @{
    displayName = "Require MFA for Staff"
    state = "enabled"
    conditions = @{
        users = @{
            includeGroups = @($StaffGroup.Id)
        }
        applications = @{
            includeApplications = @("All")
        }
        locations = @{
            includeLocations = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}

New-MgConditionalAccessPolicy -BodyParameter $CAPolicy

Write-Host "Conditional Access policy created: Require MFA for Staff" -ForegroundColor Green
```

### Device Compliance (Students - Managed Devices Only)

```powershell
# Restrict students to district-managed devices only
$StudentGroup = Get-MgGroup -Filter "displayName eq 'All-Students'"

$DeviceCAPolicy = @{
    displayName = "Students - Require Compliant Devices"
    state = "enabled"
    conditions = @{
        users = @{
            includeGroups = @($StudentGroup.Id)
        }
        applications = @{
            includeApplications = @("Office365")
        }
    }
    grantControls = @{
        operator = "AND"
        builtInControls = @("compliantDevice", "domainJoinedDevice")
    }
}

New-MgConditionalAccessPolicy -BodyParameter $DeviceCAPolicy

Write-Host "Student device compliance policy created" -ForegroundColor Green
```

---

## Intune Endpoint Management

### Windows Autopilot for New Device Provisioning

**Zero-touch deployment for district-owned devices:**

```powershell
# Import device hardware hashes from CSV (obtained from OEM or Get-WindowsAutopilotInfo.ps1)
$DeviceCSV = Import-Csv "C:\Autopilot\NewDevices.csv"  # Columns: DeviceSerialNumber, HardwareHash, GroupTag

foreach ($Device in $DeviceCSV) {
    $AutopilotDevice = @{
        serialNumber = $Device.DeviceSerialNumber
        hardwareIdentifier = $Device.HardwareHash
        groupTag = $Device.GroupTag  # e.g., "Staff-Laptop", "Student-Chromebook-Replacement"
    }

    New-MgDeviceManagementWindowsAutopilotDeviceIdentity -BodyParameter $AutopilotDevice

    Write-Host "Autopilot device added: $($Device.DeviceSerialNumber) [$($Device.GroupTag)]" -ForegroundColor Green
}

# Assign Autopilot profile to group tag
$Profile = Get-MgDeviceManagementWindowsAutopilotDeploymentProfile -Filter "displayName eq 'District Standard - Staff'"
$Devices = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter "groupTag eq 'Staff-Laptop'"

foreach ($Device in $Devices) {
    Set-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Device.Id -ProfileId $Profile.Id
}
```

### Application Deployment

**Deploy Office 365 Apps and Educational Software:**

```powershell
# Create Intune app deployment (Office 365 ProPlus)
$Office365App = @{
    "@odata.type" = "#microsoft.graph.officeSuiteApp"
    displayName = "Microsoft 365 Apps for Enterprise (District Standard)"
    officeConfigurationXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
    </Product>
  </Add>
  <Updates Enabled="TRUE" Channel="MonthlyEnterprise" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@
}

$App = New-MgDeviceAppManagementMobileApp -BodyParameter $Office365App

# Assign to "All Devices" group
$AllDevices = Get-MgGroup -Filter "displayName eq 'All-Devices'"

$Assignment = @{
    target = @{
        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
    }
    intent = "required"
}

New-MgDeviceAppManagementMobileAppAssignment -MobileAppId $App.Id -BodyParameter $Assignment

Write-Host "Office 365 deployment created and assigned to all devices" -ForegroundColor Green
```

### Compliance Policies

**Enforce device security baselines:**

```powershell
# Windows 10/11 compliance policy
$CompliancePolicy = @{
    "@odata.type" = "#microsoft.graph.windows10CompliancePolicy"
    displayName = "Windows Device Compliance - District Standard"
    osMinimumVersion = "10.0.19045"  # Windows 10 22H2 minimum
    passwordRequired = $true
    passwordMinimumLength = 8
    bitLockerEnabled = $true
    secureBootEnabled = $true
    defenderEnabled = $true
    defenderVersion = "4.18.2001.0"  # Minimum Windows Defender version
}

$Policy = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $CompliancePolicy

# Assign to all Windows devices
$Assignment = @{
    target = @{
        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
    }
}

New-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $Policy.Id -BodyParameter $Assignment

Write-Host "Windows compliance policy created and assigned" -ForegroundColor Green
```

---

## SharePoint Online Team Sites for Departments

### Automated Site Provisioning

```powershell
# Create department team sites
$Departments = @(
    @{Name = "IT Department"; Alias = "IT"; Owner = "it-director@district.edu"}
    @{Name = "Curriculum & Instruction"; Alias = "Curriculum"; Owner = "curriculum-director@district.edu"}
    @{Name = "Special Education"; Alias = "SPED"; Owner = "sped-director@district.edu"}
    @{Name = "Human Resources"; Alias = "HR"; Owner = "hr-director@district.edu"}
)

foreach ($Dept in $Departments) {
    $SiteUrl = "https://district.sharepoint.com/sites/$($Dept.Alias)"

    New-SPOSite `
        -Url $SiteUrl `
        -Owner $Dept.Owner `
        -StorageQuota 25600 `  # 25 GB
        -Title $Dept.Name `
        -Template "STS#3"  # Team Site

    Write-Host "SharePoint site created: $($Dept.Name)" -ForegroundColor Green
}
```

---

## Microsoft Teams for Education

### Auto-Create Class Teams from SIS

**Sync with School Data Sync (SDS) to create Teams for every course:**

```powershell
# School Data Sync PowerShell integration
$SISCourses = Import-Csv "C:\SDS\Courses.csv"  # Columns: CourseID, CourseName, Teacher, Students

foreach ($Course in $SISCourses) {
    # Create Team from template
    $Team = New-Team `
        -DisplayName $Course.CourseName `
        -Description "Course: $($Course.CourseID) | Teacher: $($Course.Teacher)" `
        -Visibility Private `
        -Template "EDU_Class"

    # Add teacher as owner
    Add-TeamUser -GroupId $Team.GroupId -User $Course.Teacher -Role Owner

    # Add students as members
    $Students = $Course.Students -split ";"
    foreach ($Student in $Students) {
        Add-TeamUser -GroupId $Team.GroupId -User $Student -Role Member
    }

    Write-Host "Team created: $($Course.CourseName) [$($Students.Count) students]" -ForegroundColor Green
}
```

---

## Automated Reporting and Compliance

### Monthly License Usage Report

```powershell
# Generate license usage report for budget planning
$LicenseReport = Get-MgSubscribedSku | ForEach-Object {
    [PSCustomObject]@{
        Product = $_.SkuPartNumber
        TotalLicenses = $_.PrepaidUnits.Enabled
        AssignedLicenses = $_.ConsumedUnits
        AvailableLicenses = $_.PrepaidUnits.Enabled - $_.ConsumedUnits
        UtilizationPercent = [Math]::Round(($_.ConsumedUnits / $_.PrepaidUnits.Enabled) * 100, 1)
    }
}

$LicenseReport | Format-Table -AutoSize

# Export to CSV for leadership review
$LicenseReport | Export-Csv "C:\Reports\M365-License-Usage-$(Get-Date -Format 'yyyy-MM').csv" -NoTypeInformation
```

### Conditional Access Sign-In Report

```powershell
# Identify users failing Conditional Access policies
$FailedSignIns = Get-MgAuditLogSignIn -Filter "status/errorCode ne 0 and createdDateTime ge $(Get-Date).AddDays(-7)" -All

$FailedCASignIns = $FailedSignIns | Where-Object {
    $_.ConditionalAccessStatus -eq "failure"
} | Select-Object UserPrincipalName, AppDisplayName, @{N='FailureReason';E={$_.Status.FailureReason}}, CreatedDateTime

$FailedCASignIns | Format-Table -AutoSize

# Alert IT team if high failure rate
if ($FailedCASignIns.Count -gt 50) {
    Send-MailMessage `
        -To "it-security@district.edu" `
        -From "azure-alerts@district.edu" `
        -Subject "HIGH VOLUME: Conditional Access Sign-In Failures" `
        -Body ($FailedCASignIns | Out-String) `
        -SmtpServer "smtp.district.edu"
}
```

---

## Integration with Third-Party Educational Platforms

### Canvas LMS SSO via Azure AD

**Configure SAML-based SSO for Canvas Learning Management System:**

```powershell
# Register Canvas as Enterprise Application in Azure AD
$CanvasApp = New-MgServicePrincipal -AppId "5d5b6a65-45ab-42c0-8b74-d1e2002c8e5b"  # Canvas App ID from Azure AD Gallery

# Assign all students and staff
$AllUsers = Get-MgGroup -Filter "displayName eq 'All-Users'"
New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $CanvasApp.Id `
    -PrincipalId $AllUsers.Id `
    -ResourceId $CanvasApp.Id `
    -AppRoleId "00000000-0000-0000-0000-000000000000"  # Default access

Write-Host "Canvas LMS SSO configured - users can sign in with Azure AD credentials" -ForegroundColor Green
```

---

## 2026 Technology Trends for K-12

### 1. Copilot for Microsoft 365 in Education

**AI-powered productivity assistant for staff:**
- Automated lesson plan generation
- Email summarization for administrators
- Data analysis in Excel for student performance metrics
- Meeting summaries in Teams

**PowerShell management:**
```powershell
# Enable Copilot for specific user groups (teachers, administrators)
$TeacherGroup = Get-MgGroup -Filter "displayName eq 'Teachers'"

# Assign Copilot license
$CopilotSKU = Get-MgSubscribedSku | Where-Object {$_.SkuPartNumber -eq "Microsoft_365_Copilot"}
Set-MgUserLicense -UserId "teacher@district.edu" -AddLicenses @{SkuId = $CopilotSKU.SkuId} -RemoveLicenses @()
```

### 2. Entra ID Protection (Identity Threat Detection)

**Automated risk-based Conditional Access:**
```powershell
# Create risk-based policy (block high-risk sign-ins)
$RiskPolicy = @{
    displayName = "Block High-Risk Sign-Ins"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
        }
        userRiskLevels = @("high")
        signInRiskLevels = @("high")
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("block")
    }
}

New-MgConditionalAccessPolicy -BodyParameter $RiskPolicy
```

### 3. Defender for Endpoint (Student Device Protection)

**Deploy Microsoft Defender for Endpoint to district-owned devices:**
```powershell
# Onboard devices to Defender for Endpoint via Intune
$DefenderPolicy = @{
    "@odata.type" = "#microsoft.graph.windowsDefenderAdvancedThreatProtectionConfiguration"
    displayName = "Defender for Endpoint - District Devices"
    enableExpeditedTelemetryReporting = $true
}

New-MgDeviceManagementDeviceConfiguration -BodyParameter $DefenderPolicy
```

---

## Best Practices Summary

1. **OneDrive Migration:** Phased approach over 18-24 months, pilot with IT department first
2. **Conditional Access:** Require MFA for staff, restrict students to managed devices
3. **Autopilot:** Zero-touch device provisioning reduces IT workload by 75%
4. **Compliance Policies:** Enforce BitLocker, Windows Defender, minimum OS versions
5. **Teams for Education:** Automate class creation via School Data Sync (SDS)
6. **License Management:** Monthly usage reports prevent license over-purchasing
7. **SSO Integration:** Canvas, Google Classroom (legacy), Clever via Azure AD SAML
8. **Security Monitoring:** Weekly Conditional Access failure reports, Identity Protection alerts
9. **Storage Quotas:** 5 GB students, 100 GB staff (adjust based on district budget)
10. **Copilot Rollout (2026):** Teachers and administrators first, evaluate before student deployment

---

## Additional Resources

- [Microsoft 365 Education Deployment Guide](https://learn.microsoft.com/en-us/microsoft-365/education/)
- [School Data Sync Documentation](https://learn.microsoft.com/en-us/schooldatasync/)
- [Intune for Education](https://learn.microsoft.com/en-us/intune-education/)
- [OneDrive Migration Tools](https://learn.microsoft.com/en-us/sharepointmigration/migrate-to-sharepoint-online)
- [Azure AD Conditional Access Best Practices](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/)
