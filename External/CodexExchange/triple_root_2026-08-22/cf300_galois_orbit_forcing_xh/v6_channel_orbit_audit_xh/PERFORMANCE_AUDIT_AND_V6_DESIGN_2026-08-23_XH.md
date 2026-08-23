# CF300 Galois V5 performance audit and exact-channel V6a

Date: 2026-08-23

Scope: no-kernel, read-only audit of the live V5 mission plus a separately
frozen V6 implementation. The active V5 source, pool, processes, watchlist,
package files, and output were not edited, signalled, restarted, or stopped.

## Executive result

V5 is not blocked on FLINT. Its first log milestone occurs only after two
silent symbolic phases: the complete Galois-letter census and
`DRCARebindAnsatz`. The census repeatedly converts the same algebraic
potentials and dlogs between root expressions and rational field channels.
It also certifies the Klein-four action by thousands of algebraic root
substitutions even though the action is diagonal in the existing channel
basis.

V6 removes those conversions from the census:

1. source potentials come directly from the pinned
   `baseAssembly["ExactChannelForms", "BBar"]` cache;
2. base one-form fingerprints come from the pinned
   `baseAssembly["ExactChannelForms", "OneForms"]` cache;
3. each distinct source potential is inverted and differentiated once in the
   four-dimensional rational channel algebra;
4. all four Galois images are exact character sign maps on channel grades;
5. candidates are deduplicated by canonical channel fingerprint before a
   one-form expression is composed;
6. appended one-forms are compiled directly from certified rational channels,
   bypassing algebraic `TRFieldDecompose` in the rebind;
7. a new `channel_orbit_ready` milestone separates census time from rebind
   time.

The launchable V6a driver is frozen but has not been launched by this audit.
It explicitly supersedes the earlier frozen V6 driver SHA
`e6d0dd17378d3e7662f5926abaa97a6feef370bf6cb24b1ba26534c2e2385ba3`:
V6 stored integer `4` under a Boolean-sounding subset-certificate key and
hardcoded adjacent structural Booleans. V6a gives the integer its correct
`ResidueColumnsPerLetter` name and derives/fail-closes the structural Boolean
from counts, exact column layout, the rebind seal, and every image's exact base
column prefix.

Static tests are 63/63. A no-Wolfram adversarial model passed 1,254 exact character
checks, 160 second-order bivariate finite-field jet trials at primes 10007 and
10039, six stabilizer tests, twelve exact-channel rebind adversaries, and
fourteen subset-certificate schema/mutant checks.

## What V5 does before its first milestone

The first V5 `target_ready` print is at old source lines 718--723. Before it,
V5 performs all of the following:

1. reads and fingerprints the 28 MiB preparation and 32 MiB compiled cache;
2. validates the dedicated hydration context and full ABIs;
3. constructs 28 nontrivial source potentials from four epsilon images;
4. constructs 112 source/sign candidates;
5. symbolically differentiates, simplifies, decomposes, recomposes, and
   certifies every candidate;
6. canonicalizes the 36 base one-forms again;
7. recomputes the eight diagonal forms;
8. canonicalizes the maximal basis again;
9. performs the full 28 by 4 by 4 orbit-composition table by algebraic branch
   substitutions;
10. builds and validates the maximal preparation; and
11. algebraically decomposes and compiles every appended one-form in
    `DRCARebindAnsatz`.

Consequently, a silent log does not identify whether the kernel is in the
candidate census or the rebind.

### Expected operation count for this pinned CF300 case

The prior independent census gives 28 source potentials, 40 unique forcing
letters, 12 appended letters, and 48 maximal one-forms. With those counts, V5
performs approximately 572 algebraic `TRFieldDecompose` calls before
`target_ready`:

| site | decompositions |
|---|---:|
| source potentials | 28 |
| conjugated potentials | 112 |
| two components of 112 candidate dlogs | 224 |
| two components of 36 base forms | 72 |
| two components of eight diagonal forms | 16 |
| two components of 48 maximal forms | 96 |
| two components of 12 appended forms in rebind | 24 |
| total | 572 |

The cardinality bounds in V5 permit up to 860 such calls. Every rank-two
decomposition can execute root replacement, algebraic `Together`, polynomial
reduction, a rational 4 by 4 field inverse/`LinearSolve`, multiplication, and
an algebraic roundtrip.

The candidate builder also performs about 896 explicit symbolic derivatives:
eight per candidate (source dlog, conjugate dlog, repeated dlog identity, and
closure). It executes 448 algebraic branch applications in candidate records.
The 28 by 16 Klein table performs three branch applications per entry, another
1,344. Thus the visible V5 code contains about 1,792 algebraic branch
applications before accounting for root replacement inside decomposition.

At 11:58 local time, active V5 had run about 38.5 minutes with no milestone.
This observation was read-only; it does not distinguish its current internal
phase.

## Exact V6a algebra

Write a rank-two field element in mask order as

`p = sum_m p_m r_m`, where `m` is in `{0,1,2,3}`.

For sign mask `s`, the Galois action is

`sigma_s(p)_m = (-1)^popcount(s & m) p_m`.

This is exact because character parity satisfies

`chi_s(a) chi_s(b) = chi_s(a xor b)`.

It therefore commutes with field multiplication, inverse, and the gradewise
multiquadratic derivative. V6 computes a source dlog once as

`omega_mu = p^(-1) * TRDerivative[p, deltas, variable_mu]`

and obtains every orbit image as `sigma_s(omega_mu)`. Candidate dlog identity,
involution, derivative equivariance, closure, and XOR composition then inherit
from the exactly checked source identity plus a finite exact character-table
certificate. These are algebraic certificates, not modular guesses.

The orbit hot loop contains no `D`, algebraic `Together`,
`TRFieldDecompose`, `TRFieldInverse`, or `TRApplyRootBranches`. Canonical
`Together` remains only on rational channels, where it cannot generate radical
expression swell.

## Memoization and canonical fingerprints

V6a has three independent caches:

- source potential fingerprint to exact inverse/dlog core;
- source dlog fingerprint plus sign mask to canonical orbit dlog;
- source potential fingerprint plus sign mask to canonical orbit potential.

The fingerprint ABI is deliberately the V5 ABI:

`Hash[ToString[InputForm[{expanded numerator, expanded denominator}...]],
SHA256]`.

Fingerprint groups are still collision-checked by exact canonical-channel
equality. Only one expression per unique one-form group is composed. Internal
inverse, derivative, and raw dlog channels are removed from final provenance
records to prevent output and memory inflation.

## Exact-channel rebind

The specialized rebind is one-form-only and fail-closed. It:

1. validates the base assembly and target preparation;
2. pins the exact assembler source SHA;
3. rejects changes to record, roots, variables, regulator, support,
   denominator, normalizations, dimensions, or equation counts;
4. checks that every supplied channel vector composes exactly to the target
   appended one-form;
5. invokes the pinned rational-leaf compiler directly;
6. preserves `E`, `C`, `BBar`, root-square data, root-log data, denominator,
   and denominator-log data exactly; and
7. rebuilds every semantic fingerprint and passes the public full assembly
   validator.

This removes the last 24 expected algebraic decompositions in the old rebind.

## Input binding and analytic rescaling

V6a intentionally pins the same artifacts as V5:

- preparation SHA:
  `6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4`;
- compiled cache SHA:
  `0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be`.

Therefore V6a is currently certified against the pre-existing sector-12
`(12,9)` sidecar preparation, not against a preparation rebuilt from the new
post-rescaling full-family state. The analytic rescaling acts on the sector-11
two-dimensional block, so invariance of a sector-12 to sector-9 strip is
plausible, but it is not yet proven. Post-rescaling certification requires
rebuilding that preparation/cache or proving exact equality of the extracted
strip and fingerprints.

## Expected timing

These are estimates, not a runtime benchmark:

- the failed-closed V4 hydration path took 15.2 seconds;
- `channel_orbit_ready` should normally appear within roughly 1--5 minutes;
- exact-channel `target_ready` should add roughly 1--3 minutes;
- four finite-field sample/rank images should dominate the remaining runtime,
  plausibly 5--15 minutes on a clean worker.

The first clean V6a run is authoritative. The driver reports census and rebind
times separately so a miss is diagnosable.

## Frozen source hashes

| artifact | SHA256 |
|---|---|
| launchable V6a driver | `9465f690d0b46ef31d8c5b5dc378b94becf677cd2036155e80a98522db62bc29` |
| superseded V6 driver | `e6d0dd17378d3e7662f5926abaa97a6feef370bf6cb24b1ba26534c2e2385ba3` |
| exact channel-orbit core | `e7546be3b222581594fa2e57c6f22f2c891a27d21fd0a02c819ce732ad1f9942` |
| exact-channel rebind | `2fceb1511c7084b5047b748820460b763e96ff902935ba488255a8c3ae21be44` |
| integration reference | `c1c1e3d0268f3847e372ef14b32e9cae4bb27dc1db3ecb1db5be60b6884cc9eb` |
| static gate | `5772027414f03133efc3018ec05fbee8d6b2b00d314638b16830b1e8ec68b8ef` |
| adversarial model | `d20e2e9edbd6141436ad408945a844dfc82c7c3bb83fccf8604d9691f539d27d` |

## Launch contract (not executed by this audit)

The distinct output was verified absent when this report was prepared:

`/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6a.wl`

Use helper count zero and two native FLINT threads:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_galois_orbit_forcing_xh_v6a \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/v6_channel_orbit_audit_xh/run_cf300_sector12_galois_orbit_forcing_screen_v6a.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6a.wl \
  2
```

The driver refuses a pre-existing output and writes its result atomically.

## Verification scope and caveats

Passed without launching Wolfram:

- conservative Wolfram delimiter/namespace/source-pin/static gates: 63/63;
- exact character table census through rank three: 1,254 checks;
- two-prime, second-order rational-function jet trials: 160;
- orbit stabilizer adversaries: six;
- exact-channel rebind mutation/order/shape adversaries: twelve.
- subset-certificate schema and mutant adversaries: fourteen.

The jet trials independently exercise field multiplication, field inverse,
root-log derivatives, dlog identity, closure, character equivariance, branch
composition, stabilizers, and direct-expression agreement. They do not replace
the first Wolfram parse/runtime run. The frozen V6 must still be independently
sealed and run on a clean worker before its result is called certified.
