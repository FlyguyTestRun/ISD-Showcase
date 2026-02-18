# Microsoft Cloud Operations (Practical Scripts)

This folder provides concise, interview-friendly examples of cloud operations scripting aligned with Microsoft systems responsibilities.

## Scripts

### `Get-EntraRiskSummary.ps1`
- Summarizes high-level identity risk signals from Entra sign-in/risk events.
- Designed for weekly security operations review.

### `Get-IntuneComplianceSnapshot.ps1`
- Produces a compliance snapshot (compliant/non-compliant/unknown) for endpoint governance reporting.
- Supports endpoint posture trend tracking.

### `Get-M365ServiceHealthSnapshot.ps1`
- Captures active service health incidents/advisories from Microsoft 365.
- Useful for daily operations briefings and incident communication.

## Output Pattern

Each script outputs an object and can export CSV/JSON for:
- dashboard ingestion,
- operational runbooks,
- leadership status updates.

## Notes

- Scripts use Microsoft Graph/M365 admin cmdlets where applicable.
- Parameters are included for safe demo mode and report export paths.
- These examples are designed for portfolio demonstration and should be adapted for production auth/secrets handling.
