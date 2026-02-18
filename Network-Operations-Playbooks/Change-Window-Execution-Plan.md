# Network Change Window Execution Plan

## Change Overview
- Change ID:
- Scope:
- Planned date/time:
- Maintenance window:
- Risk level:

## Pre-Change Checks
- [ ] Configuration backup completed
- [ ] Dependencies validated (firewall, DHCP, DNS, WAN)
- [ ] Stakeholder communication sent
- [ ] Rollback plan reviewed
- [ ] Monitoring dashboards open and baseline captured

## Execution Steps
1. Document baseline metrics (latency, packet loss, availability)
2. Apply approved configuration set
3. Validate reachability and routing
4. Validate campus critical services (SIS, LMS, internet filtering)
5. Record outcomes and anomalies

## Rollback Criteria
- Trigger thresholds (e.g., >2% packet loss, core service outage >10 min)
- Rollback command sequence:
- Communications during rollback:

## Post-Change Validation
- [ ] Service health checks passed
- [ ] No unexpected security policy denials
- [ ] Monitoring trend stabilized for 60 minutes
- [ ] Change record updated with evidence
