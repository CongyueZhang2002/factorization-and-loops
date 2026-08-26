#!/usr/bin/env wolframscript

$HistoryLength = 0;

Module[{file, expectedHash, payload, solution},
  file = "/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/" <>
    "cf303_17_12_pair_chart_solve_v1/solution.wxf";
  expectedHash =
    "20ed234d0bb41933aa120f329193779c005be920fabbdc84d493f5c55985a3e9";
  If[Rest[$ScriptCommandLine] =!= {} ||
      ! IntegerQ[$KernelID] || $KernelID <= 0 || Length[Kernels[]] =!= 0 ||
      ! FileExistsQ[file] ||
      FileHash[file, "SHA256", "HexString"] =!= expectedHash,
    Print["CF303METAPROBEV1 failure=preflight"];
    Return[$Failed]];
  payload = Import[file, "WXF"];
  solution = Lookup[payload, "Solution", $Failed];
  If[! AssociationQ[payload] || ! AssociationQ[solution],
    Print["CF303METAPROBEV1 failure=payload"];
    Return[$Failed]];
  Print["CF303METAPROBEV1 payloadKeys=", Keys[payload]];
  Print["CF303METAPROBEV1 solutionKeys=", Keys[solution]];
  Print["CF303METAPROBEV1 shapes=", AssociationMap[
    Quiet[Check[Dimensions[solution[#]], Head[solution[#]]]] &,
    Intersection[Keys[solution], {"Gauge", "Alphabet", "ResidueMatrices",
      "PfaffianResiduals", "ExactPfaffianResiduals"}]]];
  Print["CF303METAPROBEV1 exactFlags=", KeyTake[solution,
    {"LettersEpsFree", "ResiduesKinematicsFree", "ResiduesEpsFree",
     "ExactPfaffianResidualsZero", "ExactPfaffianIdentitiesZero",
     "ConstantResidues", "DLogFormCertified",
     "CanonicalEpsFormCertified", "ExactDLog"}]];
  Print["CF303METAPROBEV1 residueFreeByVariable=",
    AssociationMap[FreeQ[solution["ResidueMatrices"], #] &,
      Join[payload["Variables"], {payload["Regulator"]}]]];
  Print["CF303METAPROBEV1 status=PASS"];
  0
]
