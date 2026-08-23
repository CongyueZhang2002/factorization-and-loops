(* Epsilon forms of irreducible diagonal blocks (the hard-class stage-1
   problem) on the finite-field affine machinery.

   The transformation equation of a diagonal block,
       dT = A T - T (eps Sum_a R_a dlog phi_a),
   is bilinear in (T, R_a), so the off-diagonal affine sampler cannot be
   pointed at it directly.  The route implemented here linearizes it in
   three exact steps:

     1. ONE slice.  At a generic rational value y0 of the spectator the
        block is a one-variable system; Lee's balances (Libra) normalize
        it and Lee's linear factor-out step gives the slice epsilon form
        with constant residues.  Every letter that depends on x appears
        as a slice locus, so this fixes R_a for all x-dependent letters
        (in one constant frame).
     2. The x-equation  d_x T = A_x T - T B_x,  B_x = eps Sum_a R_a
        d_x log phi_a, is then a homogeneous LINEAR system for a
        rational T with pure-letter denominators.  It is solved by
        finite-field sampling (ansatz numerator over a letter
        denominator, affine system at kinematic points modulo primes,
        regulator interpolation, Chinese remaindering, rational
        reconstruction) and checked exactly.  Its rational solution
        space is one-dimensional up to scalar functions of y.
     3. The y-direction is then determined exactly:  T^-1 A_y T -
        T^-1 d_y T minus the known letters must equal eps times constant
        residues of the pure-y letters plus a scalar dlog with integer
        residues (the rational scalar gauge c).  Both are read off from
        one exact partial-fraction decomposition.

   The only acceptance is the two-variable gate: the ORIGINAL system
   pushed through T equals eps Sum_a R_a dlog phi_a entrywise in both
   variables with constant R_a, the form is flat, and T is invertible.
   Slice data, sampled solutions and interpolations are candidate
   generators; the certificate is the exact gate.

   Terminology: "diagonal block" = a block of the block-triangular
   family connection; this file treats one block in isolation.
*)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[DiagonalBlockLetters, DiagonalBlockSliceEpsForm, SolveDiagonalBlockGaugeFiniteField, CompleteDiagonalBlockEpsForm, CertifyDiagonalBlockEpsForm, DiagonalBlockEpsForm];
ClearAll[
  diagonalBlockTogether,
  diagonalBlockZeroQ,
  diagonalBlockSameLetterQ,
  diagonalBlockDenominatorFactors,
  diagonalBlockLinearRoot,
  diagonalBlockResidueAt,
  diagonalBlockResidueAtInfinity,
  diagonalBlockSliceSpectra,
  diagonalBlockSliceNormalizedQ,
  diagonalBlockSliceIntegerExponentsQ,
  diagonalBlockSliceBadness,
  diagonalBlockMaskCombinations,
  diagonalBlockLeeStep,
  diagonalBlockFactorOut,
  diagonalBlockGenericSlicePointQ,
  diagonalBlockNumericBalance,
  diagonalBlockNumericProjector,
  diagonalBlockNumericExponent,
  diagonalBlockNumericSpectra,
  diagonalBlockNumericNormalizedQ,
  diagonalBlockNumericBadness,
  diagonalBlockNumericEigenvectors,
  diagonalBlockNumericLeeStep,
  diagonalBlockNumericSlice,
  diagonalBlockCanonicalFrame,
  diagonalBlockPolynomialRules,
  diagonalBlockRationalRules,
  diagonalBlockEvaluateRules,
  diagonalBlockPrepareSampling,
  diagonalBlockMultiplicityCensus,
  diagonalBlockInfinityGrowth,
  diagonalBlockSample,
  diagonalBlockLiftFunction,
  diagonalBlockInterpolateHinted,
  diagonalBlockInterpolate,
  diagonalBlockNestedInterpolate,
  diagonalBlockLift,
  diagonalBlockDLogForm,
  diagonalBlockIntegerPart,
  diagonalBlockScalarEpsForm,
  diagonalBlockCurveCoefficient,
  diagonalBlockFrames,
  diagonalBlockChartRetry
];

DiagonalBlockSliceEpsForm::system =
  "The input must be a pair of equally sized square connection matrices.";
SolveDiagonalBlockGaugeFiniteField::input =
  "The residue data, letters, or options are inconsistent.";

diagonalBlockTogether[m_] := Map[Cancel[Together[#]] &, m, {2}];

diagonalBlockZeroQ[m_] := AllTrue[Flatten[{m}],
  TrueQ[Cancel[Together[#]] === 0] &];

diagonalBlockSameLetterQ[a_, b_] := With[{r = Cancel[Together[a/b]]},
  NumberQ[r] && r =!= 0];

diagonalBlockDenominatorFactors[matrix_, variables_List] :=
  DeleteDuplicates[
    Select[Flatten[Table[
      First /@ Rest[FactorList[Denominator[Together[entry]]]],
      {entry, Flatten[matrix]}]],
      ! FreeQ[#, Alternatives @@ variables] &],
    diagonalBlockSameLetterQ];

DiagonalBlockLetters[{ax_, ay_}, {x_, y_}, eps_] := Module[{factors},
  factors = diagonalBlockDenominatorFactors[Join[ax, ay], {x, y}];
  <|
    "Letters" -> Select[factors, FreeQ[#, eps] &],
    "ApparentFactors" -> Select[factors, ! FreeQ[#, eps] &]
  |>
];

(* root in v of a polynomial linear in v; $Failed otherwise *)
diagonalBlockLinearRoot[poly_, v_] := Module[{c1, c0},
  If[Exponent[poly, v] =!= 1, Return[$Failed]];
  c1 = Coefficient[poly, v, 1]; c0 = Coefficient[poly, v, 0];
  Cancel[Together[-c0/c1]]
];

diagonalBlockResidueAt[a_, x_, x0_] :=
  diagonalBlockTogether[Cancel[Together[(x - x0) a]] /. x -> x0];

diagonalBlockResidueAtInfinity[a_, x_] := Module[{xi, axi},
  xi = Unique["xi"];
  axi = diagonalBlockTogether[-(a /. x -> 1/xi)/xi^2];
  diagonalBlockTogether[Cancel[Together[xi axi]] /. xi -> 0]
];

diagonalBlockIntegerPart[e_, eps_] := Cancel[Together[e /. eps -> 0]];

(* ---------------------------------------------------------------- *)
(* Slice engine: Lee balances (Libra) + linear factor-out           *)
(* ---------------------------------------------------------------- *)

diagonalBlockSliceSpectra[a_, x_, eps_, points_List] := Table[
  Module[{p = points[[k]], r},
    r = Block[{$Output = {}}, Libra`PoincareRank[a, {x, p}]];
    {k, r, Which[
      r > 0, "PoincareRankPositive",
      r < 0, "Regular",
      True, Together /@ Eigenvalues[
        If[p === Infinity, diagonalBlockResidueAtInfinity[a, x],
          diagonalBlockResidueAt[a, x, p]]]]}],
  {k, Length[points]}];

diagonalBlockSliceNormalizedQ[spectra_List, eps_] :=
  AllTrue[spectra, #[[2]] <= 0 &] &&
  AllTrue[Flatten[Select[spectra[[All, 3]], ListQ]],
    TrueQ[diagonalBlockIntegerPart[#, eps] === 0] &];

diagonalBlockSliceIntegerExponentsQ[spectra_List, eps_] :=
  AllTrue[Flatten[Select[spectra[[All, 3]], ListQ]],
    IntegerQ[diagonalBlockIntegerPart[#, eps]] &];

(* sum over points of (Poincare rank weight + |integer parts|) *)
diagonalBlockSliceBadness[spectra_List, eps_] := Total[Table[
  If[entry[[2]] > 0, 100 entry[[2]],
    If[ListQ[entry[[3]]], Total[Abs[diagonalBlockIntegerPart[#, eps] & /@ entry[[3]]]], 0]],
  {entry, spectra}]];

diagonalBlockMaskCombinations[lengths_List] := Module[{n = Length[lengths]},
  If[n === 0, {},
    Table[With[{mask = IntegerDigits[m, 2, n]},
      {mask, Total[Pick[lengths, mask, 1]]}], {m, 0, 2^n - 1}]]
];

(* One Lee step (port of Scripts/epsform_lee79b_c79.wls, 2026-08-16):
   Poincare-rank-positive points are tried first as the raise point;
   left/right towers come from Libra`GetSubspaces, the projector from
   Libra`Projector, the balance from Libra`Balance.  When a
   rank-positive point finds no singular partner (every Fuchsian point
   already has zero integer parts), Lee's Fuchsification lowers at a
   REGULAR point instead: the balance creates an apparent singularity
   with integer exponents there, which the normalization removes later.
   Returns {leftChoice, rightChoice, T, newPoint|None} or $Failed. *)
diagonalBlockLeeStep[a_, x_, eps_, points_List, spectra_List] := Module[
  {active, left = <||>, right = <||>, leftChoices, rightChoices, found,
   irregular, regularCandidates, freshCandidates},
  active = Select[Range[Length[points]], spectra[[#, 2]] >= 0 &];
  (* Libra prints tower diagnostics; route them nowhere (rebinding Print
     would break Libra's own option keys, see masterTransportLoadLibra) *)
  Block[{$Output = {}},
  Do[
    left[k] = Quiet[Libra`GetSubspaces[a, {x, points[[k]]}, eps, Left]];
    right[k] = Quiet[Libra`GetSubspaces[a, {x, points[[k]]}, eps, Right]];
    If[! ListQ[left[k]], left[k] = {}];
    If[! ListQ[right[k]], right[k] = {}],
    {k, active}]];
  leftChoices = DeleteCases[Reverse[SortBy[Flatten[Table[
      {k, #[[1]], #[[2]]} & /@ diagonalBlockMaskCombinations[
        Length /@ left[k]], {k, active}], 1],
      {If[spectra[[#[[1]], 2]] > 0, 1, 0] &, Last}]], {_, _, 0}];
  rightChoices = DeleteCases[Reverse[SortBy[Flatten[Table[
      {k, #[[1]], #[[2]]} & /@ diagonalBlockMaskCombinations[
        Length /@ right[k]], {k, active}], 1], Last]], {_, _, 0}];
  found = Catch[
    Do[
      Do[
        Module[{uu, vv, projector},
          If[lss[[1]] === rss[[1]], Continue[]];
          uu = Flatten[Pick[left[lss[[1]]], lss[[2]], 1], 1];
          vv = Flatten[Pick[right[rss[[1]]], rss[[2]], 1], 1];
          projector = Block[{$Output = {}}, Quiet[Libra`Projector[uu, vv]]];
          If[MatrixQ[projector] && Union[Flatten[projector]] =!= {0} &&
              diagonalBlockZeroQ[projector . projector - projector],
            Throw[{lss, rss, diagonalBlockTogether[
              Libra`Balance[projector,
                {x, points[[lss[[1]]]], points[[rss[[1]]]]}]], None}]]],
        {rss, Select[rightChoices, Last[#] === Last[lss] &]}],
      {lss, leftChoices}];
    $Failed];
  If[found =!= $Failed, Return[found]];
  (* Fallback with a REGULAR point (Lee): when a point that must be
     raised (positive Poincare rank, or a negative integer part) has no
     singular partner -- every candidate projector degenerates -- balance
     against a regular point; symmetrically, lower a point with a
     positive integer part into a regular point.  The apparent
     singularity created there carries integer exponents and is removed
     by later steps.  Rank-positive points first, then the others. *)
  irregular = Join[
    Select[active, spectra[[#, 2]] > 0 && left[#] =!= {} &],
    Select[active, spectra[[#, 2]] === 0 && left[#] =!= {} &]];
  regularCandidates = Select[Range[Length[points]],
    spectra[[#, 2]] < 0 && points[[#]] =!= Infinity &];
  freshCandidates = Select[{-1, 2, -2, 3, -3, 5, -5, 1/2, -1/2, 7, -7},
    ! MemberQ[points, #] &];
  found = Catch[
    Do[
      Module[{uu = Flatten[left[k], 1], projector, t},
        projector = Block[{$Output = {}}, Quiet[Libra`Projector[uu, uu]]];
        If[! (MatrixQ[projector] && Union[Flatten[projector]] =!= {0} &&
            diagonalBlockZeroQ[projector . projector - projector]),
          Continue[]];
        Do[
          t = diagonalBlockTogether[Libra`Balance[projector, {x, points[[k]], x2}]];
          Throw[{{k, ConstantArray[1, Length[left[k]]], Length[uu]},
            {If[MemberQ[points, x2], FirstPosition[points, x2][[1]], Length[points] + 1],
              "Regular", Length[uu]}, t,
            If[MemberQ[points, x2], None, x2]}],
          {x2, Join[points[[regularCandidates]], freshCandidates]}]],
      {k, irregular}];
    $Failed];
  If[found =!= $Failed, Return[found]];
  (* lower side *)
  Catch[
    Do[
      Module[{vv = Flatten[right[k], 1], projector, t},
        If[vv === {}, Continue[]];
        projector = Block[{$Output = {}}, Quiet[Libra`Projector[vv, vv]]];
        If[! (MatrixQ[projector] && Union[Flatten[projector]] =!= {0} &&
            diagonalBlockZeroQ[projector . projector - projector]),
          Continue[]];
        Do[
          t = diagonalBlockTogether[Libra`Balance[projector, {x, x2, points[[k]]}]];
          Throw[{{If[MemberQ[points, x2], FirstPosition[points, x2][[1]], Length[points] + 1],
              "Regular", Length[vv]},
            {k, ConstantArray[1, Length[right[k]]], Length[vv]}, t,
            If[MemberQ[points, x2], None, x2]}],
          {x2, Join[points[[regularCandidates]], freshCandidates]}]],
      {k, Select[active, spectra[[#, 2]] === 0 &]}];
    $Failed]
];

(* Lee's factor-out step on a normalized slice: U with
   M_i(eps) U = eps U N_i for every locus, N_i = M_i(mu0)/mu0. *)
diagonalBlockFactorOut[residues_List, eps_, mu0_] := Module[
  {n = Length[First[residues]], references, unknowns, equations, matrix,
   nullspace, u, inverse, constants},
  references = Map[Together, (# /. eps -> mu0)/mu0, {2}] & /@ residues;
  unknowns = Array[u, {n, n}];
  equations = Numerator /@ (Together /@ Flatten[Table[
    residues[[i]] . unknowns - eps unknowns . references[[i]],
    {i, Length[residues]}]]);
  (* CoefficientArrays drops the linear part when every equation is
     identically zero (a 1x1 block, or residues already of the form
     eps N_i): build the coefficient matrix explicitly *)
  matrix = Table[Coefficient[equation, variable],
    {equation, equations}, {variable, Flatten[unknowns]}];
  nullspace = NullSpace[matrix];
  Which[
    Length[nullspace] === 1,
      u = Map[Together, Partition[First[nullspace], n], {2}],
    Length[nullspace] > 1 &&
      AllTrue[residues, FreeQ[diagonalBlockTogether[#/eps], eps] &],
      (* the residues are already eps times constants: the identity is
         a valid factor-out gauge *)
      u = IdentityMatrix[n],
    True,
      Return[<|"Status" -> "FactorOutNullity", "Nullity" -> Length[nullspace]|>]];
  If[TrueQ[Together[Det[u]] === 0],
    Return[<|"Status" -> "FactorOutSingular"|>]];
  inverse = diagonalBlockTogether[Inverse[u]];
  constants = diagonalBlockTogether[inverse . # . u/eps] & /@ residues;
  If[! AllTrue[constants, FreeQ[#, eps] &],
    Return[<|"Status" -> "FactorOutResiduesNotConstant"|>]];
  <|"Status" -> "OK", "U" -> u, "UInverse" -> inverse,
    "Residues" -> constants|>
];

(* ---------------------------------------------------------------- *)
(* NumericalEps slice engine: eps specialized to a rational number   *)
(* ---------------------------------------------------------------- *)

(* "NumericalEps" means exactly that: the regulator is replaced by one
   fixed rational number (1/101) before the balance chain, the way the
   spectator is fixed to y0 for the slice; all arithmetic stays exact
   over Q(x).  Nothing is floating point. *)

(* The slice's only downstream output is the residue tuple up to one
   common constant conjugation.  Two normalized Fuchsian forms of the
   same one-variable system at a fixed generic regulator value e differ
   by a rational gauge with no integer exponent shifts, i.e. a CONSTANT
   matrix; hence the residues M_a(e)/e of a Lee chain run entirely at
   eps = e are a constant conjugate of the true residues.  So the whole
   search runs in Q(x) with e = 1/101 (integer parts read off as
   Round[lambda], the eps-part as (lambda - a)/e), Lee's factor-out step
   is unnecessary, and eps is never symbolic.  Conventions are Libra's
   (read from its source, 2026-08-21): Left/raise subspace at x1 =
   column eigenvectors of the residue with NEGATIVE integer part, Right/
   lower subspace at x2 = row eigenvectors with POSITIVE integer part,
   P = u^T (v u^T)^-1 v, Balance = I - P + P (x - x2)/(x - x1) (with the
   obvious limits for x1 or x2 = Infinity).  Poincare-rank-positive
   points use Libra's A0A1ToSubspaces through GetSubspaces, whose
   rank-positive branch never touches the regulator. *)

diagonalBlockNumericBalance[p_, x_, x1_, x2_] := Which[
  x1 === Infinity, IdentityMatrix[Length[p]] - p + p (x - x2),
  x2 === Infinity, IdentityMatrix[Length[p]] - p + p/(x - x1),
  True, IdentityMatrix[Length[p]] - p + p (x - x2)/(x - x1)];

diagonalBlockNumericProjector[uu_List, vv_List] := Module[{ut, gram},
  If[uu === {} || vv === {} || Length[uu] =!= Length[vv], Return[$Failed]];
  ut = Transpose[uu]; gram = vv . ut;
  If[TrueQ[Together[Det[gram]] === 0], Return[$Failed]];
  Map[Together, ut . Inverse[gram] . vv, {2}]
];

(* exponent decomposition lambda = a + b e at the numeric regulator e *)
diagonalBlockNumericExponent[lambda_, e_] := With[{a = Round[lambda]},
  {a, Together[(lambda - a)/e]}];

diagonalBlockNumericSpectra[a_, x_, points_List, e_] := Table[
  Module[{p = points[[k]], r, m, eig},
    r = Block[{$Output = {}}, Libra`PoincareRank[a, {x, p}]];
    Which[
      r > 0, {k, r, "PoincareRankPositive", None},
      r < 0, {k, r, "Regular", None},
      True,
        m = If[p === Infinity, diagonalBlockResidueAtInfinity[a, x],
          diagonalBlockResidueAt[a, x, p]];
        eig = Eigenvalues[m];
        If[! AllTrue[eig, MatchQ[#, _Integer | _Rational] &],
          {k, r, "ExponentsNotRational", m},
          {k, r, diagonalBlockNumericExponent[#, e] & /@ eig, m}]]],
  {k, Length[points]}];

diagonalBlockNumericNormalizedQ[spectra_List] :=
  AllTrue[spectra, #[[2]] <= 0 &] &&
  AllTrue[Flatten[Select[spectra[[All, 3]], ListQ], 1], #[[1]] === 0 &];

diagonalBlockNumericBadness[spectra_List] := Total[Table[
  If[entry[[2]] > 0, 100 entry[[2]],
    If[ListQ[entry[[3]]], Total[Abs[First /@ entry[[3]]]], 0]], {entry, spectra}]];

(* column eigenvectors of m for the eigenvalues lambda with a < 0
   (raise); row eigenvectors for a > 0 (lower) *)
diagonalBlockNumericEigenvectors[m_, exponents_List, e_, side_] := Module[
  {targets},
  targets = DeleteDuplicates[Select[exponents,
    If[side === Left, #[[1]] < 0, #[[1]] > 0] &]];
  (* one group per eigenvector: rank-one balances *)
  Flatten[Table[
    With[{lambda = t[[1]] + t[[2]] e},
      List /@ If[side === Left, NullSpace[m - lambda IdentityMatrix[Length[m]]],
        NullSpace[Transpose[m] - lambda IdentityMatrix[Length[m]]]]],
    {t, targets}], 1]
];

(* one numeric Lee step: {raiseIndex, lowerIndex, T, newPoint|None} or $Failed *)
diagonalBlockNumericLeeStep[a_, x_, points_List, spectra_List, e_] := Module[
  {n = Length[a], active, left = <||>, right = <||>, raiseOrder, found,
   regularCandidates, freshCandidates, dummy},
  dummy = Unique["regulator"];
  active = Select[Range[Length[points]], spectra[[#, 2]] >= 0 &];
  Do[
    If[spectra[[k, 2]] > 0,
      (* Libra's rank-positive branch: regulator-free *)
      left[k] = Block[{$Output = {}}, Quiet[Libra`GetSubspaces[a, {x, points[[k]]}, dummy, Left]]];
      right[k] = Block[{$Output = {}}, Quiet[Libra`GetSubspaces[a, {x, points[[k]]}, dummy, Right]]];
      If[! ListQ[left[k]], left[k] = {}]; If[! ListQ[right[k]], right[k] = {}];
      (* towers individually, then their union *)
      If[Length[left[k]] > 1, AppendTo[left[k], Flatten[left[k], 1]]];
      If[Length[right[k]] > 1, AppendTo[right[k], Flatten[right[k], 1]]],
      left[k] = diagonalBlockNumericEigenvectors[spectra[[k, 4]], spectra[[k, 3]], e, Left];
      right[k] = diagonalBlockNumericEigenvectors[spectra[[k, 4]], spectra[[k, 3]], e, Right]],
    {k, active}];
  (* rank-positive raise points first, then the largest negative parts *)
  raiseOrder = SortBy[Select[active, left[#] =!= {} &],
    {If[spectra[[#, 2]] > 0, -1, 0] &, If[ListQ[spectra[[#, 3]]], Min[First /@ spectra[[#, 3]]], -100] &}];
  found = Catch[
    Do[
      Do[
        If[k1 === k2, Continue[]];
        Do[
          Do[
            Module[{projector = diagonalBlockNumericProjector[uu, vv], t},
              If[projector === $Failed, Continue[]];
              t = diagonalBlockTogether[diagonalBlockNumericBalance[projector, x, points[[k1]], points[[k2]]]];
              Throw[{k1, k2, t, None}]],
            {vv, Select[right[k2], Length[#] === Length[uu] &]}],
          {uu, left[k1]}],
        {k2, Select[active, right[#] =!= {} &]}],
      {k1, raiseOrder}];
    $Failed];
  If[found =!= $Failed, Return[found]];
  (* regular-point fallback, raise side then lower side *)
  regularCandidates = points[[Select[Range[Length[points]], spectra[[#, 2]] < 0 && points[[#]] =!= Infinity &]]];
  freshCandidates = Select[{-1, 2, -2, 3, -3, 5, -5, 1/2, -1/2, 7, -7, 11, -11}, ! MemberQ[points, #] &];
  Catch[
    Do[
      Do[
        Module[{projector = diagonalBlockNumericProjector[uu, uu], t},
          If[projector === $Failed, Continue[]];
          Do[
            t = diagonalBlockTogether[diagonalBlockNumericBalance[projector, x, points[[k1]], x2]];
            Throw[{k1, If[MemberQ[points, x2], FirstPosition[points, x2][[1]], None], t,
              If[MemberQ[points, x2], None, x2]}],
            {x2, Join[regularCandidates, freshCandidates]}]],
        {uu, left[k1]}],
      {k1, raiseOrder}];
    Do[
      Do[
        Module[{projector = diagonalBlockNumericProjector[vv, vv], t},
          If[projector === $Failed, Continue[]];
          Do[
            t = diagonalBlockTogether[diagonalBlockNumericBalance[projector, x, x2, points[[k2]]]];
            Throw[{If[MemberQ[points, x2], FirstPosition[points, x2][[1]], None], k2, t,
              If[MemberQ[points, x2], None, x2]}],
            {x2, Join[regularCandidates, freshCandidates]}]],
        {vv, right[k2]}],
      {k2, Select[active, spectra[[#, 2]] === 0 && right[#] =!= {} &]}];
    $Failed]
];

(* the numeric slice: returns the same record shape as the symbolic
   engine (SliceLetters, SliceResidues, ...) *)
diagonalBlockNumericSlice[{ax_, ay_}, {x_, y_}, eps_, y0_, e_, letters_List,
    xLetters_List, maximumBalances_Integer, log_] := Module[
  {n = Length[ax], a, loci, points, spectra, status, step, path = {}, badness, stall = 0,
   total, t0 = AbsoluteTime[], residues, matched, apparent, residueList, inverse},
  a = diagonalBlockTogether[ax /. {y -> y0, eps -> e}];
  loci = diagonalBlockDenominatorFactors[a, {x}];
  If[AnyTrue[loci, Exponent[#, x] =!= 1 &],
    Return[<|"Status" -> "SlicePoleNotLinear", "Poles" -> loci|>]];
  points = Append[DeleteDuplicates[diagonalBlockLinearRoot[#, x] & /@ loci], Infinity];
  spectra = diagonalBlockNumericSpectra[a, x, points, e];
  If[MemberQ[spectra[[All, 3]], "ExponentsNotRational"] ||
      ! AllTrue[Flatten[Select[spectra[[All, 3]], ListQ], 1], IntegerQ[#[[1]]] && IntegerQ[#[[2]]] &],
    Return[<|"Status" -> "ExponentsNotInteger", "Spectra" -> spectra|>]];
  badness = diagonalBlockNumericBadness[spectra];
  status = If[diagonalBlockNumericNormalizedQ[spectra], "Normalized", "Running"];
  Do[
    If[status =!= "Running", Break[]];
    step = diagonalBlockNumericLeeStep[a, x, points, spectra, e];
    If[step === $Failed, status = "NoBalanceFound"; Break[]];
    inverse = diagonalBlockTogether[Inverse[step[[3]]]];
    a = diagonalBlockTogether[inverse . a . step[[3]] - inverse . D[step[[3]], x]];
    If[step[[4]] =!= None, points = Insert[points, step[[4]], -2]];
    AppendTo[path, <|"Raise" -> If[IntegerQ[step[[1]]], points[[step[[1]]]], step[[4]]],
      "Lower" -> If[IntegerQ[step[[2]]], points[[step[[2]]]], step[[4]]]|>];
    spectra = diagonalBlockNumericSpectra[a, x, points, e];
    log["numeric balance ", iteration, ": raise ", Last[path]["Raise"], " / lower ",
      Last[path]["Lower"], "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"];
    If[MemberQ[spectra[[All, 3]], "ExponentsNotRational"] ||
        ! AllTrue[Flatten[Select[spectra[[All, 3]], ListQ], 1], IntegerQ[#[[1]]] && IntegerQ[#[[2]]] &],
      status = "ExponentsNotInteger"; Break[]];
    With[{b = diagonalBlockNumericBadness[spectra]}, If[b < badness, badness = b; stall = 0, stall++]];
    If[stall > 2 n + 2, status = "NormalizationStalled"; Break[]];
    If[diagonalBlockNumericNormalizedQ[spectra], status = "Normalized"],
    {iteration, maximumBalances}];
  If[status === "Running", status = "BalanceBudgetExhausted"];
  If[status =!= "Normalized",
    Return[<|"Status" -> status, "SlicePoint" -> y0, "RegulatorValue" -> e,
      "BalancePath" -> path, "Spectra" -> spectra, "Seconds" -> AbsoluteTime[] - t0|>]];
  (* residues of the normalized slice, divided by e *)
  (* points that became regular carry no residue matrix in the spectra *)
  residues = Table[If[MatrixQ[spectra[[k, 4]]], Map[Together, spectra[[k, 4]]/e, {2}],
    ConstantArray[0, {n, n}]], {k, Length[points] - 1}];
  matched = Table[
    Module[{point = points[[k]], letterIndex},
      letterIndex = SelectFirst[Range[Length[xLetters]],
        TrueQ[Together[diagonalBlockLinearRoot[xLetters[[#]] /. y -> y0, x] - point] === 0] &, $Failed];
      <|"Point" -> point, "LetterIndex" -> letterIndex, "Residue" -> residues[[k]],
        "ZeroResidue" -> diagonalBlockZeroQ[residues[[k]]]|>],
    {k, Length[points] - 1}];
  apparent = Select[matched, #["LetterIndex"] === $Failed &];
  If[AnyTrue[apparent, ! #["ZeroResidue"] &],
    Return[<|"Status" -> "UnmatchedLocusWithResidue", "SlicePoint" -> y0,
      "Unmatched" -> Select[apparent, ! #["ZeroResidue"] &], "Seconds" -> AbsoluteTime[] - t0|>]];
  residueList = Table[
    With[{hit = SelectFirst[matched, #["LetterIndex"] === i &, $Failed]},
      If[hit === $Failed, ConstantArray[0, {n, n}], hit["Residue"]]],
    {i, Length[xLetters]}];
  residueList = diagonalBlockCanonicalFrame[residueList]["Residues"];
  <|"Status" -> "OK", "SliceVariable" -> x, "SpectatorVariable" -> y, "SlicePoint" -> y0,
    "RegulatorValue" -> e, "Regulator" -> eps, "Letters" -> letters,
    "SliceLetters" -> xLetters, "SpectatorLetters" -> Select[letters, FreeQ[#, x] &],
    "SliceResidues" -> residueList,
    "InfinityResidue" -> If[MatrixQ[spectra[[-1, 4]]], Map[Together, spectra[[-1, 4]]/e, {2}],
      ConstantArray[0, {n, n}]],
    "Engine" -> "NumericalEps", "BalancePath" -> path, "BalanceCount" -> Length[path],
    "Seconds" -> AbsoluteTime[] - t0|>
];

(* Canonical frame for a residue tuple: a constant conjugation that
   removes the frame-dependent heights (a Lee chain at eps = 1/101
   leaves powers of 101 everywhere).  The residue with the most distinct
   eigenvalues is diagonalized (rational eigenvectors: the eigenvalues
   are integers), then the remaining diagonal-scaling freedom is fixed
   by scaling a spanning tree of the nonzero entries of the next residue
   to 1.  Any conjugate tuple is an equally valid input of the
   x-equation; the gate certifies whatever comes out. *)
diagonalBlockCanonicalFrame[residues_List] := Module[
  {n, nonzero, columns = {}, candidates, p, conjugated, second, scale,
   visited, queue, i, j, d, independentQ},
  If[residues === {}, Return[<|"Residues" -> residues, "Frame" -> None|>]];
  n = Length[First[residues]];
  nonzero = Select[residues, ! diagonalBlockZeroQ[#] &];
  If[nonzero === {}, Return[<|"Residues" -> residues, "Frame" -> IdentityMatrix[n]|>]];
  independentQ[vectors_] := MatrixRank[vectors] === Length[vectors];
  (* directions canonical up to scale: eigenvectors of SIMPLE eigenvalues
     of any residue, in a deterministic order *)
  candidates = Flatten[Table[
    Module[{ev = Eigenvalues[r], simple},
      If[! AllTrue[ev, MatchQ[#, _Integer | _Rational] &], {},
        simple = Select[DeleteDuplicates[ev], Count[ev, #] === 1 &];
        Table[First[NullSpace[r - lambda IdentityMatrix[n]]], {lambda, simple}]]],
    {r, nonzero}], 1];
  Do[If[independentQ[Append[columns, c]], AppendTo[columns, c]], {c, candidates}];
  (* fill with echelon bases of multi-dimensional eigenspaces *)
  If[Length[columns] < n,
    Do[
      Module[{ev = Eigenvalues[r]},
        If[AllTrue[ev, MatchQ[#, _Integer | _Rational] &],
          Do[Do[If[independentQ[Append[columns, c]], AppendTo[columns, c]],
            {c, NullSpace[r - lambda IdentityMatrix[n]]}],
            {lambda, DeleteDuplicates[ev]}]]],
      {r, nonzero}]];
  If[Length[columns] < n, Return[<|"Residues" -> residues, "Frame" -> IdentityMatrix[n]|>]];
  p = Transpose[Take[columns, n]];
  conjugated = Map[Together, Inverse[p] . # . p, {2}] & /@ residues;
  (* fix the scales of the columns by a spanning tree of the nonzero
     off-diagonal entries, over the residues in order *)
  scale = ConstantArray[1, n]; visited = {1}; queue = {1};
  Do[
    While[queue =!= {},
      i = First[queue]; queue = Rest[queue];
      Do[
        If[! MemberQ[visited, j] && second[[i, j]] =!= 0,
          scale[[j]] = Together[scale[[i]]/second[[i, j]]];
          AppendTo[visited, j]; AppendTo[queue, j]];
        If[! MemberQ[visited, j] && second[[j, i]] =!= 0,
          scale[[j]] = Together[scale[[i]] second[[j, i]]];
          AppendTo[visited, j]; AppendTo[queue, j]],
        {j, n}]];
    If[Length[visited] === n, Break[]];
    (* restart the search from every visited node for the next residue *)
    queue = visited,
    {second, conjugated}];
  d = DiagonalMatrix[scale];
  conjugated = Map[Together, Inverse[d] . # . d, {2}] & /@ conjugated;
  <|"Residues" -> conjugated, "Frame" -> Map[Together, p . d, {2}]|>
];

diagonalBlockGenericSlicePointQ[xLetters_List, yLetters_List, x_, y_, y0_] :=
  Module[{roots},
    If[AnyTrue[yLetters, TrueQ[Together[# /. y -> y0] == 0] &], Return[False]];
    If[AnyTrue[xLetters, TrueQ[Together[Coefficient[#, x, 1] /. y -> y0] == 0] &],
      Return[False]];
    roots = diagonalBlockLinearRoot[# /. y -> y0, x] & /@ xLetters;
    ! MemberQ[roots, $Failed] && DuplicateFreeQ[roots]
  ];

Options[DiagonalBlockSliceEpsForm] = {
  "Engine" -> "NumericalEps",
  "RegulatorValues" -> {1/101, 1/103, 1/107},
  "SlicePoint" -> Automatic,
  "SliceCandidates" -> {3/7, 2/9, 5/11, 7/13, 4/5, 1/6, 9/14, 5/8, 3/10, 8/17},
  "ReferenceRegulator" -> 1/5,
  "MaximumBalances" -> 60,
  "StepTimeLimit" -> 1500,
  "Verbose" -> False
};

DiagonalBlockSliceEpsForm[{ax_, ay_}, {x_, y_}, eps_, OptionsPattern[]] :=
 Module[
  {verbose, log, n, letterData, letters, xLetters, yLetters, y0,
   candidates, a, loci, points, spectra, total, path = {}, status,
   step, t0 = AbsoluteTime[], maximumBalances, stepLimit, mu0,
   finiteResidues, infinityResidue, factorOut, residues, matched,
   residueList, sliceForm, sliceOK, apparent, badness, stall},
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[dblock-slice] ", args]];
  If[! (SquareMatrixQ[ax] && SquareMatrixQ[ay] && Length[ax] === Length[ay]),
    Message[DiagonalBlockSliceEpsForm::system]; Return[<|"Status" -> "SystemInvalid"|>]];
  n = Length[ax];
  If[masterTransportLoadLibra[$feynFacetRoot] =!= True,
    Return[<|"Status" -> "LibraNotLoaded"|>]];
  Off[OptionValue::optnf];
  letterData = DiagonalBlockLetters[{ax, ay}, {x, y}, eps];
  letters = letterData["Letters"];
  xLetters = Select[letters, ! FreeQ[#, x] &];
  yLetters = Select[letters, FreeQ[#, x] &];
  If[AnyTrue[xLetters, Exponent[#, x] =!= 1 &],
    Return[<|"Status" -> "LetterNotLinearInSliceVariable",
      "Letters" -> letters|>]];
  candidates = Replace[OptionValue["SlicePoint"],
    Automatic :> OptionValue["SliceCandidates"]];
  candidates = Flatten[{candidates}];
  y0 = SelectFirst[candidates,
    diagonalBlockGenericSlicePointQ[xLetters, yLetters, x, y, #] &, $Failed];
  If[y0 === $Failed,
    Return[<|"Status" -> "NoGenericSlicePoint", "Letters" -> letters|>]];
  log["slice at ", y, " = ", y0];
  If[OptionValue["Engine"] === "NumericalEps",
    Module[{numeric = $Failed},
      Do[
        numeric = diagonalBlockNumericSlice[{ax, ay}, {x, y}, eps, y0, e, letters, xLetters,
          OptionValue["MaximumBalances"], log];
        log["numeric engine at eps = ", e, ": ", numeric["Status"]];
        If[numeric["Status"] === "OK" || numeric["Status"] === "ExponentsNotInteger", Break[]],
        {e, OptionValue["RegulatorValues"]}];
      If[numeric["Status"] === "OK" || numeric["Status"] === "ExponentsNotInteger",
        Return[Join[numeric, <|"ApparentFactors" -> letterData["ApparentFactors"]|>]]];
      log["numeric engine did not normalize; falling back to the symbolic engine"]]];
  a = diagonalBlockTogether[ax /. y -> y0];
  (* every pole of the slice, apparent ones included *)
  loci = diagonalBlockDenominatorFactors[a, {x}];
  If[AnyTrue[loci, Exponent[#, x] =!= 1 &],
    Return[<|"Status" -> "SlicePoleNotLinear", "Poles" -> loci|>]];
  points = Append[DeleteDuplicates[
    diagonalBlockLinearRoot[#, x] & /@ loci], Infinity];
  maximumBalances = OptionValue["MaximumBalances"];
  stepLimit = OptionValue["StepTimeLimit"];
  total = IdentityMatrix[n];
  spectra = diagonalBlockSliceSpectra[a, x, eps, points];
  (* a non-integer integer part (half-integer exponents at a Kallen
     locus) cannot be moved by balances: this frame needs a chart *)
  If[! diagonalBlockSliceIntegerExponentsQ[spectra, eps],
    Return[<|"Status" -> "ExponentsNotInteger", "SlicePoint" -> y0,
      "Spectra" -> spectra, "Seconds" -> AbsoluteTime[] - t0|>]];
  status = If[diagonalBlockSliceNormalizedQ[spectra, eps],
    "Normalized", "Running"];
  badness = diagonalBlockSliceBadness[spectra, eps]; stall = 0;
  Do[
    If[status =!= "Running", Break[]];
    step = TimeConstrained[
      diagonalBlockLeeStep[a, x, eps, points, spectra], stepLimit, $TimedOut];
    Which[
      step === $TimedOut, status = "BalanceStepTimedOut"; Break[],
      step === $Failed, status = "NoBalanceFound"; Break[]];
    Module[{t = step[[3]], inverse},
      inverse = diagonalBlockTogether[Inverse[t]];
      a = diagonalBlockTogether[inverse . a . t - inverse . D[t, x]];
      total = diagonalBlockTogether[total . t]];
    If[step[[4]] =!= None, points = Insert[points, step[[4]], -2]];
    AppendTo[path, <|
      "RaisePoint" -> If[step[[1, 2]] === "Regular" && step[[4]] =!= None, step[[4]], points[[step[[1, 1]]]]],
      "RaiseMask" -> step[[1, 2]],
      "LowerPoint" -> If[step[[2, 2]] === "Regular" && step[[4]] =!= None, step[[4]], points[[step[[2, 1]]]]],
      "LowerMask" -> step[[2, 2]], "Rank" -> step[[1, 3]]|>];
    spectra = diagonalBlockSliceSpectra[a, x, eps, points];
    log["balance ", iteration, ": raise ", Last[path]["RaisePoint"],
      " / lower ", Last[path]["LowerPoint"], "  (",
      Round[AbsoluteTime[] - t0, 0.1], " s)"];
    If[! diagonalBlockSliceIntegerExponentsQ[spectra, eps],
      status = "ExponentsNotInteger"; Break[]];
    (* progress guard: the regular-point fallbacks move integer parts
       around; allow a bounded number of non-improving steps *)
    With[{b = diagonalBlockSliceBadness[spectra, eps]},
      If[b < badness, badness = b; stall = 0, stall++]];
    If[stall > 2 n + 2, status = "NormalizationStalled"; Break[]];
    If[diagonalBlockSliceNormalizedQ[spectra, eps], status = "Normalized"],
    {iteration, maximumBalances}];
  If[status === "Running", status = "BalanceBudgetExhausted"];
  If[status =!= "Normalized",
    Return[<|"Status" -> status, "SlicePoint" -> y0, "BalancePath" -> path,
      "Spectra" -> spectra, "Seconds" -> AbsoluteTime[] - t0|>]];
  (* factor out eps *)
  mu0 = OptionValue["ReferenceRegulator"];
  finiteResidues = diagonalBlockResidueAt[a, x, #] & /@ Most[points];
  infinityResidue = diagonalBlockResidueAtInfinity[a, x];
  factorOut = diagonalBlockFactorOut[
    Append[finiteResidues, infinityResidue], eps, mu0];
  If[factorOut["Status"] =!= "OK",
    Return[Join[factorOut, <|"SlicePoint" -> y0, "BalancePath" -> path,
      "Seconds" -> AbsoluteTime[] - t0|>]]];
  residues = factorOut["Residues"];
  (* exact slice check: U^-1 A U == eps Sum_k R_k/(x - x_k) *)
  sliceForm = diagonalBlockTogether[factorOut["UInverse"] . a . factorOut["U"]];
  sliceOK = diagonalBlockZeroQ[sliceForm -
    eps Sum[residues[[k]]/(x - points[[k]]), {k, Length[points] - 1}]];
  If[! sliceOK,
    Return[<|"Status" -> "SliceFormCheckFailed", "SlicePoint" -> y0,
      "BalancePath" -> path, "Seconds" -> AbsoluteTime[] - t0|>]];
  (* map finite loci to letters *)
  matched = Table[
    Module[{point = points[[k]], letterIndex},
      letterIndex = SelectFirst[Range[Length[xLetters]],
        TrueQ[Together[diagonalBlockLinearRoot[
          xLetters[[#]] /. y -> y0, x] - point] === 0] &, $Failed];
      <|"Point" -> point, "LetterIndex" -> letterIndex,
        "Residue" -> residues[[k]],
        "ZeroResidue" -> diagonalBlockZeroQ[residues[[k]]]|>],
    {k, Length[points] - 1}];
  apparent = Select[matched, #["LetterIndex"] === $Failed &];
  If[AnyTrue[apparent, ! #["ZeroResidue"] &],
    Return[<|"Status" -> "UnmatchedLocusWithResidue", "SlicePoint" -> y0,
      "Unmatched" -> Select[apparent, ! #["ZeroResidue"] &],
      "Letters" -> letters, "Seconds" -> AbsoluteTime[] - t0|>]];
  residueList = Table[
    With[{hit = SelectFirst[matched, #["LetterIndex"] === i &, $Failed]},
      If[hit === $Failed, ConstantArray[0, {n, n}], hit["Residue"]]],
    {i, Length[xLetters]}];
  <|
    "Status" -> "OK",
    "SliceVariable" -> x, "SpectatorVariable" -> y, "SlicePoint" -> y0,
    "Regulator" -> eps,
    "Letters" -> letters,
    "SliceLetters" -> xLetters,
    "SpectatorLetters" -> yLetters,
    "SliceResidues" -> residueList,
    "InfinityResidue" -> Last[residues],
    "ApparentFactors" -> letterData["ApparentFactors"],
    "SliceTransformation" -> diagonalBlockTogether[total . factorOut["U"]],
    "BalancePath" -> path,
    "BalanceCount" -> Length[path],
    "Seconds" -> AbsoluteTime[] - t0
  |>
];

(* ---------------------------------------------------------------- *)
(* Finite-field solve of the x-equation                              *)
(* ---------------------------------------------------------------- *)

(* integer-coefficient exponent tables {coefficients, xExps, yExps, eExps}
   of a polynomial in {x, y, eps}; rational coefficients are cleared by
   the caller *)
diagonalBlockPolynomialRules[poly_, {x_, y_, eps_}] := Module[{rules},
  rules = CoefficientRules[Expand[poly], {x, y, eps}];
  If[rules === {}, rules = {{0, 0, 0} -> 0}];
  {Developer`ToPackedArray[rules[[All, 2]]],
    Developer`ToPackedArray[rules[[All, 1, 1]]],
    Developer`ToPackedArray[rules[[All, 1, 2]]],
    Developer`ToPackedArray[rules[[All, 1, 3]]]}
];

(* {numeratorRules, denominatorRules} with integer coefficients *)
diagonalBlockRationalRules[expr_, vars_List] := Module[
  {t = Together[expr], num, den, content},
  num = Numerator[t]; den = Denominator[t];
  content = LCM @@ (Denominator /@ Join[
    CoefficientRules[Expand[num], vars][[All, 2]],
    CoefficientRules[Expand[den], vars][[All, 2]]]);
  {diagonalBlockPolynomialRules[content num, vars],
    diagonalBlockPolynomialRules[content den, vars]}
];

diagonalBlockEvaluateRules[{c_, xs_, ys_, es_}, xPowers_, yPowers_, ePowers_,
    prime_Integer] := Module[{t},
  t = Mod[xPowers[[xs + 1]] yPowers[[ys + 1]], prime];
  t = Mod[t ePowers[[es + 1]], prime];
  Mod[Total[Mod[Mod[c, prime] t, prime]], prime]
];

(* pole-order bound of T at each letter from the integer parts of the
   local exponents of the source connection: T ~ (x - x_a)^(n + eps k)
   with n an integer part of A's exponents, so ord_a(T) >= min n. *)
diagonalBlockMultiplicityCensus[{ax_, ay_}, {x_, y_}, eps_, letters_List] :=
 Table[
  Module[{letter = letters[[i]], a, v, root, order, residue, eigenvalues, parts},
    If[! FreeQ[letter, x], a = ax; v = x, a = ay; v = y];
    root = diagonalBlockLinearRoot[letter, v];
    order = Max[0, Max[Flatten[Table[
      Cases[FactorList[Denominator[Together[entry]]],
        {f_, e_} /; diagonalBlockSameLetterQ[f, letter] :> e],
      {entry, Flatten[a]}]]]];
    Which[
      root === $Failed, 1,
      order === 0, 0,
      order > 1, order,
      True,
        residue = diagonalBlockResidueAt[a, v, root];
        eigenvalues = Eigenvalues[residue];
        parts = diagonalBlockIntegerPart[#, eps] & /@ eigenvalues;
        If[AllTrue[parts, IntegerQ], Max[0, -Min[parts]], 1]]],
  {i, Length[letters]}];

(* growth bound of T at v = Infinity from the source connection:
   A_v ~ A_inf/v gives solutions ~ v^(eigenvalues of A_inf), and the
   canonical side contributes only eps-proportional exponents, so
   deg_v(numerator) - deg_v(denominator) <= max integer part of those
   eigenvalues.  Returns Missing[] when the point is not Fuchsian. *)
diagonalBlockInfinityGrowth[a_, v_, eps_] := Module[{xi, axi, order, residue, parts},
  xi = Unique["xi"];
  axi = diagonalBlockTogether[-(a /. v -> 1/xi)/xi^2];
  order = Max[0, Max[Flatten[Table[
    Cases[FactorList[Denominator[Together[entry]]], {f_, e_} /; ! FreeQ[f, xi] && Exponent[f, xi] === 1 && Coefficient[f, xi, 0] === 0 :> e],
    {entry, Flatten[axi]}]]]];
  If[order > 1, Return[Missing["NotFuchsianAtInfinity"]]];
  (* A_inf = -(residue in xi) *)
  residue = -diagonalBlockTogether[Cancel[Together[xi axi]] /. xi -> 0];
  parts = diagonalBlockIntegerPart[#, eps] & /@ Eigenvalues[residue];
  If[AllTrue[parts, IntegerQ], Max[parts], Missing["ExponentsNotInteger"]]
];

diagonalBlockPrepareSampling[{ax_, ay_}, {x_, y_}, eps_, letters_List,
    xLetters_List, residues_List, multiplicities_List, degrees_List] :=
 Module[{vars = {x, y, eps}, n = Length[ax], maxDegrees},
  maxDegrees = Table[Max[
    If[k <= 2, degrees[[k]] + 2, 0],
    Max[Exponent[Numerator[Together[#]], vars[[k]]] & /@ Flatten[ax]],
    Max[Exponent[Denominator[Together[#]], vars[[k]]] & /@ Flatten[ax]],
    Max[Exponent[#, vars[[k]]] & /@ letters]], {k, 3}];
  <|
    "Dimension" -> n,
    "SourceRules" -> Map[diagonalBlockRationalRules[#, vars] &, ax, {2}],
    "LetterRules" -> (diagonalBlockPolynomialRules[#, vars] & /@ letters),
    "LetterDerivativeRules" ->
      (diagonalBlockPolynomialRules[D[#, x], vars] & /@ letters),
    (* index by identity at level 1 only: FirstPosition would match the
       symbol x INSIDE the letter -1 + x *)
    "LetterIndices" -> Table[
      SelectFirst[Range[Length[letters]], letters[[#]] === xLetters[[i]] &],
      {i, Length[xLetters]}],
    "Residues" -> residues,
    "Multiplicities" -> multiplicities,
    "Degrees" -> degrees,
    "MaximumPowers" -> maxDegrees
  |>
];

(* One ODE sample: at fixed (y, eps) modulo prime, solve
       Den d_x N - N d_x Den - Den (A_x N - N B_x) = 0
   for the polynomial matrix N(x) = Sum_i N_i x^i of degree <= n_x, by
   evaluating at x-points.  The rational solution space at a generic
   fixed spectator value is one-dimensional; the member with coordinate
   `column` equal to 1 is returned (column === Automatic selects the
   first independent coordinate and reports it). *)
diagonalBlockSample[preparation_Association, yValue_Integer, epsilonValue_,
    prime_Integer, column_, seed_Integer] := Module[
  {n, n2, degreeX, unknownCount, epsMod, ePowers, yPowers, maxPowers,
   sourceRules, letterRules, letterDerivativeRules, letterIndices,
   residuesMod, multiplicities, identity, pointCount, rows = {},
   accepted = 0, attempts = 0, xv, xPowers, letterValues,
   letterDerivatives, sourceValues, bx, k, den, dden, mono, dmono,
   avalues, bvalues, matrix, nullspace, columns, normalized, member,
   selected},
  n = preparation["Dimension"]; n2 = n^2;
  degreeX = preparation["Degrees"][[1]];
  unknownCount = n2 (degreeX + 1);
  pointCount = degreeX + 4;
  epsMod = Mod[Numerator[epsilonValue] PowerMod[Denominator[epsilonValue], -1, prime], prime];
  maxPowers = preparation["MaximumPowers"];
  ePowers = Table[PowerMod[epsMod, p, prime], {p, 0, maxPowers[[3]]}];
  yPowers = Table[PowerMod[yValue, p, prime], {p, 0, maxPowers[[2]]}];
  sourceRules = preparation["SourceRules"];
  letterRules = preparation["LetterRules"];
  letterDerivativeRules = preparation["LetterDerivativeRules"];
  letterIndices = preparation["LetterIndices"];
  residuesMod = Map[Mod[Numerator[#] PowerMod[Denominator[#], -1, prime], prime] &,
    preparation["Residues"], {3}];
  multiplicities = preparation["Multiplicities"];
  identity = IdentityMatrix[n2];
  SeedRandom[seed];
  While[accepted < pointCount && attempts < 40 pointCount,
    attempts++;
    xv = RandomInteger[{2, prime - 2}];
    xPowers = Table[PowerMod[xv, p, prime], {p, 0, maxPowers[[1]]}];
    letterValues = diagonalBlockEvaluateRules[#, xPowers, yPowers, ePowers, prime] & /@ letterRules;
    If[MemberQ[letterValues, 0], Continue[]];
    sourceValues = Map[
      With[{num = diagonalBlockEvaluateRules[#[[1]], xPowers, yPowers, ePowers, prime],
        d = diagonalBlockEvaluateRules[#[[2]], xPowers, yPowers, ePowers, prime]},
        If[d === 0, $Failed, Mod[num PowerMod[d, -1, prime], prime]]] &,
      sourceRules, {2}];
    If[! FreeQ[sourceValues, $Failed], Continue[]];
    letterDerivatives = diagonalBlockEvaluateRules[#, xPowers, yPowers, ePowers, prime] & /@ letterDerivativeRules;
    (* a zero matrix seed: with no slice letters the Sum is the scalar 0
       and Transpose[0] poisoned the row block (1x1 classes, 2026-08-21) *)
    bx = Mod[epsMod (ConstantArray[0, {n, n}] + Sum[
      Mod[residuesMod[[i]] Mod[letterDerivatives[[letterIndices[[i]]]]
        PowerMod[letterValues[[letterIndices[[i]]]], -1, prime], prime], prime],
      {i, Length[letterIndices]}]), prime];
    k = Mod[KroneckerProduct[sourceValues, IdentityMatrix[n]] -
      KroneckerProduct[IdentityMatrix[n], Transpose[bx]], prime];
    den = Mod[Times @@ MapThread[PowerMod[#1, #2, prime] &, {letterValues, multiplicities}], prime];
    dden = Mod[den Sum[multiplicities[[i]] Mod[letterDerivatives[[i]]
      PowerMod[letterValues[[i]], -1, prime], prime], {i, Length[letterValues]}], prime];
    mono = xPowers[[Range[0, degreeX] + 1]];
    dmono = Mod[Range[0, degreeX] xPowers[[Max[#, 1] & /@ Range[0, degreeX]]], prime];
    avalues = Mod[den dmono - mono dden, prime];
    bvalues = Mod[den mono, prime];
    AppendTo[rows, Mod[KroneckerProduct[{avalues}, identity] - KroneckerProduct[{bvalues}, k], prime]];
    accepted++];
  If[accepted < pointCount,
    Return[<|"Status" -> "PointSamplingFailed", "Prime" -> prime|>]];
  matrix = Developer`ToPackedArray[Join @@ rows];
  nullspace = NullSpace[matrix, Modulus -> prime];
  If[Length[nullspace] =!= 1,
    Return[<|"Status" -> If[nullspace === {}, "NoSolution", "NullityNotOne"],
      "Prime" -> prime, "YValue" -> yValue, "EpsilonValue" -> epsilonValue,
      "Nullity" -> Length[nullspace], "UnknownCount" -> unknownCount|>]];
  selected = If[column === Automatic,
    First[finiteFieldStripIndependentColumns[nullspace, prime]], column];
  If[nullspace[[1, selected]] === 0,
    Return[<|"Status" -> "DiscardNormalizationSingular", "Prime" -> prime,
      "YValue" -> yValue, "EpsilonValue" -> epsilonValue|>]];
  member = Mod[PowerMod[nullspace[[1, selected]], -1, prime] nullspace[[1]], prime];
  <|"Status" -> "OK", "Prime" -> prime, "YValue" -> yValue,
    "EpsilonValue" -> epsilonValue, "EpsilonMod" -> epsMod, "Values" -> member,
    "NormalizationColumn" -> selected, "UnknownCount" -> unknownCount|>
];

(* Chinese remaindering + rational reconstruction of one regulator
   interpolation per prime into an exact rational function of eps *)
diagonalBlockLiftFunction[interpolations_List, primes_List, eps_] := Module[
  {combined, modulus = Times @@ primes, numerator, denominator},
  combined = epsFormFiniteFieldCombineCoordinate[interpolations, primes];
  If[combined === $Failed, Return[$Failed]];
  numerator = epsFormFiniteFieldRationalReconstruct[#, modulus] & /@ combined["Numerator"];
  denominator = epsFormFiniteFieldRationalReconstruct[#, modulus] & /@ combined["Denominator"];
  If[MemberQ[numerator, $Failed] || MemberQ[denominator, $Failed], Return[$Failed]];
  (* explicit Function variables: nested slots would bind to the prime *)
  If[! (And @@ MapThread[Function[{integer, rational},
          AllTrue[primes, epsFormFiniteFieldImageQ[integer, rational, #] &]],
        {combined["Numerator"], numerator}] &&
      And @@ MapThread[Function[{integer, rational},
          AllTrue[primes, epsFormFiniteFieldImageQ[integer, rational, #] &]],
        {combined["Denominator"], denominator}]),
    Return[$Failed]];
  Together[FromDigits[Reverse[numerator], eps]/FromDigits[Reverse[denominator], eps]]
];

(* assemble T from the per-prime nested interpolations: coordinate i
   (an x-coefficient of one entry) is  Sum_a c_ia(eps) y^a / Sum_b
   d_ib(eps) y^b  with c, d lifted from their regulator interpolations *)
diagonalBlockLift[modularData_List, preparation_Association, {x_, y_}, eps_,
    letters_List] := Catch[Module[
  {primes, coordinateCount, n, degreeX, den, coordinates, columnIndex},
  primes = Lookup[modularData, "Prime"];
  coordinateCount = Length[First[modularData]["Coordinates"]];
  If[Length[DeleteDuplicates[Lookup[modularData, "YDegrees"]]] =!= 1,
    Throw[<|"Status" -> "SpectatorDegreesInconsistent"|>, "lift"]];
  coordinates = Table[
    Module[{numerator, denominator},
      numerator = Table[
        diagonalBlockLiftFunction[
          modularData[[All, "Coordinates", i, "Numerator", a]], primes, eps],
        {a, Length[First[modularData]["Coordinates"][[i]]["Numerator"]]}];
      denominator = Table[
        diagonalBlockLiftFunction[
          modularData[[All, "Coordinates", i, "Denominator", b]], primes, eps],
        {b, Length[First[modularData]["Coordinates"][[i]]["Denominator"]]}];
      If[MemberQ[numerator, $Failed] || MemberQ[denominator, $Failed],
        Throw[<|"Status" -> "ModulusTooSmall", "Coordinate" -> i|>, "lift"]];
      Together[Sum[numerator[[a + 1]] y^a, {a, 0, Length[numerator] - 1}]/
        Sum[denominator[[b + 1]] y^b, {b, 0, Length[denominator] - 1}]]],
    {i, coordinateCount}];
  n = preparation["Dimension"];
  degreeX = preparation["Degrees"][[1]];
  den = Times @@ MapThread[Power, {letters, preparation["Multiplicities"]}];
  columnIndex[power_, i_, j_] := power n^2 + (i - 1) n + j;
  <|"Status" -> "OK",
    "Transformation" -> Table[Together[
      Sum[coordinates[[columnIndex[power, i, j]]] x^power, {power, 0, degreeX}]/den],
      {i, n}, {j, n}],
    "CombinedModulus" -> Times @@ primes, "Primes" -> primes|>
 ], "lift"];

Options[SolveDiagonalBlockGaugeFiniteField] = {
  "Primes" -> {2147483647, 2147483629, 2147483587, 2147483579,
    2147483563, 2147483549, 2147483543, 2147483497, 2147483489,
    2147483477, 2147483423, 2147483399, 2147483353, 2147483323,
    2147483269, 2147483249, 2147483237, 2147483179, 2147483171,
    2147483137},
  "EpsilonSampleCount" -> 40,
  "MaximumEpsilonSampleCount" -> 160,
  "SpectatorSampleCount" -> Automatic,
  "DenominatorMultiplicities" -> Automatic,
  "MultiplicitySlack" -> {0, 1, 2},
  "NumeratorDegreeOffsets" -> {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {6, 6}},
  "RandomSeed" -> 20260821,
  "Verbose" -> False
};

(* rational interpolation at KNOWN degrees {dn, dd}: one nullspace, no
   degree ladder; validated on every point; $Failed when the data do not
   fit those degrees (the caller then falls back to the ladder).  Same
   result shape as finiteFieldStripInterpolateCoordinate. *)
diagonalBlockInterpolateHinted[data_List, prime_Integer, {dn_, dd_}] := Module[
  {matrix, nullspace, vector, pair, degrees, requirement},
  If[dn === -Infinity,
    Return[If[AllTrue[data, Last[#] === 0 &],
      <|"Numerator" -> {0}, "Denominator" -> {1}, "Degrees" -> {-Infinity, 0},
        "ConstructionNullity" -> 1, "ValidatedPointCount" -> Length[data],
        "UniquenessPointRequirement" -> 1|>, $Failed]]];
  requirement = 2 (dn + dd) + 1;
  If[Length[data] < requirement || AnyTrue[data, Last[#] =!= 0 &] === False, Return[$Failed]];
  matrix = Table[Join[
    Table[PowerMod[datum[[1]], power, prime], {power, 0, dn}],
    Table[Mod[-datum[[2]] PowerMod[datum[[1]], power, prime], prime], {power, 0, dd}]],
    {datum, data}];
  nullspace = NullSpace[matrix, Modulus -> prime];
  If[Length[nullspace] =!= 1, Return[$Failed]];
  vector = First[nullspace];
  If[AllTrue[vector[[dn + 2 ;;]], # === 0 &], Return[$Failed]];
  pair = finiteFieldStripReduceRationalPair[vector[[1 ;; dn + 1]], vector[[dn + 2 ;;]], prime];
  degrees = Length[#] - 1 & /@ pair;
  If[degrees =!= {dn, dd} || ! finiteFieldStripInterpolationQ[pair, data, prime],
    Return[$Failed]];
  <|"Numerator" -> pair[[1]], "Denominator" -> pair[[2]], "Degrees" -> degrees,
    "ConstructionNullity" -> 1, "ValidatedPointCount" -> Length[data],
    "UniquenessPointRequirement" -> requirement|>
];

diagonalBlockInterpolate[data_List, prime_Integer, hint_, construction_Integer,
    maximumDegree_Integer] := Module[{result = $Failed},
  If[ListQ[hint], result = diagonalBlockInterpolateHinted[data, prime, hint]];
  If[result === $Failed,
    result = finiteFieldStripInterpolateCoordinate[data, prime, construction, maximumDegree]];
  result
];

(* nested rational interpolation of one list of samples:
   first in the spectator (per regulator value), then in the regulator
   (per spectator-polynomial coefficient).  Returns per coordinate
   <|"Numerator" -> {eps-interpolation per y-power}, "Denominator" -> ...|>
   or a failure association. *)
diagonalBlockNestedInterpolate[samples_List, prime_Integer, coordinateCount_Integer,
    hints_] := Catch[Module[
  {byEpsilon, spectatorInterpolations, degreesByCoordinate, yDegrees,
   construction, maximumDegree, coordinates, unresolved = {},
   learned, spectatorHints, regulatorHints},
  spectatorHints = Lookup[Replace[hints, Except[_Association] -> <||>], "Spectator", None];
  regulatorHints = Lookup[Replace[hints, Except[_Association] -> <||>], "Regulator", None];
  learned = If[ListQ[spectatorHints] && Length[spectatorHints] === coordinateCount,
    spectatorHints, ConstantArray[None, coordinateCount]];
  byEpsilon = GatherBy[samples, #EpsilonMod &];
  (* spectator interpolation for every regulator value and coordinate;
     degrees learned on the first group (or carried from the previous
     prime) make every later one a single nullspace *)
  spectatorInterpolations = Table[
    Module[{group = group, count = Length[group], result},
      construction = count - 6; maximumDegree = construction - 2;
      result = Table[
        With[{r = diagonalBlockInterpolate[
            ({#YValue, #Values[[i]]} &) /@ group, prime, learned[[i]], construction, maximumDegree]},
          If[AssociationQ[r] && learned[[i]] === None, learned[[i]] = r["Degrees"]];
          r],
        {i, coordinateCount}];
      <|"EpsilonMod" -> First[group]["EpsilonMod"], "Interpolations" -> result|>],
    {group, byEpsilon}];
  degreesByCoordinate = Table[
    Commonest[Cases[spectatorInterpolations[[All, "Interpolations", i]],
      a_Association :> a["Degrees"]]],
    {i, coordinateCount}];
  If[MemberQ[degreesByCoordinate, {}],
    Throw[<|"Status" -> "SpectatorInterpolationFailed",
      "Unresolved" -> Flatten[Position[degreesByCoordinate, {}]]|>, "nested"]];
  yDegrees = First /@ degreesByCoordinate;
  coordinates = Table[
    Module[{degrees = yDegrees[[i]], usable, numeratorLength, denominatorLength,
      numerator, denominator, epsilonCount, hintN, hintD},
      usable = Select[spectatorInterpolations,
        AssociationQ[#["Interpolations"][[i]]] &&
          #["Interpolations"][[i]]["Degrees"] === degrees &];
      epsilonCount = Length[usable];
      If[epsilonCount < 12,
        Throw[<|"Status" -> "TooFewRegulatorSamples", "Coordinate" -> i,
          "Count" -> epsilonCount|>, "nested"]];
      numeratorLength = If[degrees[[1]] === -Infinity, 1, degrees[[1]] + 1];
      denominatorLength = degrees[[2]] + 1;
      {hintN, hintD} = If[ListQ[regulatorHints] && Length[regulatorHints] === coordinateCount &&
          AssociationQ[regulatorHints[[i]]],
        {regulatorHints[[i]]["Numerator"], regulatorHints[[i]]["Denominator"]}, {{}, {}}];
      numerator = Table[
        diagonalBlockInterpolate[
          ({#EpsilonMod, PadRight[#["Interpolations"][[i]]["Numerator"], numeratorLength][[a]]} &) /@ usable,
          prime, If[Length[hintN] >= a, hintN[[a]], None], epsilonCount - 6, epsilonCount - 8],
        {a, numeratorLength}];
      denominator = Table[
        diagonalBlockInterpolate[
          ({#EpsilonMod, PadRight[#["Interpolations"][[i]]["Denominator"], denominatorLength][[b]]} &) /@ usable,
          prime, If[Length[hintD] >= b, hintD[[b]], None], epsilonCount - 6, epsilonCount - 8],
        {b, denominatorLength}];
      If[MemberQ[numerator, $Failed] || MemberQ[denominator, $Failed],
        AppendTo[unresolved, i]];
      <|"Numerator" -> numerator, "Denominator" -> denominator|>],
    {i, coordinateCount}];
  If[unresolved =!= {},
    Throw[<|"Status" -> "RegulatorInterpolationFailed", "Unresolved" -> unresolved|>, "nested"]];
  <|"Status" -> "OK", "Coordinates" -> coordinates, "YDegrees" -> yDegrees,
    "Hints" -> <|"Spectator" -> yDegrees,
      "Regulator" -> Table[<|"Numerator" -> Lookup[#, "Degrees"] & /@ c["Numerator"],
        "Denominator" -> Lookup[#, "Degrees"] & /@ c["Denominator"]|>, {c, coordinates}]|>,
    "SpectatorDegreeHistogram" -> Counts[yDegrees],
    "RegulatorDegreeHistogram" -> Counts[Flatten[Table[
      Lookup[#, "Degrees"] & /@ Join[c["Numerator"], c["Denominator"]], {c, coordinates}], 1]]|>
 ], "nested"];

(* Solve d_x T = A_x T - T B_x, B_x = eps Sum_a R_a d_x log phi_a, for a
   rational T with letter denominators.  sliceData is the output of
   DiagonalBlockSliceEpsForm (or any association with Letters,
   SliceLetters, SliceResidues). *)
SolveDiagonalBlockGaugeFiniteField[{ax_, ay_}, {x_, y_}, eps_,
    sliceData_Association, OptionsPattern[]] := Module[
  {verbose, log, letters, xLetters, residues, n, primes, sampleCount,
   maximumSampleCount, spectatorCount, baseMultiplicities, slacks, offsets,
   seed, t0 = AbsoluteTime[], preparation = $Failed, pilot, selected = $Failed,
   column, epsilonValues, spectatorValues, samples, data, nested, hints = None,
   modularData = {}, lift, transformation, bx, residual, ladder, degreeBase,
   status, growth, sampleSeconds = 0, interpolationSeconds = 0,
   liftSeconds = 0, checkSeconds = 0, seconds},
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[dblock-ff] ", args]];
  letters = sliceData["Letters"];
  xLetters = sliceData["SliceLetters"];
  residues = sliceData["SliceResidues"];
  n = Length[ax];
  If[! ListQ[letters] || ! ListQ[xLetters] || ! ListQ[residues] ||
      Length[xLetters] =!= Length[residues] ||
      ! AllTrue[residues, MatrixQ[#] && Dimensions[#] === {n, n} &] ||
      ! AllTrue[Flatten[residues], MatchQ[#, _Integer | _Rational] &],
    Message[SolveDiagonalBlockGaugeFiniteField::input];
    Return[<|"Status" -> "InputInvalid"|>]];
  primes = DeleteDuplicates[OptionValue["Primes"]];
  sampleCount = OptionValue["EpsilonSampleCount"];
  maximumSampleCount = OptionValue["MaximumEpsilonSampleCount"];
  spectatorCount = OptionValue["SpectatorSampleCount"];
  slacks = OptionValue["MultiplicitySlack"];
  offsets = OptionValue["NumeratorDegreeOffsets"];
  seed = OptionValue["RandomSeed"];
  baseMultiplicities = Replace[OptionValue["DenominatorMultiplicities"],
    Automatic :> diagonalBlockMultiplicityCensus[{ax, ay}, {x, y}, eps, letters]];
  growth = {diagonalBlockInfinityGrowth[ax, x, eps],
    diagonalBlockInfinityGrowth[ay, y, eps]};
  log["letters ", letters, "  multiplicity census ", baseMultiplicities,
    "  growth at infinity ", growth];
  epsilonValues[count_] := Table[k/(k + 20), {k, count}];
  (* spectator sample values: small integers avoiding letter zeros *)
  spectatorValues[count_] := Take[Select[Range[2, 40 count],
    Function[v, AllTrue[letters, FreeQ[#, x] || Together[Coefficient[#, x, 1] /. y -> v] =!= 0 &] &&
      AllTrue[Select[letters, FreeQ[#, x] &], Together[# /. y -> v] =!= 0 &] &&
      DuplicateFreeQ[diagonalBlockLinearRoot[# /. y -> v, x] & /@ Select[letters, ! FreeQ[#, x] &]]]],
    UpTo[count]];
  (* degree ladder: (multiplicity slack, numerator offset); the first
     ansatz with a one-dimensional ODE solution space is kept *)
  ladder = Flatten[Table[{s, o}, {s, slacks}, {o, offsets}], 1];
  Do[
    Module[{mult = baseMultiplicities + entry[[1]], degrees, prep, probe},
      degreeBase = {Total[mult Map[Exponent[#, x] &, letters]],
        Total[mult Map[Exponent[#, y] &, letters]]};
      degreeBase = Table[Max[0, degreeBase[[k]] +
        If[IntegerQ[growth[[k]]], growth[[k]], 0]], {k, 2}];
      degrees = degreeBase + entry[[2]];
      prep = diagonalBlockPrepareSampling[{ax, ay}, {x, y}, eps, letters,
        xLetters, residues, mult, degrees];
      probe = diagonalBlockSample[prep, First[spectatorValues[1]], epsilonValues[1][[1]],
        First[primes], Automatic, seed];
      log["probe multiplicities ", mult, " degrees ", degrees, " -> ",
        probe["Status"], " nullity ", Lookup[probe, "Nullity", 1],
        " unknowns ", Lookup[probe, "UnknownCount", 0]];
      If[probe["Status"] === "NullityNotOne" && Lookup[probe, "Nullity", 0] > 1,
        (* the x-equation alone does not fix the frame in this direction
           (a reducible slice); no ansatz change can help -- the caller
           switches the slice direction *)
        selected = "Degenerate"; Break[]];
      If[probe["Status"] === "OK",
        preparation = prep; pilot = probe; selected = entry; Break[]]],
    {entry, ladder}];
  If[selected === "Degenerate",
    Return[<|"Status" -> "SolutionSpaceDegenerate", "Seconds" -> AbsoluteTime[] - t0|>]];
  If[selected === $Failed,
    Return[<|"Status" -> "AnsatzLadderExhausted", "Seconds" -> AbsoluteTime[] - t0|>]];
  column = pilot["NormalizationColumn"];
  (* a coordinate is a ratio of two spectator polynomials of degree
     <= n_y: uniqueness of its rational interpolation needs 2(2 n_y)+1
     points, plus validation *)
  If[spectatorCount === Automatic,
    spectatorCount = 4 preparation["Degrees"][[2]] + 8];
  log["ansatz: multiplicities ", preparation["Multiplicities"], " degrees ",
    preparation["Degrees"], " unknowns per ODE ", pilot["UnknownCount"],
    " normalization column ", column, " spectator samples ", spectatorCount];
  status = "Unsolved";
  Do[
    Module[{count = sampleCount, done = False, primeStatus = "OK", ys},
      ys = spectatorValues[spectatorCount];
      While[! done,
        {seconds, samples} = AbsoluteTiming[Flatten[Table[
          diagonalBlockSample[preparation, yv, e, prime, column, seed + 7 yv],
          {e, epsilonValues[count]}, {yv, ys}]]];
        sampleSeconds += seconds;
        data = Select[samples, #["Status"] === "OK" &];
        log["prime ", prime, ": ", Length[data], "/", Length[samples],
          " ODE samples OK (", Round[seconds, 0.1], " s) ",
          Counts[#["Status"] & /@ Select[samples, #["Status"] =!= "OK" &]]];
        If[Length[data] < 12 spectatorCount, primeStatus = "TooFewSamples"; Break[]];
        {seconds, nested} = AbsoluteTiming[
          diagonalBlockNestedInterpolate[data, prime, pilot["UnknownCount"], hints]];
        interpolationSeconds += seconds;
        If[nested["Status"] === "OK", done = True,
          log["  interpolation: ", nested["Status"], " ",
            Lookup[nested, "Unresolved", ""], " at ", count, " regulator samples"];
          If[nested["Status"] =!= "RegulatorInterpolationFailed" &&
              nested["Status"] =!= "TooFewRegulatorSamples",
            primeStatus = nested["Status"]; Break[]];
          If[2 count > maximumSampleCount,
            primeStatus = "RegulatorDegreeTooHigh"; Break[]];
          count = 2 count]];
      If[primeStatus =!= "OK", status = primeStatus; Break[]];
      hints = nested["Hints"];
      AppendTo[modularData, <|"Prime" -> prime, "Coordinates" -> nested["Coordinates"],
        "YDegrees" -> nested["YDegrees"]|>];
      log["  spectator degrees ", nested["SpectatorDegreeHistogram"],
        "  regulator degrees ", nested["RegulatorDegreeHistogram"],
        "  (interpolation ", Round[seconds, 0.1], " s)"];
      {seconds, lift} = AbsoluteTiming[
        diagonalBlockLift[modularData, preparation, {x, y}, eps, letters]];
      liftSeconds += seconds;
      If[lift["Status"] =!= "OK", log["  lift: ", lift["Status"]]; Continue[]];
      transformation = lift["Transformation"];
      bx = eps Sum[residues[[i]] D[xLetters[[i]], x]/xLetters[[i]], {i, Length[xLetters]}];
      {seconds, residual} = AbsoluteTiming[
        diagonalBlockZeroQ[D[transformation, x] - ax . transformation + transformation . bx]];
      checkSeconds += seconds;
      log["  exact x-equation check: ", residual, "  (", Round[seconds, 0.1], " s)"];
      If[TrueQ[residual] && ! TrueQ[Together[Det[transformation]] === 0],
        status = "Solved"; Break[]]],
    {prime, primes}];
  If[status =!= "Solved",
    Return[<|"Status" -> If[status === "Unsolved", "NotReconstructed", status],
      "PrimeCount" -> Length[modularData], "Seconds" -> AbsoluteTime[] - t0|>]];
  <|"Status" -> "Solved",
    "Transformation" -> transformation,
    "Letters" -> letters, "SliceLetters" -> xLetters, "SliceResidues" -> residues,
    "Multiplicities" -> preparation["Multiplicities"],
    "NumeratorDegrees" -> preparation["Degrees"],
    "UnknownCount" -> pilot["UnknownCount"],
    "NormalizationColumn" -> column,
    "SpectatorSampleCount" -> spectatorCount,
    "Primes" -> lift["Primes"], "PrimeCount" -> Length[modularData],
    "SpectatorDegrees" -> Last[modularData]["YDegrees"],
    "ExactXEquation" -> True,
    "SampleSeconds" -> sampleSeconds, "InterpolationSeconds" -> interpolationSeconds,
    "LiftSeconds" -> liftSeconds, "CheckSeconds" -> checkSeconds,
    "Seconds" -> AbsoluteTime[] - t0|>
];

(* ---------------------------------------------------------------- *)
(* Exact completion in the spectator variable                        *)
(* ---------------------------------------------------------------- *)

diagonalBlockDLogForm[letters_List, residues_List, v_, eps_] :=
  eps Sum[residues[[i]] D[letters[[i]], v]/letters[[i]], {i, Length[letters]}];

(* Given T solving the x-equation, read off the pure-y residues and the
   rational scalar gauge from  T^-1 A_y T - T^-1 d_y T  exactly.  The
   remainder after the known letters is x-free and decomposes as
       eps Sum_b R_b dlog phi_b  +  (Sum_q k_q dlog q) 1,
   with phi_b the pure-y letters (linear in y) and q the factors of the
   scalar gauge (any degree in y, possibly regulator dependent), k_q
   integers.  Trace and traceless parts are treated separately so that a
   non-linear scalar factor never requires a residue computation. *)
CompleteDiagonalBlockEpsForm[{ax_, ay_}, {x_, y_}, eps_, solve_Association] :=
 Catch[Module[
  {t, letters, xLetters, xResidues, yLetters, n, inverse, formY, remainder,
   scalarPart, traceless, tracelessFactors, terms, grouped, scalarGauge = 1,
   traceParts = <||>, residues = <||>, yResidues, finalLetters,
   finalResidues, tFinal, details = {}, letterOf},
  t = solve["Transformation"];
  letters = solve["Letters"]; xLetters = solve["SliceLetters"];
  xResidues = solve["SliceResidues"];
  yLetters = Select[letters, FreeQ[#, x] &];
  n = Length[t];
  inverse = diagonalBlockTogether[Inverse[t]];
  formY = diagonalBlockTogether[inverse . ay . t - inverse . D[t, y]];
  remainder = diagonalBlockTogether[formY -
    diagonalBlockDLogForm[xLetters, xResidues, y, eps]];
  If[! FreeQ[remainder, x],
    Throw[<|"Status" -> "SpectatorRemainderDependsOnSliceVariable"|>, "dblock"]];
  letterOf[q_] := SelectFirst[Range[Length[yLetters]],
    diagonalBlockSameLetterQ[yLetters[[#]], q] &, $Failed];
  scalarPart = Cancel[Together[Tr[remainder]/n]];
  traceless = diagonalBlockTogether[remainder - scalarPart IdentityMatrix[n]];
  (* traceless part: only simple poles at pure-y letters *)
  tracelessFactors = Merge[Table[Association[Cases[FactorList[Denominator[entry]],
      {f_, e_} /; ! FreeQ[f, y] :> (f -> e)]], {entry, Flatten[traceless]}], Max];
  If[AnyTrue[Values[tracelessFactors], # > 1 &],
    Throw[<|"Status" -> "SpectatorPoleNotSimple", "Orders" -> tracelessFactors|>, "dblock"]];
  If[! diagonalBlockZeroQ[Map[PolynomialQuotient[Numerator[#], Denominator[#], y] &,
      traceless, {2}]],
    Throw[<|"Status" -> "SpectatorPolynomialPart"|>, "dblock"]];
  Do[
    Module[{q = factor, index = letterOf[factor], root, res},
      If[index === $Failed,
        Throw[<|"Status" -> "TracelessPoleAtNonLetter", "Factor" -> q|>, "dblock"]];
      root = diagonalBlockLinearRoot[q, y];
      If[root === $Failed,
        Throw[<|"Status" -> "SpectatorLetterNotLinear", "Factor" -> q|>, "dblock"]];
      res = diagonalBlockTogether[diagonalBlockResidueAt[traceless, y, root]/eps];
      If[! FreeQ[res, eps],
        Throw[<|"Status" -> "SpectatorResidueNotConstant", "Factor" -> q|>, "dblock"]];
      residues[yLetters[[index]]] = res],
    {factor, DeleteDuplicates[Keys[tracelessFactors], diagonalBlockSameLetterQ]}];
  (* scalar part: partial fractions in y; every term must be a constant
     multiple c dlog q with c = k + eps tau, k integer; tau is the
     trace/n of a letter residue and must vanish at non-letters *)
  terms = Replace[Apart[scalarPart, y],
    {HoldPattern[Plus[a__]] :> {a}, 0 -> {}, other_ :> {other}}];
  grouped = GroupBy[terms, Function[term,
    With[{den = Denominator[Together[term]]},
      Select[First /@ Rest[FactorList[den]], ! FreeQ[#, y] &]]]];
  If[KeyExistsQ[grouped, {}] && ! diagonalBlockZeroQ[Total[grouped[{}]]],
    Throw[<|"Status" -> "SpectatorScalarPolynomialPart"|>, "dblock"]];
  Do[
    Module[{q, term, ratio, k, tau, index},
      If[key === {}, Continue[]];
      If[Length[key] =!= 1,
        Throw[<|"Status" -> "SpectatorScalarTermNotPrimary", "Factors" -> key|>, "dblock"]];
      q = First[key];
      term = Together[Total[grouped[key]]];
      ratio = Cancel[Together[term q/D[q, y]]];
      If[! FreeQ[ratio, y],
        Throw[<|"Status" -> "SpectatorScalarTermNotDLog", "Factor" -> q|>, "dblock"]];
      k = diagonalBlockIntegerPart[ratio, eps];
      tau = Cancel[Together[(ratio - k)/eps]];
      index = letterOf[q];
      If[! IntegerQ[k] || ! FreeQ[tau, eps] || (index === $Failed && tau =!= 0),
        Throw[<|"Status" -> "SpectatorScalarTermInvalid", "Factor" -> q,
          "Ratio" -> ratio|>, "dblock"]];
      scalarGauge = scalarGauge q^k;
      If[index =!= $Failed, traceParts[yLetters[[index]]] = tau];
      AppendTo[details, <|"Factor" -> q, "IntegerPart" -> k,
        "Letter" -> index =!= $Failed|>]],
    {key, Keys[grouped]}];
  yResidues = Table[
    Lookup[residues, l, ConstantArray[0, {n, n}]] +
      Lookup[traceParts, l, 0] IdentityMatrix[n],
    {l, yLetters}];
  tFinal = diagonalBlockTogether[t scalarGauge];
  finalLetters = Join[xLetters, yLetters];
  finalResidues = Join[xResidues, yResidues];
  With[{keep = Select[Range[Length[finalLetters]],
      ! diagonalBlockZeroQ[finalResidues[[#]]] &]},
    finalLetters = finalLetters[[keep]]; finalResidues = finalResidues[[keep]]];
  <|"Status" -> "OK", "Transformation" -> tFinal, "ScalarGauge" -> scalarGauge,
    "Letters" -> finalLetters, "Residues" -> finalResidues,
    "SpectatorPoles" -> details|>
 ], "dblock"];

(* ---------------------------------------------------------------- *)
(* The gate                                                          *)
(* ---------------------------------------------------------------- *)

CertifyDiagonalBlockEpsForm[{ax_, ay_}, {x_, y_}, eps_, t_List, letters_List,
    residues_List] := Module[
  {inverse, formX, formY, targetX, targetY, gateX, gateY, flat, det,
   constant, lettersEpsilonFree, t0 = AbsoluteTime[]},
  det = Together[Det[t]];
  If[TrueQ[det === 0], Return[<|"Status" -> "TransformationSingular"|>]];
  inverse = diagonalBlockTogether[Inverse[t]];
  formX = diagonalBlockTogether[inverse . ax . t - inverse . D[t, x]];
  formY = diagonalBlockTogether[inverse . ay . t - inverse . D[t, y]];
  targetX = diagonalBlockDLogForm[letters, residues, x, eps];
  targetY = diagonalBlockDLogForm[letters, residues, y, eps];
  gateX = diagonalBlockZeroQ[formX - targetX];
  gateY = diagonalBlockZeroQ[formY - targetY];
  constant = FreeQ[residues, x | y | eps];
  lettersEpsilonFree = FreeQ[letters, eps];
  flat = diagonalBlockZeroQ[D[targetX, y] - D[targetY, x] + targetX . targetY - targetY . targetX];
  <|"Status" -> If[gateX && gateY && constant && lettersEpsilonFree && flat,
      "Certified", "GateFailed"],
    "GateX" -> gateX, "GateY" -> gateY, "ConstantResidues" -> constant,
    "LettersEpsFree" -> lettersEpsilonFree,
    "Flat" -> flat, "Invertible" -> True, "EpsForm" -> {targetX, targetY},
    "Seconds" -> AbsoluteTime[] - t0|>
];

(* ---------------------------------------------------------------- *)
(* Scalar blocks                                                     *)
(* ---------------------------------------------------------------- *)

(* A 1x1 block needs no slice: every pole q of (a_x, a_y) carries a
   coefficient k_q + eps r_q; T = Prod q^k_q, letters = the q with r_q
   != 0.  Each q must be linear in at least one variable (the
   coefficient is read as a residue in that variable). *)
(* coefficient c of a simple pole along the curve q = 0 in  entry =
   c q_u/q + regular,  read modulo q in the variable u: with entry =
   N/(q D), c = N/(D q_u) on the curve, i.e. N - c D q_u == 0 mod q for
   a constant c.  Works for q of any degree in u. *)
diagonalBlockCurveCoefficient[entry_, q_, u_, eps_] := Module[
  {e = Cancel[Together[entry]], num, den, cofactor, rn, rd, c},
  num = Numerator[e]; den = Denominator[e];
  cofactor = Cancel[Together[den/q]];
  If[! PolynomialQ[cofactor, u] ||
      TrueQ[PolynomialRemainder[cofactor, q, u] === 0],
    Return[$Failed]];  (* q not a factor, or a higher-order pole *)
  rn = PolynomialRemainder[num, q, u];
  rd = PolynomialRemainder[cofactor D[q, u], q, u];
  If[TrueQ[rd === 0], Return[$Failed]];
  (* c = rn/rd must be constant modulo q: test with the leading coefficient *)
  c = Cancel[Together[Coefficient[rn, u, Exponent[rd, u]]/Coefficient[rd, u, Exponent[rd, u]]]];
  If[! TrueQ[PolynomialRemainder[Together[rn - c rd], q, u] === 0] || ! FreeQ[c, u],
    Return[$Failed]];
  c
];

diagonalBlockScalarEpsForm[{ax_, ay_}, {x_, y_}, eps_] := Catch[Module[
  {a = {Cancel[Together[ax[[1, 1]]]], Cancel[Together[ay[[1, 1]]]]}, factors,
   transformation = 1, letters = {}, residues = {}, coefficient, k, r},
  factors = DeleteDuplicates[Select[Flatten[
    First /@ Rest[FactorList[Denominator[#]]] & /@ a], ! FreeQ[#, x | y] &],
    diagonalBlockSameLetterQ];
  Do[
    Module[{q = factor, u, entry},
      Which[
        ! FreeQ[q, x] && ! FreeQ[a[[1]], x], u = x; entry = a[[1]],
        ! FreeQ[q, y], u = y; entry = a[[2]],
        True, u = x; entry = a[[1]]];
      coefficient = diagonalBlockCurveCoefficient[entry, q, u, eps];
      If[coefficient === $Failed && u === x && ! FreeQ[q, y],
        coefficient = diagonalBlockCurveCoefficient[a[[2]], q, y, eps]];
      If[coefficient === $Failed,
        Throw[<|"Status" -> "ScalarCoefficientNotFound", "Factor" -> q|>, "scalar"]];
      If[! FreeQ[coefficient, x | y],
        Throw[<|"Status" -> "ScalarCoefficientNotConstant", "Factor" -> q|>, "scalar"]];
      k = diagonalBlockIntegerPart[coefficient, eps];
      r = Cancel[Together[(coefficient - k)/eps]];
      If[! IntegerQ[k] || ! FreeQ[r, eps],
        Throw[<|"Status" -> "ScalarCoefficientNotAffine", "Factor" -> q,
          "Coefficient" -> coefficient|>, "scalar"]];
      transformation = transformation q^k;
      If[r =!= 0, AppendTo[letters, q]; AppendTo[residues, {{r}}]]],
    {factor, factors}];
  <|"Status" -> "OK", "Transformation" -> {{transformation}},
    "Letters" -> letters, "Residues" -> residues|>
 ], "scalar"];

(* ---------------------------------------------------------------- *)
(* Driver                                                            *)
(* ---------------------------------------------------------------- *)

Options[DiagonalBlockEpsForm] = Join[
  Options[DiagonalBlockSliceEpsForm],
  FilterRules[Options[SolveDiagonalBlockGaugeFiniteField], Except["Verbose"]],
  {"Shears" -> {1, -1, 2, -2, 3}, "ChartRetry" -> True}];

(* conic chart retry (the CanonicalBlocks rule): exactly one irreducible
   factor of total degree two among the poles means one conic, hence a
   rational parametrization; the block is then solved in the chart
   variables and the record carries the chart, as the class ledger does. *)
diagonalBlockChartRetry[{ax_, ay_}, {x_, y_}, eps_, opts_List] := Module[
  {quadratics, parameter, chart, candidates, variables, result},
  quadratics = Select[canonicalBlocksQuadraticFactors[{ax, ay}, {x, y}], FreeQ[#, eps] &];
  If[Length[quadratics] =!= 1, Return[<|"Status" -> "ChartNotSingleQuadratic",
    "Quadratics" -> quadratics|>]];
  parameter = Symbol["Global`t"];
  (* both signs of the conic (q = t^2 and -q = t^2) are genuine charts;
     the one whose pulled-back alphabet is linear in a variable is the
     usable one -- the hard-class lesson "check the pulled-back alphabet
     before anything else" (class 79, 2026-08-16) *)
  candidates = DeleteCases[Table[
    Module[{c = canonicalBlocksBuildChart[sign First[quadratics], {x, y}, parameter], sys, vars, lets},
      If[c === None, None,
        {sys, vars} = canonicalBlocksApplyChart[{ax, ay}, c, {x, y}, parameter];
        sys = diagonalBlockTogether /@ sys;
        lets = DiagonalBlockLetters[sys, vars, eps]["Letters"];
        <|"Chart" -> c, "System" -> sys, "Variables" -> vars,
          "Linear" -> AnyTrue[vars, Function[u, AllTrue[lets, Exponent[#, u] <= 1 &]]]|>]],
    {sign, {1, -1}}], None];
  (* catalog charts (TransportCharts.wl) whose root square is this
     quadratic: the Kallen and Q4 parametrizations, whose pulled-back
     alphabets are known to be linear where the conic t-chart's is not
     (class 79, 2026-08-16) *)
  If[SymbolName[x] === "v" && SymbolName[y] === "w",
    Do[
      If[Lookup[entry, "Kind", None] === "TwoVariable" && Length[Lookup[entry, "Roots", {}]] === 1 &&
          diagonalBlockSameLetterQ[entry["RootSquare"], First[quadratics]],
        Module[{sub = entry["Subst"], cv = entry["Variables"], sv, sw, sys, lets},
          sv = x /. sub; sw = y /. sub;
          sys = diagonalBlockTogether /@ {
            (ax /. sub) D[sv, cv[[1]]] + (ay /. sub) D[sw, cv[[1]]],
            (ax /. sub) D[sv, cv[[2]]] + (ay /. sub) D[sw, cv[[2]]]};
          lets = DiagonalBlockLetters[sys, cv, eps]["Letters"];
          AppendTo[candidates, <|"Chart" -> entry, "System" -> sys, "Variables" -> cv,
            "Linear" -> AnyTrue[cv, Function[u, AllTrue[lets, Exponent[#, u] <= 1 &]]]|>]]],
      {entry, Values[TransportChartCatalog[]]}]];
  If[candidates === {}, Return[<|"Status" -> "ChartNotBuilt", "Quadratic" -> First[quadratics]|>]];
  candidates = SortBy[candidates, If[#["Linear"], 0, 1] &];
  result = <|"Status" -> "ChartAttemptsFailed"|>;
  Do[
    result = DiagonalBlockEpsForm[candidate["System"], candidate["Variables"], eps,
      "ChartRetry" -> False, Sequence @@ FilterRules[opts, Except["ChartRetry"]]];
    chart = candidate["Chart"]; variables = candidate["Variables"];
    If[result["Status"] === "Certified", Break[]],
    {candidate, candidates}];
  Join[result, <|"Chart" -> chart, "ChartVariables" -> variables,
    "SourceVariables" -> {x, y}|>]
];

(* candidate frames: slice in x, slice in y, then sheared frames (x, s)
   with y = s + lambda x (a generic line through the spectator
   direction; restricting an irreducible connection to a generic line
   keeps its monodromy, so the x-equation has a one-dimensional solution
   space there even when the coordinate slices are reducible) *)
diagonalBlockFrames[{ax_, ay_}, {x_, y_}, eps_, letters_List, shears_List] := Module[
  {frames = {}, s = Unique["s"], linearQ},
  linearQ[lets_, u_] := AllTrue[lets, Exponent[Cancel[Together[#]], u] <= 1 &];
  Do[
    Module[{u = orientation[[1]], uy = orientation[[2]], au = orientation[[3]], auy = orientation[[4]]},
      Do[
        With[{forward = If[lambda === 0, {}, {uy -> s + lambda u}]},
          If[linearQ[letters /. forward, u],
            AppendTo[frames, <|
              "Name" -> "Slice" <> ToString[u] <> If[lambda === 0, "", "Shear" <> ToString[lambda]],
              "System" -> If[lambda === 0, {au, auy},
                {diagonalBlockTogether[(au + lambda auy) /. forward],
                 diagonalBlockTogether[auy /. forward]}],
              "Variables" -> If[lambda === 0, {u, uy}, {u, s}],
              "Back" -> If[lambda === 0, {}, {s -> uy - lambda u}],
              "Forward" -> forward|>]]],
        {lambda, Prepend[shears, 0]}]],
    {orientation, {{x, y, ax, ay}, {y, x, ay, ax}}}];
  (* plain slices first, then shears *)
  SortBy[frames, Length[#["Forward"]] &]
];

DiagonalBlockEpsForm[{ax_, ay_}, {x_, y_}, eps_, opts : OptionsPattern[]] :=
 Module[{n, letters, frames, attempts = {}, t0 = AbsoluteTime[], verbose,
   log, scalar, gate, result = None},
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[dblock] ", args]];
  n = Length[ax];
  (* zero block *)
  If[diagonalBlockZeroQ[ax] && diagonalBlockZeroQ[ay],
    Return[<|"Status" -> "Certified", "Transformation" -> IdentityMatrix[n],
      "Letters" -> {}, "Residues" -> {}, "EpsForm" -> {ConstantArray[0, {n, n}], ConstantArray[0, {n, n}]},
      "ScalarGauge" -> 1, "Variables" -> {x, y}, "Regulator" -> eps,
      "Method" -> "ZeroBlock", "Frame" -> "Identity",
      "Gate" -> <|"Status" -> "Certified", "GateX" -> True, "GateY" -> True,
        "ConstantResidues" -> True, "LettersEpsFree" -> True,
        "Flat" -> True, "Invertible" -> True|>,
      "Timing" -> <|"TotalSeconds" -> AbsoluteTime[] - t0|>|>]];
  (* scalar block *)
  If[n === 1,
    scalar = diagonalBlockScalarEpsForm[{ax, ay}, {x, y}, eps];
    If[scalar["Status"] =!= "OK",
      Return[<|"Status" -> "ScalarFailed", "Scalar" -> scalar|>]];
    gate = CertifyDiagonalBlockEpsForm[{ax, ay}, {x, y}, eps,
      scalar["Transformation"], scalar["Letters"], scalar["Residues"]];
    Return[<|"Status" -> If[gate["Status"] === "Certified", "Certified", "GateFailed"],
      "Transformation" -> scalar["Transformation"],
      "Letters" -> scalar["Letters"], "Residues" -> scalar["Residues"],
      "EpsForm" -> Lookup[gate, "EpsForm", Missing[]], "ScalarGauge" -> scalar["Transformation"][[1, 1]],
      "Variables" -> {x, y}, "Regulator" -> eps, "Method" -> "ScalarDLog", "Frame" -> "Identity",
      "Gate" -> KeyDrop[gate, "EpsForm"],
      "Timing" -> <|"TotalSeconds" -> AbsoluteTime[] - t0|>|>]];
  letters = DiagonalBlockLetters[{ax, ay}, {x, y}, eps]["Letters"];
  frames = diagonalBlockFrames[{ax, ay}, {x, y}, eps, letters, OptionValue["Shears"]];
  If[frames === {},
    AppendTo[attempts, <|"Frame" -> "None", "Stage" -> "Frames",
      "Status" -> "NoLinearSliceFrame"|>]];
  Do[
    Module[{fs = frame["System"], fv = frame["Variables"], slice, solve, completion,
      tBack, lettersBack, ts = AbsoluteTime[]},
      log["frame ", frame["Name"], " variables ", fv];
      slice = DiagonalBlockSliceEpsForm[fs, fv, eps,
        Sequence @@ FilterRules[{opts}, Options[DiagonalBlockSliceEpsForm]]];
      If[slice["Status"] =!= "OK",
        AppendTo[attempts, <|"Frame" -> frame["Name"], "Stage" -> "Slice",
          "Status" -> slice["Status"], "Seconds" -> AbsoluteTime[] - ts|>];
        log["  slice: ", slice["Status"]]; Continue[]];
      solve = SolveDiagonalBlockGaugeFiniteField[fs, fv, eps, slice,
        Sequence @@ FilterRules[{opts}, Options[SolveDiagonalBlockGaugeFiniteField]]];
      If[solve["Status"] =!= "Solved",
        AppendTo[attempts, <|"Frame" -> frame["Name"], "Stage" -> "Solve",
          "Status" -> solve["Status"], "Seconds" -> AbsoluteTime[] - ts|>];
        log["  solve: ", solve["Status"]]; Continue[]];
      completion = CompleteDiagonalBlockEpsForm[fs, fv, eps, solve];
      If[completion["Status"] =!= "OK",
        AppendTo[attempts, <|"Frame" -> frame["Name"], "Stage" -> "Completion",
          "Status" -> completion["Status"], "Seconds" -> AbsoluteTime[] - ts|>];
        log["  completion: ", completion["Status"]]; Continue[]];
      tBack = diagonalBlockTogether[completion["Transformation"] /. frame["Back"]];
      lettersBack = Cancel[Together[#]] & /@ (completion["Letters"] /. frame["Back"]);
      gate = CertifyDiagonalBlockEpsForm[{ax, ay}, {x, y}, eps, tBack, lettersBack,
        completion["Residues"]];
      AppendTo[attempts, <|"Frame" -> frame["Name"], "Stage" -> "Gate",
        "Status" -> gate["Status"], "Seconds" -> AbsoluteTime[] - ts|>];
      log["  gate: ", gate["Status"]];
      If[gate["Status"] === "Certified",
        result = <|"Status" -> "Certified",
          "Transformation" -> tBack, "Letters" -> lettersBack,
          "Residues" -> completion["Residues"], "EpsForm" -> gate["EpsForm"],
          "ScalarGauge" -> completion["ScalarGauge"] /. frame["Back"],
          "Variables" -> {x, y}, "Regulator" -> eps,
          "Method" -> "SliceResiduesFiniteFieldAffine", "Frame" -> frame["Name"],
          "FrameVariables" -> fv,
          "Gate" -> KeyDrop[gate, "EpsForm"],
          "Slice" -> KeyDrop[slice, "SliceTransformation"],
          "Solve" -> KeyDrop[solve, {"Transformation", "SliceResidues"}],
          "Attempts" -> attempts,
          "Timing" -> <|"SliceSeconds" -> slice["Seconds"],
            "SolveSeconds" -> solve["Seconds"], "GateSeconds" -> gate["Seconds"],
            "TotalSeconds" -> AbsoluteTime[] - t0|>|>;
        Break[]]],
    {frame, frames}];
  If[result =!= None, Return[result]];
  If[TrueQ[OptionValue["ChartRetry"]],
    Module[{retry = diagonalBlockChartRetry[{ax, ay}, {x, y}, eps, {opts}]},
      If[retry["Status"] === "Certified",
        Return[Join[retry, <|"Attempts" -> Join[attempts, Lookup[retry, "Attempts", {}]],
          "Frame" -> "Chart:" <> ToString[Lookup[retry, "Frame", ""]]|>]]];
      AppendTo[attempts, <|"Frame" -> "Chart", "Stage" -> "Chart",
        "Status" -> retry["Status"], "Detail" -> KeyDrop[retry, {"Transformation", "EpsForm", "Slice", "Solve"}]|>]]];
  <|"Status" -> "NotCertified", "Attempts" -> attempts, "Letters" -> letters,
    "Timing" -> <|"TotalSeconds" -> AbsoluteTime[] - t0|>|>
];

(* ---------------------------------------------------------------- *)
(* Class campaign (the CanonicalizeClasses contract)                 *)
(* ---------------------------------------------------------------- *)

Options[DiagonalBlockClassCampaign] = {
  "Kernels" -> 0,
  "Overwrite" -> False,
  (* the dim-4 hard classes need up to ~3000 s in a 4-subkernel pool
     (class 77: 2950 s, measured 2026-08-21) *)
  "TimeConstraint" -> 3600,
  "Fallback" -> None,
  "CanonicaValidation" -> True,
  "Verbose" -> True
};

DiagonalBlockClassCampaign::input =
  "The classes must be a list of class records with RepAv, RepAw and ClassID, or the path of such a file.";

(* one class -> one ledger record (schema of CanonicalBlocks.wl's
   CanonicalizeClasses: Transformation, EpsForm, Variables, Chart, Frame,
   Method, Seconds, Validated), or a failure record *)
diagonalBlockClassRecord[class_Association, eps_, timeConstraint_, fallback_,
    canonicaValidation_] := Module[
  {v = Symbol["Global`v"], w = Symbol["Global`w"], matrices, start = AbsoluteTime[],
   result, record, validated, variables, chart},
  matrices = diagonalBlockTogether /@ {class["RepAv"], class["RepAw"]};
  result = TimeConstrained[DiagonalBlockEpsForm[matrices, {v, w}, eps],
    timeConstraint, <|"Status" -> "TimedOut"|>];
  If[result["Status"] =!= "Certified" && fallback === "CANONICA",
    Module[{converted, attempt},
      canonicalBlocksLoadCanonica[];
      converted = matrices /. canonicalBlocksToCanonica[eps];
      attempt = canonicalBlocksAttempt[converted, Length[matrices[[1]]], {v, w},
        {0, 1, 2}, 300, 12 10^9, canonicalBlocksSolve[Automatic], eps, False];
      If[AssociationQ[attempt],
        result = <|"Status" -> "Certified",
          "Transformation" -> (attempt["Transformation"] /. canonicalBlocksFromCanonica[eps]),
          "EpsForm" -> (attempt["EpsForm"] /. canonicalBlocksFromCanonica[eps]),
          "Variables" -> {v, w}, "Regulator" -> eps, "Method" -> "CANONICA",
          "Frame" -> "vw", "AnsatzDegree" -> attempt["AnsatzDegree"],
          "FallbackAttempts" -> Lookup[result, "Attempts", {}]|>]]];
  If[result["Status"] =!= "Certified",
    Return[<|"ClassID" -> Lookup[class, "ClassID", None], "Status" -> result["Status"],
      "Attempts" -> Lookup[result, "Attempts", {}],
      "Detail" -> KeyDrop[result, {"Transformation", "EpsForm", "Slice", "Solve", "Attempts"}],
      "Seconds" -> AbsoluteTime[] - start|>]];
  variables = Lookup[result, "ChartVariables", result["Variables"]];
  chart = Lookup[result, "Chart", None];
  validated = If[TrueQ[canonicaValidation],
    (canonicalBlocksLoadCanonica[];
     TrueQ[ValidateCanonicalForm[
       result["EpsForm"] /. canonicalBlocksToCanonica[eps], variables,
       "Regulator" -> CANONICA`eps]]),
    Missing["NotRun"]];
  <|
    "Format" -> "FeynFacet-CanonicalClassForm",
    "FormatVersion" -> $canonicalBlocksArtifactVersion,
    "ClassID" -> Lookup[class, "ClassID", None],
    "ContentAddress" -> Lookup[class, "ContentAddress", None],
    "RepFamily" -> Lookup[class, "RepFamily", None],
    "RepRows" -> Lookup[class, "RepRows", None],
    "RepBasis" -> Lookup[class, "RepBasis", Missing[]],
    "Dim" -> Length[matrices[[1]]],
    "Transformation" -> result["Transformation"],
    "EpsForm" -> result["EpsForm"],
    "Variables" -> variables,
    "Regulator" -> eps,
    "Chart" -> chart,
    "Frame" -> Lookup[result, "Frame", "vw"],
    "Method" -> Lookup[result, "Method", "SliceResiduesFiniteFieldAffine"],
    "Letters" -> Lookup[result, "Letters", Missing[]],
    "Residues" -> Lookup[result, "Residues", Missing[]],
    "Certificate" -> Lookup[result, "Gate", Missing[]],
    "Attempts" -> Lookup[result, "Attempts", {}],
    "Timing" -> Lookup[result, "Timing", Missing[]],
    "Seconds" -> AbsoluteTime[] - start,
    "Status" -> "CANONICALIZED",
    "Validated" -> validated
  |>
];

DiagonalBlockClassCampaign[input_, directory_String, OptionsPattern[]] := Module[
  {classes, eps = Symbol["Global`eps"], kernels, overwrite, timeConstraint, fallback,
   canonicaValidation, verbose, log, todo, results = {}, file, launched, queue, running,
   result, finished, record, report},
  classes = Which[
    StringQ[input], FamilyArtifactRead[input],
    ListQ[input], input,
    AssociationQ[input] && KeyExistsQ[input, "Classes"], input["Classes"],
    True, $Failed];
  If[! (ListQ[classes] && AllTrue[classes, AssociationQ[#] && KeyExistsQ[#, "RepAv"] &]),
    Message[DiagonalBlockClassCampaign::input]; Return[$Failed]];
  kernels = OptionValue["Kernels"]; overwrite = TrueQ[OptionValue["Overwrite"]];
  timeConstraint = OptionValue["TimeConstraint"]; fallback = OptionValue["Fallback"];
  canonicaValidation = OptionValue["CanonicaValidation"];
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[dblock-campaign] ", args]];
  If[! DirectoryQ[directory], CreateDirectory[directory, CreateIntermediateDirectories -> True]];
  file[class_] := FileNameJoin[{directory, "class" <> ToString[Lookup[class, "ClassID", "unknown"]] <> ".wl"}];
  todo = Select[classes, overwrite || ! FileExistsQ[file[#]] &];
  log[Length[todo], " of ", Length[classes], " classes to do"];
  report[class_, rec_] := (
    If[rec["Status"] === "CANONICALIZED", FamilyArtifactWrite[rec, file[class]]];
    AppendTo[results, KeyTake[rec, {"ClassID", "Status", "Method", "Frame", "Seconds", "Validated", "Attempts", "Detail"}]];
    log["class ", rec["ClassID"], " dim ", Lookup[class, "Dim", "-"], " -> ", rec["Status"],
      " ", Lookup[rec, "Method", ""], " ", Lookup[rec, "Frame", ""], " ",
      Round[rec["Seconds"], 0.1], " s", If[rec["Status"] =!= "CANONICALIZED", " " <> ToString[Lookup[rec, "Detail", ""]], ""]]);
  If[kernels > 0,
    launched = LaunchKernels[kernels];
    With[{loader = FileNameJoin[{$feynFacetRoot, "Addon", "Load", "LoadFACET.wl"}]},
      ParallelEvaluate[Block[{$Output = {}}, Get[loader]]; $KernelID]];
    queue = todo; running = {};
    While[queue =!= {} || running =!= {},
      While[queue =!= {} && Length[running] < kernels,
        (* ParallelSubmit holds its argument: inject the option VALUES,
           not the main kernel's Module variables *)
        With[{class = First[queue], tc = timeConstraint, fb = fallback, cv = canonicaValidation},
          AppendTo[running, ParallelSubmit[
            {class, FeynFacet`Private`diagonalBlockClassRecord[class, Symbol["Global`eps"],
              tc, fb, cv]}]]];
        queue = Rest[queue]];
      If[running =!= {},
        {result, finished, running} = WaitNext[running];
        If[ListQ[result] && Length[result] === 2 && AssociationQ[result[[2]]],
          report[result[[1]], result[[2]]],
          log["evaluation failed: ", Short[result]]]]];
    CloseKernels[launched],
    Do[report[class, diagonalBlockClassRecord[class, eps, timeConstraint, fallback, canonicaValidation]],
      {class, todo}]];
  <|"Directory" -> directory, "Classes" -> Length[classes], "Attempted" -> Length[todo],
    "Canonicalized" -> Count[results, r_ /; r["Status"] === "CANONICALIZED"],
    "Results" -> results|>
];
