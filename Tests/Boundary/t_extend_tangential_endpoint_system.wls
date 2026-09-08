#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[exZ,exV,exE];
exZero[x_]:=FeynFacet`Private`tangentialEndpointZeroQ[x];
exRequest=<|"MaximumNormalOrder"->0,"AnalyticDomain"->"0<v<1; 0<z<1",
 "BranchPrescription"->"Positive real z, continuation from v=1/4"|>;
exBase=ConstructTangentialEndpointSystem[
 <|"NormalVariable"->exZ,"TangentialVariable"->exV,"DimensionalRegulator"->exE,
   "NormalConnectionMatrix"->{{(exE-2)/exZ+exE/(1-exZ)}},
   "TangentialConnectionMatrix"->{{0}}|>,exRequest,
 "NormalGaugeMatrix"->{{exZ^-2}}];
exResult=ExtendTangentialEndpointSystem[exBase,3];
exExpected={1,exE,exE(exE+1)/2,exE(exE+1)(exE+2)/6};
FTAssert["new normal coefficients equal the analytic binomial expansion",
 AssociationQ[exResult] && exZero[
   exResult["PrimarySectors"][[1]]["NormalizedCoefficients"][[All,1,1,1]]-exExpected]];
FTAssert["the Laurent gauge shifts the original coefficient rectangle exactly",
 exResult["OriginalNormalOrderRange"]==={-2,1} &&
 exZero[exResult["PrimarySectors"][[1]]["OriginalCoefficients"][[All,1,1,1]]-exExpected]];
exKeys={"NormalGaugeMatrix","InverseNormalGaugeMatrix","NormalizedNormalConnectionMatrix",
 "NormalizedTangentialConnectionMatrix","NormalResidue","TangentialConnectionMatrix"};
FTAssert["accepted gauges and both connections are reused unchanged",
 Lookup[exResult,exKeys]===Lookup[exBase,exKeys]];
exPartial=ExtendTangentialEndpointSystem[exBase,1];
exContinued=ExtendTangentialEndpointSystem[exPartial,3];
FTAssert["continuing existing jets preserves them and agrees with direct extension",
 exContinued["PrimarySectors"]===exResult["PrimarySectors"] &&
 exContinued["ExtensionVerification"]["VerifiedNewNormalOrders"]==={2,3}];
exS={{1,0},{exV,1}};exR=exS.{{exE,1},{0,exE}}.Inverse[exS];
exMoving=ConstructTangentialEndpointSystem[
 <|"NormalVariable"->exZ,"TangentialVariable"->exV,"DimensionalRegulator"->exE,
   "NormalConnectionMatrix"->exR/exZ+exE IdentityMatrix[2]/(1-exZ),
   "TangentialConnectionMatrix"->D[exS,exV].Inverse[exS]|>,exRequest,
 "NormalGaugeMatrix"->IdentityMatrix[2]];
exMoved=ExtendTangentialEndpointSystem[exMoving,2];
FTAssert["moving noncommuting Jordan logarithms obey the new tangential equations",
 AssociationQ[exMoved] && exMoved["PrimarySectors"][[1]]["NilpotencyIndex"]===2 &&
 exZero[exMoved["PrimarySectors"][[1]]["NormalizedCoefficients"][[3,2]]-
   exE(exE+1)(exR-exE IdentityMatrix[2])/2] &&
 exMoved["ExtensionVerification"]["TangentialCoefficientEquations"]];
FTAssert["extension requires an accepted record and a nondecreasing order",
 FailureQ[ExtendTangentialEndpointSystem[exBase,-1]] &&
 FailureQ[ExtendTangentialEndpointSystem[KeyDrop[exBase,"Verification"],2]]];
FTReport[];
