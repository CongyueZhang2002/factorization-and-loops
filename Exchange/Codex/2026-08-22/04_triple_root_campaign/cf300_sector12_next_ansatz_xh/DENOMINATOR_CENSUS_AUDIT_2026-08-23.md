# CF300 sector-12 denominator census launch audit

Date: 2026-08-23  
Scope: External-only driver; no Wolfram launch and no package change

## Verdict

The original driver was source/cache-bound and syntactically well structured,
but its candidate predicate did not isolate the factors omitted by
`TRRationalGaugeDenominator`.

That denominator is constructed from the rational channels of the forcing
block (`BBar`): a forcing pole of maximum order `p` requires gauge exponent
`max(p-1,0)`.  In particular, the deliberately omitted simple-pole set is

```text
BBar maximum denominator exponent = 1
gauge denominator exponent = 0
factor is epsilon-free and kinematics-dependent.
```

The original census instead took the maximum exponent over `E`, `C` and
`BBar` together and admitted factors that occurred only in a diagonal block.
It could therefore report contextual diagonal letters as if they were
factors dropped by the forcing-denominator rule, or miss a forcing simple
pole when another source carried a higher exponent.

The patched driver now computes per-source exponent maxima and uses the exact
forcing predicate above.  Diagonal-only simple poles remain available under
the explicitly diagnostic `ContextualDiagonalSimplePoleCandidates` key, but
they are not promoted as omitted forcing factors.

## Additional hardening

- For every forcing factor, the driver checks that the current gauge exponent
  is at least `max(p-1,0)`.  A deficit at a higher-order pole returns the typed
  failure `GaugeDenominatorMissingRequiredHigherPoleFactor`; it cannot be
  mislabeled as the intentional simple-pole omission.
- Denominator, channel-factor and gauge-factor SHA-256 groups receive exact
  canonical-polynomial collision checks before deduplication or association
  construction.
- Canonical factors must lie strictly in `Q[epsilon,x,y]`; undeclared symbolic
  coefficients are rejected.  The selected canonical pivot is rechecked to
  be exactly one after normalization.
- Gauge canonicalization now fails before factorization is attempted.
- The output records the candidate definition, per-source exponents, expected
  minimal gauge exponent, deficit, exact candidates and separate contextual
  diagonal candidates.
- The existing immutable cache SHA, source hashes, driver hash, atomic fresh
  output and end-of-run source/cache stability checks remain intact.

## Launch interpretation

Only `EpsilonFreeSimplePoleCandidates` should be sent to the denominator
rebind/witness screen.  The compatibility key name is retained, but it now
means precisely the omitted forcing set.  `ContextualDiagonalSimplePoleCandidates`
may inform a later resonance test; it is not evidence that the minimal
forcing denominator dropped that factor.

An empty exact candidate set returns the typed terminal status
`NoOmittedEpsilonFreeForcingSimplePoleCandidates`.  This is deliberately not
silently promoted to a passed nonempty-candidate artifact.

## Static verification

`test_denominator_census_static.sh` checks delimiter balance, immutable
cache/artifact validation, collision guards, the per-source forcing rule,
the `p-1` gauge invariant, candidate conditions, atomic/source-stability
guards, and absence of process or parallel-kernel entry points.

Result: `DENOMINATOR_CENSUS_STATIC PASS 26/26`; an independent
string/comment-aware delimiter scan and `bash -n` also passed.

Pinned audit hashes:

- original driver: `0e13ca101839caf9a95cd1ab4cb150500436aaa179caad93967f1873996bc0f6`
- patched driver: `1bf0c237c488268ccdd32f48a65da4fc7516c2bf2e723a479a619ceb3be751af`
- static test: `6f134b773936966e585119e898b4511aa8e132c9041ec1352df12ffb532ec4a0`

No dynamic mathematical result is claimed until the patched driver runs in
the managed pool.
