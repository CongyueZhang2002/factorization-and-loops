Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
ints=FeynCalc`GLI[ResidualTest,{#}]&/@Range[5];
{a,b,c,d,f}=ints;
rows={<|a->(rx+1),b->-(rx+1)^2,c->2|>,<|a->1,b->-(rx+1)|>,<|d->1,f->-rx|>};
known={a->(rx+1)b};
residual=FeynFacet`EliminateKnownIntegralRules[rows,{a,c},known];
FTTest`FTAssert["substitution retains constraints outside the requested target span",
 AssociationQ[residual]&&residual["Rows"]==={<|c->2|>,<|d->1,f->-rx|>}&&residual["Targets"]==={b,c}];
FTTest`FTAssert["exact zero equations disappear without deleting a nonzero column",
 residual["OriginalEquationCount"]===3&&residual["ResidualEquationCount"]===2&&residual["ResidualColumnCount"]===3];
FTTest`FTAssert["the residual has exactly the original equations on the known relation",
 AllTrue[MapThread[Factor[#1-#2]&,{(Total[KeyValueMap[Times,#]]&/@rows)/.known,
  {2c,0,d-rx f}}],#===0&]];
FTTest`FTAssert["unclosed and cyclic relations fail instead of losing columns",
 FailureQ[FeynFacet`EliminateKnownIntegralRules[rows,{a},{a->b,b->c}]]&&
 FailureQ[FeynFacet`EliminateKnownIntegralRules[rows,{a},{a->b,b->a}]]];
FTTest`FTAssert["nonlinear, inhomogeneous, approximate and duplicate rules fail",
 AllTrue[{{a->b^2},{a->b+1},{a->1.1b},{a->b,a->c}},
 FailureQ[FeynFacet`EliminateKnownIntegralRules[rows,{a},#]]&]];
FTTest`FTAssert["a vanishing target does not create a fake master",
 FeynFacet`EliminateKnownIntegralRules[{}, {a}, {a->0}]["Targets"]==={}];

definition=FeynFacet`CreateMasslessPhaseSpaceDefinition[<|"Name"->ResidualPhase,
 "FinalMomenta"->{rk1,rk2},"TotalMomentum"->rq,"ExternalMomenta"->{rq},
 "KinematicRules"->{FeynCalc`SPD[rq]->rs},"Assumptions"->rs>0|>];
family=FeynFacet`CreateCutIntegralFamily[definition];name=family["Topology"][[1]];
targets=FeynCalc`GLI[name,#]&/@{{1,1},{2,1},{1,2},{3,1},{2,2}};
work=CreateDirectory[];
request=<|"SeedPolicy"->"TargetDownsets","Threads"->1,"PreferredMasterIntegrals"->{First[targets]},
 "HomogeneousScale"->rs,"RationalSolver"->"FireFly"|>;
prior=FeynFacet`KiraReduction[{family},Take[targets,3],Join[request,<|"WorkingDirectory"->work<>"/Prior"|>]];
full=FeynFacet`KiraReduction[{family},targets,Join[request,<|"WorkingDirectory"->work<>"/Full"|>]];
If[!AllTrue[{prior,full},AssociationQ],Print[InputForm[{prior,full}]];FTTest`FTReport[];Exit[1]];
reduced=FeynFacet`KiraReduction[{family},targets,Join[request,
 <|"WorkingDirectory"->work<>"/Residual","KnownIntegralRules"->prior["Rules"]|>]];
FTTest`FTAssert["native residual reconstruction preserves the full physical-scale reduction",
 AssociationQ[reduced]&&reduced["Masters"]===full["Masters"]&&
 AllTrue[Factor/@((targets/.reduced["Rules"])-(targets/.full["Rules"])),#===0&]];
ids=FeynFacet`FamilyArtifactRead[work<>"/Residual/IntegralIdentifiers.wxf"];
FTTest`FTAssert["solved columns are absent from the new native system and scale is removed once",
 AssociationQ[ids]&&Intersection[ids["IndexedIntegrals"],First/@prior["Rules"]]==={}&&
 FreeQ[ids["CoefficientVariables"],rs]&&reduced["KnownRuleElimination"]["ResidualColumnCount"]<
 reduced["KnownRuleElimination"]["OriginalColumnCount"]];
cached=FeynFacet`KiraReduction[{family},targets,Join[request,
 <|"WorkingDirectory"->work<>"/Residual","KnownIntegralRules"->prior["Rules"]|>]];
FTTest`FTAssert["a cached residual result restores original target rules exactly once",
 AssociationQ[cached]&&TrueQ[cached["ReusedSolvedReduction"]]&&cached["Rules"]===reduced["Rules"]];
FeynFacet`FamilyArtifactDelete[work<>"/Residual/Reduction.wl"];
resumed=Block[{FeynFacet`Private`cutGenerateIBPBatch},
 FeynFacet`Private`cutGenerateIBPBatch[___]:=Failure["UnexpectedEquationRegeneration",<||>];
 FeynFacet`KiraReduction[{family},targets,Join[request,
  <|"WorkingDirectory"->work<>"/Residual","KnownIntegralRules"->prior["Rules"]|>]]];
FTTest`FTAssert["unfinished residual imports reuse equations and preserve their original scale and statistics",
 AssociationQ[resumed]&&resumed["Rules"]===reduced["Rules"]&&
 resumed["KnownRuleElimination"]===reduced["KnownRuleElimination"]];
changed=FeynFacet`KiraReduction[{family},targets,Join[request,
 <|"WorkingDirectory"->work<>"/Residual","KnownIntegralRules"->{}|>]];
FTTest`FTAssert["changed known relations cannot reuse a native reconstruction state",
 MatchQ[changed,Failure["KiraWorkspaceDefinitionMismatch",_]]];
zero=FeynFacet`KiraReduction[{family},{targets[[2]]},<|"WorkingDirectory"->work<>"/Zero",
 "KnownIntegralRules"->{targets[[2]]->0}|>];
FTTest`FTAssert["all-zero targets finish directly under their supplied exact relation",
 AssociationQ[zero]&&zero["Masters"]==={}&&zero["Rules"]==={targets[[2]]->0}&&
 !FileExistsQ[work<>"/Zero/jobs.yaml"]];
identity=FeynFacet`KiraReduction[{family},Take[targets,2],<|"WorkingDirectory"->work<>"/Identity",
 "SeedIntegrals"->{},"ExtraEquations"->{<|targets[[2]]->1,targets[[1]]->-rx|>},
 "KnownIntegralRules"->{targets[[2]]->rx targets[[1]]},"HomogeneousScale"->rs|>];
FTTest`FTAssert["an empty residual system retains its unconstrained target instead of dropping it",
 AssociationQ[identity]&&identity["Masters"]==={First[targets]}&&
 !FileExistsQ[work<>"/Identity/jobs.yaml"]];
FeynFacet`FamilyArtifactDelete[work<>"/Identity/Reduction.wl"];
identityResumed=FeynFacet`KiraReduction[{family},Take[targets,2],<|"WorkingDirectory"->work<>"/Identity",
 "SeedIntegrals"->{},"ExtraEquations"->{<|targets[[2]]->1,targets[[1]]->-rx|>},
 "KnownIntegralRules"->{targets[[2]]->rx targets[[1]]},"HomogeneousScale"->rs|>];
FTTest`FTAssert["empty residual imports require neither a native solve nor a scale-normalization record",
 AssociationQ[identityResumed]&&identityResumed["Rules"]===identity["Rules"]&&
 !FileExistsQ[work<>"/Identity/jobs.yaml"]];
partial=Join[full,<|"Targets"->targets[[{1,4}]],
 "Rules"->Select[full["Rules"],First[#]===targets[[4]]&]|>];
system=FeynFacet`ConstructCutDifferentialSystem[{family},{First[targets]},{rs},
 Join[request,<|"WorkingDirectory"->work<>"/DifferentialClosure","InitialReduction"->partial,
  "KnownIntegralRules"->Select[full["Rules"],First[#]===targets[[5]]&],
  "EliminateKnownRules"->True,"MomentumDerivatives"-><|rs-><|rq->rq/(2rs)|>|>|>]];
FTTest`FTAssert["differential closure reuses prior identities in a new residual native system",
 AssociationQ[system]&&AssociationQ[system["Reduction"]["KnownRuleElimination"]]&&
 FileExistsQ[system["Reduction"]["InputWorkspace"]<>"/EquationElimination.wl"]];
FTTest`FTAssert["the residual DE gives the exact two-particle phase-volume scaling",
 AssociationQ[system]&&system["MasterIntegralBasis"]==={First[targets]}&&
 Factor[Normal[First[system["ConnectionMatrices"]]][[1,1]]-(D-4)/(2rs)]===0];
nativeDefinition=FeynFacet`FamilyArtifactRead[system["Reduction"]["InputWorkspace"]<>"/InputDefinition.wl"];
FTTest`FTAssert["a supplied identity outside the prior target set survives automatic DE propagation",
 AssociationQ[nativeDefinition]&&MemberQ[Flatten[Keys/@nativeDefinition["ExtraEquations"]],targets[[5]]]];
FTTest`FTAssert["the diagnostic native route refuses to silently ignore known identities",
 MatchQ[FeynFacet`KiraReduction[{family},targets,<|"WorkingDirectory"->work<>"/Diagnostic",
  "EquationSource"->"NativeDiagnostic","KnownIntegralRules"->prior["Rules"]|>],
  Failure["KnownIntegralRulesRequireTypedIBP",_]]];
If[StringStartsQ[ExpandFileName[work],ExpandFileName[$TemporaryDirectory]<>"/"],DeleteDirectory[work,DeleteContents->True]];
Print["RESIDUAL INTEGRAL EQUATIONS TEST COMPLETE"];
FTTest`FTReport[];
