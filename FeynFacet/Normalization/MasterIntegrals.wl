(* Convert precisely declared physical and normalized loop/cut measures. *)
BeginPackage["FeynFacet`"];
MasterIntegralMeasureConversion::usage =
 "MasterIntegralMeasureConversion[definition] returns the factor converting the physical momentum-space master in definition to the normalized GLI measure used by the coefficient tables.";
Begin["`Private`"];
FeynFacet`MasterIntegralMeasureConversion[definition_Association] := Module[
 {dim=Lookup[definition,"Dimension",None],phase=Lookup[definition,"PhaseSpaceLoopCount",None],
  prescription=Lookup[definition,"Prescription",None],measure=Lookup[definition,"MeasurePrefactor",None],
  extra=Lookup[definition,"MasterIntegralPrefactor",1],negative},
 If[!IntegerQ[phase]||phase<0||!ListQ[prescription]||
   !AllTrue[prescription,MemberQ[{-1,0,1},#]&]||Count[prescription,0]=!=phase||
   dim===None||measure===None||measure===0||extra===0,
  Return[Failure["MasterMeasureDefinitionIncomplete",<||>]]];
 negative=Count[prescription,-1];
 <|"Factor"->1/(I Pi^(dim/2))^Length[prescription]/measure/extra,
   "FromConvention"->"PhysicalMomentumSpaceMaster",
   "ToConvention"->"NormalizedGLICoefficientIntegral",
   "PhaseSpaceLoopCount"->phase,"NegativePrescriptionLoopCount"->negative|>
 ];
End[];EndPackage[];
