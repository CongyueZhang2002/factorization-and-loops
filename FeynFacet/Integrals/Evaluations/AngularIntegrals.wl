(* Normalized two-body angular integrals, reduced by tangential IBP.
   The metric is (+---); BetaGram is the Euclidean Gram matrix of spatial
   vectors in denominators 1-beta_i.n. Solid angle and dimensional phase
   volume are NOT included. Reference: Somogyi, arXiv:1101.3557. *)
BeginPackage["FeynFacet`"];
ReduceTwoBodyAngularPowers::usage="ReduceTwoBodyAngularPowers[powers,betaGram,epsilon] reduces one or two integer powers of (1-beta_i.n) on S^(D-2) to explicit normalized angular seeds by tangential IBP. At most one positive-power direction may be massive; numerator directions may be spacelike. Returns exact rational seed coefficients, with no angular integral left unevaluated.";
ExpandTwoBodyAngularSeeds::usage="ExpandTwoBodyAngularSeeds[reduction,through] evaluates the normalized massive, massless and mixed angular seeds through epsilon^1 using logarithms and dilogarithms. Orders above the implemented range fail. This fixed-kinematics expansion does not replace the separate generic-epsilon endpoint limit.";
ConstructTwoBodyAngularGeometry::usage="ConstructTwoBodyAngularGeometry[family,epsilon] derives the normalized angular denominator scales, spatial Gram matrix and exact phase-space prefactor of a typed two-particle massless cut family. Ordinary prescriptions remain part of the input; their removal needs the shared certificate.";
EvaluateTwoBodyCutIntegral::usage="EvaluateTwoBodyCutIntegral[geometry,GLI] reduces a two-particle unit-cut integral to the normalized angular seeds, restoring all denominator scales, routing Jacobians and the declared dimensional measure. It returns a generic-kinematic analytic expression, not an endpoint distribution.";
EvaluateTwoBodyIntegralCombination::usage="EvaluateTwoBodyIntegralCombination[decomposition,request] evaluates named rational combinations of typed two-particle cut integrals by exact angular IBP and explicit hypergeometric seeds. It certifies the maximal ordinary powers once per family and retains every physical measure. Endpoint distributions are a separate operation.";
PublishTwoBodyAngularSeeds::usage="PublishTwoBodyAngularSeeds[density,request] stores the explicit physical volume, massive single-denominator and two-denominator seed integrals in the shared master library. It retains typed cuts, measures, prescriptions and the generic-kinematic scope; endpoint distributions are separate.";
Begin["`Private`"];
angularIntegralFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"AngularIntegrals"];
angularNullMoment[j_Integer,e_]:=If[j<=0,
 Sum[Binomial[-j,2h]Pochhammer[1/2,h]/Pochhammer[3/2-e,h],{h,0,Floor[-j/2]}],
 Cancel[2^-j Times@@Table[2-j-2e+h,{h,0,j-1}]/Times@@Table[1-j-e+h,{h,0,j-1}]]];
ReduceTwoBodyAngularPowers[powers_List,betaGram_List,e_Symbol]:=Catch[Module[
 {nu=powers,g=betaGram,n,rho,v,one,two,jfun,pairSeed=Unique["angularPair$"],
  singleSeed=Unique["angularSingle$"],reduction,seeds=<||>,symbols,rows,
  polynomial,axis,other,j,m,beta2,c,transverse,t,d=Unique["angularDenominator$"],terms},
 n=Length[nu];
 If[!MemberQ[{1,2},n]||!VectorQ[nu,IntegerQ]||Dimensions[g]=!={n,n}||g=!=Transpose[g]||
   !FreeQ[g,e|_Real|_Failure|Indeterminate|_DirectedInfinity],angularIntegralFail["ExactAngularPowersAndSpatialGramRequired"]];
 rho=Cancel[(1-#)/4]&/@Diagonal[g];
 If[n===2&&nu[[1]]>0&&nu[[2]]>0&&rho[[2]]=!=0,
  If[rho[[1]]=!=0,angularIntegralFail["TwoMassiveAngularDenominatorsRequireAdditionalSeeds"]];
  nu=Reverse[nu];g=Reverse[Reverse[g,2]];rho=Reverse[rho]];
 v=If[n===2,Cancel[(1-g[[1,2]])/2],0];
 one[j_Integer,r_]:=one[j,r]=Which[
  j<=0,Sum[Binomial[-j,2h](1-4r)^h Pochhammer[1/2,h]/Pochhammer[3/2-e,h],{h,0,Floor[-j/2]}],
  r===0,angularNullMoment[j,e],
  r===1/4,1,
  j===1,singleSeed,
  True,Cancel[((2j-4+2e)one[j-1,r]+(3-2e-j)one[j-2,r])/(4(j-1)r)]];
 jfun[j_Integer,0]:=one[j,First[rho]];
 jfun[0,k_Integer]:=one[k,Last[rho]];
 jfun[1,1]=pairSeed;
 (* Tangential divergence along the massless direction raises the first
    power; the massive direction raises the second. Neither divides by e. *)
 jfun[j_Integer?Positive,k_Integer?Positive]:=jfun[j,k]=If[j===1,
  Cancel[((k-1+2e)jfun[1,k-1]+(2-k-2e)jfun[0,k-1]-
    4First[rho]jfun[2,k-1]+(k-1)jfun[0,k])/(2(k-1)v)],
  Cancel[((j+2k-3+2e)jfun[j-1,k]+(3-2e-j-k)jfun[j-1,k-1]+
    (j-1)jfun[j,k-1])/(2(j-1)v)]];
 Which[
  n===1,reduction=one[First[nu],First[rho]],
  AllTrue[nu,#>0&],
   If[v===0,angularIntegralFail["CoincidentAngularDirectionsNeedCombinedPowers"]];
   reduction=jfun@@nu,
  MemberQ[nu,0],axis=If[nu[[1]]===0,2,1];reduction=one[nu[[axis]],rho[[axis]]];rho={rho[[axis]]};n=1,
  True,
   (* Average the polynomial numerator at fixed polar angle of the one
      denominator. The residual rotational space has D-2 dimensions. *)
   axis=If[nu[[1]]>0,1,2];other=3-axis;j=nu[[axis]];m=-nu[[other]];
   If[j<=0,
    axis=If[g[[1,1]]=!=0,1,2];other=3-axis;j=nu[[axis]];m=-nu[[other]]];
   beta2=g[[axis,axis]];c=g[[axis,other]];
   If[beta2===0,reduction=one[nu[[other]],rho[[other]]],
    t=(1-d)/Sqrt[beta2];transverse=Cancel[g[[other,other]]-c^2/beta2];
    polynomial=Sum[Binomial[m,2h](1-c(1-d)/beta2)^(m-2h)*
      transverse^h(1-(1-d)^2/beta2)^h Pochhammer[1/2,h]/Pochhammer[1-e,h],
     {h,0,Floor[m/2]}];
    terms=CoefficientRules[Expand[polynomial],{d}];
    reduction=Total[(Last[#]one[j-First[First[#]],rho[[axis]]])&/@terms];
    (* The seed name refers to the direction used as the denominator. *)
    rho={rho[[axis]]};n=1]];
 If[!FreeQ[reduction,singleSeed],
  AssociateTo[seeds,singleSeed-><|"Type"->"SingleMassive","MassInvariant"->First[rho],
   "ExactExpression"->Hypergeometric2F1[1/2,1,3/2-e,1-4First[rho]],"LaurentLowerBound"->0|>]];
 If[!FreeQ[reduction,pairSeed],
  AssociateTo[seeds,pairSeed->If[First[rho]===0,
   <|"Type"->"MasslessPair","AngularInvariant"->v,"LaurentLowerBound"->-1,
    "ExactExpression"->-(1-2e)/(2e)Hypergeometric2F1[1,1,1-e,1-v]|>,
   With[{b=Sqrt[1-4First[rho]]},<|"Type"->"OneMassPair","MassInvariant"->First[rho],
    "AngularInvariant"->v,"LaurentLowerBound"->-1,
    "ExactExpression"->-(1-2e)/(4e v)AppellF1[1,-e,-e,1-2e,
      1-(1+b)/(2v),1-(1-b)/(2v)]|>]]]];
 reduction=FeynFacet`CancelRationalCoefficients[{reduction}];
 If[!ListQ[reduction]||Length[reduction]=!=1,angularIntegralFail["CompactAngularReductionRequired"]];
 reduction=First[reduction];
 symbols=Keys[seeds];rows=FeynFacet`PolynomialCoefficientRules[reduction,symbols];
 If[FailureQ[rows]||!AllTrue[First/@rows,Total[#]<=1&],angularIntegralFail["LinearAngularSeedReductionRequired"]];
 <|"Format"->"FeynFacet-TwoBodyAngularReduction","DimensionalRegulator"->e,
  "Powers"->powers,"BetaGram"->betaGram,"Reduction"->reduction,"Seeds"->seeds,
  "ExactExpression"->(reduction/.Normal[Map[#["ExactExpression"]&,seeds]]),
  "Normalization"->"Average over the unit sphere S^(D-2); D=4-2 epsilon",
  "EndpointExpansionIncluded"->False|>
],"AngularIntegrals"];
ConstructTwoBodyAngularGeometry[input_Association,e_Symbol]:=Catch[Module[
 {family,top,cuts,loop,external,kin,conditions,momenta,total,m2,a,shift,r=Unique["cutMomentum$"],
  routing,core,cores,constants,vectors,scales,gram,sp,indices,coordinate,coefficients,value,prefactor},
 family=FeynFacet`CreateCutIntegralDefinition[input];
 If[!AssociationQ[family],angularIntegralFail["TypedTwoBodyCutDefinitionRequired",<|"Cause"->family|>]];
 top=family["Topology"];cuts=family["CutIndices"];
 If[Length[top[[3]]]=!=1||Length[cuts]=!=2||family["MeasurementCutIndices"]=!={}||
   !AllTrue[family["Cuts"],#["Type"]==="Particle"&&Lookup[#,"MassSquared",0]===0&],
  angularIntegralFail["TwoMasslessParticleCutsAndOneIntegrationMomentumRequired"]];
 loop=First[top[[3]]];external=top[[4]];kin=top[[5]];conditions=family["Assumptions"];
 momenta=(#["EnergyDirection"]#["Momentum"]&/@family["Cuts"]);total=Expand[Total[momenta]];
 If[!FreeQ[total,loop],angularIntegralFail["ExternalTwoBodyTotalMomentumRequired"]];
 sp[u_,v_]:=Factor[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[u,v]]]/.kin];
 m2=sp[total,total];
 If[!TrueQ[FullSimplify[m2>0,conditions]],angularIntegralFail["PositiveTwoBodyInvariantRequired"]];
 a=Coefficient[First[momenta],loop];shift=Expand[First[momenta]-a loop];
 If[!MatchQ[a,_Integer|_Rational]||a===0||!FreeQ[shift,loop],angularIntegralFail["AffineTwoBodyRoutingRequired"]];
 routing={loop->(r-shift)/a};indices=Complement[Range[Length[top[[2]]]],cuts];
 cores=FeynCalc`ExpandScalarProduct[family["InversePropagators"]/.routing]/.kin;
 coordinate=FeynCalc`FCI[FeynCalc`SPD[r,#]]&/@external;
 constants={};vectors={};scales={};
 Do[
  core=Expand[cores[[index]]/.FeynCalc`FCI[FeynCalc`SPD[r]]->0];
  coefficients=Coefficient[core,#]&/@coordinate;FeynFacet`DeclareScalar[coefficients];
  value=Factor[core-coefficients.coordinate];
  If[!FreeQ[value,r|_FeynCalc`Pair],angularIntegralFail["AffineOnShellAngularDenominatorRequired"]];
  AppendTo[constants,value];AppendTo[vectors,coefficients.external];
  AppendTo[scales,Factor[value+sp[Last[vectors],total]/2]],
 {index,indices}];
 If[MemberQ[scales,0],angularIntegralFail["NonzeroAngularDenominatorScalesRequired"]];
 gram=Table[Factor[(sp[vectors[[i]],total]sp[vectors[[j]],total]-m2 sp[vectors[[i]],vectors[[j]]])/
    (4scales[[i]]scales[[j]])],{i,Length[indices]},{j,Length[indices]}];
 prefactor=FeynFacet`MasslessPhaseSpaceVolume[2,m2,e]*
  ((family["MeasurePrefactor"]/(2Pi)^(2-D)Abs[a]^-D)/.D->4-2e);
 <|"Format"->"FeynFacet-TwoBodyAngularGeometry","Family"->family,"DimensionalRegulator"->e,
  "AngularIndices"->indices,"DenominatorScales"->scales,"BetaGram"->gram,
  "TotalMomentum"->total,"InvariantMassSquared"->m2,"RoutingJacobian"->Abs[a]^(-4+2e),
  "PhaseSpacePrefactor"->prefactor,"Assumptions"->conditions,
  "OrdinaryPrescriptionRemoved"->False,"EndpointExpansionIncluded"->False|>
],"AngularIntegrals"];
twoBodyAngularCertificate[family_,bounds_]:=twoBodyAngularCertificate[family,bounds]=
 FeynFacet`CertifyOrdinaryPrescriptionRemoval[family,FeynCalc`GLI[family["Topology"][[1]],bounds],
  <|"ExternalKinematicConditions"->family["Assumptions"]|>];
EvaluateTwoBodyCutIntegral[geometry_Association,integral_FeynCalc`GLI,powerBounds_:Automatic]:=Catch[Module[
 {family,e,nu,indices,scales,gram,active,reduction,prefactor,constant=1,kept={},power,beta,bounds,certificate},
 If[Lookup[geometry,"Format",None]=!="FeynFacet-TwoBodyAngularGeometry",angularIntegralFail["TwoBodyAngularGeometryRequired"]];
 family=geometry["Family"];e=geometry["DimensionalRegulator"];nu=integral[[2]];
 If[integral[[1]]=!=family["Topology"][[1]]||Length[nu]=!=Length[family["Topology"][[2]]]||
   !VectorQ[nu,IntegerQ]||nu[[family["CutIndices"]]]=!=ConstantArray[1,Length[family["CutIndices"]]],
  angularIntegralFail["MatchingTwoBodyUnitCutIntegralRequired"]];
 bounds=If[powerBounds===Automatic,Max[#,0]&/@nu,powerBounds];
 If[!MatchQ[bounds,{__Integer}]||Length[bounds]=!=Length[nu]||
   bounds[[family["CutIndices"]]]=!=nu[[family["CutIndices"]]]||!TrueQ[And@@Thread[bounds>=nu]]||Min[bounds]<0,
  angularIntegralFail["DominatingUnitCutPowerBoundsRequired"]];
 certificate=twoBodyAngularCertificate[family,bounds];
 If[!AssociationQ[certificate]||FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"GenericKinematics"]=!=True,
  angularIntegralFail["TwoBodyOrdinaryPrescriptionCertificateRequired",<|"Cause"->certificate|>]];
 indices=geometry["AngularIndices"];scales=geometry["DenominatorScales"];gram=geometry["BetaGram"];
 active=Select[Range[Length[indices]],nu[[indices[[#]]]]=!=0&];
 Do[
  power=nu[[indices[[i]]]];constant*=scales[[i]]^-power;
  If[gram[[i,i]]=!=0,AppendTo[kept,i]],{i,active}];
 If[Length[kept]>2,angularIntegralFail["AtMostTwoIndependentAngularDenominatorsRequired"]];
 reduction=If[kept==={},<|"Format"->"FeynFacet-TwoBodyAngularReduction","DimensionalRegulator"->e,
   "Powers"->{0},"BetaGram"->{{0}},"Reduction"->1,"Seeds"-><||>,"ExactExpression"->1|>,
  FeynFacet`ReduceTwoBodyAngularPowers[nu[[indices[[kept]]]],gram[[kept,kept]],e]];
 If[!AssociationQ[reduction],angularIntegralFail["TwoBodyAngularReductionFailed",<|"Cause"->reduction|>]];
 prefactor=geometry["PhaseSpacePrefactor"]constant;
 Join[reduction,<|"MasterIntegral"->integral,"PhysicalPrefactor"->prefactor,
  "AnalyticExpression"->prefactor reduction["ExactExpression"],
  "OriginalFamily"->family,"OrdinaryPrescriptionRemoved"->True,
  "OrdinaryPrescriptionCertificate"->certificate,"CertifiedPowerBounds"->bounds,
  "EndpointExpansionIncluded"->False|>]
],"AngularIntegrals"];

EvaluateTwoBodyIntegralCombination[data_Association,request_Association]:=Catch[Module[
 {e=Lookup[request,"DimensionalRegulator",Global`Epsilon],families,targets,coefficients,
  geometries=<||>,bounds=<||>,integrals=<||>,values,name,selected,geometry,answer,value,normalization,started=facetElapsedClock[],counter=0,verbose=Lookup[request,"PrintTimings",False],commonPhase,normalized,hyper,aliases,formal,field,restore,vars,compact,seedRows,cached,file,reductions,monomials,bySeed,seedValues,localSeeds,seedFunctions,seedIndices,localValues},
 If[!MemberQ[{"FeynFacet-MeasuredIntegralDecomposition","FeynFacet-CombinedCutIntegralDecompositions"},Lookup[data,"Format",None]],
  angularIntegralFail["CompletedTypedIntegralDecompositionRequired"]];
 families=Association[(#["Topology"][[1]]->#)&/@data["Families"]];targets=data["Targets"];
 coefficients=If[data["Format"]==="FeynFacet-MeasuredIntegralDecomposition",<|"Scalar"->data["Coefficients"]|>,data["Coefficients"]];
 Do[
  selected=Select[targets,First[#]===name&];
  If[selected==={},Continue[]];
  If[TrueQ[verbose],Print["ANGULAR GEOMETRY ",name," SECONDS ",N[facetElapsedClock[]-started]]];
  geometry=FeynFacet`ConstructTwoBodyAngularGeometry[families[name],e];
  If[!AssociationQ[geometry],angularIntegralFail["TwoBodyFamilyGeometryFailed",<|"Family"->name,"Cause"->geometry|>]];
  AssociateTo[geometries,name->geometry];
  AssociateTo[bounds,name->(Max[Prepend[#,0]]&/@Transpose[Last/@selected])],
 {name,Keys[families]}];
 file=Lookup[request,"IntegralEvaluationFile",None];
 cached=If[StringQ[file]&&FileExistsQ[file],FeynFacet`FamilyArtifactRead[file],None];
 If[AssociationQ[cached]&&Lookup[cached,"DimensionalRegulator",None]===e&&
   Lookup[cached,"Families",None]===data["Families"]&&Keys[Lookup[cached,"IntegralEvaluations",<||>]]===targets,
  integrals=cached["IntegralEvaluations"],
  Do[
   counter++;If[TrueQ[verbose]&&(counter<=3||Mod[counter,20]===0),Print["ANGULAR INTEGRAL ",counter,"/",Length[targets]," ",integral," SECONDS ",N[facetElapsedClock[]-started]]];
   answer=FeynFacet`EvaluateTwoBodyCutIntegral[geometries[First[integral]],integral,bounds[First[integral]]];
   If[!AssociationQ[answer],angularIntegralFail["TwoBodyIntegralEvaluationFailed",<|"Integral"->integral,"Cause"->answer|>]];
   AssociateTo[integrals,integral->answer],{integral,targets}];
  If[StringQ[file],FeynFacet`FamilyArtifactWrite[<|"DimensionalRegulator"->e,
   "Families"->data["Families"],"IntegralEvaluations"->integrals|>,file,Compression->Automatic]]];
 If[TrueQ[verbose],Print["ANGULAR COMBINATION SECONDS ",N[facetElapsedClock[]-started]]];
 commonPhase=First[Values[geometries]]["PhaseSpacePrefactor"];
 If[!AllTrue[Values[geometries],#["PhaseSpacePrefactor"]===commonPhase&],
  angularIntegralFail["CommonTwoBodyPhaseSpaceNormalizationRequired"]];
 (* Keep the dimensional phase volume outside the rational cancellation.
    Reduce coefficients of independent analytic seeds separately; otherwise
    an expanded common numerator repeats every Gamma and angular function. *)
 (* Extract from each reduction while its seeds are still single symbols.
    Restoring hypergeometric expressions first made repeated denominator
    polynomials expand in the generic coefficient-field collector. *)
 hyper=DeleteDuplicates[Flatten[(Values[Map[#["ExactExpression"]&,#["Seeds"]]]&/@Values[integrals]),1]];
 reductions=Map[Function[row,
  localSeeds=Keys[row["Seeds"]];
  seedFunctions=Values[Map[#["ExactExpression"]&,row["Seeds"]]];
  seedIndices=Prepend[(First[FirstPosition[hyper,#]]&/@seedFunctions),0];
  localValues=Prepend[Coefficient[row["Reduction"],#]&/@localSeeds,
    row["Reduction"]/.Thread[localSeeds->0]];
  AssociationThread[seedIndices,Cancel[row["PhysicalPrefactor"]/commonPhase]localValues]],integrals];
 If[TrueQ[verbose],Print["ANGULAR REDUCTION COEFFICIENT BYTES ",ByteCount[reductions]]];
 seedValues=Flatten[Values/@Values[reductions]];
 compact=FeynFacet`CancelRationalCoefficients[seedValues];
 If[!ListQ[compact]||Length[compact]=!=Length[seedValues],angularIntegralFail["CompactAngularReductionCoefficientsRequired"]];
 compact=(Numerator[#]/Factor[Denominator[#]])&/@compact;
 counter=0;reductions=Map[Function[row,AssociationThread[Keys[row],
   Take[compact,{counter+1,counter+=Length[row]}]]],reductions];
 If[TrueQ[verbose],Print["ANGULAR REDUCTION COEFFICIENTS COMPACTED BYTES ",ByteCount[reductions]," SECONDS ",N[facetElapsedClock[]-started]]];
 monomials=Range[0,Length[hyper]];
 normalization=Lookup[request,"CurrentNormalization",1]Lookup[request,"SymmetryFactor",1]Lookup[request,"FlavorMultiplicity",1];
 values=Map[Function[row,
  bySeed=Table[Total[KeyValueMap[#2 Lookup[reductions[#1],Key[monomial],0]&,row]]/.D->4-2e,{monomial,monomials}];
  If[TrueQ[verbose],Print["ANGULAR RATIONAL COEFFICIENTS BYTES ",ByteCount[bySeed]," SECONDS ",N[facetElapsedClock[]-started]]];
  If[ByteCount[bySeed]>Lookup[request,"MaximumCombinationBytes",536870912],
   angularIntegralFail["AngularCombinationExpressionSizeLimit",<|"Bytes"->ByteCount[bySeed]|>]];
  {field,restore}=coefficientRationalFieldReduce[bySeed];
  vars=DeleteDuplicates[Cases[field,_Symbol,{0,Infinity}]];
  compact=If[vars==={},field,FeynFacet`CancelRationalExpressions[field,vars]];
  If[!ListQ[compact]||Length[compact]=!=Length[monomials],angularIntegralFail["ExplicitAngularCombinationCancellationFailed",<|"Cause"->compact|>]];
  compact=(Numerator[#]/Factor[Denominator[#]])&/@compact;
  compact=compact/.restore;
  If[TrueQ[verbose],Print["ANGULAR RATIONAL COEFFICIENTS REDUCED BYTES ",ByteCount[compact]," SECONDS ",N[facetElapsedClock[]-started]]];
  value=compact.Prepend[hyper,1];
  FeynFacet`SubstituteScalarPowers[normalization commonPhase value,Lookup[request,"BareCouplingRules",{}]]/.
   Lookup[request,"ColorRules",{}]],coefficients];

 If[!FreeQ[values,_FeynCalc`GLI|_FeynCalc`Pair|_FeynCalc`FeynAmpDenominator|_FeynCalc`SMP|_Integrate|_Failure]||
   (!FreeQ[values,s_Symbol/;StringStartsQ[SymbolName[s],"angularSingle$"|"angularPair$"|"angularFunction$"]]),
  angularIntegralFail["IntegratedTwoBodyScalarCombinationRequired"]];
 answer=<|"Format"->"FeynFacet-TwoBodyAngularDensity","DimensionalRegulator"->e,
  "Values"->values,"IntegralEvaluations"->integrals,"FamilyGeometries"->geometries,
  "OrdinaryPowerBounds"->bounds,"OrdinaryPrescriptionScope"->"GenericKinematics",
  "EndpointExpansionIncluded"->False,"ExactInEpsilon"->True|>;
 cached=FeynFacet`PublishTwoBodyAngularSeeds[answer];
 If[!AssociationQ[cached],angularIntegralFail["AngularSeedPublicationFailed",<|"Cause"->cached|>]];
 Append[answer,"MasterLibraryPublication"->cached]
],"AngularIntegrals"];

(* Publish the independent angular seed functions, not every numerator or
   raised-power target reduced to them. Canonical library families further
   identify equivalent seed integrals across source families. *)
PublishTwoBodyAngularSeeds[data_Association,request_Association:<||>]:=Catch[Module[
 {mode=Lookup[request,"Mode",FeynFacet`$MasterIntegralLibraryMode],geometries,integrals,e,
  targets={},nu,indices,active,seed,geometry,family,selected,master,definitions,
  values=<||>,found,answer,stored,records={},row,started=facetElapsedClock[]},
 If[MemberQ[{"Disabled","ReadOnly"},mode],Return[<|"Status"->"PublicationDisabled","Mode"->mode,"SeedCount"->0,"Seconds"->0|>]];
 If[Lookup[data,"Format",None]=!="FeynFacet-TwoBodyAngularDensity",angularIntegralFail["TwoBodyAngularDensityRequired"]];
 geometries=data["FamilyGeometries"];integrals=data["IntegralEvaluations"];e=data["DimensionalRegulator"];
 KeyValueMap[Function[{identifier,evaluation},
  geometry=geometries[First[identifier]];family=geometry["Family"];
  nu=ConstantArray[0,Length[identifier[[2]]]];nu[[family["CutIndices"]]]=1;
  AppendTo[targets,FeynCalc`GLI[First[identifier],nu]];
  indices=geometry["AngularIndices"];
  active=Select[Range[Length[indices]],identifier[[2,indices[[#]]]]=!=0&];
  Do[
   selected=Switch[seed["Type"],
    "SingleMassive",Take[Select[active,Cancel[Together[geometry["BetaGram"][[#,#]]-(1-4seed["MassInvariant"])]]===0&],UpTo[1]],
    "MasslessPair"|"OneMassPair",active,
    _,angularIntegralFail["KnownAngularSeedRequired"]];
   If[Length[selected]=!=If[seed["Type"]==="SingleMassive",1,2],angularIntegralFail["AngularSeedDirectionsRequired"]];
   nu=ConstantArray[0,Length[identifier[[2]]]];nu[[family["CutIndices"]]]=1;nu[[indices[[selected]]]]=1;
   AppendTo[targets,FeynCalc`GLI[First[identifier],nu]],{seed,Values[evaluation["Seeds"]]}]
 ],integrals];
 targets=DeleteDuplicates[targets];
 definitions=FeynFacet`ConstructMasterIntegralDefinitions[<|
  "MasterIntegralBasis"->targets,"Topologies"->(# ["Family"]&/@Values[geometries]),
  "DimensionalRegulator"->e|>];
 If[!AssociationQ[definitions]||definitions["UnresolvedIntegralDefinitions"]=!=<||>,
  angularIntegralFail["AngularLibraryDefinitionsRequired",<|"Cause"->definitions|>]];
 Do[
  master=targets[[index]];row=definitions["MasterIntegralDefinitions"][index];
  found=FeynFacet`FindMasterIntegralValue[row,Automatic,request];
  If[FailureQ[found],angularIntegralFail["AngularLibraryLookupFailed",<|"Cause"->found|>]];
  If[AssociationQ[found],AppendTo[records,<|"MasterIntegral"->master,"Status"->"Reused"|>];Continue[]];
  geometry=geometries[First[master]];
  answer=FeynFacet`EvaluateTwoBodyCutIntegral[geometry,master];
  If[!AssociationQ[answer],angularIntegralFail["AngularSeedValueRequired",<|"Cause"->answer|>]];
  stored=FeynFacet`StoreMasterIntegralValue[row,<|"ExactValue"->answer["AnalyticExpression"]|>,
   Join[request,<|"Provenance"-><|"Producer"->"TwoBodyAngularSeeds","EvaluationScope"->"GenericKinematics"|>|>]];
  If[FailureQ[stored],angularIntegralFail["AngularSeedPublicationFailed",<|"Cause"->stored|>]];
  AppendTo[records,<|"MasterIntegral"->master,"Status"->"Stored"|>],{index,Length[targets]}];
 <|"Status"->"Completed","Mode"->mode,"SeedCount"->Length[targets],"Records"->records,
  "StoredCount"->Count[Lookup[records,"Status"],"Stored"],"ReusedCount"->Count[Lookup[records,"Status"],"Reused"],
  "Seconds"->facetElapsedClock[]-started,"EndpointExpansionIncluded"->False|>
],"AngularIntegrals"];

(* An even angular function may use either real square root. When its
   squared argument is a rational square and |root|<1 is established, use
   the signed rational root. This removes spurious absolute values at a
   massive-direction collision without excluding that kinematic surface. *)
angularSeedSquareRoot[argument_,assum_]:=Module[{value,numerator,denominator,constant,factors,root},
 value=Together[argument];
 If[value===0,Return[0]];
 numerator=FactorList[Numerator[value]];denominator=FactorList[Denominator[value]];
 constant=First[numerator][[1]]/First[denominator][[1]];
 factors=Join[Rest[numerator],({First[#],-Last[#]}&/@Rest[denominator])];
 If[!AllTrue[factors,EvenQ[Last[#]]&]||!TrueQ[constant>0],Return[Sqrt[argument]]];
 root=Sqrt[constant]Times@@(First[#]^(Last[#]/2)&/@factors);
 If[TrueQ[FullSimplify[-1<root<1,assum]],root,Sqrt[argument]]
];

angularSeedCoefficients[seed_,e_,high_]:=Module[{b,v,r,l,c},
 Switch[seed["Type"],
  "SingleMassive",
   r=seed["MassInvariant"];b=angularSeedSquareRoot[1-4r,Lookup[seed,"Assumptions",True]];l=Log[1+b]-Log[1-b];
   If[b===0,Return[<|0->1,1->0|>]];
   (* This divided difference is analytic in beta squared. Store its
      removable value explicitly, so later specialization to a zero spatial
      velocity does not exclude a physical kinematic surface. *)
   <|0->Piecewise[{{1,1-4r==0}},l/(2b)],
     1->Piecewise[{{0,1-4r==0}},(PolyLog[2,2b/(1+b)]-PolyLog[2,-2b/(1-b)]-2l)/(2b)]|>,
  "OneMassPair",
   r=seed["MassInvariant"];v=seed["AngularInvariant"];b=Sqrt[1-4r];
   l=Log[(1+b)/(2v)]+Log[(1-b)/(2v)];
   <|-1->-1/(4v),0->-(l-2)/(4v),
    1->-(l^2/2-2l+2PolyLog[2,1-2v/(1+b)]+2PolyLog[2,1-2v/(1-b)])/(4v)|>,
  "MasslessPair",
   v=seed["AngularInvariant"];l=Log[v];
   <|-1->-1/(2v),0->(l+2)/(2v),1->-(l^2/2+2l+PolyLog[2,1-v])/(2v)|>,
  _,angularIntegralFail["KnownAngularSeedRequired"]]
];
ExpandTwoBodyAngularSeeds[data_Association,high_Integer]:=Catch[Module[
 {e,expr,seeds,rules={},lower,needed,seed,coefficient,coefficients,poly,lo},
 If[Lookup[data,"Format",None]=!="FeynFacet-TwoBodyAngularReduction"||!Between[high,{-1,1}],
  angularIntegralFail["AngularExpansionThroughOrderOneRequired"]];
 e=data["DimensionalRegulator"];expr=data["Reduction"];seeds=data["Seeds"];
 Do[
  coefficient=Coefficient[expr,symbol];lower=FeynFacet`DetermineMeromorphicLaurentLowerBound[coefficient,e];
  If[!IntegerQ[lower],angularIntegralFail["AngularCoefficientLaurentBoundRequired"]];
  needed=high-lower;
  If[needed>1,angularIntegralFail["HigherAngularSeedOrderRequired",<|"ThroughOrder"->needed|>]];
  seed=seeds[symbol];coefficients=angularSeedCoefficients[seed,e,needed];
  epsilonAuditMultiplier[coefficient,e,seed["LaurentLowerBound"],1,high,"TwoBodyAngularSeed",seed];
  AppendTo[rules,symbol->Total[KeyValueMap[#2 e^#1&,coefficients]]],
 {symbol,Keys[seeds]}];
 poly=Normal[Series[expr/.rules,{e,0,high}]];
 lo=FeynFacet`DetermineMeromorphicLaurentLowerBound[poly,e];
 If[lo===Infinity,lo=0];
 If[!IntegerQ[lo]||!FreeQ[poly,_SeriesData|_Series|_Derivative|_Hypergeometric2F1|_AppellF1|_Integrate],
  angularIntegralFail["ExplicitAngularLaurentCoefficientsRequired"]];
 <|"DimensionalRegulator"->e,"LaurentLowerBound"->lo,"KnownThroughOrder"->high,
  "Coefficients"->Association@Table[n->Coefficient[Expand[e^-lo poly],e,n-lo],{n,lo,high}],
  "ExactInEpsilon"->False,"EndpointExpansionIncluded"->False|>
],"AngularIntegrals"];
End[];EndPackage[];
