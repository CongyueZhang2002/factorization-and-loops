#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[pvZ,pvV,pvE];
pvS={{1,pvV},{pvV,1}};
pvR=Simplify[pvS.DiagonalMatrix[{pvE,1+pvE}].Inverse[pvS]];
pvB=Simplify[D[pvS,pvV].Inverse[pvS]];
pvResult=ConstructTangentialEndpointSystem[
 <|"NormalVariable"->pvZ,"TangentialVariable"->pvV,"DimensionalRegulator"->pvE,
   "NormalConnectionMatrix"->pvR/pvZ,"TangentialConnectionMatrix"->pvB|>,
 <|"MaximumNormalOrder"->1,"AnalyticDomain"->"0<v<1",
   "BranchPrescription"->"Positive z and continuation from v=1/4"|>,
 "ParameterVerificationRules"->{pvV->1/4}];
pvZero[x_]:=FeynFacet`Private`tangentialEndpointZeroQ[x];
FTAssert["normal gauge remains symbolic after parameter-specialized checks",
 AssociationQ[pvResult] && !FreeQ[pvResult["NormalGaugeMatrix"],pvV]];
FTAssert["the moving gauge derivative is retained in the tangential connection",
 AssociationQ[pvResult] && pvZero[pvResult["TangentialConnectionMatrix"]-pvB]];
FTAssert["the composed inverse factors invert the complete symbolic gauge",
 AssociationQ[pvResult] && pvZero[pvResult["NormalGaugeMatrix"].
   pvResult["InverseNormalGaugeMatrix"]-IdentityMatrix[2]]];
FTAssert["normalized residue and finite equations remain exact symbolic identities",
 AssociationQ[pvResult] && pvZero[pvResult["NormalResidue"]-pvE IdentityMatrix[2]] &&
 pvResult["Verification"]["TangentialCoefficientEquations"]];
pvVerification=pvResult["NormalGaugeConstructionVerification"]["EndpointNormalization"];
FTAssert["sampled inner checks are labeled and specify the tangential parameter",
 pvVerification["ExactIdentity"]===False &&
 pvVerification["ParameterVerificationRules"]==={pvV->1/4} &&
 AllTrue[pvVerification["Points"],MemberQ[#,pvV->1/4]&]];
pvFactors=<|"Variable"->pvZ,"Dimension"->3,"GaugeFactors"->{
 <|"Type"->"BlockDiagonal","Rows"->{{1},{2},{3}},
   "Matrices"->{{{pvZ}},{{1/pvZ}},{{1}}},
   "InverseMatrices"->{{{1/pvZ}},{{pvZ}},{{1}}}|>,
 <|"Type"->"OffDiagonal","Rows"->{2},"Columns"->{1},
   "Power"->-1,"Matrix"->{{pvV}}|>,
 <|"Type"->"OffDiagonal","Rows"->{3},"Columns"->{2},
   "Power"->-2,"Matrix"->{{1+pvV}}|>}|>;
FTAssert["noncommuting shear inverses are composed in reverse product order",
 pvZero[FeynFacet`Private`RegularSingularInverseGaugeMatrix[pvFactors].
   FeynFacet`RegularSingularGaugeMatrix[pvFactors]-IdentityMatrix[3]]];
FTReport[];
