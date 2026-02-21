# IT Infrastructure Health Dashboard

[View Dashboard PDF](./IT-Infrastructure-Dashboard.pdf)

**Purpose:** Daily operational visibility into identity health, device compliance, backup status, and endpoint security at large-district scale.

**Mock data profile:** 34,000 students, 4,500 staff, 23,000 managed Windows 11 devices (Surface, grades 5-12).

---

## What It Tracks

**Entra ID Account Health**
- Total accounts: ~38,500 (students + staff)
- Sync status and last sync timestamp from AD Connect
- Stale accounts: no login in >30 days during active school year
- Password expiration queue: accounts expiring within 14 days by role group

**Intune Device Compliance, 23,000 Endpoints**
- Compliance rate by policy: Windows 11 version, Defender status, BitLocker, OS minimum
- Non-compliant device count and 30-day trend line, alert threshold: >2% drift triggers review
- Autopilot provisioning success rate for new device enrollments
- Devices not seen in >7 days (loss, reimage, or Autopilot re-enrollment candidates)

**Backup Job Status**
- SIS database: nightly, 14-day retention, any failure flags next-morning triage
- File servers: nightly, 30-day retention
- Domain controllers: nightly, 7-day retention
- Failed job count with trend: 3-day rolling window

**M365 A5 Security & Compliance Posture**
- Defender for Endpoint sensor coverage across managed device fleet
- Conditional Access enforcement rate: staff (MFA required) and student devices
- MFA registration rate by group: staff target 100%, student target per policy

**Forward-Looking: What Comes Next for a District at This Stage**
- Autopilot profile expansion, new device categories (staff refreshes, shared lab devices)
- Conditional Access gap analysis: any unmanaged personal devices accessing district resources
- Canvas LMS authentication health, SSO token failures, sync errors with Entra ID
- M365 A5 license consumption tracking, E5 compliance seats, unused license recapture
- Windows 11 feature update compliance, keeping 23K endpoints on supported builds

---

## Data Sources (Mock, District-Scale)

- `active-directory-health.csv`: 38,500 account records, daily snapshot
- `backup-job-status.csv`: all backup job results, 90-day history
- `endpoint-compliance.csv`: 23,000 device records, Intune compliance state

---

**Created by:** Bryan Shaw
**Last Updated:** February 2026
