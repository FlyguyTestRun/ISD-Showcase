# Operational KPIs (Systems + Network)

Practical KPI datasets and generation script for operations dashboards and leadership reporting. Targets are calibrated to a large K-12 district operating a post-migration Microsoft stack: M365 A5, Intune-managed Windows 11 devices, Entra ID at full district scale, Canvas LMS.

## KPI Datasets

- `incident-trends.csv`: incident volume, MTTR, and priority distribution by week
- `change-success-rate.csv`: scheduled vs. successful changes, rollback events, success rate
- `backup-sla-attainment.csv`: backup completion rate, failed jobs, SLA attainment trend
- `network-availability.csv`: campus availability, latency, packet loss, outage minutes

## Data Generation

```powershell
./Generate-OperationalKPIData.ps1
```

Outputs synthetic data to `sample-data/` at district-approximate scale.

## KPI Targets

**Infrastructure Operations**
- Change Success Rate: >= 95%
- Backup SLA Attainment: >= 98%
- Campus Network Availability: >= 99.5%
- P1 Incident MTTR: <= 60 minutes

**Intune / Device Fleet (23,000 endpoints)**
- Device Compliance Rate: >= 95% of managed fleet
- Autopilot Provisioning Success Rate: >= 99%
- Devices Not Seen >7 Days: <= 0.5% of fleet (triggers review)
- OS Update Compliance (Windows 11 supported build): >= 98%

**Entra ID / Identity**
- AD Connect Sync Errors: 0 (any sustained error triggers alert)
- Stale Account Rate: <= 1% of total accounts during active school year
- MFA Registration Rate (staff): 100% target
- Password Expiration Alerts Delivered: 100% of expiring accounts notified 7 days out

**M365 A5 / Security**
- Conditional Access Coverage: 100% of staff, 100% of managed student devices
- Defender for Endpoint Sensor Coverage: >= 99% of enrolled devices
- M365 Service Health P1 Response: <= 15 minutes (per Microsoft SLA)

**Canvas + Microsoft Integration**
- Canvas SSO Authentication Failures: <= 2/day before escalation review
- School Data Sync (SDS) roster update success: >= 99% per sync cycle

## Reporting Cadence

- **Daily:** Backup job review, device compliance drift check, Entra sync health
- **Weekly:** Incident MTTR review, change success summary, Intune non-compliance trend
- **Monthly:** Backup SLA report, license consumption review, Conditional Access audit
- **Quarterly:** DR test result, stale account cleanup, policy review cycle
