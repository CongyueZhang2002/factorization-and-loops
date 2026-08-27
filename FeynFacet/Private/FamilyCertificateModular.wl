(* Modular (finite-field) family certificate (2026-08-22; revised the same
   day after Codex's adversarial review,
   Exchange/Codex/2026-08-22/02_final_checker_stress_suite).

   Every matrix entry is compiled ONCE (after Together) into integer
   coefficient and exponent arrays; all identities are evaluated at random
   points modulo DISTINCT random 24-bit primes with power tables and packed
   dot products:
     S S^-1 = 1,  S^-1 (A S - dS) = A',  dA' + A'^A' = 0,
     e2 A'(e1) = e1 A'(e2)   (eps-factorization, e2 != e1),
     A' = eps Sum_a K_a dlog L_a with CONSTANT K_a (dlog form; letters =
       irreducible factors of the combined denominators; the residues are
       FITTED on training points until the design has full column rank and
       VALIDATED on fresh points; rank deficiency at a prime discards the
       prime; an empty alphabet certifies only a zero form),
     dA + A^A = 0 in the source variables at the mapped point.
   Residues: CRT of the per-prime solutions, rational reconstruction against
   the product modulus, verification at every prime (sticky); a missing or
   unverified residue fails ConstantResidues.
   Degree bounds are propagated per identity through the rational
   operations ({n, d} pairs: product, derivative, common-denominator sum,
   composition with the chart map); error terms are reported separately:
   ordinary identities, dlog validation, and the bad-characteristic term
   (a prime dividing the content of a nonzero residual), the last guarded by
   one exact characteristic-zero evaluation of the matrix identities. *)

ClearAll[
  familyCertCompile, familyCertCompileMatrix, familyCertPowers, familyCertPolyValue,
  familyCertValue, familyCertDerivativeValue, familyCertMatrixValue, familyCertMatrixDerivativeValue,
  familyCertDegree, familyCertLetters, familyCertRationalReconstruct,
  familyCertDegMul, familyCertDegDeriv, familyCertDegAdd, familyCertDegCompose, familyCertBounds,
  familyCertCharacteristicZeroPoint, familyCertificateModular
];

(* ---- compilation ---- *)

familyCertCompile[expr_, symbols_List] := Module[{rat, num, den, rn, rd, scale, cn, cd},
  If[TrueQ[expr === 0], Return[<|"Zero" -> True, "Degree" -> {0, 0}, "Max" -> {0, 0, 0}, "Height" -> 1, "Terms" -> 0|>]];
  rat = Together[expr];
  {num, den} = {Numerator[rat], Denominator[rat]};
  If[! (PolynomialQ[num, symbols] && PolynomialQ[den, symbols]), Return[$Failed]];
  rn = CoefficientRules[Expand[num], symbols]; rd = CoefficientRules[Expand[den], symbols];
  If[rn === {} || AllTrue[Values[rn], PossibleZeroQ], Return[<|"Zero" -> True, "Degree" -> {0, 0}, "Max" -> {0, 0, 0}, "Height" -> 1, "Terms" -> 0|>]];
  scale = LCM @@ Join[Denominator /@ Values[rn], Denominator /@ Values[rd]];
  cn = Developer`ToPackedArray[scale Values[rn]]; cd = Developer`ToPackedArray[scale Values[rd]];
  <|"Zero" -> False,
    "NC" -> cn, "NE" -> Developer`ToPackedArray[Keys[rn]],
    "DC" -> cd, "DE" -> Developer`ToPackedArray[Keys[rd]],
    "Max" -> MapThread[Max, {Max /@ Transpose[Keys[rn]], Max /@ Transpose[Keys[rd]]}],
    "Degree" -> {Max[Total /@ Keys[rn]], Max[Total /@ Keys[rd]]},
    "Height" -> Max[Abs[Join[cn, cd]]], "Terms" -> Max[Length[rn], Length[rd]]|>];

familyCertCompileMatrix[matrix_List, symbols_List] := Map[familyCertCompile[#, symbols] &, matrix, {2}];

familyCertPowers[point_List, maxima_List, p_Integer] :=
  Table[PowerMod[point[[v]], k, p], {v, Length[point]}, {k, 0, maxima[[v]]}];

familyCertPolyValue[c_, e_, powers_, p_Integer] := Module[{m},
  m = Mod[powers[[1, e[[All, 1]] + 1]] powers[[2, e[[All, 2]] + 1]], p];
  m = Mod[m powers[[3, e[[All, 3]] + 1]], p];
  Mod[Mod[c, p] . m, p]];

familyCertValue[entry_Association, powers_, p_Integer] := Module[{n, d},
  If[entry["Zero"], Return[0]];
  d = familyCertPolyValue[entry["DC"], entry["DE"], powers, p];
  If[d === 0, Return[$Failed]];
  n = familyCertPolyValue[entry["NC"], entry["NE"], powers, p];
  Mod[n PowerMod[d, -1, p], p]];

familyCertDerivativeValue[entry_Association, v_Integer, powers_, p_Integer] := Module[
  {n, d, nv, dv, keepN, keepD, cN, eN, cD, eD},
  If[entry["Zero"], Return[0]];
  d = familyCertPolyValue[entry["DC"], entry["DE"], powers, p];
  If[d === 0, Return[$Failed]];
  n = familyCertPolyValue[entry["NC"], entry["NE"], powers, p];
  keepN = Flatten[Position[entry["NE"][[All, v]], _?Positive, {1}, Heads -> False]];
  keepD = Flatten[Position[entry["DE"][[All, v]], _?Positive, {1}, Heads -> False]];
  nv = If[keepN === {}, 0,
    cN = entry["NC"][[keepN]] entry["NE"][[keepN, v]]; eN = entry["NE"][[keepN]];
    eN[[All, v]] -= 1; familyCertPolyValue[cN, eN, powers, p]];
  dv = If[keepD === {}, 0,
    cD = entry["DC"][[keepD]] entry["DE"][[keepD, v]]; eD = entry["DE"][[keepD]];
    eD[[All, v]] -= 1; familyCertPolyValue[cD, eD, powers, p]];
  Mod[Mod[nv d - n dv, p] PowerMod[d, -2, p], p]];

familyCertMatrixValue[compiled_List, powers_, p_Integer] := Module[{m},
  m = Map[familyCertValue[#, powers, p] &, compiled, {2}];
  If[! FreeQ[m, $Failed], $Failed, m]];
familyCertMatrixDerivativeValue[compiled_List, v_Integer, powers_, p_Integer] := Module[{m},
  m = Map[familyCertDerivativeValue[#, v, powers, p] &, compiled, {2}];
  If[! FreeQ[m, $Failed], $Failed, m]];

(* {max numerator total degree, max denominator total degree, max exponents, height bits, max terms} *)
familyCertDegree[compiled_List] := Module[{entries = Select[Flatten[compiled], ! #["Zero"] &]},
  If[entries === {}, {0, 0, {0, 0, 0}, 0, 0},
    {Max[#["Degree"][[1]] & /@ entries], Max[#["Degree"][[2]] & /@ entries],
     MapThread[Max, #["Max"] & /@ entries], Max[Log2[N[#["Height"]]] & /@ entries], Max[#["Terms"] & /@ entries]}]];

(* letters: irreducible factors of the COMBINED denominators of the eps-form
   (Together first: an uncombined sum hides its poles) *)
familyCertLetters[epsilonForm_List, variables_List, regulator_Symbol] := Module[{factors},
  factors = DeleteDuplicates[Flatten[
    (First /@ Rest[FactorList[Denominator[Together[#]]]]) & /@
      Select[Flatten[epsilonForm], ! TrueQ[# === 0] &]]];
  factors = Select[factors, ! FreeQ[#, Alternatives @@ variables] &];
  DeleteDuplicates[factors, PossibleZeroQ[#1 - #2] || PossibleZeroQ[#1 + #2] &]];

familyCertRationalReconstruct[a_Integer, m_Integer] := Module[{bound = Floor[Sqrt[(m - 1)/2]], r0, r1, t0 = 0, t1 = 1, q},
  {r0, r1} = {m, Mod[a, m]};
  If[r1 === 0, Return[0]];
  While[r1 > bound, q = Quotient[r0, r1]; {r0, r1} = {r1, r0 - q r1}; {t0, t1} = {t1, t0 - q t1}];
  If[t1 === 0 || Abs[t1] > bound || ! CoprimeQ[r1, t1], $Failed, r1/t1]];

(* ---- degree algebra on {numerator degree, denominator degree} ---- *)
familyCertDegMul[a_, b_] := a + b;
familyCertDegDeriv[{n_, d_}] := {n + d - 1, 2 d};
familyCertDegAdd[terms_List] := With[{ds = terms[[All, 2]]},
  {Max[Table[terms[[i, 1]] + Total[ds] - ds[[i]], {i, Length[terms]}]], Total[ds]}];
(* an entry {n, d} in the source variables composed with a map of degree m
   (numerator and denominator of the map both <= m): a monomial of degree k
   becomes a rational function of degree <= {k m, k m} *)
familyCertDegCompose[{n_, d_}, m_] := {(n + d) m, (n + d) m};
(* n x n matrix product: n-term common-denominator sum of products *)
familyCertMatMul[a_, b_, n_] := familyCertDegAdd[ConstantArray[familyCertDegMul[a, b], n]];

(* per-identity numerator-degree bounds; a_ = {n, d} of the source in the
   variables it is evaluated in, map_ = degree of the chart map (0: none) *)
familyCertBounds[dS_, dSi_, dB_, dA_, dL_, n_Integer, map_Integer, dMapJac_] := Module[
  {one = {0, 0}, inv, gauge, flat, epsf, dlog, src, aChart, dSd, dBd, aC},
  inv = familyCertDegAdd[{familyCertMatMul[dS, dSi, n], one}];
  (* the chart connection: A_v d_x f + A_w d_x g with A composed with the map *)
  aChart = If[map > 0,
    familyCertDegAdd[{familyCertDegMul[familyCertDegCompose[dA, map], dMapJac],
      familyCertDegMul[familyCertDegCompose[dA, map], dMapJac]}], dA];
  dSd = familyCertDegDeriv[dS];
  gauge = familyCertDegAdd[{familyCertMatMul[familyCertMatMul[dSi, aChart, n], dS, n],
    familyCertMatMul[dSi, dSd, n], dB}];
  dBd = familyCertDegDeriv[dB];
  flat = familyCertDegAdd[{dBd, dBd, familyCertMatMul[dB, dB, n], familyCertMatMul[dB, dB, n]}];
  epsf = familyCertDegAdd[{dB + {1, 0}, dB + {1, 0}}];
  dlog = familyCertDegAdd[Join[{dB + {0, 1}}, ConstantArray[familyCertDegDeriv[dL] + {0, dL[[1]]}, Max[1, n]]]];
  (* source flatness in the source variables, then composed with the map *)
  aC = dA; src = familyCertDegAdd[{familyCertDegDeriv[aC], familyCertDegDeriv[aC],
    familyCertMatMul[aC, aC, n], familyCertMatMul[aC, aC, n]}];
  src = If[map > 0, familyCertDegCompose[src, map], src];
  <|"Inverse" -> inv[[1]], "Gauge" -> gauge[[1]], "Flatness" -> flat[[1]],
    "EpsFactored" -> epsf[[1]], "DLog" -> dlog[[1]], "SourceFlatness" -> src[[1]]|>];

(* one exact characteristic-zero evaluation of the matrix identities (guards
   the bad-characteristic term: a nonzero residual whose content every
   sampled prime divides would pass the modular test) *)
familyCertCharacteristicZeroPoint[s_, si_, b1_, b2_, av_, aw_, variables_, regulator_, chart_, sourceVariables_,
    letters_: {}, residues_: None] := Module[
  {size = 10^9, rules, rules2, S, Si, B1, B2, B1b, B2b, dB, dSx, dSy, A1, A2, map, jac, ok, eval, e1, e2, dlogOK = True, dl, n},
  eval[m_, r_] := Quiet[Check[Map[Together[# /. r] &, m, {2}], $Failed]];
  rules = Thread[Append[variables, regulator] -> RandomInteger[{3, size}, 3]/RandomInteger[{size, 10 size}, 3]];
  e1 = Last[Last[rules]]; e2 = e1 + 1/RandomInteger[{2, 10^6}];
  rules2 = ReplacePart[rules, -1 -> (regulator -> e2)];
  n = Length[s];
  {S, Si, B1, B2} = eval[#, rules] & /@ {s, si, b1, b2};
  {B1b, B2b} = eval[#, rules2] & /@ {b1, b2};
  dB = eval[D[b1, variables[[2]]] - D[b2, variables[[1]]], rules];
  dSx = eval[D[s, variables[[1]]], rules]; dSy = eval[D[s, variables[[2]]], rules];
  If[AssociationQ[chart],
    map = Thread[sourceVariables -> (Last /@ chart["Subst"] /. rules)];
    jac = Quiet[Check[Map[Together[# /. rules] &, chart["Jacobian"], {2}], $Failed]];
    A1 = eval[av, Join[map, {Last[rules]}]]; A2 = eval[aw, Join[map, {Last[rules]}]];
    If[MemberQ[{jac, A1, A2}, $Failed], Return[<|"OK" -> False, "Reason" -> "PointRejected"|>]];
    {A1, A2} = {A1 jac[[1, 1]] + A2 jac[[2, 1]], A1 jac[[1, 2]] + A2 jac[[2, 2]]},
    A1 = eval[av, rules]; A2 = eval[aw, rules]];
  If[MemberQ[{S, Si, B1, B2, B1b, B2b, dB, dSx, dSy, A1, A2}, $Failed] ||
      ! FreeQ[{S, Si, B1, B2, B1b, B2b, dB, dSx, dSy, A1, A2}, ComplexInfinity | Indeterminate | DirectedInfinity],
    Return[<|"OK" -> False, "Reason" -> "PointRejected"|>]];
  (* the dlog identity with the exactly reconstructed residues: a polynomial
     part whose integer content every sampled prime divides is invisible
     modulo those primes (Codex case 7, 2026-08-22) but not here *)
  If[letters =!= {} && ListQ[residues],
    dl = Quiet[Check[Table[{D[Log[L], variables[[1]]], D[Log[L], variables[[2]]]} /. rules, {L, letters}], $Failed]];
    If[dl === $Failed || ! FreeQ[dl, ComplexInfinity | Indeterminate | DirectedInfinity], Return[<|"OK" -> False, "Reason" -> "PointRejected"|>]];
    dlogOK = AllTrue[Flatten[{B1/e1 - Sum[residues[[a]] dl[[a, 1]], {a, Length[letters]}],
      B2/e1 - Sum[residues[[a]] dl[[a, 2]], {a, Length[letters]}]}], TrueQ[Together[#] == 0] &]];
  ok = AllTrue[Flatten[{S . Si - IdentityMatrix[n], Si . S - IdentityMatrix[n],
    Si . A1 . S - Si . dSx - B1, Si . A2 . S - Si . dSy - B2,
    dB + B1 . B2 - B2 . B1, e2 B1 - e1 B1b, e2 B2 - e1 B2b}], TrueQ[# == 0] &];
  <|"OK" -> ok && dlogOK, "MatrixIdentities" -> ok, "DLog" -> dlogOK, "Point" -> rules|>];

(* ---- the certificate ---- *)

Options[familyCertificateModular] = {"Points" -> 12, "Primes" -> 3, "ValidationPoints" -> 4,
  "MaxPrimes" -> 60,   (* residue reconstruction adds primes (6 at a time) until the CRT modulus suffices;
                          CF231's residues reach 101 digits (2026-08-22), i.e. ~30 primes of 24 bits *)
  "CharacteristicZeroGuard" -> True, "Seed" -> Automatic, "Verbose" -> False};

(* The certificate is written for a TWO-variable family: it samples
   {variables[[1]], variables[[2]], regulator} as one triple, differentiates
   in both variables and reads one flatness identity.  The signature says
   so.  A three-variable list used to match variables_List and was then
   sampled as a pair, i.e. certified the wrong system; with this pattern
   the call does not evaluate and the caller reports
   "ModularCertificateFailed" (generality pass 2026-08-23). *)
familyCertificateModular[{b1_, b2_}, s_, si_,
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    {av_, aw_}, sourceVariables : {_Symbol, _Symbol}, chart_,
    OptionsPattern[]] := Module[
  {symbols = Append[variables, regulator], srcSymbols = Append[sourceVariables, regulator],
   cS, cSi, cB1, cB2, cAv, cAw, cF, cG, letters, cL, n = Length[s], verbose, log, t0 = AbsoluteTime[],
   degS, degSi, degB, degA, degL, bounds, maxima, srcMaxima, primes = {}, trials = {},
   pointsPerPrime, validationPoints, checks, residues = <||>, chartQ = AssociationQ[chart],
   f, g, compileSeconds, trouble = <||>, mapDegree = 0, mapJac = {0, 0}, seed, bad = False,
   residueRecon = Missing["NotAttempted"], residueVerified = Missing["NotAttempted"],
   charZero = Missing["NotRun"], zeroForm, termsMax, pLow = 2^23, pHigh = 2^24, primeTries = 0,
   recordPoints = {}},
  verbose = TrueQ[OptionValue["Verbose"]];
  log[args___] := If[verbose, Print["[certificate] ", args]];
  pointsPerPrime = OptionValue["Points"]; validationPoints = OptionValue["ValidationPoints"];
  If[! (IntegerQ[pointsPerPrime] && pointsPerPrime > 0 && IntegerQ[validationPoints] && validationPoints > 0 &&
      IntegerQ[OptionValue["Primes"]] && OptionValue["Primes"] > 0),
    Return[<|"Status" -> "InvalidCounts"|>]];
  seed = If[OptionValue["Seed"] === Automatic, RandomInteger[{1, 2^31}], OptionValue["Seed"]];
  SeedRandom[seed];
  (* --- compile (Together inside) --- *)
  compileSeconds = First[AbsoluteTiming[
    cS = familyCertCompileMatrix[s, symbols]; cSi = familyCertCompileMatrix[si, symbols];
    cB1 = familyCertCompileMatrix[b1, symbols]; cB2 = familyCertCompileMatrix[b2, symbols];
    cAv = familyCertCompileMatrix[av, srcSymbols]; cAw = familyCertCompileMatrix[aw, srcSymbols];
    If[chartQ,
      {f, g} = Last /@ chart["Subst"];
      cF = familyCertCompile[f, symbols]; cG = familyCertCompile[g, symbols]];
    letters = familyCertLetters[{b1, b2}, variables, regulator];
    cL = familyCertCompile[#, symbols] & /@ letters]];
  If[! FreeQ[{cS, cSi, cB1, cB2, cAv, cAw, cL, If[chartQ, {cF, cG}, {}]}, $Failed],
    Return[<|"Status" -> "NotRational"|>]];
  zeroForm = AllTrue[Flatten[Join[cB1, cB2]], #["Zero"] &];
  log["compiled ", n, "x", n, " matrices and ", Length[letters], " letters in ", Round[compileSeconds, 0.1], " s"];
  (* --- degrees, bounds, power tables --- *)
  {degS, degSi, degB, degA} = familyCertDegree /@ {cS, cSi, Join[cB1, cB2], Join[cAv, cAw]};
  degL = If[letters === {}, {0, 0, {0, 0, 0}, 0, 0}, familyCertDegree[{cL}]];
  If[chartQ, mapDegree = Max[cF["Degree"], cG["Degree"], 1];
    mapJac = familyCertDegDeriv[{mapDegree, mapDegree}]];
  bounds = familyCertBounds[degS[[;; 2]], degSi[[;; 2]], degB[[;; 2]], degA[[;; 2]], degL[[;; 2]], n, mapDegree, mapJac];
  maxima = MapThread[Max, {degS[[3]], degSi[[3]], degB[[3]], degL[[3]],
    If[chartQ, MapThread[Max, {cF["Max"], cG["Max"]}], degA[[3]]]}] + 1;
  srcMaxima = degA[[3]] + 1;
  (* arithmetic safety: p^2 * terms < 2^62 for packed dot products *)
  termsMax = Max[degS[[5]], degSi[[5]], degB[[5]], degA[[5]], degL[[5]], 1];
  While[pHigh^2 termsMax >= 2^62 && pHigh > 2^16, pHigh = pHigh/2; pLow = pLow/2];
  (* --- primes (distinct), trials --- *)
  checks = <|"TransformationInverse" -> False, "GaugeIdentity" -> False, "Flatness" -> False,
    "EpsFactored" -> False, "DLog" -> False, "ConstantResidues" -> False, "SourceFlatness" -> False|>;
  Module[{perPrime = <||>, allOK = <||>, target = OptionValue["Primes"], runTrials},
    (* each trial: a distinct prime; rank-deficient dlog design -> discard the prime *)
    runTrials[dlogOnly_: False] := While[Length[trials] < target && primeTries < 4 target,
      primeTries++;
      Module[{p, done = 0, tries = 0, pt, pw, spw, S, Si, B1, B2, dSx, dSy, dB, A1, A2, Av, Aw, v0, w0, jac,
          e2, B1b, B2b, ok, idOK = <|"TransformationInverse" -> True, "GaugeIdentity" -> True, "Flatness" -> True,
            "EpsFactored" -> True, "SourceFlatness" -> True|>,
          trainRows = {}, trainRhs = {}, valRows = {}, valRhs = {}, K = None, rank = 0, phase = "train",
          lval, lvx, lvy, pts = {}, trained = 0, validated = 0, dlogOK, rankOK},
        p = RandomPrime[{pLow, pHigh}];
        If[MemberQ[primes, p], Continue[]];
        ok[m_] := AllTrue[Flatten[Mod[m, p]], # === 0 &];
        While[validated < validationPoints && tries < 8 (pointsPerPrime + validationPoints),
          tries++;
          pt = RandomInteger[{2, p - 2}, 3];
          pw = familyCertPowers[pt, maxima, p];
          {B1, B2} = familyCertMatrixValue[#, pw, p] & /@ {cB1, cB2};
          If[MemberQ[{B1, B2}, $Failed], Continue[]];
          If[dlogOnly,
            (* residue-reconstruction trial: only the dlog rows *)
            If[letters =!= {},
              lval = familyCertValue[#, pw, p] & /@ cL;
              lvx = familyCertDerivativeValue[#, 1, pw, p] & /@ cL; lvy = familyCertDerivativeValue[#, 2, pw, p] & /@ cL;
              If[MemberQ[Flatten[{lval, lvx, lvy}], $Failed] || MemberQ[lval, 0], Continue[]]];
            AppendTo[pts, {pt, None}]; done++;
            If[letters =!= {},
              Module[{inv = PowerMod[pt[[3]], -1, p], linv = PowerMod[#, -1, p] & /@ lval, rx, ry},
                rx = Mod[lvx linv, p]; ry = Mod[lvy linv, p];
                If[phase === "train",
                  trainRows = Join[trainRows, {rx, ry}]; trainRhs = Join[trainRhs, {Mod[inv Flatten[B1], p], Mod[inv Flatten[B2], p]}];
                  trained++;
                  If[Length[trainRows] >= Length[letters] && MatrixRank[trainRows, Modulus -> p] === Length[letters],
                    K = Quiet[Check[LinearSolve[trainRows, trainRhs, Modulus -> p], $Failed]];
                    rank = Length[letters];
                    If[K === $Failed || ! AllTrue[Flatten[Mod[trainRows . K - trainRhs, p]], # === 0 &], K = "Inconsistent"];
                    phase = "validate"],
                  valRows = Join[valRows, {rx, ry}]; valRhs = Join[valRhs, {Mod[inv Flatten[B1], p], Mod[inv Flatten[B2], p]}];
                  validated++]],
              validated++];
            If[letters =!= {} && phase === "train" && trained >= 2 pointsPerPrime, Break[]];
            Continue[]];
          S = familyCertMatrixValue[cS, pw, p]; Si = familyCertMatrixValue[cSi, pw, p];
          dSx = familyCertMatrixDerivativeValue[cS, 1, pw, p]; dSy = familyCertMatrixDerivativeValue[cS, 2, pw, p];
          dB = Module[{a = familyCertMatrixDerivativeValue[cB1, 2, pw, p], b = familyCertMatrixDerivativeValue[cB2, 1, pw, p]},
            If[a === $Failed || b === $Failed, $Failed, Mod[a - b, p]]];
          If[MemberQ[{S, Si, dSx, dSy, dB}, $Failed], Continue[]];
          If[chartQ,
            v0 = familyCertValue[cF, pw, p]; w0 = familyCertValue[cG, pw, p];
            jac = {{familyCertDerivativeValue[cF, 1, pw, p], familyCertDerivativeValue[cF, 2, pw, p]},
                   {familyCertDerivativeValue[cG, 1, pw, p], familyCertDerivativeValue[cG, 2, pw, p]}};
            If[MemberQ[Flatten[{v0, w0, jac}], $Failed], Continue[]];
            spw = familyCertPowers[{v0, w0, pt[[3]]}, srcMaxima, p];
            Av = familyCertMatrixValue[cAv, spw, p]; Aw = familyCertMatrixValue[cAw, spw, p];
            If[MemberQ[{Av, Aw}, $Failed], Continue[]];
            A1 = Mod[Av jac[[1, 1]] + Aw jac[[2, 1]], p]; A2 = Mod[Av jac[[1, 2]] + Aw jac[[2, 2]], p],
            spw = pw; Av = Aw = None;
            A1 = familyCertMatrixValue[cAv, pw, p]; A2 = familyCertMatrixValue[cAw, pw, p];
            If[MemberQ[{A1, A2}, $Failed], Continue[]]];
          (* second regulator value, distinct *)
          e2 = RandomInteger[{2, p - 2}]; While[e2 === pt[[3]], e2 = RandomInteger[{2, p - 2}]];
          B1b = familyCertMatrixValue[cB1, familyCertPowers[ReplacePart[pt, 3 -> e2], maxima, p], p];
          B2b = familyCertMatrixValue[cB2, familyCertPowers[ReplacePart[pt, 3 -> e2], maxima, p], p];
          If[B1b === $Failed || B2b === $Failed, Continue[]];
          Module[{dAvw = familyCertMatrixDerivativeValue[cAv, 2, spw, p], dAwv = familyCertMatrixDerivativeValue[cAw, 1, spw, p], Avs, Aws},
            If[dAvw === $Failed || dAwv === $Failed, Continue[]];
            {Avs, Aws} = If[chartQ, {Av, Aw}, {A1, A2}];
            If[! ok[dAvw - dAwv + Avs . Aws - Aws . Avs], idOK["SourceFlatness"] = False]];
          (* dlog rows need every letter nonzero at the point *)
          If[letters =!= {},
            lval = familyCertValue[#, pw, p] & /@ cL;
            lvx = familyCertDerivativeValue[#, 1, pw, p] & /@ cL; lvy = familyCertDerivativeValue[#, 2, pw, p] & /@ cL;
            If[MemberQ[Flatten[{lval, lvx, lvy}], $Failed] || MemberQ[lval, 0], Continue[]]];
          (* the point is accepted: identities *)
          AppendTo[pts, {pt, e2}];
          If[! ok[S . Si - IdentityMatrix[n]] || ! ok[Si . S - IdentityMatrix[n]], idOK["TransformationInverse"] = False];
          If[! ok[Si . Mod[A1 . S, p] - Si . dSx - B1] || ! ok[Si . Mod[A2 . S, p] - Si . dSy - B2], idOK["GaugeIdentity"] = False];
          If[! ok[dB + B1 . B2 - B2 . B1], idOK["Flatness"] = False];
          If[! ok[e2 B1 - pt[[3]] B1b] || ! ok[e2 B2 - pt[[3]] B2b], idOK["EpsFactored"] = False];
          done++;
          (* dlog: training rows until full rank, then fresh validation rows *)
          If[letters =!= {},
            Module[{inv = PowerMod[pt[[3]], -1, p], linv = PowerMod[#, -1, p] & /@ lval, rx, ry},
              rx = Mod[lvx linv, p]; ry = Mod[lvy linv, p];
              If[phase === "train",
                trainRows = Join[trainRows, {rx, ry}]; trainRhs = Join[trainRhs, {Mod[inv Flatten[B1], p], Mod[inv Flatten[B2], p]}];
                trained++;
                If[Length[trainRows] >= Length[letters] && MatrixRank[trainRows, Modulus -> p] === Length[letters],
                  K = Quiet[Check[LinearSolve[trainRows, trainRhs, Modulus -> p], $Failed]];
                  rank = Length[letters];
                  If[K === $Failed || ! AllTrue[Flatten[Mod[trainRows . K - trainRhs, p]], # === 0 &],
                    K = "Inconsistent"];
                  phase = "validate"],
                valRows = Join[valRows, {rx, ry}]; valRhs = Join[valRhs, {Mod[inv Flatten[B1], p], Mod[inv Flatten[B2], p]}];
                validated++]],
            (* no letters: the form must be zero; count every point as validation *)
            validated++];
          If[letters =!= {} && phase === "train" && trained >= 2 pointsPerPrime,
            (* the design never reached full rank: the prime is discarded *)
            Break[]]];
        rankOK = letters === {} || (phase === "validate" && rank === Length[letters]);
        If[! rankOK, trouble["DlogRankDeficient" <> ToString[p]] = <|"Prime" -> p, "Trained" -> trained|>; Continue[]];
        If[validated < validationPoints, trouble["TooFewPoints" <> ToString[p]] = <|"Prime" -> p, "Validated" -> validated|>; Continue[]];
        dlogOK = Which[
          letters === {}, zeroForm,
          K === "Inconsistent" || K === None, False,
          True, AllTrue[Flatten[Mod[valRows . K - valRhs, p]], # === 0 &]];
        AppendTo[primes, p];
        AppendTo[trials, <|"Prime" -> p, "Points" -> done, "TrainingPoints" -> trained, "ValidationPoints" -> validated,
          "DlogRank" -> rank, "Letters" -> Length[letters], "DlogConsistent" -> dlogOK,
          "Identities" -> If[dlogOnly, Missing["DlogOnlyTrial"], idOK], "DlogOnly" -> dlogOnly,
          "PointsAndSecondRegulator" -> pts|>];
        perPrime[p] = <|"K" -> If[MatrixQ[K], K, None], "DlogOK" -> dlogOK, "Identities" -> idOK|>]];
    runTrials[];
    If[Length[trials] < OptionValue["Primes"],
      trouble["NotEnoughPrimes"] = Length[trials]; bad = True];
    (* verdicts: every trial must pass *)
    If[! bad,
      Do[checks[k] = AllTrue[Select[trials, ! TrueQ[#["DlogOnly"]] &], TrueQ[#["Identities"][k]] &], {k, {"TransformationInverse", "GaugeIdentity", "Flatness", "EpsFactored", "SourceFlatness"}}];
      checks["DLog"] = AllTrue[trials, TrueQ[#["DlogConsistent"]] &];
      (* residues: CRT over the primes, rational reconstruction, verification at every prime (sticky) *)
      If[letters === {},
        checks["ConstantResidues"] = zeroForm; residueRecon = {}; residueVerified = zeroForm,
        If[checks["DLog"] && AllTrue[primes, MatrixQ[perPrime[#]["K"]] &],
          Module[{reconstruct, rec = $Failed, verified = False},
            reconstruct[] := Module[{ks = perPrime[#]["K"] & /@ primes, modulus = Times @@ primes, crt, r},
              crt = MapThread[ChineseRemainder[{##}, primes] &, ks, 2];
              r = Map[familyCertRationalReconstruct[#, modulus] &, crt, {2}];
              If[FreeQ[r, $Failed],
                {r, AllTrue[Range[Length[primes]], Function[i,
                  Mod[Map[Mod[Numerator[#] PowerMod[Denominator[#], -1, primes[[i]]], primes[[i]]] &, r, {2}] - ks[[i]], primes[[i]]] ===
                    ConstantArray[0, Dimensions[r]]]]},
                {$Failed, False}]];
            {rec, verified} = reconstruct[];
            (* residues taller than the CRT modulus allows: add primes (the
               new trials also test every identity again) *)
            While[! (MatrixQ[rec] && verified) && Length[primes] < OptionValue["MaxPrimes"],
              target = Min[OptionValue["MaxPrimes"], Length[primes] + 6];
              log["residue reconstruction needs more primes: ", Length[primes], " -> ", target];
              Module[{before = Length[primes]}, primeTries = 0; runTrials[True];
                If[Length[primes] === before, trouble["NoNewPrimes"] = before; Break[]]];
              If[! AllTrue[trials, TrueQ[#["DlogConsistent"]] &], Break[]];
              If[! AllTrue[primes, MatrixQ[perPrime[#]["K"]] &], Break[]];
              {rec, verified} = reconstruct[]];
            (* the verdicts must hold at every prime used (matrix identities
               on the full trials, the dlog statement on all) *)
            Do[checks[k] = AllTrue[Select[trials, ! TrueQ[#["DlogOnly"]] &], TrueQ[#["Identities"][k]] &], {k, {"TransformationInverse", "GaugeIdentity", "Flatness", "EpsFactored", "SourceFlatness"}}];
            checks["DLog"] = AllTrue[trials, TrueQ[#["DlogConsistent"]] &];
            If[MatrixQ[rec] && verified,
              residueRecon = Table[Partition[rec[[a]], n], {a, Length[letters]}];
              residueVerified = True; checks["ConstantResidues"] = checks["DLog"];
              trouble["ResidueHeightDigits"] = Max[IntegerLength /@ Abs[Cases[Flatten[{Numerator[Flatten[rec]], Denominator[Flatten[rec]]}], _Integer]]],
              residueRecon = Missing["ReconstructionFailed"]; residueVerified = False;
              trouble["ResidueHeightExceedsModulus"] = Length[primes];
              checks["ConstantResidues"] = False]],
          checks["ConstantResidues"] = False]]]];
  (* characteristic-zero guard point for the matrix identities *)
  If[! bad && TrueQ[OptionValue["CharacteristicZeroGuard"]],
    charZero = familyCertCharacteristicZeroPoint[s, si, b1, b2, av, aw, variables, regulator, chart, sourceVariables,
      letters, If[ListQ[residueRecon], residueRecon, None]];
    If[! TrueQ[charZero["MatrixIdentities"]],
      checks["TransformationInverse"] = checks["GaugeIdentity"] = checks["Flatness"] = checks["EpsFactored"] = False;
      trouble["CharacteristicZeroGuard"] = Lookup[charZero, "Reason", "MatrixIdentitiesFailed"]];
    If[! TrueQ[charZero["DLog"]],
      checks["DLog"] = checks["ConstantResidues"] = False;
      trouble["CharacteristicZeroGuardDLog"] = "DLogIdentityFailedAtRationalPoint"];
    (* a zero form with an empty alphabet: nothing to test beyond the matrix identities *)
    If[letters =!= {} && ! ListQ[residueRecon] && checks["DLog"],
      checks["DLog"] = checks["ConstantResidues"] = False;
      trouble["CharacteristicZeroGuardDLog"] = "NoReconstructedResidues"]];
  (* --- error terms --- *)
  With[{pMin = If[primes === {}, pLow, Min[primes]], nPrimes = Length[Select[trials, ! TrueQ[#["DlogOnly"]] &]],
      nPrimesDlog = Length[trials],
      vPts = If[trials === {}, 0, Min[#["ValidationPoints"] & /@ trials]],
      iPts = If[trials === {}, 0, Min[#["Points"] & /@ Select[trials, ! TrueQ[#["DlogOnly"]] &]]]},
    Join[checks, <|
      "Letters" -> letters, "LettersEpsFree" -> FreeQ[letters, regulator],
      "Residues" -> residueRecon, "ResiduesVerifiedAtAllPrimes" -> residueVerified,
      "DegreeBounds" -> bounds, "DegreeBound" -> Max[Values[bounds]],
      "HeightBits" -> Max[degS[[4]], degSi[[4]], degB[[4]], degA[[4]]],
      "Primes" -> primes, "PrimeRange" -> {pLow, pHigh}, "Seed" -> seed, "Trials" -> trials,
      "PointsPerPrime" -> pointsPerPrime, "PointsDone" -> (KeyTake[#, {"Points", "TrainingPoints", "ValidationPoints", "DlogRank", "Letters"}] & /@ trials),
      (* ordinary identities: every accepted point tests a fixed polynomial *)
      "ErrorBoundIdentities" -> If[nPrimes === 0, 1, Min[1, N[8 n^2 (Max[bounds["Inverse"], bounds["Gauge"], bounds["Flatness"], bounds["EpsFactored"], bounds["SourceFlatness"]]/pMin)^(iPts nPrimes), 3]]],
      (* dlog: only the validation points count *)
      "ErrorBoundDLog" -> If[nPrimes === 0, 1, Min[1, N[2 n^2 (bounds["DLog"]/pMin)^(vPts nPrimesDlog), 3]]],
      "BadCharacteristicGuard" -> If[TrueQ[OptionValue["CharacteristicZeroGuard"]], "OneExactRationalPoint", "None"],
      "CharacteristicZeroPoint" -> If[AssociationQ[charZero], Lookup[charZero, "Point", Missing[]], Missing[]],
      "ErrorBoundGoodCharacteristic" -> If[nPrimes === 0, 1, Min[1, N[8 n^2 (Max[Values[bounds]]/pMin)^(iPts nPrimes) + 2 n^2 (bounds["DLog"]/pMin)^(vPts nPrimesDlog), 3]]],
      "Probabilistic" -> True,
      "CompileSeconds" -> compileSeconds, "Seconds" -> AbsoluteTime[] - t0,
      "Trouble" -> trouble|>]]
];
