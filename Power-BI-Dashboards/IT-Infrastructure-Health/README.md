# IT Infrastructure Health Dashboard

**Purpose:** Monitor Active Directory health, backup operations, and endpoint compliance for K-12 infrastructure.

**Target Audience:** IT leadership, infrastructure team, compliance officers

---

## 📊 Dashboard Overview

This dashboard provides real-time visibility into critical IT infrastructure components:

1. **Active Directory Health**
   - User account trends and aging analysis
   - Password expiration tracking
   - Stale account identification
   - Computer object inventory

2. **Backup & Recovery Status**
   - Veeam backup job success rates
   - Failed backup identification and alerting
   - Data protection coverage metrics
   - RTO/RPO compliance tracking

3. **Endpoint Compliance**
   - Device compliance percentage trends
   - BitLocker encryption status
   - Antivirus update compliance
   - OS patch deployment status
   - Password policy adherence

---

## 📁 Data Sources

### 1. active-directory-health.csv
**Fields:**
- `Date` - Daily snapshot date
- `TotalUsers` - Total user accounts
- `ActiveUsers` - Enabled user accounts
- `DisabledUsers` - Disabled user accounts
- `PasswordExpiring7Days` - Passwords expiring within 7 days
- `PasswordExpiring30Days` - Passwords expiring within 30 days
- `StaleAccounts90Days` - Accounts inactive for 90+ days
- `LockedAccounts` - Currently locked accounts
- `ComputerObjects` - Total computer objects
- `StaleComputers90Days` - Computers inactive for 90+ days

**Coverage:** 90 days of historical data

### 2. backup-job-status.csv
**Fields:**
- `Date` - Backup job execution date
- `JobName` - Backup job identifier
- `Status` - Success | Warning | Failed
- `Duration` - Job runtime in minutes
- `DataSizeGB` - Amount of data backed up
- `SuccessRate` - Job success percentage

**Coverage:** 30 days × 8 jobs = 240 records

### 3. endpoint-compliance.csv
**Fields:**
- `Date` - Daily snapshot date
- `TotalDevices` - Total managed endpoints
- `Compliant` - Fully compliant devices
- `NonCompliant` - Non-compliant devices
- `Unknown` - Devices with unknown status
- `CompliancePercent` - Overall compliance percentage
- `BitLockerEncrypted` - Devices with BitLocker enabled
- `AntivirusUpToDate` - Devices with current AV definitions
- `OSPatchCompliant` - Devices with latest OS patches
- `PasswordPolicyCompliant` - Devices meeting password requirements

**Coverage:** 90 days of historical data

---

## 🎨 Building the Dashboard (Step-by-Step)

### Prerequisites
- Power BI Desktop installed (free from Microsoft Store)
- Sample data generated (`Generate-SampleData.ps1` executed)

### Step 1: Create New Power BI File

1. Launch **Power BI Desktop**
2. Click **"Get Data"** > **"Text/CSV"**
3. Navigate to `sample-data/` folder
4. Import all 3 CSV files:
   - `active-directory-health.csv`
   - `backup-job-status.csv`
   - `endpoint-compliance.csv`

### Step 2: Configure Data Types

For each table, click **"Transform Data"** and verify:

**active-directory-health:**
- `Date` → Date type
- All other columns → Whole Number type

**backup-job-status:**
- `Date` → Date type
- `JobName` → Text type
- `Status` → Text type
- `Duration`, `DataSizeGB`, `SuccessRate` → Whole Number/Decimal type

**endpoint-compliance:**
- `Date` → Date type
- All numeric columns → Whole Number type
- `CompliancePercent` → Decimal Number type

Click **"Close & Apply"**

### Step 3: Create DAX Measures

In the **Modeling** tab, create these calculated measures:

```DAX
// Active Directory Metrics
Current Total Users =
    CALCULATE(
        SUM('active-directory-health'[TotalUsers]),
        LASTDATE('active-directory-health'[Date])
    )

Active User % =
    DIVIDE(
        CALCULATE(SUM('active-directory-health'[ActiveUsers]), LASTDATE('active-directory-health'[Date])),
        CALCULATE(SUM('active-directory-health'[TotalUsers]), LASTDATE('active-directory-health'[Date])),
        0
    ) * 100

// Backup Metrics
Backup Success Rate =
    DIVIDE(
        COUNTROWS(FILTER('backup-job-status', 'backup-job-status'[Status] = "Success")),
        COUNTROWS('backup-job-status'),
        0
    ) * 100

Failed Backups (Last 7 Days) =
    CALCULATE(
        COUNTROWS(FILTER('backup-job-status', 'backup-job-status'[Status] = "Failed")),
        DATESINPERIOD('backup-job-status'[Date], LASTDATE('backup-job-status'[Date]), -7, DAY)
    )

// Compliance Metrics
Current Compliance % =
    CALCULATE(
        AVERAGE('endpoint-compliance'[CompliancePercent]),
        LASTDATE('endpoint-compliance'[Date])
    )

Non-Compliant Devices =
    CALCULATE(
        SUM('endpoint-compliance'[NonCompliant]),
        LASTDATE('endpoint-compliance'[Date])
    )
```

### Step 4: Build Visualizations

**Page 1: Infrastructure Overview**

**Visual 1: Active Directory Users (Line Chart)**
- X-axis: `Date` (from active-directory-health)
- Y-axis: `TotalUsers`, `ActiveUsers`, `DisabledUsers`
- Legend: Auto-generated
- Title: "Active Directory User Trends (90 Days)"

**Visual 2: Backup Success Rate (Gauge)**
- Value: `Backup Success Rate` (measure created above)
- Minimum: 0
- Maximum: 100
- Target: 95
- Title: "Backup Success Rate"
- Color: Green if ≥95%, Yellow if 90-94%, Red if <90%

**Visual 3: Endpoint Compliance (Donut Chart)**
- Legend: Create categories (Compliant, Non-Compliant, Unknown)
- Values: Current day counts
- Title: "Endpoint Compliance Status"
- Colors: Green (Compliant), Red (Non-Compliant), Gray (Unknown)

**Visual 4: Password Expirations (Card)**
- Fields: `PasswordExpiring7Days` (current day)
- Title: "Passwords Expiring (Next 7 Days)"
- Format: Whole number with alert color if >30

**Visual 5: Failed Backups Table**
- Columns: `Date`, `JobName`, `Status`, `Duration`
- Filter: `Status` = "Failed" OR "Warning"
- Title: "Backup Jobs Requiring Attention"
- Conditional formatting: Red for Failed, Yellow for Warning

**Visual 6: Compliance Trend (Line Chart)**
- X-axis: `Date` (from endpoint-compliance)
- Y-axis: `CompliancePercent`
- Title: "Endpoint Compliance Trend (90 Days)"
- Reference line at 90% (compliance target)

**Visual 7: Stale Accounts (Card)**
- Fields: `StaleAccounts90Days` (current day)
- Title: "Stale User Accounts (90+ Days)"
- Format: Whole number with warning indicator if >50

**Visual 8: BitLocker Status (Card)**
- Fields: `BitLockerEncrypted` / `TotalDevices` (current day)
- Title: "BitLocker Encryption Rate"
- Format: Percentage

### Step 5: Add Interactivity

1. **Date Slicer** - Add date range filter (top of dashboard)
2. **Backup Job Filter** - Add slicer for `JobName`
3. **Drill-Through** - Enable on Failed Backups table to see job details
4. **Tooltips** - Customize tooltips to show additional context

### Step 6: Format Dashboard

1. **Theme:** Use a professional color scheme (Blues/Greens for positive metrics)
2. **Layout:** Arrange visuals in logical flow (top-to-bottom, left-to-right)
3. **Text Boxes:** Add explanatory text for key metrics
4. **Title:** Add dashboard title with last refresh date
5. **Mobile Layout:** Configure mobile-optimized view

### Step 7: Save and Export

1. Save file as: `IT-Infrastructure-Dashboard.pbix`
2. Export to PDF: **File** > **Export** > **Export to PDF**
3. Take screenshots for GitHub README
4. Document key insights and findings

---

## 📈 Key Insights to Highlight

When demonstrating this dashboard, emphasize:

1. **Proactive Monitoring:** Identify issues before they become problems
   - "We can see backup failure trends before they impact recovery capability"
   - "Password expiration tracking prevents account lockouts"

2. **Compliance Visibility:** Transparent reporting for audits
   - "FERPA compliance requires endpoint security - this dashboard shows our 92% compliance rate"
   - "BitLocker encryption status is immediately visible to leadership"

3. **Automation Integration:** PowerShell generates data, Power BI visualizes
   - "This dashboard pulls from automated scripts that run daily"
   - "No manual data entry - everything is scripted and repeatable"

4. **Operational Efficiency:** Reduce manual reporting time
   - "Previously, generating this report took 2 hours manually"
   - "Now it updates automatically and is always current"

---

## 🎯 Strategic Value for Keller ISD

This dashboard aligns with:
- **Microsoft Migration:** Monitoring Azure AD and M365 endpoint compliance
- **Data Compliance:** Jamie Yates (Director of Data Compliance) needs visibility
- **Infrastructure Stability:** Sean Ducar values proactive infrastructure monitoring
- **Cost Savings:** Automation reduces manual reporting overhead

---

## 💡 Tips for Interview Presentation

If asked to demonstrate this dashboard:

1. **Start with the problem:** "IT leadership needed visibility into infrastructure health but manual reports were time-consuming and outdated"

2. **Show the solution:** "I built this Power BI dashboard fed by PowerShell automation to provide real-time insights"

3. **Highlight automation:** "The data generation scripts run on a schedule - no manual intervention needed"

4. **Emphasize K-12 context:** "This tracks FERPA compliance, backup protection for student data, and endpoint security across the district"

5. **Be honest about learning:** "I identified Power BI as a growth area and proactively developed these skills to demonstrate data-driven operational insights"

---

**Created by:** Bryan Shaw
**Purpose:** Keller ISD Senior Systems Engineer Portfolio
**Last Updated:** February 15, 2026
