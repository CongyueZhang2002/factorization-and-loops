# Certified family epsilon-form inventory, 2026-08-20

The single ground-truth inventory now exists. Any campaign's family
discovery must read it; a family listed Exact there is never re-solved.
This implements the requirement in your handoff correction (recognize a
result by its mathematical certificate, not by the directory that
generated it).

## Where

- `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/FamilyEpsFormsCertified/`
  — 54 records, each RECOMPUTED from the family differential system by
  `FeynFacet`CertifyFamilyEpsilonForm` (chart identities, both
  inverses, complete gauge identity in both variables, source and
  transformed flatness, epsilon factorization, constant-residue dlog
  reconstruction; no stored verdict is ever trusted).
- `certification_report.wl` in the same directory: per-family status,
  measured seconds, and per-candidate diagnostics for the failures.
- Census run: 91 families, 1 main + 8 subkernels, 1628 s wall,
  zero unexpected failures.

## Result by certificate

- one-root: 31/31 Exact.
- two-root: 10/13 Exact — including all nine sector-route records
  (CF23, CF48, CF52, CF232, CF236, CF240, CF254, CF319, CF321), which
  were REWRITTEN today to carry the absolute transformation
  TTotal = diag(T_class) . S (`TTotalBasis -> "SourceChartConnection"`);
  the previous records stored only the sector gauge S relative to the
  assembled connection and could never pass an absolute certification.
- zero-root: 15/44 Exact; 29 are transport-only (masters solved, no
  family epsilon form).
- Incomplete (37, all expected): the 29 zero-root above (17 never
  attempted + 12 GateFailed on the old two-variable Moser route),
  CF231/CF265/CF305, CF385/CF408, CF259/CF300/CF303 (triple-root).

## Two defects found and fixed today (why past certifications failed)

1. Context poisoning: certifying any family loads CANONICA; every later
   bare `Get` in the same kernel parsed eps/x/y into `CANONICA\``, so
   only the FIRST family of a batch ever certified. Fix: all artifact
   reads go through `FeynFacet`FamilyArtifactRead` (context-guarded),
   and both CANONICA loaders now restore `$ContextPath`.
2. Relative transformation: sector-route records stored TTotal = S.
   Fixed at the writer (`Scripts/family_epsform_sector.wls` composes
   the diagonal-block layer; cached checkpoints that predate it re-run
   the assembly) and all nine existing records upgraded from their
   checkpoints (2–5 min each).

## Note on CF385/CF408

Your blockwise results are finished analytic objects and their check
flags are complete, but the `factor_dependence_*` schema carries no
`TTotal`/`EpsFormX` keys, so certification rejects them typed
(`RequiredMatricesMissing`). Two options, either is fine with us:
(a) you write standard-schema records for them (keys as in any
sector-route record, transformation absolute against the chart-pulled-
back source connection), or (b) we add a schema adapter after
confirming the semantics of `RawTransformation` vs `Transformation`
against the checkpoint's `SystemX` frame. Until then they stay
correctly listed as incomplete by certificate, though solved in
substance.

## Also today

The four rung modules got an independent review (verdict: FIX, no
rewrite; two blockers repaired: the parallel CANONICA degree search
kept only the last-completed degree — a misplaced bracket — and the
undefined `SymbolQ` guard that could let a specialized-regulator check
certify). All module tests green. The Maple-vs-finite-field
apples-to-apples benchmark harness is ready
(`Scripts/benchmark_strip_backends.wls`), pending fixture extraction —
per the agreed protocol: same coupling record, 1 Wolfram kernel + 2
external cores, fresh finite-field artifacts, split prep/solve timers.
