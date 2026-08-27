# CF303 19→12 sharded pullback and 21→12 preparation checkpoint

Date: 2026-08-24

Package source was not modified. All work below is scratch-only and executed
through the existing eight-worker kernel pool with helper ceiling zero for each
mission.

## Pro conversation routing

All further consultations are pinned to the existing ChatGPT Classic Pro chat
**Assess Multiquadratic Pipeline**, conversation ID
`6a8a4f28-4504-83e8-b794-f156372e1c85`. Use `send`/`send-files`, never
`new`/`new-files`. See `PRO_CONVERSATION_PIN_2026-08-24.md`.

## Exact 19→12 Kallen23 source pullback

The monolithic exact pullback passed:

- chart gauge: 4×4, 53,353 leaves;
- source gauge: 4×4, 1,534,219 leaves;
- roots `{1,2}`, root 3 absent, constant field `Q`;
- accepted sheets `{{1,1},{1,-1}}`;
- wall time 1,331.0 s;
- source WXF SHA-256
  `10adfc9e322de030d02386dbdff0ffe5825d271f992e6f990490556bf198b468`.

The row-sharded route also passed:

| shard | rows | pullback | source leaves | source SHA-256 | certificate |
|---|---:|---:|---:|---|---:|
| 1 | `{1,2}` | 333.8 s | 496,427 | `95bec5d70761d0213ea24801028a0bde5ca1368f9c7f8cb86a70746d876434e9` | 68.0 s |
| 2 | `{3}` | 408.8 s | 545,865 | `ca4f108e175de91056758e927b686551fd642489378aa8d478e6303bf641920f` | 83.4 s |
| 3 | `{4}` | 385.0 s | 491,929 | `f03fcb4cc2d78171295a6cbc058e1e53206cdc1af2f2e810daad2bed1bd14bcd` | 66.4 s |

Every shard certificate found the same root set and accepted sheets, with no
undeclared radical. The exact aggregator passed in 1.2 s and produced the full
source gauge with SHA-256
`5afc03d2d731363c8566beaf783cb9cf560f871e79f7ec68a0eb60f286691a64`.
An independent oracle-equivalence mission found the sharded and monolithic
source gauges structurally identical entry by entry (`SameQ=True`). The
certified critical path is about 493.4 s, approximately 2.7× faster than the
monolithic route.

## Exact source-channel decomposition

Each shard was decomposed only over its active root subset and then lifted into
the fixed rank-3 little-endian eight-grade ABI. Local and global compositions
were checked exactly.

| shard | time | channel SHA-256 |
|---|---:|---|
| 1 | 677.8 s | `42463172895894cbe666c73159b8012337d64f844702f1165f03d23e3c1439ce` |
| 2 | 915.3 s | `9312ff3ada90268edd3b646a4afdf241beea4461d74514c064d93792ea87674d` |
| 3 | 687.2 s | `ec5487969ee357d334e4049090ffac9a90b4f2a766b01e89f8063a771837f659` |

The factor-bundle and freshly constructed identity-frame roots were also
proved to have the same ordering, representatives, and squares.

## 21→12 recurrence provenance

The pinned state SHA-256 is
`1454906ac674090664e0065732881b2cd8409a15c2f670ca61fd05b5a7d4de06`.
It is the accumulated connection after sector 16, not the raw connection.
Therefore right actions from rows through 16 are already present and must not
be reintroduced.

The scratch census constructs

```text
A19,12(cur) = A19,12
             + eps (E19 D19,12 - D19,12 C12)
             - dD19,12

B21,12 = state[A]21,12
          + state[A]21,20 D20,12
          + state[A]21,19 D19,12
          + state[A]21,18 D18,12

F21,12 = B21,12 - Σ(k=13..20) D21,k A(k,12)(cur).
```

The post-state sector-17 term vanishes because `state[A]21,17=0`; the
sector-18 and sector-20 right actions vanish because `D18,12=D20,12=0`;
the sector-19 term is retained. The driver also checks
`state[A]19,17=0`, so the omitted row-17 update of `A19,12` is exact.

Mission `fresh_cf303_21_12_v2_static_and_state_gate_v1` passed in 5.8 s.
It parsed the prepared census under `HoldComplete`, verified the state hash and
sector number, found exactly all 120 expected strip pairs through sector 16,
confirmed every strip summary has an exact frame/zero certificate, and
confirmed all 15 sector transitions used the blockwise route. Summary:

`/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/cf303_21_12_v2_static_and_state_gate_v1/summary.wl`

## Current work

Three exact derivative-channel certificates are running independently, one
per source-row shard. Each proves

```text
d Compose(channels) = Compose(multiquadraticDerivative(channels))
```

against the direct derivative of the pinned source rows. Their hashes will be
pinned into the fail-closed 21→12 census before it is submitted. The census
will then determine whether this is the first dependency-closed strip that
genuinely retains all three roots. If it does, the first production pilot is
the Kallen23 pair chart plus one residual quadratic generator; the direct
eight-grade identity-frame route remains the independent oracle/fallback.
