$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
signSetup=<|"PartonMomentum"->({signKa,signKb}->{signP1,signP2}),
 "SetMassZero"->{signKa,signKb,signP1,signP2},
 "ForwardAmplitudes"-><|"LoopMomenta"->{}|>,"ConjugateAmplitudes"-><|"LoopMomenta"->{}|>|>;
signBounds[q_]:=Module[{d=FeynFacet`Private`safePropagatorData[signSetup,FeynCalc`SFAD[q]]},If[ListQ[d],d[[2;;3]],d]];
Scan[Function[row,FTTest`FTAssert["exact bounds "<>ToString[row[[1]],InputForm],signBounds[row[[1]]]===row[[2]]]],{
 {signKa+signKb,{1,1}},{signKa-signKb,{-1,-1}},{signP1,{0,0}},
 {signKa-signP1,{-1,0}},{signKa+signP1,{0,1}},
 {signKa-signKb+2signP1,{-3,1}}}];
FTTest`FTAssert["momentum conservation and momentum reversal preserve bounds",
 signBounds[signKa+signP1]===signBounds[-signKa-signP1]===signBounds[2signKa+signKb-signP2]];
signShifted=FeynCalc`SFAD[{{signKa+signP1,0},signS/2}];
FTTest`FTAssert["shifted quadratic cannot inherit its unshifted sign",Quiet[FeynFacet`IdentifySafePropagator[signSetup,signShifted]]===$Failed];
signNegative=FeynCalc`SFAD[I(signKa+signKb)];
signNegativeData=Quiet[FeynFacet`Private`safePropagatorData[signSetup,signNegative]];
FTTest`FTAssert["negative quadratic representation retains its sign",ListQ[signNegativeData]&&signNegativeData[[2;;3]]==={-1,-1}];
FTTest`FTAssert["identically zero is not strictly signed",Quiet[FeynFacet`IdentifySafePropagator[signSetup,FeynCalc`SFAD[signP1]]]===$Failed];
FTTest`FTAssert["mixed range is rejected",Quiet[FeynFacet`IdentifySafePropagator[signSetup,FeynCalc`SFAD[signKa-signKb+2signP1]]]===$Failed];
FTTest`FTAssert["unknown mass shell is unsupported",Quiet[FeynFacet`IdentifySafePropagator[Append[signSetup,"SetMassZero"->{signKa,signKb,signP1}],FeynCalc`SFAD[signKa+signP1]]]===$Failed];
FTTest`FTAssert["symbolic coefficients are not numerically guessed",Quiet[signBounds[signZ signKa+signP1]]===$Failed];
FTTest`FTAssert["virtual loop momentum is unsupported",Quiet[FeynFacet`IdentifySafePropagator[Append[signSetup,"ForwardAmplitudes"-><|"LoopMomenta"->{signL}|>],FeynCalc`SFAD[signKa+signL]]]===$Failed];
FeynFacet`DeclareScalar[{scalarProbe,scalarProbe^2}];scalarTypes=DownValues[FeynCalc`DataType];
FeynFacet`DeclareScalar[{scalarProbe,scalarProbe^2}];
FTTest`FTAssert["repeated scalar declarations preserve definitions",DownValues[FeynCalc`DataType]===scalarTypes&&TrueQ[FeynCalc`DataType[scalarProbe,FeynCalc`FCVariable]]];
FeynCalc`DataType[scalarProbe,FeynCalc`FCVariable]=False;
FeynFacet`DeclareScalar[scalarProbe];
FTTest`FTAssert["a removed declaration is reinstated",TrueQ[FeynCalc`DataType[scalarProbe,FeynCalc`FCVariable]]];
signFamily=<|"Topology"->FeynCalc`FCTopology[signFamilyName,
 {FeynCalc`SFAD[signKa+signKb],FeynCalc`SFAD[signKa-signKb+2signP1]},
 {signP1},{signKa,signKb},{},{}],"CutIndices"->{},
 "BaseGLI"->FeynCalc`GLI[signFamilyName,{1,0}]|>;
FTTest`FTAssert["absent mixed-sign completion slot is allowed",
 FeynFacet`Private`checkCompletedPropagators[signSetup,{signFamily}]===True];
FTTest`FTAssert["polynomial numerator at a mixed-sign slot is allowed",
 FeynFacet`Private`checkCompletedPropagators[signSetup,{signFamily},{FeynCalc`GLI[signFamilyName,{1,-1}]}]===True];
FTTest`FTAssert["a selected master cannot activate that mixed-sign slot",
 Quiet[FeynFacet`Private`checkCompletedPropagators[signSetup,{signFamily},{FeynCalc`GLI[signFamilyName,{1,1}]}]]===$Failed];
FTTest`FTAssert["unknown master family fails closed",
 FeynFacet`Private`checkCompletedPropagators[signSetup,{signFamily},{FeynCalc`GLI[signUnknown,{1,0}]}]===$Failed];
FTTest`FTAssert["incomparable sectors are not replaced by their union",
 Sort[FeynFacet`Private`ibpMaximalSectorMasks[FeynCalc`GLI[signFamilyName,#]& /@ {{1,1,0},{2,0,1},{1,0,-2}}]]===Sort[{{1,1,0},{1,0,1}}]];
FTTest`FTAssert["noninteger indices cannot be polynomial numerator support",
 FeynFacet`Private`checkCompletedPropagators[signSetup,{signFamily},{FeynCalc`GLI[signFamilyName,{1,-1/2}]}]===$Failed];
FTTest`FTAssert["a pinched cut fails support validation",
 FeynFacet`Private`checkCompletedPropagators[signSetup,{Append[signFamily,"CutIndices"->{1}]},{FeynCalc`GLI[signFamilyName,{0,-1}]}]===$Failed];
FTTest`FTAssert["symbolic sector indices fail closed",
 FeynFacet`Private`ibpMaximalSectorMasks[{FeynCalc`GLI[signFamilyName,{1,signIndex}]}]===$Failed];
FTTest`FTAssert["empty integral support requires no denominator certificate",
 FeynFacet`Private`checkCompletedPropagators[signSetup,{}]===True];
signBilinear[left_,right_,mass_:0]:=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[0,
 FeynCalc`Pair[FeynCalc`Momentum[left,D],FeynCalc`Momentum[right,D]],mass,{1,1}]];
signLinearData=FeynFacet`Private`safePropagatorData[signSetup,signBilinear[signKa,signP1]];
FTTest`FTAssert["null bilinear retains the factor one half",ListQ[signLinearData]&&signLinearData[[2;;3]]==={0,1/2}];
FTTest`FTAssert["non-null bilinear is outside the implemented half-square rule",
 Quiet[FeynFacet`IdentifySafePropagator[signSetup,signBilinear[signKa+signKb,signP1]]]===$Failed];
FTTest`FTAssert["shifted bilinear is unsupported",
 Quiet[FeynFacet`IdentifySafePropagator[signSetup,signBilinear[signKa,signP1,signS]]]===$Failed];
FTTest`FTAssert["repeated momenta and internal products are reported only once",
 FeynFacet`Private`remainingDeclaredMomenta[signKa,{signKa,signKa}]==={signKa} &&
 Length[FeynFacet`Private`internalScalarProductObjects[{FeynCalc`Pair[FeynCalc`Momentum[signKa,D],FeynCalc`Momentum[signP1,D]],FeynCalc`Pair[FeynCalc`Momentum[signKa,D],FeynCalc`Momentum[signP1,D]]}]]===1];
FTTest`FTReport[];
