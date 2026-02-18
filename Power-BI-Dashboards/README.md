# Power BI Dashboards for K-12 IT Operations

This section demonstrates how infrastructure automation data can be transformed into operational KPIs and leadership-ready dashboards.

## Dashboard Set

### 1) IT Infrastructure Health
- **Files:** `IT-Infrastructure-Dashboard.pbix`, `IT-Infrastructure-Dashboard.pdf`
- **Data Sources:** Active Directory health, backup status, endpoint compliance
- **Primary KPIs:** Backup success rate, compliance rate, account lifecycle indicators

### 2) Student Enrollment Analytics
- **Files:** `Student-Enrollment-Dashboard.pbix`, `Student-Enrollment-Dashboard.pdf`
- **Data Sources:** Enrollment trend dataset + account lifecycle activity
- **Primary KPIs:** Enrollment distribution, provisioning velocity, FERPA trend signals

### 3) Network Infrastructure Monitoring
- **Files:** `Network-Infrastructure-Dashboard.pbix`, `Network-Infrastructure-Dashboard.pdf`
- **Data Sources:** DHCP scope utilization + network device inventory
- **Primary KPIs:** Scope utilization, healthy device %, campus/device distribution

---

## Data Generation (Reproducible)

Each dashboard folder contains a PowerShell script to regenerate synthetic demo data:

- `IT-Infrastructure-Health/Generate-SampleData.ps1`
- `Student-Enrollment-Analytics/Generate-EnrollmentData.ps1`
- `Network-Infrastructure-Monitoring/Generate-NetworkData.ps1`

This supports repeatable demos, safe sharing, and clean portfolio portability.

---

## Why This Matters

These dashboards demonstrate:
- **Operational visibility:** health and risk signals in one view
- **Proactive management:** trend-based issue detection
- **Compliance support:** auditable metrics presentation
- **Leadership communication:** concise KPI reporting for decision-makers

---

## Quick File Map

```text
Power-BI-Dashboards/
├── IT-Infrastructure-Health/
│   ├── Generate-SampleData.ps1
│   ├── sample-data/
│   ├── IT-Infrastructure-Dashboard.pbix
│   └── IT-Infrastructure-Dashboard.pdf
├── Student-Enrollment-Analytics/
│   ├── Generate-EnrollmentData.ps1
│   ├── sample-data/
│   ├── Student-Enrollment-Dashboard.pbix
│   └── Student-Enrollment-Dashboard.pdf
├── Network-Infrastructure-Monitoring/
│   ├── Generate-NetworkData.ps1
│   ├── sample-data/
│   ├── Network-Infrastructure-Dashboard.pbix
│   └── Network-Infrastructure-Dashboard.pdf
└── IMPLEMENTATION-STATUS.md
```
