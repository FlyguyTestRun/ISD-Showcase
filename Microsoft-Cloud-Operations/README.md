# Microsoft Cloud Operations

Day-to-day operational scripts for a district running M365 A5, Entra ID at full scale, and 23,000 Intune-managed Windows 11 devices. These are the checks that run on a schedule — not one-time setup tasks.

---

## Scripts

### `Get-EntraRiskSummary.ps1`
Pulls high-risk and medium-risk sign-in events and identity risk detections from Entra ID Protection. Designed for a weekly security operations review or to feed a Power BI risk dashboard.

At 34,000+ accounts, identity risk signals surface daily. This script filters for actionable items — accounts flagged as high-risk that need remediation or Conditional Access block review.

### `Get-IntuneComplianceSnapshot.ps1`
Produces a compliance snapshot across all enrolled devices: compliant, non-compliant, unknown, and not evaluated. Outputs a CSV for trend tracking.

At 23,000 managed Windows 11 devices, even a 1% non-compliance rate means 230 endpoints out of policy. This script is the input for the daily compliance check and the trigger for remediation workflows.

### `Get-M365ServiceHealthSnapshot.ps1`
Captures active service health incidents and advisories from Microsoft 365. Useful for the morning operations check and for communicating to staff before a degraded service becomes a flood of help desk tickets.

Canvas LMS authenticates via Entra ID SSO — an Exchange Online or Entra incident can affect Canvas availability. This script catches it before teachers report it.

### `Get-AutopilotProvisioningStatus.ps1`
*(New addition — KISD-relevant post-deployment)*
Tracks Autopilot deployment success rate for recent device enrollments. Surfaces devices that enrolled but failed to complete provisioning, devices waiting for Autopilot profile assignment, and new student accounts without a linked device.

After a large Autopilot deployment (23,000 devices), the ongoing work is ensuring new devices enroll cleanly — staff refreshes, device replacements, additions from bond-funded purchases. This script catches provisioning failures before the student or teacher reports a bare device.

---

## Output Pattern

Each script outputs a structured object and accepts export parameters:
- `-ExportCSV` — writes to a file path for dashboard ingestion
- `-ExportJSON` — for integration with monitoring tools
- Default output: formatted console table for quick review

---

## Notes

- Scripts use Microsoft Graph API and M365 admin cmdlets
- Auth handled via service principal or delegated credentials (not embedded)
- Demo mode parameter available for safe portfolio demonstration without live tenant
- Adapt connection handling for your specific auth method before production use
