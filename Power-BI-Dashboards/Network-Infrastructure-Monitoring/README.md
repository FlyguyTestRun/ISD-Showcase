# Network Infrastructure Monitoring Dashboard

**Purpose:** Monitor DHCP scope utilization, network device inventory, and campus connectivity for K-12 network infrastructure.

**Target Audience:** IT leadership, network infrastructure team, campus technology coordinators

---

## 📊 Dashboard Overview

This dashboard provides comprehensive visibility into Keller ISD's network infrastructure:

1. **DHCP Scope Management**
   - Utilization tracking across 5 VLANs
   - Capacity planning and threshold alerting
   - Lease rate monitoring

2. **Network Device Inventory**
   - 439 devices across 4 campuses
   - Device health status monitoring
   - Firmware version tracking
   - Hardware lifecycle management

3. **Campus Connectivity**
   - Device distribution by location
   - Uptime and availability metrics
   - Performance monitoring (CPU, memory, port utilization)

---

## 📁 Data Sources

### 1. dhcp-scope-utilization.csv
**Fields:**
- `Date` - Daily snapshot date
- `ScopeName` - VLAN identifier (Student, Staff, Admin, IoT, Guest)
- `Network` - IP network range (CIDR notation)
- `Campus` - Campus location (All, Main, etc.)
- `TotalAddresses` - Total available IP addresses in scope
- `AddressesUsed` - Currently assigned addresses
- `AddressesAvailable` - Remaining available addresses
- `UtilizationPercent` - Scope utilization percentage
- `LeaseRate` - New leases per hour
- `ExpiringLeases24h` - Leases expiring in next 24 hours

**Coverage:** 30 days × 5 VLANs = 150 records

**VLAN Segmentation:**
- **Student-VLAN (10.100.0.0/16):** 65,534 addresses - Student devices
- **Staff-VLAN (10.101.0.0/16):** 65,534 addresses - Teacher/staff devices
- **Admin-VLAN (10.102.0.0/24):** 254 addresses - Administrative systems
- **IoT-VLAN (10.103.0.0/16):** 65,534 addresses - IoT devices (cameras, printers, etc.)
- **Guest-VLAN (10.104.0.0/16):** 65,534 addresses - Visitor network

### 2. network-device-inventory.csv
**Fields:**
- `DeviceID` - Unique device identifier
- `DeviceType` - Core Switch | Distribution Switch | Access Switch | Wireless Controller | Access Point | Firewall | Router
- `Model` - Device model number (Cisco Catalyst, Palo Alto, etc.)
- `Location` - Campus location
- `HealthStatus` - Healthy | Warning | Critical
- `UptimeDays` - Days since last reboot
- `FirmwareVersion` - Current firmware/OS version
- `LastSeen` - Last contact timestamp
- `CPUUtilization` - CPU usage percentage
- `MemoryUtilization` - Memory usage percentage
- `PortUtilization` - Switch port usage percentage (switches only)

**Coverage:** 439 devices across 4 campuses

**Device Breakdown:**
- Core Switches: 4
- Distribution Switches: 12
- Access Switches: 85
- Wireless Controllers: 4
- Access Points: 320
- Firewalls: 6
- Routers: 8

---

## 🎨 Building the Dashboard (Step-by-Step)

### Prerequisites
- Power BI Desktop installed
- Sample data generated (`Generate-NetworkData.ps1` executed)

### Step 1: Import Data

1. Launch **Power BI Desktop**
2. **Get Data** > **Text/CSV**
3. Import both CSV files:
   - `dhcp-scope-utilization.csv`
   - `network-device-inventory.csv`

### Step 2: Configure Data Model

**Transform Data (Power Query):**

**dhcp-scope-utilization table:**
- `Date` → Date type
- `ScopeName`, `Network`, `Campus` → Text type
- All numeric fields → Whole Number
- `UtilizationPercent` → Decimal Number

**network-device-inventory table:**
- `DeviceID`, `DeviceType`, `Model`, `Location`, `HealthStatus`, `FirmwareVersion` → Text type
- `LastSeen` → DateTime type
- `UptimeDays`, `CPUUtilization`, `MemoryUtilization`, `PortUtilization` → Whole Number

**Add Calculated Columns:**

```M
// For network-device-inventory: Categorize uptime
UptimeCategory = if [UptimeDays] < 30 then "Recent Reboot"
                 else if [UptimeDays] < 90 then "Moderate"
                 else "Long Uptime"

// Health Score (0-100)
HealthScore = if [HealthStatus] = "Healthy" then 100
              else if [HealthStatus] = "Warning" then 50
              else 0
```

Click **"Close & Apply"**

### Step 3: Create DAX Measures

```DAX
// Device Inventory Metrics
Total Devices = COUNTROWS('network-device-inventory')

Healthy Devices = COUNTROWS(FILTER('network-device-inventory', 'network-device-inventory'[HealthStatus] = "Healthy"))

Healthy % = DIVIDE([Healthy Devices], [Total Devices], 0) * 100

Critical Devices = COUNTROWS(FILTER('network-device-inventory', 'network-device-inventory'[HealthStatus] = "Critical"))

Warning Devices = COUNTROWS(FILTER('network-device-inventory', 'network-device-inventory'[HealthStatus] = "Warning"))

Avg Uptime Days = AVERAGE('network-device-inventory'[UptimeDays])

Devices Requiring Attention = [Critical Devices] + [Warning Devices]

// DHCP Utilization Metrics
Current DHCP Utilization (Avg) =
    CALCULATE(
        AVERAGE('dhcp-scope-utilization'[UtilizationPercent]),
        LASTDATE('dhcp-scope-utilization'[Date])
    )

High Utilization Scopes =
    CALCULATE(
        COUNTROWS('dhcp-scope-utilization'),
        'dhcp-scope-utilization'[UtilizationPercent] > 80,
        LASTDATE('dhcp-scope-utilization'[Date])
    )

Total IP Addresses = CALCULATE(SUM('dhcp-scope-utilization'[TotalAddresses]), LASTDATE('dhcp-scope-utilization'[Date]))

Used IP Addresses = CALCULATE(SUM('dhcp-scope-utilization'[AddressesUsed]), LASTDATE('dhcp-scope-utilization'[Date]))

// Performance Metrics
Avg CPU Utilization = AVERAGE('network-device-inventory'[CPUUtilization])

High CPU Devices = COUNTROWS(FILTER('network-device-inventory', 'network-device-inventory'[CPUUtilization] > 75))

Avg Memory Utilization = AVERAGE('network-device-inventory'[MemoryUtilization])
```

### Step 4: Build Visualizations

**Page 1: Network Overview**

**Visual 1: DHCP Utilization by VLAN (Gauge Charts - 5 total)**
Create 5 separate gauge visualizations:
- Value: `UtilizationPercent` (filtered by ScopeName)
- Min: 0
- Max: 100
- Target: 80 (warning threshold)
- Title: Each VLAN name (Student-VLAN, Staff-VLAN, etc.)
- Color: Green <70%, Yellow 70-85%, Red >85%

**Visual 2: Device Count by Type (Stacked Bar Chart)**
- Axis: `DeviceType`
- Values: Count of devices
- Legend: `HealthStatus`
- Title: "Network Devices by Type and Health Status"
- Colors: Green (Healthy), Yellow (Warning), Red (Critical)

**Visual 3: Device Distribution by Campus (Clustered Column Chart)**
- X-axis: `Location` (campus)
- Y-axis: Count of devices
- Title: "Device Distribution Across Campuses"
- Data labels: Show counts

**Visual 4: Network Health Summary (Cards - 4 total)**
Create 4 card visualizations:
- **Total Devices:** `Total Devices` measure
- **Healthy %:** `Healthy %` measure (green if >90%)
- **Devices Needing Attention:** `Devices Requiring Attention` measure (red if >10)
- **Avg Uptime:** `Avg Uptime Days` measure

**Visual 5: DHCP Utilization Trend (Line Chart)**
- X-axis: `Date`
- Y-axis: `UtilizationPercent`
- Legend: `ScopeName` (separate line per VLAN)
- Title: "DHCP Scope Utilization Trends (30 Days)"
- Reference line at 80% (capacity planning threshold)

**Visual 6: Critical/Warning Devices Table**
- Columns: `DeviceID`, `DeviceType`, `Location`, `HealthStatus`, `UptimeDays`, `CPUUtilization`
- Filter: `HealthStatus` = "Critical" OR "Warning"
- Title: "Devices Requiring Immediate Attention"
- Conditional formatting: Red for Critical, Yellow for Warning
- Sort: HealthStatus (Critical first)

**Visual 7: Firmware Version Distribution (Donut Chart)**
- Legend: `FirmwareVersion`
- Values: Count of devices
- Title: "Firmware Version Distribution"
- Purpose: Identify outdated firmware

**Visual 8: Device Performance Metrics (Clustered Column Chart)**
- X-axis: `DeviceType`
- Y-axis: `Avg CPU Utilization`, `Avg Memory Utilization`
- Title: "Average Resource Utilization by Device Type"
- Reference line at 75% (high utilization threshold)

**Page 2: Campus Detail View (Optional)**

**Visual 9: Campus Map or Table**
- Rows: `Location`
- Values:
  - Device Count
  - Healthy %
  - Avg CPU Utilization
  - Critical Device Count
- Title: "Campus-by-Campus Infrastructure Health"

**Visual 10: Access Point Heatmap**
- Matrix visual showing AP distribution and health by campus
- Rows: `Location`
- Columns: `HealthStatus`
- Values: Count of Access Points
- Title: "Wireless Infrastructure Coverage"

### Step 5: Add Interactivity

1. **Campus Filter (Slicer):** Allow filtering by location
2. **Device Type Filter:** Focus on specific device categories
3. **Health Status Filter:** Show only Critical/Warning devices
4. **Date Range Slicer:** For DHCP utilization trends
5. **Drill-Through:** Click device type to see individual devices
6. **Cross-Filtering:** Clicking campus filters all visuals

### Step 6: Format Dashboard

**Color Scheme:**
- **Health Status:**
  - Green: Healthy (#28a745)
  - Yellow: Warning (#ffc107)
  - Red: Critical (#dc3545)
- **VLANs:** Use distinct colors for easy identification
- **Background:** Professional dark or light theme

**Layout Best Practices:**
- Group DHCP gauges together (top row)
- Health summary cards below gauges
- Device inventory visuals in middle section
- Detail tables at bottom

**Title Section:**
```
Network Infrastructure Monitoring
Keller ISD | 4 Campuses | 439 Devices | 5 VLANs
Last Updated: [Dynamic Date]
```

### Step 7: Add Annotations and Context

**Text Box - VLAN Purpose:**
```
VLAN Segmentation Strategy:
• Student-VLAN: Student-owned devices (BYOD program)
• Staff-VLAN: Teacher and staff workstations
• Admin-VLAN: Administrative systems and servers
• IoT-VLAN: Cameras, printers, building automation
• Guest-VLAN: Visitor network (isolated, internet-only)
```

**Text Box - Capacity Planning:**
```
DHCP Thresholds:
• Green (<70%): Healthy capacity
• Yellow (70-85%): Monitor closely
• Red (>85%): Plan scope expansion

Target: Maintain <80% utilization for growth headroom
```

### Step 8: Save and Export

1. Save as: `Network-Infrastructure-Dashboard.pbix`
2. Export to PDF for documentation
3. Capture screenshots for GitHub README
4. Test mobile layout

---

## 📈 Key Insights to Highlight

When presenting this dashboard:

1. **Capacity Planning:**
   - "The Student-VLAN runs at 65% utilization - we have headroom for 35% enrollment growth before needing expansion"
   - "Admin-VLAN is at 75% - we should plan scope expansion within 6 months"

2. **Infrastructure Health:**
   - "92% of devices are healthy status - 3 critical devices require immediate attention"
   - "439 network devices across 4 campuses - all monitored from a single dashboard"

3. **Proactive Maintenance:**
   - "31 devices showing warning status - scheduled maintenance can prevent outages"
   - "Firmware version tracking shows 15% of devices need updates"

4. **CIPA Compliance:**
   - "Segmented VLANs ensure student internet traffic is isolated and filtered per CIPA requirements"
   - "Guest VLAN prevents visitor devices from accessing student/staff resources"

---

## 🔗 Connection to K12-Network-Architecture Documentation

This dashboard visualizes the network architecture documented in:
`/K12-Network-Architecture/KISD-Network-Segmentation.md`

**Alignment:**
- 5-tier VLAN design (documented) → DHCP scopes (monitored in dashboard)
- Network security controls (documented) → Device health status (tracked in dashboard)
- CIPA compliance architecture (documented) → VLAN utilization (measured in dashboard)

**PowerShell Integration Opportunity:**
The `VLAN-Configuration-Template.ps1` script could be extended to export DHCP scope data that feeds this dashboard.

---

## 🎯 Strategic Value for Keller ISD

**For Sean Ducar (Technology Systems):**
- Real-time infrastructure health visibility
- Proactive issue identification before outages
- Capacity planning data for budget justification

**For Darian Nealy (Network Infrastructure):**
- DHCP scope management across all campuses
- Device inventory and firmware tracking
- Performance monitoring and optimization

**For Rhonda Dominguez (Executive Director):**
- Infrastructure investment ROI visualization
- Capacity planning for enrollment growth
- Technology refresh cycle planning

---

## 💡 Interview Talking Points

**If asked about network monitoring:**

1. **Problem:**
   "Network teams often lack centralized visibility into DHCP utilization and device health across multiple campuses."

2. **Solution:**
   "This Power BI dashboard aggregates network data to provide real-time monitoring and capacity planning insights."

3. **K-12 Specific:**
   "The VLAN segmentation aligns with CIPA compliance requirements - student traffic is isolated and filtered per federal regulations."

4. **Automation Potential:**
   "The PowerShell scripts can be extended to automatically collect DHCP scope data from Windows DHCP servers or network devices via API."

5. **Operational Value:**
   "Instead of manually checking each DHCP scope, the dashboard shows all 5 VLANs at a glance with color-coded alerts."

---

## 📊 Sample Data Highlights

The generated sample data includes:

**Device Health Distribution:**
- Healthy: 405 devices (92%)
- Warning: 31 devices (7%)
- Critical: 3 devices (1%)

**DHCP Utilization Patterns:**
- Student-VLAN: 65% (weekday), 20% (weekend) - reflects student presence
- Staff-VLAN: 25% (average) - smaller user base
- Admin-VLAN: 75% (high but stable) - servers and systems
- IoT-VLAN: 35% (steady) - always-on devices
- Guest-VLAN: 15% (variable) - visitor traffic

**Campus Distribution:**
- Main Campus: ~40% of devices (largest location)
- North/South/East: ~20% each (balanced distribution)

This creates a realistic representation of a well-designed, multi-campus K-12 network infrastructure.

---

**Created by:** Bryan Shaw
**Purpose:** Keller ISD Senior Systems Engineer Portfolio
**Connects to:** K12-Network-Architecture documentation
**Last Updated:** February 15, 2026
