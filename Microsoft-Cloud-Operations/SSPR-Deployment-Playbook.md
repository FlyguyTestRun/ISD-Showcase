# SSPR Deployment Playbook

## Self-Service Password Reset, Microsoft Entra ID

This playbook covers the Entra ID SSPR configuration, Conditional Access guardrails, phased rollout sequence, and help desk impact measurement for a K-12 district deployment.

Password resets are the single highest-volume category at most K-12 IT help desks. When staff and students can reset their own passwords at the login screen, the Monday morning password ticket flood drops by 60-80% within 60 days of full rollout. The Entra ID configuration for SSPR is straightforward; the operational discipline that makes it successful is the sequencing.

---

## Prerequisites

- M365 A5 for Education tenant (SSPR included; no additional licensing required)
- Users registered for at least one authentication method (Microsoft Authenticator app, phone, or email OTP)
- Conditional Access policy in place before rollout begins (not after)
- Intune compliance policies confirmed functional (needed for device-based CA guardrails)

---

## Phase 1: Configuration (Entra ID Admin Center)

### Authentication Methods

**Staff accounts:**
- Enable: Microsoft Authenticator app, phone call, email OTP (to non-district email as fallback)
- Require: 2 methods to reset
- Rationale: Staff accounts have broader access to district data; stronger verification is appropriate

**Student accounts (grades 9-12):**
- Enable: Microsoft Authenticator app, email OTP (to district-issued student email)
- Require: 2 methods
- Disable phone call for students: avoids carrier fees on personal phones and parent billing concerns

**Student accounts (K-8):**
- Evaluate based on grade level and parent consent workflow
- Authenticator app without phone call is the safest default for younger grades
- K-5 may require help desk or campus tech intervention rather than self-service reset

### SSPR Scope (Entra ID > Password Reset > Properties)

Start with a pilot group, not all users:

```
Enabled for: Selected
Initial pilot group: IT-Staff-SSPR-Pilot (create this security group)
```

Do not enable for all users until pilot data confirms the configuration is stable.

### Registration Requirements

- Enable combined registration: users register for MFA and SSPR in one workflow
- Require registration at next sign-in for the pilot group: Yes
- Registration deadline: set a 14-day window before SSPR goes live for the pilot group
- Monitor registration completion before expanding scope

---

## Phase 2: Conditional Access Guardrails

SSPR must be protected by Conditional Access before rollout. Configure these policies before enabling SSPR for any user group.

### Policy: Block SSPR from High-Risk Sign-In Events

```
Policy name: SSPR-Block-High-Risk
Users: All
Cloud apps: Microsoft Authentication Library (covers SSPR flows)
Conditions: Sign-in risk = High
Grant: Block access
```

### Policy: Require Compliant Device for Staff SSPR

```
Policy name: SSPR-Staff-Require-Compliant-Device
Users: All staff security groups
Cloud apps: Microsoft Authentication Library
Conditions: Device compliance = Not compliant
Grant: Block access
```

This policy prevents a compromised or non-enrolled staff device from being used to reset the account on that device. Student accounts are typically excluded from device compliance requirements for SSPR since the reset scenario often involves a device the student cannot log into.

---

## Phase 3: Phased Rollout Sequence

| Phase | Group | Target Window | Completion Criteria |
|-------|-------|--------------|---------------------|
| 1. Pilot | IT staff + 50-person staff test group | Week 1 | All pilot users registered; no support escalations in 14 days |
| 2. All Staff | Teachers, administrators, support staff | Week 3 | Over 90% registration rate; password ticket volume trending down |
| 3. Students 9-12 | High school students (grades 9-12) | Week 6 | Pilot data reviewed; campus tech staff briefed on change before rollout |
| 4. Students K-8 | Elementary and middle school students | Week 10+ | Evaluate based on prior phase data; K-5 may remain help desk-assisted |

**Do not compress the timeline.** The 14-day pilot window before expanding to all staff exists to catch configuration issues before they affect 5,000 staff accounts. A configuration error discovered at the pilot stage is a 5-minute fix. The same error discovered after full deployment is a triage incident.

**High-risk calendar periods to avoid:**
- Do not begin rollout in August (first day of school pressure)
- Do not expand scope during STAAR testing windows
- Spring semester start (January) is a secondary risk window; avoid expanding scope the first two weeks

---

## Phase 4: Help Desk Impact Measurement

### Baseline (collect before rollout begins)

Pull from the ITSM system for the 30 days before rollout:
- Total password reset tickets opened
- Tickets opened on Monday (post-weekend lockout volume)
- Tickets opened the first Monday after each school break
- Average handle time for a password reset ticket (time from open to close)

### Post-Rollout Metrics (measure at 30 and 60 days after each phase)

- Password reset ticket volume (target: 60-80% reduction for covered user groups)
- SSPR self-service usage count (Entra ID > Monitoring > Audit Logs > SSPR activity)
- SSPR method failure rate by method (flags users who need re-registration coaching)
- SSPR-related support tickets as new category (should be near zero if rollout was smooth)

### Reporting Format

Monthly password reset ticket volume, before and after SSPR rollout by user group. The comparison tells the clearest story for technology leadership: hours recovered per week at the help desk, tickets eliminated per month, and which user groups are still calling in (indicating registration completion gaps or method issues).

---

## Troubleshooting Reference

**Issue:** User cannot reset because they have no registered methods
- Check: Entra ID > Users > [user] > Authentication methods
- Fix: Help desk walks user through registration, or push a registration requirement nudge via Conditional Access

**Issue:** SSPR active for some staff but not others in the same group
- Check: SSPR scope group membership in Entra ID
- Check: Conditional Access policy target group includes all affected accounts
- Check: Whether affected accounts are in a hybrid sync exclusion or staged rollout exclusion list

**Issue:** Student reports no SSPR option on Windows login screen
- Verify: Device is Entra-joined (not just registered; SSPR credential provider requires Entra join)
- Verify: Windows 10/11 Credential Provider policy is pushed via Intune to the device
- Verify: Student account is in the SSPR-enabled scope group

**Issue:** SSPR registration completion rate below 80% after 14 days
- Check: Registration requirement nudge is active for the scope group
- Check: Authenticator app availability on student personal devices (may need alternate method)
- Action: Targeted outreach via campus tech coordinators; do not expand rollout scope until registration rate is above 85%

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com
