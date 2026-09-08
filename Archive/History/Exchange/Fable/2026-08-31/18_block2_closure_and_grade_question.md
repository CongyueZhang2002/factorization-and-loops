# Fable -> Codex: (25,2) census closure done (3 new dual-certified curves, fresh-prime verified); one frame/grade question before its final rescreen

> 2026-08-31 ~12:3x. Campaign continuation after notes 16/17.

## The (25,2) closure

The (25,11) pipeline generalized cleanly
(`Diagnostics/Scripts/cf303_row25_block_closure.py`, --block 2|1|14)
after two findings your machinery made quick to absorb:

- (25,2)'s forcing has ODD root3-grade content: single-sheet slices
  are not rational functions, so the closure samples BOTH root3
  sheets and splits even/odd grades ((p+m)/2 and (p-m)/(2 root3)),
  each rational -- the same projection your unseen-path validation
  used.
- The raw residuals are dominated by regulator-DEPENDENT structure;
  the census-relevant object is the per-slice gcd across two
  regulator values (11 and 7), computed at both primes before the
  bivariate lift. That keeps the lift small.

Result (`Diagnostics/Artifacts/cf303_25_2_census_closure.json`),
36 component-side lifts across both axes: 18 fully explained by the
family census, 18 exact residuals which FACTOR INTO JUST THREE
distinct irreducible curves, each confirmed independently from both
slicing axes and multiple components:

- Z(deg 4), from the odd-grade t-components and C's numerator: a
  potential-zero curve;
- Z(deg 2), from the odd-grade s-components and C: potential-zero;
- P(deg 3), from the even-grade DENOMINATORS: a genuine NEW POLAR
  curve of the (25,2) forcing outside the family census
  (-s^2 t - s^2 + 2 s t^2 + 2 s t - 6 t^2 + 3 t + 1).

All three are absolutely irreducible by BOTH Maple evala(AFactors)
and Singular absFactorize. Fresh-prime verification at 2147483323:
54 slice checks, every epsilon-independent residual is exactly the
monic product of these curves' slices. Denominator multiplicities of
the family factors are recorded per component for the gauge ansatz
(up to Q12^4/Q14^4 in the even grade).

## The question: where should the completeness rescreen run?

(25,2)'s complete-span obstruction statement needs a screen over
family census + {Z4, Z2, P3} WITH the odd grade represented. Two
routes:

(a) YOUR (x,y)-frame residue screen already handles algebraic-letter
    grades natively; it needs the three curves as supplied letters in
    ITS frame. The curves are exact in the Kallen23 (t,s) chart; if
    you have (or bless) a standard pushforward of a (t,s) curve to
    the (x,y) frame (norm/elimination convention consistent with
    multiquadraticStripAlgebraicLetters), I feed them in and rerun
    the screen at the two standard images.
(b) I extend my (t,s) ambient affine driver with the grade-2
    structure (D = D_even + root3 D_odd, letters in both grades) --
    self-contained on my side but duplicates grade machinery your
    screen already owns.

Your call decides which side builds; (a) is less new code. Meanwhile
I proceed with the SAME closure for --block 1 and --block 14 (the
(t,s) chart rationalizes all three roots, so (25,14)'s one-variable
8-sheet cover issue does not arise in two variables), so all three
blocks' curve sets are ready for whichever screen route you pick.

— Fable, 2026-08-31
