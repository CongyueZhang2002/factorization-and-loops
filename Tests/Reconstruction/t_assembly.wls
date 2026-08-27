(* Weighted assembly of cut contributions.

   Acceptance criteria:
   A. Weight derivation: NLO UU card -> +1; NNLO UU gluon card -> +1/2;
      NNLO ghost card -> -1.
   B. Assembling one contribution with weight 1 reproduces it: same
      masters, every combined coefficient equals PreFactor x Coefficient
      of the source, same remainder.
   C. Assembling the same contribution twice doubles every coefficient
      (shared-name merging).
   D. Ghost x ghost assembly: two ghost contributions give weight -1
      each, so coefficients are -2 x the source products.
   E. Malformed input is rejected. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

nloCard = Get[FileNameJoin[{root, "ppHX_NLO", "Cards", "UU.wl"}]];
gluonCard = Get[FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Cards", "UU.wl"
}]];
ghostCard = Get[FileNameJoin[{
  root, "ppHX_NNLO_DoubleReal", "Cards", "UU_Ghost.wl"
}]];

FTTest`FTAssert["A1. NLO UU weight +1",
  FeynFacet`Private`assemblyWeight[nloCard] === 1];
FTTest`FTAssert["A2. NNLO gluon weight +1/2",
  FeynFacet`Private`assemblyWeight[gluonCard] === 1/2];
FTTest`FTAssert["A3. NNLO ghost weight -1",
  FeynFacet`Private`assemblyWeight[ghostCard] === -1];

referenceFile = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_05_10x10_1", "CoefficientResult.wl"
}];
reference = Get[referenceFile];

single = FeynFacet`AssembleCutContributions[{referenceFile}];
FTTest`FTAssert["B1. single-contribution assembly completes",
  AssociationQ[single] && single["Format"] === "FeynFacet-CutAssembly"];
FTTest`FTAssert["B2. same master set",
  AssociationQ[single] &&
    Sort[ToString[#["Master"], InputForm] & /@ single["Masters"]] ===
      Sort[ToString[#["Master"], InputForm] & /@ reference["Masters"]]];

referenceProducts = Association[
  ToString[#["Master"], InputForm] ->
    #["PreFactor"] #["Coefficient"] & /@ reference["Masters"]
];
FTTest`FTAssert["B3. combined coefficients equal the source products",
  AssociationQ[single] && AllTrue[
    single["Masters"],
    TrueQ @ FeynFacet`Private`exactZeroQ[
      #["Coefficient"] -
        referenceProducts[ToString[#["Master"], InputForm]]
    ] &
  ]];
FTTest`FTAssert["B4. same remainder",
  AssociationQ[single] &&
    TrueQ @ FeynFacet`Private`exactZeroQ[
      single["Remainder"] - reference["Remainder"]
    ]];

double = FeynFacet`AssembleCutContributions[
  {referenceFile, referenceFile}
];
FTTest`FTAssert["C. doubling: coefficients are 2x the source products",
  AssociationQ[double] && AllTrue[
    double["Masters"],
    TrueQ @ FeynFacet`Private`exactZeroQ[
      #["Coefficient"] -
        2 referenceProducts[ToString[#["Master"], InputForm]]
    ] &
  ]];

(* Ghost-weighted merging on a synthetic ghost-signed copy. *)
ghostified = reference;
ghostified["Setup"] = Join[
  reference["Setup"],
  <|
    "Partons" -> ghostCard["Partons"],
    "HadronMomentum" -> ghostCard["HadronMomentum"]
  |>
];
ghostPair = FeynFacet`AssembleCutContributions[{ghostified, ghostified}];
FTTest`FTAssert["D. ghost-signed pair: coefficients are -2x the products",
  AssociationQ[ghostPair] && AllTrue[
    ghostPair["Masters"],
    TrueQ @ FeynFacet`Private`exactZeroQ[
      #["Coefficient"] +
        2 referenceProducts[ToString[#["Master"], InputForm]]
    ] &
  ]];

FTTest`FTAssert["E. malformed input rejected",
  Quiet[FeynFacet`AssembleCutContributions[{<|"Format" -> "junk"|>}]] ===
    $Failed];

FTTest`FTReport[];
