(* Independent validation; reference coefficients never enter production. *)
$HistoryLength=0;$MaxExtraPrecision=50;
root=DirectoryName[ExpandFileName[$InputFileName],3];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];Get[root<>"/FeynFacet/Solution.m"];$PrePrint=.;
args=Rest[$ScriptCommandLine];If[Length[args]<1,Print["Usage: check_sidis_nnlo.wls PROJECT [POINT_INDEX]"];Exit[2]];
projectName=First[args];pointIndex=If[Length[args]>1,ToExpression[args[[2]]],1];
project=FeynFacet`ReadProjectCard[root<>"/Projects/"<>projectName];pol=First[project["Polarization"]["Incoming"]]==="L";
validation=project["Directory"]<>"/NNLO/q-q/Results/Validation";
refFile=validation<>"/ReferenceNNLOCoefficients.wl";
If[!FileExistsQ[refFile],Print["Translated independent NNLO reference required"];Exit[1]];
reference=FeynFacet`FamilyArtifactRead[refFile];
points={{5/11,3/13},{4/5,2/3},{3/13,5/11},{2/3,4/5},{5/11,3/13}};
If[!IntegerQ[pointIndex]||!Between[pointIndex,{1,Length[points]}],Exit[2]];
point=points[[pointIndex]];wp=50;
scaleRules=If[pointIndex===1,{Q2->7/3,muR2->7/3,muF2->7/3,muD2->7/3},
 {Q2->7/3,muR2->5/2,muF2->11/5,muD2->13/4}];
rules=Join[Thread[{x,z}->point],scaleRules,{eU->2/3,eD->-1/3,nU->2,nD->1,
 FeynCalc`CA->3,FeynCalc`CF->4/3,FeynCalc`Tf->1/2,TR->1/2,FeynFacet`\[Alpha]s->1}];
If[pointIndex===5,rules=Join[KeyDrop[Association[rules],{eU,eD,nU,nD,FeynCalc`CA,FeynCalc`CF}]//Normal,
 {eU->4/7,eD->-2/5,nU->3,nD->2,FeynCalc`CA->5,FeynCalc`CF->12/5}]];
refRules={NC->FeynCalc`CA,NF->nU+nD,LMUR->Log[muR2/Q2],LMUF->Log[muF2/Q2],LMUA->Log[muD2/Q2],
 rln2->Log[2],poly2->1+2x+x^2-4x z,sqrtxz1->Sqrt[1-2z+z^2+4x z],
 sqrtxz2->Sqrt[1+2x+x^2-4x z],sqrtxz3->Sqrt[x/z],
 ReferenceRegion[r1]->Boole[z<1-x],ReferenceRegion[r2]->Boole[z>1-x],
 ReferenceRegion[t1]->Boole[z>x],ReferenceRegion[t2]->Boole[z<x],
 ReferenceRegion[u1]->Boole[z<1-x&&z<x],ReferenceRegion[u2]->Boole[z>1-x&&z<x],
 ReferenceRegion[u3]->Boole[z<1-x&&z>x],ReferenceRegion[u4]->Boole[z>1-x&&z>x],
 InverseTangentIntegral[a_]:>(PolyLog[2,I a]-PolyLog[2,-I a])/(2I)};
n=Length[project["StructureFunctions"]];actual=<||>;expected=<||>;pole=<||>;
walk[tree_,path_List,depth_Integer]:=If[depth===0,
 Table[Append[path,i]->If[ListQ[tree],tree[[i]],tree],{i,n}],
 Join[walk[tree["DeltaCoefficient"],Append[path,"Delta"],depth-1],
  Flatten[KeyValueMap[walk[#2,Append[path,{"Plus",#1}],depth-1]&,tree["PlusCoefficients"]],1],
  walk[tree["RegularCoefficient"],Append[path,"Regular"],depth-1]]];
stateObjects={{Dd[1-x],Dn[0,1-x],Dn[1,1-x],Dn[2,1-x],Dn[3,1-x]},
 {Dd[1-z],Dn[0,1-z],Dn[1,1-z],Dn[2,1-z],Dn[3,1-z]}};
objects=Flatten[stateObjects];states={"Delta",{"Plus",0},{"Plus",1},{"Plus",2},{"Plus",3}};
expectedExpression[channel_,component_]:=Module[{prefix,key,sumCharges=nU eU^2+nD eD^2,sign},
 prefix=If[pol,"DC2","C2"<>If[component===1,"T","L"]];
 Switch[channel,
 "q-q"|"qbar-qbar",eU^2 reference[prefix<>"Q2QNS"]+sumCharges reference[prefix<>"Q2QPS"],
 "q-qbar"|"qbar-q",eU^2 reference[prefix<>"Q2QB"],
 "q-g"|"qbar-g",eU^2 reference[prefix<>"Q2G"],
 "g-q"|"g-qbar",eU^2 reference[prefix<>"G2Q"],
 "g-g",sumCharges reference[prefix<>"G2G"],
 _,sign=If[MemberQ[{"q-qp","qbar-qpbar"},channel],1,-1];
  eU^2 reference[prefix<>"Q2QP1"]+eD^2 reference[prefix<>"Q2QP2"]+sign eU eD reference[prefix<>"Q2QP3"]]
];
Do[
 result=FeynFacet`ReadPartonicResult[project["Directory"]<>"/NNLO/"<>channel<>"/Results/CombinedLaurentResult.wl"];
 If[!AssociationQ[result],Print["Missing combined result ",channel];Exit[1]];
 finite=Association[walk[result["Coefficients"][0],{channel},2]];
 KeyValueMap[AssociateTo[actual,#1->(2Pi)^2 #2]&,finite];
 Do[KeyValueMap[AssociateTo[pole,Prepend[#1,k]->(2Pi)^2 #2]&,Association[walk[result["Coefficients"][k],{channel},2]]],
 {k,Select[Keys[result["Coefficients"]],#<0&]}];
 Do[
 expression=expectedExpression[channel,i];
 terms=FeynFacet`PolynomialCoefficientRules[expression,objects];
 If[FailureQ[terms],Print["Nonpolynomial reference distribution"];Exit[1]];
 Do[
 powers=First[term];coefficient=Last[term];path={};
 Do[sub=Take[powers,{5(j-1)+1,5j}];
  If[Total[sub]>1,Print["Invalid reference distribution degree"];Exit[1]];
  AppendTo[path,If[Total[sub]===0,"Regular",states[[First@FirstPosition[sub,1]]]]],{j,2}];
 AssociateTo[expected,Append[Prepend[path,channel],i]->coefficient],
 {term,terms}],
 {i,n}],
{channel,project["Orders"]["NNLO"]}];
keys=Union[Keys[actual],Keys[expected]];
a=Lookup[actual,keys,0];b=Lookup[expected,keys,0]//.refRules;
Print["EVALUATING POINT ",pointIndex," FINITE STRATA ",Length[keys]," POLE STRATA ",Length[pole],
 " GPLS ",Length[DeleteDuplicates[Cases[{a,Values[pole]},_FeynFacetSolution`G,{0,Infinity}]]]];
{seconds,numerical}=AbsoluteTiming[Quiet[FeynFacetSolution`EvaluateGPLExpression[{a,Values[pole]},rules,
 "WorkingPrecision"->wp,"TimeLimit"->180,"RealLetterPrescription"->If[MemberQ[{3,4},pointIndex],1,None]],N::meprec]];
If[FailureQ[numerical]||!AllTrue[Flatten[numerical],NumericQ],
 FeynFacet`FamilyArtifactWrite[numerical,validation<>"/NNLONumericalFailure.wl"];Print["NUMERICAL FAILED ",StringTake[ToString[numerical,InputForm],UpTo[4000]]];Exit[1]];
refNumeric=N[b/.rules,wp];
If[!VectorQ[refNumeric,NumericQ],Print["REFERENCE UNRESOLVED ",DeleteDuplicates[Cases[refNumeric,_Symbol,Infinity]]];Exit[1]];
errors=MapThread[Abs[#1-#2]/Max[1,Abs[#1],Abs[#2]]&,{numerical[[1]],refNumeric}];
poleErrors=Abs[numerical[[2]]];
failed=Pick[keys,#>10^-30&/@errors,True];poleFailed=Pick[Keys[pole],#>10^-30&/@poleErrors,True];
out=<|"Point"->point,"ParameterRules"->rules,"WorkingPrecision"->wp,"EvaluationSeconds"->seconds,
 "FiniteCoefficientCount"->Length[keys],"PoleCoefficientCount"->Length[pole],
 "MaximumFiniteRelativeError"->Max[errors],"MaximumPoleAbsoluteResidual"->Max[poleErrors],
 "FailedFiniteCoefficients"->failed,"FailedPoleCoefficients"->poleFailed,
 "FiniteValues"->AssociationThread[keys,Transpose[{numerical[[1]],refNumeric,errors}]],
 "PoleValues"->AssociationThread[Keys[pole],numerical[[2]]],
 "ReferenceFiles"->{refFile,root<>"/External/References/SIDIS/SingleValued_2505.18109v2/README.md"},
 "Status"->If[failed==={}&&poleFailed==={},"Passed","Failed"]|>;
FeynFacet`FamilyArtifactWrite[out,validation<>"/NNLOComparisonPoint"<>ToString[pointIndex]<>".wl",Compression->Automatic];
Print["NNLO COMPARISON ",out["Status"]," FINITE FAILED ",Length[failed],"/",Length[keys]," POLES FAILED ",Length[poleFailed],"/",Length[pole],
 " MAX ERR ",N[Max[errors],6]," MAX POLE ",N[Max[poleErrors],6]," SECONDS ",seconds];
Print["FAILED FINITE ",Take[failed,UpTo[15]]," FAILED POLES ",Take[poleFailed,UpTo[15]]];
If[out["Status"]=!="Passed",Exit[1]];
