# Mentoring & Enablement Case Studies

## Case Study 1: Identity Automation Onboarding

**Situation:** Support needs for student account provisioning during enrollment surge.

**Approach:** Paired walkthrough of `K12-Identity-Management/`, then guided execution using `sample-students.csv` and batch script workflow.

**Mentoring Focus:** Naming conventions, OU placement logic, audit logging expectations, safe validation before execution.

**Outcome:** On the first run, nearly executed the batch script against the production OU, the confusion was test environment requirements not correctly sequenced. The pre-run validation check caught the mismatch before any accounts were created. From that point, confirming target OU and domain before any write operation became a required checkpoint in every provisioning run. The subsequent execution batch onboarded independently and documented exceptions for review.

---

## Case Study 2: Cross-Team Backup/DR Readiness Coaching

**Situation:** Support staff needed better understanding of backup failures vs. true DR risk.

**Approach:** Used backup runbooks and architecture docs to demonstrate the difference between job failure triage, SLA tracking, and full recovery validation.

**Mentoring Focus:** Escalation triggers, evidence capture, and post-incident communication structure.

**Outcome:** After coaching, the team stopped submitting tickets that just said "backup failed." Every escalation began to include the job name, last successful backup timestamp, and data size transferred, the three data points needed to immediately assess severity. This cut the back-and-forth that had been adding time between escalation and incident response.

---

## Case Study 3: Network Change Confidence Building (CoreSkills)

**Situation:** CoreSkills technicians and analysts (mid-size company IT staff skill building) were hesitant to execute network changes due to rollback uncertainty. CoreSkills operated as a trainer-to-trainers program, developing analysts in KPI pipeline automation, Python-based data workflows, and infrastructure operations. Integrating Grafana dashboards into metrics and KPI reports. 

**Approach:** Introduced a change-window checklist and RCA template, then rehearsed a low-risk change in controlled sequence. For network confidence specifically, the session focused on firewall rule additions (allow/deny) as the execution scenario.

**Mentoring Focus:** Pre-change state capture, explicit rollback criteria, and post-change verification discipline.

**Outcome:** The CoreSkills technician executed a firewall allow/deny rule addition in full sequence: pre-change state documented, rule applied, connectivity verified against the baseline. The discipline of "evidence before and after every change" became a repeatable habit that carried directly into their production environments.

---

## Mentoring Principles Demonstrated

- Teach *why* behind runbook steps, not only *how*
- Use repeatable templates to reduce decision fatigue under pressure
- Build confidence through staged execution and clear rollback paths
- Emphasize documentation quality as a force multiplier for the team
