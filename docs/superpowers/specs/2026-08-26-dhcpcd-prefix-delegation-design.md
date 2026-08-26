# dhcpcd Prefix Delegation Design

## Goal
Replace WIDE DHCPv6 client management with dhcpcd across the STSBL IPv6 stack while preserving existing ifupdown configurations and making dhcpy6d use delegated global prefixes dynamically.

## Scope
The coordinated change affects `stsbl-iserv-config-ipv6`, dhcpy6d based on `upstream/config-prefix-substitution`, and `stsbl-iserv-server-dhcpy6d`.

## Client migration
`stsbl-iserv-config-ipv6` will replace its WIDE dependency, generated defaults, `dhcp6c.conf`, hook scripts, service, wait unit, and WIDE-specific checks with `dhcpcd` and a generated `/etc/dhcpcd.conf`.

The generated configuration uses pve00's proven form: global `duid`, `noipv6rs`, `waitip 6`, `ipv6only`, DNS/domain options, `rapid_commit`, and `slaac token ::2`; the upstream interface gets `ipv6rs`, an optional `ia_na 1`, and `ia_pd 1/::/<delegated-length>`. Each delegation interface is appended as `<interface>/<sla-id>/64`.

Canonical ifupdown modes are `dhcpcd` and `dhcpcd-delegation`; new dhcpcd-named interface options replace `wide-dhcpv6-*`. Legacy `widedhcp`, `delg`, and `wide-dhcpv6-*` remain read-compatible. Saving a configuration writes canonical dhcpcd names. Migration preserves persisted SLA length, SLA ID, IA_NA request, and existing interface lists.

The old PPP/ifupdown WIDE restart paths become dhcpcd restarts. pve00's existing `ip-up.d/iserv` already restarts dhcpcd, so config-ipv6 must avoid duplicate competing restart behavior while retaining the delayed accept_ra retry for PPP interfaces.

## dhcpy6d dynamic prefix and option expansion
The packaged dhcpy6d hook and systemd environment drop-in remain opt-in via `ENABLE_DYNAMIC_PREFIX_FROM_DHCPCD=yes`. On dhcpcd BOUND6, RENEW6, or REBIND6 of IA_PD 1, the hook derives the delegated prefix stem, writes it atomically to the environment file, and restarts dhcpy6d only when it changed.

`$prefix$` expansion becomes a central configuration normalization step before validation and DHCP option encoding. It applies to global and class-scoped server address, nameserver, NTP server, and SNTP server values. Address-pool and delegated-prefix patterns continue using their existing runtime expansion. Non-address NTP FQDN values remain untouched.

## Generated server configuration
For interfaces in the delegated dhcpcd set, `stsbl-iserv-server-dhcpy6d` derives each global /64's SLA suffix and emits `$prefix$<suffix>` in address-pool patterns and advertised server/NTP addresses. ULA values remain literal. Static non-delegated global prefixes remain literal.

`stsbl-iserv-server-dhcpy6d` declares a dependency on the released dhcpy6d package version that contains the dhcpcd hook and expanded option handling.

## Tests and validation
- Tests use documentation-only IPv6 ranges.
- dhcpy6d tests verify global/class nameserver, NTP, SNTP, and server address expansion; no expansion of FQDNs; pool behavior remains intact.
- config-ipv6 tests verify dhcpcd configuration generation for IA_NA, IA_PD, SLA mappings, legacy aliases, and PPP restart integration.
- server-dhcpy6d tests verify delegated global output is `$prefix$`-based and ULA/static values remain literal.
- Package builds and applicable project test suites must pass.
