# Inclusive coverage and exact endpoint subtraction review

Actual ChatGPT 6 Pro, response completed after 13m11s, read on 2026-09-18.
Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84
Exact pushed revision reviewed: `3229fdbe91d23abafca5d265f6b2cb126e4da03d`.
Repository: https://github.com/CongyueZhang2002/factorization-and-loops/tree/3229fdbe91d23abafca5d265f6b2cb126e4da03d

This is a retained summary of the completed response, not a claim of independent
execution. Pro explicitly inspected the endpoint regularity, contact, subtraction
and face-jet source, the measured one-loop card driver, native reduction import
and dependency closure, mixed-loop decomposition, and the two endpoint tests.
It also inspected relevant upstream Kira 3.1 exporter routines. It did not run
Wolfram tests or inspect saved production charts or the live native database.
No published NLO EEC hard coefficient was requested or compared.

## Confirmed mathematics

- The common negative-epsilon domain and componentwise external modulus bound
  establish the original source's external prescription limit AFTER causal loop
  integration, followed by meromorphic continuation. This does not assert joint
  absolute convergence of the original real/virtual loop integration, and does
  not authorize prescription removal in arbitrary dotted IBP descendants.
- The Taylor subtraction signs, factorials, stronger-power Taylor depths and
  partially integrated strata are correct. For each singular axis use
  `N_i=-1-p_i(0)`, `R_i=1-T_i`. The bulk is the product of all `R_i`; stratum B
  is the product of `T_i` for i in B and `R_i` otherwise, with the Taylor
  monomials integrated exactly as `1/(p_i+j+1)`. Every WHOLE stratum is integrable
  after its finite regulator poles are cleared. Its individual expanded
  summands need not be integrable and must not be integrated independently.
- For a smooth factor `epsilon^(-P) Hhat` and r integrated logarithmic faces,
  a requested upper order h can require `Hhat` through h+P+r. The current exact
  subtraction stage truncates nothing. Its future consumer must determine
  epsilon demands from the complete coefficients, including face denominators.
- Initial Kira `masters` is the correct declaration for the supplied equation
  system; `masters.final` describes reconstructed RHS identifiers. The new
  export-first, dependency-only closure and unchanged-state resume are sound.
  These are spanning reductions, not proofs of a minimal physical basis.

## Required general-interface repairs

1. Apply the existing finite parameter-coefficient check to coordinate-dependent
   powers and every Gauss/Appell parameter. For example `(1+x)^(epsilon/(a-b))`
   must fail under `a==b`; positive bases do not cure an undefined exponent.
2. A complete new coordinate square does not itself prove that the original
   phase space is exhausted. Derive the observable support, verify the original
   physical domain is covered by retained roots, and verify unit delta
   normalization before declaring an unweighted measurement integral inclusive.
   `2*observable` is a concrete counterexample to inferring inclusiveness just
   from roots that are physical for every z in (0,1).
3. Bind `MeasuredScalarLoopIntegrals.wl` to the exact `CalculationDefinition`.
   An interrupted changed-card preparation could otherwise leave a new scalar
   source alongside an old prepared record. Later input-companion equality
   alone only binds to the source that happened to be read.

These findings do not demonstrate a wrong value in the eight physical charts.

## Recommended completion route

Prefer measurement-free reduction of the generated inclusive source to universal
one-scale scalar inputs (candidate V5a, V5b, U8), with their independently derived
complex normalization and enough Laurent orders. This is not a prescribed master
count: unmatched integrals remain unresolved. The finite strata are retained as
an alternate representation; generic two-dimensional GPL integration can require
conversion of GPLs with letters depending on the next integration variable.

Treat dependent original products narrowly. For factors independent of virtual
loop momentum, AFTER the proved source-level external limit, a relation
`Sum[c_j G_j] = c0 + Sum[d_a C_a]`, c0 nonzero, permits source-level partial
fractions on original UNIT particle cuts. Example:
`1/(s12 s13 s23) = (1/(s12 s13)+1/(s12 s23)+1/(s13 s23))/s`.
It does not apply unchanged to dotted cuts. Subsequent families keep unrestricted
original denominator definitions.

If a dependence involves virtual denominators, their finite causal regulator
enters the relation as `c0+i delta Sum[c_j eta_j]`. The new external proof cannot
remove that term. Keep those products pending a justified causal representation,
or use the finite-stratum route instead.

Optional diagnostic improvement: store per-target Reduced / ExplicitZero /
DeclaredIdentity / Unresolved status and declaration origins. Do not put identity
self-rules into recursive rewrite rules. This needs no additional native solve
or content hash.
