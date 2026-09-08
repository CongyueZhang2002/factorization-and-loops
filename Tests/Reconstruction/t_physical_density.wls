$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
Begin["FeynFacet`Private`"];
Get[Global`root<>"/FeynFacet/Coefficients/PhysicalDensity.wl"];
End[];
passed=0;failed=0;
assert[name_,condition_]:=If[TrueQ[condition],passed++;Print["PASS ",name],failed++;Print["FAIL ",name]];
m=FeynCalc`GLI["Synthetic",{1,1,1}];
tab=<|"Format"->"FeynFacet-MasterIntegralCoefficients","FormatVersion"->1,
 "Definitions"-><|"Setup"-><||>|>,"PreFactor"->dist[xa]/xa,
 "DimensionalRegulator"->eps,"FractionMeasure"->dxa,"PhaseSpace"->oldMeasure,
 "Masters"->{<|"Master"->m,"Terms"->{<|"PreFactor"->1/(eps t),"Representation"->"LaurentSeries",
  "Coefficient"-><|"SeriesVariable"->eps,"Orders"-><|-1->2,0->3,1->5|>,"SeriesTruncation"->1|>|>}|>},
 "RemainderTerms"->{},"Contributions"->{<|"Weight"->1/2|>}|>;
def=<|"MasterIntegral"->m,"Dimension"->4-2eps,"DimensionalRegulator"->eps,
 "LoopMomenta"->{q1,q2},"Prescription"->{0,0},"PhaseSpaceLoopCount"->2,
 "MeasurePrefactor"->(2Pi)^(-5+4eps),"MasterIntegralPrefactor"->1,
 "PropagatorPowers"->{1,1,1},"PropagatorTypes"->ConstantArray["QuadraticLorentzian",3],
 "PermittedMetadata"->Missing["NotNeeded"]|>;
request=<|"Scale"->s,"ReferenceScale"->1,"Assumptions"->s>0,
 "KinematicRules"->{t->-s v},"EliminatedKinematicVariables"->{t},
 "FluxFactor"->1/(2s),"AdditionalFactors"-><|"DeclaredFactor"->eps^(-2)|>|>;
res=FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->def|>,request];
assert["construction succeeds",AssociationQ[res]];
If[AssociationQ[res],
 e=res["DimensionalRegulator"];term=First[First[res["Masters"]]["Terms"]];
 expected=(-2^(5-4e)Pi^(1-2e))s^(1-2e)*(1/(-e s v))*(1/(2s))*e^-2;
 assert["measure sign, homogeneity, coordinates and declared factors",FullSimplify[term["PreFactor"]/expected,s>0]===1];
 assert["global distribution prefactor retained",res["PreFactor"]===tab["PreFactor"]];
 assert["Laurent representation and explicit truncation retained",term["Representation"]==="LaurentSeries"&&term["Coefficient"]["SeriesTruncation"]===1&&term["Coefficient"]["Orders"]===<|-1->2,0->3,1->5|>];
 assert["contribution weights retained",res["Contributions"]===tab["Contributions"]];
 assert["source phase measure retained only as provenance",res["PhaseSpace"]===1&&res["SourcePhaseSpace"]===oldMeasure];
 assert["unsupplied Jacobian recorded",res["PhysicalDensityNormalization"]["SuppliedFactors"]["ObservedVariableJacobian"]["Status"]==="NotSupplied"];
 assert["epsilon pole factors cannot consume missing orders",FailureQ[FeynFacet`ExpandMasterIntegralCoefficient[First[res["Masters"]],e,{-4,0}]]];
 assert["repeated conversion rejected",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[res,<|m->def|>,request]]];
];
assert["normalized ID keys accepted",AssociationQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|{"Synthetic",{1,1,1}}->def|>,request]]];
assert["missing integral definition rejected",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<||>,request]]];
assert["mismatching definition identity rejected",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->Join[def,<|"MasterIntegral"->FeynCalc`GLI["Other",{1,1,1}]|>]|>,request]]];
assert["nonpositive scale rejected",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->def|>,Join[request,<|"Scale"->-1|>]]]];
assert["undeclared positive scale rejected",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->def|>,KeyDrop[request,"Assumptions"]]]];
assert["unresolved declared coordinate rejected",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->def|>,Join[request,<|"KinematicRules"->{}|>]]]];
assert["duplicate normalized definition keys rejected",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->def,{"Synthetic",{1,1,1}}->def|>,request]]];
assert["observed measure is recorded when supplied",Module[{rr=FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->def|>,Join[request,<|"ObservableMeasureConvention"->"Fixed observed momentum"|>]]},AssociationQ[rr]&&rr["PhysicalDensityNormalization"]["ObservableMeasureConvention"]["Convention"]==="Fixed observed momentum"]];
assert["epsilon-dependent scale rejected across regulator aliases",FailureQ[FeynFacet`ConstructPhysicalMasterCoefficientDensity[tab,<|m->def|>,Join[request,<|"Scale"->1+eps,"Assumptions"->eps>0|>]]]];
Print["TALLY passed=",passed," failed=",failed];Exit[If[failed===0,0,1]];
