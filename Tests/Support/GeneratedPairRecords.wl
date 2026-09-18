(* Small physical pair inputs generated afresh; no saved calculation is a fixture. *)
BeginPackage["FeynFacetTestPairs`"];
GeneratePairTestRecords::usage="GeneratePairTestRecords[root,directory] generates two tree interference records from the retained declaration card.";
Begin["`Private`"];
GeneratePairTestRecords[root_String,directory_String] := Module[{card,generated,rows},
 card=FeynFacet`ReadContributionCard[root<>"/Projects/ppHX_UU/Raw/NLO/qqp-qqp","Real"];
 If[!AssociationQ[card],Return[$Failed]];
 card=Join[card,<|"DiagramIndices"->{{1},{1,2}},"WorkDirectory"->directory,
   "Execution"->Join[card["Execution"],<|"Kernels"->1|>]|>];
 generated=FeynFacet`GenerateContributionPairArtifacts[card,"all"];
 If[!AssociationQ[generated]||Length[generated["PairFiles"]]=!=2,Return[$Failed]];
 rows=FeynFacet`FamilyArtifactRead/@generated["PairFiles"];
 If[AllTrue[rows,AssociationQ],rows,$Failed]
];
End[];EndPackage[];
