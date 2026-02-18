# Operational KPIs (Systems + Network)

This folder contains practical KPI datasets and a generation script intended to support operations dashboards, reporting cadence, and leadership visibility.

## Included KPI Datasets

- `incident-trends.csv`
  - Tracks incident volume, MTTR, and priority distribution by week.
- `change-success-rate.csv`
  - Tracks scheduled vs successful changes, rollback events, and change success %.
- `backup-sla-attainment.csv`
  - Tracks backup completion %, failed jobs, and SLA attainment trend.
- `network-availability.csv`
  - Tracks campus availability %, latency, packet loss, and outage minutes.

## Data Generation

Use:
```powershell
./Generate-OperationalKPIData.ps1
```

Outputs are written to `sample-data/` with safe, synthetic data.

## Example Reporting Uses

### Systems Operations
- Weekly service health report
- Monthly change-quality review
- Backup compliance and DR readiness review

### Network Operations
- Campus uptime trend review
- Latency/packet-loss threshold watch
- MTTR trend and escalation effectiveness

## Recommended KPI Targets (Demo Baseline)

- Change Success Rate: **>= 95%**
- Backup SLA Attainment: **>= 98%**
- Campus Availability: **>= 99.5%**
- P1 Incident MTTR: **<= 60 minutes**

## Suggested Visualization Layout

- **Top row cards:** Change success %, backup SLA %, average availability, MTTR
- **Middle row trends:** weekly incidents, change outcomes, backup trend, availability trend
- **Bottom table:** exception list (failed changes, SLA misses, high-latency campuses)
