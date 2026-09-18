(* Physical branch and color identities in generated Born normalization. *)
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
bornRegionConfig=<|"CoefficientKinematics"-><|
 "DimensionlessCoordinates"-><|bx->-bt/bs,by->-bu/bs|>,
 "PhysicalRegion"->bx>0&&by>0&&bx+by==1,
 "PositiveFractions"->{ba,bb}|>|>;
bornRegion=FeynFacet`Private`coefficientKinematicsAssumptions[bornRegionConfig];
FTTest`FTAssert["dimensionless region becomes an evaluated invariant condition",
 FreeQ[bornRegion,bx|by|_Association]&&
 TrueQ[bornRegion/.{bs->5,bt->-2,bu->-3,ba->1/3,bb->2/3}]];
FTTest`FTAssert["declared region rejects off-support Born invariants",
 (bornRegion/.{bs->5,bt->-2,bu->-2,ba->1/3,bb->2/3})===False];
bornPower=Sqrt[bs ba/bb] (bs bb)^(-3/2);
bornNormalized=FeynFacet`Private`expandPositiveMonomialPowers[bornPower,bs>0&&ba>0&&bb>0];
FTTest`FTAssert["positive monomial powers combine without expanding sums",
 Factor[bornNormalized-Sqrt[ba]/(bs bb^2)]===0];
FTTest`FTAssert["unknown branches are left untouched",
 FeynFacet`Private`expandPositiveMonomialPowers[Sqrt[ba bb],True]===Sqrt[ba bb]];
FTTest`FTAssert["two negative factors do not split onto wrong principal branches",
 FeynFacet`Private`expandPositiveMonomialPowers[Sqrt[ba bb],ba<0&&bb<0]===Sqrt[ba bb]];
bornProject=FeynFacet`ReadProjectCard[root<>"/Projects/ppHX_UU"];
bornRequest=FeynFacet`ProjectAssemblyRequest[bornProject,"u-ub_g-g","Born"];
FTTest`FTAssert["Born request inherits the declared color identities",
 bornRequest["ColorRules"]===bornProject["ColorRules"]];
{bornSeconds,bornFresh}=AbsoluteTiming[FeynFacet`ConstructBornResult[
 FeynFacet`ReadProcessCard[root<>"/Projects/ppHX_UU/Raw/LO/u-ub_g-g","Born"],
 Join[bornRequest,<|"EpsilonRange"->{0,1},"BornCouplingPower"->2|>]]];
FTTest`FTAssert["observed-gluon Born has no PDF fraction or reference-coordinate dependence through epsilon one",
 AssociationQ[bornFresh]&&FreeQ[bornFresh["Coefficients"],xa|xb|zh|_SeriesData|$Aborted|$Failed]];
bornColor=FeynCalc`CA;
bornExpected=-(bornColor^2-1)(1-2v+2v^2)*
 (bornColor^2-1-2bornColor^2 v+2bornColor^2 v^2)*
 \[Alpha]s^2/(2bornColor^3 s^2(v-1)v^2);
FTTest`FTAssert["qqb to gg Born retains its exact invariant normalization",
 AssociationQ[bornFresh]&&Factor[bornFresh["Coefficients"][0]["DeltaCoefficient"]-bornExpected]===0];
Print["BORN_NORMALIZATION_SECONDS ",bornSeconds];
FTTest`FTReport[];
