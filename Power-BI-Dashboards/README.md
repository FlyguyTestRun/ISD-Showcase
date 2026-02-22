# Power BI Dashboards, K-12 IT Operations

Operational KPI dashboards built around how a large district runs at the start of each school year: account provisioning velocity, device assignment tracking, enrollment trends, and campus capacity. Data is synthetic at KISD-approximate scale (34,000 students, 23,000 Windows 11 devices, 22+ campuses).

---

## Dashboard Preview

[Full PDF export](./Dashboards/KISD-Dashboards.pdf) | [Source file: `Dashboards/KISD.pbix`](./Dashboards/KISD.pbix)

---

## Dashboard Pages

### Page 1, Enrollment Overview
Enrollment by grade (K-12), grade band distribution (Elementary / Middle / High School), year-over-year change, and campus capacity utilization. Over-capacity campuses surface first. GradeSort integer ensures K sorts correctly. This is a common failure point in school district Power BI builds.

### Page 2, Provisioning and Identity
Daily new student and staff accounts with the August surge visible. Monthly created vs. disabled comparison. Average provisioning time tracked against a 15-minute SLA. Password reset volume trending weekly. FERPA audit log completeness gauge (target 99%+, alert below 97%).

### Page 3, Device Assignment (Grades K-12)
Autopilot fleet status by campus: Assigned / Pending / Unassigned. Provisioning success rate trending over 26 weeks. Devices not seen in 7 and 30 days by grade band, loss and reimage candidates. New enrollment device assignment tracked through provisioning.

### Page 4, Campus Capacity
Campus-level enrollment vs. capacity with utilization percent. Transfer in/out tracking by campus and month. Conditional formatting: >95% utilization flags red, >85% amber.

---

## Data Model (4 CSVs, Student Enrollment Analytics)

| File | Granularity | Key Columns |
|------|-------------|-------------|
| `student-enrollment-trends.csv` | Daily x Grade | `GradeSort` (0-12), `GradeLabel`, `GradeBand`, `TotalEnrolled`, provisioning counts |
| `campus-enrollment.csv` | Weekly x Campus | Campus name, `GradeBand`, `Capacity`, `CapacityUtilPct`, transfers |
| `account-provisioning.csv` | Daily | New/disabled accounts, `AvgProvisioningTimeMins`, `PasswordResetsTotal`, `AuditLogCompletePct` |
| `device-assignment.csv` | Weekly x Campus | `FleetSize`, assigned/pending/unassigned, `AutopilotSuccessRatePct`, devices not seen |

The other two dashboards (IT Infrastructure Health, Network Infrastructure Monitoring) use separate CSV sets in their own subfolders.

---

## Data Generation

All sample data is reproducible via PowerShell:
- `Student-Enrollment-Analytics/Generate-EnrollmentData.ps1`: regenerates all 4 enrollment CSVs
- `IT-Infrastructure-Health/Generate-SampleData.ps1`: AD health, endpoint, backup data
- `Network-Infrastructure-Monitoring/Generate-NetworkData.ps1`: 22-campus network inventory

---

## What This Shows

- Star schema data model: DateTable, CampusDim, GradeDim as dimension tables, all fact tables connect through shared dimensions, not directly to each other
- K-12 grade handling: GradeSort integer (0=K) prevents "K" string from breaking numeric aggregation
- DAX time intelligence: DATESMTD, LASTDATE, DATESINPERIOD for provisioning and trend measures
- Conditional formatting for operational alerting (capacity >95% = red)
- Slicer sync across pages for consistent district/campus/date filtering

---

**Author:** Bryan Shaw
**Last Updated:** February 2026
