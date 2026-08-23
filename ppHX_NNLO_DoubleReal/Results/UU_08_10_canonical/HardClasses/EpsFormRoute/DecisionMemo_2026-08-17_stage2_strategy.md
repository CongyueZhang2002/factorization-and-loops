# Decision memo: stage-2 strategy after three external reviews (2026-08-17, ~11:15 PDT)

Inputs: `Consult_2026-08-17_stage2_strategy.md` and the three replies —
`FableMax_reply_2026-08-17_stage2_strategy.md` (FM),
`../../../../../External/CodexExchange/codex_assessment_stage2_strategy_2026-08-17.md` (CX),
`GPTPro_reply_2026-08-17_stage2_strategy.md` (Pro; user caution: framed
by the planar-amplitude literature — weigh its program-level advice
against our different end product, stage-4 distributional data at the
strata and master-level cross-checking against Codex's parallel
derivation). Status: campaign PAUSED; nothing below is started until
the user signs off.

## 1. Settled by three-way convergence (no further debate needed)

C1. The consult's own §4 self-diagnosis was WRONG: class-first
    canonicalization was not the structural mistake. All three treat
    the 173 class forms as valid capital — the diagonal seeds. The
    global-347-basis option (C) is rejected by all three.
C2. THE cure for the measured bottleneck is the off-diagonal completion
    of each family's eps-form BEFORE transport. FM and CX write the
    same equation (dD - eps(E D - D C) = B - B_can, T = 1 + D); Pro
    calls it "the literature-standard correction" and adds the negative
    result we should stop looking for: no transport package makes
    non-canonical couplings cheap.
C3. By-parts transport at depth >= 2 is retired from production; do not
    raise its timeouts (all three). Keep it as certification
    cross-check and tripwire (FM).
C4. The sparse Chen representation and the measured scales (weights
    <= 7, <= 11k words, <= 46 MB) are sane (FM Q7, Pro §7; CX silent =
    no objection). The 46 transported families stand — except families
    transported THROUGH deep by-parts should be regenerated through the
    purified basis before stage 3/4 consumption (FM Q7 risk 1).
C5. Series/numeric engines (DiffExp/SeaSyde/AMFlow) are evaluators and
    checks only, never the analytic product (all three).
C6. Economy of columns: transport the physical boundary subspace
    (1 + q columns after nullity), not full fundamental matrices, for
    expensive families (Pro §6; FM and the 2026-08-16 reviews; CX #7).
    Ordering: boundary nullity -> physical columns -> transport.
C7. The triple-root families are NOT obstructed (FM, CX): algebraic
    letters without rationalization, segment-wise/mixed charts,
    per-chain charts are all legitimate; the genus test is the only
    theorem-level stop (FM); up to seven roots handled in the
    literature (CX: arXiv:2501.07490).

## 2. The one open mechanism choice — resolved by one experiment

HOW to complete the off-diagonal eps-form:
  - FM: solve the graded exactness equation DIRECTLY (choice-free
    entrywise primitives per eps-order; residues at eps-deformed loci
    vanish by closedness; cycling impossible by construction). Tools
    are overhead; Libra only a comparator.
  - CX: use the established implementations — Libra CORRECTLY (all
    prior negatives void per the Projector trap; it can reduce
    off-diagonal blocks modulo the irreducible polynomial, no root
    splitting), CANONICA as the slow reference; and if a rational gauge
    does NOT eliminate a locus, the structural fix is upstream: master
    re-selection sector-by-sector (arXiv:2002.08042, 2002.08173;
    2503.19837 cured near-identical symptoms this way), with
    finite-field reconstruction of D if expressions swell (FiniteFlow).
  - Pro: agnostic on the tool; confirms the stage.

DECISION RULE (proposed): run the corrected-Libra retry AND the direct
graded solve on the same two systems — CF230 (certified family form
exists = ground truth; entrywise diff possible) and CF124 (worst
measured TimedOut datum, 971 s for one order) — under the same exact
purity gate. Adopt whichever passes the gate and is cheaper/more
robust; the loser stays as the cross-check (satisfying C3's tripwire
role and the two-tool discipline). If BOTH fail to remove a locus by a
rational gauge, that is the (and only the) trigger for CX's master
re-selection in the affected sectors — not before, because re-selection
costs new Kira reductions + re-derived family DEs per sector.

## 3. Pro's novel items — positions (with the user's caution applied)

P1. Observable-submodule projection (transport only the row module of
    the hard-coefficient rows; rank r by finite-field sampling first).
    ADOPT AS A CHEAP RANK PROBE ONLY (their step 1-4, no symbolic
    reconstruction): it is exactly the "transport only what the
    observable sees" economy the earlier reviews asked for, and the
    probe is discarded for free if r ~ N. CAUTIONS: (i) the c-rows must
    be the SUBTRACTED assembly's coefficients, or the rank is about the
    wrong object; (ii) the deliverable the user set is the MASTERS
    (cross-checked against Codex's parallel derivation, consumed at the
    strata by stage 4), so even a transformative r << N would make this
    an ADDITIONAL route for the generic-kinematics part of H, not a
    replacement for master-level artifacts at the strata; (iii) it must
    wait for the purified bases anyway (same A_mu).
P2. Shared function basis per alphabet/chamber (pentagon-function
    style). DEFER. The deduplication argument is real (91 families,
    173 shared classes), but this is an amplitude-program deliverable;
    our word counts are not the bottleneck (C4), and stage 3/4 design
    (endpoint modes, strata) should drive any basis choice. Revisit
    after boundary constants exist. Pro's own Experiment 3 (compression
    ratio on the 46 done families) is a cheap diagnostic to run when
    idle — informative, not blocking.
P3. One-fold integral representations above weight ~4. KEEP IN POCKET.
    Correct escape hatch if a purified family still blows up in word
    count; none of the 46 measured artifacts needs it (C4). Do not
    build a backend for a problem we have not measured.
P4. Tier I/II/III layering (canonical spec / shared coordinates /
    consumer forms). ADOPT TIER I FORMALLY at zero cost: our per-family
    artifact already contains {T, letters, residues, symbolic
    constants, path, chart}; add the explicit chamber/branch record and
    declare it the primary analytic deliverable (this also implements
    FM's Q7 risk 2: anchor and branch conventions declared once,
    globally). Tiers II/III follow stage-3/4 needs, not the other way
    around.

## 4. Codex's novel item — position

CX-M. Master re-selection ("good masters") in affected sectors.
    CONTINGENCY, triggered only by the §2 decision rule failing, OR by
    a purified family that still transports expensively (then the basis
    is bad in a way no gauge fixes). Independent 30-minute prep that is
    worth doing regardless: the literature diff of our family/master
    definitions against published ancillaries (2503.19837 semi-inclusive
    cuts; Mistlberger-lineage) — it serves BOTH the re-selection (import
    good bases instead of searching) and FM's Q8 support-condition
    check.

## 5. Other adopted resolutions from FM (unopposed by CX/Pro)

R1. +1 safety: strict N = -val for bulk transport stands; the genuine
    +1 consumer is the DISTRIBUTIONAL endpoint expansion (delta
    coefficient needs one more order of ENDPOINT data), paid at the
    strata by the local Frobenius construction, not by deeper bulk
    transport. PREREQUISITE CHECK (30 min): provenance of
    MasterCoefficientValuations — before or after distributional
    expansion of measure/subtraction factors (trace the eps^-4 and one
    eps^-2 column).
R2. Acceptance: co-signed, with the per-order DE check RE-STATED IN THE
    CANONICAL FRAME made mandatory (it is the only end-to-end test that
    touches the strips; cheap after purification), plus (i) a
    cross-family consistency assertion for shared masters via the
    registry, (ii) 2-3 AMFlow/DiffExp spot values per family, labeled
    outside the proof chain.
R3. Registry hygiene NOW (cheap, prevents a stage-3 trap): integration
    constants keyed BY MASTER, not by (family, master); one global
    declaration of path anchor (the soft/collinear corner where stage-3
    constants live) and branch/deck conventions per chart family.

## 6. Proposed execution order (awaiting user go-ahead; nothing started)

E1. Corrected-Libra retry on CF230 + CF124 (pool missions, ~1 h) —
    the FM+CX converged experiment. Verdict recorded either way.
E2. Direct graded-primitive gauge (design already written up, task #9)
    on the same two systems; exact purity gate; on CF230 diff against
    the certified family form.
    -> Decision per §2 rule; then purify the ~30 blocked non-triple
    families with the winner and re-run the sweep (route 2), including
    REGENERATION of the few families that went through deep by-parts.
E3. In parallel (cheap, independent): R1 provenance check; CX/FM
    literature diff; FM's triple-root census (chain root map, ordering
    retry, genus test); R3 registry hygiene.
E4. After purification: P1 rank probe on CF258 (subtracted c-rows,
    finite fields); Pro's Experiment 3 compression diagnostic on idle
    kernels.
E5. Stage 3 (boundary constants) then proceeds on the purified bases
    with the nullity-first column economy (C6).

Rejected for now: global 347 basis (all three), function-basis
construction before stage-3 design (P2), one-fold backend without a
measured need (P3), any timeout increase for by-parts (C3), replacing
master-level artifacts by the submodule route (P1 caution ii).
