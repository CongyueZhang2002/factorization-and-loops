#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
Clear[kl,ll,pp,ms,ee,xx,vacuumFamily,phaseFamily,numFamily,otherFamily];
ordinaryTop=FeynCalc`FCTopology[vacuumFamily,
 {FeynCalc`SFAD[{kl,ms}],FeynCalc`SFAD[{ll,ms}],FeynCalc`SFAD[kl-ll]},
 {kl,ll},{},{},{}];
ordinaryInput=<|"Topology"->ordinaryTop,"DimensionalRegulator"->ee,
 "Master"->{FeynCalc`GLI[vacuumFamily,{2,2,0}],FeynCalc`GLI[vacuumFamily,{2,2,-1}]},
 "KinematicRules"->{ms->1}|>;
originalInput=ordinaryInput;
ordinary=ConstructMasterIntegralRepresentations[ordinaryInput];
reps=ordinary["MasterIntegralRepresentations"];
FTAssert["ordinary conversion uses topology and integer indices only",
 ordinary["Status"]==="IntegralRepresentationsConstructed" &&
 !KeyExistsQ[ordinaryInput,"SymanzikPolynomials"] && ordinaryInput===originalInput];
FTAssert["virtual measure is the AMFlow convention",
 reps[1]["MeasurePrefactor"]===-Pi^(-4+2ee) && reps[1]["BoundaryNormalizationChanged"]===False];
FTAssert["ordinary scalar and numerator masters both receive explicit parameter integrands",
 And@@(#["Representation"]==="ProjectiveFeynmanParameters"& /@ Values[reps])];
bounds=DetermineIntegralLaurentBound /@ reps;
FTAssert["derived Gamma and endpoint factors establish the two-loop double pole",
 bounds[1]["LowerBound"]===-2 && bounds[2]["LowerBound"]===-2];
FTAssert["negative powers remain numerators",reps[2]["PropagatorPowers"]==={2,2,-1}];
(* At epsilon=5/4 both massive vacuum integrations converge. The numerator
   identity k^2=(k^2-m^2)+m^2 gives 2 (T1+m^2 T2) T2. *)
params=reps[2]["FeynmanParameters"];
integrand=reps[2]["ParametricIntegrand"];
parametricNumerator=reps[2]["ParametricPrefactor"]/.ee->5/4;
parametricNumerator=parametricNumerator Total[Table[
 NIntegrate[Evaluate[integrand/.params[[pivot]]->1/.ee->5/4],
  Evaluate[{First[Delete[params,pivot]],0,1}],WorkingPrecision->30,PrecisionGoal->18],
 {pivot,2}]];
numeratorReference=2(-Gamma[1/4]+Gamma[5/4])Gamma[5/4];
FTAssert["numerator parametrization agrees with the independent tadpole identity",
 Abs[parametricNumerator-numeratorReference]<10^-16];

rescaled=ConstructMasterIntegralRepresentations[ordinaryInput,
 <|"MasterIntegralPrefactors"-><|1->ee^2,2->1/ee|>|>]["MasterIntegralRepresentations"];
FTAssert["explicit master rescaling is separate from the measure",
 rescaled[1]["MeasurePrefactor"]===reps[1]["MeasurePrefactor"] &&
 rescaled[1]["MasterIntegralPrefactor"]===ee^2];
FTAssert["master prefactor zeros and poles change required expansion depth",
 DetermineIntegralLaurentBound[rescaled[1]]["LowerBound"]===0 &&
 DetermineIntegralLaurentBound[rescaled[2]]["LowerBound"]===-3];
FTAssert["family mismatch is rejected",
 ConstructMasterIntegralRepresentations[Join[ordinaryInput,<|"Master"->FeynCalc`GLI[otherFamily,{2,2,0}]|>]][
  "UnresolvedIntegralDefinitions"]=!=<||>];
FTAssert["regulator aliases are normalized",
 ConstructMasterIntegralRepresentations[ordinaryInput/.ee->CANONICA`eps]["DimensionalRegulator"]===CANONICA`eps];

singleTop=FeynCalc`FCTopology[numFamily,{FeynCalc`SFAD[{kl,xx}]},{kl},{},{},{}];
de=<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "OriginalMasterIntegralBasis"->{FeynCalc`GLI[numFamily,{2}]},
 "Topology"->singleTop,"ConnectionMatrices"->{{{-ee/xx}}}|>;
orders=DetermineMasterIntegralExpansionOrders[de,<|"BasePoint"->{1/4},
 "RequestedMasterIntegralOrderRanges"-><|1->{-1,0}|>|>];
FTAssert["the order planner automatically constructs missing integral representations",
 orders["Status"]==="SufficientOrdersDetermined" &&
 orders["OrdinaryPointConstantLowerBounds"]==={-1} &&
 orders["FundamentalMatrixEpsilonOrders"]["MaximumTransformedOrder"]===1];
legacy=ConstructMasterIntegralRepresentations[<|
 "Topology"->FeynCalc`FCTopology[numFamily,{FeynCalc`FAD[{kl,1}]},{kl},{},{},{}],
 "Master"->FeynCalc`GLI[numFamily,{2}],"DimensionalRegulator"->ee|>];
FTAssert["ordinary massive FAD inputs are converted to standard propagators",
 DetermineIntegralLaurentBound[legacy["MasterIntegralRepresentations"][1]]["LowerBound"]===-1];
overridden=ConstructMasterIntegralRepresentations[Join[ordinaryInput,<|
 "Topology"->ReplacePart[ordinaryTop,5->{ms->2}],"KinematicRules"->{ms->1}|>]];
FTAssert["explicit scalar-product and mass rules take precedence over topology defaults",
 overridden["MasterIntegralRepresentations"][1]["InversePropagators"]===reps[1]["InversePropagators"]];
FTAssert["automatic construction fixes no new boundary normalization",
 orders["BoundaryNormalization"]["Type"]==="OrdinaryPoint" &&
 orders["IntegralRepresentationConstruction"]["BoundaryNormalizationChanged"]===False];

phaseTop=FeynCalc`FCTopology[phaseFamily,
 {FeynCalc`SFAD[kl],FeynCalc`SFAD[pp-kl]},{kl},{pp},{FeynCalc`SPD[pp]->1},{}];
phaseInput=<|"Topology"->phaseTop,"DimensionalRegulator"->ee,"Prescription"->{0},
 "CutIndices"->{1,2},"CutMomenta"->{kl,pp-kl},
 "Master"->{FeynCalc`GLI[phaseFamily,{1,1}],FeynCalc`GLI[phaseFamily,{1,2}],
  FeynCalc`GLI[phaseFamily,{1,3}],FeynCalc`GLI[phaseFamily,{0,1}]}|>;
phase=ConstructMasterIntegralRepresentations[phaseInput];
ph=phase["MasterIntegralRepresentations"];
FTAssert["all cut powers are processed without hand-written representations",
 phase["Status"]==="IntegralRepresentationsConstructed" && Length[ph]===4];
FTAssert["the massless two-particle volume has the standard AMFlow normalization",
 FullSimplify[ph[1]["Terms"][[1,"Prefactor"]]/.ee->0]===1/(8Pi)];
FTAssert["the two-particle volume is epsilon regular",
 DetermineIntegralLaurentBound[ph[1]]["LowerBound"]===0];
FTAssert["a double cut propagator is a signed delta derivative",
 ph[2]["CutDistributions"][[2,"DistributionCoefficient"]]===-1 &&
 !FreeQ[ph[2]["Integrand"],Derivative[1][DiracDelta]] &&
 ph[2]["UnitCutRepresentation"]===None];
FTAssert["a triple cut propagator includes the derivative factorial",
 ph[3]["CutDistributions"][[2,"DistributionCoefficient"]]===1/2];
FTAssert["nonpositive cut powers give zero",
 DetermineIntegralLaurentBound[ph[4]]["LowerBound"]===Infinity];
FTAssert["the Gram construction retains its Jacobian and energy domain",
 ph[2]["ScalarProductJacobian"]===1/2 && ph[2]["KinematicConditions"]===True &&
 ph[2]["DomainConditions"]=!=True];
dotBound=DetermineIntegralLaurentBound[ph[2]];
tripleBound=DetermineIntegralLaurentBound[ph[3]];
FTAssert["localized double cuts have a finite pole bound",
 AssociationQ[dotBound] && dotBound["LowerBound"]===0];
FTAssert["normal derivatives agree with the massive two-body phase-volume derivative",
 FullSimplify[dotBound["ResolvedTerms"][[1,"Prefactor"]]/.ee->0]===-1/(8Pi)];
FTAssert["a vanishing leading coefficient in a triple cut is retained",
 AssociationQ[tripleBound] && tripleBound["LowerBound"]===1];

threeTop=FeynCalc`FCTopology[phaseFamily,
 {FeynCalc`SFAD[kl],FeynCalc`SFAD[ll],FeynCalc`SFAD[pp-kl-ll]},
 {kl,ll},{pp},{FeynCalc`SPD[pp]->3},{}];
three=ConstructMasterIntegralRepresentations[<|"Topology"->threeTop,
 "Master"->FeynCalc`GLI[phaseFamily,{1,1,1}],"CutIndices"->{1,2,3},
 "CutMomenta"->{kl,ll,pp-kl-ll},"Prescription"->{0,0},"DimensionalRegulator"->ee|>];
FTAssert["recursive phase space works at a different loop and cut count",
 FullSimplify[three["MasterIntegralRepresentations"][1]["Terms"][[1,"Prefactor"]]/.ee->0]===3/(256Pi^3)];

incomplete=ConstructMasterIntegralRepresentations[<|"Topology"->threeTop,
 "Master"->FeynCalc`GLI[phaseFamily,{1,1,2}],"CutIndices"->{1,2,3},
 "CutMomenta"->{kl,ll,pp-kl-ll},"Prescription"->{0,0},"DimensionalRegulator"->ee|>];
FTAssert["incomplete denominator coordinates are completed by scalar products",
 incomplete["MasterIntegralRepresentations"][1]["Representation"]==="BaikovCut" &&
 Length[incomplete["MasterIntegralRepresentations"][1]["IntegrationVariables"]]===5];
badCut=ConstructMasterIntegralRepresentations[Join[phaseInput,<|"Prescription"->{1}|>]];
FTAssert["cuts cannot depend on virtual momenta",badCut["UnresolvedIntegralDefinitions"]=!=<||>];
badDirection=ConstructMasterIntegralRepresentations[Join[phaseInput,<|"CutDirections"->{0,1}|>]];
FTAssert["invalid cut orientation is rejected",badDirection["UnresolvedIntegralDefinitions"]=!=<||>];
minusTop=singleTop/.{1,1}->{1,-1};
minus=ConstructMasterIntegralRepresentations[<|"Topology"->minusTop,"Master"->FeynCalc`GLI[numFamily,{2}],
 "Prescription"->{-1},"DimensionalRegulator"->ee,"KinematicRules"->{xx->1}|>]["MasterIntegralRepresentations"][1];
FTAssert["the conjugate virtual measure carries AMFlow's minus sign",
 FullSimplify[minus["MeasurePrefactor"]-I Pi^(-2+ee)]===0];
FTAssert["the conjugate branch is explicitly retained",
 minus["AnalyticContinuation"]==="Continuation with the -i0 prescription."];

(* A real saved family exercises references, Kira scalar products, cut order,
   basis-completion numerators and all 23 master index vectors in one call. *)
actualPath=FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","UU_08_10_canonical",
 "DifferentialEquationDataV2","CF269","FamilyDLogEpsilonForm.wl"}];
actual=Get[actualPath];
actualDefinitions=ConstructMasterIntegralRepresentations[actual,<|"BasePoint"->{1/4,1/3}|>];
ar=actualDefinitions["MasterIntegralRepresentations"];
FTAssert["saved DE references automatically supply every CF269 master definition",
 actualDefinitions["Status"]==="IntegralRepresentationsConstructed" && Length[ar]===23];
FTAssert["the family Gram construction is shared across exponent vectors",
 ar[1]["BaikovPolynomial"]===ar[2]["BaikovPolynomial"] &&
 ar[1]["IntegrationVariables"]===ar[2]["IntegrationVariables"]];
FTAssert["saved master identity and cut ordering are preserved",
 ar[2]["MasterIntegral"]===actual["OriginalMasterIntegralBasis"][[2]] &&
 ar[2]["CutIndices"]==={2,8,1} && ar[2]["CutDistributions"][[2,"Power"]]===2];
FTAssert["source kinematics and scale are read rather than supplied by hand",
 ar[1]["TimeDirectionSquared"]===5/12];
FTAssert["the actual inclusive master has a derived finite bound",
 DetermineIntegralLaurentBound[ar[5]]["LowerBound"]===0];
FTAssert["compact cut geometry supplies a conservative pole bound",
 DetermineIntegralLaurentBound[ar[1]]["LowerBound"]===-5 &&
 DetermineIntegralLaurentBound[ar[1]]["Method"]==="CompactSemialgebraicPoleMultiplicityBound"];
actualOrders=DetermineMasterIntegralExpansionOrders[actual,<|"BasePoint"->{1/4,1/3},
 "RequestedMasterIntegralOrderRanges"-><|1->{-4,0},2->{-4,0},3->{-4,0},4->{-4,0}|>|>];
FTAssert["the planner now derives all required cut bounds from their definitions",
 actualOrders["Status"]==="SufficientOrdersDetermined" &&
 Length[actualOrders["IntegralBoundRecords"]]===23 &&
 actualOrders["IntegralBoundRecords"][5]["LowerBound"]===0 &&
 actualOrders["AssumedMasterLaurentBounds"]==={} &&
 actualOrders["IntegralRepresentationConstruction"]["Status"]==="IntegralRepresentationsConstructed"];
FTReport[];
