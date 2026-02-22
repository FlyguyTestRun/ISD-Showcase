# Network Monitoring Baseline

This baseline defines a practical minimum for "mock" network operations visibility.

## Core Metrics

### Availability
- Campus availability % (daily/weekly)
- Core services uptime (DNS, DHCP, internet edge)

### Performance
- WAN latency (average, 95th percentile)
- Packet loss %
- WLAN client density by campus/time block

### Reliability
- Incident volume by severity
- MTTR by severity
- Repeat incident count (same root cause)

### Change Quality
- Change success rate
- Rollback count
- Unauthorized change exceptions

## Recommended Alert Thresholds
- Availability < 99.5% (campus)
- Packet loss > 1.5% sustained 10 min
- WAN latency > 60 ms sustained 10 min
- DHCP scope utilization > 85%

## Reporting Cadence
- Daily: NOC/ops summary
- Weekly: engineering review (availability, incidents, change quality)
- Monthly: leadership summary with trend commentary and risk forecast
