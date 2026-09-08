
(* Translation and positive overall-scale normalization of two-center
   Euclidean integrals, followed by exact integration-domain symmetries. *)
Begin["FeynFacet`Private`"];
FeynFacet`NormalizeEuclideanIntegralScale::usage="NormalizeEuclideanIntegralScale[data] extracts the positive squared separation of two external centers and returns a canonical unit-distance integral and its exact scale factor. Loop permutations and cube reflections are exact changes of variables.";
FeynFacet`NormalizeEuclideanIntegralScale[data_Association] := Catch[Module[
 {den=data["QuadraticDenominators"],gram=Normal[data["ExternalGramMatrix"]],dim=data["LoopDimension"],
 eps=data["DimensionalRegulator"],xs=Lookup[data,"AdditionalIntegrationVariables",{}],
 powers,loops,forms,centers,origin,direction,separation,entry,shift,coordinate,normalized,vars,
 endpoint,upper,mapped,variants={},permutations,reflections,rules,trial,lp,up,canonical,key,
 coefficients,center,orientation,offset,sgn},
 loops=Length[den[[1,"SquaredForms",1,"LoopCoefficients"]]];powers=Lookup[den,"Power"];
 forms=Flatten[Lookup[den,"SquaredForms"]];
 If[!AllTrue[forms,VectorQ[#["LoopCoefficients"],NumberQ]&&VectorQ[#["ExternalCoefficients"],NumberQ]&],
  boundaryIntegrationFail["ExactEuclideanCoefficientVectorsRequired"]];
 centers=DeleteDuplicates[(#["ExternalCoefficients"]/Total[#["LoopCoefficients"]])&/@
   Select[forms,Total[#["LoopCoefficients"]]=!=0&]];
 If[Length[centers]=!=2,boundaryIntegrationFail["TwoExternalEuclideanCentersRequired"]];
 {origin,direction}={First[centers],Last[centers]-First[centers]};
 separation=Cancel[Together[direction.gram.direction]];
 If[!NumberQ[separation]||!TrueQ[separation>0],boundaryIntegrationFail["PositiveEuclideanSquaredScaleRequired"]];
 normalized=Table[<|"Power"->d["Power"],"SquaredForms"->Table[
   shift=f["ExternalCoefficients"]-Total[f["LoopCoefficients"]]origin;
   coordinate=Cancel[Together[shift.gram.direction/separation]];
   If[!AllTrue[Map[Cancel[Together[#]]&,shift-coordinate direction],#===0&],
    boundaryIntegrationFail["EuclideanCentersNotOnOneAffineLine"]];
   <|"Weight"->Lookup[f,"Weight",1],"LoopCoefficients"->f["LoopCoefficients"],
    "ExternalCoefficients"->{coordinate}|>,
   {f,d["SquaredForms"]}]|>,{d,den}];
 vars=Table[Symbol["FeynFacetEuclideanCoordinates`parameter"<>ToString[j]],{j,Length[xs]}];
 normalized=normalized/.Thread[xs->vars];
 endpoint=Lookup[data,"EndpointPowers",ConstantArray[0,Length[xs]]];
 upper=Lookup[data,"UpperEndpointPowers",ConstantArray[0,Length[xs]]];
 permutations=If[loops<=3,Permutations[Range[loops]],{Range[loops]}];
 reflections=If[Length[xs]<=3,Tuples[{False,True},Length[xs]],{ConstantArray[False,Length[xs]]}];
 Do[
  rules=MapThread[#1->If[#2,1-#1,#1]&,{vars,reflection}];
  lp=MapThread[If[#3,#2,#1]&,{endpoint,upper,reflection}];
  up=MapThread[If[#3,#1,#2]&,{endpoint,upper,reflection}];
  trial=Table[<|"Power"->d["Power"],"SquaredForms"->SortBy[Table[
    coefficients=f["LoopCoefficients"][[permutation]];coordinate=First[f["ExternalCoefficients"]];
    offset=If[orientation===0,coordinate,Total[coefficients]-coordinate];
    sgn=Sign[SelectFirst[Join[coefficients,{offset}],#=!=0&,1]];
    <|"Weight"->Expand[f["Weight"]/.rules],"LoopCoefficients"->sgn coefficients,
      "ExternalCoefficients"->{sgn offset}|>,
    {f,d["SquaredForms"]}],ToString[#,InputForm]&]|>,{d,normalized}];
  trial=SortBy[trial,ToString[#,InputForm]&];
  AppendTo[variants,{trial,lp,up}],
 {permutation,permutations},{reflection,reflections},{orientation,0,1}];
 canonical=First[SortBy[variants,ToString[#,InputForm]&]];
 key={"EuclideanUnitDistanceIntegral",dim,canonical};
 <|"DataType"->"EuclideanScaleNormalization","IntegralEquivalenceKey"->key,
 "IntegralScaleFactor"->Lookup[data,"Prefactor",1]separation^(loops dim/2-Total[powers]),
 "SquaredExternalScale"->separation,"OriginalExternalOrigin"->origin,"OriginalExternalDirection"->direction,
 "NormalizedIntegralInput"-><|"DimensionalRegulator"->eps,"LoopDimension"->dim,"ExternalGramMatrix"->{{1}},
  "QuadraticDenominators"->canonical[[1]],"AdditionalIntegrationVariables"->vars,
  "EndpointPowers"->canonical[[2]],"UpperEndpointPowers"->canonical[[3]],"Prefactor"->1|>,
 "NormalizationChanged"->False|>
 ],"BoundaryIntegration"];
End[];
