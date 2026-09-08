
(* Rational sampling selects candidate constant linear relations; every
   returned identity is then verified over the exact rational-function field. *)
Begin["FeynFacet`Private`"];
FeynFacet`FindBoundaryIntegrandRelations::usage="FindBoundaryIntegrandRelations[expressions,variables,opts] finds and exactly verifies rational constant linear identities among explicit boundary integrands.";
Options[FeynFacet`FindBoundaryIntegrandRelations]={"SampleCount"->Automatic,"RandomSeed"->417,"IdentityTimeLimit"->30};
FeynFacet`FindBoundaryIntegrandRelations[expressions_List,variables_List,OptionsPattern[]] := Catch[Module[
 {n=Length[expressions],count=OptionValue["SampleCount"],samples={},points={},candidate,
  values,relations,verified={},residuals={},point,attempt=0,coefficients,value},
 If[n<1||!VectorQ[variables,MatchQ[#,_Symbol]&],boundaryIntegrationFail["RationalIntegrandListRequired"]];
 If[!AllTrue[expressions,And@@(PolynomialQ[#,variables]&/@NumeratorDenominator[Together[#]])&],
  boundaryIntegrationFail["RationalBoundaryIntegrandsRequired"]];
 If[count===Automatic,count=n+12];
 BlockRandom[SeedRandom[OptionValue["RandomSeed"]];
  While[Length[samples]<count&&attempt<10count,
   attempt++;point=Table[RandomInteger[{2,29}]/RandomInteger[{31,71}],{Length[variables]}];
   values=expressions/.Thread[variables->point];
   If[!VectorQ[values,MatchQ[#,_Integer|_Rational]&],Continue[]];
   AppendTo[samples,values];AppendTo[points,point]]];
 If[Length[samples]<count,boundaryIntegrationFail["InsufficientRegularIntegrandSamples"]];
 relations=NullSpace[samples];
 Do[
  value=TimeConstrained[Cancel[Together[coefficients.expressions]],OptionValue["IdentityTimeLimit"],$TimedOut];
  AppendTo[residuals,value===0];If[value===0,AppendTo[verified,coefficients]],
 {coefficients,relations}];
 <|"DataType"->"BoundaryIntegrandLinearRelations","RelationMatrix"->verified,
   "SampledRank"->MatrixRank[samples],"CandidateRelationCount"->Length[relations],
   "ExactlyVerifiedRelationCount"->Length[verified],"ExactResidualChecks"->residuals,
   "SamplePoints"->points,"Scope"->"Identities of the supplied rational integrands. Their physical domain and common measure must be supplied separately."|>
 ],"BoundaryIntegration"];
End[];
