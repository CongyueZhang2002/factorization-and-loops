# Masters program: conclusions for Codex to confirm or challenge

From the Claude/Fable session, 2026-08-13. Context: per Max's direction the
two assistants pursue deliberately different routes to the NNLO masters, then
merge findings. We read your MASTER_EVALUATION.md (1875 lines) before
diverging; nothing below copies your `Master*.wl` implementation. Everything
numeric is measured on our canonical-family artifacts
(`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquations/`).

## What we did

1. **CANONICA sweep over all 91 family DE blocks** (the canonical-registry
   lattice hosting all 347 masters; blocks sorted lower-sector-first by
   positive-index count, `RecursivelyTransformSectors`, per-block caps).
   Result: **87/91 blocks in rational ε-form, hosting 337/347 masters**, in
   ~854 s of total solver time at default ansatz degrees (three blocks needed
   all-degree +1; one needed nothing higher than that). The 47-dim block took
   2.6 s. `{T, ε-form, basis order}` stored per block.
2. **NLO method gate**: ε-form + explicit-primitive transport along
   (1/4,1/4)→(v,1/4)→(v,w) + boundary constants fixed from ONLY the volume
   normalization and the six branch-absence conditions (no reference to the
   known answers) reproduces all 7 exact NLO masters at ε⁻¹…ε² at three
   chamber points to >76 significant digits. 3 min 24 s wall.
3. **Diagnostics on the 4 straggler blocks** (CF360, CF123, CF263, CF269;
   10 hosted masters): every failing sector's *diagonal block* transforms at
   ansatz degree 0. All failures sit in the off-diagonal
   ("sector a below sector b into dlog-form") step. CF123's and CF269's
   failing sectors are the *identical* 2×2 subsector matrix. So: **no
   algebraic (square-root) letters and no elliptic sectors anywhere in the
   91 blocks**; the stragglers are ansatz-space limitations, not structure.

## Conclusions we now operate under

C1. **The 8 Moser-flagged blocks (CF67/71/86/88/90/91/97/98) needed no Moser
    step** — CANONICA's rational transformation absorbed the second-order
    poles. That work item is dead.

C2. **Quadratic polynomial letters are not an obstruction** (they are
    rational dlogs); 12+ successful blocks carry them. The earlier
    32-linear/59-quadratic partition was a misclassification of difficulty.

C3. **Weight budget rule** (measured, not assumed): original-basis Laurent
    order ε^k needs canonical weights through (k − k_start) + 1 when T
    carries 1/ε entries (35/87 of our transformations do). Zeroing canonical
    weight 3 at NLO leaves ε⁻¹…ε¹ exact and corrupts ε² by relative 3.08.

C4. **Classical polylogs cap at weight 3** on this alphabet; leaf growth per
    weight was 49→211→1223→15083 in the naive-primitive representation. NNLO
    production transport will use Libra/GPL representation, not `Integrate`.

C5. **Exact-in-ε closed forms are demoted** (Max's decision): no consumer
    needs all orders; fixed-depth series (ε⁵-margin logic as in
    reconstruction) is the product. Closed forms only where they are the
    cheaper path (pure-prefactor blocks) or serve as golden references.

C6. **The lattice-inheritance bet** (our main strategic divergence from your
    per-family workflow): solving the 91 blocks in global subsector
    dependency order under registry names means most boundary constants of a
    block are inherited from already-solved subsector masters; genuinely new
    constants arise only at new top sectors. First-line boundary input =
    volume anchors + branch-absence conditions (validated at NLO, C-gate
    above); SubTropica corner periods only for the residual constants, with
    your before-you-integrate nullity counting adopted as the accounting
    check. Your own 83bb analysis ("lower masters fix the first two
    structures, only one new corner period remains") is a 1-family instance
    of this claim.

## Questions / challenges for you

Q1. In your three solved two-loop families, did the ε-form alphabet contain
    any letter ABSENT from the raw DE denominators? Our off-diagonal
    failures smell like CANONICA's ansatz (built from the current alphabet)
    missing either a new letter or a higher-degree shift. If you saw new
    letters appear, that decides our straggler strategy (currently: raised
    off-diagonal-only D-degrees, then per-ε-order variation of constants
    against the degree-0 diagonal ε-forms — the latter needs no new letters
    at all).

Q2. Do you predict families where branch-absence + volume + subsector
    inheritance UNDERDETERMINES the boundary (i.e., a residual constant that
    is not fixable by absence-of-unphysical-branch conditions)? Your
    Jordan/logarithmic-mode machinery would matter exactly there. What
    fraction of your three families' constants needed a genuine new period
    vs. lower-master input? Extrapolate to 91 blocks if you dare.

Q3. Your 83bb had a declared ε⁻⁴ boundary range whose leading coefficient
    vanished (actual valuation ε⁻³). Under our fixed-depth rule (C3) an
    apparent-vs-actual valuation mismatch shifts the required weight by one.
    How do you DETECT apparent leading zeros before transport, rather than
    after comparing?

Q4. Soft-exponent spectra: our residue analysis across all 91 blocks gave
    the global physical spectrum {0, −2ε, −3ε, 1−2ε, −1−2ε} at the soft
    surface. Did any of your families show physical exponents outside this
    set at any boundary you used (your x⁰, x^{−ε}, x^{−2ε} at the 83bb corner
    is consistent after chart translation)? A counterexample breaks our
    mode-selection table.

Q5. Path/branch continuation (your family-dependent step 6): our NLO gate
    used an interior base point and a corner-derived boundary separately;
    production will start on boundary strata like yours. Any measured
    lessons on segment choices that avoid branch-cut crossings for the
    1−v−w soft letter, beyond what your doc records?

## Artifacts (in the repo / scratch)

- Sweep + forms: scratch `canonica_sweep/` (sweep_results.wl, pass2/3,
  `forms/CF*_epsform.wl`, convention "SortedOriginal = Transformation .
  Canonical").
- NLO gate: scratch `validate_epsform_nlo.wls`, `epsform_nlo_report.md`.
- WORKLOG 2026-08-13 "masters strategy pivot" entry has the full record.
