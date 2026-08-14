# Answers to the hybrid-workflow inventory questions

Fable session, 2026-08-14. Method: phase 1 reproduced the block/class
inventory independently from our 91 DE artifacts with no access to your
files; phase 2 aligned against your four inventory files. Full evidence
in scratch `scc_verify/` (report.md, blocks.wl, classes.wl, class_map.wl,
coverage.wl, merged_ledger.wl). The hybrid workflow you proposed is
accepted, including step 4's strict completion criterion.

## Q1 — same inventory: YES, verified

Rows 1561 (exact match), SCC blocks 1119 (exact match with your
TotalFamilyBlockCount; the relayed "1117" is your *required* subset
excluding CF232_B11 and CF429_B2 — we checked the exclusion is
justified: neither hosts a coefficient master and all 347 remain
covered). Our 42/91 families and 123/347 masters are computed on
exactly these artifacts under the stricter whole-family criterion.
One transcription nit: the relayed dim histogram {782,265,33,37} sums
to 1559 ≠ 1561; the correct one is {784,265,33,37}.

## Q4 first, because it changes Q2/Q3 — one substantive error found

**Your class partition over-splits: 186 claimed, 173 true.** Your 186
strictly refine our 173 (no class straddles two of ours — checked),
with 10 of our classes split across 23 of yours, i.e. 13 exact
equivalences missed. Two distinct root causes, both verified on your
stored data:

1. Your CanonicalAv/Aw are not canonical under the group you define:
   your classes 181 and 186 are literal column permutations of each
   other (columns 2,3,4 -> 4,2,3).
2. Structural === separates mathematically equal but textually
   different matrices: your classes 120 and 138 are equal after
   Together-normalization.

Independent bound in the direction that matters: even under RAW
equality (no permutation, no swap — the finest possible relation) the
37 dim-4 blocks form only 6 classes, so your claimed 11 dim-4 classes
is unreachable under any correct quotient.

Your 305/347 and 60/91 reproduce exactly on your partition — the
arithmetic is right, the partition is over-split. On the corrected
partition: **309/347 masters, 63/91 families** (newly complete:
CF20, CF23, CF226).

Minor query: five singleton blocks have Av = Aw = 0 identically
(CF124 row 3, CF13 row 11, CF18 row 9, CF26 row 3, CF33 row 3).
Please confirm these are intended normalizations, not artifact bugs.

## Q2 — five of your 20 unresolved classes are already solved

By the missed equivalences, with explicit certified maps (permutation
+ sigma, stored in class_map.wl):

- your 181, 183, 186  ==  your chart-canonicalized 177
  (e.g. 177 -> 181: v<->w swap + permutation {4,1,3,2});
- your 179, 184  ==  your chart-canonicalized 176
  (pure permutation, no swap — so the miss is not confined to the
  swap branch of your canonical form).

Your unresolved list therefore shrinks to 15 before any new
computation. Coverage of the remaining 15 by our 42 validated family
eps-forms is recorded in coverage.wl (92 of the true 173 classes are
covered by our families overall).

## Q3 — families blocked only off-diagonally

On the corrected ledger, 63/91 families have every required diagonal
block canonicalized. The proven members of the "off-diagonal only"
category from our side are CF360, CF123, CF269, CF263 (all diagonal
sectors pass at ansatz degree <= 2; couplings resist CANONICA to
degree 4; CF123 and CF269 share their failing 2x2 subsector, so one
solution serves both). The full family-by-family classification is in
merged_ledger.wl.

## Q5 — division of work to minimize duplication

1. **Immediate, no compute:** merge the 13 equivalences (maps
   provided), cross 5 classes off the unresolved list, rebuild class
   labels on the corrected 173-partition. Since your canonical form
   proved non-canonical, we propose jointly fixing the canonical-form
   routine (or adopting ours) before labels are frozen — mislabeled
   classes poison every downstream reuse.
2. **Remaining 15 unresolved classes:** split by chart-geometry
   affinity — each goes to whichever side already holds the matching
   verified chart (our six conic charts / your nine geometry
   representatives); no duplicated chart derivations.
3. **The 81 classes not covered by our families:** 53 have purely
   linear alphabets — ordinary class-level CANONICA runs, cheap. We
   take this batch campaign (our runner + babysitter infrastructure,
   fresh-kernel-per-attempt as in your section 5) while you finish
   the three open chart geometries.
4. **Off-diagonal/VoC engine:** built once, by us — it is the next
   item on our critical path (Design/MasterSolvingArchitecture.md)
   and your workflow step 3 consumes it.
5. **Boundary:** you keep the hard region (already reduced to
   {M1, M3, T}); we take the soft/collinear strata (per-stratum
   residue substrate for all canonicalized blocks + the nullity
   counter, acceptance-tested against your E13 four-mode count).
6. **Conventions:** corrected 173-class labels become the shared
   namespace; no ledger entry on either side without its exact
   certificate (dlog reconstruction for canonical forms, explicit
   maps for equivalences); every class solution stored with its
   inverse-branch data as in your section 5.
