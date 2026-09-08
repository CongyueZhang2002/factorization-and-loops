# Fable assessment: the two unresolved two-root classes (CF231 (8,7) / CF254 (9,8))
Date: 2026-08-19. Read: PRO_REVIEW_REQUEST.md, the full solver source, the
CF254 strip record, the Maple logs. Pro's reply is pending; this review is
independent and should be cross-checked against it when it lands.

## What the current method already does right
Row coupling through CANONICA's NextEquationD (previousD.cmix in bbar);
free residue entries carried into Maple as unknowns c[1001..] (the CF48
lesson, applied); exact both-variable re-checks; the request itself asks
the two right hard questions (Q1 row coupling, Q7 affine space).

## Gap 1 (most likely the actual blocker): affine freedom is discarded twice
(a) Solver line "parameterRules = Join[parameterRules,
Thread[remainingParameters -> 0]]": every parameter the CURRENT strip does
not determine is zeroed. Undetermined-by-this-strip is not arbitrary --
those parameters are exactly the freedom later strips in the same row (and
the sector's dlog->eps normalisation) may need. This is CF48's "setting it
to zero removes the rational solution" one level up. Fix: keep
remainingParameters symbolic in the row state; zero only at row end if
still free.
(b) ExactRationalConnectionSolution's fast path REJECTS any candidate with
homogeneous constants (nops(constants) != 0 -> next). The hard strips are
hard precisely because the Hom(C,E) connection is resonant there -- which
is when rational HOMOGENEOUS solutions exist -- so Mratsolde returns an
affine family and the wrapper discards a solvable case. Fix: accept the
affine space; the second equation's conditions on the constants are LINEAR
-- impose them instead of demanding uniqueness.

## Gap 2: the strip-level target may be over-constrained
CF48's own solved strip has K_a = P(eps)/eps^3 x integers -- NOT
"constant" residues. If the residue solve restricts K_a's eps-dependence
(the request text says "constant matrices K_a"), hard strips whose dlog
prefactors carry resonant eps-poles will read "no gauge" falsely. The
safe target per strip is the DLOG FORM (K_a rational in eps), with the
eps-normalisation done per sector by TransformDlogToEpsForm -- CANONICA's
own two-stage split. Verify which one the code enforces; if the stronger
one, weaken it.

## Gap 3 (the decisive instrument; answers their Q2/Q3/Q4): per-divisor
## local analysis instead of any ansatz sweep
For the vectorised connection M_mu = eps(E_mu (x) 1 - 1 (x) C_mu^T), the
local exponents at each letter W_a (and at infinity in each variable) are
eps (lambda_E - lambda_C) sums -- computable in minutes for 1x2/2x2 strips.
Then: (i) sharp pole bound of R at W_a divisor-by-divisor (their
D = (Prod W_a)^p is simultaneously too big -- letters where Hom(C,E) is
regular need power 0 -- and possibly too small -- one resonant letter can
need a higher power than 3); (ii) an EXISTENCE decision: the local Laurent
conditions at all divisors + the global degree count assemble into one
finite linear system in the numerator coefficients, the free K entries,
and the homogeneous constants -- solvable iff a rational gauge exists in
this chart. This is the Barkatou-Cluzeau denominator-bounding that
Mratsolde performs internally in ONE variable, done divisor-wise in both.
It replaces the (p,q) grid entirely (retire it, do not instrument it).
On their Q4: a one-variable Mratsolde failure certifies nonexistence only
for the GIVEN K and source; with free K carried and the affine space kept,
a two-orientation failure of the assembled linear system IS a certificate.

## Gap 4: two cheap structural alternatives absent from their list
(a) INVOLUTION PULLBACK: lambda_2 = lambda_1(-v,w), lambda_3 =
lambda_1(v,-w); the Kallen23/Kallen13 charts are exact sign/swap
involutions of Kallen12, whose two-root class IS solved. Check whether an
exact family map conjugates a solved class's completed strips into these
two classes -- the stage-1 precedent (T_77 = T_eq . sigma* T_97) cost one
afternoon and eliminated a "hard" class outright. They already use family
maps WITHIN a class (CF305 from CF231); the CROSS-class involution is the
untried move and the single cheapest possible resolution.
(b) TARGETED BALANCES: if Gap-3's census shows an integer resonance at a
specific divisor, one Libra balance between the two diagonal blocks'
exponents at that divisor shifts the spectrum by +-1 and can convert
"no rational gauge" into "exists" -- legitimately (balances preserve
eps-form diagonals). FuchsifyFinite/Infinity remove higher poles; they do
NOT perform resonance-shifting balances. This is the standard cure for
exactly this obstruction in Lee's algorithm.

## Gap 5: the negatives are not yet evidence-grade (their own caveat)
Timeouts killed the candidate ledgers; CF231's orientation 2 never ran; a
16854 s run "reported no exact gauge" without a per-candidate record. By
the house rule (a negative needs evidence like a positive), the current
state is UNDECIDED, not unsolvable. The cure is Gap 3's certificate, not
longer time limits.

## Priority order (minimal wasted runtime)
1. (~0.5 h) Involution pullback across Kallen12/13/23 vs the solved class.
2. (~1 h) Per-divisor exponent census on both strips: resonances + sharp
   pole bounds; decides existence for the current (E, C, Bbar).
3. If resonant: one targeted balance at the offending divisor; re-run the
   strip (minutes).
4. Else: ONE sparse exact linear solve (both equations at once, per-divisor
   denominators, free K and homogeneous constants retained; modular +
   rational reconstruction only if entries swell -- the degree-10, 12-digit
   strip data says they might).
5. Keep affine freedom in the row state (drop remainingParameters -> 0
   until row end); accept affine Maple solutions.
6. Retire the (p,q) grid.
