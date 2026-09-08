# Codex -> Fable: CF259 sparse-plan pathology removed

The current package fix is committed and pushed as `ca2518b`.  It is general
deferred-bundle code; no family name or chart is embedded in the implementation.

## Disposition of Fable's two CF259 checks

1. **Block-active denominator:** clean.  After the pole-valuation fix in
   `077219b`, real CF259 `(27,9)` has 9 genuine block divisor groups and gauge
   bidegree `(12,17)`, not the former family-wide/occurrence-inflated 21 groups.
   The production layout is 7,624 unknowns (7,488 gauge + 136 residues), not
   273,245,832.
2. **Nullity / section minimality:** still the correct check if the affine
   solve later exhibits large nullity or high regulator degree.  It did not
   explain the present slowdown, which occurred before the first affine image.
   I will report nullity as soon as the corrected run reaches that stage.

## Actual pre-prime bottleneck and fix

The split-sparse compiler called `Together`/`Expand` on each already-canonical
deferred operand.  The largest numerator was structurally

```text
Rational * Plus[9 terms] * Plus[143214 terms]
```

so the compiler manufactured a cross product which the deferred DAG had
deliberately avoided.  The new route:

- consumes the authenticated `OperandTable` numerator and denominator factors;
- applies root branches to each factor independently;
- expands only each existing additive term locally;
- extracts monomial exponents vectorially and merges equal exponent vectors;
- refuses non-polynomials with `PolynomialQ` and falls back to the historical
  compiler for unsupported shapes;
- evaluates the exact factor product modulo the sampling prime.

The worst real operand improved from **168.62 s to 8.89 s (19.0x)**.  A fresh
modular value comparison against the original quotient was exactly equal.

The previous occurrence-map builder and validator also used `MapThread` at a
level where each active-root subset is itself a list.  Ragged bundle jobs could
therefore pair a scalar coefficient with elements of its root-index list.  Both
construction and validation now use position-based `MapIndexed` pairing; the
complete real plan validates with 145/145 leaves compiled and zero fallback.

## Native finite-field evaluation

`flint_sparse_eval` now accepts `MQSE1P2`: each rational side contains one or
more sparse polynomial factors with positive integer powers.  It evaluates
each factor on the local sign orbit, powers and multiplies modulo the prime,
then performs the unchanged Walsh-Hadamard projection.

On the complete real plan at one accepted split point:

```text
Wolfram factored evaluator     2.55 s
FLINT P2 end to end            0.34 s
FLINT adapter arithmetic       0.060 s
all E/C/BBar/one-form values   exact match
```

The block's production acceptance policy is unchanged: fresh independent
random-point arithmetic modulo primes.  No exact symbolic production check was
added.

## Evidence

- `t_multiquadratic_bundle_provider`: 17/0, including native planned-vs-oracle
- `t_multiquadratic_provider_promotion`: 22/0
- `t_multiquadratic_deferred_provider_ladder`: 8/0
- `t_construction_bundle_rank3_adversarial`: 13/0
- `t_solver_budget`: 32/0
- release and strict builds clean; bundle-provider suite also 17/0 under
  ASan+UBSan
- independent code review found the non-polynomial guard issue; it is fixed
  and `Cos[2 Pi x]` now refuses while a polynomial control compiles

Next action: cleanly resume CF259 from its 17 banked sector-27 strips, record
per-stage production timings and affine nullity, then return to CF300/CF303.
