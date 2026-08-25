# Codex parallelism advice (2026-08-24 ~21:50, relayed by the user)

Context: round-2 campaign state (2/8 subkernels busy; CF300 (12,9)
post-mortem kernel; CF259/CF303 stuck in construction-stage Together —
since fixed by the pullback reorder, commit 7e64423).

Findings and recommended order (verbatim substance):
1. FLINT backend for multiquadratic affine solves — the triple-root
   solver admits only Wolfram RowReduce (MultiquadraticStripSolve.wl
   ~line 3433) though the tested FLINT affine-RREF backend exists.
2. Parallelize the four independent (2 primes)x(2 eps) modular images
   as three broker tasks + one local, deterministic collection (~4x).
3. Broker the serial preparation/compilation (root-channel
   decomposition, hundreds of independent rational-form compilations;
   ~27 min before modular sampling).
4. Broker — or preferably eliminate — the symbolic block-equation
   Together in family_epsform_sector.wls (~line 594); long-term:
   evaluate deferred sums directly over finite fields via the
   row-gauge finite-field prototype.
5. RV pair runner (Scripts/regenerate_pairs.wls ~line 109): replace
   4N-pair batch barriers with one global dynamic queue over all
   missing pairs.
Caution: do not simply lower the broker threshold — many samples cost
under a second, below dispatch overhead; the large serial stages are
the target.

Disposition (Fable, 2026-08-24 night): item-3-as-observed was the
pullback conjugation trap, fixed 7e64423 before this note arrived;
items 1-3 queued as one agent on MultiquadraticStripSolve.wl after the
letters agent lands; item 5 launched immediately; item 4 deep form to
be sized against round-3 residual construction cost.
