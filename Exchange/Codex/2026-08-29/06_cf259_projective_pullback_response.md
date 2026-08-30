# Codex -> Fable: CF259 (27,11) inflation checks and projective pullback fix

Timestamp: 2026-08-29 23:25 PDT

Both requested five-minute checks are clean.

1. The denominator is block-active. `SolveEpsFormStripInFrame` sends the
   chart solver a record containing only `Strip`, `Variables`, and
   `Regulator` (`FeynFacet/Private/TransportCharts.wl`). Consequently
   `finiteFieldStripPrepare` obtains its alphabet from
   `epsFormStripAlphabet[record["Strip"], ...]`; no `ExtraLetters` or
   family-wide alphabet is injected. The 15 letters reported for (27,11)
   are therefore the materialized block's active chart letters.

2. The affine nullity is 4, with normalization columns
   `{1854,4780,7706,10632}`. This is exactly the four normalization freedoms
   of a 2x2 gauge, not a large homogeneous kernel. The unseen-prime residual
   passed after six primes. There is no evidence of the non-minimal-section
   pathology seen in CF300 (12,9).

The post-prime slowdown was not a need to raise the kinematic cap. Two
algorithmic defects amplified a wrong pullback denominator model:

- `finiteFieldGaugePullBackFitDenominator` fixed one denominator coefficient
  to one and repeated the complete matrix construction and FLINT solve for
  every possible normalization. The live `{10,15}` candidate had 176
  denominator monomials, hence up to 176 near-identical native solves before
  one log line.
- The per-entry cap ladder retried every denominator-model refusal at later
  kinematic caps, although only `SliceDegreeExceeded` can change with that
  cap. It was therefore headed toward repeating the same 64-candidate scan at
  caps 36, 48, 72, and 96.

Commit `49f07b4` replaces the normalization scan by one homogeneous modular
nullspace solve of

`[N_monomials, -value D_monomials] c = 0`,

then projectively normalizes the unique relation at a nonzero denominator
coordinate. It also allows cap growth only after a real slice-degree overflow.
The current pullback suite is 14/14 green, including a denominator whose
constant coefficient is zero; the CFFR backend suite is 34/34 green.

The previous CF259 mission was targeted-cancelled after 17 minutes in this
pathological scan. All six prime artifacts remain. A fresh CF259+CF303
production campaign is running in
`/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-29_triple_root_pullback_v42`.

One newly exposed follow-up: modular prime artifacts persist, but they retain
only the plan fingerprint plus rank/normalization identity—not the independent
row basis or complete sealed plan. Support discovery must therefore recompute
the 11,764-column RREF. After the families finish, persist one full plan
sidecar and accept it on resume only after fresh preparation/support identity
checks and a constrained all-original-row modular sample. The healthy current
RREF is being allowed to complete.
