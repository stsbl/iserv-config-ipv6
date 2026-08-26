# dhcpcd Prefix Delegation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace WIDE DHCPv6 management with dhcpcd while making dhcpy6d consume delegated prefixes consistently.

**Architecture:** config-ipv6 generates dhcpcd configuration and lifecycle controls; dhcpy6d derives a prefix from IA_PD and normalizes all IPv6 option fields; server-dhcpy6d generates `$prefix$` values for delegated global networks only.

**Tech Stack:** Debian packaging, IServ iconf/iservchk, Perl, POSIX shell, Python unittest, dhcpcd.

**Spec:** `docs/superpowers/specs/2026-08-26-dhcpcd-prefix-delegation-design.md`

## Global Constraints

- Use documentation-only IPv6 ranges in tests.
- Canonical configuration is dhcpcd-named; WIDE mode/option names remain read-compatible.
- dyndnsd is out of scope.
- Do not remove WIDE configuration until equivalent dhcpcd configuration is generated.
- dhcpy6d changes use `/tmp/dhcpy6d-prefix-substitution-base` on `upstream/config-prefix-substitution`.

---

### Task 1: Generate and package dhcpcd configuration

**Files:** `stsbl-iserv-config-ipv6/debian/control`, `debian/*.install`, new `iconf/etc/dhcpcd.conf/{00config-ipv6_head.templ,20config-ipv6_interfaces.pl}`, tests.

- [ ] Write a failing generator test: upstream `wan0`, `/56`, downstream `br100/0/64 br200/24/64` must generate `interface wan0`, `ipv6rs`, and `ia_pd 1/::/56 br100/0/64 br200/24/64`.
- [ ] Run it and confirm failure because the generator is absent.
- [ ] Implement managed global defaults (`duid`, `noipv6rs`, `waitip 6`, `ipv6only`, DNS/domain options, rapid-commit, `slaac token ::2`) and interface-specific IA_NA/IA_PD generation.
- [ ] Replace the WIDE dependency/install artifacts with dhcpcd equivalents; rerun test and commit.

### Task 2: Preserve legacy ifupdown and migrate lifecycle/PPP hooks

**Files:** `share/iservcfg/10network6`, `iservchk/11network/20config-ipv6`, WIDE check fragment replacement, `iconf/etc/network/if-up.d/iserv/{40config-ipv6,60config-ipv6_ppp}`, `iconf/etc/network/if-up.d/zzz_iserv-ipv6/30config-ipv6`, new `iconf/etc/ppp/ip-up.d/iserv/80config-ipv6`, tests.

- [ ] Write failing tests that accept `widedhcp`, `delg`, and `wide-dhcpv6-*`, and expect saved canonical `dhcpcd`, `dhcpcd-delegation`, and `dhcpcd-*` values.
- [ ] Implement alias reads/canonical writes, preserving SLA length, SLA ID, IA_NA request, and interface lists.
- [ ] Replace WIDE `Reload`, `Stop`, `Enable`, and delayed PPP restarts with dhcpcd service commands; remove stale WIDE files only after generation.
- [ ] Add only `systemctl restart dhcpcd.service` to PPP fragment 80; do not add a dyndnsd action.
- [ ] Run fixtures/iservchk output checks and commit.

### Task 3: Package dhcpy6d IA_PD hook

**Files:** dhcpy6d `debian/70-dhcpy6d`, `debian/dhcpy6d-override.conf`, `debian/dhcpy6d.{install,postinst,service}`, `etc/default/dhcpy6d`, hook tests.

- [ ] Write a failing test for `2001:db8:1234:5600::/56` producing `2001:db8:1234:56` and for no restart on an unchanged result.
- [ ] Implement BOUND6/RENEW6/REBIND6 handling, atomic environment update, opt-in default flag, service EnvironmentFile, and sandbox write access.
- [ ] Test disabled/invalid PD clearing behavior, run package build, and commit.

### Task 4: Expand `$prefix$` in IPv6 configuration values

**Files:** dhcpy6d `config.py`, option preparation as needed, `tests/test_prefix_substitution.py`, `doc/dhcpy6d.conf.rst`.

- [ ] Add failing tests for general/class `address`, `nameserver`, `ntp_server`, and `sntp_servers` using `$prefix$18::1`; add an NTP FQDN unchanged test.
- [ ] Implement one normalization helper before IPv6 validation and option dictionaries are built.
- [ ] Verify pool/prefix-pattern tests retain current behavior; update docs and commit.

### Task 5: Generate `$prefix$`-based server pools and advertisements

**Files:** server-dhcpy6d `iconf/etc/dhcpy6d.conf/30server-dhcpy6d_interfaces.pl`, `iconf/etc/default/dhcpy6d/20server-dhcpy6d_general.templ`, `debian/control`, tests.

- [ ] Write failing generator tests: delegated SLA `18` produces `$prefix$18::$eui64$` and `$prefix$18::1`; ULA remains literal.
- [ ] Implement delegated-network detection, SLA suffix rendering, and conditional hook enablement.
- [ ] Bump the dhcpy6d dependency to the released version containing Tasks 3 and 4; run tests and commit.

### Task 6: Verify and build

- [ ] Run dhcpy6d tests without leaking unittest flags into its config parser.
- [ ] Run config-ipv6 and server-dhcpy6d generator tests.
- [ ] Build all Debian packages.
- [ ] Verify pve00-style `/56` mappings for SLA 0/24/25/160 and report final package versions.
