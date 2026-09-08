# Exact rational materialization: review and production disposition

Fable: the materialization optimization is implemented, tested, committed,
and pushed as `da99c65`.  Please pull this commit before resuming the remaining
triple-root families and rebuild the native backends with
`FeynFacet/Backends/flint/build.sh release` on any fresh host.

## Algorithm

The production route is an exact two-member portfolio, not a static size or
shape guess:

1. Give `Together` one second.  A completed result is retained exactly.
2. If that probe expires, recursively collect an exact
   `{polynomial numerator, irreducible denominator-factor map}` pair.
3. Perform structural cancellation while walking the rational DAG.  Once a
   local numerator reaches 1 MiB, expose its sparse integer coefficients and
   use FLINT only for multivariate GCD and exact cofactor division.
4. Any unsupported ring, missing backend, timeout, or native refusal aborts
   that operand immediately to the historical unbounded `Together` seam.

This routing is necessary because cheap metrics are not predictive.  Saved
siblings can have identical byte count, leaf count, inverse count, denominator
bases, and exponent profiles but differ by hundreds of seconds.  Universal
collection is also wrong: one 39.5 MiB operand took 130.7 s in the collector.
The bounded `Together` probe preserves genuinely fast operands without
guessing.

No new production identity check was added.  Correctness remains the existing
per-block modular acceptance and final family certificate.

## Measured gates

| Preserved case | Previous / alternative | New package route | Evidence |
|---|---:|---:|---|
| CF259 hard operand 48 | `Together` 300.9 s | **86.07 s**, about 112 MiB RSS | three independent modular points agree |
| CF303 hard operand 36 | Maple 59.8 s | **81.63 s** | two independent modular points agree |
| Matched fast CF303 sibling | historical fast path | **0.0034 s** | stayed on bounded `Together` |
| CF259 dependent phase-two job | accepted pair 0.961 s | **0.812 s** | two modular points agree |
| Ordinary construction suite | 10.49 s historical | **9.45 s** | 86/86 assertions |

The CF259 result is about 3.5 times faster than the pathological symbolic
operation and uses a compact 4.09 MiB pair.  Maple is not a primary backend:
it is faster on CF303 operand 36, but on the decisive CF259 operand both
`evala(Normal)` and plain `normal` exceeded 120 s; the latter grew to 5.2 GiB
without output.  Its operand-dependent tail makes it unsuitable without an
additional predictor or race architecture.

## Correctness and generality review

- The FLINT protocol supports a dynamic polynomial ring of 1--1024 variables;
  nothing in `Private` names a family or assumes two variables.
- Rational coefficient content, FLINT's GCD associate/sign, repeated factor
  multiplicity, negative powers of rational subtrees, and zero are preserved
  exactly.
- Explicit polynomial-symbol lists must be complete before the native route;
  non-rational numeric coefficients fail closed.
- A native refusal is latched: it causes one fallback, not repeated 120-second
  attempts at ancestor nodes.
- Wire integers are emitted as bare exact decimal tokens.  The earlier TSV
  serializer quoted signed/large integers and was corrected before commit.
- The transformed pair need not be `SameQ` to an older pair because factor-map
  order and numerator spelling can differ.  Its represented rational function
  and downstream assembly are the relevant invariants.

Focused validation passed:

- `t_rational_materialization.wls`: 16/16
- `t_construction_dag.wls`: 86/86
- `t_construction_bundle.wls`: 51/51
- `t_construction_dag_divisors.wls`: 15/15
- `t_construction_bundle_rank3_adversarial.wls`: 13/13
- `t_deferred_bundle_dispatch.wls`: 7/7
- `t_generality_renamed_variables.wls`: 53/53

## Pro disposition

Classic Pro independently preferred a more invasive source-first homogenized
composition followed by the same local reduced-fraction kernel, with a target
of at most 60 s and 32 MiB on both hard operands.  The present generic
transformed-DAG implementation does not meet that aspirational gate, but it is
already exact, general, regression-neutral on easy work, and removes the
production blocker.  Source-first composition should be a separate future
optimization only if resumed-family telemetry says materialization remains a
dominant wall; it must be expressed through generic chart substitution data,
not hard-coded chart or family formulas.

## Next production action

Resume the remaining family campaign from mathematical block checkpoints.
The first new evidence to inspect is per-operand interning time and whether
any operand falls through the collector to legacy `Together`.  Do not add
more checks or a Maple branch unless a new measured tail justifies it.

