# CORRECTION IN PROGRESS: CF303 45-master GPL/eMPL transport

Date: 2026-08-31 21:38 PDT

Late pre-commit audit invalidated the original completeness claim.  The weighted
operator is correct for the supplied deck, but that deck omitted exception
blocks `{1,2,11,14,18}` (seven source-master columns), and the explicit output
has not yet been convolved with the accepted block-25 source gauge.  Do not
consume the current artifact as a complete or physical result.

## Recovery update — 22:42 PDT

- All 14 omitted entries have now been reconstructed from the authoritative
  accepted gauges on the same direct-`u` quartic path.  All three root images
  are exact and no residual radicals remain.
- Blocks 2 and 14 have completed exact quotient/Hermite reduction.  All six
  entries have nonzero exact primitives; block 14 also has elliptic remainder
  letters.  Therefore the old residue-only completion is mathematically
  insufficient.
- The shortest correction is a finite path-only triangular gauge.  Writing
  `F25=G25+H L`, `dL=eps S L`, `dF25=eps D F25+B L`, its recurrence is
  `B'_n=B_n+D H_(n-1)-H_(n-1) S-dH_n`.  At each order, exact Hermite reduction
  supplies `H_n` and the dlog remainder.  Normalize `H_n(u0)=0`, so the
  canonical boundary constants do not change.
- The block-2 leading-order pilot is accepted for both entries:
  `B'_-2=B_-2-dH_-2` is exactly the 16-letter GPL remainder and
  `H_-2(u0)=0`.  The complete gauge needs orders `-2..4` for target output
  through `eps^2`.
- The 43-master source operator was rebuilt with the required source and
  boundary orders through `eps^4`: 244 boundary columns instead of the
  incomplete 158-column window.  This remains lazy and does not enumerate
  words.
- Blocks 18 and 11 are still reducing; block 1 is queued behind them.  Pro is
  independently reviewing the connection-gauge route in the existing
  “Assess Multiquadratic Pipeline” conversation.

## Superseded partial-deck result

For the 76-entry `SolvedForms` subset only, the census gave:

- 76/76 accepted entries;
- zero exact primitives;
- zero eta2 letters;
- 72 incoming entries with rational-in-epsilon residues of valuation `-2`;
- four diagonal entries exactly linear in epsilon;
- 33 distinct quartic GPL/eMPL letters.

Those figures do not cover the 14 exception entries and must not be promoted
to a statement about the complete block-25 row.

## Completed layers

- Block 15: 39 entries, 23 letters, zero primitives/eta2, five constant
  homogeneous generators.
- Block 17: 23 entries, 27 letters, zero primitives/eta2, one generator.
- Block 21: 48 entries, 27 letters, zero primitives/eta2, three generators.
  Its bounded quadratic projector completed in about 16.8 minutes wall with
  2.79 GB peak RSS; the discarded global route had exceeded 15.7 GB before
  entry 10.
- Block 25: six diagonal forms compress to three constant generators.

## Provisional partial operator and explicit output

The partial operator uses the exact final-layer grammar
`D...D` or `D...D B_r S...S`.  It builds in 0.289 s and stores 225 incoming
residue matrices, 5,990 nonzero incoming coordinates, 143 internal letters,
and 164 boundary columns.  A separate full weighted-residue construction
agrees on six boundary/diagonal/incoming/mixed word cases.

Explicit standard simple-point output for rows 44--45 is materialized at:

- `eps^-4`: 15 GPL/eMPL terms;
- `eps^-3`: 404 terms;
- `eps^-2`: 9,107 terms.

Factor letters are split at output into algebraic points denoted
`CF303Root[f,k]`.  The 24 MB ancillary contains no `GPLFactor`, `E4Factor`,
compressed-letter, unevaluated-integral, or master-integral heads.  Higher
orders remain exact and lazy; an eager `eps^-1` dump crosses the intentional
20,000-internal-word cap.

Provisional report:

`/home/maxzhang/factorization-and-loops-codex/Diagnostics/Reports/CF303_FINAL45_ELLIPTIC_TRANSPORT.md`

Principal final artifacts:

- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_final45_lazy_elliptic_operator_15_17_21.wl`
- `/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_final45_low_order_materialization.wl`
