Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
phase=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->tangentPhase,
 "FinalMomenta"->{p1,p2,p3},"TotalMomentum"->q,"ExternalMomenta"->{q},
 "KinematicRules"->{FeynCalc`SPD[q]->s},"Assumptions"->s>0|>];
prepared=FeynFacet`PrepareCutIntegrand[FeynCalc`FCI[FeynCalc`SFAD[p1+p2]^2],phase,
 <|"ExternalKinematicConditions"->s>0|>];
data=FeynFacet`DecomposeMeasuredCutIntegrand[prepared];family=First[data["Families"]];
vectors=FeynFacet`ConstructCutCompatibleIBPVectors[family,<|"Degree"->1|>];
If[FailureQ[vectors],Print[InputForm[vectors]]];
FTTest`FTAssert["bounded momentum-space nullspace yields exact individually tangent vectors",
 AssociationQ[vectors]&&Length[vectors["Operators"]]>0&&
 AllTrue[Flatten[Lookup[vectors["VectorCertificates"],"TangencyResiduals"]],#===0&]];
rows=If[AssociationQ[vectors],FeynFacet`GenerateCutCompatibleIBPEquations[family,data["Targets"],vectors],$Failed];
FTTest`FTAssert["protected particle-cut powers never increase in the generated equations",
 AssociationQ[rows]&&AllTrue[Flatten[Keys/@rows["Rows"]],
  #[[2,family["ParticleCutIndices"]]]===ConstantArray[1,Length[family["ParticleCutIndices"]]]&]];
(* Independently reconstruct each momentum vector's divergence from its
   polynomial coefficients, before any inverse-denominator substitution. *)
ops=FeynFacet`Private`cutIBPOperators[family];vars=family["DenominatorVariables"];
velocities=Map[(Total[Last[#]Times@@MapThread[Power,{vars,First[#]}]&/@#]&/@#["DenominatorDerivativeMonomials"])&,ops];
divergences=Map[Function[proof,Module[{cs=proof["MomentumVectorCoefficients"]/.family["ScalarProductRules"]},
 Sum[If[vectors["MomentumVectorBasis"][[i,1]]===vectors["MomentumVectorBasis"][[i,2]],D cs[[i]],0]+
  Sum[D[cs[[i]],vars[[j]]]velocities[[i,j]],{j,Length[vars]}],{i,Length[cs]}]]],vectors["VectorCertificates"]];
FTTest`FTAssert["polynomial coefficient derivatives contribute to the full vector divergence",
 And@@MapThread[Cancel[Together[#1-(#2/.family["ScalarProductRules"])]]===0&,
  {divergences,Lookup[vectors["VectorCertificates"],"Divergence"]}]];
rowComparisons=Table[
 expectedRows={};cs=vectors["VectorCertificates"][[v]]["MomentumVectorCoefficients"]/.family["ScalarProductRules"];
 Do[Do[powers=First[data["Targets"]][[2]]-First[term];
  If[Min[powers[[family["CutIndices"]]]]<=0,Continue[]];
  one=FeynFacet`Private`cutGenerateIBPEquations[family,{FeynCalc`GLI[family["Topology"][[1]],powers]},{ops[[i]]}];
  expectedRows=Join[expectedRows,(Map[Last[term]#&,#]&/@one["Rows"])],
  {term,CoefficientRules[cs[[i]],vars]}],{i,Length[cs]}];
 actual=FeynFacet`Private`cutGenerateIBPEquations[family,{First[data["Targets"]]},{vectors["Operators"][[v]]}];
 difference=Merge[Join[expectedRows,Map[Map[-#&,#]&,actual["Rows"]]],Total];
 AllTrue[Values[difference],Cancel[Together[#]]===0&],{v,Length[vectors["Operators"]]}];
FTTest`FTAssert["cofactor equations equal ordinary total derivatives of polynomial-shifted seeds",
 AllTrue[rowComparisons,TrueQ]];
FTTest`FTAssert["a bounded vector search makes no completeness or dot-removal claim",
 !vectors["CompleteSyzygyModuleEstablished"]&&!vectors["ExistingCutDotsRemoved"]];
Print["CUT COMPATIBLE VECTORS TEST COMPLETE"];FTTest`FTReport[];
