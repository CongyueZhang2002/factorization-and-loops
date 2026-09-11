Print["FEYNFACET DRIVER ENTERED"];
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;$HistoryLength=0;
Get[root<>"/Tests/TestKit.wl"];
Clear[eps,z,v,x,y,w,tx,ty,te,ca,tc];
dir=CreateDirectory[];
master=FeynCalc`GLI["Source",{1}];target=FeynCalc`GLI["Frame",{1}];
sourceID=FeynFacet`Private`coefficientMasterID[master];
targetID=FeynFacet`Private`coefficientMasterID[target];
convention=<|"MomentumSpaceConvention"->"AMFlow"|>;
definition=<|"MasterIntegral"->master,"MomentumSpaceConvention"->"AMFlow","MasterIntegralPrefactor"->1|>;
physical=<|"Definitions"-><|"MasterIntegralDefinitions"-><|master->definition|>|>|>;
mapping=<|"Source"->master,"Representative"->target,"Factor"->1|>;
catalog=<|"CutCatalog"-><|"Normalization"->convention|>,"IntegralEquivalences"-><|
 "Mappings"->{<|"Source"->target,"Representative"->target,"Factor"->1|>}|>|>;
system=<|"OriginalMasterIntegralBasis"->{target},"KinematicVariableDefinition"-><|"ScaleNormalization"->s->1|>|>;
file=dir<>"/System.wxf";Export[file,system,"WXF"];
frame=<|"OriginalMasterIntegralBasis"->{target},"SourceDifferentialSystemFile"->file,
 "Endpoint"-><|"DimensionalRegulator"->eps|>,
 "AcceptedEndpointBinding"-><|"SourceInput"-><|"CoordinateRules"->{v->x,w->1-x-z}|>|>|>;
normalization=<|"ReferenceScale"->1,"KinematicRules"->{}|>;
rules={v->x,w->1-x-z};
bind[p_:physical,n_:normalization,c_:catalog,r_:rules]:=
 FeynFacet`Private`coefficientPlanFrameBinding[c,frame,1,p,master,mapping,n,r];
FTAssert["the physical source and accepted endpoint row have an explicit unit identity",
 AssociationQ[bind[]]&&bind[]["Status"]==="UnitPhysicalIntegralIdentityEstablished"];
FTAssert["a different reference scale cannot use unconverted physical frame bounds",
 MatchQ[bind[physical,Append[normalization,"ReferenceScale"->2]],Failure["EndpointPhysicalReferenceScaleMismatch",_]]];
FTAssert["a physical master normalization multiplier is not silently discarded",
 FailureQ[bind[<|"Definitions"-><|"MasterIntegralDefinitions"-><|master->Append[definition,"MasterIntegralPrefactor"->eps]|>|>|>]]];
FTAssert["a nonunit representative-to-frame identity requires explicit handling",
 FailureQ[bind[physical,normalization,Append[catalog,"IntegralEquivalences"-><|
 "Mappings"->{<|"Source"->target,"Representative"->target,"Factor"->2|>}|>]]]];
FTAssert["endpoint coordinate identity includes physical normalization substitutions",
 FailureQ[bind[physical,Append[normalization,"KinematicRules"->{v->2v}]]]];
data=<|"SymbolRules"-><|x->tx,y->ty,eps->te,ca->tc|>|>;
context=<|"DimensionlessCoordinates"-><|x->v,y->w|>,"ColorRules"->{}|>;
endpoint=<|"DimensionalRegulator"->eps,"NormalVariable"->z,"TangentialVariable"->v|>;
norm=<|"KinematicRules"->{w->1-v-z}|>;
effective=FeynFacet`Private`coefficientPlanEffectiveRules[data,context,norm,{},endpoint,0<v<1&&ca>1];
FTAssert["effective coordinate substitution follows production composition",
 effective==={x->v,y->1-v-z,eps->eps,ca->ca}];
contextColor=Append[context,"ColorRules"->{ca->(ca^2-1)/(2ca)}];
effectiveColor=FeynFacet`Private`coefficientPlanEffectiveRules[data,contextColor,norm,{},endpoint,0<v<1&&ca>1];
FTAssert["proved nonzero color denominators are supported",
 ListQ[effectiveColor]&&FeynFacet`Private`coefficientOrderCoordinateRulesQ[effectiveColor,eps,z,0<v<1&&ca>1]];
FTAssert["a color denominator cannot be assumed nonzero without a domain",
 FailureQ[FeynFacet`Private`coefficientPlanEffectiveRules[data,contextColor,norm,{},endpoint,0<v<1]]];
FTAssert["duplicate substitution keys fail instead of silently choosing one",
 FailureQ[FeynFacet`Private`coefficientPlanEffectiveRules[data,context,norm,{v->x,v->y},endpoint,0<v<1]]];
FTAssert["nonlinear endpoint transformations remain explicitly unsupported",
 FailureQ[FeynFacet`Private`coefficientPlanEffectiveRules[data,context,norm,{v->v^2},endpoint,0<v<1]]];
FTAssert["order analysis rejects untracked regulator substitution even without planning",
 !FeynFacet`Private`coefficientOrderCoordinateRulesQ[{x->eps^-1},eps,z,True]];
FTAssert["order analysis verifies parameter units instead of trusting a flag",
 !FeynFacet`Private`coefficientOrderCoordinateRulesQ[{x->1/ca},eps,z,True]];
DeleteDirectory[dir,DeleteContents->True];FTReport[];
