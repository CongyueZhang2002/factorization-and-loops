# Codex assessment of Consult_2026-08-17_stage2_strategy.md — received 2026-08-17 ~10:45 PDT (verbatim relay from the user; Codex was encouraged to read through the literature)

[Session notes in brackets; reconciliation against
`EpsFormRoute/FableMax_reply_2026-08-17_stage2_strategy.md` at the end.
Nothing has been acted on: the user paused the campaign until ALL
external replies (GPT Pro pending) are read.]

Yes. The literature indicates that Fable is attacking transport one stage too early.

Main Finding
The community normally does not transport a block-triangular system whose diagonal blocks are canonical but whose off-diagonal couplings still contain higher-order poles and eps-dependent apparent singularities.
For a family connection

    dI = ( eps C   0  ) I
         (   B   eps E )

one first seeks a block-unitriangular transformation

    I = ( 1  0 ) J
        ( D  1 )

such that

    dD - eps (E D - D C) = B - B_can,

where B_can is logarithmic and proportional to eps. Only then is the family transported. This is precisely the off-diagonal recursion implemented by CANONICA and related algorithms. [CANONICA: inspirehep 19554e80e2c31e5af77d45d157c5b5d0], [Lee's reduction algorithm: arXiv:1411.0911].
Fable's 173 class eps-forms are therefore not wrong. They are the diagonal input to this equation, not the final basis in which transport should occur.

What We Missed
The most important missing stage is probably master-basis improvement before family canonicalization.
A recent calculation of semi-inclusive cut integrals through four loops encountered almost exactly Fable's symptoms:

* dimension-dependent kinematic poles;
* irreducible quadratic denominators;
* spurious poles in off-diagonal blocks;
* severe canonicalization times.

The authors generated neighboring candidate masters by raising propagator powers or inserting numerators, changed the master basis sector by sector, and thereby removed the quadratic artifacts before applying Fuchsia. [Semi-inclusive massless four-loop cuts: arXiv:2503.19837].
This is established more generally in:

* [How to choose master integrals: arXiv:2002.08042], which explains why the master basis returned by IBP reduction is often analytically poor.
* [Factorization of denominators in IBP reductions: arXiv:2002.08173], which selects masters so that eps-dependent denominator factors separate from kinematics.

I therefore infer that Fable's eps-dependent apparent loci are likely properties of the chosen Kira/class basis, rather than intrinsic singularities of the integrals.

Roots And Charts
The absence of one chart rationalizing all three roots is not enough to declare the three triple-root families obstructed.
It is sufficient, but not necessary, to rationalize every root simultaneously. Different rationalizations can be used for different pieces provided they describe the same physical integration path and branches are matched exactly. Examples with as many as seven roots have been treated this way. [Feynman integrals with multiple square roots: arXiv:2501.07490].
Other valid choices are:

* retain algebraic dlog letters without rationalizing them;
* use different charts on consecutive path segments;
* use a loop-by-loop Baikov representation to identify a pure basis before choosing coordinates. [UT integrals from Baikov leading singularities: arXiv:2103.04638].

Thus Fable's "no common rational chart" condition is too restrictive.

Recommended Route

1. Retry Libra correctly on a complete assembled family. The earlier negative Libra results are invalid because of the `Projector` problem.
2. Use the full irreducible denominator polynomial. Libra can reduce off-diagonal blocks algebraically modulo an irreducible polynomial; it need not first split that polynomial into path roots. [Libra: arXiv:2012.00279].
3. Test two families:
   * CF230, whose full family eps-form is already known;
   * one unresolved family with an eps-dependent apparent locus.
4. If Libra does not eliminate the locus, generate alternative masters in the affected sectors and rank them by: absence of mixed (eps, kinematics) denominator factors, lower off-diagonal pole order, and simpler determinant letters.
5. For the remaining difficult family, construct pure candidates from maximal cuts or Baikov leading singularities, reduce them back to the IBP basis, and derive the family connection again.
6. If symbolic expressions swell, reconstruct the block correction D over finite fields. This remains exact analytic reconstruction, not numerical evaluation. [FiniteFlow: arXiv:1905.08019].
7. Transport only after obtaining either:

    dJ = eps Sum_alpha M_alpha dlog W_alpha J,

   or, at minimum, an exactly Fuchsian off-diagonal system suitable for variation of constants.

Verdict
Fable does not need one global basis for all 347 masters. It needs one coherent basis for each coupled family, with the relative off-diagonal transformations determined. The current class bases remain useful as diagonal seeds.
The highest-value immediate experiment is the corrected Libra calculation on CF230 and one unresolved family. The highest-value structural change is inserting a good-master selection stage before spending more time on transport. Increasing the current path-transport timeouts is unlikely to solve the underlying problem.

---

[RECONCILIATION vs Fable Max's reply (session notes, 2026-08-17 10:50):

CONVERGENT (both reviewers, independent):
1. The class eps-forms are valid capital — the diagonal seeds; the
   mistake is transporting before the off-diagonal completion, NOT the
   class-first ordering itself. (Both explicitly reject the consult's
   §4 self-diagnosis and option (C), the global 347-master basis.)
2. The off-diagonal completion is THE missing stage, and it is the SAME
   equation in both replies: dD - eps(E D - D C) = B - B_can (Codex) is
   exactly Fable Max's graded exactness solve for T = 1 + D.
3. The corrected Libra retry (post-Projector-trap) on an assembled
   family is the highest-value immediate experiment; run it on CF230
   (ground truth exists) + one unresolved family (CF124 per Fable Max).
4. By-parts transport at depth >= 2 and bigger timeouts are the wrong
   tools (both; Fable Max: "retire from production", Codex: "unlikely to
   solve the underlying problem").
5. Triple-root families are NOT obstructed: algebraic letters without
   rationalization, segment-wise/mixed charts, per-chain analysis are
   all legitimate (Codex adds arXiv:2501.07490, seven roots; Fable Max
   adds the genus test as the theorem-level stop condition).

DIVERGENT (the real decision, once GPT Pro's reply is in):
A. THE CURE for the eps-deformed loci.
   - Fable Max: solve the graded equation DIRECTLY (choice-free
     entrywise primitives per eps-order; residues at apparent loci
     vanish by closedness; no iteration, no tool) — CANONICA's recursion
     is generality overhead; Libra is only an empirical comparator.
   - Codex: use the established implementations (Libra, correctly; can
     work modulo the irreducible polynomial without splitting roots),
     and if the locus survives, the STRUCTURAL fix is upstream:
     re-select masters sector-by-sector (2002.08042, 2002.08173,
     2503.19837 saw nearly identical symptoms) so the loci never enter
     the connection at all.
   These are complementary, not contradictory: the gauge (or Libra)
   fixes the connection in the CURRENT basis at transport cost; master
   re-selection removes the artifact at source but costs new Kira
   reductions + re-derived family DEs per affected sector, and would
   also simplify stages 3/4. The decisive experiment (Libra on CF230 +
   CF124) discriminates: if the loci are eliminated by a rational gauge,
   basis re-selection is optional simplification; if not, it is the
   route.
B. Codex's basis-improvement stage has no counterpart in Fable Max's
   reply (which implicitly assumes the current basis stays); Fable Max's
   Q5 (+1 only at strata), Q6 (acceptance additions), Q7 (anchor
   conventions, constants keyed by master) and Q8 (support condition +
   literature diff of the master set vs published ancillaries) have no
   counterpart in Codex's. Note the interaction: Codex's literature diff
   candidates (2503.19837 semi-inclusive cuts; Mistlberger-lineage
   ancillaries) serve BOTH Fable Max's Q8 shortcut check and Codex's
   master re-selection (published good bases for overlapping sectors
   could be imported rather than searched for).

STATUS: no action taken; awaiting GPT Pro's reply, then a three-way
decision memo.]
