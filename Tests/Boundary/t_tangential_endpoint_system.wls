#!/usr/bin/env wolframscript
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];
Get[FileNameJoin[{root,"FeynFacet","Boundary","TangentialSystem.wl"}]];
Clear[tepZ,tepV,tepE];
tepRequest=<|"MaximumNormalOrder"->2,"AnalyticDomain"->"0<v<1, 0<z<1-v away from the corners.",
 "BranchPrescription"->"Positive z and v with real logarithms, continued from v=1/4."|>;
tepSystem[a_,b_]:=<|"NormalVariable"->tepZ,"TangentialVariable"->tepV,
 "DimensionalRegulator"->tepE,"NormalConnectionMatrix"->a,"TangentialConnectionMatrix"->b|>;
tepZero[x_]:=FeynFacet`Private`tangentialEndpointZeroQ[x];

tepScalar=ConstructTangentialEndpointSystem[
 tepSystem[{{(1+tepE)/tepZ+tepV}},{{(1+tepE)/tepV+tepZ}}],tepRequest];
Print["scalar constructor: ",If[FailureQ[tepScalar],tepScalar,tepScalar["Status"]]];
FTAssert["symbolic normal normalization and nonzero tangential evolution",
 AssociationQ[tepScalar] && tepZero[tepScalar["NormalResidue"]-{{tepE}}] &&
 tepZero[tepScalar["TangentialConnectionMatrix"]-{{(1+tepE)/tepV}}]];
FTAssert["finite endpoint coefficients retain symbolic v",
 AssociationQ[tepScalar] && tepZero[tepScalar["PrimarySectors"][[1,"OriginalCoefficients"]]-
 {{{{1}}},{{{tepV}}},{{{tepV^2/2}}}}]];

tepMoving={{1,tepV},{0,1}};
tepJordan={{tepE,0},{1,tepE}};
tepR=Simplify[tepMoving.tepJordan.Inverse[tepMoving]];
tepGamma=D[tepMoving,tepV].Inverse[tepMoving];
tepResonant=ConstructTangentialEndpointSystem[tepSystem[tepR/tepZ,tepGamma],
 tepRequest,"NormalGaugeMatrix"->IdentityMatrix[2]];
FTAssert["noncommuting varying residue has a horizontal boundary DE",
 AssociationQ[tepResonant] && !tepZero[tepR.D[tepR,tepV]-D[tepR,tepV].tepR] &&
 tepResonant["PrimarySectors"][[1,"NilpotencyIndex"]]===2];
FTAssert["Jordan logarithm and epsilon exponent are preserved exactly",
 AssociationQ[tepResonant] && tepResonant["PrimarySectors"][[1,"Exponent"]]===tepE &&
 tepZero[tepResonant["PrimarySectors"][[1,"NormalizedCoefficients",1,2]]-
 (tepR-tepE IdentityMatrix[2])]];

tepReference=<|"TangentialBasePoint"->1/4,
 "NormalizedDifferentialSystem"-><|"Variable"->tepZ,"DimensionalRegulator"->tepE,
   "ConnectionMatrix"->tepJordan/tepZ|>,
 "OriginalToNormalizedGauge"->Inverse[tepMoving/.tepV->1/4],
 "SeedMatrix"->{{1,1},{0,1}}|>;
tepMatch=MatchTangentialEndpointBoundaryBasis[tepResonant,tepReference];
FTAssert["physical reference maps the full seed before selecting constants",
 AssociationQ[tepMatch] && tepZero[tepMatch["AmplitudeToInitialVectorMatrix"]-
  (tepMoving/.tepV->1/4).tepReference["SeedMatrix"]]];
tepSolution=ConstructTangentialEndpointSolution[tepResonant,
 <|"TangentialBasePoint"->1/4,"EpsilonOrderRange"->{0,1},
 "PhysicalBoundaryValues"-><|"BoundaryBasisMatching"->tepMatch,
   "AmplitudeLaurentLowerBounds"->{0,0},
   "AmplitudeCoefficients"-><|{1,0}->2,{1,1}->3,{2,0}->5,{2,1}->7|>|>|>];
Print["finite constructor: ",If[FailureQ[tepSolution],tepSolution,tepSolution["Status"]]];
FTAssert["physical finite tangential functions have no unknown constants",
 AssociationQ[tepSolution] && tepSolution["PhysicalBoundaryValuesApplied"] &&
 FreeQ[tepSolution["EndpointTerms"],FeynFacetSolution`C[__]]];
tepExpand[expression_,record_]:=Module[{value=expression,aa,ff,kk},
 aa=record["AlgebraicDefinitions"];ff=record["IntegralDefinitions"];
 Do[value=value/.FeynFacetSolution`a[j]->aa[[j]],{j,Length[aa],1,-1}];
 Do[With[{f=ff[[j]]},value=value/.FeynFacetSolution`F[j,u_]:>
   Inactive[Integrate][f["Integrand"],{f["IntegrationVariable"],0,u}]],
   {j,Length[ff],1,-1}];
 kk=FeynFacet`Private`solutionResolveKernelDefinitions[record["KernelDefinitions"]];
 value=value/.FeynFacetSolution`K[j_Integer,u_]:>
   (kk[[j]]/.record["KernelDefinitions"][[j,"Parameter"]]->u);
 Simplify[Activate[value]]];
FTAssert["finite physical tangential functions equal the analytic moving-basis solution",
 AssociationQ[tepSolution] &&
 tepZero[tepExpand[tepSolution["EndpointTerms"][[1,"Coefficients",Key[0]]],tepSolution]-{7+5 tepV,5}] &&
 tepZero[tepExpand[tepSolution["EndpointTerms"][[2,"Coefficients",Key[1]]],tepSolution]-{10 tepV,10}]];
tepMissing=ConstructTangentialEndpointSolution[tepResonant,
 <|"TangentialBasePoint"->1/4,"EpsilonOrderRange"->{0,1},
 "PhysicalBoundaryValues"-><|"BoundaryBasisMatching"->tepMatch,
   "AmplitudeLaurentLowerBounds"->{0,0},
   "AmplitudeCoefficients"-><|{1,0}->2,{2,0}->5|>|>|>];
FTAssert["missing physical epsilon orders are explicit failures",
 MatchQ[tepMissing,Failure["PhysicalEndpointAmplitudeOrderMissing",_]]];

tepInteger=ConstructTangentialEndpointSystem[
 tepSystem[{{0,0},{1,1/tepZ}},ConstantArray[0,{2,2}]],tepRequest];
Print["integer resonance constructor: ",If[FailureQ[tepInteger],tepInteger,tepInteger["Status"]]];
FTAssert["integer resonance is moved into a retained logarithmic Jordan mode",
 AssociationQ[tepInteger] && Max[Lookup[tepInteger["PrimarySectors"],"NilpotencyIndex"]]===2];
tepBad=ConstructTangentialEndpointSystem[
 tepSystem[{{0,0},{0,1/tepZ}},{{0,1/tepZ},{0,0}}],tepRequest,
 "NormalGaugeMatrix"->IdentityMatrix[2]];
FTAssert["a singular tangential restriction is not projected away",
 MatchQ[tepBad,Failure["TangentialEndpointPoleRequiresCoefficientStateConstruction",_]]];
tepBad=ConstructTangentialEndpointSystem[
 tepSystem[{{tepE/tepZ}},{{tepZ}}],tepRequest];
FTAssert["nonflat input is rejected",MatchQ[tepBad,Failure["EndpointConnectionNotFlat",_]]];

tepNegative=ConstructTangentialEndpointSystem[
 tepSystem[tepE IdentityMatrix[2]/tepZ,{{0,1/tepE},{0,0}}],
 Join[tepRequest,<|"MaximumNormalOrder"->0|>],"NormalGaugeMatrix"->tepE IdentityMatrix[2]];
tepNegativeSolution=ConstructTangentialEndpointSolution[tepNegative,
 <|"TangentialBasePoint"->1/4,"EpsilonOrderRange"->{0,0},
 "InitialConstantLaurentLowerBounds"->{0,0}|>];
FTAssert["negative epsilon connection paths lower symbolic-v coefficient bounds",
 AssociationQ[tepNegativeSolution] &&
 tepNegativeSolution["TangentialFunctionLaurentLowerBounds"]==={-1,0} &&
 tepZero[tepExpand[tepNegativeSolution["EndpointTerms"][[1,"Coefficients",Key[0]]],tepNegativeSolution]-
  {(tepV-1/4)FeynFacetSolution`C[2,0],0}]];

tepSource=Get[FileNameJoin[{root,"Projects","ppHX_UU_NNLO","NNLO","qqp-qqp","Results","DoubleReal","UU_08_10_canonical",
 "Stage1And2_2026-09-06","CF198","FamilyDifferentialSystem.wl"}]];
{tepSourceV,tepSourceW}=tepSource["KinematicVariables"];
tepSourceE=tepSource["DimensionalRegulator"];
tepRows={8};
tepNormal=-tepSource["ConnectionMatrices"][[2,tepRows,tepRows]];
tepTangent=Subtract@@tepSource["ConnectionMatrices"][[All,tepRows,tepRows]];
tepRules={tepSourceV->tepV,tepSourceW->1-tepV-tepZ,tepSourceE->tepE};
tepProcess=ConstructTangentialEndpointSystem[
 tepSystem[tepNormal/.tepRules,tepTangent/.tepRules],tepRequest];
FTAssert["current-process phase-space block has exponent 1-2 epsilon and constant angle amplitude",
 AssociationQ[tepProcess] && tepZero[tepProcess["NormalGaugeMatrix"]-{{tepZ}}] &&
 tepZero[tepProcess["TangentialConnectionMatrix"]] &&
 tepProcess["PrimarySectors"][[1,"Exponent"]]===-2 tepE];
tepOut=FileNameJoin[{root,"Projects","ppHX_UU_NNLO","NNLO","qqp-qqp","Results","Assembly","TangentialEndpoint_2026-09-07"}];
If[!DirectoryQ[tepOut],CreateDirectory[tepOut,CreateIntermediateDirectories->True]];
Put[<|"ScalarSystem"->tepScalar,"MovingJordanSystem"->tepResonant,
 "PhysicalBoundaryMatching"->tepMatch,"FinitePhysicalSolution"->tepSolution,
 "IntegerResonance"->tepInteger,"CF198PhaseSpaceBlock"->tepProcess|>,tepOut<>"/focused_examples.wl.tmp"];
RenameFile[tepOut<>"/focused_examples.wl.tmp",tepOut<>"/focused_examples.wl",OverwriteTarget->True];
FTReport[];
