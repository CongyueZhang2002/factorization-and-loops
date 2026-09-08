# CF300 sector 12: exact local resonance gate and bounded RAD9 fallback

Date: 2026-08-23  
Scope: External-only design and static verification. No Wolfram kernel was
launched, no package or active mission source was edited, and no process was
signalled or controlled.

## Sharp conclusion

A blind repeated-denominator exponent cube is not physics-motivated for this
block.

The pinned direct-channel assembler represents each gauge basis element as

```text
x^a y^b r_1^g1 r_2^g2 / D
```

and its derivative contains the exact algebraic-basis term

```text
(1/2) Sum_i g_i dlog(Delta_i).
```

The diagonal actions are the cached epsilon-free `E` and `C` kernels
multiplied by `epsilon` by the source-pinned assembler.  Therefore, at a
finite divisor `f), a hypothetical leading pole of positive integral
denominator order `k` has homogeneous local operator

```text
(-k + nu_grade(f)/2) I + epsilon L_f,
```

where `nu_grade(f)` is the valuation of the active root monomial.

The two active root squares are

```text
Q = 1 - 2 x + x^2 + 2 y + 2 x y + y^2,
Delta_3 = 1 - 4 x y.
```

Each is a simple factor in the exact nine-divisor channel catalog, and no
other catalog factor occurs in either root square.  Thus every grade
valuation at every catalog divisor is either zero or one.  For every positive
integer `k`, the epsilon-zero spectrum is consequently either `-k` or
`-k+1/2`, never zero.  Equivalently, the determinant has a nonzero
epsilon-constant term

```text
Product_grade (-k + nu_grade(f)/2)^4.
```

It is therefore not the zero rational function in epsilon.  No genuine
higher spatial pole above the forcing valuation can be supported by a local
resonance.  At an ordinary finite point all root valuations are zero and the
same argument reduces to `(-k)^16), so a new unlisted finite pole is also
excluded.

This closes repeated finite-pole multiplicity as a physical loophole.  It
does not close additional numerator growth at infinity.

## Two explicit modes in the frozen driver

The driver has a required mode argument.

### `CERTIFICATE` (recommended)

This is the compact exact gate.  It:

- hydrates the preparation, cache, and denominator census in a fixed
  dedicated context with no `Global` symbol dependency;
- validates the preparation/cache/assembly values and their stored exact and
  compiled fingerprints;
- reconstructs the current denominator from the exact census factorization;
- derives the 2 by 9 root-valuation matrix from the exact root squares and
  canonical divisor factors;
- proves the half-root local spectrum is nonzero and records independent
  modular nonzero checks at primes 10007 and 10039;
- exits before ansatz rebind, sampling, witness construction, or native rank.

### `RAD9` (bounded adversarial fallback; do not run as a pole search)

This mode intentionally over-completes the denominator by multiplying the
current denominator once by the radical of all nine exact channel divisors.
It should only be interpreted as a numerator/cancellation-support stress.

Exact target:

```text
D_RAD9 = D_current Product_(nine exact divisors) f
bidegree(Product f) = (9,7)
bidegree(D_RAD9) = (13,12)
dense support = 182
gauge unknowns = 16 * 182 = 2912
residue unknowns = 144
total unknowns = 3056
points/image = Ceiling[(3056+32)/32] = 97
```

The mode resolves this maximal target before its only rebind.  It constructs
all 512 bounded profiles (base plus 511 nonempty subsets).  For profile
`S`,

```text
D_S = D Product_(i in S) f_i,
D_RAD9 / D_S = Product_(i not in S) f_i.
```

Multiplication by the nonzero complement is injective, and exact convolution
of each profile's dense numerator rectangle lies in the `(13,12)` RAD9
rectangle.  Residue columns are unchanged.  Hence an inconsistent maximal
RAD9 system rejects every one of the 511 nonempty profiles by exact column
space inclusion.

For every image the driver additionally constructs the epsilon-specialized
sparse convolution embedding and requires

```text
A_RAD9 . embedding == A_base
```

on the same 21 accepted points before using the certified base left witness.
It scores every RAD9 column.  A nonzero necessary score promotes the one
maximal target to independent native ranks of `A` and `[A|b]`; an all-zero
score rejects it immediately.

## Persistent-kernel safety

The driver is rebased on the fixed dedicated-context hydration pattern:

- raw message-tolerant artifact reads;
- the artifact context remains on `$ContextPath` through all public
  validators, rebinds, samplers, and fingerprints;
- the public reader that hardcodes `Global` is deliberately not called;
- exact namespace identity and definition-free state are checked before,
  during, and after hydration;
- literal context cleanup and caller context restoration are mandatory;
- no `InheritedBlock`, `Unlock`, `Unprotect`, global symbol mutation,
  Wolfram parallel entry point, or process-control entry point occurs.

All copied Galois-orbit status/schema names were removed.  The driver has its
own versioned package, exit tag, hydration status, output statuses, and
literal artifact context.

## Static and adversarial verification

The no-kernel test passed 45/45 checks.  Besides delimiter and namespace
audits it independently:

- recomputes the exact radical and target bidegrees;
- recomputes support, unknown, and point counts;
- enumerates all 512 profile support convolutions;
- models the two simple root-square valuations;
- checks every half-root determinant constant is nonzero modulo both primes;
- checks the certificate mode exits before the only ansatz rebind;
- checks target-first assembly, common-point convolution projection, witness
  ordering, two-rank promotion, source pins, source stability, and forbidden
  runtime operations.

Frozen SHA-256:

```text
driver  5c43e5ad88270968d34b35c4445247a815a35fa8e5bb6598013098e1089708b1
static  c10a437d01b0906eac356dcb9139c90de0c405e38bb52cc7c2f2e0d61c862965
```

No dynamic mathematical result is claimed until the compact certificate mode
is run centrally.  The RAD9 fallback should not be scheduled merely to test
higher poles; the exact gate already excludes that interpretation.

## Exact central launch arguments

Recommended compact certificate only:

```bash
ROOT=/home/maxzhang/factorization-and-loops
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool
DIR=$ROOT/External/CodexExchange/triple_root_2026-08-22/cf300_repeated_pole_resonance_xh
PREP=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl
CACHE=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl
CENSUS=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_denominator_census_xh_v5.wl

POOL="$POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$ROOT/Scripts/kpsubmit.sh" cf300_s12_local_resonance_cert_xh_v1 \
  "$DIR/run_cf300_sector12_repeated_pole_rad9_screen_v1.wls" \
  "$ROOT" "$PREP" "$CACHE" "$CENSUS" \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_local_resonance_cert_xh_v1.wl \
  CERTIFICATE 1
```

Bounded fallback syntax, retained for explicit later authorization:

```bash
POOL="$POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$ROOT/Scripts/kpsubmit.sh" cf300_s12_rad9_support_stress_xh_v1 \
  "$DIR/run_cf300_sector12_repeated_pole_rad9_screen_v1.wls" \
  "$ROOT" "$PREP" "$CACHE" "$CENSUS" \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rad9_support_stress_xh_v1.wl \
  RAD9 4
```

The last integer controls FLINT threads only.  The driver launches no Wolfram
subkernels.
