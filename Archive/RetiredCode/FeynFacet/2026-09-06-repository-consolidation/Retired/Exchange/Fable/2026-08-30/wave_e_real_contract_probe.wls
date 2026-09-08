#!/usr/bin/env wolframscript
(* Wave E step 1 (Codex note 24): compare entries of the pulled-back
   REAL CF303 complete connection against direct source evaluation at
   fresh modular (tau, eps) points, both consistent root signs.  No
   global symbolic identity; exact modular arithmetic only. *)

root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

contract = Get["/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_u3_common_path_contract.wl"];
Print["contract: ", contract["Status"], " family ", contract["Family"]];

stateFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/CF303_exception14_continuation_2026-08-30/sector_state_CF303_standard.wl";
Print["loading state (154 MB) ..."];
loadSeconds = First[AbsoluteTiming[state = Get[stateFile];]];
Print["state loaded in ", loadSeconds, " s; keys: ", Keys[state]];

(* locate the connection pair *)
{av, aw} = Which[
  KeyExistsQ[state, "A"], state["A"],
  KeyExistsQ[state, "Av"], {state["Av"], state["Aw"]},
  True, $Failed];
Print["connection dimensions: ", Dimensions[av]];

z = contract["PathVariable"];
vars = contract["Variables"];
path = contract["SourcePath"];
rootSquares = contract["SourceRootSquares"];
rootBranches = contract["SourceRootBranches"];
extension = contract["PathExtension"];
delta2 = extension["RootSquare"];
r2 = extension["Root"];
endpoints = {1/7, 5/7};
{z0, z1} = endpoints;
tau = Global`waveEProbeTau;
eps = Global`ep;  (* the state's regulator symbol is checked below *)

(* pick the regulator symbol actually present *)
regulatorCandidates = Select[{Global`ep, Global`eps, Global`epsilon},
  ! FreeQ[{av[[44, 44]], av[[45, 45]]}, #] &];
Print["regulator symbols present: ", regulatorCandidates];
If[regulatorCandidates =!= {}, eps = First[regulatorCandidates]];

(* entries to probe: sector-25 diagonal, sector-18 diagonal, one
   feeder coupling, one lower-row coupling *)
probes = {{44, 44}, {44, 45}, {45, 44}, {45, 45},
  {29, 29}, {30, 29}, {44, 29}, {45, 30}, {44, 12}, {45, 12}};

pullback = FeynFacet`Private`pathTransportExceptionPullback;
ztau = z0 + tau (z1 - z0);
xOfZ = path[vars[[1]]]; yOfZ = path[vars[[2]]];
dxdz = D[xOfZ, z]; dydz = D[yOfZ, z];

modRational = FeynFacet`Private`multiquadraticStripModRational;

evaluateModular[expr_, tauValue_, epsValue_, prime_, r2Sign_] := Module[
  {radicals, radical, baseValue, sheet, sheetInverse, substituted},
  radicals = DeleteDuplicates[Cases[expr,
    Power[q_, e_] /; ! IntegerQ[e] && ! FreeQ[q, tau] :> q,
    {0, Infinity}]];
  If[Length[radicals] > 1, Return["MultipleRadicals"]];
  sheet = 0; sheetInverse = 0;
  If[radicals =!= {},
    radical = First[radicals];
    baseValue = modRational[radical /. tau -> tauValue, prime];
    If[baseValue === $Failed || JacobiSymbol[baseValue, prime] =!= 1,
      Return["RadicalNotSquare"]];
    sheet = Mod[r2Sign PowerMod[baseValue, (prime + 1)/4, prime], prime];
    sheetInverse = PowerMod[sheet, -1, prime]];
  substituted = expr /. Power[q_, e_Rational] /; ! FreeQ[q, tau] :>
    If[e > 0, sheet^Numerator[2 e], sheetInverse^(-Numerator[2 e])];
  modRational[substituted /. tau -> tauValue /. eps -> epsValue, prime]];

report = {};
primes = {2305843009213692139, 2305843009213692107};
epsPoints = {5/17, 7/19};
delta2OnPath[t0_] := delta2 /. z -> (z0 + t0 (z1 - z0));
tauPointsFor[prime_] := Module[{found = {}, k = 3},
  While[Length[found] < 2 && k < 200,
    Module[{t0 = k/(k + 8), v},
      v = modRational[delta2OnPath[t0], prime];
      If[IntegerQ[v] && JacobiSymbol[v, prime] === 1,
        AppendTo[found, t0]]];
    k += 2];
  found];
tauPointsByPrime = tauPointsFor /@ primes;
Print["QR-admissible tau points per prime: ", tauPointsByPrime];

Do[Module[{i, j, entryV, entryW, pulledV, pulledW, ahatEntry, verdicts},
  {i, j} = probe;
  entryV = av[[i, j]]; entryW = aw[[i, j]];
  If[entryV === 0 && entryW === 0,
    AppendTo[report, <|"Entry" -> probe, "Verdict" -> "ZeroEntry"|>],
    pulledV = pullback[entryV, contract, endpoints, tau];
    pulledW = pullback[entryW, contract, endpoints, tau];
    ahatEntry = (z1 - z0) (pulledV (dxdz /. z -> ztau) +
      pulledW (dydz /. z -> ztau));
    verdicts = Flatten@Table[Module[
      {p = primes[[pi]], t0 = tauPointsByPrime[[pi, ti]],
       e0 = epsPoints[[ti]],
       sign, lhs, lhsOpposite, zt0, x0, y0, branchValues,
       branchValuesFor, rhsFor, rhs, rhsOpposite, sanity},
      Table[
        sign = If[si === 1, 1, -1];
        lhs = evaluateModular[ahatEntry, t0, e0, p, sign];
        lhsOpposite = evaluateModular[ahatEntry, t0, e0, p, -sign];
        zt0 = z0 + t0 (z1 - z0);
        x0 = xOfZ /. z -> zt0; y0 = yOfZ /. z -> zt0;
        branchValuesFor[s_] := Table[
          If[rootBranches[[a]] === r2,
            Mod[s PowerMod[modRational[delta2 /. z -> zt0, p],
              (p + 1)/4, p], p],
            modRational[rootBranches[[a]] /. z -> zt0, p]],
          {a, Length[rootBranches]}];
        branchValues = branchValuesFor[sign];
        sanity = And @@ Table[
          Mod[branchValues[[a]]^2 - modRational[
            rootSquares[[a]] /. Thread[vars -> {x0, y0}], p], p] === 0,
          {a, Length[rootBranches]}];
        rhsFor[s_] := Module[{bv = branchValuesFor[s], bvInv, rr, direct},
          bvInv = PowerMod[#, -1, p] & /@ bv;
          (* every half-integer power of a declared root square, in
             numerators AND denominators, becomes the corresponding
             modular branch power *)
          rr = Flatten[Table[With[{sq = rootSquares[[a]],
              v = bv[[a]], vi = bvInv[[a]]},
            Power[sq, e_Rational] :> If[e > 0, v^Numerator[2 e],
              vi^(-Numerator[2 e])]],
            {a, Length[rootSquares]}]];
          direct[expr_] := modRational[
            expr /. rr /. Thread[vars -> {x0, y0}] /. eps -> e0, p];
          Mod[modRational[(z1 - z0) (dxdz /. z -> zt0), p] *
              direct[entryV] +
            modRational[(z1 - z0) (dydz /. z -> zt0), p] *
              direct[entryW], p]];
        rhs = rhsFor[sign];
        rhsOpposite = rhsFor[-sign];
        (* the pulled radical's base may be a rational-square multiple
           of Delta2, so the two principal square roots can differ by a
           global sign; the exact statement "equal for both consistent
           root signs" is the PAIRED match below, which still fails
           with probability 1 - O(1/p) on any wrong pullback *)
        <|"Prime" -> pi, "Point" -> ti, "Sign" -> sign,
          "BranchSanity" -> sanity,
          "Match" -> (IntegerQ[lhs] && IntegerQ[lhsOpposite] &&
            ((lhs === rhs && lhsOpposite === rhsOpposite) ||
             (lhs === rhsOpposite && lhsOpposite === rhs)))|>,
        {si, 1}]],
      {pi, 2}, {ti, 2}];
    AppendTo[report, <|"Entry" -> probe,
      "AllMatch" -> AllTrue[verdicts, TrueQ[#["Match"]] &],
      "AllSanity" -> AllTrue[verdicts, TrueQ[#["BranchSanity"]] &],
      "Images" -> Length[verdicts]|>]]],
  {probe, probes}];

Print["==== RESULTS ===="];
Do[Print[r], {r, report}];
ok = AllTrue[Select[report, KeyExistsQ[#, "AllMatch"] &],
  TrueQ[#["AllMatch"]] && TrueQ[#["AllSanity"]] &];
Print["PROBE ", If[ok, "ACCEPTED", "FAILED"]];
Put[<|"Status" -> If[ok, "CF303RealContractPullbackProbeAcceptedV1",
    "CF303RealContractPullbackProbeFailedV1"],
  "StateFile" -> stateFile, "Endpoints" -> endpoints,
  "Primes" -> primes, "Report" -> report|>,
  "/home/maxzhang/factorization-and-loops/Exchange/Fable/2026-08-30/wave_e_real_contract_probe_result.wl"];
Exit[If[ok, 0, 1]];
