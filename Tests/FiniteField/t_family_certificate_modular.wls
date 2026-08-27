(* The modular family certificate (FamilyCertificateModular.wl, default
   IdentityMethod "Modular" of CertifyFamilyEpsilonForm, 2026-08-22):
   (a) CF231's exact record certifies (agrees with the symbolic certificate
       of 12:00 the same day) with the bounds recorded;
   (b) a corrupted transformation is rejected at the gauge identity;
   (c) a corrupted eps-form is rejected at eps-factorization, dlog, gauge
       and flatness;
   (d) the symbolic path is still selectable on a small synthetic system. *)
root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
R = FileNameJoin[{root, "ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical"}];
recordFile = FileNameJoin[{R, "FamilyEpsFormsCertified/family_epsform_CF231.wl"}];
If[! FileExistsQ[recordFile], Print["CF231 certified record missing; skipping"]; Exit[0]];
record = FeynFacet`FamilyArtifactRead[recordFile];
system = FeynFacet`FamilyArtifactRead[FileNameJoin[{R, "DifferentialEquations/nnlo_de_CF231.wl"}]];
{t, c} = AbsoluteTiming[FeynFacet`CertifyFamilyEpsilonForm[record, system]];
cert = Lookup[c, "EpsilonFormCertificate", <||>]; m = Lookup[cert, "Modular", <||>];
Print["(a) ", Round[t, 0.1], " s: ", c["Status"], "; error bounds identities ", Lookup[cert, "IdentityErrorBoundIdentities", "?"], " dlog ", Lookup[cert, "IdentityErrorBoundDLog", "?"], "; residues verified ", Lookup[m, "ResiduesVerifiedAtAllPrimes", "?"]];
check["(a) CF231 certifies (Modular)", c["Status"] === "ExactEpsilonForm" && TrueQ[FeynFacet`ExactFamilyEpsilonFormQ[c]]];
check["(a) all checks true", AssociationQ[c["Checks"]] && And @@ Values[c["Checks"]]];
check["(a) bounds recorded", NumberQ[Lookup[cert, "IdentityErrorBoundGoodCharacteristic", None]] && Lookup[cert, "IdentityErrorBoundGoodCharacteristic"] < 10^-20 && IntegerQ[Lookup[cert, "IdentityDegreeBound", None]] && Length[Lookup[m, "Primes", {}]] >= 3 && DuplicateFreeQ[Lookup[m, "Primes", {}]]];
check["(a) dlog fitted at full rank and validated on fresh points at every prime", AllTrue[Lookup[m, "PointsDone", {}], #["DlogRank"] === #["Letters"] && #["ValidationPoints"] >= 4 &]];
check["(a) residues reconstructed (CRT) and verified at all primes", TrueQ[Lookup[m, "ResiduesVerifiedAtAllPrimes", False]] && ListQ[Lookup[Lookup[c, "EpsilonFormCertificate", <||>], "Letters", None] /. None -> {}]];
check["(a) characteristic-zero guard ran", Lookup[m, "BadCharacteristicGuard", "?"] === "OneExactRationalPoint" && ! KeyExistsQ[Lookup[m, "Trouble", <||>], "CharacteristicZeroGuard"]];
check["(a) under 120 s (CF231's residues reach 101 digits: ~30 primes for the reconstruction)", t < 120];
bad = record; bad["TTotal"] = ReplacePart[record["TTotal"], {2, 1} -> record["TTotal"][[2, 1]] + record["Regulator"]/7];
c2 = FeynFacet`CertifyFamilyEpsilonForm[bad, system];
check["(b) corrupted transformation rejected", c2["Status"] =!= "ExactEpsilonForm" && Lookup[c2["Checks"], "GaugeIdentity", True] === False];
bad2 = record; bad2["EpsFormX"] = ReplacePart[record["EpsFormX"], {3, 2} -> record["EpsFormX"][[3, 2]] + record["Regulator"]^2/(1 + record["Variables"][[1]])];
c3 = FeynFacet`CertifyFamilyEpsilonForm[bad2, system];
check["(c) corrupted eps-form rejected at EpsFactored, DLog, Gauge, Flatness",
  Lookup[c3["Checks"], "EpsFactored"] === False && Lookup[c3["Checks"], "DLog"] === False &&
  Lookup[c3["Checks"], "GaugeIdentity"] === False && Lookup[c3["Checks"], "Flatness"] === False];
(* (d) symbolic path on a synthetic 2x2 record without chart *)
Clear[x, y, eps];
a = {{eps/x, 0}, {eps/(x - 1), eps/x}}; b = {{eps/y, 0}, {0, eps/(y + 1)}};
syn = <|"Family" -> "SYN", "Variables" -> {x, y}, "Regulator" -> eps, "Chart" -> None,
  "TTotal" -> IdentityMatrix[2], "TTotalInverse" -> IdentityMatrix[2], "Blocks" -> {{{1}, 1}, {{2}, 2}}, "Ranges" -> {{1}, {2}},
  "EpsFormX" -> a, "EpsFormY" -> b|>;
sys = <|"Av" -> a, "Aw" -> b|>;
cs = FeynFacet`CertifyFamilyEpsilonForm[syn, sys, "SourceVariables" -> {x, y}, "Chart" -> None, "IdentityMethod" -> "Symbolic"];
cm = FeynFacet`CertifyFamilyEpsilonForm[syn, sys, "SourceVariables" -> {x, y}, "Chart" -> None];
Print["(d) symbolic ", cs["Status"], " modular ", cm["Status"]];
check["(d) symbolic and modular agree on the synthetic system", cs["Status"] === cm["Status"]];
(* (e) Codex adversarial cases
   (Exchange/Codex/2026-08-22/02_final_checker_stress_suite) *)
rec1[name_, bx_, by_] := <|"Family" -> name, "Variables" -> {x, y}, "Regulator" -> eps, "Chart" -> None,
  "TTotal" -> IdentityMatrix[1], "TTotalInverse" -> IdentityMatrix[1], "Blocks" -> {{{1}, 1}}, "Ranges" -> {{1}}, "EpsFormX" -> bx, "EpsFormY" -> by|>;
cert1[r_] := FeynFacet`CertifyFamilyEpsilonForm[r, <|"Av" -> r["EpsFormX"], "Aw" -> r["EpsFormY"]|>, "SourceVariables" -> {x, y}, "Chart" -> None];
ce = cert1[rec1["EMPTY", {{eps}}, {{0}}]];
check["(e) nonzero form with empty alphabet rejected", ce["Status"] =!= "ExactEpsilonForm" && Lookup[ce["Checks"], "DLog", True] === False];
cs2 = cert1[rec1["SUM", {{eps (1/x + 1)}}, {{0}}]];
check["(e) uncombined sum: letter x found, non-dlog rejected", cs2["Status"] =!= "ExactEpsilonForm" && MemberQ[Lookup[Lookup[Lookup[cs2, "EpsilonFormCertificate", <||>], "DLog", <||>], "Letters", {}], x]];
cz = cert1[rec1["ZERO", {{0}}, {{0}}]];
check["(e) zero form certifies", cz["Status"] === "ExactEpsilonForm"];
cg = cert1[rec1["GOOD", {{eps/x + eps/(x - 1)}}, {{eps/y}}]];
check["(e) genuine 1x1 dlog form certifies with reconstructed residues", cg["Status"] === "ExactEpsilonForm" &&
  TrueQ[Lookup[Lookup[Lookup[cg, "EpsilonFormCertificate", <||>], "Modular", <||>], "ResiduesVerifiedAtAllPrimes", False]]];
cpoly = cert1[rec1["POLY", {{eps/x + eps x}}, {{0}}]];
check["(e) polynomial part (pole at infinity) rejected", cpoly["Status"] =!= "ExactEpsilonForm" && Lookup[cpoly["Checks"], "DLog", True] === False];
Print["t_family_certificate_modular: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
