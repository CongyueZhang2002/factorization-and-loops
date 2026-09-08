#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[FileNameJoin[{root,"Tests","TestKit.wl"}]];
Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]];
Clear[ee,xx,yy];
FTAssert["rational cancellations precede valuation",
 DetermineLaurentValuation[(1+ee)/ee^2-1/ee^2,ee]===-1];
FTAssert["gamma normalization and reciprocal zeros",
 DetermineLaurentValuation[Gamma[ee^2]/Gamma[-1+ee],ee]===-1];
FTAssert["essential regulator singularity rejected",
 FailureQ[DetermineLaurentValuation[Exp[1/ee],ee]]];
FTAssert["regulator package context normalized",
 DetermineLaurentValuation[1/CANONICA`eps^2,ee]===-2];
resolved[powers_,g_:1,pref_:1,logs_:Automatic] := <|"DimensionalRegulator"->ee,
 "Terms"->{<|"IntegrationVariables"->Take[{xx,yy},Length[powers]],
  "EndpointPowers"->powers,"RegularFactor"->g,"Prefactor"->pref,
  "LogPowers"->If[logs===Automatic,ConstantArray[0,Length[powers]],logs]|>}|>;
bound[powers_,g_:1,pref_:1,logs_:Automatic] :=
 DetermineIntegralLaurentBound[resolved[powers,g,pref,logs]];
FTAssert["power divergence with no resonant Taylor coefficient has no epsilon pole",
 bound[{-2-ee}]["LowerBound"]===0];
FTAssert["resonant Taylor coefficient creates one pole",
 bound[{-2-ee},1+xx]["LowerBound"]===-1];
FTAssert["independent endpoint poles add within one integral",
 bound[{-1-ee,-1-2ee}]["LowerBound"]===-2];
FTAssert["gamma normalization contributes to the integral bound",
 bound[{-1-ee},1,Gamma[ee]]["LowerBound"]===-2];
FTAssert["exact moment cancellations are retained",
 bound[{-1-ee},ee(1+xx)]["LowerBound"]===0];
FTAssert["smooth rational remainder yields a pole bound",
 bound[{-1-ee},1/(1+xx)]["LowerBound"]===-1];
FTAssert["moving singularity fails uniform regularity",
 FailureQ[bound[{-1-ee},1/(xx+ee)]]];
FTAssert["interior singularity is not called a regular remainder",
 FailureQ[bound[{-1-ee},1/(xx-1/2)]]];
FTAssert["log powers and nonlinear regulator approach multiply pole order",
 bound[{-1-ee^2},1,1,{2}]["LowerBound"]===-6];
FTAssert["zero integrand has no unregulated pole",
 bound[{-1},0]["LowerBound"]===Infinity];
two=resolved[{-1-ee}];two["Terms"]=Join[two["Terms"],two["Terms"]];
FTAssert["sectors are added rather than their pole orders",
 DetermineIntegralLaurentBound[two]["LowerBound"]===-1];

calc[inputs_,ops_,requests_] := DetermineEpsilonOrders[<|"DimensionalRegulator"->ee,
 "Inputs"->inputs,"Operations"->ops,"RequestedOrders"->requests|>];
linear[id_,terms_] := <|"Id"->id,"Operation"->"LinearCombination","Terms"->terms|>;
term[id_,z_] := <|"Input"->id,"Coefficient"->z|>;
r=calc[<|"I"->-2|>,{linear["F",{term["I",1/ee],term["I",-1/ee+1]}]},<|"F"->0|>];
FTAssert["same master coefficients combined before order selection",
 r["RequiredInputUpperOrders"]===<|"I"->0|>];
FTAssert["coefficient depth uses the master lower bound",
 r["CoefficientExpansionOrders"][[1,"ThroughOrder"]]===2];
FTAssert["integer lower bounds remain assumptions",
 r["Status"]==="SufficientForAssumedInputBounds"];
r=calc[<|"I"->bound[{-1-ee}]|>,{linear["F",{term["I",ee]}]},<|"F"->0|>];
FTAssert["positive coefficient valuation can request only negative master orders",
 r["RequiredInputOrders"]===<|"I"->{-1}|> &&
 r["Status"]==="SufficientForInputRepresentations"];
r=calc[<|"A"->-2,"B"->-1|>,
 {<|"Id"->"F","Operation"->"Product","Inputs"->{"A","B"}|>},<|"F"->0|>];
FTAssert["bilinear products require the other factor's lower bound",
 r["RequiredInputUpperOrders"]===<|"A"->1,"B"->2|>];
r=calc[<|"A"->-2|>,
 {<|"Id"->"F","Operation"->"Convolution","Inputs"->{"A","A"}|>},<|"F"->0|>];
FTAssert["repeated factors retain both dependencies",
 r["RequiredInputUpperOrders"]===<|"A"->2|>];
r=calc[<|"A"->Missing[],"B"->-1|>,
 {<|"Id"->"F","Operation"->"Product","Inputs"->{"A","B"}|>},<|"F"->0|>];
FTAssert["unknown lower bounds produce unresolved requirements",
 r["Status"]==="AdditionalLaurentBoundsRequired" && r["MissingLaurentBounds"]=!={}];
r=calc[<|"A"->bound[{-1-ee}],"unused"->Missing[]|>,{},<|"A"->0|>];
FTAssert["unused unknown inputs do not obstruct a result",
 r["Status"]==="SufficientForInputRepresentations"];
r=calc[<|"A"->Infinity|>,{},<|"A"->0|>];
FTAssert["a zero assumption cannot be silently promoted to proof",
 r["Status"]==="SufficientForAssumedInputBounds"];
r=calc[<|"A"->Missing[]|>,{linear["F",{term["A",0]}]},<|"F"->0|>];
FTAssert["identically zero coefficient needs no unknown master",
 r["RequiredInputUpperOrders"]===<||> && r["MissingLaurentBounds"]==={}];

matrix[a_,left_,right_,req_] := DetermineFundamentalMatrixEpsilonOrders[
 <|"DimensionalRegulator"->ee,"ConnectionMatrices"->{a},
 "LeftBasisMatrix"->left,"RightBasisMatrix"->right|>,
 <|"RequestedCoefficients"->req|>];
qmat={{1,ee},{1,0}};
r=matrix[ee {{xx,0},{0,1}},qmat,Inverse[qmat],{{1,1,2},{1,2,2},{2,1,2},{2,2,2}}];
FTAssert["entrywise basis requirements avoid the global extra order",
 r["MaximumTransformedOrder"]===2];
r=matrix[{{0,0,0},{1,0,0},{0,ee,0}},IdentityMatrix[3],IdentityMatrix[3],{{3,1,2}}];
FTAssert["DE requirements close through epsilon-zero triangular dependencies",
 r["TransformedCoefficientUpperOrders"][[2,1]]===1 &&
 r["TransformedCoefficientUpperOrders"][[1,1]]===1];
FTAssert["shortest path gives a lower bound on solution entries",
 r["TransformedCoefficientLowerBounds"][[3,1]]===1 &&
 r["TransformedCoefficientLowerBounds"][[1,3]]===Infinity];
FTAssert["negative powers require preparation before recurrence planning",
 FailureQ[matrix[{{0,1/ee},{0,0}},IdentityMatrix[2],IdentityMatrix[2],{{1,2,0}}]]];

endpoint[powers_,logs_:Automatic,pref_:1] := DetermineEndpointEpsilonOrders[
 <|"DimensionalRegulator"->ee,"NormalVariables"->Take[{xx,yy},Length[powers]],
 "EndpointPowers"->powers,"LogPowers"->If[logs===Automatic,ConstantArray[0,Length[powers]],logs],
 "Prefactor"->pref|>,<|"ThroughOrder"->0|>];
r=endpoint[{-1-2ee}];
FTAssert["ordinary part and boundary value have different requirements",
 Lookup[r["Requirements"],"CoefficientUpperOrder"]==={0,1}];
r=endpoint[{-1-ee,-1-2ee}];
FTAssert["two endpoints require bulk zero, faces one, corner two",
 Lookup[r["Requirements"],"CoefficientUpperOrder"]==={0,1,1,2}];
r=endpoint[{-3-ee}];
FTAssert["higher power needs a higher derivative, not more epsilon orders",
 r["Requirements"][[2,"NormalDerivativeOrders"]][xx]===2 &&
 r["Requirements"][[2,"CoefficientUpperOrder"]]===1];
FTAssert["logarithmic endpoint factor requires its actual pole order",
 endpoint[{-1-ee},{2}]["Requirements"][[2,"CoefficientUpperOrder"]]===3];
FTAssert["nonlinear epsilon slope is accounted for",
 endpoint[{-1-ee^3}]["Requirements"][[2,"CoefficientUpperOrder"]]===3];
FTAssert["normalization zeros reduce endpoint requirements",
 Lookup[endpoint[{-1-ee},Automatic,ee]["Requirements"],"CoefficientUpperOrder"]==={-1,0}];
jordan={{0,1,0},{0,0,1},{0,0,0}};
r=DetermineEndpointEpsilonOrders[<|"DimensionalRegulator"->ee,
 "ExponentMatrix"->ee IdentityMatrix[3]+jordan|>,<|"ThroughOrder"->0|>];
FTAssert["Jordan matrix moment can have a third order pole",
 r["MatrixMoments"][[1,"CoefficientUpperOrders",1,3]]===3];
r=DetermineEndpointEpsilonOrders[<|"DimensionalRegulator"->ee,
 "ExponentMatrix"->ee(IdentityMatrix[3]+jordan)|>,<|"ThroughOrder"->0|>];
FTAssert["epsilon times an invertible constant matrix has only a simple moment pole",
 Max[Flatten[r["MatrixMoments"][[1,"CoefficientUpperOrders"]]]]===1];

frob[a_] := DetermineFrobeniusLaurentBounds[<|"DimensionalRegulator"->ee,
 "NormalVariable"->xx,"ConnectionMatrix"->a/xx|>];
r=frob[ee IdentityMatrix[2]];
FTAssert["nonresonant local frame requires no positive Taylor coefficient",
 r["LastResonantIndex"]===0 && r["InverseLocalFundamentalMatrixLaurentLowerBound"]===0];
r=frob[{{1+ee^3,xx},{0,0}}];
FTAssert["near resonance derives matching pole bound without a matching solution",
 r["LocalFundamentalMatrixLaurentLowerBound"]===-3 &&
 r["InverseLocalFundamentalMatrixLaurentLowerBound"]===-3 &&
 r["FrobeniusCoefficientMatrices"][[2,1,2]]===-ee^-3];
r=frob[{{1,xx},{0,0}}];
FTAssert["persistent resonance is solved with logarithms",
 r["FrobeniusCoefficientMatrices"][[2,1,2]]===r["LogarithmVariable"] &&
 r["LocalFundamentalMatrixLaurentLowerBound"]===0];
r=frob[{{2+ee,xx^2},{0,0}}];
FTAssert["last resonant index follows integer eigenvalue differences",
 r["LastResonantIndex"]===2 && r["FrobeniusCoefficientMatrices"][[3,1,2]]===-1/ee];
FTAssert["a pole approaching the endpoint prevents a uniform local conclusion",
 FailureQ[frob[{{1+xx ee/(xx+ee)}}]]];

req=<|"BasePoint"->{1/5},"RequestedEpsilonOrders"->{0,1,2},
 "RequestedRows"->{1},"AnalyticDomain"->"Ordinary neighborhood of 1/5",
 "BranchPrescription"->"Continuation from the base point"|>;
sol=ConstructMasterIntegralSolution[<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{ee {{xx,0},{0,1}}},
 "BasisTransformationMatrix"->qmat|>,req,"AutomaticPreparation"->False];
FTAssert["finite constructor uses the computed entrywise requirements",
 MasterIntegralSolutionQ[sol] && sol["TransformedSystemEpsilonOrderRange"]==={0,2}];
FTAssert["pruned finite coefficients satisfy independent exact DE identities",
 AssociationQ[VerifyMasterIntegralSolution[sol,"IdentityCheck"->"Exact"]]];
(* Scalar diagonal prepared solution gives an independent closed form. *)
v=MasterIntegralSolutionCoefficient[sol,1,2];
aa=sol["AlgebraicDefinitions"];ff=sol["IntegralDefinitions"];
Do[v=v/.FeynFacetSolution`a[j]->aa[[j]],{j,Length[aa],1,-1}];
Do[With[{f=ff[[j]]},v=v/.FeynFacetSolution`F[j,u_]:>
 Inactive[Integrate][f["Integrand"],{f["IntegrationVariable"],0,u}]],{j,Length[ff],1,-1}];
v=v/.FeynFacetSolution`K[j_Integer,u_]:>
 (sol["KernelDefinitions"][[j,"Expression"]]/.sol["KernelDefinitions"][[j,"Parameter"]]->u);
expected=qmat.DiagonalMatrix[{Exp[ee(xx^2-1/25)/2],Exp[ee(xx-1/5)]}].Inverse[qmat];
FTAssert["optimized original-basis coefficients agree with the closed exponential solution",
 Simplify[Activate[v]-Map[SeriesCoefficient[#,{ee,0,2}]&,expected[[1]]]]==={0,0}];

r=calc[<|"I"->Missing[]|>,
 {linear["F",{<|"Input"->"I","CoefficientLaurentLowerBound"->-4|>}]},<|"F"->0|>];
FTAssert["saved coefficient valuations yield upper orders without fabricated coefficients",
 r["RequiredInputUpperOrders"]===<|"I"->4|> &&
 MissingQ[r["CoefficientExpansionOrders"][[1,"Coefficient"]]] &&
 r["Status"]==="AdditionalLaurentBoundsRequired"];
r=calc[<|"I"->0|>,
 {linear["F",{<|"Input"->"I","CoefficientLaurentLowerBound"->Infinity|>}]},<|"F"->0|>];
FTAssert["supplied zero coefficient bound remains conditional",
 r["SuppliedCoefficientBounds"]=!={} && r["Status"]==="SufficientForAssumedInputBounds"];
FTAssert["non-Laurent endpoint dependence is not accepted from its finite limit",
 FailureQ[bound[{1+Sqrt[ee]}]] && FailureQ[endpoint[{1+Sqrt[ee]}]]];

r=DetermineEpsilonOrders[<|"DimensionalRegulator"->ee,"Entries"->{
 <|"MasterIntegralIndex"->4,"HardFunctionCoefficientEpsilonValuation"->-2|>,
 <|"MasterIntegralIndex"->7,"HardFunctionCoefficientEpsilonValuation"->Missing["ZeroColumn"]|>}|>,
 <|"ThroughOrder"->0|>];
FTAssert["coefficient-table adapter preserves indices and skips zero columns",
 r["RequiredInputUpperOrders"]===<|"I4"->2|> &&
 Keys[r["MasterIntegralInputMap"]]==={"I4","I7"} &&
 r["Status"]==="AdditionalLaurentBoundsRequired"];

boundSol=ConstructMasterIntegralSolution[<|"KinematicVariables"->{xx},"DimensionalRegulator"->ee,
 "ConnectionMatrices"->{{{ee}}}|>,<|"BasePoint"->{1/5},
 "RequestedMasterIntegralEpsilonOrders"->{0},
 "InitialConstantLaurentLowerBounds"->{bound[{-1-ee}]},
 "AnalyticDomain"->"Ordinary neighborhood","BranchPrescription"->"Base point continuation"|>];
FTAssert["derived integral bounds can directly request solved master coefficients",
 MasterIntegralSolutionQ[boundSol] &&
 boundSol["InitialConstantLowerBoundStatus"]==="BoundsEstablishedForSuppliedIntegralRepresentations" &&
 boundSol["RequestedEpsilonOrders"]==={0,1}];
corrupted=Join[sol,<|"TransformedCoefficientUpperOrders"->ConstantArray[-Infinity,{2,2}]|>];
FTAssert["a changed storage mask cannot bypass the stored order requirements",
 !MasterIntegralSolutionQ[corrupted]];
FTReport[];

