(* From a fixed normalization and integral definitions to all required orders.
   This file never calls the finite global solution constructor. *)
Begin["FeynFacet`Private`"];
Clear[epsOrderIntervals,
 epsOrderPrepareFrame,epsOrderOrdinaryPointQ,epsOrderSelectBasePoint,
 epsOrderLocalBoundary,epsOrderCloseMatrix,epsOrderMasterExpansion,
 epsOrderCutRecurrenceRequested,epsOrderCutRecurrenceBounds,
 epsOrderPointIntegralDefinitions,epsOrderPhysicalPointQ,epsOrderRequestedBasePoint];

epsOrderIntervals[lo_,hi_] := Which[
 hi===-Infinity || lo===Infinity,{},MissingQ[lo] || MissingQ[hi],Missing["LaurentBoundRequired"],
 True,Range[lo,hi]];
epsOrderPrepareFrame[s_,seconds_,automatic_] := Module[
 {a,vars,e,n,t,h,hi,b,p,q,qi,coefficientSource,m,mi},
 a=Normal /@ Lookup[s,"ConnectionMatrices",{}];vars=Lookup[s,"KinematicVariables",{}];
 e=Lookup[s,"DimensionalRegulator",None];n=If[a==={},0,Length[First[a]]];
 If[n<1 || vars==={} || Length[a]=!=Length[vars] || !DuplicateFreeQ[vars] ||
   !VectorQ[vars,MatchQ[#,_Symbol]&] || e===None || !MatchQ[e,_Symbol] || MemberQ[vars,e] ||
   !AllTrue[a,Dimensions[#]==={n,n}&],epsOrderFail["DifferentialSystemRequired"]];
 t=Normal[Lookup[s,"BasisTransformationMatrix",IdentityMatrix[n]]];
 h=Normal[Lookup[s,"HomogeneousFundamentalMatrix",IdentityMatrix[n]]];
 If[Dimensions[t]=!={n,n} || Dimensions[h]=!={n,n} || !FreeQ[h,e] ||
   !FreeQ[{a,t,h},_Real],epsOrderFail["ExactBasisAndConnectionRequired"]];
 hi=Map[Cancel,Inverse[h],{2}];
 b=MapThread[hi.#1.h-hi.D[h,#2]&,{a,vars}];
 p=If[TrueQ[automatic],
   Catch[solutionPrepareConnection[b,vars,e,seconds,
     <|"BlockReductionData"->Lookup[s,"EpsilonZeroBlockReductions",{}]|>],"FiniteSolution"],
   <|"ConnectionMatrices"->b,"BasisTransformationMatrix"->IdentityMatrix[n],
     "InverseBasisTransformationMatrix"->IdentityMatrix[n]|>];
 If[FailureQ[p],epsOrderFail["FiniteIntegrationPreparationRequired",<|"PreparationFailure"->p|>]];
 q=t.h.p["BasisTransformationMatrix"];
 qi=p["InverseBasisTransformationMatrix"].hi.
   Normal[Lookup[s,"InverseBasisTransformationMatrix",Inverse[t]]];
 m=h.p["BasisTransformationMatrix"];mi=p["InverseBasisTransformationMatrix"].hi;
 coefficientSource=Lookup[s,"ConnectionCoefficientSource",None];
 coefficientSource=If[AssociationQ[coefficientSource],
   <|"ConnectionMatrices"->coefficientSource["ConnectionMatrices"],
     "BasisTransformationMatrix"->coefficientSource["BasisTransformationMatrix"].m,
     "InverseBasisTransformationMatrix"->mi.coefficientSource["InverseBasisTransformationMatrix"]|>,
   <|"ConnectionMatrices"->a,"BasisTransformationMatrix"->m,"InverseBasisTransformationMatrix"->mi|>];
 <|"ConnectionCoefficientSource"->coefficientSource,
   "ConnectionMatrices"->p["ConnectionMatrices"],"BasisTransformationMatrix"->q,
   "InverseBasisTransformationMatrix"->qi,"Preparation"->p|>
];
epsOrderOrdinaryPointQ[expressions_,vars_,point_,e_] := Module[{rules,z,v,den},
 rules=Thread[vars->point];
 AllTrue[Flatten[expressions],Function[entry,
   z=Together[entry];
   den=Denominator[z];
   If[!PolynomialQ[den,e],Return[False]];
   v=Exponent[den,e,Min];
   den=Coefficient[den,e,v]/.rules;
   !epsOrderZero[den] && FreeQ[den,Indeterminate|DirectedInfinity[_]]
 ]]
];
(* Point selection uses the defining physical cut domain when available.
   No IBP reduction or boundary-value evaluation is performed while searching. *)
epsOrderRequestedBasePoint[system_,r_,boundary_] := Module[{point,records,points},
 point=Lookup[boundary,"BasePoint",Lookup[r,"BasePoint",Automatic]];
 If[point=!=Automatic,Return[point]];
 records=Lookup[r,"DimensionalRecurrences",{}];
 If[KeyExistsQ[r,"DimensionalRecurrence"],records=Append[records,r["DimensionalRecurrence"]]];
 points=DeleteDuplicates[Cases[Lookup[Select[records,AssociationQ],"BasePoint",None],_List]];
 If[Length[points]>1,epsOrderFail["IncompatibleDimensionalRecurrenceBasePoints"]];
 If[Length[points]===1,First[points],Lookup[system,"BasePoint",Automatic]]
];
epsOrderPointIntegralDefinitions[system_,request_,e_] := Module[
 {source,ids,families,result={},d},
 ids=miRepFC[Lookup[system,"OriginalMasterIntegralBasis",{}]];
 If[ids==={} || !AllTrue[ids,MatchQ[#,_FeynCalc`GLI]&],Return[{}]];
 source=Catch[miRepSourceData[Join[system,request],Replace[Lookup[request,"InputRoot",Automatic],Automatic:>$feynFacetRoot]],"EpsilonOrders"];
 If[!AssociationQ[source],Return[{}]];
 families=DeleteDuplicatesBy[ids,First];
 Do[
  d=Catch[miRepDefinition[miRepFamilyData[source,master],master,e],"EpsilonOrders"];
  If[AssociationQ[d] && d["VirtualLoopCount"]===0 && d["CutIndices"]=!={},
    AppendTo[result,d]],{master,families}];
 result
];
epsOrderPhysicalPointQ[definitions_,vars_,point_] := AllTrue[definitions,
 AssociationQ[Catch[cutOrderGeometry[#/.Thread[vars->point]],"EpsilonOrders"]]&];
epsOrderSelectBasePoint[frame_,vars_,e_,requested_,region_,definitions_:{}] := Module[{points,chosen=None,qr,signs},
 signs=DeleteDuplicates[Join[{ConstantArray[1,Length[vars]],ConstantArray[-1,Length[vars]]},
   Table[1-2 IntegerDigits[j,2,Length[vars]],{j,0,Min[63,2^Length[vars]-1]}]]];
 points=If[requested===Automatic,
   DeleteDuplicates[Flatten[Table[
     With[{candidate=sign Table[1/(2i+j+2),{i,Length[vars]}]},
       {candidate,Reverse[candidate]}],{j,0,31},{sign,signs}],2]],{requested}];
 Do[
  If[!ListQ[pt] || Length[pt]=!=Length[vars] ||
    !VectorQ[pt,MatchQ[#,_Integer|_Rational]&],Continue[]];
  If[!TrueQ[region/.Thread[vars->pt]],Continue[]];
  If[!epsOrderOrdinaryPointQ[Lookup[frame,{"ConnectionMatrices","BasisTransformationMatrix",
       "InverseBasisTransformationMatrix"}],vars,pt,e],Continue[]];
  If[!epsOrderPhysicalPointQ[definitions,vars,pt],Continue[]];
  qr=Thread[vars->pt];
  If[!solutionMatrixZero[(frame["BasisTransformationMatrix"]/.qr).
       (frame["InverseBasisTransformationMatrix"]/.qr)-IdentityMatrix[Length[First[frame["ConnectionMatrices"]]]]],
    Continue[]];
  chosen=pt;Break[],
 {pt,points}];
 If[chosen===None,epsOrderFail["OrdinaryBasePointNotEstablished",
   <|"RequestedBasePoint"->requested|>]];chosen
];

(* Bounds on Phi and Phi^-1 come from a finite resonant prefix and ordinary
   epsilon-regular continuation along the fixed normal segment. *)
epsOrderLocalBoundary[frame_,vars_,e_,base_,d_,seconds_] := Module[
 {n,x,index,singular,direction,rho,rho0,sub,q,b,g,gi,local,a,fr,
  denominators,pathParameter,pathChecked,reach,phi,iphi,s,si,g0,g0i,
  mg,ms,mgi,msi,mp,mi,beta},
 n=Length[First[frame["ConnectionMatrices"]]];
 x=Lookup[d,"NormalVariable",None];index=FirstPosition[vars,x,Missing[]];
 singular=Lookup[d,"SingularPoint",0];
 If[MissingQ[index] || !MatchQ[singular,_Integer|_Rational],
   epsOrderFail["BoundaryNormalCoordinateRequired"]];
 index=First[index];rho0=base[[index]]-singular;
 direction=Lookup[d,"NormalDirection",If[rho0<0,-1,1]];
 rho0=direction rho0;
 If[!MemberQ[{-1,1},direction] || !TrueQ[rho0>0],
   epsOrderFail["NonzeroOrdinaryNormalCoordinateRequired"]];
 rho=Unique["normalCoordinate"];
 sub=Thread[vars->base];sub[[index]]=x->singular+direction rho;
 q=frame["BasisTransformationMatrix"]/.sub;
 b=direction frame["ConnectionMatrices"][[index]]/.sub;
 g=Lookup[d,"LocalBasisTransformationMatrix",Automatic];
 If[g===Automatic,
  g=q;local=b,
  g=Normal[g/.sub];
  If[Dimensions[g]=!={n,n},epsOrderFail["LocalBasisDimensionMismatch"]];
  gi=Inverse[g];
  local=Map[Cancel,gi.(D[q,rho]+q.b).Inverse[q].g-gi.D[g,rho],{2}]
 ];
 fr=FeynFacet`DetermineFrobeniusLaurentBounds[<|"NormalVariable"->rho,
   "DimensionalRegulator"->e,"ConnectionMatrix"->local|>];
 If[FailureQ[fr],epsOrderFail["LocalBoundaryPoleBoundsNotEstablished",<|"LocalAnalysis"->fr|>]];
 a=Map[Cancel,rho local,{2}];
 denominators=DeleteDuplicates[(Denominator[Together[#]]/.e->0)& /@ Flatten[a]];
 pathParameter=Unique["normalPathParameter"];
 pathChecked=And@@Table[
   TrueQ[TimeConstrained[Resolve[Exists[pathParameter,
    0<=pathParameter<=1 && (den/.rho->rho0 pathParameter)==0],Reals],seconds,$Failed]===False],
 {den,denominators}];
 If[!pathChecked,epsOrderFail["UniformNormalMatchingPathNotEstablished"]];
 beta=Table[epsOrderValuation[local[[i,j]],e],{i,n},{j,n}];
 reach=epsOrderDistances[Map[If[#===Infinity,Infinity,0]&,beta,{2}]];
 phi=fr["LocalFundamentalMatrixEntryLowerBounds"];
 iphi=fr["InverseLocalFundamentalMatrixEntryLowerBounds"];
 s=Normal[Lookup[d,"BoundaryNormalizationMatrix",IdentityMatrix[n]]];
 If[!FreeQ[s,x],epsOrderFail["ConstantBoundaryNormalizationMatrixRequired"]];
 s=s/.Thread[vars->base];
 If[Dimensions[s]=!={n,n} || !FreeQ[s,_Real] ||
   epsOrderZero[Det[s]],epsOrderFail["InvertibleBoundaryNormalizationMatrixRequired"]];
 si=Map[Cancel,Inverse[s],{2}];
 g0=g/.rho->rho0;g0i=Map[Cancel,Inverse[g0],{2}];
 If[!FreeQ[{g0,g0i},Indeterminate|DirectedInfinity[_]],epsOrderFail["LocalBasisSingularAtMatchingPoint"]];
 mg=Map[epsOrderValuation[#,e]&,g0,{2}];ms=Map[epsOrderValuation[#,e]&,s,{2}];
 mgi=Map[epsOrderValuation[#,e]&,g0i,{2}];msi=Map[epsOrderValuation[#,e]&,si,{2}];
 mp=epsOrderProductBounds[epsOrderProductBounds[mg,phi],ms];
 mi=epsOrderProductBounds[epsOrderProductBounds[msi,iphi],mgi];
 <|"Type"->"Frobenius","Definition"->"I=G(rho) Phi(rho,epsilon) S(epsilon) b(epsilon), evaluated at the fixed tangential point; Phi=H rho^R and H_0=identity.",
  "NormalVariable"->x,"SingularPoint"->singular,"NormalDirection"->direction,
  "LocalNormalVariable"->rho,"OrdinaryMatchingCoordinate"->rho0,
  "TangentialPoint"->KeyDrop[AssociationThread[vars,base],x],
  "LocalConnectionMatrix"->local,"LocalBasisTransformationMatrix"->g,
  "BoundaryNormalizationMatrix"->s,"LocalAnalysis"->fr,
  "LocalFundamentalMatrixEntryLowerBounds"->phi,
  "LocalConnectionEntryLowerBounds"->beta,
  "LocalBasisAtMatchingPointEntryLowerBounds"->mg,
  "BoundaryNormalizationEntryLowerBounds"->ms,
  "BoundaryToOrdinaryPointEntryLowerBounds"->mp,
  "OrdinaryPointToBoundaryEntryLowerBounds"->mi,
  "UniformNormalMatchingPathEstablished"->True,
  "BoundaryConstantsKinematicsIndependent"->True|>
];

epsOrderCloseMatrix[beta_,lower_,upper_] := Module[
 {n=Length[beta],v=upper,a,queue,pair,i,j,k,cut,next},
 a=ConstantArray[-Infinity,{n,n}];
 queue=Select[Tuples[Range[n],2],Extract[v,#]=!=-Infinity&];
 While[queue=!={},
  pair=First[queue];queue=Rest[queue];{i,j}=pair;cut=v[[i,j]];
  Do[If[beta[[i,k]]===Infinity || lower[[k,j]]===Infinity ||
      beta[[i,k]]+lower[[k,j]]>cut,Continue[]];
   a[[i,k]]=Max[a[[i,k]],cut-lower[[k,j]]];
   next=cut-beta[[i,k]];
   If[next>v[[k,j]],v[[k,j]]=next;AppendTo[queue,{k,j}]],
  {k,n}]
 ];
 <|"SolutionCoefficientUpperOrders"->v,"ConnectionCoefficientUpperOrders"->a|>
];


(* Local normalization Phi=H exp(R Log[rho]) can consume higher residue
   coefficients than the differential recurrence for Phi alone. Include
   these factor orders explicitly, using the exact resonant prefix. *)
epsOrderFrobeniusFactorOrders[info_,phiUpper_,e_] := Module[
 {fr=info["LocalAnalysis"],n,hlo,elo,hu,eu,r,ar,br,ba,au,ru,queue,
  i,j,k,cut,new,ec,rho},
 n=Length[phiUpper];hlo=fr["FrobeniusSeriesEntryLowerBounds"];
 elo=fr["ResidueExponentialEntryLowerBounds"];
 hu=ConstantArray[-Infinity,{n,n}];eu=hu;au=hu;ru=hu;
 Do[
  If[phiUpper[[i,j]]===-Infinity,Continue[]];
  Do[If[hlo[[i,k]]===Infinity || elo[[k,j]]===Infinity ||
    hlo[[i,k]]+elo[[k,j]]>phiUpper[[i,j]],Continue[]];
   hu[[i,k]]=Max[hu[[i,k]],phiUpper[[i,j]]-elo[[k,j]]];
   eu[[k,j]]=Max[eu[[k,j]],phiUpper[[i,j]]-hlo[[i,k]]],
  {k,n}],{i,n},{j,n}];
 r=fr["ResidueMatrix"];rho=info["LocalNormalVariable"];
 ar=Map[Cancel,rho info["LocalConnectionMatrix"]-r,{2}];
 br=Map[epsOrderValuation[#,e]&,r,{2}];ba=Map[epsOrderValuation[#,e]&,ar,{2}];
 queue=Select[Tuples[Range[n],2],Extract[hu,#]=!=-Infinity&];
 While[queue=!={},
  {i,j}=First[queue];queue=Rest[queue];cut=hu[[i,j]];
  Do[
   Do[With[{weight=If[source===1,ba[[i,k]],br[[i,k]]]},
    If[weight===Infinity || hlo[[k,j]]===Infinity || weight+hlo[[k,j]]>cut,Continue[]];
    If[source===1,au[[i,k]]=Max[au[[i,k]],cut-hlo[[k,j]]],
      ru[[i,k]]=Max[ru[[i,k]],cut-hlo[[k,j]]]];
    new=cut-weight;
    If[new>hu[[k,j]],hu[[k,j]]=new;AppendTo[queue,{k,j}]]],
   {source,2}];
   If[br[[k,j]]===Infinity || hlo[[i,k]]===Infinity ||
      br[[k,j]]+hlo[[i,k]]>cut,Continue[]];
   ru[[k,j]]=Max[ru[[k,j]],cut-hlo[[i,k]]];
   new=cut-br[[k,j]];
   If[new>hu[[i,k]],hu[[i,k]]=new;AppendTo[queue,{i,k}]],
  {k,n}]
 ];
 ec=epsOrderCloseMatrix[br,elo,eu];
 ru=MapThread[Max,{ru,ec["ConnectionCoefficientUpperOrders"]},2];
 <|"FrobeniusSeriesCoefficientUpperOrders"->hu,
   "ResidueExponentialCoefficientUpperOrders"->ec["SolutionCoefficientUpperOrders"],
   "ResidueMatrixCoefficientUpperOrders"->ru,
   "RegularConnectionCoefficientUpperOrders"->au,
   "RegularConnectionConvention"->"A_regular=rho times the normal connection minus its residue; its Taylor coefficients drive the Frobenius series after the exact resonant prefix."|>
];


(* A recurrence belongs to one complete IBP master basis at the specified
   ordinary point. Grouping here lets a request contain several families. *)
epsOrderCutRecurrenceRequested[r_] :=
 Lookup[r,"CutPoleBoundMethod","Geometric"]==="DimensionalRecurrence" ||
 KeyExistsQ[r,"DimensionalRecurrence"] || KeyExistsQ[r,"DimensionalRecurrences"];
epsOrderCutRecurrenceBounds[representations_,ids_,r_,seconds_] := Module[
 {given,groups,records=<||>,reports=<||>,method,options,directory,groupReps,
  family,record,bounds,candidates,definitions,construction},
 method=Lookup[r,"CutPoleBoundMethod","Geometric"];
 If[!MemberQ[{"Geometric","DimensionalRecurrence"},method],
  epsOrderFail["CutPoleBoundMethodInvalid"]];
 given=Lookup[r,"DimensionalRecurrences",{}];
 If[KeyExistsQ[r,"DimensionalRecurrence"],given=Append[given,r["DimensionalRecurrence"]]];
 If[!ListQ[given] || !AllTrue[given,
   AssociationQ[#] && Lookup[#,"DataType",None]==="MasterIntegralDimensionalRecurrence" &&
    MatchQ[Lookup[#,"OriginalMasterIntegralBasis",{}],{__}]&],
  epsOrderFail["DimensionalRecurrenceRecordsRequired"]];
 options=Lookup[r,"DimensionalRecurrenceOptions",<||>];
 If[!AssociationQ[options] || Complement[Keys[options],
   First /@ Options[FeynFacet`ConstructMasterIntegralDimensionalRecurrence]]=!={},
  epsOrderFail["DimensionalRecurrenceOptionsInvalid"]];
 options=Join[<|"RegularityProofTimeLimit"->seconds|>,options];
 directory=Lookup[options,"WorkingDirectory",Automatic];
 groups=GatherBy[Select[Keys[representations],
   Lookup[representations[#],"VirtualLoopCount",-1]===0 &&
   Lookup[representations[#],"CutIndices",{}]=!={}&],
   miRepFamilyName[miRepFC[ids[[#]]][[1]]]&];
 Do[
  family=miRepFamilyName[miRepFC[ids[[First[group]]]][[1]]];
  candidates=Select[given,miRepFamilyName[miRepFC[
    First[Lookup[#,"OriginalMasterIntegralBasis",{None}]]][[1]]]===family&];
  If[Length[candidates]>1,epsOrderFail["DuplicateFamilyDimensionalRecurrence"]];
  If[candidates==={} && method=!="DimensionalRecurrence",Continue[]];
  groupReps=representations /@ group;
  definitions=cutDrrDefinitions[groupReps];
  If[candidates=!={},
   record=First[candidates];
   If[KeyExistsQ[record,"BasePoint"] && record["BasePoint"]=!=Lookup[r,"BasePoint",None],
    epsOrderFail["DimensionalRecurrenceBasePointMismatch"]];
   If[!ListQ[Lookup[record,"IntegralDefinitions",None]] ||
      cutDrrDefinitions[record["IntegralDefinitions"]]=!=definitions,
    epsOrderFail["DimensionalRecurrenceIntegralDefinitionMismatch",<|"Family"->family|>]];
   record=Join[record,<|"IntegralRepresentations"->groupReps,
      "OriginalMasterIntegralBasis"->Lookup[groupReps,"MasterIntegral"]|>],
   construction=Join[options,If[StringQ[directory],
     <|"WorkingDirectory"->FileNameJoin[{directory,family}]|>,<||>]];
   record=FeynFacet`ConstructMasterIntegralDimensionalRecurrence[
     AssociationThread[Range[Length[group]],groupReps],Sequence@@Normal[construction]];
   If[FailureQ[record],Throw[record,"EpsilonOrders"]]
  ];
  bounds=FeynFacet`DetermineLaurentBoundsFromDimensionalRecurrence[record,
    "RegularityProofTimeLimit"->seconds];
  If[FailureQ[bounds],Throw[bounds,"EpsilonOrders"]];
  Do[AssociateTo[records,group[[j]]->bounds["IntegralBoundRecords"][j]],{j,Length[group]}];
  AssociateTo[reports,family->Join[KeyDrop[bounds,"IntegralBoundRecords"],
    <|"Reduction"->Lookup[record,"Reduction",None]|>]],
 {group,groups}];
 If[Length[given]>Length[reports],epsOrderFail["UnusedDimensionalRecurrenceRecord"]];
 <|"IntegralBoundRecords"->records,"FamilyReports"->reports|>
];

Options[FeynFacet`DetermineMasterIntegralExpansionOrders]={
 "AutomaticPreparation"->True,"HomogeneousSolveTimeLimit"->30,
 "RegularityProofTimeLimit"->5,"MaximumSectors"->512,"MaximumSectorDepth"->32};
epsOrderMasterExpansion[s_,request_,automatic_,homSeconds_,proofSeconds_,sectorLimit_,depthLimit_] := Module[
 {r,e,vars,system,frame,n,base,boundary,kind,masterRanges,rows,targets,q,qi0,beta,dist,lv,rv,u,
  boundaryInfo,mp,mi,potentialC,potentialB,neededAnchors,representations,supplied,records=<||>,
  cbounds,unresolved={},assumptions={},source,rep,record,status,ub,cu,requests,plan,
  boundaryLower,boundaryUpper,localOrders=None,phi,gs,ss,pUpper,gUpper,sUpper,matchingUpper,
  localClosure,factorOrders,need,boundaryRows,evolutionRequests,ids,observedBounds,allUpper,lo,hi,
  definitionConstruction=None,automaticRows,recurrenceRequested,recurrenceReport=None,pointDefinitions,pointSelection},
 e=Lookup[s,"DimensionalRegulator",None];
 If[e===None || !MatchQ[e,_Symbol],epsOrderFail["DimensionalRegulatorRequired"]];
 system=epsOrderNormalize[s,e];r=epsOrderNormalize[request,e];
 If[Lookup[system,"DataType",None]==="FamilyDLogEpsilonForm",
  system=Join[system,<|
   "KinematicVariables"->system["CoefficientVariables"],
   "ConnectionMatrices"->Table[e Total[MapThread[#1 D[#2,v]/#2&,
     {system["ConstantResidueMatrices"],system["Letters"]}]],{v,system["CoefficientVariables"]}],
   "InverseBasisTransformationMatrix"->system["CachedInverseBasisTransformationMatrix"]|>]
 ];
 vars=Lookup[system,"KinematicVariables",{}];
 frame=epsOrderPrepareFrame[system,homSeconds,automatic];
 n=Length[First[frame["ConnectionMatrices"]]];
 ids=Lookup[system,"OriginalMasterIntegralBasis",Range[n]];
 If[Length[ids]=!=n || !DuplicateFreeQ[ids],epsOrderFail["MasterBasisDimensionMismatch"]];
 masterRanges=Lookup[r,"RequestedMasterIntegralOrderRanges",<||>];
 If[!AssociationQ[masterRanges] || masterRanges===<||> ||
   !AllTrue[Keys[masterRanges],IntegerQ[#] && 1<=#<=n&] ||
   !AllTrue[Values[masterRanges],MatchQ[#,{_Integer,_Integer}] && First[#]<=Last[#]&],
   epsOrderFail["MasterIntegralOrderRangesRequired"]];
 rows=Keys[masterRanges];targets=Last /@ masterRanges;
 boundary=Lookup[r,"BoundaryNormalization",<|"Type"->"OrdinaryPoint"|>];
 If[!AssociationQ[boundary],epsOrderFail["BoundaryNormalizationRequired"]];
 kind=Lookup[boundary,"Type","OrdinaryPoint"];
 pointDefinitions=epsOrderPointIntegralDefinitions[system,r,e];
 base=epsOrderSelectBasePoint[frame,vars,e,
   epsOrderRequestedBasePoint[system,r,boundary],
   Lookup[r,"BasePointRegion",True],pointDefinitions];
 pointSelection=<|"BasePoint"->base,"PhysicalCutFamilyCount"->Length[pointDefinitions],
   "PhysicalCutKinematicsChecked"->(pointDefinitions=!={}),
   "SharedByCoupledMasterSystem"->True,"BoundaryEvaluationCostOptimized"->False,
   "Criterion"->"An ordinary rational point satisfying the requested region and every available compact physical cut domain."|>;
 q=frame["BasisTransformationMatrix"];
 qi0=frame["InverseBasisTransformationMatrix"]/.Thread[vars->base];
 lv=Map[epsOrderValuation[#,e]&,q,{2}];
 rv=Map[epsOrderValuation[#,e]&,qi0,{2}];
 beta=Table[Min[epsOrderValuation[#[[i,j]],e]& /@ frame["ConnectionMatrices"]],{i,n},{j,n}];
 If[AnyTrue[Flatten[beta],#<0&] || !And@@Flatten[Table[beta[[i,j]]>0,{i,n},{j,i,n}]],
   epsOrderFail["PreparedTriangularEpsilonRegularConnectionRequired"]];
 dist=epsOrderDistances[beta];
 u=epsOrderProductBounds[epsOrderProductBounds[lv,dist],rv];
 potentialC=Select[Range[n],Function[j,AnyTrue[rows,u[[#,j]]=!=Infinity&]]];
 boundaryInfo=Switch[kind,
  "OrdinaryPoint",<|"Type"->kind,"Definition"->"C(epsilon)=I(BasePoint,epsilon) in the original master basis.",
    "BoundaryConstantsKinematicsIndependent"->True|>,
  "Frobenius",epsOrderLocalBoundary[frame,vars,e,base,boundary,proofSeconds],
  _,epsOrderFail["UnsupportedBoundaryNormalization",<|"Type"->kind|>]];
 If[kind==="Frobenius",
  mp=boundaryInfo["BoundaryToOrdinaryPointEntryLowerBounds"];
  mi=boundaryInfo["OrdinaryPointToBoundaryEntryLowerBounds"];
  potentialB=Select[Range[n],Function[j,AnyTrue[potentialC,mp[[#,j]]=!=Infinity&]]];
  neededAnchors=Union[potentialC,Select[Range[n],Function[k,AnyTrue[potentialB,mi[[#,k]]=!=Infinity&]]]],
  neededAnchors=potentialC
 ];
 representations=Lookup[r,"MasterIntegralRepresentations",Lookup[system,"MasterIntegralRepresentations",<||>]];
 supplied=Lookup[r,"MasterIntegralLaurentLowerBounds",<||>];
 If[!AssociationQ[representations] || !AssociationQ[supplied],epsOrderFail["MasterIntegralDataAssociationsRequired"]];
 If[!MemberQ[{"Geometric","DimensionalRecurrence"},Lookup[r,"CutPoleBoundMethod","Geometric"]],
  epsOrderFail["CutPoleBoundMethodInvalid"]];
 recurrenceRequested=epsOrderCutRecurrenceRequested[r];
 automaticRows=Select[If[recurrenceRequested,Range[n],neededAnchors],
   !KeyExistsQ[representations,#] && (recurrenceRequested || !KeyExistsQ[supplied,#]) &&
   MatchQ[miRepFC[ids[[#]]],_FeynCalc`GLI]&];
 If[automaticRows=!={},
  definitionConstruction=FeynFacet`ConstructMasterIntegralRepresentations[system,
    Join[r,<|"RequestedRows"->automaticRows,"BasePoint"->base|>],"InputRoot"->Lookup[r,"InputRoot",Automatic]];
  If[AssociationQ[definitionConstruction],
   representations=Join[definitionConstruction["MasterIntegralRepresentations"],representations]]
 ];
 If[recurrenceRequested,
  representations=Map[Join[#/.Thread[vars->base],<|"DimensionalRegulator"->e|>]&,representations];
  recurrenceReport=epsOrderCutRecurrenceBounds[representations,ids,Join[r,<|"BasePoint"->base|>],proofSeconds];
  records=recurrenceReport["IntegralBoundRecords"]
 ];
 cbounds=ConstantArray[Missing["IntegralRepresentationRequired"],n];
 Do[
  If[KeyExistsQ[records,j],cbounds[[j]]=records[j]["LowerBound"];Continue[]];
  If[KeyExistsQ[representations,j],
   rep=representations[j];
   If[!AssociationQ[rep],epsOrderFail["IntegralRepresentationMustBeAnAssociation"]];
   If[KeyExistsQ[rep,"MasterIntegral"] && rep["MasterIntegral"]=!=ids[[j]],
     epsOrderFail["IntegralRepresentationMasterMismatch",<|"MasterRow"->j|>]];
   (* Parameter names may not be kinematic variables: substitution must not
      turn integration variables into ordinary-point numbers. *)
   If[Intersection[Flatten[Lookup[#,"IntegrationVariables",{}]& /@ Lookup[rep,"Terms",{}]],
       vars]=!={} || Intersection[Lookup[rep,"FeynmanParameters",{}],vars]=!={},
     epsOrderFail["IntegrationParametersMustDifferFromKinematicVariables"]];
   rep=Join[rep/.Thread[vars->base],<|"DimensionalRegulator"->e|>];
   record=FeynFacet`DetermineIntegralLaurentBound[rep,
     "RegularityProofTimeLimit"->proofSeconds,"MaximumSectors"->sectorLimit,"MaximumSectorDepth"->depthLimit];
   AssociateTo[records,j->record];
   If[FailureQ[record],AppendTo[unresolved,<|"MasterRow"->j,"MasterIntegral"->ids[[j]],"Reason"->record|>],
     cbounds[[j]]=record["LowerBound"]],
   If[KeyExistsQ[supplied,j],
    source=supplied[j];cbounds[[j]]=epsOrderBound[source];
    AssociateTo[records,j->source];
    If[MissingQ[cbounds[[j]]],AppendTo[unresolved,<|"MasterRow"->j,"Reason"->"UnrecognizedLaurentBound"|>],
      AppendTo[assumptions,j]],
    AppendTo[unresolved,<|"MasterRow"->j,"MasterIntegral"->ids[[j]],
      "Reason"->"NormalizedIntegralRepresentationRequired"|>]
   ]
  ],
 {j,neededAnchors}];
 cu=ConstantArray[-Infinity,n];ub=ConstantArray[-Infinity,{n,n}];requests={};
 Do[If[u[[i,j]]===Infinity || cbounds[[j]]===Infinity,Continue[]];
   If[!MissingQ[cbounds[[j]]] && targets[i]<u[[i,j]]+cbounds[[j]],Continue[]];
   cu[[j]]=Max[cu[[j]],targets[i]-u[[i,j]]];
   If[!MissingQ[cbounds[[j]]],
    ub[[i,j]]=targets[i]-cbounds[[j]];
    AppendTo[requests,{i,j,ub[[i,j]]}]],
 {i,rows},{j,n}];
 If[unresolved=!={},
  Return[<|"DataType"->"MasterIntegralExpansionOrders","Status"->"AdditionalIntegralDataRequired",
   "BasePoint"->base,"BasePointSelection"->pointSelection,"BoundaryNormalization"->boundaryInfo,
   "RequestedMasterIntegralOrderRanges"->masterRanges,
   "OriginalFundamentalMatrixEntryLowerBounds"->u,
   "OrdinaryPointConstantUpperOrders"->cu,"IntegralBoundRecords"->records,
   "MissingIntegralData"->unresolved,"AssumedMasterLaurentBounds"->assumptions,
   "IntegralRepresentationConstruction"->definitionConstruction,
   "DimensionalRecurrenceBounds"->recurrenceReport,
   "GlobalEvolutionComputed"->False,"BoundaryCoefficientsEvaluated"->False|>]
 ];
 plan=epsOrderPlanFromValuations[beta,lv,rv,requests];
 boundaryLower=cbounds;boundaryUpper=cu;
 If[kind==="Frobenius",
  boundaryLower=Flatten[epsOrderProductBounds[mi,Transpose[{cbounds}]]];
  boundaryUpper=ConstantArray[-Infinity,n];matchingUpper=ConstantArray[-Infinity,{n,n}];
  phi=boundaryInfo["LocalFundamentalMatrixEntryLowerBounds"];
  gs=boundaryInfo["LocalBasisAtMatchingPointEntryLowerBounds"];
  ss=boundaryInfo["BoundaryNormalizationEntryLowerBounds"];
  pUpper=ConstantArray[-Infinity,{n,n}];gUpper=pUpper;sUpper=pUpper;
  Do[
   If[cu[[i]]===-Infinity || mp[[i,j]]===Infinity || boundaryLower[[j]]===Infinity ||
      cu[[i]]<mp[[i,j]]+boundaryLower[[j]],Continue[]];
   matchingUpper[[i,j]]=cu[[i]]-boundaryLower[[j]];
   boundaryUpper[[j]]=Max[boundaryUpper[[j]],cu[[i]]-mp[[i,j]]];
   Do[If[MemberQ[{gs[[i,a]],phi[[a,b]],ss[[b,j]]},Infinity] ||
     cu[[i]]<gs[[i,a]]+phi[[a,b]]+ss[[b,j]]+boundaryLower[[j]],Continue[]];
    pUpper[[a,b]]=Max[pUpper[[a,b]],cu[[i]]-gs[[i,a]]-ss[[b,j]]-boundaryLower[[j]]];
    gUpper[[i,a]]=Max[gUpper[[i,a]],cu[[i]]-phi[[a,b]]-ss[[b,j]]-boundaryLower[[j]]];
    sUpper[[b,j]]=Max[sUpper[[b,j]],cu[[i]]-gs[[i,a]]-phi[[a,b]]-boundaryLower[[j]]],
   {a,n},{b,n}],
  {i,n},{j,n}];
  localClosure=epsOrderCloseMatrix[boundaryInfo["LocalConnectionEntryLowerBounds"],phi,pUpper];
  factorOrders=epsOrderFrobeniusFactorOrders[boundaryInfo,localClosure["SolutionCoefficientUpperOrders"],e];
  localClosure["ConnectionCoefficientUpperOrders"]=MapThread[Max,
    {localClosure["ConnectionCoefficientUpperOrders"],
     factorOrders["ResidueMatrixCoefficientUpperOrders"],
     factorOrders["RegularConnectionCoefficientUpperOrders"]},2];
  localOrders=Join[localClosure,factorOrders,<|"MatchingMatrixUpperOrders"->matchingUpper,
    "LocalBasisAtMatchingPointUpperOrders"->gUpper,"BoundaryNormalizationUpperOrders"->sUpper,
    "LocalFundamentalMatrixOrderRanges"->Table[
      epsOrderIntervals[phi[[i,j]],localClosure["SolutionCoefficientUpperOrders"][[i,j]]],{i,n},{j,n}],
    "ResonantPrefixConvention"->"Use the exact finite Frobenius prefix returned by the local analysis; its epsilon poles are already included in these bounds."|>]
 ];
 boundaryRows=Table[<|"Component"->j,"LaurentLowerBound"->boundaryLower[[j]],
   "RequiredThroughOrder"->boundaryUpper[[j]],
   "PoleOrderUpperBound"->If[MissingQ[boundaryLower[[j]]],Missing["NotRequired"],
     Max[0,-boundaryLower[[j]]]],
   "RequiredOrders"->epsOrderIntervals[boundaryLower[[j]],boundaryUpper[[j]]]|>,{j,n}];
 evolutionRequests=Table[
  allUpper=DeleteCases[ub[[i]],-Infinity];
  If[allUpper==={},Nothing,
   lo=Min[u[[i]]];hi=Max[allUpper];
   <|"BasePoint"->base,"RequestedRows"->{i},"RequestedEpsilonOrders"->Range[lo,hi],
     "AnalyticDomain"->Lookup[r,"AnalyticDomain","A simply connected ordinary neighborhood containing the fixed base point and evolution paths."],
     "BranchPrescription"->Lookup[r,"BranchPrescription","Analytic continuation from the fixed ordinary point; singular-boundary powers use positive normal coordinates."]|>],
 {i,rows}];
 <|"DataType"->"MasterIntegralExpansionOrders",
  "Status"->If[assumptions==={},"SufficientOrdersDetermined","SufficientForAssumedLaurentBounds"],
  "RequestedMasterIntegralOrderRanges"->masterRanges,"OriginalMasterIntegralBasis"->ids,
  "KinematicVariables"->vars,"DimensionalRegulator"->e,"BasePoint"->base,"BasePointSelection"->pointSelection,
  "BoundaryNormalization"->boundaryInfo,"IntegralBoundRecords"->records,
  "IntegralRepresentationConstruction"->definitionConstruction,
   "DimensionalRecurrenceBounds"->recurrenceReport,
  "OrdinaryPointConstantLowerBounds"->cbounds,"OrdinaryPointConstantUpperOrders"->cu,
  "BoundaryCoefficientOrders"->boundaryRows,
  "MaximumRequiredBoundaryPoleOrder"->Max[Prepend[
    (-boundaryLower[[#]]& /@ Select[Range[n],boundaryUpper[[#]]=!=-Infinity&]),0]],
  "AssumedMasterLaurentBounds"->assumptions,
  "OriginalFundamentalMatrixEntryLowerBounds"->u,
  "OriginalFundamentalMatrixCoefficientUpperOrders"->ub,
  "FundamentalMatrixEpsilonOrders"->plan,"LocalBoundaryEpsilonOrders"->localOrders,
  "PreparedDifferentialSystem"-><|"KinematicVariables"->vars,"DimensionalRegulator"->e,
    "OriginalMasterIntegralBasis"->ids,"ConnectionMatrices"->frame["ConnectionMatrices"],
    "BasisTransformationMatrix"->q,
    "InverseBasisTransformationMatrix"->frame["InverseBasisTransformationMatrix"],
    "ConnectionCoefficientSource"->frame["ConnectionCoefficientSource"]|>,
  "EvolutionConstructionRequests"->evolutionRequests,
  "EvolutionConstructionConvention"->"The per-row requests are compatible conservative uniform-column requests; the entrywise tables give the sharper requirements.",
  "OrderDerivation"->"Integral definitions bound C. Fixed local normalization and its inverse bound b without solving global evolution. Laurent product remainders then determine evolution, matching, and boundary coefficient orders.",
  "GlobalEvolutionComputed"->False,"BoundaryCoefficientsEvaluated"->False|>
];
FeynFacet`DetermineMasterIntegralExpansionOrders[s_Association,r_Association,OptionsPattern[]] :=
 Catch[epsOrderMasterExpansion[s,r,OptionValue["AutomaticPreparation"],
  OptionValue["HomogeneousSolveTimeLimit"],OptionValue["RegularityProofTimeLimit"],
  OptionValue["MaximumSectors"],OptionValue["MaximumSectorDepth"]],"EpsilonOrders"];
End[];
