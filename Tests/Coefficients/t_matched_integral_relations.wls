#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;
root=DirectoryName[ExpandFileName[$InputFileName],3];Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
prop[m_]:=FeynCalc`FeynAmpDenominator[FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[m,D],0,0,{1,1}]];
family[name_,momentum_]:=<|"Topology"->FeynCalc`FCTopology[name,{prop[k],prop[k-momentum]},
 {k},{p,q},{FeynCalc`SPD[p]->s,FeynCalc`SPD[q]->0,FeynCalc`SPD[p,q]->s/2}],
 "CutIndices"->{1},"CutMomenta"->{k},"CutDirections"->{1}|>;
a=FeynCalc`GLI["A",{1,1}];targets=FeynCalc`GLI["Collision",{1,#}]&/@{1,0,-1,-2};
basis=Prepend[targets,a];families={family["A",p],family["Collision",q]};
catalog=<|"Integrals"->basis,"Families"->families,"Normalization"->"Bare normalized GLIs",
 "PreferredIntegrals"->targets|>;
source=<|"Integrals"->{First[targets]},"Families"->{family["Collision",p]},
 "Normalization"->catalog["Normalization"]|>;
match=Append[FeynFacet`MatchCutIntegralCatalogs[source,catalog],"TargetCatalog"->catalog];
row={1,-1/eps,-2,-3,-4};
relations=<|"Catalog"->KeyDrop[catalog,"PreferredIntegrals"],"Basis"->basis,
 "ConstraintMatrix"->{row},"Rules"->{a->-Rest[row].targets},
 "DimensionalRegulator"->eps,"KinematicVariables"->{v,w}|>;
relations=Append[relations,"ScaleConvention"-><|"Scale"->s,"ReferenceScale"->1,
 "KinematicVariables"->{v,w},"CoordinateRules"->{},"ParameterMassDimensions"-><|s->2|>|>];
request=<|"TargetIntegrals"->targets,"Scale"->s,"ParameterMassDimensions"-><|s->2|>,
 "Assumptions"->s>0,"DimensionalRegulator"->eps,"KinematicVariables"->{v,w}|>;
result=FeynFacet`ReduceMatchedIntegralCatalog[match,relations,request];
FTTest`FTAssert["independent source names remain disjoint through relation composition",
 AssociationQ[result]&&First[First[result["Rules"]]]===First[targets]&&
 FeynFacet`Private`relationZeroQ[Last[First[result["Rules"]]]-
 (targets[[1]]/eps+2targets[[2]]/s+3targets[[3]]/s^2+4targets[[4]]/s^3)]];
FTTest`FTAssert["scale restoration includes negative numerator indices",
 AssociationQ[result]&&Lookup[result["IntegralRelationReduction"]["PhysicalScaleHomogeneity"]["Weights"],basis]==={-2,-2,-1,0,1}];
FTTest`FTAssert["linear relations retain exact witnesses independently of affine evidence",
 result["IntegralRelationReduction"]["Witnesses"][[1,"ConstraintRowCombination"]]==={1}&&
 KeyExistsQ[result,"AffineRules"]];
FTTest`FTAssert["reordering the declared basis without its catalog is rejected",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,Append[relations,"Basis"->Reverse[basis]],request],
 Failure["OrderedRelationBasisAndDefinitionsMismatch",_Association]]];
FTTest`FTAssert["a wrong constraint-column order fails its exact witness",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,Append[relations,"ConstraintMatrix"->{Reverse[row]}],request],
 Failure["ExactIntegralRelationWitnessFailed",_Association]]];
FTTest`FTAssert["relation catalogs cannot change the integral normalization",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,Append[relations,"Catalog"->
 Append[relations["Catalog"],"Normalization"->2]],request],
 Failure["OrderedRelationBasisAndDefinitionsMismatch",_Association]]];
FTTest`FTAssert["the regulator and coordinate convention must be explicit and identical",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,relations,Append[request,"KinematicVariables"->{w,v}]],
 Failure["RelationRegulatorOrCoordinatesMismatch",_Association]]];
badFamilies=ReplacePart[families,2->Join[families[[2]],<|"Topology"->
 ReplacePart[families[[2,"Topology"]],3->{k,ell}]|>]];
bad=Catch[FeynFacet`Private`relationScaleWeights[basis,badFamilies,catalog["Normalization"],request],"IntegralRelations"];
FTTest`FTAssert["unequal loop measures cannot use the common-loop scale shortcut",FailureQ[bad]];
badFamilies=Append[#,"MasterIntegralPrefactor"->2]&/@families;
bad=Catch[FeynFacet`Private`relationScaleWeights[basis,badFamilies,catalog["Normalization"],request],"IntegralRelations"];
FTTest`FTAssert["extra integral prefactors require an explicit normalization conversion",
 MatchQ[bad,Failure["BareHomogeneousParticleCutIntegralsRequired",_Association]]];
badFamilies=families/.FeynCalc`StandardPropagatorDenominator[m_,0,0,power_]:>
 FeynCalc`StandardPropagatorDenominator[m,0,-1,power];
bad=Catch[FeynFacet`Private`relationScaleWeights[basis,badFamilies,catalog["Normalization"],request],"IntegralRelations"];
FTTest`FTAssert["a fixed mass scale cannot disappear during homogeneous restoration",
 MatchQ[bad,Failure["IntegralScaleHomogeneityNotEstablished",_Association]]];
terms={<|"Representation"->"LaurentSeries","PreFactor"->1/eps,
 "Coefficient"-><|"SeriesVariable"->eps,"Orders"-><|0->2|>,"SeriesTruncation"->0|>|>};
FTTest`FTAssert["a relation pole raises the required stored epsilon order",
 MatchQ[FeynFacet`ExpandMasterIntegralCoefficient[<|"Terms"->terms|>,eps,{0,0}],
 Failure["CoefficientEpsilonOrdersInsufficient",_Association]]];
FTTest`FTAssert["scale restoration cannot be applied twice to a composed match",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[result,relations,request],
 Failure["IntegralRelationReductionAlreadyApplied",_Association]]];
FTTest`FTAssert["the regulator and dimensionless ratios cannot acquire scale dimensions",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,relations,Append[request,
 "ParameterMassDimensions"-><|s->2,v->2|>]],
 Failure["SavedIntegralScaleConventionMismatch",_Association]]];
FTTest`FTAssert["an unrelated positive scale cannot replace the saved normalization scale",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,relations,Join[request,<|
 "Scale"->otherScale,"Assumptions"->otherScale>0,"ParameterMassDimensions"-><|s->2,otherScale->2|>|>]],
 Failure["SavedIntegralScaleConventionMismatch",_Association]]];
FTTest`FTAssert["coordinate substitutions cannot delete integral identifiers",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,relations,Append[request,"KinematicRules"->{targets[[1]]->0}]],
 Failure["CoordinateRulesDoNotMatchSavedConvention",_Association]]];
FTTest`FTAssert["a scalar substitution cannot silently specialize the saved kinematics",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,relations,Append[request,"KinematicRules"->{v->0}]],
 Failure["CoordinateRulesDoNotMatchSavedConvention",_Association]]];
FTTest`FTAssert["malformed nested adapter arguments return a failure",
 MatchQ[FeynFacet`ReduceMatchedIntegralCatalog[match,42,request],
 Failure["CatalogMatchRelationsAndRequestAssociationsRequired",_Association]]];
FTTest`FTAssert["affine destinations are labeled separately from composed rules",
 KeyExistsQ[result,"AffineMappings"]&&!KeyExistsQ[result,"Mappings"]];
FTTest`FTReport[];
