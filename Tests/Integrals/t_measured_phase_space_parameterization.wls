$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
psRequest=<|"ReferenceMomentum"->psP,"TotalMomentum"->psTotal,
 "ParticleMomenta"->{psK1,psK2,psK3},"InvariantMassSquared"->psS,
 "ReferenceProjection"->psJ/2,"MeasurementVariable"->psZ,"DimensionalRegulator"->psE,
 "Parameters"->{psT,psY,psA},"Assumptions"->psS>0&&psJ>0&&0<psZ<1|>;
psGeometry=FeynFacet`ConstructMeasuredThreeParticlePhaseSpace[psRequest];
FTTest`FTAssert["the measured three-body parameterization is constructed from declared geometry",
 AssociationQ[psGeometry]];
If[!AssociationQ[psGeometry],Print[psGeometry];FTTest`FTReport[]];
psRules=psGeometry["ScalarProductRules"];psMomenta=psGeometry["ParticleMomenta"];
psValue[expr_]:=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[expr]]/.psRules];
FTTest`FTAssert["every particle stays massless and the invariant masses sum to P squared",
 (psValue[FeynCalc`SPD[#]]&/@psMomenta)==={0,0,0}&&
 psValue[FeynCalc`SPD[Total[psMomenta]]-psS]===0];
FTTest`FTAssert["the tagged fraction is exact and all light-cone fractions sum to unity",
 psValue[2FeynCalc`SPD[psP,psK1]/psJ-psZ]===0&&
 Factor[Total[psGeometry["TaggedFractions"]]]===1];
psBetaMoment[n_,shape_]:=Pochhammer[shape[[1]],n]/Pochhammer[Total[shape],n];
psAveragePolynomial[expr_]:=Total[Last[#]Times@@MapThread[psBetaMoment,
 {First[#],psGeometry["BetaShapes"]}]&/@CoefficientRules[Expand[expr],{psT,psY,psA}]]//Factor;
FTTest`FTAssert["the angular cosine has zero mean and the full-D variance",
 psAveragePolynomial[1-2psA]===0&&
 Factor[psAveragePolynomial[(1-2psA)^2]-1/(2-2psE)]===0];
ps12=psGeometry["PairInvariantMassesSquared"][[1]];
ps23=psGeometry["PairInvariantMassesSquared"][[3]];
(* The odd azimuthal term integrates to zero before the remaining polynomial moments. *)
FTTest`FTAssert["the exact first invariant-mass moments have the required decay symmetry",
 Factor[psAveragePolynomial[ps12/.psA->1/2]-psS(1+psZ)/4]===0&&
 Factor[psAveragePolynomial[ps23]-psS(1-psZ)/2]===0];
psVolume=FeynFacet`MasslessPhaseSpaceVolume[2,psS,psE]^2 psS/(2Pi)*
 psZ^(-psE)(1-psZ)^(1-2psE);
FTTest`FTAssert["recursive two-body phase-space normalization equals the independent three-body volume",
 FullSimplify[psGeometry["MeasuredPhaseSpaceVolume"]/psVolume,psE<0&&psS>0&&0<psZ<1]===1];
FTTest`FTAssert["unphysical external geometry is rejected",
 FailureQ[FeynFacet`ConstructMeasuredThreeParticlePhaseSpace[Join[psRequest,<|"InvariantMassSquared"->-1|>]]]];
psGram=Outer[FeynCalc`SPD,psGeometry["FullGramMomenta"],psGeometry["FullGramMomenta"]];
FTTest`FTAssert["the parameterization reproduces the full four-vector Gram determinant",
 FullSimplify[Det[Map[psValue,psGram,{2}]]-psGeometry["FullGramDeterminant"],
  psS>0&&psJ>0&&0<psZ<1&&0<psT<1&&0<psY<1&&0<psA<1]===0];
psSecond=psAveragePolynomial[(ps12/.psA->1/2)^2+
 4psS^2 psZ psT(1-psT)psY(1-psY)/(2-2psE)]/psS^2;
psAlpha=1-psE;
FTTest`FTAssert["the invariant second moment includes the relative-angle weight and square-root correlation",
 Factor[psSecond-(psAlpha+1)*(psAlpha*(1+psZ)^2+1+psZ^2)/(4(2psAlpha+1)^2)]===0];
FTTest`FTReport[];
