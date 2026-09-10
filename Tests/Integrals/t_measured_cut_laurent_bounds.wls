$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
mfFamily=FeynFacet`CreateMeasuredPhaseSpaceDefinition[<|"Name"->mfThree,
 "FinalMomenta"->{mfK1,mfK2,mfK3},"TotalMomentum"->mfP+mfQ,
 "ExternalMomenta"->{mfP,mfQ},"ReferenceMomentum"->mfP,"TaggedMomentum"->mfK1,
 "MeasurementVariable"->mfZ,"KinematicRules"->{FeynCalc`SPD[mfP]->0,
 FeynCalc`SPD[mfQ]->0,FeynCalc`SPD[mfP,mfQ]->mfS/2},
 "Assumptions"->mfS>0&&0<mfZ<1|>];
mfInput=<|"DimensionalRegulator"->mfEps,"KinematicVariables"->{mfS,mfZ},
 "Families"->{mfFamily},"MasterIntegralBasis"->{
 FeynCalc`GLI[mfThree,{1,1,1,1}],FeynCalc`GLI[mfThree,{1,1,1,2}],
 FeynCalc`GLI[mfThree,{2,1,1,1}]}|>;
mfDefs=FeynFacet`ConstructMasterIntegralDefinitions[mfInput,<|"BasePoint"->{1,1/3}|>]["MasterIntegralDefinitions"];
mfReps=Map[Join[#,FeynFacet`Private`miRepBaikov[#]]&,mfDefs];
mfBounds=FeynFacet`DetermineIntegralLaurentBound/@mfReps;
Print["MEASURED BOUNDS ",Map[If[AssociationQ[#],KeyTake[#,{"LowerBound","RemainingIntegrationDimension"}],#]&,mfBounds]];
FTTest`FTAssert["fixed measured slices use the same compact-cut pole theorem",
 AllTrue[Values[mfBounds],AssociationQ]&&AllTrue[Values[mfBounds],#["RemainingIntegrationDimension"]===3&]];
If[AllTrue[Values[mfBounds],AssociationQ],
 FTTest`FTAssert["measurement and particle dots affect the finite normal order",
  mfBounds[2]["CutIntegralTerms"]["NormalDerivativeOrder"]===1&&
  mfBounds[3]["CutIntegralTerms"]["NormalDerivativeOrder"]===1];
 FTTest`FTAssert["the fixed-slice proof does not certify endpoint distributions or a regular parameter chamber",
  mfBounds[1]["ConvergenceCertificate"]["FixedFiberLaurentBoundEstablished"]===True&&
  mfBounds[1]["ConvergenceCertificate"]["ExternalEndpointUniformityEstablished"]===False&&
  mfBounds[1]["ConvergenceCertificate"]["RegularParameterChamberEstablished"]===False];
 FTTest`FTAssert["a measurement does not add a particle or change the explicit measure",
  mfBounds[1]["EffectiveExternalRank"]===2&&
  mfBounds[1]["ConvergenceCertificate"]["Geometry"]["ParticleCutIndices"]==={1,2,3}];
 mfExact=FeynFacet`ConstructMasterIntegralRepresentations[mfInput,<|"BasePoint"->{1,1/3}|>]["MasterIntegralRepresentations"];
 mfExactBounds=FeynFacet`DetermineIntegralLaurentBound/@KeyTake[mfExact,{1,2}];
 FTTest`FTAssert["derived bounds enclose the independent exact Gamma valuations",
  And@@Table[mfBounds[i]["LowerBound"]<=mfExactBounds[i]["LowerBound"],{i,2}]]];

(* Two independent fractions of the three forward particles: the same
   constructor and proof see a codimension-two slice, with no SIDIS names. *)
mfTop=mfFamily["Topology"];
mfSecond=FeynCalc`FCI[FeynCalc`FeynAmpDenominator[
 FeynCalc`StandardPropagatorDenominator[0,2FeynCalc`SPD[mfP,mfK2],-mfS mfY,{1,1}]]];
mfDouble=FeynFacet`CreateCutIntegralDefinition[<|
 "Topology"->ReplacePart[mfTop,2->Append[mfTop[[2]],mfSecond]],
 "Cuts"->Append[mfFamily["Cuts"],<|"Index"->5,"Type"->"Measurement"|>],
 "MeasurePrefactor"->mfS mfFamily["MeasurePrefactor"],"TimeDirection"->mfP+mfQ,
 "Assumptions"->mfS>0&&mfZ>0&&mfY>0&&mfZ+mfY<1|>];
mfDoubleInput=<|"DimensionalRegulator"->mfEps,"KinematicVariables"->{mfS,mfZ,mfY},
 "Families"->{mfDouble},"MasterIntegralBasis"->{FeynCalc`GLI[mfThree,{1,1,1,1,2}]}|>;
mfDoubleRep=FeynFacet`ConstructMasterIntegralRepresentations[mfDoubleInput,
 <|"BasePoint"->{1,1/4,1/3}|>]["MasterIntegralRepresentations"][1];
mfDoubleBound=FeynFacet`DetermineIntegralLaurentBound[mfDoubleRep];
Print["TWO MEASUREMENTS ",If[AssociationQ[mfDoubleBound],
 KeyTake[mfDoubleBound,{"LowerBound","RemainingIntegrationDimension"}],mfDoubleBound]];
FTTest`FTAssert["any number of independent affine measurements reduces the residual dimension",
 AssociationQ[mfDoubleBound]&&mfDoubleBound["RemainingIntegrationDimension"]===2&&
 mfDoubleBound["ConvergenceCertificate"]["MeasurementCutCount"]===2];


(* Direct geometry check deliberately changes the cut value while retaining
   a true external condition, so rejection comes from the empty slice. *)
mfBad=Join[mfDefs[1],<|"InversePropagators"->ReplacePart[mfDefs[1]["InversePropagators"],
 4->mfDefs[1]["InversePropagators"][[4]]-5/3],"KinematicConditions"->True|>];
mfBad=Join[mfBad,FeynFacet`Private`miRepBaikov[mfBad]];
mfBadBound=FeynFacet`DetermineIntegralLaurentBound[mfBad];
FTTest`FTAssert["an empty measured slice cannot receive an ordinary fixed-fiber bound",
 FailureQ[mfBadBound]&&mfBadBound[[1]]==="StrictMeasuredSliceInteriorNotEstablished"];

(* The derivative of a moving-domain integral has a finite continued term
   from a vanishing coefficient times an integral pole. *)
mfMovingExact=(1-mfA)^(2mfL+1)Gamma[mfL+1]^2/Gamma[2mfL+2];
mfMovingJet=-mfL(1-mfA)^(2mfL)Gamma[mfL]Gamma[mfL+1]/Gamma[2mfL+1];
FTTest`FTAssert["moving boundary normal derivatives retain evanescent coefficients times poles",
 FullSimplify[FunctionExpand[D[mfMovingExact,mfA]-mfMovingJet],
 Assumptions->mfA<1&&mfL>1]===0&&Limit[mfMovingJet,mfL->0]===-1];

mfScaledDefs=FeynFacet`ConstructMasterIntegralDefinitions[
 Join[mfInput,<|"KinematicVariables"->{mfZ}|>],<|"BasePoint"->{1/3}|>]["MasterIntegralDefinitions"];
mfScaled=Join[mfScaledDefs[1],FeynFacet`Private`miRepBaikov[mfScaledDefs[1]]];
mfScaledBound=FeynFacet`DetermineIntegralLaurentBound[mfScaled];
FTTest`FTAssert["the physical scale stays symbolic with a proved exact scaling factor",
 AssociationQ[mfScaledBound]&&mfScaledBound["LowerBound"]===mfBounds[1]["LowerBound"]&&
 Simplify[mfScaledBound["HomogeneousScaleNormalization"]["ScaleSquaredMomentumDegree"]-(1-2mfEps)]===0&&
 mfScaledBound["HomogeneousScaleNormalization"]["ScalingRules"]==={mfS->1}];
FTTest`FTReport[];
