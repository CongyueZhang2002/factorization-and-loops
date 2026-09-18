Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
olrMomenta={olrL,olrL+olrP,olrL+olrP+olrQ,olrL+olrP+olrQ+olrR};
olrKin=FeynCalc`FCI[{FeynCalc`SPD[olrP]->0,FeynCalc`SPD[olrQ]->0,FeynCalc`SPD[olrR]->0,
 FeynCalc`SPD[olrP,olrQ]->olrS/2,FeynCalc`SPD[olrQ,olrR]->olrT/2,
 FeynCalc`SPD[olrP,olrR]->(-olrS-olrT)/2}];
olrDefinition=<|"LoopMomenta"->{olrL},"DimensionalRegulator"->olrE,"Dimension"->4-2olrE,
 "PropagatorPowers"->{1,1,1,1},"CutIndices"->{},"Prescription"->{1},
 "PropagatorTypes"->ConstantArray["QuadraticLorentzian",4],"PropagatorMomenta"->olrMomenta,
 "KinematicRules"->olrKin,"KinematicConditions"->olrS>0&&olrT<0&&olrS+olrT>0,
 "InversePropagators"->(FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[#]]]/.olrKin&/@olrMomenta),
 "MeasurePrefactor"->1/(I Pi^(2-olrE)),"MasterIntegralPrefactor"->1,
 "MasterIntegral"->FeynCalc`GLI["GeometricMasslessBox",{1,1,1,1}]|>;
olrPositive=FeynFacet`EvaluateOneLoopIntegral[olrDefinition,{-2,1}];
If[!AssociationQ[olrPositive],Print[olrPositive]];
FTTest`FTAssert["momentum geometry evaluates a massless box through the requested positive epsilon order",
 AssociationQ[olrPositive]&&olrPositive["KnownThroughOrder"]===1&&Keys[olrPositive["Coefficients"]]===Range[-2,1]&&
 FreeQ[olrPositive["Coefficients"],_Integrate|_SeriesData|_SeriesCoefficient|_Hypergeometric2F1|_Failure]];
olrPoint={olrS->5,olrT->-2};
olrLs=Log[olrS]-I Pi;olrLt=Log[-olrT];
olrGamma=Gamma[1+olrE]Gamma[1-olrE]^2/Gamma[1-2olrE];
olrFinite=Normal[Series[2olrGamma/(olrS olrT)*
 ((Exp[-olrE olrLs]+Exp[-olrE olrLt])/olrE^2-(olrLs-olrLt)^2/2-Pi^2/2),{olrE,0,0}]];
FTTest`FTAssert["the all-order box agrees with the infrared pole and finite on-shell formula",
 AssociationQ[olrPositive]&&AllTrue[Range[-2,0],
  Abs[N[olrPositive["Coefficients"][#]/.olrPoint,40]-
    N[Coefficient[Expand[olrE^2 olrFinite],olrE,#+2]/.olrPoint,40]]<10^-30&]];
olrNegative=FeynFacet`EvaluateOneLoopIntegral[Join[olrDefinition,
 <|"Prescription"->{-1},"MeasurePrefactor"->-1/(I Pi^(2-olrE))|>],{-2,1}];
FTTest`FTAssert["the negative loop prescription conjugates every computed Laurent coefficient",
 AssociationQ[olrNegative]&&AllTrue[Range[-2,1],
  Abs[N[olrNegative["Coefficients"][#]/.olrPoint,40]-Conjugate[N[olrPositive["Coefficients"][#]/.olrPoint,40]]]<10^-30&]];
olrShifted=FeynFacet`WithEpsilonRemainderChecks[FeynFacet`EvaluateOneLoopIntegral[
 Join[olrDefinition,<|"MasterIntegralPrefactor"->(1+olrE)/olrE|>],{-3,0}]];
FTTest`FTAssert["a master normalization pole demands the extra box order before multiplication",
 AssociationQ[olrShifted["Result"]]&&olrShifted["EpsilonRemainderAudit"]["Status"]==="Passed"&&
 olrShifted["Result"]["LaurentLowerBound"]===-3&&
 Abs[N[olrShifted["Result"]["Coefficients"][0]/.olrPoint,40]-
   N[(olrPositive["Coefficients"][0]+olrPositive["Coefficients"][1])/.olrPoint,40]]<10^-30];
olrBeyond=FeynFacet`EvaluateOneLoopIntegral[Join[olrDefinition,<|"MasterIntegralPrefactor"->olrE^5|>],{-2,1}];
FTTest`FTAssert["known zero orders below a raised leading power do not mark the whole integral exact zero",
 AssociationQ[olrBeyond]&&AllTrue[Values[olrBeyond["Coefficients"]],#===0&]&&olrBeyond["ExactInEpsilon"]===False];
olrComplete=FeynFacet`EvaluateOneLoopIntegral[olrDefinition,{0,1}];
FTTest`FTAssert["requesting finite and positive terms preserves the complete lower Laurent coefficients",
 AssociationQ[olrComplete]&&olrComplete["LaurentLowerBound"]===-2&&Keys[olrComplete["Coefficients"]]===Range[-2,1]];
FTTest`FTReport[];
