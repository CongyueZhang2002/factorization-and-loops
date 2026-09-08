$HistoryLength=0;$MaxExtraPrecision=50;root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Get[root<>"/FeynFacet/Boundary/TangentialSystem.wl"];
Get[root<>"/FeynFacet/Coefficients/EndpointAssembly.wl"];
Get[root<>"/FeynFacet/Coefficients/EndpointProjection.wl"];
passed=0;failed=0;assert[name_,x_]:=If[TrueQ[x],passed++;Print["PASS ",name],failed++;Print["FAIL ",name]];
Clear[seZ,seV,seE];
seMasterBasis={FeynCalc`GLI["ScalarEndpointTest",{1,0}],FeynCalc`GLI["ScalarEndpointTest",{0,1}]};
gauge=DiagonalMatrix[{seZ^-2,seZ^2}];
source=<|"NormalVariable"->seZ,"TangentialVariable"->seV,"DimensionalRegulator"->seE,
 "NormalConnectionMatrix"->DiagonalMatrix[{(-2+seE)/seZ,(2+seE)/seZ}],
 "TangentialConnectionMatrix"->DiagonalMatrix[{0,seE/seV}],"OriginalMasterIntegralBasis"->seMasterBasis|>;
endpoint=FeynFacet`ConstructTangentialEndpointSystem[source,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"0<v<1,0<z<1-v",
 "BranchPrescription"->"Positive z and v with real logarithms."|>,"NormalGaugeMatrix"->gauge];
reference=<|"TangentialBasePoint"->1/4,"NormalizedDifferentialSystem"->
 <|"Variable"->seZ,"DimensionalRegulator"->seE,"ConnectionMatrix"->seE IdentityMatrix[2]/seZ|>,
 "OriginalToNormalizedGauge"->Inverse[gauge],"SeedMatrix"->IdentityMatrix[2]|>;
matching=FeynFacet`MatchTangentialEndpointBoundaryBasis[endpoint,reference];
bounds=FeynFacet`DetermineTangentialEndpointLaurentBounds[endpoint,matching,{0,0}];
entries={<|"Master"->seMasterBasis[[1]],"Terms"->{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->0|>}|>,
 <|"Master"->seMasterBasis[[2]],"Terms"->{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->seZ^-3|>}|>};
plan=FeynFacet`DetermineMasterCoefficientEndpointOrders[entries,endpoint,bounds,<|"ThroughOrder"->0|>];
projection=FeynFacet`ConstructScalarEndpointProjection[plan,endpoint,bounds];
assert["planner and scalar projection succeed",AssociationQ[projection]];
assert["normal depth uses c^T T after gauge cancellation",plan["MaximumNormalOrder"]===0&&plan["DensityNormalGaugeRow"]==={0,1/seZ}];
assert["row-specific singular term survives omitted original coefficient",AssociationQ[projection]&&Length[projection["Terms"]]===1&&projection["Terms"][[1,"Power"]]===-1&&projection["Terms"][[1,"CoefficientRowMatrix"]]==={{0,1}}&&endpoint["PrimarySectors"][[1,"OriginalCoefficients",1,1,2,2]]===0];
assert["columnwise c solve avoids the inactive column",projection["RequestedTangentialFunctionOrderRanges"]===<|2->{0,1}|>];
request=<|"TangentialBasePoint"->1/4,"ThroughOrder"->0,"PhysicalBoundaryValues"->
 <|"BoundaryBasisMatching"->matching,"AmplitudeLaurentLowerBounds"->{0,0},
 "AmplitudeCoefficients"-><|{1,0}->2,{1,1}->3,{2,0}->5,{2,1}->7|>|>|>;
result=FeynFacet`ConstructScalarEndpointSolution[projection,endpoint,request];
Print["CONSTRUCTION ",If[FailureQ[result],result,Lookup[result,"Status",None]]];
assert["physical scalar endpoint is explicitly constructed",AssociationQ[result]&&result["PhysicalBoundaryValuesApplied"]];
expandFinite[x_,record_]:=Module[{value=x,aa,ff,kk},
 aa=record["AlgebraicDefinitions"];ff=record["IntegralDefinitions"];
 Do[value=value/.FeynFacetSolution`a[j]->aa[[j]],{j,Length[aa],1,-1}];
 Do[With[{f=ff[[j]]},value=value/.FeynFacetSolution`F[j,u_]:>Inactive[Integrate][f["Integrand"],{f["IntegrationVariable"],0,u}]],{j,Length[ff],1,-1}];
 kk=FeynFacet`Private`solutionResolveKernelDefinitions[record["KernelDefinitions"]];
 value=value/.FeynFacetSolution`K[j_Integer,u_]:>(kk[[j]]/.record["KernelDefinitions"][[j,"Parameter"]]->u);
 FullSimplify[Activate[value],seV>0&&seV!=1/4]];
If[AssociationQ[result],
 assert["no unknown constants or lazy functions remain",FreeQ[result,FeynFacetSolution`C[__]|_Function|_SeriesCoefficient]];
 assert["zeroth scalar coefficient equals physical seed",expandFinite[result["EndpointTerms"][[1,"Coefficients",Key[0]]],result]===5];
 assert["finite c solution retains nonconstant tangential logarithm",FullSimplify[expandFinite[result["EndpointTerms"][[1,"Coefficients",Key[1]]],result]-7-5Log[4seV],seV>0]===0];
 distInput=<|"DimensionalRegulator"->seE,"Variable"->seZ,"Interval"->{0,1},"Assumptions"->0<seV<1,
 "EndpointConditions"-><|"NoOtherSingularities"->True,"UniformEpsilonExpansion"->True,"RepresentationValidOnInterval"->True|>,"Terms"->result["DistributionInputTerms"]|>;
 distr=FeynFacet`ExtractEndpointDistributions[distInput,<|"ThroughOrder"->0|>];
 assert["finite scalar terms feed the distribution extractor",AssociationQ[distr]&&distr["Status"]==="ExplicitFiniteCoefficients"];
];
assert["upward retargeting requires a fresh tail proof",MatchQ[FeynFacet`ConstructScalarEndpointSolution[projection,endpoint,Join[request,<|"ThroughOrder"->1|>]],Failure["EndpointCoefficientReplanningRequired",_]]];
assert["insufficient coefficient tail is rejected",FailureQ[FeynFacet`ConstructScalarEndpointProjection[Join[plan,<|"Status"->"CoefficientOrdersMissing"|>],endpoint,bounds]]];
assert["missing physical coefficient is not zero",FailureQ[FeynFacet`ConstructScalarEndpointSolution[projection,endpoint,Join[request,<|"PhysicalBoundaryValues"->Join[request["PhysicalBoundaryValues"],<|"AmplitudeCoefficients"-><|{2,0}->5|>|>]|>]]]];
seed84=ConstantArray[0,{2,84}];seed84[[1,1]]=1;seed84[[2,84]]=1;
matching84=FeynFacet`MatchTangentialEndpointBoundaryBasis[endpoint,Join[reference,<|"SeedMatrix"->seed84|>]];
known84=Association@Table[j->If[j===84,5+7seE,If[j===1,2,0]],{j,84}];
construction84=<|"KnownAmplitudeExpressions"->known84,"UnknownAmplitudeDefinitions"->{},
 "AmplitudeReduction"-><|"DimensionalRegulator"->seE,"BoundaryInputMatrix"->{{}},"FreeAmplitudeMatrix"->{{}},
 "BoundaryInputs"->{},"AmplitudeLaurentLowerBounds"->{0},"RemainingUnknownAmplitudeCount"->0,
 "AllBoundaryInputsPhysicallyDetermined"->True,"ParticularSolutionCompatibility"->"AutomaticFromInputBounds"|>|>;
request84=Join[request,<|"PhysicalBoundaryValues"-><|"BoundaryBasisMatching"->matching84,
 "AmplitudeLaurentLowerBounds"->ConstantArray[0,84],"AmplitudeCoefficients"-><|"PhysicalBoundaryConstruction"->construction84|>|>|>];
result84=FeynFacet`ConstructScalarEndpointSolution[projection,endpoint,request84];
assert["all 84 physical seed columns are retained and assigned",AssociationQ[result84]&&result84["SourceAmplitudeCount"]===84&&Length[result84["AmplitudeLaurentLowerBounds"]]===84];
assert["an unassigned physical seed column is rejected",MatchQ[FeynFacet`ConstructScalarEndpointSolution[projection,endpoint,
 Join[request84,<|"PhysicalBoundaryValues"->Join[request84["PhysicalBoundaryValues"],<|"AmplitudeCoefficients"-><|"PhysicalBoundaryConstruction"->Join[construction84,<|"KnownAmplitudeExpressions"->KeyDrop[known84,83]|>]|>|>]|>]],Failure["PhysicalSeedColumnAssignmentIncomplete",_]]];
jordanEndpoint=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->seZ,"TangentialVariable"->seV,"DimensionalRegulator"->seE,
 "NormalConnectionMatrix"->{{seE,1},{0,seE}}/seZ,"TangentialConnectionMatrix"->ConstantArray[0,{2,2}],"OriginalMasterIntegralBasis"->seMasterBasis|>,
 <|"MaximumNormalOrder"->0,"AnalyticDomain"->"0<v<1,0<z<1-v","BranchPrescription"->"Positive z"|>,"NormalGaugeMatrix"->IdentityMatrix[2]];
jordanMatching=FeynFacet`MatchTangentialEndpointBoundaryBasis[jordanEndpoint,
 <|"TangentialBasePoint"->1/4,"NormalizedDifferentialSystem"-><|"Variable"->seZ,"DimensionalRegulator"->seE,"ConnectionMatrix"->{{seE,1},{0,seE}}/seZ|>,"OriginalToNormalizedGauge"->IdentityMatrix[2],"SeedMatrix"->IdentityMatrix[2]|>];
jordanBounds=FeynFacet`DetermineTangentialEndpointLaurentBounds[jordanEndpoint,jordanMatching,{0,0}];
jordanEntries=MapIndexed[Join[#1,<|"Master"->seMasterBasis[[First[#2]]]|>]&,Reverse[entries]/.seZ^-3->seZ^-1];
jordanPlan=FeynFacet`DetermineMasterCoefficientEndpointOrders[jordanEntries,jordanEndpoint,jordanBounds,<|"ThroughOrder"->0|>];
jordanProjection=FeynFacet`ConstructScalarEndpointProjection[jordanPlan,jordanEndpoint,jordanBounds];
assert["Jordan log adds its own contact order per active column",AssociationQ[jordanProjection]&&jordanProjection["RequestedTangentialFunctionOrderRanges"]===<|1->{0,1},2->{0,2}|>];
assert["analytic units use the shared conservative Laurent bound",
 FeynFacet`Private`scalarEndpointValuation[(Pi^seE+3^seE)/seE,seE]["LowerBound"]===-1];
zeroSlopeEndpoint=FeynFacet`ConstructTangentialEndpointSystem[
 <|"NormalVariable"->seZ,"TangentialVariable"->seV,"DimensionalRegulator"->seE,
 "NormalConnectionMatrix"->DiagonalMatrix[{0,seE/seZ}],"TangentialConnectionMatrix"->ConstantArray[0,{2,2}],
 "OriginalMasterIntegralBasis"->seMasterBasis|>,<|"MaximumNormalOrder"->0,"AnalyticDomain"->"0<v<1,0<z<1-v","BranchPrescription"->"Positive z"|>,
 "NormalGaugeMatrix"->IdentityMatrix[2]];
zeroSlopeMatching=FeynFacet`MatchTangentialEndpointBoundaryBasis[zeroSlopeEndpoint,
 <|"TangentialBasePoint"->1/4,"NormalizedDifferentialSystem"-><|"Variable"->seZ,"DimensionalRegulator"->seE,
 "ConnectionMatrix"->DiagonalMatrix[{0,seE/seZ}]|>,"OriginalToNormalizedGauge"->IdentityMatrix[2],"SeedMatrix"->IdentityMatrix[2]|>];
zeroSlopeBounds=FeynFacet`DetermineTangentialEndpointLaurentBounds[zeroSlopeEndpoint,zeroSlopeMatching,{Infinity,0}];
zeroSlopeEntries=Table[<|"Master"->seMasterBasis[[j]],"Terms"->{<|"Representation"->"Exact","PreFactor"->1,"Coefficient"->1/seZ|>}|>,{j,2}];
zeroSlopePlan=FeynFacet`DetermineMasterCoefficientEndpointOrders[zeroSlopeEntries,zeroSlopeEndpoint,zeroSlopeBounds,<|"ThroughOrder"->0|>];
zeroSlopeProjection=FeynFacet`ConstructScalarEndpointProjection[zeroSlopePlan,zeroSlopeEndpoint,zeroSlopeBounds];
assert["uniform physical bounds remove the formal zero-slope projector",AssociationQ[zeroSlopeProjection]&&
 Length[zeroSlopeProjection["StructurallyAbsentPrimarySectors"]]===1&&
 Lookup[zeroSlopeProjection["Terms"],"RegulatorExponent"]==={1}&&zeroSlopeProjection["ActiveOriginalCoefficientRows"]==={1,2}];
assert["equal analytic units cancel after exponent normalization",
 FeynFacet`Private`scalarEndpointRow[{2^(-6+3(3-2seE)+6seE)/seZ-8/seZ}]==={0}];
assert["scalar result records weighted canonical master coverage and included prefactor",
 AssociationQ[result]&&result["OriginalMasterIntegralBasis"]===seMasterBasis&&
 result["ProjectedMasterIdentities"]==={{"ScalarEndpointTest",{0,1}}}&&
 TrueQ[result["GlobalPrefactorIncluded"]]&&result["GlobalPrefactor"]===1];
heldMerge=FeynFacet`Private`scalarEndpointDefinitionMerge[
 <|"KernelDefinitions"->{<|"Index"->1,"Parameter"->seV,"Expression"->1|>},"IntegralDefinitions"->{<|"Index"->1,"Integrand"->1|>},"AlgebraicDefinitions"->{1}|>,
 <|"KernelDefinitions"->{<|"Index"->1,"Parameter"->seV,"Expression"->FeynFacetSolution`a[1]|>},
   "IntegralDefinitions"->{<|"Index"->1,"Integrand"->FeynFacetSolution`K[1,seV]|>},
   "AlgebraicDefinitions"->{FeynFacetSolution`F[1,seV]}|>,
 {<|"Coefficient"->FeynFacetSolution`a[1]+FeynFacetSolution`K[1,seV]+FeynFacetSolution`F[1,seV]|>}];
assert["definition reference shifts survive exact serialization of association values",
 heldMerge===BinaryDeserialize[BinarySerialize[heldMerge]]&&
 heldMerge["Values"][[1,"Coefficient"]]===FeynFacetSolution`a[2]+FeynFacetSolution`K[2,seV]+FeynFacetSolution`F[2,seV]&&
 heldMerge["KernelDefinitions"][[2,"Index"]]===2&&heldMerge["IntegralDefinitions"][[2,"Index"]]===2];
hiddenConstantMock=<|"KernelDefinitions"->{},"IntegralDefinitions"->{},
 "AlgebraicDefinitions"->{FeynFacetSolution`C[99,99],FeynFacetSolution`C[2,0],FeynFacetSolution`C[2,1]},
 "MasterIntegralCoefficients"-><|0->{2->FeynFacetSolution`a[2]},1->{2->FeynFacetSolution`a[3]}|>|>;
hiddenConstantResult=Internal`InheritedBlock[{FeynFacet`ConstructMasterIntegralSolution},
 Clear[FeynFacet`ConstructMasterIntegralSolution];
 FeynFacet`ConstructMasterIntegralSolution[___]:=hiddenConstantMock;
 FeynFacet`ConstructScalarEndpointSolution[projection,endpoint,request]];
assert["reachable hidden constants are physical and unused boundary orders are never requested",
 AssociationQ[hiddenConstantResult]&&FreeQ[hiddenConstantResult,FeynFacetSolution`C[__]]&&
 hiddenConstantResult["AlgebraicDefinitions"]==={5,7}&&
 expandFinite[hiddenConstantResult["EndpointTerms"][[1,"Coefficients",Key[0]]],hiddenConstantResult]===5];
coefficientField=FeynFacet`Private`scalarEndpointCoefficientFieldAtoms[
 {sePdf[xa] seFragmentation[zh]/seZ,seUnknown[seV]/seZ},{seE,seZ,seV}];
assert["declared external coefficient factors remain explicit field constants",
 Sort[coefficientField]===Sort[{sePdf[xa],seFragmentation[zh]}]&&
 FeynFacet`Private`scalarEndpointDefinitionsValidQ[
 {<|0->sePdf[xa] seFragmentation[zh]|>},<||>,coefficientField]];
assert["coordinate functions and invalid finite definitions remain rejected",
 !FeynFacet`Private`scalarEndpointDefinitionsValidQ[{<|0->seUnknown[seV]|>},<||>,coefficientField]&&
 !FeynFacet`Private`scalarEndpointDefinitionsValidQ[{<|0->1|>},
 <|"AlgebraicDefinitions"->{sePdf[xa]}|>,coefficientField]];

Print["TALLY passed=",passed," failed=",failed];Exit[If[failed===0,0,1]];
