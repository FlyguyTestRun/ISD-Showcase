# First 90 Days

**Role:** Senior Systems Engineer, K-12 Infrastructure
**Author:** Bryan Shaw

This is how I think about onboarding into a production environment. Not a list of changes to make, but a structure for building situational awareness, earning standing, and making the first contribution land well.

The K-12 calendar shapes every decision. Starting in August means walking into the highest-stakes operational period of the year. Starting in spring means a runway before the August surge. Either way, the approach below treats the school calendar as a hard constraint, not background context.

---

## Days 1-14: Inventory and Awareness

No changes. No proposals. Read everything that exists.

**Infrastructure inventory:**
- Map the AD topology: domain controllers, site links, replication health, FSMO role placement
- Document Entra ID Connect sync scope, schedule, and connector health status
- Review Intune tenant: policy assignments, compliance baselines, Autopilot deployment profiles
- Audit Veeam: every job, last successful backup timestamp, repository capacity, any silently failing jobs
- Review iDRAC firmware versions on all PowerEdge hardware
- Check the Canvas enterprise app in Entra ID: SAML attribute mapping, certificate expiry, Conditional Access coverage

**Documentation review:**
- Read every runbook and procedure that exists, noting gaps
- Review the last 90 days of help desk escalations: what is IT touching repeatedly that automation could eliminate?
- Read the most recent Veeam DR test report; if none exists, flag it

**Relationship inventory:**
- Meet with each stakeholder once; ask more than propose
- Understand what broke in the last 12 months that made the team nervous
- Learn the school calendar in detail: first day, last day, STAAR testing windows, break periods
- Understand the change window schedule and who owns change approval

**Deliverable:** An inventory document. Not a proposal. A documented picture of what is running, where the risks are, and what questions still need answers.

---

## Days 15-30: Stabilize Known Gaps

Address what the inventory revealed. No new projects. Fix what is already broken or at risk.

Likely candidates at district scale:
- Silent backup failures: jobs that completed but produced restore points that have not been validated
- Identity mismatches: AD accounts not reflecting current SIS state (stale accounts, incorrect OU placement)
- Intune compliance drift: devices that fell out of policy without triggering an alert
- Expiring certificates: Entra ID enterprise app certs (Canvas SAML, ADFS if applicable)
- Autopilot profile gaps: device categories not covered by a profile, or profiles pointing at wrong groups

**Approach:** Each fix follows the same sequence. Document the current state. Apply the change in a defined window. Verify the outcome. Write up what changed. No silent repairs.

**What does not happen in this window:** New deployments. SSPR rollout. Major GPO changes. Any work requiring a project approval cycle is scoped and queued, not started.

---

## Month 2: First Automation Win

One well-executed improvement. Not a project backlog. One.

**Best candidate: SSPR pilot rollout (staff)**

Self-service password reset is the highest-ROI project at any district. When staff can reset their own passwords at the Windows login screen, the Monday morning password ticket flood drops by 50-80% depending on current call volume. The Entra ID Conditional Access guardrails are well-established. The rollout risk is low when sequenced correctly.

Rollout sequence:
1. Pilot group: IT staff + a small staff test group, 30-day observation window
2. All staff: after pilot data confirms stability and method success rates
3. Students grades 9-12: after full-staff rollout, with campus tech staff briefed on the change
4. Students K-8: evaluate based on data from prior phases

**Month 2 deliverable:** SSPR active for IT staff and pilot group. 30-day observation data in hand. Rollout plan presented for leadership review. See [SSPR-Deployment-Playbook.md](./Microsoft-Cloud-Operations/SSPR-Deployment-Playbook.md) for the full configuration and measurement framework.

---

## Month 3: One Infrastructure Improvement with Full Change Management

An infrastructure change proposed in month 2, scheduled and executed in month 3.

Likely candidates depending on what the inventory revealed:
- Automating nightly SDS sync validation (surface Canvas roster failures before teachers report them)
- Deploying the daily Veeam backup report to IT leadership (scheduled visibility into backup health)
- Extending Intune compliance policies to cover a gap found in the inventory
- Autopilot profile consolidation if profiles have drifted from the defined standard

**What makes this different from a month 1 fix:** This is not emergency stabilization. It is a scoped proposal, reviewed by the appropriate stakeholders, executed in a defined change window, documented in a change record, and verified against success criteria. The process is as important as the outcome. A new engineer who demonstrates change discipline in the first 90 days earns standing to propose larger changes later.

---

## How the Calendar Changes the Timeline

**Starting in August:**
- Weeks 1-2 overlap with the highest-intensity operational period of the year: enrollment processing, Autopilot deployments, first-day authentication load, device distribution
- Inventory and awareness work runs alongside active operational support
- Month 2 and 3 work shifts to November or December; no changes during September STAAR prep windows

**Starting in spring (February-May):**
- The runway before August is the time to stabilize and build
- SSPR rollout can complete before summer break
- Month 3 infrastructure work can be scoped and ready to execute during summer break

**Starting in summer:**
- Summer break is the best change window in the K-12 calendar
- Month 1 and 2 compress into pre-August preparation
- Month 3 improvement executes before the first day of school, with full verification before students arrive

---

**Author:** Bryan Shaw
**Contact:** BryanJShaw@gmail.com

**Note:** All scenarios described here are based on KISD-approximate operating environment (34,000 students, 23,000 managed devices, M365 A5, Canvas LMS). Actual first 90 days would adapt to the specific environment and priorities established with Sean Ducar.
