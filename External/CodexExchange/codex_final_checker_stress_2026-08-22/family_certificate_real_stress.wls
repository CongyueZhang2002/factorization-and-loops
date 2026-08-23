(* Bounded real-family stress tests for the modular final checker.
   External diagnostic only; no package or result artifact is modified. *)

root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0;
fail = 0;
check[label_, condition_] := If[
  TrueQ[condition],
  pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]
];

resultRoot = FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Results", "UU_08_10_canonical"
}];

loadRecord[family_] := FeynFacet`FamilyArtifactRead[FileNameJoin[{
  resultRoot, "FamilyEpsFormsCertified", "family_epsform_" <> family <> ".wl"
}]];

loadSystem[family_] := FeynFacet`FamilyArtifactRead[FileNameJoin[{
  resultRoot, "DifferentialEquations", "nnlo_de_" <> family <> ".wl"
}]];

modularData[c_] := Lookup[
  Lookup[c, "EpsilonFormCertificate", <||>], "Modular", <||>
];

(* Full end-to-end rechecks of the two largest newly certified records. *)
Do[
  record = loadRecord[family];
  system = loadSystem[family];
  {seconds, certified} = AbsoluteTiming[
    FeynFacet`CertifyFamilyEpsilonForm[record, system]
  ];
  m = modularData[certified];
  pointData = Lookup[m, "PointsDone", {}];
  primes = Lookup[m, "Primes", {}];
  Print[
    family, " full: ", NumberForm[seconds, {6, 2}], " s; status=",
    Lookup[certified, "Status", Missing[]], "; dim=", Length[record["TTotal"]],
    "; primes=", primes, "; points/ranks=", pointData,
    "; residues verified=", Lookup[m, "ResiduesVerifiedAtOtherPrimes", Missing[]],
    "; error=", Lookup[Lookup[certified, "EpsilonFormCertificate", <||>],
      "IdentityErrorBound", Missing[]]
  ];
  check[family <> " full record certifies",
    Lookup[certified, "Status", None] === "ExactEpsilonForm" &&
    And @@ (TrueQ /@ Values[Lookup[certified, "Checks", <||>]])];
  check[family <> " sampled primes are distinct",
    Length[primes] === 3 && DuplicateFreeQ[primes]];
  check[family <> " dlog design has full column rank at every prime",
    Length[pointData] === Length[primes] &&
    AllTrue[pointData, #["DlogRank"] === #["Letters"] &]];
  check["EXPOSE " <> family <> " exact verdict lacks verified residues",
    Lookup[certified, "Status", None] === "ExactEpsilonForm" &&
    ! TrueQ[Lookup[m, "ResiduesVerifiedAtOtherPrimes", False]]],
  {family, {"CF265", "CF305"}}
];

(* Isolate the dlog check on the largest real epsilon form.  Replacing the
   transformation by I and the source connection by the same B makes inverse,
   gauge and source-flatness tautological, while retaining the real 32x32
   alphabet and flat connection.  Adding eps*I to B_x preserves flatness and
   eps-linearity but is not a rational dlog one-form. *)
record = loadRecord["CF305"];
variables = record["Variables"];
regulator = record["Regulator"];
b1 = record["EpsFormX"];
b2 = record["EpsFormY"];
dimension = Length[b1];
selfRecord = <|
  "Family" -> "CF305_DLOG_ISOLATION",
  "Variables" -> variables,
  "Regulator" -> regulator,
  "Chart" -> None,
  "TTotal" -> IdentityMatrix[dimension],
  "TTotalInverse" -> IdentityMatrix[dimension],
  "Blocks" -> {{Range[dimension], 1}},
  "Ranges" -> {Range[dimension]},
  "EpsFormX" -> b1,
  "EpsFormY" -> b2
|>;

certifySelf[r_] := FeynFacet`CertifyFamilyEpsilonForm[
  r,
  <|"Av" -> r["EpsFormX"], "Aw" -> r["EpsFormY"]|>,
  "SourceVariables" -> variables,
  "Chart" -> None,
  "IdentityMethod" -> "Modular",
  "ModularPoints" -> 12,
  "ModularPrimes" -> 3
];

{baseSeconds, selfBase} = AbsoluteTiming[certifySelf[selfRecord]];
Print[
  "CF305 dlog-isolation baseline: ", NumberForm[baseSeconds, {6, 2}],
  " s; status=", Lookup[selfBase, "Status", Missing[]],
  "; checks=", Lookup[selfBase, "Checks", <||>]
];
check["CF305 dlog-isolation baseline certifies",
  Lookup[selfBase, "Status", None] === "ExactEpsilonForm"];

badRecord = selfRecord;
badRecord["Family"] = "CF305_DLOG_PLUS_IDENTITY";
badRecord["EpsFormX"] = Map[
  Together,
  b1 + regulator IdentityMatrix[dimension],
  {2}
];
{badSeconds, selfBad} = AbsoluteTiming[certifySelf[badRecord]];
badChecks = Lookup[selfBad, "Checks", <||>];
Print[
  "CF305 + eps I_x: ", NumberForm[badSeconds, {6, 2}],
  " s; status=", Lookup[selfBad, "Status", Missing[]],
  "; checks=", badChecks
];
check["CF305 flat eps-linear polynomial contamination is rejected by DLog",
  Lookup[selfBad, "Status", None] === "EpsilonFormCertificationFailed" &&
  Lookup[badChecks, "DLog", True] === False &&
  And @@ (TrueQ /@ Values[KeyDrop[badChecks, {"DLog"}]])];

Print["SUMMARY ", pass, " real-family checks OK, ", fail, " failed"];
Exit[If[fail === 0, 0, 1]];
