# CF300 (12,9) rank-2 extension-field finite-field route

Date: 2026-08-23

Status: External-only implementation is settled for syntax/load smoke and a
bounded preparation measurement.  It has **not** been executed in a Wolfram
kernel by Codex.  Package files were not changed for this route.

## Assessment

`NoRationalStripChart` is a chart-dispatch limitation, not an obstruction to
the epsilon-form equation.  The physical CF300 `(12,9)` forcing uses catalog
roots `{2,3}` and global grades `{0,2,4}`.  The existing reconstruction
prototype already writes the affine PDE over the four-dimensional
biquadratic basis and evaluates all four split sign branches at each finite
field point.  The minimal route is therefore split-prime sampling plus exact
channel reconstruction; a joint rational chart is unnecessary.

The important new issue is regulator dependence.  This input contains pure
epsilon denominators, including an `eps^3` factor and
`2+19 eps+55 eps^2+50 eps^3`.  Polynomial interpolation in epsilon is not a
correct physical solver.  The new route derives and clears the common
pure-epsilon factor from the forcing, performs rational-in-epsilon
interpolation for every affine coordinate, divides the complete reconstructed
vector (gauge and residues) by that factor, and checks the original unscaled
channel PDE exactly.

The first epsilon image performs one canonical dense `RowReduce` to discover
a constrained square plan.  Every subsequent epsilon image for that prime
uses one square multi-RHS factorization through FLINT when available, with a
Wolfram fallback, followed by residual checks against every original row.
Repeated full preparation-ABI canonicalization is avoided only inside private
helpers after one full public validation.  Public sampling and verification
operations still perform a full validation.  A 2 GiB canonical dense-byte cap
(32 bytes per augmented entry estimate) rejects an oversized first RREF
before it starts.

## Files

- `TripleRootReconstructionPrototype.wl`: rational-epsilon prime interpolation,
  constrained solver, CRT/rational lift, exact residual and all-mask verifier.
- `run_cf300_sector12_rank2_extension_prepare.wls`: validates the physical
  sidecar, global `{1,2,3}` to stable local `{2,3}` masks, square classes,
  support/equation fingerprints, regulator clearance, and preparation ABI.
- `run_cf300_sector12_rank2_extension_prime.wls`: one fresh, helper-free,
  shardable 31-bit prime artifact.
- `run_cf300_sector12_rank2_extension_aggregate.wls`: three-or-more-prime lift,
  exact original dlog residual, permanently unseen prime, all split rows and
  all four sign-mask permutations, and a bound sidecar seed.
- `run_cf300_sector12_sidecar_syntax_load_smoke.wls`: isolated held parsing of
  all three drivers plus a semantic `TRCanonicalAffineSolve` smoke.

SHA-256 at settlement:

| Source | SHA-256 |
|---|---|
| physical `CF300_12_9_input.wl` | `274d5d0c4abf1c8ff7cafdf09367e4716b42b6721dc4ae294179d21a84d25af6` |
| `TripleRootAlgebra.wl` | `fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab` |
| `TripleRootStripAdapter.wl` | `ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5` |
| `TripleRootAffinePilot.wl` | `283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90` |
| `TripleRootReconstructionPrototype.wl` | `95906274f37d855a4f13c742818ad378e18b6a6ca2bb63af0ace0dcebb960f6f` |
| prepare driver | `c569e8b3e86d9b3e27dd19fc1a92ad0cee3ee8c017b2a625cc4cedadcc1070b7` |
| prime driver | `72de0c461765d4111830a83b6c9c6f49d871340654d1b029e587ecdf6b16352d` |
| aggregate driver | `0e45b664850acc761dbff033ecf320ce76c7d5072ec28160097584d4f4180fd4` |
| syntax/load smoke | `7ac310f1bd5e51b6918bfd9ce5680035477e753b39bbe3d54db2c210605693e7` |

The artifact manifest also binds `Addon/Load/LoadFACET.wl`,
`FeynFacet/FeynFacet.m`, `FeynFacet/Private/FiniteFieldStripSolve.wl`,
`FeynFacet/Private/TransportCharts.wl`, the four External dependencies above,
and each driver's own hash.  Every driver hashes before read/load, after
read/load, and at completion.  Outputs and the legacy `.tmp` sentinel are
refused at entry; commits use a UUID temporary file and a checked
`RenameFile[..., OverwriteTarget -> False]`.

## Exact pool commands

These commands use helper ceiling zero.  The three construction-prime
missions can occupy three flat pool subkernels concurrently; each modular
square solve may use two FLINT threads.  They never launch a main kernel or
broker helper tasks.

```bash
CF300_POOL=/tmp/codex-triple-root-20260823c.vx654S/pool
CF300_ROOT=/home/maxzhang/factorization-and-loops
CF300_DIR=$CF300_ROOT/External/CodexExchange/triple_root_2026-08-22/cf300_sector12_physical_rank3_xh
CF300_INPUT=$CF300_DIR/physical_sidecar_evidence_2026-08-23_xh_v3/CF300_12_9_input.wl
CF300_OUT=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_xh_v1
mkdir -p "$CF300_OUT"

POOL="$CF300_POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$CF300_ROOT/Scripts/kpsubmit.sh" cf300_s12_r2_prepare_xh_v1 \
  "$CF300_DIR/run_cf300_sector12_rank2_extension_prepare.wls" \
  "$CF300_ROOT" "$CF300_INPUT" "$CF300_OUT/preparation.wl" 2000
POOL="$CF300_POOL" "$CF300_ROOT/Scripts/kpwait.sh" \
  cf300_s12_r2_prepare_xh_v1

POOL="$CF300_POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$CF300_ROOT/Scripts/kpsubmit.sh" cf300_s12_r2_p2147483423_xh_v1 \
  "$CF300_DIR/run_cf300_sector12_rank2_extension_prime.wls" \
  "$CF300_ROOT" "$CF300_OUT/preparation.wl" \
  "$CF300_OUT/p2147483423.wl" 2147483423 48 24 22
POOL="$CF300_POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$CF300_ROOT/Scripts/kpsubmit.sh" cf300_s12_r2_p2147483543_xh_v1 \
  "$CF300_DIR/run_cf300_sector12_rank2_extension_prime.wls" \
  "$CF300_ROOT" "$CF300_OUT/preparation.wl" \
  "$CF300_OUT/p2147483543.wl" 2147483543 48 24 22
POOL="$CF300_POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$CF300_ROOT/Scripts/kpsubmit.sh" cf300_s12_r2_p2147483563_xh_v1 \
  "$CF300_DIR/run_cf300_sector12_rank2_extension_prime.wls" \
  "$CF300_ROOT" "$CF300_OUT/preparation.wl" \
  "$CF300_OUT/p2147483563.wl" 2147483563 48 24 22

POOL="$CF300_POOL" "$CF300_ROOT/Scripts/kpwait.sh" \
  cf300_s12_r2_p2147483423_xh_v1
POOL="$CF300_POOL" "$CF300_ROOT/Scripts/kpwait.sh" \
  cf300_s12_r2_p2147483543_xh_v1
POOL="$CF300_POOL" "$CF300_ROOT/Scripts/kpwait.sh" \
  cf300_s12_r2_p2147483563_xh_v1

POOL="$CF300_POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$CF300_ROOT/Scripts/kpsubmit.sh" cf300_s12_r2_aggregate_xh_v1 \
  "$CF300_DIR/run_cf300_sector12_rank2_extension_aggregate.wls" \
  "$CF300_ROOT" "$CF300_OUT/preparation.wl" \
  "$CF300_OUT/certified.wl" 2147483587 \
  "$CF300_OUT/p2147483423.wl" "$CF300_OUT/p2147483543.wl" \
  "$CF300_OUT/p2147483563.wl"
POOL="$CF300_POOL" "$CF300_ROOT/Scripts/kpwait.sh" \
  cf300_s12_r2_aggregate_xh_v1
```

All four listed moduli are prime, below `2^31`, and congruent to `3 mod 4`.
`2147483587` is never used for construction.  Three construction primes give
a CRT modulus with a symmetric rational-reconstruction height of roughly
`7e13`; coefficient reconstruction fails closed if that is insufficient, in
which case add a fourth fresh 31-bit prime artifact.

## Size and failure risks

For a `2 x 2` block with four local root grades, support size `S`, and `L`
one-forms, the exact unknown count is

`N = 2*2*4*S + 4*L = 16 S + 4 L`.

There are 32 equations per accepted split point.  The one-form candidate
catalog is at most about 40 items before exact deduplication (8 diagonal plus
32 forcing-derived candidates).  The visible denominator pattern suggests a
rectangle near bidegree `(4,5)`, hence `S` near 30 and `N` no larger than about
640, but this is only a pre-run estimate.  Preparation reports exact `S`, `L`,
`N`, and fails before sampling if `N > 2000`.

Forty-eight deterministic epsilon images with 24 construction images and
maximum total rational degree 22 are correctness-first settings.  If a
coordinate exceeds degree 22, interpolation returns a typed failure; increase
both the sample count and maximum degree.  This first physical run uses the
public deterministic interpolation (four or more validation images), not the
newest adaptive held-out private routine.

Each prime currently discovers its own independent equation rows and
normalization columns.  The aggregator requires the semantic normalization
columns, rank/nullity, degree profiles, root order, and preparation ABI to
match.  Per-prime RREF pivot columns are recorded for diagnostics but are not
treated as cross-prime ABI.  Persisting one pilot semantic plan across all
primes is the next optimization; it is deliberately deferred because it would
serialize the present shards unless a separate plan artifact is introduced.

The validated `PrecomputedChannelSidecar` prevents ambiguity and detects stale
input, but the hot sampler still branch-substitutes the materialized algebraic
forcing.  A direct rational-channel row assembler is the main remaining speed
optimization after this benchmark.

## Certification and continuation

Acceptance requires all of the following:

1. three independent construction-prime artifacts with matching semantic ABI;
2. exact rational CRT lift and zero characteristic-zero channel residual for
   the scaled equation;
3. division by the nonzero pure-epsilon clear factor and zero exact dlog
   residual for the original physical equation;
4. a permanently held-out 31-bit prime at two new epsilon values;
5. every point's four split sign rows and all four branch-flip permutations;
6. unchanged input, dependencies, drivers, and artifacts through atomic
   commit.

The branch-flip masks are an adversarial row-permutation check because all four
sign branches are already present at each point; they are not four independent
physical certificates.  The characteristic-zero exact residual is decisive.

On success, `certified.wl` contains `SidecarSeed`, bound to input SHA,
term-graph/channel/support fingerprints, root source order, root-order and
preparation ABI fingerprints, dependency hashes, and a gauge fingerprint.
No current package/physical-sidecar driver consumes this seed.  It must be
treated as unconsumable until a loader revalidates all bindings, verifies the
gauge shape is `2 x 2`, and reruns the exact dlog residual.  After that check,
the loader can set the `(12,9)` solved gauge and allow the physical sidecar to
continue through lower sector 8 to the first rank-3 block.

## Static checks performed

No Wolfram or standalone process was launched.  `git diff --check` passed;
the existing CF300 driver integrity shell test passed 16/16; the five changed
Wolfram sources have balanced raw square, curly, and parenthesis delimiter
counts.  The isolated Wolfram syntax/load/semantic smoke remains the required
first pool mission before accepting a physical certificate.
