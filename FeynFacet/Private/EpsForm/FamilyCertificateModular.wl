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
  , familyCertMQFailure, familyCertMQModRational, familyCertMQSquareRoot,
  familyCertMQPrepare, familyCertMQIndependentColumns,
  familyCertMQAuthenticateRegulatorRootFrames,
  familyCertMQPivotSignature, familyCertMQSelectModalPivotTrials,
  familyCertMQTrial, familyCertMQReconstructResidues,
  familyCertMQValidateResiduesAtTrial,
  familyCertificateMultiquadratic
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

(* one implementation (Core/ModularArithmetic.wl, overhaul 2026-09-02):
   Wang reconstruction with the symmetric bound Floor[Sqrt[(m-1)/2]] *)
familyCertRationalReconstruct[a_Integer, m_Integer] := modularRationalReconstruct[a, m];

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

(* ------------------------------------------------------------------ *)
(* Whole-family certificate in a declared multiquadratic source frame. *)
(* ------------------------------------------------------------------ *)

(* This is deliberately a verifier, not a second solver.  The expensive
   algebraic objects are converted once to rational expressions in formal
   generators rho_i.  At a split finite-field point every one of the 2^r
   embeddings rho_i -> +/-sqrt(delta_i) is then evaluated.  Matrix products
   are formed only after evaluation.  Thus the certificate proves the same
   identities as familyCertificateModular, but never asks Together to
   multiply full matrices containing radicals. *)

familyCertMQFailure[status_String, detail_: <||>] := Join[
  <|"Status" -> status, "Probabilistic" -> True,
    "CoefficientField" -> "Multiquadratic"|>,
  If[AssociationQ[detail], detail, <|"Detail" -> detail|>]];

(* Authenticate every graded root frame carried by regulator
   factorization before adding its generators to the certificate field.
   Recomputing the evidence catches altered counts, branches, ordering,
   numeric classes or fingerprints.  The union is then revalidated as one
   independent square-class basis; duplicate generators shared with the
   chart frame are merged by their exact root square. *)
familyCertMQAuthenticateRegulatorRootFrames[baseRoots_List, frames_List,
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    rankLimit_Integer] := Module[
  {required, frame, recomputed, authenticated = {}, combined, merged, stable},
  required = {"Schema", "Status", "RootCount", "GradeCount",
    "MaximumRank", "RootFingerprints", "OrderingFingerprint",
    "NumericRootIndices", "NumericRootSquares", "FrameFingerprint"};
  Do[
    frame = frames[[frameIndex]];
    If[! AssociationQ[frame] ||
        Lookup[frame, "Schema", None] =!=
          "FamilyRegulatorGradedRootFrameV1" ||
        ! ListQ[Lookup[frame, "Roots", $Failed]],
      Return[familyCertMQFailure["RegulatorRootFrameMetadataInvalid",
        <|"FrameIndex" -> frameIndex|>], Module]];
    recomputed = familyRegulatorGradedFrameEvidence[
      frame["Roots"], variables, regulator];
    If[Lookup[recomputed, "Status", None] =!= "StableRootFrame" ||
        KeyTake[frame, required] =!= KeyTake[recomputed, required],
      Return[familyCertMQFailure["RegulatorRootFrameAuthenticationFailed",
        <|"FrameIndex" -> frameIndex,
          "Expected" -> KeyDrop[recomputed, "Roots"],
          "Observed" -> KeyDrop[frame, "Roots"]|>], Module]];
    AppendTo[authenticated, recomputed],
    {frameIndex, Length[frames]}];
  combined = Join[baseRoots, Flatten[Lookup[authenticated, "Roots", {}], 1]];
  merged = Fold[Function[{kept, root},
      If[AnyTrue[kept, TrueQ[Quiet[Together[
            #1["RootSquare"] - root["RootSquare"]]] === 0] &],
        kept, Append[kept, KeyTake[root, {"Root", "RootSquare"}]]]],
    {}, combined];
  If[Length[merged] > rankLimit,
    Return[familyCertMQFailure["RootRankTooLarge",
      <|"RootCount" -> Length[merged], "RootRankLimit" -> rankLimit,
        "ProducerMaximumRank" -> $familyRegulatorMaximumGradedRank|>]]];
  stable = blockEquationDeferredRootFrame[merged, variables, regulator];
  If[Lookup[stable, "Status", None] =!= "StableRootOrder",
    Return[familyCertMQFailure[
      Lookup[stable, "Status", "InvalidCombinedRootFrame"],
      <|"RootFrame" -> stable|>]]];
  <|"Status" -> "AuthenticatedRegulatorRootFrames",
    "Roots" -> stable["Roots"],
    "RootCount" -> Length[stable["Roots"]],
    "GradeCount" -> 2^Length[stable["Roots"]],
    "RootFingerprints" -> stable["RootFingerprints"],
    "OrderingFingerprint" -> stable["OrderingFingerprint"],
    "EvidenceCount" -> Length[authenticated],
    "EvidenceFingerprints" -> Lookup[authenticated, "FrameFingerprint", {}],
    "RootRankLimit" -> rankLimit|>
];
familyCertMQAuthenticateRegulatorRootFrames[___] :=
  familyCertMQFailure["RegulatorRootFrameMetadataInvalid"];

familyCertMQModRational[value_, prime_Integer] := Module[{q, numerator, denominator},
  q = Quiet[Check[Together[value], $Failed]];
  If[q === $Failed || ! MatchQ[q, _Integer | _Rational], Return[$Failed]];
  numerator = Mod[Numerator[q], prime];
  denominator = Mod[Denominator[q], prime];
  If[denominator === 0, $Failed,
    Mod[numerator PowerMod[denominator, -1, prime], prime]]
];

(* The certificate samples primes p == 3 mod 4, so a quadratic-residue
   square root is one modular exponentiation.  Zero is excluded: otherwise
   two sign embeddings coalesce and the point does not test every grade. *)
(* one implementation (Core/ModularArithmetic.wl): a zero radicand was
   refused here and still is; every odd prime is now admissible *)
familyCertMQSquareRoot[value_Integer, prime_Integer] :=
  If[Mod[value, prime] === 0, $Failed, modularSquareRoot[value, prime]];

(* Prepare all scalar expressions once.  The root frame is the same
   canonical, square-class-independent frame used by the deferred equation
   and direct strip solver.  Nested radicals are admitted only after the
   shared exact denester rewrites them in that frame; an extra numeric square
   class is not silently synthesized and is therefore an undeclared root. *)
familyCertMQPrepare[objects_Association, roots_List,
    variables : {_Symbol, _Symbol}, regulator_Symbol, rankLimit_Integer] := Module[
  {frame, orderedRoots, census, denested, canonical, rootSymbols, polynomialized,
   surviving, numericClasses, numericClassIndices, undeclaredNumericClasses,
   rootImage, normalObjects, canonicalObjects,
   polynomializedObjects, polynomializeEntry, vectorKeys,
   compiledObjects, compileEntry, evaluationVariables, compiledLeaves,
   maximumExponents},
  If[rankLimit < 0 || Length[roots] > rankLimit,
    Return[familyCertMQFailure["RootRankTooLarge",
      <|"RootCount" -> Length[roots], "RootRankLimit" -> rankLimit|>]]];
  frame = blockEquationDeferredRootFrame[roots, variables, regulator];
  If[Lookup[frame, "Status", None] =!= "StableRootOrder",
    Return[familyCertMQFailure[Lookup[frame, "Status", "InvalidRootFrame"],
      <|"RootFrame" -> frame|>]]];
  orderedRoots = frame["Roots"];
  (* SparseArray is atomic to ReplaceAll.  Normalize only those containers;
     otherwise a radical stored in a sparse matrix can be seen by the census
     but skipped by the branch substitution. *)
  normalObjects = Map[Replace[#, sparse_SparseArray :> Normal[sparse],
      {0, Infinity}] &, objects];
  If[AnyTrue[Lookup[orderedRoots, "RootSquare", {}], ! FreeQ[#, regulator] &],
    Return[familyCertMQFailure["RegulatorDependentRootSquare"]]];
  census = transportChartRootIndices[Values[normalObjects], orderedRoots];
  If[! AssociationQ[census], Return[familyCertMQFailure["RootCensusFailed"]]];
  If[Lookup[census, "UnclassifiedRadicalBases", {}] =!= {},
    Return[familyCertMQFailure["UndeclaredRadicals",
      <|"RadicalBases" -> census["UnclassifiedRadicalBases"]|>]]];
  numericClasses = Lookup[census, "NumericRadicalClasses", {}];
  numericClassIndices = Table[FirstCase[
      Subsets[Range[Length[orderedRoots]]],
      subset_ /; TrueQ[multiquadraticStripSquareClassSquareQ[
        Together[numericClass/Times @@ Lookup[
          orderedRoots[[subset]], "RootSquare", {}]]]] :> subset,
      None],
    {numericClass, numericClasses}];
  undeclaredNumericClasses = Pick[numericClasses,
    (#1 === None & /@ numericClassIndices)];
  If[undeclaredNumericClasses =!= {},
    Return[familyCertMQFailure["UndeclaredNumericRootClasses",
      <|"SquareClasses" -> undeclaredNumericClasses,
        "DeclaredRootSquares" -> Lookup[orderedRoots, "RootSquare", {}]|>]]];
  denested = Lookup[census, "DenestedRadicalBases", <||>];
  canonical = If[denested === <||>,
    <|"Status" -> "OK", "Expression" -> Values[normalObjects],
      "Rewrites" -> <||>, "Rewritten" -> 0|>,
    transportChartCanonicalizeDenestedRadicals[
      Values[normalObjects], orderedRoots, variables, denested]];
  If[Lookup[canonical, "Status", None] =!= "OK",
    Return[familyCertMQFailure["RadicalDenestingFailed",
      <|"Denesting" -> canonical|>]]];
  rootSymbols = Table[Unique["FeynFacet`Private`familyCertMQRoot"],
    {Length[orderedRoots]}];
  (* Apply all root substitutions in one traversal.  Apart from avoiding r
     separate walks, this is stable when a previous certificate in the same
     kernel has already evaluated another set of Module-local root symbols. *)
  rootImage[base_] := rootImage[base] = Module[{scale, index},
    index = SelectFirst[Range[Length[orderedRoots]],
      transportChartRootBranchScale[base,
        orderedRoots[[#]]["RootSquare"]] =!= None &, None];
    If[index === None, None,
      scale = transportChartRootBranchScale[base,
        orderedRoots[[index]]["RootSquare"]];
      scale rootSymbols[[index]]]];
  canonicalObjects = AssociationThread[Keys[normalObjects],
    canonical["Expression"]];
  (* Large symbolic entries must not become DownValue keys.  On CF259 the
     structural hashing and retained keys inflated a 471 MB artifact to more
     than 10 GB before the first prime trial.  Atomic entries cover the common
     repeated zero/constant case without a cache. *)
  polynomializeEntry[entry_?AtomQ] := entry;
  polynomializeEntry[entry_] := Module[{direct},
    direct = entry /.
        Power[base_, exponent_Rational /; Denominator[exponent] === 2] :>
          With[{image = rootImage[base]},
            If[image === None, Power[base, exponent],
              image^(2 exponent)]];
    direct];
  vectorKeys = {"Letters", "LetterX", "LetterY"};
  polynomializedObjects = AssociationMap[Function[key,
      If[MemberQ[vectorKeys, key],
        Map[polynomializeEntry, canonicalObjects[key], {1}],
        Map[polynomializeEntry, canonicalObjects[key], {2}]]],
    Keys[canonicalObjects]];
  polynomialized = Values[polynomializedObjects];
  surviving = transportChartRadicalBases[polynomialized];
  If[surviving =!= {},
    Return[familyCertMQFailure["UndeclaredRadicalsAfterDenesting",
      <|"RadicalBases" -> surviving,
        "DeclaredRootSquares" -> Lookup[orderedRoots, "RootSquare", {}],
        "DenestedRadicalBases" -> Keys[denested],
        "PerObjectRadicals" -> Select[
          Map[transportChartRadicalBases,
            polynomializedObjects], # =!= {} &],
        "SurvivingPowers" -> Take[Cases[polynomialized,
          Power[_, exponent_Rational /; Denominator[exponent] === 2],
          {0, Infinity}, Heads -> True], UpTo[6]]|>]]];
  (* Production trials consume an exact polynomial plan, never the symbolic
     expressions themselves.  The same packed evaluator already used by the
     multiquadratic strip screens reduces exact coefficients once per prime
     and then evaluates every point and sign sheet with machine-integer power
     tables.  Keep Letters only as a cardinality marker; their logarithmic
     derivatives are the compiled LetterX/LetterY matrices. *)
  evaluationVariables = Join[variables, {regulator}, rootSymbols];
  compileEntry[0] := 0;
  compileEntry[entry_] :=
    multiquadraticStripScreenCompileScalarExact[
      entry, {}, {}, evaluationVariables];
  compiledObjects = AssociationMap[Function[key,
      If[key === "Letters", canonicalObjects[key],
        Map[compileEntry, polynomializedObjects[key], {2}]]],
    Keys[polynomializedObjects]];
  If[! FreeQ[KeyDrop[compiledObjects, "Letters"], $Failed],
    Return[familyCertMQFailure["CompiledEvaluatorConstructionFailed"]]];
  compiledLeaves = Cases[KeyDrop[compiledObjects, "Letters"],
    association_Association /; KeyExistsQ[association, "Numerator"] :>
      association, {0, Infinity}];
  maximumExponents = If[compiledLeaves === {},
    ConstantArray[0, Length[evaluationVariables]],
    Max /@ Transpose[Lookup[compiledLeaves, "MaximumExponents"]]];
  <|"Status" -> "PreparedMultiquadraticCertificate",
    "Objects" -> compiledObjects,
    "ObjectRepresentation" -> "CompiledExactRationalV1",
    "EvaluationVariables" -> evaluationVariables,
    "MaximumExponents" -> maximumExponents,
    "Roots" -> orderedRoots, "RootSymbols" -> rootSymbols,
    "RootCount" -> Length[orderedRoots],
    "GradeCount" -> 2^Length[orderedRoots],
    "RootFingerprints" -> frame["RootFingerprints"],
    "RootOrderingFingerprint" -> frame["OrderingFingerprint"],
    "RootCensus" -> Join[KeyTake[census,
      {"RootIndices", "RadicalBases", "DenestedRadicalBases"}],
      <|"RootIndices" -> Sort[DeleteDuplicates[Join[
        Lookup[census, "RootIndices", {}],
        Flatten[DeleteCases[numericClassIndices, None]]]]]|>],
    "DeclaredNumericRootClasses" -> numericClasses,
    "DeclaredNumericRootIndices" -> numericClassIndices,
    "DenestedRadicals" -> Lookup[canonical, "Rewritten", 0]|>
];

(* A redundant supplied alphabet is harmless.  Select a deterministic
   independent column subset instead of rejecting a correct dlog form merely
   because two supplied letters have the same logarithmic differential. *)
familyCertMQIndependentColumns[matrix_List, prime_Integer] := Module[
  {selected = {}, rank = 0, next},
  Do[
    next = MatrixRank[matrix[[All, Append[selected, column]]],
      Modulus -> prime];
    If[next > rank, AppendTo[selected, column]; rank = next],
    {column, If[matrix === {}, 0, Length[First[matrix]]]}];
  selected
];

familyCertMQPivotSignature[trial_Association] := Module[
  {prime = Lookup[trial, "Prime", $Failed],
   pivots = Lookup[trial, "PivotColumns", $Failed],
   rank = Lookup[trial, "DLogRank", $Failed], signature},
  If[! IntegerQ[prime] || ! PrimeQ[prime] ||
      ! VectorQ[pivots, IntegerQ] || ! IntegerQ[rank] || rank < 0 ||
      Length[pivots] =!= rank || ! DuplicateFreeQ[pivots],
    Return[familyCertMQFailure["DLogPivotSignatureInvalid",
      <|"Prime" -> prime|>]]];
  signature = {rank, pivots};
  <|"Status" -> "DLogPivotSignature", "Prime" -> prime,
    "Rank" -> rank, "PivotColumns" -> pivots,
    "Signature" -> signature,
    "SignatureFingerprint" ->
      Hash[signature, "SHA256", "HexString"]|>
];
familyCertMQPivotSignature[___] :=
  familyCertMQFailure["DLogPivotSignatureInvalid"];

(* Select a pivot plan only after a bounded quorum over distinct primes.
   This prevents an exceptional first characteristic from becoming the
   authority which rejects every later generic prime.  Ties and a missing
   quorum are typed instability, never an arbitrary first-prime choice. *)
familyCertMQSelectModalPivotTrials[trials_List, quorum_Integer] := Module[
  {evidence, groups, groupCounts, maximum, modes, mode, accepted, rejected,
   reference, signature},
  If[quorum < 2 || Length[trials] < quorum ||
      ! DuplicateFreeQ[Lookup[trials, "Prime", {}]],
    Return[familyCertMQFailure["DLogPivotQuorumInvalid",
      <|"Quorum" -> quorum, "TrialCount" -> Length[trials]|>]]];
  evidence = familyCertMQPivotSignature /@ trials;
  If[AnyTrue[evidence,
      Lookup[#1, "Status", None] =!= "DLogPivotSignature" &],
    Return[FirstCase[evidence,
      item_ /; Lookup[item, "Status", None] =!= "DLogPivotSignature" :>
        item]]];
  groups = GatherBy[evidence, Lookup[#1, "Signature", Missing[]] &];
  groupCounts = (<|"Signature" -> First[#1]["Signature"],
      "SignatureFingerprint" -> First[#1]["SignatureFingerprint"],
      "Count" -> Length[#1]|> &) /@ groups;
  maximum = If[groups === {}, 0, Max[Length /@ groups]];
  modes = Select[groups, Length[#1] === maximum &];
  If[maximum < quorum || Length[modes] =!= 1,
    Return[familyCertMQFailure["DLogPivotStructureUnstable",
      <|"Quorum" -> quorum, "SignatureCounts" -> groupCounts,
        "Evidence" -> evidence|>]]];
  mode = First[modes];
  reference = First[mode];
  signature = reference["Signature"];
  accepted = Select[trials,
    {Lookup[#1, "DLogRank", Missing[]],
       Lookup[#1, "PivotColumns", Missing[]]} === signature &];
  rejected = Select[trials,
    {Lookup[#1, "DLogRank", Missing[]],
       Lookup[#1, "PivotColumns", Missing[]]} =!= signature &];
  <|"Status" -> "ModalDLogPivotSignature",
    "Signature" -> signature,
    "SignatureFingerprint" -> reference["SignatureFingerprint"],
    "Rank" -> reference["Rank"],
    "PivotColumns" -> reference["PivotColumns"],
    "Quorum" -> quorum, "VoteCount" -> maximum,
    "Trials" -> accepted, "RejectedTrials" -> rejected,
    "Evidence" -> evidence|>
];
familyCertMQSelectModalPivotTrials[___] :=
  familyCertMQFailure["DLogPivotQuorumInvalid"];

(* One prime trial.  A point is usable only if all declared root squares are
   nonzero residues and every denominator is regular on every sign sheet.
   Training and validation are point-disjoint; all sign sheets of a point
   remain in the same partition. *)

(* B14 (overhaul 2026-09-02).  A prime at which a NUMERIC root square (a
   constant of the coefficient field, 3 for Sqrt[3]) is a non-residue admits
   no split point at all.  The loops below used to draw any p == 3 (mod 4),
   spend up to maxPointAttempts on such a prime, and count it against ONE
   prime budget shared by the pilot, CRT, extension and fresh-validation
   stages -- measured 2026-09-02: the numeric constant-field certification
   failed in about one run of twelve on both trees, always as
   InsufficientFreshValidationPrimes after InsufficientUsablePoints at
   p == 7 (mod 12).  Now only admissible primes are drawn (bounded raw
   draws) and only trials consume the budget. *)
familyCertMQNumericRootSquares[roots_List] :=
  Select[Lookup[roots, "RootSquare", {}], MatchQ[#, _Integer | _Rational] &];
familyCertMQPrimeAdmissibleQ[numericSquares_List, p_Integer] :=
  AllTrue[numericSquares, Function[c, With[
    {a = Mod[Numerator[c], p], b = Mod[Denominator[c], p]},
    a =!= 0 && b =!= 0 &&
      JacobiSymbol[Mod[a PowerMod[b, -1, p], p], p] === 1]]];
familyCertMQDrawPrime[roots_List, attempted_List, range_List] := Module[
  {numeric = familyCertMQNumericRootSquares[roots], p, draws = 0, found = None},
  While[found === None && draws < 4096,
    draws++;
    p = RandomPrime[range];
    If[Mod[p, 4] === 3 && ! MemberQ[attempted, p] &&
        familyCertMQPrimeAdmissibleQ[numeric, p], found = p]];
  found];

familyCertMQTrial[prepared_Association, variables : {_Symbol, _Symbol},
    regulator_Symbol, prime_Integer, trainingPoints_Integer,
    validationPoints_Integer, maxPointAttempts_Integer] := Module[
  {exactObjects = prepared["Objects"], objects,
   roots = prepared["Roots"],
   rootSymbols = prepared["RootSymbols"], rank = prepared["RootCount"],
   evaluationVariables = Lookup[prepared, "EvaluationVariables", {}],
   maximumExponents = Lookup[prepared, "MaximumExponents", {}],
   reduceEntry, evaluate, evaluateMatrix, powerTables,
   n, target, accepted = 0, attempts = 0, trainRows = {}, trainRhs = {},
   validationRows = {}, validationRhs = {}, identityChecks, pointRecords = {},
   point, epsilon2, scalarRules, deltaValues, rootValues, pointRows, pointRhs,
   pointIdentity, pointOK, sheetRecords, signedRoots, signs,
   S, Si, B1, B2, B1b, B2b, dSx, dSy, Av, Aw, dAvw, dAwv,
   jacobian, A1, A2, letterX, letterY, inverseEpsilon, ok, dimension,
   pivotColumns, coefficients, dlogOK, zeroFormAtPoints = True,
   trainingQ, mask},
  If[Lookup[prepared, "ObjectRepresentation", None] =!=
        "CompiledExactRationalV1" ||
      Length[evaluationVariables] =!= 3 + rank ||
      Length[maximumExponents] =!= Length[evaluationVariables],
    Return[familyCertMQFailure[
      "PreparedCompiledEvaluatorMissing"]]];
  reduceEntry[0] := 0;
  reduceEntry[entry_Association] :=
    multiquadraticStripScreenReduceScalar[entry, prime];
  reduceEntry[_] := $Failed;
  objects = AssociationMap[Function[key,
      If[key === "Letters", exactObjects[key],
        Map[reduceEntry, exactObjects[key], {2}]]],
    Keys[exactObjects]];
  If[! FreeQ[KeyDrop[objects, "Letters"], $Failed],
    Return[familyCertMQFailure[
      "CompiledEvaluatorPrimeReductionFailed", <|"Prime" -> prime|>]]];
  evaluate[0] := 0;
  evaluate[entry_Association] :=
    multiquadraticStripScreenEvaluateRationalValue[
      entry, powerTables, prime];
  evaluate[_] := $Failed;
  evaluateMatrix[matrix_] := Map[evaluate, matrix, {2}];
  n = Length[objects["S"]]; dimension = n;
  target = trainingPoints + validationPoints;
  identityChecks = <|"TransformationInverse" -> True,
    "GaugeIdentity" -> True, "Flatness" -> True,
    "EpsFactored" -> True, "SourceFlatness" -> True|>;
  ok[matrix_] := AllTrue[Flatten[Mod[matrix, prime]], # === 0 &];
  While[accepted < target && attempts < maxPointAttempts,
    attempts++;
    point = RandomInteger[{2, prime - 2}, 3];
    If[point[[3]] === 0, Continue[]];
    scalarRules = Thread[Append[variables, regulator] -> point];
    deltaValues = familyCertMQModRational[# /. scalarRules, prime] & /@
      Lookup[roots, "RootSquare", {}];
    If[MemberQ[deltaValues, $Failed], Continue[]];
    rootValues = familyCertMQSquareRoot[#, prime] & /@ deltaValues;
    If[MemberQ[rootValues, $Failed], Continue[]];
    epsilon2 = RandomInteger[{2, prime - 2}];
    While[epsilon2 === point[[3]], epsilon2 = RandomInteger[{2, prime - 2}]];
    pointRows = {}; pointRhs = {}; pointIdentity = identityChecks;
    pointOK = True; sheetRecords = {};
    Do[
      signs = Table[If[BitGet[mask, bit] === 1, -1, 1],
        {bit, 0, rank - 1}];
      signedRoots = Mod[signs rootValues, prime];
      powerTables = multiquadraticStripScreenPowerTables[
        Join[point, signedRoots], maximumExponents, prime];
      {S, Si, B1, B2, dSx, dSy, Av, Aw, dAvw, dAwv,
        jacobian, letterX, letterY} = Map[evaluateMatrix, Lookup[objects,
        {"S", "Si", "B1", "B2", "dSx", "dSy",
         "Av", "Aw", "dAvw", "dAwv", "Jacobian", "LetterX", "LetterY"}]];
      If[MemberQ[{S, Si, B1, B2, dSx, dSy, Av, Aw,
          dAvw, dAwv, jacobian, letterX, letterY}, $Failed],
        pointOK = False; Break[]];
      powerTables = multiquadraticStripScreenPowerTables[
        Join[ReplacePart[point, 3 -> epsilon2], signedRoots],
        maximumExponents, prime];
      {B1b, B2b} = evaluateMatrix /@ Lookup[objects, {"B1", "B2"}];
      If[MemberQ[{B1b, B2b}, $Failed], pointOK = False; Break[]];
      A1 = Mod[Av jacobian[[1, 1]] + Aw jacobian[[2, 1]], prime];
      A2 = Mod[Av jacobian[[1, 2]] + Aw jacobian[[2, 2]], prime];
      pointIdentity["TransformationInverse"] =
        pointIdentity["TransformationInverse"] &&
        ok[S . Si - IdentityMatrix[dimension]] &&
        ok[Si . S - IdentityMatrix[dimension]];
      pointIdentity["GaugeIdentity"] = pointIdentity["GaugeIdentity"] &&
        ok[Si . A1 . S - Si . dSx - B1] &&
        ok[Si . A2 . S - Si . dSy - B2];
      pointIdentity["SourceFlatness"] = pointIdentity["SourceFlatness"] &&
        ok[dAvw - dAwv + Av . Aw - Aw . Av];
      (* For an invertible gauge, the gauge identity transports the source
         curvature covariantly.  Re-differentiating the two enormous final
         epsilon-form matrices proves no additional statement and dominated
         CF300's otherwise modular certificate. *)
      pointIdentity["Flatness"] = pointIdentity["Flatness"] &&
        pointIdentity["TransformationInverse"] &&
        pointIdentity["GaugeIdentity"] &&
        pointIdentity["SourceFlatness"];
      pointIdentity["EpsFactored"] = pointIdentity["EpsFactored"] &&
        ok[epsilon2 B1 - point[[3]] B1b] &&
        ok[epsilon2 B2 - point[[3]] B2b];
      inverseEpsilon = PowerMod[point[[3]], -1, prime];
      If[Length[letterX] === 0,
        If[! (ok[B1] && ok[B2]), zeroFormAtPoints = False],
        AppendTo[pointRows, Flatten[letterX]];
        AppendTo[pointRhs, Mod[inverseEpsilon Flatten[B1], prime]];
        AppendTo[pointRows, Flatten[letterY]];
        AppendTo[pointRhs, Mod[inverseEpsilon Flatten[B2], prime]]];
      AppendTo[sheetRecords, <|"Sheet" -> mask,
        "RootSigns" -> signs|>],
      {mask, 0, 2^rank - 1}];
    If[! pointOK, Continue[]];
    identityChecks = AssociationMap[
      identityChecks[#] && pointIdentity[#] &, Keys[identityChecks]];
    accepted++; trainingQ = accepted <= trainingPoints;
    If[trainingQ,
      trainRows = Join[trainRows, pointRows]; trainRhs = Join[trainRhs, pointRhs],
      validationRows = Join[validationRows, pointRows];
      validationRhs = Join[validationRhs, pointRhs]];
    AppendTo[pointRecords, <|"Point" -> point,
      "SecondRegulator" -> epsilon2,
      "Partition" -> If[trainingQ, "Training", "Validation"],
      "Sheets" -> sheetRecords|>]];
  If[accepted < target,
    Return[familyCertMQFailure["InsufficientUsablePoints",
      <|"Prime" -> prime, "UsablePoints" -> accepted,
        "RequestedPoints" -> target, "PointAttempts" -> attempts|>]]];
  If[objects["Letters"] === {},
    pivotColumns = {}; coefficients = {}; dlogOK = zeroFormAtPoints,
    pivotColumns = familyCertMQIndependentColumns[trainRows, prime];
    If[pivotColumns === {},
      Return[familyCertMQFailure["DLogDesignRankZero",
        <|"Prime" -> prime, "LetterCount" -> Length[objects["Letters"]]|>]]];
    coefficients = Quiet[Check[LinearSolve[
      trainRows[[All, pivotColumns]], trainRhs, Modulus -> prime], $Failed]];
    dlogOK = MatrixQ[coefficients] &&
      ok[trainRows[[All, pivotColumns]] . coefficients - trainRhs] &&
      ok[validationRows[[All, pivotColumns]] . coefficients - validationRhs]];
  <|"Status" -> "UsablePrime", "Prime" -> prime,
    "Checks" -> Join[identityChecks,
      <|"DLog" -> dlogOK, "ConstantResidues" -> dlogOK|>],
    "PivotColumns" -> pivotColumns, "Coefficients" -> coefficients,
    "TrainingRows" -> trainRows, "TrainingRhs" -> trainRhs,
    "ValidationRows" -> validationRows,
    "ValidationRhs" -> validationRhs,
    "DLogRank" -> Length[pivotColumns],
    "DLogPivotSignature" -> {Length[pivotColumns], pivotColumns},
    "DLogPivotSignatureFingerprint" ->
      Hash[{Length[pivotColumns], pivotColumns}, "SHA256", "HexString"],
    "TrainingPoints" -> trainingPoints,
    "ValidationPoints" -> validationPoints,
    "PointAttempts" -> attempts, "Points" -> pointRecords,
    "AllSheetsPerPoint" -> 2^rank|>
];

familyCertMQReconstructResidues[trials_List, letterCount_Integer,
    dimension_Integer] := Module[
  {primes, pivots, coefficientTables, modulus, crt, reconstructed, verified,
   full},
  If[letterCount === 0, Return[<|"Status" -> "ReconstructedResidues",
    "Residues" -> {}, "PivotCoefficientTable" -> {},
    "Verified" -> True, "PivotColumns" -> {}|>]];
  primes = Lookup[trials, "Prime", {}];
  pivots = Lookup[First[trials], "PivotColumns", {}];
  If[pivots === {} || ! AllTrue[trials, Lookup[#, "PivotColumns", None] === pivots &],
    Return[familyCertMQFailure["DLogPivotPlanUnstable"]]];
  coefficientTables = Lookup[trials, "Coefficients", {}];
  modulus = Times @@ primes;
  crt = Table[ChineseRemainder[
      coefficientTables[[All, i, j]], primes],
    {i, Length[pivots]}, {j, dimension^2}];
  reconstructed = Map[familyCertRationalReconstruct[#, modulus] &, crt, {2}];
  If[! FreeQ[reconstructed, $Failed],
    Return[familyCertMQFailure["ResidueReconstructionNeedsMorePrimes",
      <|"ModulusBits" -> IntegerLength[modulus, 2]|>]]];
  verified = AllTrue[Range[Length[primes]], Function[k,
    Mod[Map[Mod[Numerator[#] PowerMod[Denominator[#], -1, primes[[k]]],
          primes[[k]]] &, reconstructed, {2}] - coefficientTables[[k]],
      primes[[k]]] === ConstantArray[0, Dimensions[reconstructed]]]];
  If[! verified, Return[familyCertMQFailure["ResidueCRTVerificationFailed"]]];
  full = ConstantArray[0, {letterCount, dimension^2}];
  full[[pivots]] = reconstructed;
  <|"Status" -> "ReconstructedResidues",
    "Residues" -> (Partition[#, dimension] & /@ full),
    "PivotCoefficientTable" -> reconstructed,
    "Verified" -> True, "PivotColumns" -> pivots,
    "ModulusBits" -> IntegerLength[modulus, 2]|>
];

(* Validate a reconstructed rational lift at one prime which did not enter
   its CRT modulus.  Equality with the independently fitted coefficients is
   checked first, then the lift itself is replayed on both the training and
   point-disjoint validation rows.  A prime dividing a reconstructed
   denominator is exceptional, never positive evidence. *)
familyCertMQValidateResiduesAtTrial[reconstruction_Association,
    trial_Association] := Module[
  {prime, pivots, rational, reduced, reduce, expected, trainingRows,
   trainingRhs, validationRows, validationRhs, zero, requiredChecks},
  If[Lookup[reconstruction, "Status", None] =!= "ReconstructedResidues" ||
      Lookup[trial, "Status", None] =!= "UsablePrime",
    Return[familyCertMQFailure["FreshPrimeValidationInputsInvalid"]]];
  prime = Lookup[trial, "Prime", $Failed];
  pivots = Lookup[reconstruction, "PivotColumns", $Failed];
  rational = Lookup[reconstruction, "PivotCoefficientTable", $Failed];
  expected = Lookup[trial, "Coefficients", $Failed];
  If[! IntegerQ[prime] || ! ListQ[pivots] || ! ListQ[rational] ||
      ! ListQ[expected] || Lookup[trial, "PivotColumns", None] =!= pivots,
    Return[familyCertMQFailure["FreshPrimePivotPlanMismatch",
      <|"Prime" -> prime, "ExpectedPivots" -> pivots,
        "FoundPivots" -> Lookup[trial, "PivotColumns", Missing[]]|>]]];
  reduce[value_] := Module[{denominator = Mod[Denominator[value], prime]},
    If[denominator === 0, $Failed,
      Mod[Numerator[value] PowerMod[denominator, -1, prime], prime]]];
  reduced = Map[reduce, rational, {2}];
  If[! FreeQ[reduced, $Failed],
    Return[familyCertMQFailure["FreshPrimeDividesLiftDenominator",
      <|"Prime" -> prime|>]]];
  If[Mod[reduced - expected, prime] =!=
      ConstantArray[0, Dimensions[expected]],
    Return[familyCertMQFailure["FreshPrimeResidueMismatch",
      <|"Prime" -> prime|>]]];
  {trainingRows, trainingRhs, validationRows, validationRhs} = Lookup[trial,
    {"TrainingRows", "TrainingRhs", "ValidationRows", "ValidationRhs"},
    $Failed];
  If[MemberQ[{trainingRows, trainingRhs, validationRows, validationRhs},
      $Failed],
    Return[familyCertMQFailure["FreshPrimeReplayRowsMissing",
      <|"Prime" -> prime|>]]];
  zero[matrix_] := AllTrue[Flatten[Mod[matrix, prime]], # === 0 &];
  If[pivots =!= {} &&
      ! (zero[trainingRows[[All, pivots]] . reduced - trainingRhs] &&
        zero[validationRows[[All, pivots]] . reduced - validationRhs]),
    Return[familyCertMQFailure["FreshPrimeResidueReplayFailed",
      <|"Prime" -> prime|>]]];
  If[pivots === {} &&
      ! (zero[trainingRhs] && zero[validationRhs]),
    Return[familyCertMQFailure["FreshPrimeZeroAlphabetReplayFailed",
      <|"Prime" -> prime|>]]];
  requiredChecks = {"TransformationInverse", "GaugeIdentity", "Flatness",
    "EpsFactored", "SourceFlatness", "DLog", "ConstantResidues"};
  If[! AllTrue[requiredChecks,
      TrueQ[Lookup[trial["Checks"], #, False]] &],
    Return[familyCertMQFailure["FreshPrimeIdentityCheckFailed",
      <|"Prime" -> prime, "Checks" -> trial["Checks"]|>]]];
  <|"Status" -> "FreshPrimeValidated", "Prime" -> prime,
    "PivotColumns" -> pivots,
    "TrainingPoints" -> trial["TrainingPoints"],
    "ValidationPoints" -> trial["ValidationPoints"],
    "AllSheetsPerPoint" -> trial["AllSheetsPerPoint"],
    "ResidueCoefficientMatch" -> True,
    "TrainingReplay" -> True, "ValidationReplay" -> True|>
];

familyCertMQValidateResiduesAtTrial[___] :=
  familyCertMQFailure["FreshPrimeValidationInputsInvalid"];

Options[familyCertificateMultiquadratic] = {
  "TrainingPoints" -> 3, "ValidationPoints" -> 2,
  "Primes" -> 3, "MaxPrimes" -> 9,
  "FreshValidationPrimes" -> 2,
  "MaxPrimeAttempts" -> 36, "MaxPointAttempts" -> 320,
  "RootRankLimit" -> Automatic,
  "RegulatorRootFrames" -> {},
  "PivotSignatureQuorum" -> 2,
  "PivotSignaturePilotPrimes" -> 3,
  "Seed" -> Automatic, "Verbose" -> False};

familyCertificateMultiquadratic[{b1_, b2_}, s_, si_,
    variables : {_Symbol, _Symbol}, regulator_Symbol,
    {av_, aw_}, sourceVariables : {_Symbol, _Symbol}, chart_Association,
    roots_List, letters_List, OptionsPattern[]] := Module[
  {trainingPoints, requestedTrainingPoints, trainingPointFloor,
   validationPoints, requestedPrimes, maxPrimes,
   freshValidationPrimes, maxPrimeAttempts, maxPointAttempts, rankLimit,
   regulatorRootFrames, authenticatedRootFrame,
   pivotSignatureQuorum, pivotSignaturePilotPrimes,
   seed, jacobian, subst,
   objects, prepared, trials = {}, pivotPilotTrials = {},
   pivotSelection = <||>, modalPivotSignature = None,
   rejected = {}, attemptedPrimes = {},
   primeAttempts = 0, p, trial, reconstruction, checks, dimension = Length[s],
   allTrue, rootsUsed, t0 = AbsoluteTime[], falsePositiveEstimate, pMin,
   dlogTrialsOK, crtCandidateOK, validationTrials = {}, validationEvidence = {},
   validation, allTrials, trialEvidence},
  trainingPoints = OptionValue["TrainingPoints"];
  requestedTrainingPoints = trainingPoints;
  validationPoints = OptionValue["ValidationPoints"];
  requestedPrimes = OptionValue["Primes"];
  maxPrimes = OptionValue["MaxPrimes"];
  freshValidationPrimes = OptionValue["FreshValidationPrimes"];
  maxPrimeAttempts = OptionValue["MaxPrimeAttempts"];
  maxPointAttempts = OptionValue["MaxPointAttempts"];
  rankLimit = Replace[OptionValue["RootRankLimit"], Automatic :>
    $familyRegulatorMaximumGradedRank];
  regulatorRootFrames = OptionValue["RegulatorRootFrames"];
  pivotSignatureQuorum = OptionValue["PivotSignatureQuorum"];
  pivotSignaturePilotPrimes = OptionValue["PivotSignaturePilotPrimes"];
  If[! And @@ {IntegerQ[trainingPoints] && trainingPoints > 0,
      IntegerQ[validationPoints] && validationPoints > 0,
      IntegerQ[requestedPrimes] && requestedPrimes >= 2,
      IntegerQ[maxPrimes] && maxPrimes >= requestedPrimes,
      IntegerQ[freshValidationPrimes] && freshValidationPrimes >= 2,
      IntegerQ[maxPrimeAttempts] && maxPrimeAttempts >= requestedPrimes,
      IntegerQ[maxPointAttempts] && maxPointAttempts >= trainingPoints + validationPoints,
      IntegerQ[rankLimit] && rankLimit >= 0 &&
        rankLimit <= $familyRegulatorMaximumGradedRank,
      MatchQ[regulatorRootFrames, {___Association}],
      IntegerQ[pivotSignatureQuorum] && pivotSignatureQuorum >= 2 &&
        pivotSignatureQuorum <= requestedPrimes,
      IntegerQ[pivotSignaturePilotPrimes] &&
        pivotSignaturePilotPrimes >= pivotSignatureQuorum &&
        pivotSignaturePilotPrimes <= maxPrimeAttempts},
    Return[familyCertMQFailure["InvalidCounts", <|
      "TrainingPoints" -> trainingPoints,
      "ValidationPoints" -> validationPoints,
      "Primes" -> requestedPrimes, "MaxPrimes" -> maxPrimes,
      "FreshValidationPrimes" -> freshValidationPrimes,
      "MaxPrimeAttempts" -> maxPrimeAttempts,
      "MaxPointAttempts" -> maxPointAttempts,
      "RootRankLimit" -> rankLimit,
      "ProducerMaximumRootRank" -> $familyRegulatorMaximumGradedRank,
      "PivotSignatureQuorum" -> pivotSignatureQuorum,
      "PivotSignaturePilotPrimes" -> pivotSignaturePilotPrimes|>]]];
  If[! FreeQ[letters, regulator],
    Return[familyCertMQFailure["LettersDependOnRegulator"]]];
  seed = Replace[OptionValue["Seed"], Automatic :> RandomInteger[{1, 2^31 - 1}]];
  SeedRandom[seed];
  subst = chart["Subst"];
  jacobian = chart["Jacobian"];
  (* Differentiate before the chart substitution.  This is the source
     connection's curvature, not the derivative of a pulled-back scalar. *)
  objects = <|
    "S" -> s, "Si" -> si, "B1" -> b1, "B2" -> b2,
    "dSx" -> D[s, variables[[1]]], "dSy" -> D[s, variables[[2]]],
    "Av" -> (av /. subst), "Aw" -> (aw /. subst),
    "dAvw" -> (D[av, sourceVariables[[2]]] /. subst),
    "dAwv" -> (D[aw, sourceVariables[[1]]] /. subst),
    "Jacobian" -> jacobian,
    "Letters" -> letters,
    "LetterX" -> ({D[#, variables[[1]]]/#} & /@ letters),
    "LetterY" -> ({D[#, variables[[2]]]/#} & /@ letters)|>;
  authenticatedRootFrame = familyCertMQAuthenticateRegulatorRootFrames[
    roots, regulatorRootFrames, variables, regulator, rankLimit];
  If[Lookup[authenticatedRootFrame, "Status", None] =!=
      "AuthenticatedRegulatorRootFrames", Return[authenticatedRootFrame]];
  (* One kinematic point contributes two one-form rows on every sign sheet.
     A smaller training design cannot determine a generic coefficient vector
     in the supplied alphabet: CF300's old 3-point design found a spurious
     rank-17 section which fit training images but failed fresh points, while
     seven points exposed the stable rank 23 and validated.  Size the design
     before sampling; held-out points remain disjoint acceptance evidence. *)
  trainingPointFloor = 1 + Ceiling[Length[letters]/
    (2 2^authenticatedRootFrame["RootCount"])];
  trainingPoints = Max[trainingPoints, trainingPointFloor];
  If[trainingPoints + validationPoints > maxPointAttempts,
    Return[familyCertMQFailure["TrainingDesignExceedsPointBudget", <|
      "RequestedTrainingPoints" -> requestedTrainingPoints,
      "RequiredTrainingPoints" -> trainingPoints,
      "ValidationPoints" -> validationPoints,
      "MaxPointAttempts" -> maxPointAttempts|>]]];
  prepared = familyCertMQPrepare[objects, authenticatedRootFrame["Roots"],
    variables, regulator, rankLimit];
  If[Lookup[prepared, "Status", None] =!= "PreparedMultiquadraticCertificate",
    Return[prepared]];
  rootsUsed = Lookup[prepared["RootCensus"], "RootIndices", {}];
  (* Structural pilot: choose the modal {rank,pivots} signature over
     distinct primes before any one prime is allowed to define the CRT
     section.  Two agreeing primes suffice, with at most three usable pilot
     primes by default. *)
  While[Length[pivotPilotTrials] < pivotSignaturePilotPrimes &&
      primeAttempts < maxPrimeAttempts,
    p = familyCertMQDrawPrime[prepared["Roots"], attemptedPrimes, {2^22, 2^23 - 1}];
    If[p === None, Break[]];
    primeAttempts++;
    AppendTo[attemptedPrimes, p];
    trial = familyCertMQTrial[prepared, variables, regulator, p,
      trainingPoints, validationPoints, maxPointAttempts];
    If[Lookup[trial, "Status", None] === "UsablePrime",
      AppendTo[pivotPilotTrials, trial];
      If[Length[pivotPilotTrials] >= pivotSignatureQuorum,
        pivotSelection = familyCertMQSelectModalPivotTrials[
          pivotPilotTrials, pivotSignatureQuorum];
        If[Lookup[pivotSelection, "Status", None] ===
            "ModalDLogPivotSignature", Break[]]],
      AppendTo[rejected, <|"Prime" -> p,
        "Reason" -> Lookup[trial, "Status", "PrimeTrialFailed"],
        "Detail" -> KeyDrop[trial, {"Points"}]|>]]];
  If[Lookup[pivotSelection, "Status", None] =!=
      "ModalDLogPivotSignature",
    Return[familyCertMQFailure["DLogPivotStructureUnstable",
      <|"PivotSignatureQuorum" -> pivotSignatureQuorum,
        "PivotSignaturePilotPrimes" -> pivotSignaturePilotPrimes,
        "PilotPrimes" -> Lookup[pivotPilotTrials, "Prime", {}],
        "PilotEvidence" -> Lookup[pivotSelection, "Evidence", {}],
        "PrimeAttempts" -> primeAttempts,
        "RejectedPrimes" -> rejected|>]]];
  modalPivotSignature = pivotSelection["Signature"];
  trials = pivotSelection["Trials"];
  Do[AppendTo[rejected, <|"Prime" -> nonmodal["Prime"],
      "Reason" -> "NonmodalDLogPivotSignature",
      "ObservedSignature" -> nonmodal["DLogPivotSignature"],
      "ModalSignature" -> modalPivotSignature|>],
    {nonmodal, pivotSelection["RejectedTrials"]}];
  While[Length[trials] < requestedPrimes && primeAttempts < maxPrimeAttempts,
    p = familyCertMQDrawPrime[prepared["Roots"], attemptedPrimes, {2^22, 2^23 - 1}];
    If[p === None, Break[]];
    primeAttempts++;
    AppendTo[attemptedPrimes, p];
    trial = familyCertMQTrial[prepared, variables, regulator, p,
      trainingPoints, validationPoints, maxPointAttempts];
    If[Lookup[trial, "Status", None] === "UsablePrime" &&
        Lookup[trial, "DLogPivotSignature", None] === modalPivotSignature,
      AppendTo[trials, trial],
      AppendTo[rejected, <|"Prime" -> p,
        "Reason" -> If[Lookup[trial, "Status", None] === "UsablePrime",
          "NonmodalDLogPivotSignature",
          Lookup[trial, "Status", "PrimeTrialFailed"]],
        "ObservedSignature" ->
          Lookup[trial, "DLogPivotSignature", Missing["NoSignature"]]|>]]];
  If[Length[trials] < requestedPrimes,
    Return[familyCertMQFailure["InsufficientUsablePrimes",
      <|"UsablePrimes" -> Lookup[trials, "Prime", {}],
        "RequestedPrimes" -> requestedPrimes,
        "RejectedPrimes" -> rejected|>]]];
  dlogTrialsOK = AllTrue[trials,
    TrueQ[Lookup[#1["Checks"], "DLog", False]] &&
      TrueQ[Lookup[#1["Checks"], "ConstantResidues", False]] &];
  If[dlogTrialsOK,
    reconstruction = familyCertMQReconstructResidues[trials,
      Length[letters], dimension];
    While[Lookup[reconstruction, "Status", None] ===
          "ResidueReconstructionNeedsMorePrimes" &&
        Length[trials] < maxPrimes && primeAttempts < maxPrimeAttempts,
      p = familyCertMQDrawPrime[prepared["Roots"], attemptedPrimes, {2^22, 2^23 - 1}];
      If[p === None, Break[]];
      primeAttempts++;
      AppendTo[attemptedPrimes, p];
      trial = familyCertMQTrial[prepared, variables, regulator, p,
        trainingPoints, validationPoints, maxPointAttempts];
      If[Lookup[trial, "Status", None] === "UsablePrime" &&
          Lookup[trial, "DLogPivotSignature", None] === modalPivotSignature,
        AppendTo[trials, trial],
        AppendTo[rejected, <|"Prime" -> p,
          "Reason" -> If[Lookup[trial, "Status", None] === "UsablePrime",
            "NonmodalDLogPivotSignature",
            Lookup[trial, "Status", "PrimeTrialFailed"]],
          "ObservedSignature" ->
            Lookup[trial, "DLogPivotSignature", Missing["NoSignature"]]|>]];
      reconstruction = familyCertMQReconstructResidues[trials,
        Length[letters], dimension]];
    If[Lookup[reconstruction, "Status", None] =!= "ReconstructedResidues",
      Return[Join[reconstruction, <|"Trials" -> trials,
        "RejectedPrimes" -> rejected|>]]],
    (* An inconsistent dlog system is already a negative certificate.  Do
       not spend the remaining prime budget trying to reconstruct a matrix
       that LinearSolve has proved does not exist. *)
    reconstruction = <|"Status" -> "ReconstructedResidues",
      "Residues" -> Missing["DLogInconsistent"], "Verified" -> False,
      "PivotColumns" -> Lookup[First[trials], "PivotColumns", {}],
      "PivotCoefficientTable" -> Missing["DLogInconsistent"]|>];
  crtCandidateOK = dlogTrialsOK && AllTrue[trials, Function[one,
    And @@ (TrueQ[Lookup[one["Checks"], #, False]] & /@
      {"TransformationInverse", "GaugeIdentity", "Flatness",
       "EpsFactored", "SourceFlatness", "DLog", "ConstantResidues"})]];
  (* Only a candidate which passed every CRT-prime identity reaches the
     unseen-prime gate.  A known-negative record keeps its negative verdict
     without consuming validation-prime work. *)
  If[crtCandidateOK,
    While[Length[validationTrials] < freshValidationPrimes &&
        primeAttempts < maxPrimeAttempts,
      p = familyCertMQDrawPrime[prepared["Roots"], attemptedPrimes, {2^22, 2^23 - 1}];
      If[p === None, Break[]];
      primeAttempts++;
      AppendTo[attemptedPrimes, p];
      trial = familyCertMQTrial[prepared, variables, regulator, p,
        trainingPoints, validationPoints, maxPointAttempts];
      If[Lookup[trial, "Status", None] =!= "UsablePrime",
        AppendTo[rejected, <|"Prime" -> p,
          "Reason" -> Lookup[trial, "Status", "FreshPrimeTrialFailed"]|>];
        Continue[]];
      validation = familyCertMQValidateResiduesAtTrial[reconstruction, trial];
      If[Lookup[validation, "Status", None] === "FreshPrimeValidated",
        AppendTo[validationTrials, trial];
        AppendTo[validationEvidence, Join[validation,
          <|"Points" -> (Join[KeyTake[#,
                {"Point", "SecondRegulator", "Partition"}],
              <|"SheetCount" -> Length[Lookup[#, "Sheets", {}]]|>] & /@
            trial["Points"] )|>]],
        AppendTo[rejected, <|"Prime" -> p,
          "Reason" -> Lookup[validation, "Status",
            "FreshPrimeLiftValidationFailed"],
          "Detail" -> KeyDrop[validation, {"Points"}]|>]]];
    If[Length[validationTrials] < freshValidationPrimes,
      Return[familyCertMQFailure["InsufficientFreshValidationPrimes",
        <|"CRTPrimes" -> Lookup[trials, "Prime", {}],
          "ValidationPrimes" -> Lookup[validationTrials, "Prime", {}],
          "RequestedValidationPrimes" -> freshValidationPrimes,
          "FreshValidationEvidence" -> validationEvidence,
          "RejectedPrimes" -> rejected|>]]]];
  allTrials = Join[trials, validationTrials];
  checks = AssociationMap[Function[key,
      AllTrue[allTrials, Function[one,
        TrueQ[Lookup[one["Checks"], key, False]]]]],
    {"TransformationInverse", "GaugeIdentity", "Flatness",
     "EpsFactored", "SourceFlatness", "DLog", "ConstantResidues"}];
  checks["LettersEpsFree"] = FreeQ[letters, regulator];
  checks["FreshLiftValidation"] = ! crtCandidateOK ||
    Length[validationTrials] >= freshValidationPrimes;
  allTrue = And @@ (TrueQ /@ Values[checks]);
  pMin = Min[Lookup[allTrials, "Prime"]];
  (* This number intentionally is not presented as a formal degree bound:
     the verifier avoids expanding algebraic numerators.  It is the direct
     independent-image collision scale; every point is fresh and every root
     embedding is tested. *)
  falsePositiveEstimate = N[pMin^(-Length[allTrials] validationPoints), 3];
  trialEvidence[one_] := KeyDrop[one,
    {"Coefficients", "TrainingRows", "TrainingRhs",
     "ValidationRows", "ValidationRhs"}];
  Join[checks, <|
    "Status" -> If[allTrue, "CertifiedMultiquadraticFamily", "CertificateFailed"],
    "CoefficientField" -> "Multiquadratic",
    "Method" -> "AllSignSheetsAtFreshSplitPoints",
    "Probabilistic" -> True, "Seed" -> seed,
    "RootCount" -> prepared["RootCount"],
    "GradeCount" -> prepared["GradeCount"],
    "RootIndicesUsed" -> rootsUsed,
    "RootFingerprints" -> prepared["RootFingerprints"],
    "RootOrderingFingerprint" -> prepared["RootOrderingFingerprint"],
    "RootRankLimit" -> rankLimit,
    "ProducerMaximumRootRank" -> $familyRegulatorMaximumGradedRank,
    "RegulatorRootFrameEvidenceCount" ->
      authenticatedRootFrame["EvidenceCount"],
    "RegulatorRootFrameEvidenceFingerprints" ->
      authenticatedRootFrame["EvidenceFingerprints"],
    "DenestedRadicals" -> prepared["DenestedRadicals"],
    "AllRootSheetsChecked" -> AllTrue[trials,
      #1["AllSheetsPerPoint"] === prepared["GradeCount"] &],
    "Letters" -> letters, "Residues" -> reconstruction["Residues"],
    "ResiduesVerifiedAtAllPrimes" -> (reconstruction["Verified"] &&
      (! crtCandidateOK || Length[validationTrials] >= freshValidationPrimes)),
    "DLogPivotColumns" -> reconstruction["PivotColumns"],
    "DLogModalPivotSignature" -> modalPivotSignature,
    "DLogPivotSignatureQuorum" -> pivotSignatureQuorum,
    "DLogPivotPilotPrimeLimit" -> pivotSignaturePilotPrimes,
    "DLogPivotPilotEvidence" -> pivotSelection["Evidence"],
    "Primes" -> Lookup[allTrials, "Prime", {}],
    "CRTPrimes" -> Lookup[trials, "Prime", {}],
    "ValidationPrimes" -> Lookup[validationTrials, "Prime", {}],
    "FreshValidationEvidence" -> validationEvidence,
    "RejectedPrimes" -> rejected,
    "PointsPerPrime" -> trainingPoints + validationPoints,
    "RequestedTrainingPointsPerPrime" -> requestedTrainingPoints,
    "TrainingPointFloor" -> trainingPointFloor,
    "TrainingPointsPerPrime" -> trainingPoints,
    "ValidationPointsPerPrime" -> validationPoints,
    "PointsDone" -> (KeyTake[#,
        {"Prime", "TrainingPoints", "ValidationPoints", "DLogRank",
         "AllSheetsPerPoint", "PointAttempts"}] & /@ allTrials),
    "Trials" -> (trialEvidence /@ trials),
    "ValidationTrials" -> (trialEvidence /@ validationTrials),
    "FalsePositiveCollisionScale" -> falsePositiveEstimate,
    "ErrorBoundGoodCharacteristic" ->
      Missing["AlgebraicDegreeBoundNotExpanded"],
    "ErrorBoundIdentities" ->
      Missing["AlgebraicDegreeBoundNotExpanded"],
    "ErrorBoundDLog" -> Missing["AlgebraicDegreeBoundNotExpanded"],
    "DegreeBound" -> Missing["NotExpandedInAlgebraicVerifier"],
    "BadCharacteristicGuard" -> "IndependentPrimesAndAllEmbeddings",
    "Seconds" -> AbsoluteTime[] - t0,
    "Trouble" -> <||>|>]
];

familyCertificateMultiquadratic[___] :=
  familyCertMQFailure["MultiquadraticCertificateInputsInvalid"];
