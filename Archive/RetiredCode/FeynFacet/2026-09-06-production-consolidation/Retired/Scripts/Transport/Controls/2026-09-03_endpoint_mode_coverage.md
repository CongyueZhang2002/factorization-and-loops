# Physical endpoint-to-interior campaign coverage

The current observable transports start at regular interior points.  A
singular-endpoint Frobenius vector is therefore **not** an
`OperatorAutomaton` boundary vector.  The campaign adapter implements

\[
  \beta = L\sum_{a,b} I_a^{(1)} I_b^{(2)}
    \epsilon^{|a|+|b|}R_aR_b c,
\]

where the endpoint-second segment is traversed first, the endpoint-first
segment second, and `L` is one deterministic exact left inverse of the
automaton's final boundary embedding.  `E.L` is required only on the complete
endpoint-word sum; CF299 demonstrates that it is false on separate word
coefficients.  The adapter therefore keeps endpoint Chen words separate and
never identifies `c` with the regular-base vector.

## Bounded controls

- Historical endpoint modes:
  `/home/maxzhang/factorization-and-loops-codex/External/CodexExchange/endpoint_matching_2026-08-17/BoundaryModeMap_CF299.wl`
  and `BoundaryModeMap_CF407.wl` in the same directory.
- Historical two-segment controls:
  `/home/maxzhang/factorization-and-loops/Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17/`.
- Current observable inputs:
  `/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/ObservableTransport_2026-09-01_codex/families/`.

CF299 needs endpoint connector weight 3.  Sparse reachability leaves 325
candidate and 263 nonzero word maps; its endpoint residue and every stored
regular-series coefficient agree exactly with the historical Frobenius
control.  Its old and new quotient word decompositions do not agree term by
term, as expected: only their completed endpoint-word sums lie in the regular
interior boundary subspace.

CF407 needs connector weight 2.  It has 24 reachable/nonzero word maps.  Its
endpoint residue, stored regular series, zero-word physical map and both
first- and second-segment one-forms agree exactly with the accepted historical
control.  The combined bounded test takes about 12 seconds on one queued main
kernel.

## The 20 current period classes

The authoritative class ledger is
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BoundaryPeriods/LEDGER.md`.
Only CF299 and CF407 have an on-disk `EndpointSpec`, `EndpointFrobenius` and
normalized `BoundaryModeMap`.  A local realization is not silently identified
with a ledger class: formal coefficients default to the realization key
`{family, PeriodID}` unless an exact class identity is supplied.

| PID | ledger representative | ledger value | concrete endpoint mode on disk | batch status |
|---:|---|---|---|---|
| 1 | CF1 | exact zero | none | missing mode map |
| 2 | CF123 | unevaluated | none | missing endpoint spec and mode map |
| 3 | CF123 | unevaluated | none | missing endpoint spec and mode map |
| 4 | CF124 | unevaluated | none | missing endpoint spec and mode map |
| 5 | CF124 | unevaluated | none | missing endpoint spec and mode map |
| 6 | CF124 | exact zero | none | missing mode map |
| 7 | CF124 | exact zero | CF299, exact transfer | ready as a known-zero CF299 realization |
| 8 | CF199 | unevaluated | CF299 local mode | formal CF299 map only; class transfer unchecked |
| 14 | CF212 | unevaluated | none | missing endpoint spec and mode map |
| 15 | CF212 | unevaluated | none | missing endpoint spec and mode map |
| 16 | CF236 | unevaluated | none | missing endpoint spec and mode map |
| 17 | CF236 | unevaluated | none | missing endpoint spec and mode map |
| 21 | CF267 | unevaluated | none | missing endpoint spec and mode map |
| 22 | CF267 | unevaluated | none | missing endpoint spec and mode map |
| 23 | CF267 | unevaluated | CF407 local mode | formal CF407 map only; class transfer unchecked |
| 24 | CF267 | unevaluated | none | missing endpoint spec and mode map |
| 28 | CF384 | unevaluated | none | missing endpoint spec and mode map |
| 30 | CF385 | unevaluated | none | missing endpoint spec and mode map |
| 31 | CF413 | unevaluated | none | missing endpoint spec and mode map |
| 32 | CF415 | unevaluated | none | missing endpoint spec and mode map |

The CF299 historical control additionally contains local modes labelled 9 and
25; neither is one of the current 20 ledger classes.  They remain
realization-local formal constants.

## Exact missing input per unready realization

Each remaining family needs a physical endpoint/branch specification,
`t = alpha rho^kappa`; a Frobenius mode in the same canonical frame as the
current transport; its epsilon valuation and demanded rows; and, when a ledger
class is shared, an exact realization-transfer map.  If the accepted mode is
not annihilated by the endpoint residue, the missing input also includes a log
branch and the physical-to-local factor
`Exp[epsilon Log[alpha] R_rho/kappa]`.  The adapter refuses such nonzero or
Jordan modes until that factor and tangential-log transport are supplied.
