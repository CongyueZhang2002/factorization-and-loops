# CF300 V6c parse repair and pre-launch freeze

## Diagnosis

The V6a pool launch failed before evaluation.  The independent Wolfram
diagnostic returned `ParsedHead -> "$Failed"` and `SyntaxLength -> 25502`,
which maps to the exact-channel rebind call.  The source had split a Wolfram
context-qualified symbol across physical lines:

```wl
CodexDirectRootChannelExactOneFormRebindV6`
  DRCARebindExactOneFormChannels[...]
```

Whitespace after the context mark is not valid inside a qualified symbol.
Balanced delimiter checks cannot detect this lexical error.

Frozen V6a evidence:

- driver SHA256: `9465f690d0b46ef31d8c5b5dc378b94becf677cd2036155e80a98522db62bc29`
- failed full-launch log SHA256: `7bd86c0443f0cd433e6c26dc4bac087f84716f730f33e30b67011a369e00dc15`

The first V6b parser diagnostic raced the source freeze and read the
pre-repair copy at 12:08:18; the V6b path was frozen only at 12:08:33.  Its
parser log SHA256 is
`515b0e321dc207f4a1df3e493bfafe95d73068918ad17ae65bc8dffd093948ba`.
The now-frozen V6b source SHA256 is
`225f0e96627b37259da27af21067f1a742f9f74389b8ab714ea6f88d3250ac3c`.
V6b is superseded and must not be launched.

## V6c repair

V6c keeps the exact-channel/Galois-certificate design unchanged.  The sole
semantic repair is that the qualified exact-rebind name is one lexical token:

```wl
CodexDirectRootChannelExactOneFormRebindV6`DRCARebindExactOneFormChannels[...]
```

Driver:

`/home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/run_cf300_sector12_galois_orbit_forcing_screen_v6c.wls`

Frozen driver SHA256:

`86bd849d1e129be5db7c788cf99fc99069a52732b90fb04e423a9321e504b0fc`

## Pre-launch evidence

The lexer-aware static suite passes 69/69.  It strips nested comments and
strings before looking for a context mark followed by whitespace and a symbol
name.  A mutation that reintroduces the exact newline split is rejected.  The
unchanged exact-field adversarial suite passes 1254 character identities, 160
two-prime second-order rational-jet trials, 6 stabilizer adversaries, 12 exact
rebind adversaries, and 14 certificate-schema/mutant checks.

No Wolfram kernel was launched by this audit agent.  A real Wolfram held parse
is a mandatory independent gate, not replaceable by the static tests.

## Exact central parse command

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  diagnose_v6c_wolfram_parse_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/diagnose_wolfram_parse_target_v1.wls \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/run_cf300_sector12_galois_orbit_forcing_screen_v6c.wls
```

Require mission exit 0 and `ParsedHead -> "HoldComplete"`.  Recheck the V6c
SHA before the full mission.

## Full launch only after the parse seal

Use the existing pinned sector-12 preparation/cache and a distinct output that
does not exist:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_galois_orbit_forcing_xh_v6c \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/run_cf300_sector12_galois_orbit_forcing_screen_v6c.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6c.wl \
  2
```

The driver itself rejects a stale output and writes atomically with
`OverwriteTarget -> False`.
