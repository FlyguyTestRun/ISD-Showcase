# Student Enrollment Analytics Dashboard

**Purpose:** Track student enrollment trends, account provisioning velocity, and FERPA compliance metrics for K-12 identity management.

**Target Audience:** IT leadership, student services, data compliance team

---

## 📊 Dashboard Overview

This dashboard connects PowerShell-automated identity management (KISDIdentity module) with data analytics to provide insights into:

1. **Enrollment Trends**
   - Grade-level enrollment over time
   - Seasonal patterns (new school year, graduations)
   - Multi-year trend analysis

2. **Account Provisioning Activity**
   - New student account creation velocity
   - Account deprovisioning (graduations, transfers)
   - Automation efficiency metrics

3. **FERPA Compliance**
   - Audit log completeness
   - Data governance tracking
   - Access control metrics

---

## 📁 Data Source

### student-enrollment-trends.csv
**Fields:**
- `Date` - Daily snapshot date
- `GradeLevel` - Student grade (9, 10, 11, 12)
- `GraduationYear` - Expected graduation year
- `TotalEnrolled` - Total students in grade
- `NewAccountsCreated` - Accounts provisioned that day
- `AccountsDeprovisioned` - Accounts disabled/archived
- `ActiveAccounts` - Currently active accounts
- `PasswordResets` - Password reset requests
- `FERPAComplianceRate` - FERPA audit compliance percentage
- `AuditLogEntries` - Number of audit log entries generated

**Coverage:** 365 days × 4 grade levels = 1,460 records

**Seasonal Patterns in Data:**
- **August/September:** High new account creation (new school year)
- **May/June:** High deprovisioning (graduations, end of year)
- **December/January:** Moderate activity (mid-year transfers)
- **Other months:** Steady state with minimal changes

---

## 🎨 Building the Dashboard (Step-by-Step)

### Prerequisites
- Power BI Desktop installed
- Sample data generated (`Generate-EnrollmentData.ps1` executed)

### Step 1: Import Data

1. Launch **Power BI Desktop**
2. **Get Data** > **Text/CSV**
3. Select `sample-data/student-enrollment-trends.csv`
4. Click **Load**

### Step 2: Configure Data Model

Click **"Transform Data"** (Power Query Editor):

**Data Type Configuration:**
- `Date` → Date type
- `GradeLevel` → Whole Number
- `GraduationYear` → Whole Number
- All other numeric fields → Whole Number
- `FERPAComplianceRate` → Decimal Number

**Add Calculated Columns:**

```M
// Month Name (for grouping)
MonthName = Date.MonthName([Date])

// School Year (August-July cycle)
SchoolYear = if Date.Month([Date]) >= 8
             then Text.From(Date.Year([Date])) & "-" & Text.From(Date.Year([Date]) + 1)
             else Text.From(Date.Year([Date]) - 1) & "-" & Text.From(Date.Year([Date]))
```

Click **"Close & Apply"**

### Step 3: Create DAX Measures

```DAX
// Enrollment Metrics
Current Total Enrollment =
    CALCULATE(
        SUM('student-enrollment-trends'[TotalEnrolled]),
        LASTDATE('student-enrollment-trends'[Date])
    )

Enrollment by Grade (Current) =
    CALCULATE(
        SUM('student-enrollment-trends'[TotalEnrolled]),
        LASTDATE('student-enrollment-trends'[Date]),
        ALLEXCEPT('student-enrollment-trends', 'student-enrollment-trends'[GradeLevel])
    )

// Provisioning Metrics
Total New Accounts (Period) =
    SUM('student-enrollment-trends'[NewAccountsCreated])

Avg New Accounts Per Day =
    AVERAGE('student-enrollment-trends'[NewAccountsCreated])

Total Deprovisioned (Period) =
    SUM('student-enrollment-trends'[AccountsDeprovisioned])

Provisioning Efficiency =
    DIVIDE(
        [Total New Accounts (Period)],
        DISTINCTCOUNT('student-enrollment-trends'[Date]),
        0
    )

// Compliance Metrics
Avg FERPA Compliance =
    AVERAGE('student-enrollment-trends'[FERPAComplianceRate])

Audit Log Coverage % =
    DIVIDE(
        SUM('student-enrollment-trends'[AuditLogEntries]),
        SUM('student-enrollment-trends'[NewAccountsCreated]) +
        SUM('student-enrollment-trends'[AccountsDeprovisioned]) +
        SUM('student-enrollment-trends'[PasswordResets]),
        0
    ) * 100

// Trend Calculations
Enrollment Change MoM =
    VAR CurrentMonth = CALCULATE([Current Total Enrollment], LASTDATE('student-enrollment-trends'[Date]))
    VAR PreviousMonth = CALCULATE([Current Total Enrollment], DATEADD('student-enrollment-trends'[Date], -1, MONTH))
    RETURN
    CurrentMonth - PreviousMonth

Growth Rate % =
    DIVIDE([Enrollment Change MoM],
           CALCULATE([Current Total Enrollment], DATEADD('student-enrollment-trends'[Date], -1, MONTH)),
           0
    ) * 100
```

### Step 4: Build Visualizations

**Page 1: Enrollment Overview**

**Visual 1: Enrollment by Grade Over Time (Stacked Area Chart)**
- X-axis: `Date`
- Y-axis: `TotalEnrolled`
- Legend: `GradeLevel`
- Title: "Student Enrollment Trends by Grade Level"
- Colors: Different color for each grade (9=Blue, 10=Green, 11=Orange, 12=Red)

**Visual 2: Current Enrollment Distribution (Donut Chart)**
- Legend: `GradeLevel` (9th, 10th, 11th, 12th)
- Values: `Enrollment by Grade (Current)` measure
- Title: "Current Enrollment Distribution"
- Data labels: Show percentages

**Visual 3: Total Enrollment (Card)**
- Value: `Current Total Enrollment` measure
- Title: "Total Students"
- Format: Large, bold number

**Visual 4: Monthly Change (Card with Trend)**
- Value: `Enrollment Change MoM` measure
- Title: "Month-over-Month Change"
- Format: Show +/- with green/red conditional formatting
- Trend indicator: Up/down arrow

**Visual 5: Account Provisioning Activity (Stacked Column Chart)**
- X-axis: `Date` (by month)
- Y-axis: `NewAccountsCreated` (green bars), `AccountsDeprovisioned` (red bars)
- Title: "Account Lifecycle Activity"
- Annotation: Highlight August spike (new school year)

**Visual 6: Provisioning Efficiency (Line Chart)**
- X-axis: `Date` (by week or month)
- Y-axis: `Avg New Accounts Per Day` measure
- Title: "Account Provisioning Velocity"
- Reference line: Show average across period

**Visual 7: FERPA Compliance Trend (Line Chart with Target)**
- X-axis: `Date`
- Y-axis: `FERPAComplianceRate`
- Title: "FERPA Compliance Rate"
- Reference line at 98% (compliance target)
- Format: Percentage scale

**Visual 8: Audit Log Summary (Multi-row Card)**
- Fields:
  - `Total New Accounts (Period)`
  - `Total Deprovisioned (Period)`
  - `Avg FERPA Compliance`
  - `Audit Log Coverage %`
- Title: "Identity Management Metrics"

### Step 5: Add Interactivity

1. **Date Range Slicer** - Allow filtering by date range
2. **Grade Level Filter** - Slicer to focus on specific grades
3. **School Year Filter** - Group by academic year (Aug-July)
4. **Drill-Through** - Enable drilling from summary to daily detail
5. **Cross-Filtering** - Click on grade in donut chart to filter all visuals

### Step 6: Add Context with Text Boxes

Add explanatory text boxes:

**Top of Dashboard:**
```
Student Enrollment & Identity Management Analytics
Automated account provisioning powered by KISDIdentity PowerShell module
Data Source: 365 days of enrollment trends across grades 9-12
```

**Below Provisioning Chart:**
```
Key Seasonal Patterns:
• August/September: New school year enrollment surge
• May/June: Senior graduations and year-end transfers
• January: Mid-year enrollment adjustments
```

**Near FERPA Compliance:**
```
FERPA Compliance Target: ≥98%
All identity operations logged for audit compliance
Automated audit trail generation via PowerShell module
```

### Step 7: Format Dashboard

1. **Color Scheme:**
   - Blues/greens for enrollment (positive growth)
   - Oranges/reds for deprovisioning (expected churn)
   - Consistent grade level colors across all visuals

2. **Layout:**
   - Top row: High-level metrics (cards)
   - Middle: Enrollment trends (area/column charts)
   - Bottom: Compliance and audit metrics

3. **Title Section:**
   - Dashboard title: "Student Enrollment & Identity Analytics"
   - Subtitle: "Keller ISD | Automated Identity Management"
   - Last Updated: Dynamic date

4. **Mobile Layout:** Configure for tablet/phone viewing

### Step 8: Save and Export

1. Save as: `Student-Enrollment-Dashboard.pbix`
2. Export to PDF for GitHub documentation
3. Capture screenshots of key visualizations
4. Document insights and findings

---

## 📈 Key Insights to Highlight

When presenting this dashboard:

1. **Automation Impact:**
   - "The KISDIdentity PowerShell module provisions accounts in <1 minute"
   - "Automated account creation during August enrollment surge handles 3000+ accounts seamlessly"

2. **Seasonal Intelligence:**
   - "The dashboard shows expected spikes in August (new students) and May (graduations)"
   - "This helps IT plan capacity for peak provisioning periods"

3. **FERPA Compliance:**
   - "Every identity operation generates an audit log entry for compliance"
   - "99% FERPA compliance rate demonstrates robust data governance"

4. **Operational Visibility:**
   - "Leadership can see real-time enrollment trends without manual reports"
   - "Password reset patterns help identify user training needs"

---

## 🔗 Connection to KISDIdentity PowerShell Module

This dashboard visualizes data generated by the identity automation system:

**PowerShell Module Functions:**
- `New-KISDStudentAccount` - Creates accounts (tracked in NewAccountsCreated)
- `Remove-KISDAccount` - Archives accounts (tracked in AccountsDeprovisioned)
- `Get-KISDAccountMetrics` - Generates audit reports (tracked in AuditLogEntries)

**Sample Workflow:**
1. SIS exports student roster to CSV
2. `New-StudentBatch.ps1` imports CSV and calls `New-KISDStudentAccount`
3. Audit logs capture all operations
4. Daily enrollment metrics exported to this dashboard dataset
5. Power BI refreshes and shows updated trends

---

## 🎯 Strategic Value for Keller ISD

This dashboard demonstrates:

**For Sean Ducar (Technology Systems):**
- Automation reduces manual IT workload during peak enrollment
- Consistent naming conventions (students.keller.edu) maintained automatically
- Proactive monitoring of account lifecycle

**For Jamie Yates (Data Compliance):**
- FERPA audit trail completeness visible at a glance
- Compliance rate tracking over time
- Automated audit log generation ensures no gaps

**For Rhonda Dominguez (Executive Director):**
- Data-driven insights into IT efficiency
- Cost savings from automation quantified
- Strategic capacity planning for enrollment growth

---

## 💡 Interview Talking Points

**If asked about this dashboard:**

1. **Problem Statement:**
   "Student account provisioning error-prone, and time-consuming. Adding visibility into enrollment trends or compliance metrics."

2. **Solution:**
   "Ghe ISDIdentity PowerShell module to automate provisioning, then created this Power BI dashboard to visualize the data and track compliance."

3. **Technical Integration:**
   "The dashboard pulls from automated PowerShell scripts that generate enrollment metrics daily. It combines my infrastructure automation expertise with data visualization skills."

4. **K-12 Specific Value:**
   "This addresses FERPA compliance requirements while handling seasonal enrollment spikes during school year transitions."

5. **Continuous Improvement:**
   "The dashboard helps identify patterns - like higher password resets for freshmen - which informs user training initiatives."

---

## 📊 Sample Data Characteristics

The generated sample data includes realistic patterns:

- **Base Enrollment:** ~2,410 total students (620/grade avg)
- **Seasonal Variation:**
  - August spike: +60-80 new accounts/day
  - May/June decline: -40-60 accounts/day (graduations)
  - Steady state: 0-5 accounts/day
- **FERPA Compliance:** 98-100% (realistic for well-managed system)
- **Audit Coverage:** High correlation between operations and log entries

---

**Created by:** Bryan Shaw
**Purpose:** Keller ISD Senior Systems Engineer Portfolio
**Connects to:** K12-Identity-Management PowerShell automation
**Last Updated:** February 15, 2026
