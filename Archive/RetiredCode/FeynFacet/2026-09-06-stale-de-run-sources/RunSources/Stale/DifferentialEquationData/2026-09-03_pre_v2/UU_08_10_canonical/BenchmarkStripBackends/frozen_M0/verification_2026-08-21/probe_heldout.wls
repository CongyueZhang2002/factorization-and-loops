root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
p = 2147483647;
modQ[v_] := Mod[Mod[Numerator[v], p] PowerMod[Mod[Denominator[v], p], -1, p], p];
fs = {(3 e^3 + 2 e + 1)/(e^3 - 5 e^2 + 7), (e + 2)/(4 e^2 + 1), 5, 0, e^5/(e + 3), (e^2 - 1)/(e^2 + 2 e + 1)};
(* last one reduces to (e-1)/(e+1): degrees (1,1) after cancellation *)
trueDeg = {{3, 3}, {1, 2}, {0, 0}, {-Infinity, 0}, {5, 1}, {1, 1}};
epsVals = Table[k/(k + 20), {k, 1, 24}];
canon = Table[<|"EpsilonValue" -> ev, "EpsilonMod" -> modQ[ev], "Values" -> (modQ[# /. e -> ev] & /@ fs)|>, {ev, epsVals}];
ev[c_, x_] := Mod[Fold[Mod[#1 x + #2, p] &, 0, Reverse[c]], p];
r = FeynFacet`Private`finiteFieldStripHeldOutInterpolate[canon, p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3, "MaximumTotalDegree" -> 22];
Print["status: ", r["Status"], "  samples used: ", r["SampleCount"], "  construction: ", r["ConstructionCount"], "  mode: ", r["CertificationMode"]];
Print["degrees: ", Lookup[r["Interpolations"], "Degrees"], "  expected: ", trueDeg];
Print["deterministic shortfall coords: ", r["DeterministicShortfallCoordinates"]];
fresh = {101/7, 55/3, 1000/999};
agree = Table[AllTrue[fresh, Function[x, Module[{xm = modQ[x], it = r["Interpolations"][[i]]},
  Mod[ev[it["Numerator"], xm] - modQ[fs[[i]] /. e -> x] ev[it["Denominator"], xm], p] === 0]]], {i, Length[fs]}];
Print["interpolants reproduce truth at 3 fresh eps values mod p: ", agree];
r2 = FeynFacet`Private`finiteFieldStripHeldOutInterpolate[canon, p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3, "ExpectedDegrees" -> ReplacePart[trueDeg, 1 -> {2, 2}]];
Print["wrong expected profile -> ", r2["Status"], " ", Lookup[r2, "DegreeMismatchCoordinates", {}]];
r3 = FeynFacet`Private`finiteFieldStripHeldOutInterpolate[Take[canon, 6], p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3];
Print["only 6 samples -> ", r3["Status"], " need ", Lookup[r3, "RequiredAdditionalSampleCount", Missing[]]];
r4 = FeynFacet`Private`finiteFieldStripHeldOutInterpolate[Take[canon, 8], p, "InitialConstructionCount" -> 4, "HeldOutCount" -> 3];
Print["only 8 samples -> ", r4["Status"], " ", Lookup[r4, "Reason", ""], " need ", Lookup[r4, "RequiredAdditionalSampleCount", Missing[]]];
(* learned profile on a second prime: 7 construction + 3 held-out *)
p2 = 2147483629; modQ2[v_] := Mod[Mod[Numerator[v], p2] PowerMod[Mod[Denominator[v], p2], -1, p2], p2];
canon2 = Table[<|"EpsilonValue" -> x, "EpsilonMod" -> modQ2[x], "Values" -> (modQ2[# /. e -> x] & /@ fs)|>, {x, epsVals}];
r5 = FeynFacet`Private`finiteFieldStripHeldOutInterpolate[canon2, p2, "InitialConstructionCount" -> Max[Replace[Total /@ trueDeg, -Infinity -> 0, {1}]] + 1, "HeldOutCount" -> 3, "ExpectedDegrees" -> trueDeg];
Print["second prime with learned profile: ", r5["Status"], " samples ", r5["SampleCount"]];

(* ---- unseen-prime residual: accept the true lift, reject a corrupted one, on the real (9,6) A4 artifacts ---- *)
B = root <> "/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BenchmarkStripBackends/";
fixture = FeynFacet`FamilyArtifactRead[B <> "fixtures/fixture_CF254_9_6.wl"];
files = FileNames["*_mod_*.wl", B <> "frozen_M0/a4_run/ff_artifacts_A4_CF254_9_6_155035"];
modular = FeynFacet`FamilyArtifactRead /@ files;
Print["modular artifacts: ", Length[modular], " primes ", Lookup[modular, "Prime"], " modes ", Lookup[modular, "CertificationMode", "?"]];
lifted = FeynFacet`ReconstructEpsFormStrip[fixture, modular, "KernelCount" -> 1, "ExactCheck" -> False];
Print["lift without exact check: ", lifted["Status"], "  vector length ", Length[lifted["LiftedVector"]]];
prep = FeynFacet`PrepareEpsFormStripSampling[fixture];
opts = {"PointCount" -> Automatic, "NumeratorDegreeOffset" -> {1, 0}, "Support" -> Automatic, "SupportShell" -> 0, "SolveAffineSystem" -> True, "Preparation" -> prep, "ExpectedFingerprint" -> prep["Fingerprint"]};
t0 = AbsoluteTime[];
ok = FeynFacet`Private`finiteFieldStripUnseenPrimeResidualQ[fixture, lifted, prep, 2147483399, 43/63, opts];
Print["unseen-prime residual of TRUE lift zero: ", ok, " (", Round[AbsoluteTime[] - t0, 0.1], " s)"];
bad = lifted; bad["LiftedVector"] = ReplacePart[lifted["LiftedVector"], 5 -> lifted["LiftedVector"][[5]] + 1];
bad2 = lifted; bad2["LiftedVector"] = ReplacePart[lifted["LiftedVector"], 5 -> lifted["LiftedVector"][[5]] + Global`eps/7];
Print["corrupted lift (+1 on coordinate 5) rejected: ", ! FeynFacet`Private`finiteFieldStripUnseenPrimeResidualQ[fixture, bad, prep, 2147483399, 43/63, opts]];
Print["corrupted lift (+eps/7 on coordinate 5) rejected: ", ! FeynFacet`Private`finiteFieldStripUnseenPrimeResidualQ[fixture, bad2, prep, 2147483399, 43/63, opts]];
Print["DONE"];
