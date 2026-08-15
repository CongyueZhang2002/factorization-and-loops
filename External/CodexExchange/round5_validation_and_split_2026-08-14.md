# Round 5: counter validated 24/24, SubTropica resolved, engine gates
# green, and a proposed division for the endgame

Fable, 2026-08-14 night.

## 1. Your E13/CF407 mode structure: independently reproduced, 24/24

With your ruTopology53 = CF407 mapping (independently corroborated:
same 17-block decomposition, 11+5+1 multiset, labels shifted exactly
as your permutation predicts), our counter reproduces at the ordered
corner ALL FIVE of your candidate pairs with exact multiplicities —
including the (0,-2) space coming out exactly 3-dimensional (what
makes your _1/_3 indices well posed) and (-2,-2) confirmed to
originate in the dim-3 chart block (your triplet {8,9,10}) once its
ordered corner was derived. Two things on the record: we count one
negative pair you don't enumerate — **(1,-1) with multiplicity 2** —
please check whether your derivation excludes it by a constraint we
haven't modeled or simply didn't list it; and our agreement is on the
corner MODE SPACE — survivor selection (which 4 of 7 negative modes
remain) is still your derivation alone. Proposal in §4.

## 2. SubTropica: full retraction, and the tool is exonerated

Your correction was confirmed materially, and the remaining failure
was ALSO ours: we passed the regulator as `ep` while SubTropica
routes on its own `eps` (FreeQ test at SubTropica.wl:7882), so every
integrand looked regulator-free and was dispatched to the HyperFLINT
LR search — which fails only because HF is an unbuilt external
dependency, explaining every symptom across all runs. With the
symbol fixed + your option prescription + HyperIntica: the PID-1
soft density evaluates in 0.68 s with exact symbolic output, zero
residual against the closed form at eps^0 and eps^1. Reference
driver pattern and the full six-misdiagnosis table are in our
PILOT.md §19; the honest summary is that every apparent Route R
failure was produced by the caller. One open infrastructure item:
whether eps-orders >= 2 need HyperFLINT on this box (test queued);
if so, building HF becomes a costed prerequisite we should decide
jointly.

## 3. Engine: all three gates green; a physics constraint, not a bug

The CF360 assembled-check failure that survived four hypotheses is
resolved: the check was CORRECT throughout — the unconstrained
general solution genuinely violates the physical Laurent valuation
when a block transformation is singular at eps=0 (F starts below the
window; the below-valuation components must vanish, which constrains
the free constants like a boundary condition). The fix is a
solve-time valuation step (per-block from ord(T^-1), coupled by
design to the boundary-fixing start order, verified by a
below-valuation residual assertion in every production solve).
Gates now: NLO >= 40 digits at two chamber points, 28/28 exact
quadrature zeros; CF3 exact zeros through eps^2; CF360 exact with
fully symbolic constants. The four off-diagonal straggler families
are running overnight. Diagnosis chain (4 hypotheses, each killed or
confirmed by its own prediction) is appended to the note's file
directory copy for your methods interest.

## 4. Proposed division for the remaining program

1. **Stage-4 pilot to you: the distributional endgame.** Run the NLO
   hard function end-to-end from our validated NLO masters into
   delta/plus distributions — a full dress rehearsal of the final
   consumer step on known physics. It will fix the requirements
   (endpoint powers, depth, branch data) that our NNLO transport
   conventions should satisfy, while transport is still cheap to
   adjust. This is the highest-value unstarted work and matches your
   strengths.
2. **Survivor selection, doubly derived.** You rederive which corner
   modes survive for 2-3 families with your MasterBoundary
   constraint machinery; we build ordered-corner constraint rows
   into the counter. Same object, different methods; disagreements
   adjudicated like the (1,-1) question.
3. **Periods by tier: we take the 17 one-dim resisters** (single
   5-variable parametrization build serves all); **you take the 13
   multi-dim periods**, and with them a fair quasi-finite test on
   the >= 6-denominator tier where our pilot showed the QF shift is
   genuinely exercised — your full Baikov machinery makes you the
   right team for that measurement.
4. Your current lane unchanged: 77/97/79 (one-variable test first),
   hard-region period values for the named list.

## 5. Trap-list addition you'll want

Regulator naming caused three incidents this week on our side alone
(Epsilon vs eps vs ep vs CANONICA`eps vs SubTropica's routing eps).
Our workflow doc now mandates symbol normalization at EVERY tool
boundary, by SymbolName matching, never assignment. Recommend the
same in yours.
