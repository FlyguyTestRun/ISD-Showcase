# Power BI Dashboards for K-12 IT Infrastructure

**Purpose:** Demonstrate data visualization and operational analytics capabilities for Keller ISD Senior Systems Engineer position.

**Created by:** Bryan Shaw | February 2026

---

## 📋 Overview

This folder contains three professional Power BI dashboards that showcase IT infrastructure monitoring, student enrollment analytics, and network operations visibility. Each dashboard demonstrates the integration of PowerShell automation with data-driven insights to provide leadership visibility into technology operations.

**Strategic Alignment:**
- ✅ **Keller ISD Microsoft Migration:** Monitoring Azure AD, M365, and Windows endpoints
- ✅ **Data Compliance:** FERPA audit trails and compliance reporting (Jamie Yates)
- ✅ **Infrastructure Stability:** Proactive monitoring and capacity planning (Sean Ducar)
- ✅ **Cost Optimization:** Automation reduces manual reporting overhead

---

## 📊 Dashboard Portfolio

### 1. IT Infrastructure Health Dashboard
**[View Details](./IT-Infrastructure-Health/)**

**Focus:** Active Directory, Backup/DR, Endpoint Compliance

**Key Metrics:**
- 2,450 user accounts monitored
- 95%+ backup success rate
- 92% endpoint compliance rate
- 90 days of historical trending

**Business Value:**
- Proactive issue detection before service impact
- FERPA compliance visibility for audits
- Automated alerting for failed backups
- Password expiration tracking prevents lockouts

**Data Sources:**
- `active-directory-health.csv` (90 records)
- `backup-job-status.csv` (240 records)
- `endpoint-compliance.csv` (90 records)

**Estimated Build Time:** 4-6 hours

---

### 2. Student Enrollment Analytics Dashboard
**[View Details](./Student-Enrollment-Analytics/)**

**Focus:** Enrollment trends, Account provisioning, FERPA compliance

**Key Metrics:**
- 2,410 total students across grades 9-12
- 365 days of enrollment trend data
- Automated account provisioning velocity
- 99% FERPA compliance rate

**Business Value:**
- Seasonal enrollment pattern identification
- Capacity planning for peak provisioning periods
- Automation efficiency tracking
- Audit trail completeness verification

**Data Sources:**
- `student-enrollment-trends.csv` (1,460 records)

**Integration:** Visualizes data from KISDIdentity PowerShell module

**Estimated Build Time:** 3-4 hours

---

### 3. Network Infrastructure Monitoring Dashboard
**[View Details](./Network-Infrastructure-Monitoring/)**

**Focus:** DHCP utilization, Device inventory, Campus connectivity

**Key Metrics:**
- 439 network devices across 4 campuses
- 5 VLAN scopes with utilization tracking
- 92% device health rate
- 30 days of DHCP trend data

**Business Value:**
- Capacity planning for network growth
- Proactive device maintenance scheduling
- CIPA-compliant VLAN segmentation visibility
- Multi-campus infrastructure oversight

**Data Sources:**
- `dhcp-scope-utilization.csv` (150 records)
- `network-device-inventory.csv` (439 devices)

**Integration:** Aligns with K12-Network-Architecture documentation

**Estimated Build Time:** 3-4 hours

---

## 🚀 Quick Start Guide

### Prerequisites

1. **Download Power BI Desktop** (Free)
   - Microsoft Store: Search "Power BI Desktop"
   - Direct: https://aka.ms/pbidesktopstore
   - System Requirements: Windows 10/11, 4GB RAM

2. **Generate Sample Data**
   ```powershell
   # From each dashboard folder, run:
   .\Generate-SampleData.ps1
   # Or .\Generate-EnrollmentData.ps1
   # Or .\Generate-NetworkData.ps1
   ```

### Build Process

**For Each Dashboard:**

1. **Open Power BI Desktop**
2. **Import Data:**
   - File > Get Data > Text/CSV
   - Navigate to `sample-data/` folder
   - Select CSV file(s)
   - Load data

3. **Configure Data Types:**
   - Click "Transform Data"
   - Set Date columns to Date type
   - Set numeric columns appropriately
   - Close & Apply

4. **Create DAX Measures:**
   - Follow measure definitions in each dashboard's README
   - Use Modeling tab > New Measure

5. **Build Visualizations:**
   - Follow step-by-step guide in README
   - Use Insert tab to add visuals
   - Configure fields, formats, colors

6. **Save Dashboard:**
   - Save as `.pbix` file
   - Export to PDF for GitHub documentation
   - Capture screenshots

**Total Estimated Time:** 10-12 hours for all 3 dashboards

---

## 📁 Folder Structure

```
Power-BI-Dashboards/
├── README.md (This file)
├── IMPLEMENTATION-STATUS.md (Progress tracking)
│
├── IT-Infrastructure-Health/
│   ├── README.md (Detailed build guide)
│   ├── Generate-SampleData.ps1
│   ├── sample-data/
│   │   ├── active-directory-health.csv
│   │   ├── backup-job-status.csv
│   │   └── endpoint-compliance.csv
│   └── IT-Infrastructure-Dashboard.pbix (To be created)
│
├── Student-Enrollment-Analytics/
│   ├── README.md (Detailed build guide)
│   ├── Generate-EnrollmentData.ps1
│   ├── sample-data/
│   │   └── student-enrollment-trends.csv
│   └── Student-Enrollment-Dashboard.pbix (To be created)
│
└── Network-Infrastructure-Monitoring/
    ├── README.md (Detailed build guide)
    ├── Generate-NetworkData.ps1
    ├── sample-data/
    │   ├── dhcp-scope-utilization.csv
    │   └── network-device-inventory.csv
    └── Network-Infrastructure-Dashboard.pbix (To be created)
```

---

## 💡 Why Power BI for K-12 IT?

### Industry Adoption
- **Microsoft Integration:** Native connectivity with Azure AD, Intune, M365
- **Cost-Effective:** Free desktop version, Pro licenses ~$10/user/month
- **Widespread Use:** [92% of Fortune 500 companies use Power BI](https://www.microsoft.com/en-us/power-platform/products/power-bi)
- **K-12 Specific:** Many districts use Power BI for student data and IT operations

### Technical Advantages
1. **Automation-Friendly:** PowerShell can generate/export data for dashboards
2. **Scheduled Refresh:** Dashboards update automatically on schedule
3. **Mobile Access:** View dashboards on tablets/phones
4. **Sharing:** Publish to Power BI Service for team access
5. **Security:** Row-level security for role-based access

### Keller ISD Alignment
- **Google → Microsoft Migration:** Power BI is part of Microsoft ecosystem
- **Data Compliance:** Meets FERPA requirements with proper access controls
- **Leadership Visibility:** Executives get insights without manual reports
- **IT Efficiency:** Reduces time spent generating status reports

---

## 🎯 Demonstrating Value to Keller ISD

### For Sean Ducar (Technology Systems Director)

**Problem:** "Infrastructure monitoring is reactive - we find out about issues when users call"

**Solution:** "These dashboards provide proactive monitoring with automated alerting for critical metrics like backup failures and device health"

**Impact:**
- Reduce downtime through early issue detection
- Free up IT staff from manual reporting
- Data-driven capacity planning for network and endpoints

### For Jamie Yates (Data Compliance Director)

**Problem:** "FERPA audits require proving we have audit trails and compliance controls"

**Solution:** "The dashboards show real-time FERPA compliance rates, audit log coverage, and identity governance metrics"

**Impact:**
- Instant compliance reporting for auditors
- Automated audit trail verification
- Visibility into data protection controls

### For Rhonda Dominguez (Executive Director of Technology)

**Problem:** "Leadership needs visibility into technology operations without overwhelming detail"

**Solution:** "Executive-friendly dashboards summarize infrastructure health, enrollment trends, and network capacity in visual format"

**Impact:**
- Data-driven budget justification
- Strategic technology planning insights
- ROI demonstration for automation initiatives

---

## 🔗 Integration with Existing ISD-Showcase Work

### Connections to Other Portfolio Components

**1. K12-Identity-Management**
- Student Enrollment Analytics dashboard visualizes KISDIdentity module activity
- Account provisioning metrics track `New-KISDStudentAccount` function usage
- FERPA compliance reporting aligns with audit logging

**2. Backup-DR-Automation**
- IT Infrastructure Health dashboard monitors Veeam backup jobs
- Success/failure rates validate backup automation effectiveness
- DR testing results can be visualized in future iterations

**3. K12-Network-Architecture**
- Network Infrastructure Monitoring dashboard shows DHCP scopes from VLAN design
- Device inventory aligns with documented network topology
- CIPA compliance VLAN segmentation is visualized

**4. Dell-Hardware-Management**
- Device health metrics could integrate with iDRAC health check data
- Firmware version tracking aligns with iDRAC update automation
- Future: Direct API integration for real-time hardware monitoring

---

## 📈 Progression Path: From Basic to Advanced

### Phase 1: Current Implementation (Demo/Portfolio)
✅ **What we have:**
- Synthetic data generated by PowerShell scripts
- Static CSV files for demonstration
- Professional dashboard designs
- Complete documentation

**Purpose:** Showcase Power BI skills and infrastructure monitoring concepts

### Phase 2: Production Implementation (If Hired)
🔄 **What would change:**
- Replace synthetic data with real production data
- Automate data collection via PowerShell scheduled tasks
- Connect to live systems (Azure AD, Veeam, DHCP servers, SCCM)
- Implement scheduled refresh in Power BI Service
- Add email alerts for critical thresholds

**Transition Time:** 2-3 weeks to productionize

### Phase 3: Advanced Analytics (Future State)
🚀 **Additional capabilities:**
- Predictive analytics (forecast enrollment, capacity needs)
- Machine learning for anomaly detection
- Real-time streaming data from monitoring systems
- Integration with ticketing system (ServiceNow/Jira)
- Custom Power BI visuals for specialized metrics

---

## 💬 Interview Talking Points

### Honest Framing (Power BI as Growth Area)

**Question:** "What's your experience with Power BI?"

**Answer:**
"I identified Power BI as a skill gap and proactively addressed it. I created these three dashboards to demonstrate IT infrastructure monitoring capabilities. While I'm still developing advanced Power BI skills, I'm comfortable with data modeling, DAX basics, and visualization best practices. More importantly, my PowerShell automation expertise makes data collection and integration straightforward - Power BI is the visualization layer on top of automated data pipelines I can build."

### Emphasize Automation + Analytics

"The real value isn't just the pretty dashboards - it's the automation behind them. PowerShell scripts generate the data, eliminating manual effort. Power BI makes that data actionable for leadership. Together, they multiply IT team productivity."

### K-12 Context

"Everything in these dashboards is designed with K-12 context in mind:
- FERPA compliance tracking
- School calendar-aware maintenance windows
- CIPA-compliant network segmentation
- Seasonal enrollment patterns
This isn't generic IT monitoring - it's purpose-built for educational environments."

### Learning Mindset

"I approach every skill gap the same way: research best practices, build working examples, document thoroughly, and iterate based on feedback. Power BI was no exception. I'm eager to expand these skills in a production K-12 environment."

---

## 📚 Resources Used (For Interview Follow-Up)

### Official Microsoft Documentation
- [Power BI Documentation](https://learn.microsoft.com/en-us/power-bi/)
- [DAX Formula Reference](https://learn.microsoft.com/en-us/dax/)
- [Power BI Best Practices](https://learn.microsoft.com/en-us/power-bi/guidance/power-bi-optimization)

### K-12 Power BI Examples
- [EdTech Magazine: Power BI in K-12](https://edtechmagazine.com/k12/article/2024/03/review-microsoft-power-bi-makes-data-actionable-k-12)
- [School Analytics with Power BI](https://www.schoolanalytix.com/)

### IT Infrastructure Monitoring
- [Power BI and Active Directory](https://biinsight.com/power-bi-and-active-directory-for-system-administrators/)
- [SCCM/Intune Dashboards](https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/customer-offerings-microsoft-endpoint-manager-powerbi-dashboard/ba-p/1044351)

---

## ✅ Next Steps

### To Complete This Portfolio Component:

1. **Install Power BI Desktop** (30 minutes)
   - Download from Microsoft Store
   - Launch and familiarize with interface

2. **Build Dashboard 1: IT Infrastructure Health** (4-6 hours)
   - Follow step-by-step guide in README
   - Save as .pbix file
   - Export PDF

3. **Build Dashboard 2: Student Enrollment Analytics** (3-4 hours)
   - Follow step-by-step guide
   - Save and export

4. **Build Dashboard 3: Network Infrastructure Monitoring** (3-4 hours)
   - Follow step-by-step guide
   - Save and export

5. **Create Documentation** (1-2 hours)
   - Screenshot each dashboard
   - Add screenshots to READMEs
   - Update main ISD-Showcase README

6. **Quality Review** (1 hour)
   - Test all dashboards
   - Verify data accuracy
   - Check formatting and labels

7. **Commit to GitHub** (30 minutes)
   - Add all files
   - Meaningful commit message
   - Push to repository

**Total Time Investment:** ~15-18 hours

---

## 🎉 Expected Outcome

When complete, you'll have:

✅ **3 professional Power BI dashboards** demonstrating infrastructure monitoring
✅ **Synthetic data** that tells a realistic K-12 IT operations story
✅ **Complete documentation** explaining purpose, build process, and strategic value
✅ **GitHub-ready materials** (PDFs, screenshots, READMEs)
✅ **Interview talking points** for discussing Power BI skills honestly

**Strategic Value:**
- Addresses identified skill gap in Power BI
- Demonstrates proactive learning and initiative
- Combines automation expertise (PowerShell) with analytics (Power BI)
- Shows data-driven approach to IT operations
- Aligns perfectly with Keller ISD's Microsoft migration

---

**Ready to build? Start with IT Infrastructure Health Dashboard - it has the most immediate operational value and showcases the broadest range of Power BI features!**

---

**Created by:** Bryan Shaw
**Portfolio:** Keller ISD Senior Systems Engineer
**Contact:** BryanJShaw@gmail.com | 817-653-5656
**Last Updated:** February 15, 2026
