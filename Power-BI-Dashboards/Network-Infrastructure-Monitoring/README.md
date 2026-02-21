# Network Infrastructure Monitoring Dashboard

[View Dashboard PDF](./Network-Infrastructure-Dashboard.pdf)

**Purpose:** Multi-campus network health visibility, DHCP utilization, device inventory, connectivity, and workload-aware capacity planning.

**Mock data profile:** 51 square miles, 40+ campuses and facilities, multi-VLAN segmented infrastructure.

---

## What It Tracks

**DHCP Scope Utilization by VLAN**
- Student VLAN (10.10.x.x): ~18,000 active leases, 23,000 device capacity
- Staff VLAN (10.20.x.x): ~4,500 active leases
- Admin/Server VLAN (10.30.x.x): static reservations, scope health monitored
- IoT VLAN (10.40.x.x): cameras, HVAC, smart devices, isolated, inventory tracked
- Guest VLAN (10.50.x.x): captive portal, bandwidth-throttled, 4-hour lease timeout

**Network Device Inventory, 40+ Campuses**
- ~850 access points across district (up from prior Chromebook era, Windows devices require better signal density)
- ~220 access switches, ~18 core/distribution switches
- Device health status: healthy / warning / critical, with campus drill-down
- Firmware version compliance, devices not on current approved version flagged

**Campus Connectivity**
- WAN link utilization by campus, usage spikes during Canvas LMS test/assessment windows
- Packet loss and latency trending by site
- Bandwidth demand correlation to instructional calendar (state testing weeks, enrollment weeks)

**CIPA Compliance Visibility**
- Student VLAN: content filtering active (Cisco Umbrella / Lightspeed Relay)
- SafeSearch enforcement status across student segments
- Guest isolation confirmed: no lateral access to staff or admin VLANs

**Forward-Looking: What Comes Next**
- Canvas LMS traffic profiling, identify bandwidth saturation during peak assessment windows and plan capacity proactively
- 802.1X coverage audit, Surface devices support 802.1X; verify all campus segments enforce certificate-based auth
- Wireless density review for Windows 11 devices vs. prior Chromebook fleet (different roaming behavior)
- IoT VLAN expansion planning, additional smart campus devices as bond projects complete
- Zero Trust network segmentation review post-migration: confirm no legacy trust paths remain

---

## Data Sources (Mock, District-Scale)

- `dhcp-scope-utilization.csv`: all scopes, daily snapshot by campus and VLAN
- `network-device-inventory.csv`: ~1,100 network devices, health and firmware state

---

**Created by:** Bryan Shaw
**Last Updated:** February 2026
