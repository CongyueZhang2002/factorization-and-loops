Print["FEYNFACET DRIVER ENTERED"];$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;Clear[x,e];
normal=FeynFacet`NormalizeRegularSingularSystem[<|"Variable"->x,"DimensionalRegulator"->e,
 "ConnectionMatrix"->{{-2e/x,0},{1/x,-2e/x}}|>];
primary=FeynFacet`DecomposeResidueEigenspaces[normal];
moment=FeynFacet`ConstructFrobeniusMomentPoleMatrix[normal,primary,
 {{0,1/x}}.FeynFacet`RegularSingularGaugeMatrix[normal]];
If[FailureQ[moment],Print[InputForm[moment]];Exit[1]];
FTAssert["a logarithmic Jordan mode generates the correct double dimensional pole",
 Simplify[moment["PoleMatrix"].primary["InverseBasisTransformationMatrix"]-
  {{-1/(4e^2),-1/(2e)}}]===ConstantArray[0,{1,2}]];
sourced=FeynFacet`NormalizeRegularSingularSystem[<|"Variable"->x,"DimensionalRegulator"->e,
 "ConnectionMatrix"->{{-2e/x,0},{1,0}}|>];
sPrimary=FeynFacet`DecomposeResidueEigenspaces[sourced];
sMoment=FeynFacet`ConstructFrobeniusMomentPoleMatrix[sourced,sPrimary,
 {{0,1/x^2}}.FeynFacet`RegularSingularGaugeMatrix[sourced]];
column=First[SelectFirst[sPrimary["Eigenspaces"],#["Exponent"]===-2e&]["Columns"]];
FTAssert["higher rational poles request the sourced normal coefficient before integration",
 AssociationQ[sMoment]&&sMoment["NormalDepth"]===1&&
 Simplify[sMoment["PoleMatrix"][[1,column]]+1/(2e(1-2e))]===0];
FTAssert["unregulated endpoint amplitudes stay explicit conditions",
 Length[sMoment["UnregulatedPrimaryColumns"]]===1&&!sMoment["CompleteDimensionalMomentEstablished"]];
uniform=FeynFacet`VerifyRegulatorUniformFrobeniusExpansion[
 <|"Variable"->x,"DimensionalRegulator"->e,"ConnectionMatrix"->{{-2e/x}}|>,
 {{{1/(e^2 x^3(1+x)(1-e))}}},True];
FTAssert["fixed endpoint powers and finite regulator poles permit uniform Frobenius subtraction",
 AssociationQ[uniform]&&uniform["RegulatorUniformEndpointExpansionEstablished"]];
FTAssert["a moving endpoint layer cannot disappear into a coefficientwise finite part",
 MatchQ[FeynFacet`VerifyRegulatorUniformFrobeniusExpansion[
  <|"Variable"->x,"DimensionalRegulator"->e,"ConnectionMatrix"->{{0}}|>,
  {{{e/(x+e)^2}}},True],Failure["RegulatorDependentEndpointDivisorNotResolved",_]]];
FTAssert["an essential regulator dependence is not certified by a generic local Taylor series",
 FailureQ[FeynFacet`VerifyRegulatorUniformFrobeniusExpansion[
  <|"Variable"->x,"DimensionalRegulator"->e,"ConnectionMatrix"->{{1/e}}|>,{},True]]];
Print["FROBENIUS MOMENT POLE TEST COMPLETE"];FTReport[];
