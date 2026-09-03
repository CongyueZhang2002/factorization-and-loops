(* Transport of a final layer whose incoming connection is rational in the
   regulator.

   System dF = A F, A = [[S, 0], [B, D]] on a one-dimensional path in the
   variable u: the source connection S = eps Sum S_i w_i and the final-
   layer diagonal D = eps Sum D_a w_a are dlog with constant residue
   matrices; the incoming connection B(eps, u) = Sum_n eps^n B_n(u) du is a
   rational function of eps whose orders are rational one-forms that are
   NOT dlog.  The path gauge F_T = G + H F_S with H(base) = 0 removes the
   non-dlog part order by order,

     K_n = B_n + D_1 H_(n-1) - H_(n-1) S_1 - dH_n,   K_n dlog,

   H_n the Hermite primitive of Omega_n = B_n + D_1 H_(n-1) - H_(n-1) S_1
   and K_n its residue part on the declared pole alphabet; G then obeys
   dG = D G + K F_S and a word reaching the final rows has exactly one
   incoming letter, D...D K_r S...S (or D...D on the target boundary).
   A genuinely u-dependent recurrence is executed as a sealed circuit over
   F_q[u]: leaves are specialized first, K and the endpoint value of H are
   reconstructed across primes and validated at a fresh prime.  If all
   incoming coefficients are independent of u, the exact dlog residues are
   read directly and H vanishes.  Singular endpoints remain a typed refusal
   until tangential regularization data are implemented.  On a declared
   square-free quartic Y^2=P4, the same modular recurrence uses coefficient
   pairs for h0+h1 Y and f0 du+f1 du/Y and reduces the elliptic component to
   square-free pole letters plus the three genus-one cohomology letters.
   No family name appears here. *)

Clear[BuildRationalEpsilonLayerTransport, AcceptedRationalEpsilonLayerTransportQ];
ClearAll[
  rationalLayerLetterFormQ,
  rationalLayerCurveLetterFormQ,
  rationalLayerLetterFunction,
  rationalLayerLetterPair,
  rationalLayerCurvePointValue,
  rationalLayerResidueKey,
  rationalLayerResidueLabel,
  rationalLayerAlphabetGate,
  rationalLayerPoleFactors,
  rationalLayerModularFunction,
  rationalLayerModularPolynomial,
  rationalLayerReconstructFunction,
  rationalLayerGaugeFunctionCheck,
  rationalLayerHermite,
  rationalLayerEllipticHermite,
  rationalLayerPartialFractions,
  rationalLayerRecurrenceImage,
  rationalLayerCurveRecurrenceImage,
  rationalLayerSourceStates,
  rationalLayerTargetSelectors,
  rationalLayerWords,
  rationalLayerCertificateShapeQ,
  $rationalLayerCurveLetters,
  $rationalLayerRationalLetters
];

$rationalLayerRationalLetters = {"GPLPole", "GPLFactor"};
$rationalLayerCurveLetters = {"E4Pole", "E4Factor", "E4Omega0", "E4OmegaInf", "E4Eta2"};

(* ---- alphabet ------------------------------------------------------- *)

(* A letter label: {"GPLPole", c} is du/(u - c); {"GPLFactor", q, k} is
   u^k du/q(u) with q square-free and k < deg q.  Curve letters are
   recognised, and admitted only with a declared quartic curve. *)
(* A pole position must be rational.  Algebraic conjugates are represented
   root-free by one GPLFactor letter on their minimal polynomial. *)
rationalLayerLetterFormQ[{"GPLPole", c_}, u_] := MatchQ[c, _Integer | _Rational];
rationalLayerLetterFormQ[{"GPLFactor", q_, k_Integer}, u_] :=
  PolynomialQ[q, u] && Exponent[q, u] >= 1 && 0 <= k < Exponent[q, u] &&
  VectorQ[CoefficientList[q, u], MatchQ[#, _Integer | _Rational] &] &&
  Exponent[PolynomialGCD[q, D[q, u]], u] === 0;
rationalLayerLetterFormQ[___] := False;

rationalLayerCurveLetterFormQ[{"E4Pole", c_}, _] :=
  MatchQ[c, _Integer | _Rational];
rationalLayerCurveLetterFormQ[{"E4Factor", q_, k_Integer}, u_] :=
  rationalLayerLetterFormQ[{"GPLFactor", q, k}, u];
rationalLayerCurveLetterFormQ[{"E4Omega0"}, _] := True;
rationalLayerCurveLetterFormQ[{"E4OmegaInf"}, _] := True;
rationalLayerCurveLetterFormQ[{"E4Eta2"}, _] := True;
rationalLayerCurveLetterFormQ[___] := False;

rationalLayerLetterFunction[{"GPLPole", c_}, u_] := 1/(u - c);
rationalLayerLetterFunction[{"GPLFactor", q_, k_Integer}, u_] := u^k/q;

(* A function is h0+h1 Y and a one-form is f0 du+f1 du/Y.  Pair entries
   below are their rational coefficient functions {base, elliptic}. *)
rationalLayerLetterPair[label : {head_, ___}, u_, curve_, pointValues_Association] /;
    MemberQ[$rationalLayerRationalLetters, head] :=
  {rationalLayerLetterFunction[label, u], 0};
rationalLayerLetterPair[{"E4Factor", q_, k_Integer}, u_, _, _] := {0, u^k/q};
rationalLayerLetterPair[{"E4Pole", c_}, u_, _, pointValues_Association] :=
  {0, Lookup[pointValues, c, Missing["CurvePointValue", c]]/(u - c)};
rationalLayerLetterPair[{"E4Omega0"}, _, _, _] := {0, 1};
rationalLayerLetterPair[{"E4OmegaInf"}, u_, _, _] := {0, u};
rationalLayerLetterPair[{"E4Eta2"}, u_, curve_, _] :=
  {0, u^2 + Coefficient[curve, u, 3] u/(2 Coefficient[curve, u, 4])};

rationalLayerCurvePointValue[point_, curve_, u_, declared_Association] := Module[
  {value = Together[curve /. u -> point], candidate},
  candidate = Lookup[declared, point, Automatic];
  If[candidate === Automatic, candidate = Sqrt[value]];
  If[! MatchQ[candidate, _Integer | _Rational] ||
      Together[candidate^2 - value] =!= 0,
    Missing["CurvePointValue", point], candidate]
];

(* Rational keys retain the historical {order,factor,power} ABI.  Curve
   letters are opaque in the second slot and retain the same three-field
   shape, so lazy consumers can distinguish the channels without expanding
   polynomial factors into marked points. *)
rationalLayerResidueKey[order_, {"GPLFactor", factor_, power_Integer}] :=
  {order, factor, power};
rationalLayerResidueKey[order_, label_List] := {order, label, 0};
rationalLayerResidueLabel[{_, factor_, power_Integer}] /; ! ListQ[factor] :=
  {"GPLFactor", factor, power};
rationalLayerResidueLabel[{_, label_List, _Integer}] := label;

rationalLayerAlphabetGate[labels_List, u_Symbol, curve_] := Module[
  {verdicts},
  verdicts = Table[Which[
      ! ListQ[label] || label === {},
        <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
          "Reason" -> "not a labelled letter"|>,
      MemberQ[$rationalLayerRationalLetters, First[label]],
        Which[
          rationalLayerLetterFormQ[label, u],
            <|"Label" -> label, "Status" -> "Admitted", "Channel" -> "Rational"|>,
          MatchQ[label, {"GPLPole", c_ /; NumericQ[c] && ! MatchQ[c, _Integer | _Rational]}],
            <|"Label" -> label, "Status" -> "AlgebraicPoleNotAdmitted",
              "Reason" -> "pole position is algebraic; declare the conjugate pair as a GPLFactor letter on its minimal polynomial"|>,
          True,
            <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
              "Reason" -> "malformed rational letter (pole must be a rational number, factor square-free with rational coefficients, power below the degree)"|>],
      MemberQ[$rationalLayerCurveLetters, First[label]],
        Which[
          curve === None,
            <|"Label" -> label, "Status" -> "CurveDeclarationRequired"|>,
          ! PolynomialQ[curve, u] || Exponent[curve, u] =!= 4 ||
            ! VectorQ[CoefficientList[curve, u], MatchQ[#, _Integer | _Rational] &] ||
            Exponent[PolynomialGCD[curve, D[curve, u]], u] =!= 0,
            <|"Label" -> label, "Status" -> "CurveNotQuartic",
              "Reason" -> "the declared curve must be a square-free quartic polynomial in the path variable"|>,
          ! rationalLayerCurveLetterFormQ[label, u],
            <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
              "Reason" -> "malformed elliptic letter"|>,
          True,
            <|"Label" -> label, "Status" -> "Admitted", "Channel" -> "Curve"|>],
      True,
        <|"Label" -> label, "Status" -> "AlphabetLetterNotAdmitted",
          "Reason" -> "unknown letter head"|>],
    {label, labels}];
  If[AllTrue[verdicts, #["Status"] === "Admitted" &],
    <|"Status" -> "AlphabetAdmitted", "Verdicts" -> verdicts,
      "Channels" -> DeleteDuplicates[Lookup[verdicts, "Channel"]]|>,
    Join[SelectFirst[verdicts, #["Status"] =!= "Admitted" &],
      <|"Verdicts" -> verdicts|>]]
];

(* The pole alphabet: the square-free factors over Q of the letter
   polynomials and of the denominators of the incoming coefficient
   functions, pairwise coprime, monic. *)
rationalLayerPoleFactors[letters_List, coefficients_List, u_Symbol] := Module[
  {polynomials, factors},
  polynomials = Join[
    Cases[letters, {"GPLPole", c_} :> u - c],
    Cases[letters, {"GPLFactor", q_, _} :> q],
    Cases[letters, {"E4Pole", c_} :> u - c],
    Cases[letters, {"E4Factor", q_, _} :> q],
    Denominator[Together[#]] & /@ coefficients];
  factors = DeleteDuplicates[Flatten[Cases[FactorList[Times @@ polynomials],
    {f_, _} /; ! FreeQ[f, u] :> f]]];
  factors = DeleteDuplicates[Expand[#/Coefficient[#, u, Exponent[#, u]]] & /@ factors];
  Select[factors, Exponent[#, u] >= 1 &]
];

(* ---- F_q[u] arithmetic ---------------------------------------------- *)

(* a rational function of u with rational coefficients as {numerator,
   denominator} polynomials over F_q, denominator monic; $Failed when a
   coefficient denominator vanishes at q *)
rationalLayerModularFunction[expression_, u_Symbol, prime_Integer] := Module[
  {together, numerator, denominator, lead},
  together = Quiet[Check[Together[expression, Modulus -> prime], $Failed]];
  If[together === $Failed, Return[$Failed]];
  numerator = Numerator[together]; denominator = Denominator[together];
  If[! PolynomialQ[numerator, u] || ! PolynomialQ[denominator, u] ||
      PolynomialMod[denominator, prime] === 0, Return[$Failed]];
  lead = Coefficient[denominator, u, Exponent[denominator, u]];
  If[Mod[lead, prime] === 0, Return[$Failed]];
  {PolynomialMod[numerator PowerMod[lead, -1, prime], prime],
   PolynomialMod[denominator PowerMod[lead, -1, prime], prime]}
];
(* A polynomial over Q reduced into F_q coefficient by coefficient; built-in
   modulus arithmetic does not consistently normalize rational coefficients. *)
rationalLayerModularPolynomial[expression_, u_Symbol, prime_Integer] := Module[
  {coefficients = CoefficientList[Expand[expression], u]},
  If[MemberQ[Mod[Denominator /@ coefficients, prime], 0], Return[$Failed]];
  Expand[Total[MapIndexed[
    Mod[Numerator[#1] PowerMod[Denominator[#1], -1, prime], prime] u^(First[#2] - 1) &,
    coefficients]]]
];

(* Lift one monic rational-function image from several primes.  Hermite
   primitives are stored as {numerator,monic denominator}, so their
   polynomial coefficients have a common, prime-independent normalization.
   This is used only when the path endpoint must remain symbolic. *)
rationalLayerReconstructFunction[images : {{_, _} ..}, primes : {__Integer},
    u_Symbol] := Module[
  {numeratorDegree, denominatorDegree, lift, numeratorCoefficients,
   denominatorCoefficients, numerator, denominator},
  If[Length[images] =!= Length[primes], Return[$Failed]];
  If[AllTrue[images, #[[1]] === 0 &], Return[0]];
  numeratorDegree = Max[Exponent[#[[1]], u] & /@ images];
  denominatorDegree = Max[Exponent[#[[2]], u] & /@ images];
  lift[part_, degree_] := Table[
    With[{residues = Table[Coefficient[images[[index, part]], u, power],
        {index, Length[images]}]},
      With[{crt = modularCRT[residues, primes]},
        If[crt === $Failed, $Failed,
          modularRationalReconstruct[crt, Times @@ primes]]]],
    {power, 0, degree}];
  numeratorCoefficients = lift[1, numeratorDegree];
  denominatorCoefficients = lift[2, denominatorDegree];
  If[! FreeQ[{numeratorCoefficients, denominatorCoefficients}, $Failed],
    Return[$Failed]];
  numerator = numeratorCoefficients . u^Range[0, numeratorDegree];
  denominator = denominatorCoefficients . u^Range[0, denominatorDegree];
  If[denominator === 0, $Failed, numerator/denominator]
];
rationalLayerReconstructFunction[___] := $Failed;

(* One held-out prime and one regular random point certify the lifted gauge.
   This is deliberately pointwise: production does not rematerialize a
   characteristic-zero polynomial identity merely to check the lift. *)
rationalLayerGaugeFunctionCheck[exact_Association, image_Association,
    orders_List, u_Symbol, prime_Integer, seed_Integer] := Module[
  {points, point = None, exactValue, imageValue, comparisons = 0,
   mismatches = 0, regularQ},
  points = BlockRandom[SeedRandom[seed + prime];
    RandomInteger[{2, prime - 2}, 32]];
  regularQ[candidate_] := And @@ Flatten@Table[
    With[{e = exact[order][[i, j]], f = image[order][[i, j]]},
      Mod[Denominator[Together[e]] /. u -> candidate, prime] =!= 0 &&
      Mod[f[[2]] /. u -> candidate, prime] =!= 0],
    {order, orders}, {i, Length[exact[order]]},
    {j, Length[First[exact[order]]]}];
  point = SelectFirst[points, regularQ, None];
  If[point === None,
    Return[<|"Status" -> "GaugeValidationPointUnavailable"|>]];
  Do[
    exactValue = With[{value = Together[exact[order][[i, j]]] /. u -> point},
      Mod[Numerator[value] PowerMod[Denominator[value], -1, prime], prime]];
    imageValue = With[{f = image[order][[i, j]]},
      Mod[(f[[1]] /. u -> point) PowerMod[f[[2]] /. u -> point, -1, prime],
        prime]];
    comparisons++;
    If[exactValue =!= imageValue, mismatches++],
    {order, orders}, {i, Length[exact[order]]},
    {j, Length[First[exact[order]]]}];
  <|"Status" -> "GaugeFunctionChecked", "Point" -> point,
    "Comparisons" -> comparisons, "Mismatches" -> mismatches|>
];

(* Hermite reduction over F_q (Horowitz-Ostrogradsky): f = N/D proper ->
   f = d(Bp/Dstar)/du + C/Dminus with Dminus square-free; the polynomial
   part is integrated separately.  Returns <|"Primitive" -> {Bp, Dstar}
   plus polynomial primitive, "Remainder" -> {C, Dminus}|> or $Failed. *)
rationalLayerHermite[{numerator_, denominator_}, u_Symbol, prime_Integer] := Module[
  {quotient, remainder, dStar, dMinus, m, n, bSym, cSym, unknowns, tSym,
   equation, solution, bPoly, cPoly, polynomialPrimitive, coefficients},
  {quotient, remainder} = PolynomialQuotientRemainder[numerator, denominator, u, Modulus -> prime];
  polynomialPrimitive = If[quotient === 0, 0,
    PolynomialMod[Integrate[quotient, u] /. Rational[a_, b_] :> Mod[a PowerMod[b, -1, prime], prime], prime]];
  If[Exponent[denominator, u] === 0,
    Return[<|"Primitive" -> {polynomialPrimitive, 1}, "Remainder" -> {0, 1}|>]];
  dStar = PolynomialGCD[denominator, D[denominator, u], Modulus -> prime];
  dStar = PolynomialMod[dStar PowerMod[Coefficient[dStar, u, Exponent[dStar, u]], -1, prime], prime];   (* monic, asserted rather than assumed *)
  dMinus = PolynomialQuotient[denominator, dStar, u, Modulus -> prime];
  m = Exponent[dStar, u]; n = Exponent[dMinus, u];
  If[m === 0,
    Return[<|"Primitive" -> {polynomialPrimitive, 1}, "Remainder" -> {remainder, dMinus}|>]];
  (* remainder = B' Dminus - B T + C Dstar,  T = Dminus Dstar'/Dstar *)
  tSym = PolynomialQuotient[dMinus D[dStar, u], dStar, u, Modulus -> prime];
  bSym = Array[Unique["rlB"] &, m]; cSym = Array[Unique["rlC"] &, n];
  unknowns = Join[bSym, cSym];
  bPoly = bSym . u^Range[0, m - 1]; cPoly = cSym . u^Range[0, n - 1];
  equation = Expand[D[bPoly, u] dMinus - bPoly tSym + cPoly dStar - remainder];
  coefficients = CoefficientList[equation, u];
  coefficients = PadRight[coefficients, Exponent[denominator, u], 0];
  solution = Quiet[Check[Solve[Table[coefficients[[i]] == 0,
        {i, Exponent[denominator, u]}], unknowns, Modulus -> prime], $Failed]];
  If[solution === $Failed || solution === {}, Return[$Failed]];
  solution = First[solution];
  <|"Primitive" -> {Expand[PolynomialMod[(bPoly /. solution) + polynomialPrimitive dStar, prime]], dStar},
    "Remainder" -> {PolynomialMod[cPoly /. solution, prime], dMinus}|>
];

(* Elliptic Hermite reduction on Y^2=P(u).  For f du/Y, find g and a
   square-free-pole remainder plus the three genus-one cohomology classes,

     f = P g' + P' g/2 + r/q + c0 + c1 u + c2 u^2  (mod prime),

   so that g Y is the primitive.  The reduction depends only on the quartic
   and rational-function data. *)
rationalLayerEllipticHermite[{numeratorInput_, denominatorInput_}, curve_,
    u_Symbol, prime_Integer] := Module[
  {numerator, denominator, common, lead, branchGCD, repeated, squarefree,
   repeatedDegree, squarefreeDegree, quotient, polynomialDegree,
   polynomialPrimitiveCount, commonDenominator, target, inverseTwo,
   bSymbols, rSymbols, pSymbols, cSymbols, unknowns, bPolynomial,
   rPolynomial, pPolynomial, cPolynomial, operator, equation,
   coefficients, solutions, solution, primitiveNumerator, identity},
  numerator = PolynomialMod[numeratorInput, prime];
  denominator = PolynomialMod[denominatorInput, prime];
  If[denominator === 0,
    Return[<|"Status" -> "EllipticHermiteDenominatorZero"|>]];
  If[numerator === 0,
    Return[<|"Status" -> "EllipticHermiteReduced",
      "Primitive" -> {0, 1}, "ProperRemainder" -> {0, 1},
      "Cohomology" -> {0, 0, 0}|>]];
  common = PolynomialGCD[numerator, denominator, Modulus -> prime];
  numerator = PolynomialQuotient[numerator, common, u, Modulus -> prime];
  denominator = PolynomialQuotient[denominator, common, u, Modulus -> prime];
  lead = Coefficient[denominator, u, Exponent[denominator, u]];
  numerator = PolynomialMod[numerator PowerMod[lead, -1, prime], prime];
  denominator = PolynomialMod[denominator PowerMod[lead, -1, prime], prime];
  branchGCD = PolynomialGCD[denominator, curve, Modulus -> prime];
  If[Exponent[branchGCD, u] > 0,
    Return[<|"Status" -> "CurveBranchPoleNotSupported",
      "Factor" -> branchGCD|>]];
  repeated = PolynomialGCD[denominator, D[denominator, u], Modulus -> prime];
  repeated = PolynomialMod[repeated PowerMod[
    Coefficient[repeated, u, Exponent[repeated, u]], -1, prime], prime];
  squarefree = PolynomialQuotient[denominator, repeated, u, Modulus -> prime];
  squarefree = PolynomialMod[squarefree PowerMod[
    Coefficient[squarefree, u, Exponent[squarefree, u]], -1, prime], prime];
  repeatedDegree = Exponent[repeated, u];
  squarefreeDegree = Exponent[squarefree, u];
  quotient = PolynomialQuotient[numerator, denominator, u, Modulus -> prime];
  polynomialDegree = If[quotient === 0, -1, Exponent[quotient, u]];
  polynomialPrimitiveCount = Max[0, polynomialDegree - 2];
  commonDenominator = PolynomialLCM[denominator, repeated^2, Modulus -> prime];
  commonDenominator = PolynomialLCM[commonDenominator, squarefree, Modulus -> prime];
  target = PolynomialMod[numerator PolynomialQuotient[
    commonDenominator, denominator, u, Modulus -> prime], prime];
  inverseTwo = PowerMod[2, -1, prime];
  bSymbols = Array[Unique["e4B"] &, repeatedDegree];
  rSymbols = Array[Unique["e4R"] &, squarefreeDegree];
  pSymbols = Array[Unique["e4P"] &, polynomialPrimitiveCount];
  cSymbols = Array[Unique["e4C"] &, 3];
  unknowns = Join[bSymbols, rSymbols, pSymbols, cSymbols];
  bPolynomial = If[bSymbols === {}, 0, bSymbols . u^Range[0, repeatedDegree - 1]];
  rPolynomial = If[rSymbols === {}, 0, rSymbols . u^Range[0, squarefreeDegree - 1]];
  pPolynomial = If[pSymbols === {}, 0, pSymbols . u^Range[0, polynomialPrimitiveCount - 1]];
  cPolynomial = cSymbols . {1, u, u^2};
  operator[g_] := Expand[curve D[g, u] + inverseTwo D[curve, u] g];
  equation = Expand[
    (curve (D[bPolynomial, u] repeated - bPolynomial D[repeated, u]) +
        inverseTwo D[curve, u] bPolynomial repeated)
        PolynomialQuotient[commonDenominator, repeated^2, u, Modulus -> prime] +
      rPolynomial PolynomialQuotient[commonDenominator, squarefree, u, Modulus -> prime] +
      operator[pPolynomial] commonDenominator + cPolynomial commonDenominator - target];
  coefficients = CoefficientList[equation, u];
  solutions = Quiet[Check[Solve[Thread[coefficients == 0], unknowns,
      Modulus -> prime], $Failed]];
  If[solutions === $Failed || solutions === {},
    Return[<|"Status" -> "EllipticHermiteReductionUndecided"|>]];
  solution = First[solutions];
  If[! FreeQ[unknowns /. solution, Alternatives @@ unknowns],
    Return[<|"Status" -> "EllipticHermiteReductionUnderdetermined"|>]];
  primitiveNumerator = PolynomialMod[(bPolynomial + pPolynomial repeated) /. solution, prime];
  rPolynomial = PolynomialMod[rPolynomial /. solution, prime];
  cSymbols = Mod[cSymbols /. solution, prime];
  identity = PolynomialMod[equation /. solution, prime];
  If[identity =!= 0,
    Return[<|"Status" -> "EllipticHermiteIdentityFailed"|>]];
  <|"Status" -> "EllipticHermiteReduced",
    "Primitive" -> {primitiveNumerator, repeated},
    "ProperRemainder" -> {rPolynomial, squarefree},
    "Cohomology" -> cSymbols|>
];

(* C/Dminus on the declared coprime pole factors: C/Dminus = Sum_j r_j/q_j,
   deg r_j < deg q_j; a factor of Dminus outside the alphabet is $Failed. *)
rationalLayerPartialFractions[{c_, dMinus_}, factors_List, u_Symbol, prime_Integer] := Module[
  {reduced = dMinus, present = {}, result = <||>, cofactor, gcd, inverse, r, modular, image},
  If[c === 0, Return[<||>]];
  (* the declared factors reduced into F_q, keyed by the original factor *)
  modular = Association@Table[factor -> rationalLayerModularPolynomial[factor, u, prime], {factor, factors}];
  If[MemberQ[Values[modular], $Failed], Return[$Failed]];
  Do[
    image = modular[factor];
    If[PolynomialRemainder[reduced, image, u, Modulus -> prime] === 0,
      AppendTo[present, factor];
      reduced = PolynomialQuotient[reduced, image, u, Modulus -> prime]],
    {factor, factors}];
  If[Exponent[reduced, u] > 0, Return[$Failed]];
  Do[
    image = modular[factor];
    cofactor = PolynomialQuotient[dMinus, image, u, Modulus -> prime];
    (* r = C cofactor^-1 mod factor *)
    gcd = PolynomialExtendedGCD[cofactor, image, u, Modulus -> prime];
    If[Exponent[gcd[[1]], u] =!= 0, Return[$Failed, Module]];
    inverse = PolynomialMod[gcd[[2, 1]] PowerMod[gcd[[1]], -1, prime], prime];
    r = PolynomialRemainder[PolynomialMod[c inverse, prime], image, u, Modulus -> prime];
    r = PolynomialMod[r PowerMod[Coefficient[reduced, u, 0], -1, prime], prime];
    result[factor] = PadRight[CoefficientList[r, u], Exponent[factor, u], 0],
    {factor, present}];
  result
];

(* ---- one prime image of the sealed circuit ---------------------------- *)

(* Executes the recurrence over F_q at the specialized leaves.  omegaN is
   built from the Laurent coefficients of the incoming entries (already
   specialized in every parameter but u), the diagonal and source
   residues.  Returns the residue coefficients of every K_n on the pole
   alphabet, and the images of H_n. *)
rationalLayerRecurrenceImage[laurent_Association, diagonal_List, source_Association,
    factors_List, u_Symbol, base_, orders_List, prime_Integer, endpoint_: None] := Module[
  {d, n, letterFunctions, hPrevious, h, k, omega, entryValue, hermite, fractions,
   value, evaluateAt, hImages = <||>, kResidues = <||>, failure = None,
   diagonalForms, sourceForms, dEntry, sEntry, fixed, hEntry, hEndpoint = <||>, endpointValues},
  (* Rows and columns are read from the Laurent matrix, not from a scalar
     entry's expression tree. *)
  {d, n} = Dimensions[Lookup[laurent, First[orders]]][[1 ;; 2]];
  If[n =!= source["Dimension"],
    Return[<|"Status" -> "LayerDimensionMismatch", "Prime" -> prime,
      "Columns" -> n, "SourceDimension" -> source["Dimension"]|>]];
  diagonalForms = ({rationalLayerLetterFunction[#[[1]], u], #[[2]]} &) /@ diagonal;
  sourceForms = MapThread[{rationalLayerLetterFunction[#1, u], #2} &,
    {source["Letters"], source["Residues"]}];
  evaluateAt[{num_, den_}] := Module[{image, dv, nv},
    image[r_] := Mod[Numerator[r] PowerMod[Denominator[r], -1, prime], prime];
    dv = image[den /. u -> base]; nv = image[num /. u -> base];
    If[dv === 0, $Failed, Mod[nv PowerMod[dv, -1, prime], prime]]];
  hPrevious = ConstantArray[{0, 1}, {d, n}];
  Do[
    (* Omega_n = B_n + D_1 H_(n-1) - H_(n-1) S_1, entrywise over F_q(u) *)
    omega = Table[
      Module[{terms = {}},
        AppendTo[terms, laurent[order][[i, j]]];
        Do[AppendTo[terms, form[[2]][[i, l]] form[[1]] Together[hPrevious[[l, j, 1]]/hPrevious[[l, j, 2]]]],
          {form, diagonalForms}, {l, d}];
        Do[AppendTo[terms, -Together[hPrevious[[i, l, 1]]/hPrevious[[i, l, 2]]] form[[1]] form[[2]][[l, j]]],
          {form, sourceForms}, {l, n}];
        rationalLayerModularFunction[Total[terms], u, prime]],
      {i, d}, {j, n}];
    If[! FreeQ[omega, $Failed], failure = "CoefficientNotDefinedAtPrime"; Break[]];
    h = ConstantArray[{0, 1}, {d, n}];
    Do[
      hermite = rationalLayerHermite[omega[[i, j]], u, prime];
      If[hermite === $Failed, failure = "HermiteReductionUndecided"; Break[]];
      fractions = rationalLayerPartialFractions[hermite["Remainder"], factors, u, prime];
      If[fractions === $Failed, failure = "ResiduePoleNotInAlphabet"; Break[]];
      KeyValueMap[Function[{factor, list},
        Do[Module[{matrix = Lookup[kResidues, Key[{order, factor, kk - 1}], ConstantArray[0, {d, n}]]},
            matrix[[i, j]] = list[[kk]];
            kResidues[{order, factor, kk - 1}] = matrix], {kk, Length[list]}]],
        fractions];
      (* H_n(base) = 0 *)
      value = evaluateAt[hermite["Primitive"]];
      If[value === $Failed, failure = "BasePointOnPole"; Break[]];
      hEntry = {PolynomialMod[hermite["Primitive"][[1]] - value hermite["Primitive"][[2]], prime],
        hermite["Primitive"][[2]]};
      h[[i, j]] = hEntry,
      {i, d}, {j, n}];
    If[failure =!= None, Break[]];
    hImages[order] = h;
    (* S3: the gauge at the endpoint, H_n(u1) modulo the prime; a
       denominator vanishing there makes the prime bad (skipped by the
       caller), not the route wrong *)
    If[endpoint =!= None,
      endpointValues = Map[Module[{image, dv, nv},
          image[r_] := Mod[Numerator[r] PowerMod[Denominator[r], -1, prime], prime];
          dv = image[#[[2]] /. u -> endpoint]; nv = image[#[[1]] /. u -> endpoint];
          If[dv === 0, $Failed, Mod[nv PowerMod[dv, -1, prime], prime]]] &, h, {2}];
      If[! FreeQ[endpointValues, $Failed], failure = "EndpointOnPoleAtPrime"; Break[]];
      hEndpoint[order] = endpointValues];
    hPrevious = h,
    {order, orders}];
  If[failure =!= None, Return[<|"Status" -> failure, "Prime" -> prime|>]];
  <|"Status" -> "RecurrenceImageEvaluated", "Prime" -> prime,
    "KResidues" -> kResidues, "HImages" -> hImages, "HEndpoint" -> hEndpoint|>
];

(* Quartic-curve recurrence.  Matrix entries of h are coefficient pairs for
   h0+h1 Y; form entries are pairs for f0 du+f1 du/Y.  Their product is

     (h0 f0+h1 f1) du + (h0 f1+P h1 f0) du/Y,

   while d(h1 Y)=(P h1'+P' h1/2)du/Y. *)
rationalLayerCurveRecurrenceImage[laurent_Association, diagonal_List,
    source_Association, factors_List, u_Symbol, curve_, pointValues_Association,
    base_, baseY_, orders_List, prime_Integer, endpoint_, endpointY_] := Module[
  {d, n, curveImage, baseImage, endpointImage, baseYImage, endpointYImage, scalarImage, rf, product,
   diagonalForms, sourceForms, hPrevious, h, omega, rationalHermite,
   ellipticHermite, fractions, fixed, hEntry, hImages = <||>,
   hEndpoint = <||>, endpointValues, kResidues = <||>, failure = None,
   store, shift, cohomology, evaluateAt, root, rootValue, rootValueImage},
  {d, n} = Dimensions[Lookup[laurent, First[orders]]][[1 ;; 2]];
  If[n =!= source["Dimension"],
    Return[<|"Status" -> "LayerDimensionMismatch", "Prime" -> prime|>]];
  curveImage = rationalLayerModularPolynomial[curve, u, prime];
  If[curveImage === $Failed || Exponent[curveImage, u] =!= 4 ||
      Exponent[PolynomialGCD[curveImage, D[curveImage, u], Modulus -> prime], u] > 0,
    Return[<|"Status" -> "CurveDegeneratesAtPrime", "Prime" -> prime|>]];
  scalarImage[value_] := If[Mod[Denominator[value], prime] === 0, $Failed,
    Mod[Numerator[value] PowerMod[Denominator[value], -1, prime], prime]];
  baseImage = scalarImage[base]; endpointImage = scalarImage[endpoint];
  baseYImage = scalarImage[baseY]; endpointYImage = scalarImage[endpointY];
  If[MemberQ[{baseImage, endpointImage, baseYImage, endpointYImage}, $Failed],
    Return[<|"Status" -> "CurvePointNotDefinedAtPrime", "Prime" -> prime|>]];
  If[Mod[baseYImage^2 - (curveImage /. u -> baseImage), prime] =!= 0 ||
      Mod[endpointYImage^2 - (curveImage /. u -> endpointImage), prime] =!= 0,
    Return[<|"Status" -> "CurveSheetInconsistentAtPrime", "Prime" -> prime|>]];
  rf[{numerator_, denominator_}] := numerator/denominator;
  product[functionPair_, formPair_] := With[
    {h0 = rf[functionPair[[1]]], h1 = rf[functionPair[[2]]],
     f0 = formPair[[1]], f1 = formPair[[2]]},
    {h0 f0 + h1 f1, h0 f1 + curveImage h1 f0}];
  evaluateAt[{numerator_, denominator_}, point_] := Module[{pointImage, dv, nv},
    pointImage = scalarImage[point];
    If[pointImage === $Failed, Return[$Failed, Module]];
    dv = Mod[denominator /. u -> pointImage, prime];
    nv = Mod[numerator /. u -> pointImage, prime];
    If[dv === 0, $Failed, Mod[nv PowerMod[dv, -1, prime], prime]]];
  diagonalForms = ({rationalLayerLetterPair[#[[1]], u, curve, pointValues], #[[2]]} &) /@ diagonal;
  sourceForms = MapThread[{rationalLayerLetterPair[#1, u, curve, pointValues], #2} &,
    {source["Letters"], source["Residues"]}];
  If[! FreeQ[{diagonalForms, sourceForms}, _Missing],
    Return[<|"Status" -> "CurvePointValueRequired", "Prime" -> prime|>]];
  store[order_, label_, value_, i_, j_] := If[Mod[value, prime] =!= 0,
    Module[{key = rationalLayerResidueKey[order, label], matrix},
      matrix = Lookup[kResidues, Key[key], ConstantArray[0, {d, n}]];
      matrix[[i, j]] = Mod[matrix[[i, j]] + value, prime];
      kResidues[key] = matrix]];
  shift = Mod[Coefficient[curveImage, u, 3] PowerMod[
    Mod[2 Coefficient[curveImage, u, 4], prime], -1, prime], prime];
  hPrevious = ConstantArray[{{0, 1}, {0, 1}}, {d, n}];
  Do[
    omega = Table[Module[{terms = {{laurent[order][[i, j, 1]]},
          {laurent[order][[i, j, 2]]}}, term},
        Do[
          term = product[hPrevious[[l, j]], form[[1]]];
          AppendTo[terms[[1]], form[[2, i, l]] term[[1]]];
          AppendTo[terms[[2]], form[[2, i, l]] term[[2]]],
          {form, diagonalForms}, {l, d}];
        Do[
          term = product[hPrevious[[i, l]], form[[1]]];
          AppendTo[terms[[1]], -form[[2, l, j]] term[[1]]];
          AppendTo[terms[[2]], -form[[2, l, j]] term[[2]]],
          {form, sourceForms}, {l, n}];
        rationalLayerModularFunction[Total[#], u, prime] & /@ terms],
      {i, d}, {j, n}];
    If[! FreeQ[omega, $Failed], failure = "CoefficientNotDefinedAtPrime"; Break[]];
    h = ConstantArray[{{0, 1}, {0, 1}}, {d, n}];
    Do[
      rationalHermite = rationalLayerHermite[omega[[i, j, 1]], u, prime];
      If[rationalHermite === $Failed,
        failure = "HermiteReductionUndecided"; Break[]];
      fractions = rationalLayerPartialFractions[rationalHermite["Remainder"],
        factors, u, prime];
      If[fractions === $Failed, failure = "ResiduePoleNotInAlphabet"; Break[]];
      KeyValueMap[Function[{factor, list}, Do[
        store[order, {"GPLFactor", factor, kk - 1}, list[[kk]], i, j],
        {kk, Length[list]}]], fractions];
      ellipticHermite = rationalLayerEllipticHermite[omega[[i, j, 2]],
        curveImage, u, prime];
      If[Lookup[ellipticHermite, "Status", None] =!= "EllipticHermiteReduced",
        failure = Lookup[ellipticHermite, "Status", "EllipticHermiteReductionUndecided"];
        Break[]];
      fractions = rationalLayerPartialFractions[
        ellipticHermite["ProperRemainder"], factors, u, prime];
      If[fractions === $Failed, failure = "ResiduePoleNotInAlphabet"; Break[]];
      KeyValueMap[Function[{factor, list},
        If[Exponent[factor, u] === 1,
          root = Together[-Coefficient[factor, u, 0]/Coefficient[factor, u, 1]];
          rootValue = rationalLayerCurvePointValue[root, curve, u, pointValues];
          rootValueImage = If[MissingQ[rootValue], $Failed, scalarImage[rootValue]],
          rootValueImage = $Failed];
        Do[If[kk === 1 && rootValueImage =!= $Failed && rootValueImage =!= 0,
            store[order, {"E4Pole", root},
              list[[kk]] PowerMod[rootValueImage, -1, prime], i, j],
            store[order, {"E4Factor", factor, kk - 1}, list[[kk]], i, j]],
          {kk, Length[list]}]], fractions];
      cohomology = ellipticHermite["Cohomology"];
      store[order, {"E4Omega0"}, cohomology[[1]], i, j];
      store[order, {"E4OmegaInf"}, cohomology[[2]] - shift cohomology[[3]], i, j];
      store[order, {"E4Eta2"}, cohomology[[3]], i, j];
      fixed = evaluateAt[rationalHermite["Primitive"], base];
      If[fixed =!= $Failed,
        With[{ellipticBase = evaluateAt[ellipticHermite["Primitive"], base]},
          If[ellipticBase === $Failed, fixed = $Failed,
            fixed = Mod[fixed + baseYImage ellipticBase, prime]]]];
      If[fixed === $Failed, failure = "BasePointOnPole"; Break[]];
      hEntry = {
        {PolynomialMod[rationalHermite["Primitive"][[1]] -
            fixed rationalHermite["Primitive"][[2]], prime],
          rationalHermite["Primitive"][[2]]},
        ellipticHermite["Primitive"]};
      h[[i, j]] = hEntry,
      {i, d}, {j, n}];
    If[failure =!= None, Break[]];
    hImages[order] = h;
    endpointValues = Map[Module[{v0 = evaluateAt[#[[1]], endpoint],
          v1 = evaluateAt[#[[2]], endpoint]},
        If[MemberQ[{v0, v1}, $Failed], $Failed,
          Mod[v0 + endpointYImage v1, prime]]] &, h, {2}];
    If[! FreeQ[endpointValues, $Failed], failure = "EndpointOnPoleAtPrime"; Break[]];
    hEndpoint[order] = endpointValues;
    hPrevious = h,
    {order, orders}];
  If[failure =!= None,
    Return[<|"Status" -> failure, "Prime" -> prime|>]];
  <|"Status" -> "RecurrenceImageEvaluated", "Prime" -> prime,
    "KResidues" -> kResidues, "HImages" -> hImages,
    "HEndpoint" -> hEndpoint, "CurveChannel" -> True|>
];

(* ---- words ------------------------------------------------------------ *)

(* Words D^a K_r S^b and D^a reaching (order, row): the coefficient of a
   word is the row of the matrix product against the boundary selector at
   boundary order q with q + a + r + b = order.  Words GROW from the
   selectors with every zero intermediate product pruned (the sparse word
   growth of observableTransportWordMaps): SparseArray throughout, the
   source-word growth shared across all demanded pairs (sourceStates:
   q -> states by weight), and a K letter applied only where its columns
   meet the state's nonzero rows.  "MaximumWords" caps the enumeration and
   the pair is then reported capped (typed), never truncated silently. *)
rationalLayerSourceStates[source_Association, maximumWeight_Integer, weightByOrder_: Automatic, maximumStates_: Infinity] := Module[
  {sLetters, grow, nonzeroQ, needed, total = 0},
  nonzeroQ[m_] := Length[SparseArray[m]["NonzeroPositions"]] > 0;
  sLetters = Transpose[{source["Letters"], SparseArray /@ source["Residues"]}];
  grow[states_List] := With[{next = Select[Flatten[Table[
      {Append[state[[1]], letter[[1]]], letter[[2]] . state[[2]]}, {state, states}, {letter, sLetters}], 1],
    nonzeroQ[#[[2]]] &]},
    total += Length[next];
    If[total > maximumStates, Throw[<|"Status" -> "SourceWordGrowthCapped", "MaximumStates" -> maximumStates, "States" -> total|>]];
    next];
  (* Grow each boundary order only as far as a demanded pair can reach it:
     the source-tail weight is order-q-r. *)
  needed[q_] := If[weightByOrder === Automatic, maximumWeight, Lookup[weightByOrder, q, -1]];
  Association@Table[q -> NestList[grow, {{{}, SparseArray[source["BoundarySelectors"][q]]}}, Min[maximumWeight, needed[q]]],
    {q, Select[Keys[source["BoundarySelectors"]], needed[#] >= 0 &]}]
];

rationalLayerWords[order_Integer, row_Integer, diagonal_List, kResidues_Association,
    source_Association, targetSelectors_Association, sourceBoundaryCount_Integer,
    targetBoundaryCount_Integer, maximumWeight_Integer, maximumWords_: Infinity,
    sourceStatesGiven_: Automatic, sharedBoundaryQ_: False] := Module[
  {words = {}, dLetters, kLetters, embedSource, embedTarget, grow, capped = False,
   nonzeroQ, sourceStates, dStates, kStates, count = 0, rowsOf, columnsOf, dropped = 0},
  nonzeroQ[m_] := Length[SparseArray[m]["NonzeroPositions"]] > 0;
  rowsOf[m_] := DeleteDuplicates[SparseArray[m]["NonzeroPositions"][[All, 1]]];
  columnsOf[m_] := DeleteDuplicates[SparseArray[m]["NonzeroPositions"][[All, 2]]];
  dLetters = ({#[[1]], SparseArray[#[[2]]]} &) /@ diagonal;
  kLetters = KeyValueMap[{rationalLayerResidueLabel[#1], #1[[1]], SparseArray[#2]} &,
    KeySort[kResidues]];
  kLetters = Select[kLetters, nonzeroQ[#[[3]]] &];
  kLetters = ({#[[1]], #[[2]], #[[3]], columnsOf[#[[3]]]} &) /@ kLetters;
  sourceStates = If[sourceStatesGiven === Automatic,
    rationalLayerSourceStates[source, maximumWeight], sourceStatesGiven];
  embedSource[vector_] := If[TrueQ[sharedBoundaryQ], vector,
    Join[vector, ConstantArray[0, targetBoundaryCount]]];
  embedTarget[vector_] := If[TrueQ[sharedBoundaryQ], vector,
    Join[ConstantArray[0, sourceBoundaryCount], vector]];
  grow[states_List, letters_List] := Select[Flatten[Table[
      {Append[state[[1]], letter[[1]]], letter[[2]] . state[[2]]}, {state, states}, {letter, letters}], 1],
    nonzeroQ[#[[2]]] &];
  (* Word convention (S2b): "Word" lists the letters OUTERMOST FIRST, i.e.
     {l1, l2, ..., lk} is Int_base^u l1(t1) Int_base^t1 l2(t2) ... lk(tk),
     for both word kinds; the growth appends the innermost letter first,
     so every stored word is the reverse of the growth list.  "Coefficient"
     is the row vector over the boundary constants: the source constants
     first (as in the source's selectors), then the target constants,
     grouped by target boundary order. *)
  (* target boundary words: D^a Selector[q], a = order - q *)
  Do[
    With[{a = order - q},
      If[a > maximumWeight, dropped++];
      If[0 <= a <= maximumWeight,
        dStates = Nest[grow[#, dLetters] &, {{{}, SparseArray[targetSelectors[q]]}}, a];
        Do[If[nonzeroQ[state[[2]][[row]]],
            AppendTo[words, <|"Word" -> Reverse[state[[1]]], "Kind" -> "TargetBoundary",
              "BoundaryOrder" -> q, "Coefficient" -> embedTarget[Normal[state[[2]][[row]]]]|>];
            count++; If[count > maximumWords, capped = True]],
          {state, dStates}]]],
    {q, Keys[targetSelectors]}];
  (* source boundary words: D^a K_r S^b Selector[q] *)
  Do[
    If[capped, Break[]];
    Do[
      If[capped, Break[]];
      Do[
        With[{a = order - q - kLetter[[2]] - b},
          If[a > maximumWeight, dropped++];
          If[0 <= a <= maximumWeight,
            kStates = Select[Table[
                If[Intersection[kLetter[[4]], rowsOf[state[[2]]]] === {}, Nothing,
                  {Append[state[[1]], Join[kLetter[[1]], {"Incoming", kLetter[[2]]}]],
                    kLetter[[3]] . state[[2]]}],
                {state, sourceStates[q][[b + 1]]}], nonzeroQ[#[[2]]] &];
            dStates = Nest[grow[#, dLetters] &, kStates, a];
            Do[If[nonzeroQ[state[[2]][[row]]],
                AppendTo[words, <|"Word" -> Reverse[state[[1]]], "Kind" -> "SourceBoundary",
                  "BoundaryOrder" -> q, "IncomingOrder" -> kLetter[[2]],
                  "Coefficient" -> embedSource[Normal[state[[2]][[row]]]]|>];
                count++; If[count > maximumWords, capped = True]],
              {state, dStates}]]],
        {kLetter, kLetters}],
      {b, 0, Min[maximumWeight, Length[sourceStates[q]] - 1]}],
    {q, Keys[sourceStates]}];
  If[capped || dropped > 0,
    <|"Status" -> If[capped, "WordEnumerationCapped", "WordWeightCapReached"], "MaximumWords" -> maximumWords,
      "DroppedCombinations" -> dropped, "Words" -> words|>, words]
];

(* The target boundary selectors padded into one block of columns, grouped
   by target boundary order (shared by the route and the re-verifying
   predicate so that both build the same words). *)
rationalLayerTargetSelectors[layer_Association, d_Integer, sharedQ_: False] := Module[
  {selectors, count, offsets},
  selectors = Lookup[layer, "TargetBoundarySelectors", <|0 -> IdentityMatrix[d]|>];
  If[TrueQ[sharedQ], Return[{selectors, Dimensions[First[Values[selectors]]][[2]]}]];
  count = Total[Length[First[#]] & /@ Values[selectors]];
  offsets = Accumulate[Prepend[Length[First[#]] & /@ Values[selectors], 0]];
  {Association@MapIndexed[Function[{q, index},
      q -> (PadRight[PadLeft[#, offsets[[First[index]]] + Length[#]], count] & /@ selectors[q])],
      Keys[selectors]], count}
];

(* ---- the route ------------------------------------------------------------ *)

Options[BuildRationalEpsilonLayerTransport] = {
  "Primes" -> Automatic,
  "PrimeCount" -> 3,
  "MaximumPrimeCount" -> 24,
  "Seed" -> 20260902,
  "MaximumWeight" -> Automatic,
  "MaximumWords" -> Infinity,
  "MaximumStates" -> 200000,
  "IncomingRoute" -> Automatic,
  "GaugeRepresentation" -> Automatic,
  "WordRepresentation" -> Automatic,
  "PrepareOnly" -> False,
  "Verbose" -> False
};

BuildRationalEpsilonLayerTransport[source_Association, layer_Association,
    demand_Association, OptionsPattern[]] := Catch@Module[
  {start = AbsoluteTime[], u, eps, base, rows, d, n, diagonal, incoming, curve,
   labels, gate, coefficients, symbols, factors, valuations, low, high,
   laurent, orders, primes, seed, images, freshPrime, freshImage, keys,
   reconstructed, lifted, comparisons = 0, mismatches = 0, targetSelectors,
   sourceBoundaryCount, targetBoundaryCount, demandPairs, words, maximumWeight,
   verbose, fail, kExact, certificate, laurentCoefficient, hImageCount = 0, sourceStates, directQ,
   weightByOrder, letterDecomposition, neededWeight, weightCapped, cappedPairs,
   endpoint, gaugeAtEndpoint = <||>, gaugeComparisons = 0, gaugeMismatches = 0, probePoints,
   skippedPrimes = {}, scheduleIndex, regularization, targetSelectorInput,
   primeCount, maximumPrimeCount, primeSchedule, activeIncomingOrders,
   wordRepresentation, sharedBoundaryQ, curveQ, curvePointValues,
   curveBaseValue = None, curveEndpointValue = None, curvePoints,
   recurrenceImage, operatorSource, operatorLayer, gaugeRepresentation,
   gaugeFunctions = <||>, gaugeFunctionCheck = <||>},
  verbose = TrueQ[OptionValue["Verbose"]];
  fail[status_, extra_: <||>] := Throw[Join[<|"Status" -> status|>, extra]];
  seed = OptionValue["Seed"];
  If[! IntegerQ[seed], fail["InvalidSeed"]];
  u = Lookup[layer, "PathVariable", Missing[]]; eps = Lookup[layer, "Regulator", Missing[]];
  base = Lookup[layer, "BasePoint", Missing[]]; rows = Lookup[layer, "Rows", Missing[]];
  diagonal = Lookup[layer, "Diagonal", Missing[]]; incoming = Lookup[layer, "Incoming", Missing[]];
  curve = Lookup[layer, "Curve", None];
  If[! MatchQ[u, _Symbol] || ! MatchQ[eps, _Symbol] || ! MatchQ[base, _Integer | _Rational] ||
      ! ListQ[rows] || rows === {} || ! MatchQ[diagonal, {{_List, _?MatrixQ} ..}] ||
      ! MatchQ[incoming, {__Association}],
    fail["LayerInputNotWellFormed"]];
  d = Length[rows];
  If[! AllTrue[diagonal, Dimensions[#[[2]]] === {d, d} &], fail["LayerInputNotWellFormed", <|"Reason" -> "diagonal residue dimensions"|>]];
  n = Lookup[source, "Dimension", Missing[]];
  If[! IntegerQ[n] || n < 1 || ! ListQ[Lookup[source, "Letters", None]] ||
      ! ListQ[Lookup[source, "Residues", None]] ||
      Length[source["Letters"]] =!= Length[source["Residues"]] ||
      ! AllTrue[source["Residues"], Dimensions[#] === {n, n} &] ||
      ! AssociationQ[Lookup[source, "BoundarySelectors", None]],
    fail["SourceLayerNotAccepted"]];
  targetSelectorInput = Lookup[layer, "TargetBoundarySelectors", <|0 -> IdentityMatrix[d]|>];
  sharedBoundaryQ = TrueQ[Lookup[layer, "SharedBoundaryCoordinates", False]];
  (* Source selectors all act on the same boundary-constant vector.  Target
     selectors may have different column counts because they are padded into
     disjoint target-boundary blocks below.  In both cases the Laurent-order
     labels must be integers and every selector must have at least one column. *)
  With[{selectors = source["BoundarySelectors"]},
    If[selectors === <||> || ! VectorQ[Keys[selectors], IntegerQ] ||
        ! AllTrue[Values[selectors], MatrixQ[#] && Length[Dimensions[#]] === 2 &&
          Dimensions[#][[1]] === n && Dimensions[#][[2]] >= 1 &] ||
        ! (SameQ @@ (Dimensions[#][[2]] & /@ Values[selectors])),
      fail["SourceBoundarySelectorsInvalid"]]];
  If[! AssociationQ[targetSelectorInput] || targetSelectorInput === <||> ||
      ! VectorQ[Keys[targetSelectorInput], IntegerQ] ||
      ! AllTrue[Values[targetSelectorInput], MatrixQ[#] && Length[Dimensions[#]] === 2 &&
        Dimensions[#][[1]] === d && Dimensions[#][[2]] >= 1 &],
    fail["TargetBoundarySelectorsInvalid"]];
  If[sharedBoundaryQ &&
      (! (SameQ @@ (Dimensions[#][[2]] & /@ Values[targetSelectorInput])) ||
       Dimensions[First[Values[targetSelectorInput]]][[2]] =!=
         Dimensions[First[Values[source["BoundarySelectors"]]]][[2]]),
    fail["SharedBoundarySelectorsInvalid"]];
  wordRepresentation = Replace[OptionValue["WordRepresentation"],
    Automatic -> "MaterializedWords"];
  If[! MemberQ[{"MaterializedWords", "LazyOperator"}, wordRepresentation],
    fail["WordRepresentationInvalid"]];
  If[! AllTrue[incoming, IntegerQ[#["Row"]] && 1 <= #["Row"] <= d && IntegerQ[#["Column"]] && 1 <= #["Column"] <= n &],
    fail["LayerInputNotWellFormed", <|"Reason" -> "incoming row/column indices"|>]];
  (* S5: residue matrices and selectors are constant rational matrices *)
  With[{constantQ = MatrixQ[#, MatchQ[#, _Integer | _Rational] &] &},
    With[{bad = Select[Range[Length[diagonal]], ! constantQ[diagonal[[#, 2]]] &]},
      If[bad =!= {}, fail["ResidueMatrixNotConstant", <|"Where" -> "Diagonal", "Letters" -> diagonal[[bad, 1]]|>]]];
    With[{bad = Select[Range[Length[source["Residues"]]], ! constantQ[source["Residues"][[#]]] &]},
      If[bad =!= {}, fail["ResidueMatrixNotConstant", <|"Where" -> "Source", "Letters" -> source["Letters"][[bad]]|>]]];
    If[! AllTrue[Values[source["BoundarySelectors"]], constantQ],
      fail["ResidueMatrixNotConstant", <|"Where" -> "SourceBoundarySelectors"|>]];
    If[! AllTrue[Values[targetSelectorInput], constantQ],
      fail["ResidueMatrixNotConstant", <|"Where" -> "TargetBoundarySelectors"|>]]];
  (* every source column must be present or declared as an exception; the
     check is a COLUMN-PRESENCE proxy (a column with one declared term and a
     missing forcing is not detected), and ZeroColumns must name only absent
     columns (S8) *)
  With[{present = DeleteDuplicates[Lookup[incoming, "Column"]], zero = Lookup[layer, "ZeroColumns", {}]},
    If[! (ListQ[zero] && AllTrue[zero, IntegerQ[#] && 1 <= # <= n &] && Intersection[zero, present] === {}),
      fail["ZeroColumnsInvalid", <|"ZeroColumns" -> zero, "Present" -> Intersection[Flatten[{zero}], present]|>]];
    With[{missing = Complement[Range[n], present, zero]},
      If[missing =!= {}, fail["LowerBlockExceptionRequired", <|"Columns" -> missing|>]]]];
  (* alphabet *)
  labels = DeleteDuplicates[Join[diagonal[[All, 1]], Lookup[incoming, "Letter"], source["Letters"]]];
  gate = rationalLayerAlphabetGate[labels, u, curve];
  If[gate["Status"] =!= "AlphabetAdmitted", fail[gate["Status"], KeyDrop[gate, "Status"]]];
  curveQ = MemberQ[gate["Channels"], "Curve"];
  (* incoming coefficients: rational in eps and u, every other symbol specialized *)
  coefficients = Lookup[incoming, "Coefficient"];
  symbols = DeleteDuplicates[Cases[coefficients, s_Symbol /; s =!= u && s =!= eps, {0, Infinity}]];
  If[symbols =!= {}, fail["PathParameterNotSpecialized", <|"Symbols" -> symbols|>]];
  If[! AllTrue[coefficients, With[{t = Together[#]},
      PolynomialQ[Numerator[t], {eps, u}] && PolynomialQ[Denominator[t], {eps, u}]] &],
    fail["IncomingNotRationalInEpsilon"]];
  directQ = OptionValue["IncomingRoute"] =!= "Modular" && AllTrue[coefficients, FreeQ[#, u] &];
  endpoint = Lookup[layer, "Endpoint", Lookup[demand, "Endpoint", None]];
  gaugeRepresentation = Replace[OptionValue["GaugeRepresentation"],
    Automatic -> Which[
      MatchQ[endpoint, _Integer | _Rational], "EndpointValue",
      MatchQ[endpoint, _Symbol] && endpoint =!= None && endpoint =!= u,
        "RationalFunction",
      True, "EndpointValue"]];
  If[! MemberQ[{"EndpointValue", "RationalFunction"}, gaugeRepresentation],
    fail["GaugeRepresentationInvalid"]];
  If[! directQ && gaugeRepresentation === "EndpointValue" &&
      ! MatchQ[endpoint, _Integer | _Rational],
    fail["EndpointRequired", <|"Reason" ->
      "endpoint-value gauge reconstruction needs a rational endpoint"|>]];
  If[! directQ && gaugeRepresentation === "RationalFunction" &&
      !(MatchQ[endpoint, _Symbol] && endpoint =!= None && endpoint =!= u),
    fail["SymbolicEndpointRequired", <|"Endpoint" -> endpoint|>]];
  curvePointValues = Lookup[layer, "CurvePointValues", <||>];
  If[curveQ && (! AssociationQ[curvePointValues] ||
      ! AllTrue[Keys[curvePointValues], MatchQ[#, _Integer | _Rational] &]),
    fail["CurvePointValuesInvalid"]];
  If[curveQ && gaugeRepresentation === "RationalFunction" && ! directQ,
    fail["CurveGaugeFunctionNotImplemented", <|"Reason" ->
      "a symbolic elliptic gauge also needs the endpoint curve sheet"|>]];
  If[curveQ,
    curvePoints = DeleteDuplicates[Cases[labels, {"E4Pole", point_} :> point]];
    curvePointValues = Join[curvePointValues, Association@Table[point ->
      Replace[Lookup[curvePointValues, point, Automatic],
        Automatic :> Sqrt[Together[curve /. u -> point]]], {point, curvePoints}]];
    If[! directQ,
      If[! MatchQ[endpoint, _Integer | _Rational],
        fail["EndpointRequired", <|"Reason" -> "a curve-valued gauge needs a declared endpoint"|>]];
      curveBaseValue = rationalLayerCurvePointValue[base, curve, u,
        Lookup[layer, "CurvePointValues", <||>]];
      curveEndpointValue = rationalLayerCurvePointValue[endpoint, curve, u,
        Lookup[layer, "CurvePointValues", <||>]];
      If[MissingQ[curveBaseValue] || MissingQ[curveEndpointValue] ||
          ! AllTrue[Values[curvePointValues], MatchQ[#, _Integer | _Rational] &],
        fail["CurvePointValueRequired", <|"BasePoint" -> base,
          "Endpoint" -> endpoint, "MarkedPoints" -> curvePoints,
          "Reason" -> "the modular curve recurrence needs rational sheet values y with y^2=P(point), supplied through CurvePointValues when not rational squares"|>]];
      If[AnyTrue[Normal[curvePointValues],
          Together[Last[#]^2 - (curve /. u -> First[#])] =!= 0 &],
        fail["CurvePointValuesInvalid"]]]];
  (* epsilon window: exact valuation of every coefficient at the base point and at
     two more rational points of u (the round-4 certificate style) *)
  (* S6: three random rational probe points from the seed (a coefficient
     vanishing at a fixed point evaded the former fixed probes), minimum
     over the points as in round 4; the Series' own valuation is read
     after the expansion and a pole below the window is refused *)
  probePoints = BlockRandom[SeedRandom[seed + 7];
    Table[base + RandomInteger[{1, 199}]/RandomInteger[{200, 397}], {3}]];
  valuations = Table[Module[{vs},
      vs = Table[observableTransportEpsilonOrderAtPoint[c /. u -> pt, eps], {pt, probePoints}];
      If[! AllTrue[vs, IntegerQ], fail["LayerValuationUncertified", <|"Coefficient" -> c, "Orders" -> vs|>]];
      Min[vs]], {c, coefficients}];
  low = Min[valuations];
  demandPairs = Lookup[demand, "Pairs", Missing[]];
  If[! MatchQ[demandPairs, {{_Integer, _Integer} ..}] || ! DuplicateFreeQ[demandPairs] ||
      ! AllTrue[demandPairs, 1 <= #[[2]] <= d &],
    fail["InvalidLayerDemand"]];
  (* A word D^a K_r S^b Sel[q] contributes at
     q + a + r + b, so a demanded order N needs incoming orders up to
     N - q_min over the SOURCE boundary orders (Codex: "orders -2..4 for
     the target window -4..2" with boundary orders from -2); the former
     window stopped at N and silently lost every word on a negative
     boundary order *)
  high = Max[demandPairs[[All, 1]]] - Min[Keys[source["BoundarySelectors"]]];
  If[high < low, fail["DemandBelowValuation", <|"Low" -> low, "High" -> high|>]];
  orders = Range[low, high];
  (* Laurent expansion: one Series per incoming coefficient *)
  laurentCoefficient[c_] := Module[{s = observableTransportLaurentEntrySeries[c, eps, {low, high}]},
    If[s === $Failed, Table[Cancel[Together[SeriesCoefficient[c, {eps, 0, o}]]], {o, orders}], s]];
  $observableTransportLaurentDiagnostics = <||>;
  laurent = If[curveQ,
    Table[ConstantArray[{0, 0}, {d, n}], {Length[orders]}],
    Table[ConstantArray[0, {d, n}], {Length[orders]}]];
  Do[With[{series = laurentCoefficient[entry["Coefficient"]],
      form = If[curveQ, rationalLayerLetterPair[entry["Letter"], u, curve, curvePointValues],
        rationalLayerLetterFunction[entry["Letter"], u]]},
      Do[If[curveQ,
          laurent[[k, entry["Row"], entry["Column"], 1]] += series[[k]] form[[1]];
          laurent[[k, entry["Row"], entry["Column"], 2]] += series[[k]] form[[2]],
          laurent[[k, entry["Row"], entry["Column"]]] += series[[k]] form],
        {k, Length[orders]}]],
    {entry, incoming}];
  laurent = AssociationThread[orders -> laurent];
  If[Lookup[$observableTransportLaurentDiagnostics, "ValuationBelowRange", 0] > 0,
    fail["LaurentValuationBelowWindow", <|"Window" -> {low, high},
      "Entries" -> $observableTransportLaurentDiagnostics["ValuationBelowRange"],
      "Reason" -> "an incoming coefficient has a pole in eps below the certified valuation"|>]];
  If[verbose, observableTransportMilestone["Rational layer: Laurent expansion of ", Length[incoming], " incoming entries, orders ", {low, high}, ", ", Round[AbsoluteTime[] - start, 0.1], " s"]];
  With[{mixed = Select[DeleteDuplicates[Flatten[First /@ FactorList[Denominator[Together[#]]] & /@ coefficients]],
      ! FreeQ[#, u] && ! FreeQ[#, eps] &]},
    If[mixed =!= {}, fail["MixedEpsilonPathDenominator", <|"Factors" -> mixed|>]]];
  factors = rationalLayerPoleFactors[labels, coefficients, u];
  regularization = <|"BasePoint" -> Join[
      Select[factors, (# /. u -> base) === 0 &],
      If[curveQ && Together[curve /. u -> base] === 0, {curve}, {}]],
    "Endpoint" -> If[MatchQ[endpoint, _Integer | _Rational],
      Join[Select[factors, (# /. u -> endpoint) === 0 &],
        If[curveQ && Together[curve /. u -> endpoint] === 0, {curve}, {}]], {}]|>;
  (* Residues alone are not a physical transport when an iterated-integral
     endpoint is singular.  Until tangential-base/endpoint data are accepted
     and consumed, return a typed non-acceptance instead of Accepted plus an
     unresolved warning. *)
  If[regularization["BasePoint"] =!= {} || regularization["Endpoint"] =!= {},
    fail["PathRegularizationRequired", <|"RegularizationRequired" -> regularization,
      "BasePoint" -> base, "Endpoint" -> endpoint|>]];
  (* When every incoming coefficient is free of the path
     variable, each B_n is a combination of the declared dlog letters with
     NUMERICAL coefficients, Omega_n = B_n (H_(n-1) = 0 inductively) and
     the Hermite gauge vanishes identically: the K residues are the exact
     Laurent coefficients on the letters' own factors -- no modular image
     or reconstruction.  "IncomingRoute" -> "Modular" forces the sealed
     circuit for a cross-check. *)
  If[directQ,
    (* Decompose each rational letter once over irreducible monic pole
       factors so direct and modular routes use the same labels. *)
    letterDecomposition[letter_] := letterDecomposition[letter] = Module[{a, terms, out = <||>},
      a = Apart[rationalLayerLetterFunction[letter, u], u];
      terms = If[Head[a] === Plus, List @@ a, {a}];
      Do[With[{den = Denominator[Together[term]]},
          With[{factor = SelectFirst[factors, PolynomialRemainder[den, #, u] === 0 &, None]},
            If[factor === None, Throw[<|"Status" -> "ResiduePoleNotInAlphabet", "Letter" -> letter|>]];
            With[{r = PolynomialRemainder[Together[term factor], factor, u]},
              out[factor] = Lookup[out, factor, 0] + r]]],
        {term, terms}];
      Association@KeyValueMap[#1 -> PadRight[CoefficientList[Together[#2], u], Exponent[#1, u], 0] &, out]];
    reconstructed = <||>;
    Do[With[{series = laurentCoefficient[entry["Coefficient"]], label = entry["Letter"]},
        If[MemberQ[$rationalLayerCurveLetters, First[label]],
          Do[If[series[[k]] =!= 0,
              Module[{key = rationalLayerResidueKey[orders[[k]], label], matrix},
                matrix = Lookup[reconstructed, Key[key], ConstantArray[0, {d, n}]];
                matrix[[entry["Row"], entry["Column"]]] += series[[k]];
                reconstructed[key] = matrix]],
            {k, Length[orders]}],
          With[{decomposition = letterDecomposition[label]},
            Do[If[series[[k]] =!= 0,
                KeyValueMap[Function[{factor, list},
                  Do[If[list[[kk]] =!= 0,
                      Module[{key = {orders[[k]], factor, kk - 1}, matrix},
                        matrix = Lookup[reconstructed, Key[key], ConstantArray[0, {d, n}]];
                        matrix[[entry["Row"], entry["Column"]]] += series[[k]] list[[kk]];
                        reconstructed[key] = matrix]],
                    {kk, Length[list]}]], decomposition]],
              {k, Length[orders]}]]]],
      {entry, incoming}];
    reconstructed = Select[reconstructed, ! AllTrue[Flatten[#], # === 0 &] &];
    keys = Keys[reconstructed];
    primes = {}; freshPrime = None; images = {}; comparisons = Length[keys] d n; mismatches = 0;
    If[verbose, observableTransportMilestone["Rational layer: incoming connection is dlog with path-free coefficients: ",
      Length[keys], " exact residue keys, no modular image, ", Round[AbsoluteTime[] - start, 0.1], " s"]]];
  (* primes *)
  If[TrueQ[OptionValue["PrepareOnly"]],
    Throw[<|"Status" -> "Prepared", "Laurent" -> laurent, "Orders" -> orders,
      "Factors" -> factors, "DirectQ" -> directQ, "DirectResidues" -> If[directQ, reconstructed, None],
      "Diagonal" -> diagonal, "Source" -> source, "PathVariable" -> u, "Regulator" -> eps,
      "BasePoint" -> base, "Endpoint" -> endpoint, "Window" -> {low, high}, "Rows" -> rows,
      "DemandPairs" -> demandPairs, "Dimensions" -> {d, n},
      "GaugeRepresentation" -> gaugeRepresentation,
      "WordRepresentation" -> wordRepresentation,
      "SharedBoundaryCoordinates" -> sharedBoundaryQ,
      "CurveQ" -> curveQ, "Curve" -> curve,
      "CurvePointValues" -> curvePointValues,
      "CurveBaseValue" -> curveBaseValue,
      "CurveEndpointValue" -> curveEndpointValue|>]];
  (* N3: the modular arithmetic reduces rational numbers only; a Gaussian
     rational (I) or any other non-rational number in a coefficient would
     burn the whole prime schedule -- refused typed here (the direct route
     works exactly in Q(i) and keeps such coefficients) *)
  If[! directQ && ! AllTrue[coefficients, FreeQ[#, _Complex] && VectorQ[Flatten[CoefficientList[Numerator[Together[#]], {eps, u}]], MatchQ[#, _Integer | _Rational] &] &&
        VectorQ[Flatten[CoefficientList[Denominator[Together[#]], {eps, u}]], MatchQ[#, _Integer | _Rational] &] &],
    fail["CoefficientFieldNotRational", <|"Reason" -> "the sealed modular circuit reduces rational coefficients only; a Gaussian or algebraic coefficient needs the direct route or a field extension"|>]];
  recurrenceImage[prime_] := If[curveQ,
    rationalLayerCurveRecurrenceImage[laurent, diagonal, source, factors, u,
      curve, curvePointValues, base, curveBaseValue, orders, prime,
      If[gaugeRepresentation === "EndpointValue", endpoint, None],
      curveEndpointValue],
    rationalLayerRecurrenceImage[laurent, diagonal, source, factors, u, base,
      orders, prime,
      If[gaugeRepresentation === "EndpointValue", endpoint, None]]];
  If[! directQ,
  (* Seeded prime schedule: add images until every coordinate reconstructs
     (lift-and-verify) or the declared maximum is reached. *)
  primeCount = OptionValue["PrimeCount"];
  maximumPrimeCount = OptionValue["MaximumPrimeCount"];
  If[! IntegerQ[primeCount] || primeCount < 1 || ! IntegerQ[maximumPrimeCount] ||
      maximumPrimeCount < primeCount,
    fail["InvalidPrimeCount", <|"PrimeCount" -> primeCount,
      "MaximumPrimeCount" -> maximumPrimeCount|>]];
  primeSchedule = Replace[OptionValue["Primes"], Automatic :> BlockRandom[
    SeedRandom[seed]; Module[{schedule = {}, count = maximumPrimeCount + 1},
      While[Length[schedule] < count,
        schedule = DeleteDuplicates[Append[schedule, RandomPrime[{2^30, 2^31 - 1}]]]];
      schedule]]];
  If[! MatchQ[primeSchedule, {__Integer}] || Length[primeSchedule] < primeCount + 1 ||
      ! DuplicateFreeQ[primeSchedule] || ! AllTrue[primeSchedule, # > 2 && PrimeQ[#] &],
    fail["InvalidPrimeSchedule"]];
  images = {}; reconstructed = <||>; keys = {};
  Module[{needed = primeCount, converged = False, lifted, usedPrimes,
     failingKey = None, failingEntry = None, failingResidues = None},
    scheduleIndex = 0; usedPrimes = {};
    While[! converged,
      (* A prime at which a leaf is undefined or a pole/curve factor
         degenerates is skipped and recorded.  Only exhaustion is terminal:
         distinct exceptional primes need not share a mathematical cause. *)
      While[Length[images] < needed,
        scheduleIndex++;
        If[scheduleIndex > Length[primeSchedule], fail["PrimeScheduleExhausted", <|"SkippedPrimes" -> skippedPrimes|>]];
        With[{p = primeSchedule[[scheduleIndex]], image = recurrenceImage[primeSchedule[[scheduleIndex]]]},
          If[image["Status"] === "RecurrenceImageEvaluated",
            AppendTo[images, image]; AppendTo[usedPrimes, p],
            If[image["Status"] === "CurveBranchPoleNotSupported",
              fail[image["Status"], <|"Prime" -> p|>],
              AppendTo[skippedPrimes, <|"Prime" -> p, "Status" -> image["Status"]|>]]]];
        ];
      keys = Union @@ (Keys[#["KResidues"]] & /@ images);
      reconstructed = <||>; converged = True;
      Do[
        lifted = Table[Table[
            With[{residues = Table[Lookup[images[[pi]]["KResidues"], Key[key], ConstantArray[0, {d, n}]][[i, j]], {pi, Length[images]}]},
              With[{crt = modularCRT[residues, usedPrimes]},
                If[crt === $Failed, $Failed, modularRationalReconstruct[crt, Times @@ usedPrimes]]]],
            {j, n}], {i, d}];
        If[! FreeQ[lifted, $Failed],
          converged = False;
          failingKey = key; failingEntry = First[Position[lifted, $Failed, {2}, 1]];
          failingResidues = Table[Lookup[images[[pi]]["KResidues"], Key[key], ConstantArray[0, {d, n}]][[failingEntry[[1]], failingEntry[[2]]]], {pi, Length[images]}];
          Break[]];
        reconstructed[key] = lifted,
        {key, keys}];
      (* The gauge is either lifted at one rational endpoint, or coefficientwise
         as a rational function when the endpoint is the remaining kinematic
         variable. *)
      gaugeAtEndpoint = <||>; gaugeFunctions = <||>;
      If[converged,
        If[gaugeRepresentation === "EndpointValue",
          Do[
            lifted = Table[Table[
                With[{residues = Table[images[[pi]]["HEndpoint"][order][[i, j]],
                    {pi, Length[images]}]},
                  With[{crt = modularCRT[residues, usedPrimes]},
                    If[crt === $Failed, $Failed,
                      modularRationalReconstruct[crt, Times @@ usedPrimes]]]],
                {j, n}], {i, d}];
            If[! FreeQ[lifted, $Failed], converged = False;
              failingKey = {"Gauge", order}; Break[]];
            gaugeAtEndpoint[order] = lifted,
            {order, orders}],
          Do[
            lifted = Table[Table[
                rationalLayerReconstructFunction[
                  Table[images[[pi]]["HImages"][order][[i, j]],
                    {pi, Length[images]}], usedPrimes, u],
                {j, n}], {i, d}];
            If[! FreeQ[lifted, $Failed], converged = False;
              failingKey = {"GaugeFunction", order}; Break[]];
            gaugeFunctions[order] = lifted,
            {order, orders}]]];
      If[! converged,
        If[needed >= maximumPrimeCount,
          fail["ReconstructionNotConverged", <|"PrimeCount" -> Length[images],
            "MaximumPrimeCount" -> maximumPrimeCount,
            "Key" -> failingKey, "Entry" -> failingEntry, "Residues" -> failingResidues,
            "Primes" -> usedPrimes|>]];
        needed = Min[needed + Max[1, Ceiling[needed/2]], maximumPrimeCount]]];
    (* N2: the fresh prime goes through the same skip-and-record loop *)
    freshImage = None;
    While[freshImage === None,
      scheduleIndex++;
      If[scheduleIndex > Length[primeSchedule], fail["PrimeScheduleExhausted", <|"SkippedPrimes" -> skippedPrimes, "Stage" -> "FreshPrime"|>]];
      With[{p = primeSchedule[[scheduleIndex]]},
        If[MemberQ[usedPrimes, p], Continue[]];
        With[{image = recurrenceImage[p]},
          If[image["Status"] === "RecurrenceImageEvaluated",
            freshImage = image; freshPrime = p,
            If[image["Status"] === "CurveBranchPoleNotSupported",
              fail[image["Status"], <|"Prime" -> p|>],
              AppendTo[skippedPrimes, <|"Prime" -> p, "Status" -> image["Status"]|>]]]]];
      ];
    primes = usedPrimes];
  If[verbose, observableTransportMilestone["Rational layer: ", Length[primes], " prime images of the recurrence, ",
    Length[keys], " residue keys reconstructed, ", Round[AbsoluteTime[] - start, 0.1], " s"]];
  (* fresh-prime validation *)
  gaugeComparisons = 0; gaugeMismatches = 0;
  If[gaugeRepresentation === "EndpointValue",
    Do[With[{image = freshImage["HEndpoint"][order], exact = gaugeAtEndpoint[order]},
        Do[gaugeComparisons++;
          If[Mod[Numerator[exact[[i, j]]] - image[[i, j]] Denominator[exact[[i, j]]], freshPrime] =!= 0,
            gaugeMismatches++], {i, d}, {j, n}]], {order, orders}],
    gaugeFunctionCheck = rationalLayerGaugeFunctionCheck[gaugeFunctions,
      freshImage["HImages"], orders, u, freshPrime, seed];
    If[Lookup[gaugeFunctionCheck, "Status", None] =!= "GaugeFunctionChecked",
      fail[Lookup[gaugeFunctionCheck, "Status", "GaugeFunctionValidationFailed"]]];
    gaugeComparisons = gaugeFunctionCheck["Comparisons"];
    gaugeMismatches = gaugeFunctionCheck["Mismatches"]];
  If[gaugeMismatches > 0, fail["FreshPrimeValidationFailed", <|"Gauge" -> True, "Mismatches" -> gaugeMismatches, "Comparisons" -> gaugeComparisons|>]];
  Do[
    With[{image = Lookup[freshImage["KResidues"], Key[key], ConstantArray[0, {d, n}]], exact = reconstructed[key]},
      Do[comparisons++;
        If[Mod[Numerator[exact[[i, j]]] - image[[i, j]] Denominator[exact[[i, j]]], freshPrime] =!= 0, mismatches++],
        {i, d}, {j, n}]],
    {key, Union[keys, Keys[freshImage["KResidues"]]]}];
  If[mismatches > 0, fail["FreshPrimeValidationFailed", <|"Mismatches" -> mismatches, "Comparisons" -> comparisons|>]];
  ];   (* end of the modular route *)
  If[! directQ && gaugeRepresentation === "RationalFunction",
    gaugeAtEndpoint = Association@KeyValueMap[
      #1 -> Map[# /. u -> endpoint &, #2, {2}] &, gaugeFunctions]];
  hImageCount = If[images === {}, 0, Total[Length /@ Lookup[images, "HImages"]]];
  sourceBoundaryCount = Length[First[Values[source["BoundarySelectors"]]][[1]]];
  {targetSelectors, targetBoundaryCount} =
    rationalLayerTargetSelectors[layer, d, sharedBoundaryQ];
  If[wordRepresentation === "LazyOperator",
    (* The returned K/source/diagonal data are the operator.  No source state
       and no word is constructed on this route; MaximumStates/MaximumWords
       therefore cannot turn a valid lazy transport into a census refusal. *)
    neededWeight = None; maximumWeight = None; sourceStates = <||>; words = None,
    (* Materialized words.  The weight a+b is derived from the actual nonzero
       K orders; absent K orders must not trigger fictitious source growth. *)
    activeIncomingOrders = DeleteDuplicates[First /@ Keys[
      Select[reconstructed, ! AllTrue[Flatten[#], # === 0 &] &]]];
    neededWeight = Max[Join[
      Select[Flatten[Table[pair[[1]] - q - r, {pair, demandPairs},
        {q, Keys[source["BoundarySelectors"]]}, {r, activeIncomingOrders}]], # >= 0 &],
      Select[Flatten[Table[pair[[1]] - q, {pair, demandPairs},
        {q, Keys[targetSelectorInput]}]], # >= 0 &], {0}]];
    maximumWeight = Replace[OptionValue["MaximumWeight"], Automatic -> neededWeight];
    If[! IntegerQ[maximumWeight] || maximumWeight < 0, fail["InvalidMaximumWeight"]];
    weightCapped = maximumWeight < neededWeight;
    weightByOrder = Association@Table[q -> With[{weights = Select[
          Flatten[Table[pair[[1]] - q - r, {pair, demandPairs}, {r, activeIncomingOrders}]], # >= 0 &]},
        If[weights === {}, -1, Max[weights]]], {q, Keys[source["BoundarySelectors"]]}];
    sourceStates = rationalLayerSourceStates[source, maximumWeight, weightByOrder, OptionValue["MaximumStates"]];
    If[verbose, observableTransportMilestone["Rational layer: source words grown to weight ", maximumWeight, ": ",
      Total[Length /@ Flatten[Values[sourceStates], 1]], " states, ", Round[AbsoluteTime[] - start, 0.1], " s"]];
    words = Association@Table[pair -> rationalLayerWords[pair[[1]], pair[[2]], diagonal, reconstructed, source,
        targetSelectors, sourceBoundaryCount, targetBoundaryCount, maximumWeight, OptionValue["MaximumWords"],
        sourceStates, sharedBoundaryQ], {pair, demandPairs}];
    cappedPairs = Keys[Select[words, AssociationQ]];
    If[weightCapped || cappedPairs =!= {},
      Throw[<|"Status" -> If[weightCapped, "WordWeightCapReached", "WordEnumerationCapped"],
        "NeededWeight" -> neededWeight, "MaximumWeight" -> maximumWeight,
        "MaximumWords" -> OptionValue["MaximumWords"], "CappedPairs" -> cappedPairs,
        "DroppedCombinations" -> Total[Lookup[#, "DroppedCombinations", 0] & /@ Values[Select[words, AssociationQ]]],
        "DemandedWords" -> words, "Window" -> {low, high}|>]];
    If[verbose, observableTransportMilestone["Rational layer: demanded words ",
      Total[If[AssociationQ[#], Length[#["Words"]], Length[#]] & /@ Values[words]],
      ", ", Round[AbsoluteTime[] - start, 0.1], " s"]]];
  operatorSource = <|"Dimension" -> n, "Letters" -> source["Letters"],
    "Residues" -> source["Residues"],
    "BoundarySelectors" -> source["BoundarySelectors"]|>;
  operatorLayer = <|"Rows" -> rows, "Diagonal" -> diagonal,
    "TargetBoundarySelectors" -> targetSelectorInput,
    "SharedBoundaryCoordinates" -> sharedBoundaryQ,
    "PathVariable" -> u, "Regulator" -> eps, "BasePoint" -> base,
    "Endpoint" -> endpoint, "Curve" -> If[curveQ, curve, None],
    "CurvePointValues" -> If[curveQ, curvePointValues, <||>]|>;
  certificate = <|"Status" -> "RationalEpsilonLayerTransportAccepted",
    "IncomingRoute" -> If[directQ, "IncomingDlogDirect", "SealedModularCircuit"],
    "Probabilistic" -> ! directQ, "Exact" -> directQ,
    "Primes" -> primes, "FreshValidationPrime" -> freshPrime,
    "ResidueComparisons" -> comparisons, "ResidueMismatches" -> mismatches,
    "ReconstructedResidueKeys" -> Length[keys],
    "GaugeImages" -> hImageCount,
    "GaugeReconstructed" -> ! directQ,
    "GaugeRepresentation" -> If[directQ, "Zero",
      gaugeRepresentation],
    "GaugeComparisons" -> gaugeComparisons, "GaugeMismatches" -> gaugeMismatches,
    "GaugeValidationPoint" -> Lookup[gaugeFunctionCheck, "Point", None],
    "Endpoint" -> endpoint,
    "Alphabet" -> gate["Verdicts"],
    "PoleFactors" -> factors,
    "Valuations" -> valuations, "ValuationProbePoints" -> probePoints,
    "SkippedPrimes" -> skippedPrimes,
    "RegularizationRequired" -> regularization,
    "WordRepresentation" -> wordRepresentation,
    "SharedBoundaryCoordinates" -> sharedBoundaryQ,
    "CurveChannel" -> curveQ,
    "Curve" -> If[curveQ, curve, None],
    "Window" -> {low, high},
    "Seed" -> seed|>;
  <|"Status" -> "RationalEpsilonLayerTransportAccepted",
    "Rows" -> rows, "PathVariable" -> u, "Regulator" -> eps, "BasePoint" -> base,
    "Window" -> {low, high},
    "DemandPairs" -> demandPairs,
    "OperatorSource" -> operatorSource,
    "OperatorLayer" -> operatorLayer,
    "RegularizationRequired" -> regularization,
    "KResidues" -> reconstructed,
    "GaugeImages" -> If[directQ, <||>, Association@Table[primes[[pi]] -> images[[pi]]["HImages"], {pi, Length[primes]}]],
    "GaugeAtEndpoint" -> If[directQ, Association@Table[order -> ConstantArray[0, {d, n}], {order, orders}], gaugeAtEndpoint],
    "GaugeFunctions" -> If[! directQ && gaugeRepresentation === "RationalFunction",
      gaugeFunctions, <||>],
    "Endpoint" -> endpoint,
    "GaugeStatus" -> Which[directQ, "GaugeVanishes",
      gaugeRepresentation === "RationalFunction", "GaugeRationalFunctionReconstructed",
      True, "GaugeReconstructedAtEndpoint"],
    "DemandedWords" -> words,
    "WordRepresentation" -> wordRepresentation,
    "SharedBoundaryCoordinates" -> sharedBoundaryQ,
    "CurveChannel" -> curveQ,
    "Curve" -> If[curveQ, curve, None],
    "BoundaryColumns" -> If[sharedBoundaryQ, sourceBoundaryCount,
      sourceBoundaryCount + targetBoundaryCount],
    "Certificate" -> certificate,
    "Seconds" -> N[AbsoluteTime[] - start]|>
];

rationalLayerCertificateShapeQ[certificate_] := AssociationQ[certificate] &&
  Lookup[certificate, "Status", None] === "RationalEpsilonLayerTransportAccepted" &&
  MatchQ[Lookup[certificate, "Alphabet", None], {__Association}] &&
  AllTrue[certificate["Alphabet"], #["Status"] === "Admitted" &] &&
  IntegerQ[Lookup[certificate, "ResidueComparisons", None]] &&
  certificate["ResidueComparisons"] >= 0 &&
  Lookup[certificate, "ResidueMismatches", -1] === 0 &&
  Lookup[certificate, "RegularizationRequired", None] ===
    <|"BasePoint" -> {}, "Endpoint" -> {}|> &&
  Which[
    Lookup[certificate, "IncomingRoute", None] === "SealedModularCircuit",
      TrueQ[certificate["Probabilistic"]] && certificate["Exact"] === False &&
      MatchQ[Lookup[certificate, "Primes", None], {__Integer}] &&
      DuplicateFreeQ[certificate["Primes"]] &&
      AllTrue[certificate["Primes"], # > 2 && PrimeQ[#] &] &&
      IntegerQ[Lookup[certificate, "FreshValidationPrime", None]] &&
      PrimeQ[certificate["FreshValidationPrime"]] &&
      ! MemberQ[certificate["Primes"], certificate["FreshValidationPrime"]] &&
      TrueQ[Lookup[certificate, "GaugeReconstructed", False]] &&
      IntegerQ[Lookup[certificate, "GaugeComparisons", None]] &&
      certificate["GaugeComparisons"] > 0 &&
      Lookup[certificate, "GaugeMismatches", -1] === 0 &&
      MemberQ[{"EndpointValue", "RationalFunction"},
        Lookup[certificate, "GaugeRepresentation", "EndpointValue"]],
    Lookup[certificate, "IncomingRoute", None] === "IncomingDlogDirect",
      TrueQ[certificate["Exact"]] && certificate["Probabilistic"] === False &&
      Lookup[certificate, "Primes", None] === {} &&
      Lookup[certificate, "FreshValidationPrime", Missing[]] === None &&
      Lookup[certificate, "GaugeReconstructed", True] === False &&
      Lookup[certificate, "GaugeRepresentation", "Zero"] === "Zero",
    True, False];

(* One argument checks the accepted record's structural and semantic contract.
   It deliberately does not pretend that hashes prove the mathematics; use
   the four-argument form for a fresh modular evaluation (or exact direct
   reconstruction) against the inputs. *)
AcceptedRationalEpsilonLayerTransportQ[result_] := Module[
  {certificate, route, window, orders, rows, gauge, gaugeFunctions,
   gaugeRepresentation, gaugeDimensions,
   kResidues, words, demandPairs, regularization, wordRepresentation,
   sharedBoundaryQ, operatorSource, operatorLayer, sourceDimension,
   sourceSelectors, targetSelectors, sourceWidth, targetWidth},
  If[! AssociationQ[result] ||
      Lookup[result, "Status", None] =!= "RationalEpsilonLayerTransportAccepted",
    Return[False]];
  certificate = Lookup[result, "Certificate", None];
  If[! rationalLayerCertificateShapeQ[certificate], Return[False]];
  window = Lookup[result, "Window", None];
  rows = Lookup[result, "Rows", None];
  demandPairs = Lookup[result, "DemandPairs", None];
  gauge = Lookup[result, "GaugeAtEndpoint", None];
  gaugeFunctions = Lookup[result, "GaugeFunctions", <||>];
  gaugeRepresentation = Lookup[certificate, "GaugeRepresentation",
    If[Lookup[certificate, "IncomingRoute", None] === "IncomingDlogDirect",
      "Zero", "EndpointValue"]];
  kResidues = Lookup[result, "KResidues", None];
  words = Lookup[result, "DemandedWords", None];
  regularization = Lookup[result, "RegularizationRequired", None];
  wordRepresentation = Lookup[result, "WordRepresentation", None];
  sharedBoundaryQ = Lookup[result, "SharedBoundaryCoordinates", None];
  operatorSource = Lookup[result, "OperatorSource", None];
  operatorLayer = Lookup[result, "OperatorLayer", None];
  If[! MatchQ[window, {_Integer, _Integer}] || window[[1]] > window[[2]] ||
      ! ListQ[rows] || rows === {} ||
      ! MatchQ[demandPairs, {{_Integer, _Integer} ..}] || ! DuplicateFreeQ[demandPairs] ||
      ! AllTrue[demandPairs, 1 <= #[[2]] <= Length[rows] &] ||
      ! AssociationQ[gauge] || ! AssociationQ[gaugeFunctions] ||
      ! AssociationQ[kResidues] ||
      ! MemberQ[{"MaterializedWords", "LazyOperator"}, wordRepresentation] ||
      ! BooleanQ[sharedBoundaryQ] ||
      ! IntegerQ[Lookup[result, "BoundaryColumns", None]] || result["BoundaryColumns"] < 1 ||
      Lookup[certificate, "WordRepresentation", None] =!= wordRepresentation ||
      Lookup[certificate, "SharedBoundaryCoordinates", None] =!= sharedBoundaryQ,
    Return[False]];
  If[! AssociationQ[operatorSource] || ! AssociationQ[operatorLayer] ||
      Sort[Keys[operatorSource]] =!= Sort[{"Dimension", "Letters", "Residues",
        "BoundarySelectors"}] ||
      Sort[Keys[operatorLayer]] =!= Sort[{"Rows", "Diagonal",
        "TargetBoundarySelectors", "SharedBoundaryCoordinates", "PathVariable",
        "Regulator", "BasePoint", "Endpoint", "Curve", "CurvePointValues"}],
    Return[False]];
  sourceDimension = Lookup[operatorSource, "Dimension", None];
  sourceSelectors = Lookup[operatorSource, "BoundarySelectors", None];
  targetSelectors = Lookup[operatorLayer, "TargetBoundarySelectors", None];
  If[! IntegerQ[sourceDimension] || sourceDimension < 1 ||
      ! ListQ[operatorSource["Letters"]] || ! ListQ[operatorSource["Residues"]] ||
      Length[operatorSource["Letters"]] =!= Length[operatorSource["Residues"]] ||
      ! AllTrue[operatorSource["Residues"], Dimensions[#] ===
        {sourceDimension, sourceDimension} &] ||
      ! AssociationQ[sourceSelectors] || sourceSelectors === <||> ||
      ! VectorQ[Keys[sourceSelectors], IntegerQ] ||
      ! AllTrue[Values[sourceSelectors], MatrixQ[#] &&
        Dimensions[#][[1]] === sourceDimension && Dimensions[#][[2]] >= 1 &] ||
      ! (SameQ @@ (Dimensions[#][[2]] & /@ Values[sourceSelectors])) ||
      Lookup[operatorLayer, "Rows", None] =!= rows ||
      ! MatchQ[Lookup[operatorLayer, "Diagonal", None], {{_List, _?MatrixQ} ..}] ||
      ! AllTrue[operatorLayer["Diagonal"], Dimensions[#[[2]]] ===
        {Length[rows], Length[rows]} &] ||
      ! AssociationQ[targetSelectors] || targetSelectors === <||> ||
      ! VectorQ[Keys[targetSelectors], IntegerQ] ||
      ! AllTrue[Values[targetSelectors], MatrixQ[#] &&
        Dimensions[#][[1]] === Length[rows] && Dimensions[#][[2]] >= 1 &] ||
      Lookup[operatorLayer, "SharedBoundaryCoordinates", None] =!= sharedBoundaryQ ||
      Lookup[operatorLayer, "PathVariable", Missing[]] =!=
        Lookup[result, "PathVariable", Missing[]] ||
      Lookup[operatorLayer, "Regulator", Missing[]] =!=
        Lookup[result, "Regulator", Missing[]] ||
      Lookup[operatorLayer, "BasePoint", Missing[]] =!=
        Lookup[result, "BasePoint", Missing[]] ||
      Lookup[operatorLayer, "Endpoint", Missing[]] =!=
        Lookup[result, "Endpoint", Missing[]] ||
      Lookup[operatorLayer, "Curve", Missing[]] =!=
        Lookup[result, "Curve", Missing[]] ||
      ! AssociationQ[Lookup[operatorLayer, "CurvePointValues", None]],
    Return[False]];
  sourceWidth = Dimensions[First[Values[sourceSelectors]]][[2]];
  If[sharedBoundaryQ &&
      (! (SameQ @@ (Dimensions[#][[2]] & /@ Values[targetSelectors])) ||
       Dimensions[First[Values[targetSelectors]]][[2]] =!= sourceWidth),
    Return[False]];
  targetWidth = If[sharedBoundaryQ, sourceWidth,
    Total[Dimensions[#][[2]] & /@ Values[targetSelectors]]];
  If[Lookup[result, "BoundaryColumns", None] =!=
      If[sharedBoundaryQ, sourceWidth, sourceWidth + targetWidth], Return[False]];
  If[! BooleanQ[Lookup[result, "CurveChannel", None]] ||
      Lookup[certificate, "CurveChannel", None] =!= result["CurveChannel"] ||
      Lookup[certificate, "Curve", Missing[]] =!= Lookup[result, "Curve", Missing[]],
    Return[False]];
  If[If[wordRepresentation === "MaterializedWords",
      ! AssociationQ[words] || Sort[Keys[words]] =!= Sort[demandPairs] ||
        ! AllTrue[Values[words], ListQ],
      words =!= None], Return[False]];
  orders = Range[window[[1]], window[[2]]];
  If[Sort[Keys[gauge]] =!= orders ||
      ! AllTrue[Values[gauge], MatrixQ[#] && Dimensions[#][[1]] === Length[rows] &&
        Dimensions[#][[2]] >= 1 &], Return[False]];
  gaugeDimensions = Dimensions[First[Values[gauge]]];
  If[gaugeDimensions =!= {Length[rows], sourceDimension} ||
      ! AllTrue[Values[gauge], Dimensions[#] === gaugeDimensions &] ||
      ! AllTrue[Values[kResidues], MatrixQ[#] && Dimensions[#] === gaugeDimensions &],
    Return[False]];
  If[regularization =!= <|"BasePoint" -> {}, "Endpoint" -> {}|> ||
      Lookup[certificate, "RegularizationRequired", None] =!= regularization ||
      Lookup[certificate, "Endpoint", Missing[]] =!= Lookup[result, "Endpoint", Missing[]] ||
      Lookup[certificate, "Window", None] =!= window, Return[False]];
  route = certificate["IncomingRoute"];
  Which[
    route === "IncomingDlogDirect",
      Lookup[result, "GaugeStatus", None] === "GaugeVanishes" &&
      Lookup[result, "GaugeImages", None] === <||> &&
      gaugeFunctions === <||> && gaugeRepresentation === "Zero" &&
      AllTrue[Values[gauge], AllTrue[Flatten[#], # === 0 &] &],
    route === "SealedModularCircuit",
      AssociationQ[Lookup[result, "GaugeImages", None]] &&
      Sort[Keys[result["GaugeImages"]]] === Sort[certificate["Primes"]] &&
      AllTrue[Values[result["GaugeImages"]], AssociationQ[#] && Sort[Keys[#]] === orders &] &&
      Lookup[certificate, "GaugeImages", -1] === Length[orders] Length[certificate["Primes"]] &&
      Which[
        gaugeRepresentation === "EndpointValue",
          Lookup[result, "GaugeStatus", None] === "GaugeReconstructedAtEndpoint" &&
          MatchQ[Lookup[result, "Endpoint", None], _Integer | _Rational] &&
          gaugeFunctions === <||>,
        gaugeRepresentation === "RationalFunction",
          Lookup[result, "GaugeStatus", None] === "GaugeRationalFunctionReconstructed" &&
          MatchQ[Lookup[result, "Endpoint", None], _Symbol] &&
          result["Endpoint"] =!= None && result["Endpoint"] =!= result["PathVariable"] &&
          Sort[Keys[gaugeFunctions]] === orders &&
          AllTrue[Values[gaugeFunctions], MatrixQ[#] && Dimensions[#] === gaugeDimensions &] &&
          gauge === Association@KeyValueMap[
            #1 -> Map[# /. result["PathVariable"] -> result["Endpoint"] &, #2, {2}] &,
            gaugeFunctions],
        True, False],
    True, False]
];

(* Four arguments re-derive the prepared problem from the supplied inputs,
   then re-verify the residues and gauge: exactly on the direct route, at a
   new prime on the modular route. *)
AcceptedRationalEpsilonLayerTransportQ[result_, source_Association, layer_Association, demand_Association] := Module[
  {certificate, prepared, newPrime = None, image = None, candidate, trial,
   excludedPrimes, d, n, ok, wordsAgreeQ, expectedOperatorSource,
   expectedOperatorLayer, gaugeCheck},
  If[! AcceptedRationalEpsilonLayerTransportQ[result], Return[False]];
  certificate = result["Certificate"];
  prepared = BuildRationalEpsilonLayerTransport[source, layer, demand, "PrepareOnly" -> True,
    "Seed" -> Lookup[certificate, "Seed", 20260902],
    "IncomingRoute" -> If[Lookup[certificate, "IncomingRoute", None] === "SealedModularCircuit", "Modular", Automatic],
    "GaugeRepresentation" -> If[
      Lookup[certificate, "IncomingRoute", None] === "IncomingDlogDirect",
      Automatic, Lookup[certificate, "GaugeRepresentation",
        If[MatchQ[Lookup[result, "Endpoint", None], _Integer | _Rational],
          "EndpointValue", "RationalFunction"]]],
    "WordRepresentation" -> Lookup[result, "WordRepresentation", Automatic]];
  If[Lookup[prepared, "Status", None] =!= "Prepared" || prepared["Window"] =!= result["Window"], Return[False]];
  expectedOperatorSource = <|"Dimension" -> prepared["Dimensions"][[2]],
    "Letters" -> prepared["Source"]["Letters"],
    "Residues" -> prepared["Source"]["Residues"],
    "BoundarySelectors" -> prepared["Source"]["BoundarySelectors"]|>;
  expectedOperatorLayer = <|"Rows" -> prepared["Rows"],
    "Diagonal" -> prepared["Diagonal"],
    "TargetBoundarySelectors" -> Lookup[layer, "TargetBoundarySelectors",
      <|0 -> IdentityMatrix[prepared["Dimensions"][[1]]]|>],
    "SharedBoundaryCoordinates" -> prepared["SharedBoundaryCoordinates"],
    "PathVariable" -> prepared["PathVariable"],
    "Regulator" -> prepared["Regulator"],
    "BasePoint" -> prepared["BasePoint"], "Endpoint" -> prepared["Endpoint"],
    "Curve" -> If[prepared["CurveQ"], prepared["Curve"], None],
    "CurvePointValues" -> If[prepared["CurveQ"],
      prepared["CurvePointValues"], <||>]|>;
  If[Lookup[result, "OperatorSource", None] =!= expectedOperatorSource ||
      Lookup[result, "OperatorLayer", None] =!= expectedOperatorLayer,
    Return[False]];
  (* N1: the payload fields must be the inputs' *)
  If[prepared["Endpoint"] =!= Lookup[result, "Endpoint", None] || prepared["Rows"] =!= Lookup[result, "Rows", None] ||
      prepared["BasePoint"] =!= Lookup[result, "BasePoint", None] || prepared["DemandPairs"] =!= Lookup[result, "DemandPairs", None] ||
      (! prepared["DirectQ"] && prepared["GaugeRepresentation"] =!=
        Lookup[certificate, "GaugeRepresentation", "EndpointValue"]) ||
      prepared["WordRepresentation"] =!= Lookup[result, "WordRepresentation", None] ||
      prepared["SharedBoundaryCoordinates"] =!= Lookup[result, "SharedBoundaryCoordinates", None] ||
      prepared["CurveQ"] =!= Lookup[result, "CurveChannel", None] ||
      If[prepared["CurveQ"], prepared["Curve"] =!= Lookup[result, "Curve", None],
        Lookup[result, "Curve", Missing[]] =!= None], Return[False]];
  If[prepared["DirectQ"] =!= (certificate["IncomingRoute"] === "IncomingDlogDirect"), Return[False]];
  With[{sourceWidth = Dimensions[First[Values[source["BoundarySelectors"]]]][[2]],
        targetWidth = Last[rationalLayerTargetSelectors[layer,
          prepared["Dimensions"][[1]], prepared["SharedBoundaryCoordinates"]]]},
    If[Lookup[result, "BoundaryColumns", None] =!=
        If[prepared["SharedBoundaryCoordinates"], sourceWidth,
          sourceWidth + targetWidth], Return[False]]];
  (* N1: every demanded word re-enumerated from the (re-verified) residues *)
  wordsAgreeQ[residues_] := Module[{targetSelectors, targetBoundaryCount, sourceBoundaryCount, orders = prepared["Orders"],
      demandPairs = prepared["DemandPairs"], neededWeight, weightByOrder, sourceStates,
      activeIncomingOrders},
    {targetSelectors, targetBoundaryCount} = rationalLayerTargetSelectors[layer,
      prepared["Dimensions"][[1]], prepared["SharedBoundaryCoordinates"]];
    sourceBoundaryCount = Length[First[Values[source["BoundarySelectors"]]][[1]]];
    activeIncomingOrders = DeleteDuplicates[First /@ Keys[
      Select[residues, ! AllTrue[Flatten[#], # === 0 &] &]]];
    neededWeight = Max[Join[
      Select[Flatten[Table[pair[[1]] - q - r, {pair, demandPairs},
        {q, Keys[source["BoundarySelectors"]]}, {r, activeIncomingOrders}]], # >= 0 &],
      Select[Flatten[Table[pair[[1]] - q, {pair, demandPairs},
        {q, Keys[targetSelectors]}]], # >= 0 &], {0}]];
    weightByOrder = Association@Table[q -> With[{weights = Select[
          Flatten[Table[pair[[1]] - q - r, {pair, demandPairs}, {r, activeIncomingOrders}]], # >= 0 &]},
        If[weights === {}, -1, Max[weights]]], {q, Keys[source["BoundarySelectors"]]}];
    sourceStates = Catch[rationalLayerSourceStates[source, neededWeight, weightByOrder]];
    If[! AssociationQ[sourceStates] || KeyExistsQ[sourceStates, "Status"], Return[False, Module]];
    And @@ Table[rationalLayerWords[pair[[1]], pair[[2]], prepared["Diagonal"], residues, source, targetSelectors,
        sourceBoundaryCount, targetBoundaryCount, neededWeight, Infinity, sourceStates,
        prepared["SharedBoundaryCoordinates"]] === result["DemandedWords"][pair], {pair, demandPairs}]];
  If[prepared["DirectQ"],
    Return[KeySort[prepared["DirectResidues"]] === KeySort[result["KResidues"]] &&
      (result["WordRepresentation"] === "LazyOperator" || wordsAgreeQ[prepared["DirectResidues"]])]];
  (* Modular: try bounded fresh primes outside the construction certificate.
     A prime where a denominator or pole factor degenerates is exceptional,
     not evidence against an otherwise valid record. *)
  excludedPrimes = Join[certificate["Primes"], {certificate["FreshValidationPrime"]}];
  BlockRandom[SeedRandom[Lookup[certificate, "Seed", 0] + 104729];
    Do[
      candidate = RandomPrime[{2^30, 2^31 - 1}];
      If[MemberQ[excludedPrimes, candidate], Continue[]];
      trial = If[prepared["CurveQ"],
        rationalLayerCurveRecurrenceImage[prepared["Laurent"], prepared["Diagonal"], prepared["Source"],
          prepared["Factors"], prepared["PathVariable"], prepared["Curve"],
          prepared["CurvePointValues"], prepared["BasePoint"], prepared["CurveBaseValue"],
          prepared["Orders"], candidate,
          If[prepared["GaugeRepresentation"] === "EndpointValue",
            prepared["Endpoint"], None], prepared["CurveEndpointValue"]],
        rationalLayerRecurrenceImage[prepared["Laurent"], prepared["Diagonal"], prepared["Source"],
          prepared["Factors"], prepared["PathVariable"], prepared["BasePoint"], prepared["Orders"], candidate,
          If[prepared["GaugeRepresentation"] === "EndpointValue",
            prepared["Endpoint"], None]]];
      If[Lookup[trial, "Status", None] === "RecurrenceImageEvaluated",
        newPrime = candidate; image = trial; Break[]],
      {64}]];
  If[newPrime === None, Return[False]];
  {d, n} = prepared["Dimensions"];
  ok = And @@ Flatten[Table[
      With[{exact = Lookup[result["KResidues"], Key[key], ConstantArray[0, {d, n}]], img = Lookup[image["KResidues"], Key[key], ConstantArray[0, {d, n}]]},
        Table[Mod[Numerator[exact[[i, j]]] - img[[i, j]] Denominator[exact[[i, j]]], newPrime] === 0, {i, d}, {j, n}]],
      {key, Union[Keys[result["KResidues"]], Keys[image["KResidues"]]]}]];
  If[prepared["GaugeRepresentation"] === "EndpointValue",
    ok = ok && And @@ Flatten[Table[
        With[{exact = result["GaugeAtEndpoint"][order], img = image["HEndpoint"][order]},
          Table[Mod[Numerator[exact[[i, j]]] - img[[i, j]] Denominator[exact[[i, j]]], newPrime] === 0,
            {i, d}, {j, n}]], {order, prepared["Orders"]}]],
    gaugeCheck = rationalLayerGaugeFunctionCheck[result["GaugeFunctions"],
      image["HImages"], prepared["Orders"], prepared["PathVariable"],
      newPrime, Lookup[certificate, "Seed", 0] + 104729];
    ok = ok && Lookup[gaugeCheck, "Status", None] === "GaugeFunctionChecked" &&
      Lookup[gaugeCheck, "Mismatches", -1] === 0];
  ok && (result["WordRepresentation"] === "LazyOperator" ||
    wordsAgreeQ[result["KResidues"]])
];
AcceptedRationalEpsilonLayerTransportQ[___] := False;
