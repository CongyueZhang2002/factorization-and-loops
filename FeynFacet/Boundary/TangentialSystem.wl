(* A single smooth boundary divisor with one tangential coordinate.
   The normal gauge is constructed with the tangential variable symbolic.
   No derivative of a frozen gauge or commuting derivative of z^R is used. *)
Begin["FeynFacet`Private`"];

FeynFacet`ConstructTangentialEndpointSystem::usage =
 "ConstructTangentialEndpointSystem[system,request] constructs a normalized local normal system, its induced tangential DE, and finite generic-regulator Frobenius coefficients with all Jordan logarithms. The input normal and tangential connections are in the same symbolic coordinate chart.";
FeynFacet`MatchTangentialEndpointBoundaryBasis::usage =
 "MatchTangentialEndpointBoundaryBasis[endpoint,reference] proves the gauge comparison to a physically normalized normal-line system and maps its complete seed amplitudes to the normalized tangential initial vector.";
FeynFacet`ConstructTangentialEndpointSolution::usage =
 "ConstructTangentialEndpointSolution[endpoint,request] reuses the finite DE constructor for the tangential initial-vector functions and materializes all requested endpoint coefficients up to initial constants. Physical coefficients may be supplied with an explicitly matched boundary basis.";
FeynFacet`DetermineTangentialEndpointLaurentBounds::usage =
 "DetermineTangentialEndpointLaurentBounds[endpoint,matching,sourceBounds] propagates physical seed Laurent bounds through the exact matching map, tangential connection and normal connection, without solving coefficient functions. It also records the finite primary projection matrices' entry bounds.";
FeynFacet`ExtendTangentialEndpointSystem::usage =
 "ExtendTangentialEndpointSystem[acceptedEndpoint,maximumNormalOrder] extends the Frobenius jets of an accepted symbolic endpoint record, reusing its exact connections, gauge, inverse, residue, tangential connection and existing coefficients. It verifies all newly constructed normal and tangential coefficient identities.";

Clear[tangentialEndpointFail, tangentialEndpointMatrix,
 tangentialEndpointZeroQ, tangentialEndpointOrder,
 tangentialEndpointJet, tangentialEndpointPolynomial,
 tangentialEndpointSpectrum, tangentialEndpointRationalQ,
 tangentialEndpointRegulator, tangentialEndpointPhysicalConstants,
 tangentialEndpointSeedCoefficientExpressions,tangentialEndpointPropagateBounds,
 tangentialEndpointMappedBounds];
tangentialEndpointFail[tag_,data_:<||>] :=
 Throw[Failure[tag,data],"TangentialEndpoint"];
tangentialEndpointMatrix[m_] := Map[Cancel[Together[#]]&,Normal[m],{2}];
tangentialEndpointZeroQ[m_] := AllTrue[Flatten[{Normal[m]}],
 TrueQ[Cancel[Together[#]]===0]&];
tangentialEndpointOrder[m_,z_] := Min[Flatten[
 Map[boundaryLocalOrder[#,z]&,Normal[m],{2}]]];
tangentialEndpointRegulator[x_,e_] := x /.
 q_Symbol /; MemberQ[{"eps","ep","Epsilon"},SymbolName[q]] :> e;
tangentialEndpointRationalQ[x_,vars_] := FreeQ[x,_Real] &&
 AllTrue[Flatten[{Normal[x]}],With[{a=Cancel[Together[#]]},
 PolynomialQ[Numerator[a],vars] && PolynomialQ[Denominator[a],vars]]&];
tangentialEndpointJet[m_,z_,k_Integer] := tangentialEndpointMatrix[
 Map[SeriesCoefficient[#,{z,0,k}]&,Normal[m],{2}]];
tangentialEndpointPolynomial[p_,x_,r_] := Module[
 {c=CoefficientList[p,x],a=0 r},
 Do[a=tangentialEndpointMatrix[a.r+c[[j]] IdentityMatrix[Length[r]]],
 {j,Length[c],1,-1}];a];
tangentialEndpointMappedBounds[matrix_,bounds_] := Table[
 Min[MapThread[If[#1===Infinity||#2===Infinity,Infinity,#1+#2]&,
   {row,bounds}]],{row,matrix}];
tangentialEndpointPropagateBounds[matrix_,bounds_] := Module[
 {current=bounds,next,changed=False},
 Do[next=MapThread[Min,{current,tangentialEndpointMappedBounds[matrix,current]}];
  changed=next=!=current;current=next;If[!changed,Break[]],{Length[bounds]}];
 If[changed,Failure["LaurentBoundsRequireFurtherConnectionReduction",<||>],current]];

(* A supplied annihilator is checked exactly. Generic eigenvalues must be
   affine in epsilon and have zero integer part after normalization. This
   implies that (n+lambda)1-R is invertible over Q(v,epsilon) for every
   positive integer n, including when eigenvalues coalesce at epsilon=0. *)
tangentialEndpointSpectrum[r_,v_,e_,annihilator_,x_] := Module[
 {p,factors,values,other,h,q,projector,power,index,sectors={},minimal=1},
 p=If[annihilator===Automatic,CharacteristicPolynomial[r,x],annihilator];
 If[!PolynomialQ[p,x] || Exponent[p,x]<1 ||
   !tangentialEndpointZeroQ[tangentialEndpointPolynomial[p,x,r]],
  tangentialEndpointFail["EndpointResidueAnnihilatorInvalid"]];
 factors=Select[FactorList[p],Exponent[First[#],x]>0&];
 If[!AllTrue[factors,Exponent[First[#],x]===1&],
  tangentialEndpointFail["NonrationalEndpointExponentsUnsupported"]];
 values=Cancel[-Coefficient[First[#],x,0]/Coefficient[First[#],x,1]]&/@factors;
 If[!FreeQ[values,v] || !AllTrue[values,
   PolynomialQ[#,e] && Exponent[#,e]<=1 && TrueQ[(#/.e->0)===0]&],
  tangentialEndpointFail["NormalizedAffineEndpointExponentsRequired",
   <|"ResidueEigenvalues"->values|>]];
 Do[
  other=Cancel[p/(x-values[[j]])^factors[[j,2]]];
  h=Unique["endpointSpectralShift"];
  q=Expand[other (Normal[Series[1/(other/.x->h+values[[j]]),
     {h,0,factors[[j,2]]-1}]]/.h->x-values[[j]])];
  projector=tangentialEndpointPolynomial[q,x,r];
  power=projector;index=0;
  While[!tangentialEndpointZeroQ[power] && index<=Length[r],
   power=tangentialEndpointMatrix[(r-values[[j]] IdentityMatrix[Length[r]]).power];
   index++];
  If[index>Length[r] || index===0 ||
    !tangentialEndpointZeroQ[projector.projector-projector],
   tangentialEndpointFail["EndpointPrimaryProjectorInvalid"]];
  minimal=Expand[minimal (x-values[[j]])^index];
  AppendTo[sectors,<|"Exponent"->values[[j]],
   "Projector"->projector,"NilpotencyIndex"->index|>],
 {j,Length[factors]}];
 If[!tangentialEndpointZeroQ[Total[Lookup[sectors,"Projector"]]-IdentityMatrix[Length[r]]],
  tangentialEndpointFail["EndpointPrimaryDecompositionIncomplete"]];
 <|"Sectors"->sectors,"MinimalPolynomial"->minimal,
   "SpectralVariable"->x|>
];

Options[FeynFacet`ConstructTangentialEndpointSystem]={
 "NormalGaugeMatrix"->Automatic,"ParameterVerificationRules"->{},"Verbose"->False};
FeynFacet`ConstructTangentialEndpointSystem[system_Association,
 request_Association,OptionsPattern[]] := Catch[Module[
 {z,v,e,a,b,n,order,domain,branch,t,ti,clean,normalized,r,gamma,
  spectrum,x,normalJet,tangentJet,expansions={},expansion,jet,residual,
  gaugeLow,originalJet,originalOrder,originalTerms={},originalMatrices,
  j,k,l,sector,coalescing,progress,normalizationChecks=None},
 z=Lookup[system,"NormalVariable",None];v=Lookup[system,"TangentialVariable",None];
 e=Lookup[system,"DimensionalRegulator",None];
 If[!MatchQ[{z,v,e},{_Symbol,_Symbol,_Symbol}] || !DuplicateFreeQ[{z,v,e}],
  tangentialEndpointFail["EndpointCoordinateChartRequired"]];
 a=tangentialEndpointRegulator[Lookup[system,"NormalConnectionMatrix",{}],e];
 b=tangentialEndpointRegulator[Lookup[system,"TangentialConnectionMatrix",{}],e];
 n=Length[a];order=Lookup[request,"MaximumNormalOrder",None];
 domain=Lookup[request,"AnalyticDomain",None];branch=Lookup[request,"BranchPrescription",None];
 If[n<1 || Dimensions[a]=!={n,n} || Dimensions[b]=!={n,n} ||
   !IntegerQ[order] || order<0 || !StringQ[domain] || !StringQ[branch],
  tangentialEndpointFail["TangentialEndpointInputsInvalid"]];
 If[!tangentialEndpointRationalQ[{a,b},{z,v,e}],
  tangentialEndpointFail["RationalTangentialEndpointChartRequired"]];
 {a,b}=tangentialEndpointMatrix/@{a,b};
 If[!tangentialEndpointZeroQ[D[a,v]-D[b,z]+a.b-b.a],
  tangentialEndpointFail["EndpointConnectionNotFlat"]];
 progress[s_]:=If[TrueQ[OptionValue["Verbose"]],Print[s]];
 t=OptionValue["NormalGaugeMatrix"];ti=Automatic;
 If[t===Automatic,
  progress["Constructing the normal gauge with symbolic tangential kinematics."];
  clean=RemoveCoalescingApparentSingularities[<|"Variable"->z,
    "DimensionalRegulator"->e,"ConnectionMatrix"->a|>,
    "ParameterVerificationRules"->OptionValue["ParameterVerificationRules"],
    "Verbose"->OptionValue["Verbose"]];
  If[FailureQ[clean],tangentialEndpointFail["SymbolicEndpointApparentPoleRemovalFailed",<|"Cause"->clean|>]];
  normalized=NormalizeRegularSingularSystem[clean,
    "ParameterVerificationRules"->OptionValue["ParameterVerificationRules"],
    "Verbose"->OptionValue["Verbose"]];
  If[FailureQ[normalized],tangentialEndpointFail["SymbolicEndpointNormalizationFailed",<|"Cause"->normalized|>]];
  normalizationChecks=<|"ApparentPoleRemoval"->Lookup[clean,"NormalizationVerifications",{}],
    "EndpointNormalization"->normalized["Verification"]|>;
  progress["Composing the symbolic normal gauge and its inverse factors."];
  t=tangentialEndpointMatrix[RegularSingularGaugeMatrix[clean].RegularSingularGaugeMatrix[normalized]];
  ti=tangentialEndpointMatrix[RegularSingularInverseGaugeMatrix[normalized].
    RegularSingularInverseGaugeMatrix[clean]]];
 t=tangentialEndpointRegulator[t,e];
 If[Dimensions[t]=!={n,n} || !tangentialEndpointRationalQ[t,{z,v,e}],
  tangentialEndpointFail["SymbolicRationalNormalGaugeRequired"]];
 If[ti===Automatic,ti=Quiet[Check[Inverse[t],$Failed]]];
 If[ti===$Failed || !MatrixQ[ti] || !boundaryFiniteQ[ti],
  tangentialEndpointFail["EndpointNormalGaugeSingular"]];
 ti=tangentialEndpointMatrix[ti];
 progress["Recomputing both symbolic transformed connections with the full gauge derivatives."];
 a=tangentialEndpointMatrix[ti.(a.t-D[t,z])];
 b=tangentialEndpointMatrix[ti.(b.t-D[t,v])];
 If[!TrueQ[tangentialEndpointOrder[a,z]>=-1],
  tangentialEndpointFail["EndpointNormalConnectionNotFuchsian"]];
 If[!TrueQ[tangentialEndpointOrder[b,z]>=0],
  tangentialEndpointFail["TangentialEndpointPoleRequiresCoefficientStateConstruction",
   <|"TangentialNormalOrder"->tangentialEndpointOrder[b,z]|>]];
 (* A joint normal/epsilon expansion cannot silently cross an apparent
    divisor whose location tends to the endpoint. *)
 coalescing=DeleteDuplicates@Flatten[Map[Function[value,
   Select[First/@Rest[FactorList[Denominator[Cancel[Together[value]]]]],
    !FreeQ[#,z] && !FreeQ[#,e] && TrueQ[(#/.{z->0,e->0})===0]&]],
   Flatten[{a,b,t}]]];
 If[coalescing=!={},tangentialEndpointFail["CoalescingEndpointDivisorRequiresRemoval",
   <|"Divisors"->coalescing|>]];
 r=tangentialEndpointJet[z a,z,0];gamma=tangentialEndpointJet[b,z,0];
 If[!tangentialEndpointZeroQ[D[r,v]+r.gamma-gamma.r],
  tangentialEndpointFail["EndpointResidueNotHorizontal"]];
 x=Lookup[request,"SpectralVariable",Unique["endpointEigenvalue"]];
 spectrum=tangentialEndpointSpectrum[r,v,e,
   Lookup[request,"ResidueAnnihilatingPolynomial",Automatic],x];
 normalJet=Table[tangentialEndpointJet[z a,z,k],{k,0,order}];
 tangentJet=Table[tangentialEndpointJet[b,z,k],{k,0,order}];
 gaugeLow=tangentialEndpointOrder[t,z];originalOrder=order+gaugeLow;
 If[!IntegerQ[gaugeLow],tangentialEndpointFail["NormalGaugeLaurentOrderUndetermined"]];
 originalJet=Association@Table[k->tangentialEndpointJet[t,z,k],{k,gaugeLow,originalOrder}];
 Do[
  progress["Constructing endpoint exponent "<>ToString[sector["Exponent"],InputForm]<>"."];
  expansion=FeynFacet`ConstructPrimaryFrobeniusExpansion[
   <|"Variable"->z,"DimensionalRegulator"->e,"ConnectionMatrix"->a|>,
   <|"Basis"->IdentityMatrix[n],"LeftInverse"->IdentityMatrix[n]|>,
   <|"ResidueEigenvalue"->sector["Exponent"],"SpectralVariable"->x,
     "ResidueAnnihilatingPolynomial"->spectrum["MinimalPolynomial"],
     "MaximumNormalOrder"->order|>,"Verbose"->OptionValue["Verbose"]];
  If[FailureQ[expansion],tangentialEndpointFail["EndpointPrimaryExpansionFailed",<|"Cause"->expansion|>]];
  jet=Map[Normal,expansion["Coefficients"],{2}];
  Do[
   residual=D[jet[[k+1,l+1]],v]+jet[[k+1,l+1]].gamma-
      Total@Table[tangentJet[[j+1]].jet[[k-j+1,l+1]],{j,0,k}];
   If[!tangentialEndpointZeroQ[residual],
    tangentialEndpointFail["EndpointTangentialCoefficientResidualFailed",
     <|"Exponent"->sector["Exponent"],"NormalPower"->k,"LogarithmPower"->l|>]];
   residual=((k+sector["Exponent"]) IdentityMatrix[n]-r).jet[[k+1,l+1]]+
     If[l+1<sector["NilpotencyIndex"],(l+1)jet[[k+1,l+2]],0 r]-
     If[k===0,0 r,Total@Table[normalJet[[j+1]].jet[[k-j+1,l+1]],{j,1,k}]];
   If[!tangentialEndpointZeroQ[residual],
    tangentialEndpointFail["EndpointNormalCoefficientResidualFailed"]],
   {k,0,order},{l,0,sector["NilpotencyIndex"]-1}];
  originalMatrices=Table[tangentialEndpointMatrix[Total@Table[
     originalJet[j].jet[[k-j+1,l+1]],{j,gaugeLow,k}]],
    {k,gaugeLow,originalOrder},{l,0,sector["NilpotencyIndex"]-1}];
  AppendTo[expansions,Join[sector,<|"NormalizedCoefficients"->jet,
    "OriginalCoefficients"->originalMatrices,
    "OriginalNormalOrderRange"->{gaugeLow,originalOrder}|>]],
 {sector,spectrum["Sectors"]}];
 <|"DataType"->"TangentialEndpointSystem","SchemaVersion"->1,
  "Status"->"TangentialEndpointSystemConstructed","NormalVariable"->z,
  "TangentialVariable"->v,"DimensionalRegulator"->e,"Dimension"->n,
  "OriginalMasterIntegralBasis"->Lookup[system,"OriginalMasterIntegralBasis",Range[n]],
  "NormalGaugeMatrix"->t,"InverseNormalGaugeMatrix"->ti,
  "NormalGaugeConstructionVerification"->normalizationChecks,
  "ConnectionConstructionMethod"->"Both connections are recomputed by exact symbolic pullback of the original connection with the full parameter-dependent gauge and its derivatives.",
  "NormalizedNormalConnectionMatrix"->a,"NormalizedTangentialConnectionMatrix"->b,
  "NormalResidue"->r,"TangentialConnectionMatrix"->gamma,
  "MaximumNormalOrder"->order,"OriginalNormalOrderRange"->{gaugeLow,originalOrder},
  "PrimarySectors"->expansions,"AnalyticDomain"->domain,"BranchPrescription"->branch,
  "Verification"-><|"Method"->"ExactSymbolicIdentities","Flatness"->True,
   "NormalResidueHorizontality"->True,"NormalCoefficientEquations"->True,
   "TangentialCoefficientEquations"->True|>,
  "CoefficientConvention"->"For each primary sector, OriginalCoefficients[[n-lower+1,l+1]].c(v,epsilon) multiplies z^(n+Exponent) Log[z]^l. The full normalized leading vector satisfies c'=TangentialConnectionMatrix.c.",
  "Scope"->"A smooth single divisor away from tangential singularities; no conclusion at intersections of endpoint divisors."|>
],"TangentialEndpoint"];

Options[FeynFacet`ExtendTangentialEndpointSystem]={"Verbose"->False};
FeynFacet`ExtendTangentialEndpointSystem[endpoint_Association,order_Integer,
 OptionsPattern[]] := Catch[Module[
 {z,v,e,n,a,b,t,r,gamma,old,gaugeLow,originalOrder,normalJet,tangentJet,
  originalJet,blocks,sectors={},sector,jet,linear,rhs,next,residual,original,
  m,j,k,l,progress,verification},
 old=Lookup[endpoint,"MaximumNormalOrder",None];
 verification=Lookup[endpoint,"Verification",<||>];
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem" ||
   !IntegerQ[old] || old<0 || order<old ||
   !AllTrue[Lookup[verification,{"Flatness","NormalResidueHorizontality",
     "NormalCoefficientEquations","TangentialCoefficientEquations"},False],TrueQ],
  tangentialEndpointFail["AcceptedTangentialEndpointRecordRequired"]];
 If[order===old,Return[endpoint,Module]];
 {z,v,e,n}=Lookup[endpoint,{"NormalVariable","TangentialVariable",
   "DimensionalRegulator","Dimension"}];
 {a,b,t,r,gamma}=Lookup[endpoint,{"NormalizedNormalConnectionMatrix",
   "NormalizedTangentialConnectionMatrix","NormalGaugeMatrix",
   "NormalResidue","TangentialConnectionMatrix"}];
 If[!AllTrue[{a,b,t,r,gamma,endpoint["InverseNormalGaugeMatrix"]},Dimensions[#]==={n,n}&],
  tangentialEndpointFail["AcceptedTangentialEndpointRecordRequired"]];
 gaugeLow=First[endpoint["OriginalNormalOrderRange"]];originalOrder=gaugeLow+order;
 progress[s_]:=If[TrueQ[OptionValue["Verbose"]],Print[s]];
 progress["Extending accepted normal coefficients from order "<>
   ToString[old]<>" through "<>ToString[order]<>"."];
 normalJet=Table[tangentialEndpointJet[z a,z,k],{k,0,order}];
 tangentJet=Table[tangentialEndpointJet[b,z,k],{k,0,order}];
 originalJet=Association@Table[k->tangentialEndpointJet[t,z,k],{k,gaugeLow,originalOrder}];
 blocks=familyBlockDecompositionComponents[Map[#===0&,Normal[r],{2}]]["OrderedComponents"];
 If[!ListQ[blocks],tangentialEndpointFail["EndpointResidueBlockOrderingFailed"]];
 Do[
  If[Dimensions[sector["NormalizedCoefficients"]]=!={old+1,sector["NilpotencyIndex"],n,n},
   tangentialEndpointFail["AcceptedEndpointCoefficientDimensionsInvalid"]];
  jet=Join[sector["NormalizedCoefficients"],
    ConstantArray[0,{order-old,sector["NilpotencyIndex"],n,n}]];
  Do[
   progress["Extending endpoint exponent "<>ToString[sector["Exponent"],InputForm]<>
     " at normal order "<>ToString[m]<>"."];
   linear=SparseArray[tangentialEndpointMatrix[(m+sector["Exponent"])IdentityMatrix[n]-r]];
   next=ConstantArray[0,{n,n}];
   Do[
    rhs=Total@Table[normalJet[[j+1]].jet[[m-j+1,l+1]],{j,1,m}];
    next=Normal[primarySolveByBlocks[linear,Normal[rhs-(l+1)next],blocks]];
    If[!MatrixQ[next]||!boundaryFiniteQ[next],
     tangentialEndpointFail["EndpointExtensionLinearSolveFailed"]];
    jet[[m+1,l+1]]=next,
    {l,sector["NilpotencyIndex"]-1,0,-1}],
   {m,old+1,order}];
  Do[
   residual=D[jet[[k+1,l+1]],v]+jet[[k+1,l+1]].gamma-
     Total@Table[tangentJet[[j+1]].jet[[k-j+1,l+1]],{j,0,k}];
   If[!tangentialEndpointZeroQ[residual],
    tangentialEndpointFail["EndpointTangentialCoefficientResidualFailed",
      <|"Exponent"->sector["Exponent"],"NormalPower"->k,"LogarithmPower"->l|>]];
   residual=((k+sector["Exponent"])IdentityMatrix[n]-r).jet[[k+1,l+1]]+
     If[l+1<sector["NilpotencyIndex"],(l+1)jet[[k+1,l+2]],0 r]-
     Total@Table[normalJet[[j+1]].jet[[k-j+1,l+1]],{j,1,k}];
   If[!tangentialEndpointZeroQ[residual],
    tangentialEndpointFail["EndpointNormalCoefficientResidualFailed"]],
   {k,old+1,order},{l,0,sector["NilpotencyIndex"]-1}];
  original=Join[sector["OriginalCoefficients"],
    Table[tangentialEndpointMatrix[Total@Table[
      originalJet[j].jet[[k-j+1,l+1]],{j,gaugeLow,k}]],
     {k,gaugeLow+old+1,originalOrder},{l,0,sector["NilpotencyIndex"]-1}]];
  AppendTo[sectors,Join[sector,<|"NormalizedCoefficients"->jet,
    "OriginalCoefficients"->original,"OriginalNormalOrderRange"->{gaugeLow,originalOrder}|>]],
  {sector,endpoint["PrimarySectors"]}];
 Join[endpoint,<|"MaximumNormalOrder"->order,"PrimarySectors"->sectors,
   "OriginalNormalOrderRange"->{gaugeLow,originalOrder},
   "ExtensionVerification"-><|"Method"->"ExactSymbolicCoefficientIdentities",
     "ReusedAcceptedNormalOrder"->old,"VerifiedNewNormalOrders"->{old+1,order},
     "NormalCoefficientEquations"->True,"TangentialCoefficientEquations"->True,
     "GaugeAndConnectionsReused"->True|>|>]
],"TangentialEndpoint"];

FeynFacet`DetermineTangentialEndpointLaurentBounds[endpoint_Association,
 matching_Association,sourceBounds_List] := Catch[Module[
 {e,n,z,v,base,mapValues,initial,tangentValues,tangentBounds,normalValues,
  normalBounds,gaugeValues,originalBounds,sectors,uniformSectorBounds},
 e=Lookup[endpoint,"DimensionalRegulator",None];n=Lookup[endpoint,"Dimension",None];
 {z,v}=Lookup[endpoint,{"NormalVariable","TangentialVariable"}];
 base=Lookup[matching,"TangentialBasePoint",None];
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem" ||
   Lookup[matching,"DataType",None]=!="TangentialEndpointBoundaryBasisMatching" ||
   Length[sourceBounds]=!=Lookup[matching,"SourceAmplitudeCount",None] ||
   !VectorQ[sourceBounds,IntegerQ[#]||#===Infinity&],
  tangentialEndpointFail["EndpointMatchingAndPhysicalSeedBoundsRequired"]];
 mapValues=Map[solutionValuation[#,e]&,matching["AmplitudeToInitialVectorMatrix"],{2}];
 initial=tangentialEndpointMappedBounds[mapValues,sourceBounds];
 tangentValues=Map[solutionValuation[#,e]&,endpoint["TangentialConnectionMatrix"],{2}];
 tangentBounds=tangentialEndpointPropagateBounds[tangentValues,initial];
 If[FailureQ[tangentBounds],tangentialEndpointFail["TangentialLaurentBoundsRequireFurtherReduction"]];
 normalValues=Map[solutionValuation[#,e]&,endpoint["NormalizedNormalConnectionMatrix"],{2}];
 normalBounds=tangentialEndpointPropagateBounds[
   MapThread[Min,{normalValues,tangentValues},2],tangentBounds];
 If[FailureQ[normalBounds],tangentialEndpointFail["NormalLaurentBoundsRequireFurtherReduction"]];
 gaugeValues=Map[solutionValuation[#,e]&,endpoint["NormalGaugeMatrix"],{2}];
 originalBounds=tangentialEndpointMappedBounds[gaugeValues,normalBounds];
 (* Distinct generic-epsilon powers can cancel after epsilon expansion.
    Bounds on their sum therefore do not bound an individual primary mode.
    Compose each full leading logarithm projector with the physical seed
    map before taking valuations, then propagate the coefficient functions
    in that exponent sector. Taking the minimum over its logarithms also
    includes the epsilon-order-zero source -(l+1) f[l+1]/z. *)
 uniformSectorBounds=Map[Function[sector,Module[
   {mode=sector["Projector"],nilpotent=endpoint["NormalResidue"]-
      sector["Exponent"] IdentityMatrix[n],logBounds={},composed,
    sectorInitial,sectorNormalValues,sectorBounds},
   Do[
    composed=tangentialEndpointMatrix[(mode/.v->base).
      matching["AmplitudeToInitialVectorMatrix"]];
    AppendTo[logBounds,tangentialEndpointMappedBounds[
      Map[solutionValuation[#,e]&,composed,{2}],sourceBounds]];
    mode=tangentialEndpointMatrix[nilpotent.mode/(l+1)],
    {l,0,sector["NilpotencyIndex"]-1}];
   sectorInitial=Min/@Transpose[logBounds];
   sectorNormalValues=Map[solutionValuation[#,e]&,
     tangentialEndpointMatrix[endpoint["NormalizedNormalConnectionMatrix"]-
       sector["Exponent"] IdentityMatrix[n]/z],{2}];
   sectorBounds=tangentialEndpointPropagateBounds[
     MapThread[Min,{sectorNormalValues,tangentValues},2],sectorInitial];
   If[FailureQ[sectorBounds],tangentialEndpointFail[
     "PrimarySectorLaurentBoundsRequireFurtherReduction",<|"Exponent"->sector["Exponent"]|>]];
   <|"Exponent"->sector["Exponent"],"NilpotencyIndex"->sector["NilpotencyIndex"],
     "InitialLogarithmCoefficientLaurentLowerBounds"->logBounds,
     "UniformPrimarySectorNormalizedCoefficientLaurentLowerBounds"->sectorBounds,
     "UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"->
       tangentialEndpointMappedBounds[gaugeValues,sectorBounds]|>]],
   endpoint["PrimarySectors"]];
 sectors=Map[Function[sector,Module[{projected},
   projected=Map[solutionValuation[#,e]&,sector["OriginalCoefficients"],{4}];
   <|"Exponent"->sector["Exponent"],"NilpotencyIndex"->sector["NilpotencyIndex"],
    "OriginalNormalOrderRange"->sector["OriginalNormalOrderRange"],
    "OriginalCoefficientEntryEpsilonLowerBounds"->projected,
    "RepresentedCoefficientLaurentLowerBounds"->Map[
      tangentialEndpointMappedBounds[#,tangentBounds]&,projected,{2}]|>]],
  endpoint["PrimarySectors"]];
 <|"DataType"->"TangentialEndpointLaurentBounds","SchemaVersion"->1,
  "InitialConstantLaurentLowerBounds"->initial,
  "TangentialFunctionLaurentLowerBounds"->tangentBounds,
  "NormalizedFunctionLaurentLowerBounds"->normalBounds,
  "OriginalMasterIntegralLaurentLowerBounds"->originalBounds,
  "NormalGaugeEntryEpsilonLowerBounds"->gaugeValues,
  "PrimarySectors"->sectors,
  "UniformPrimarySectors"->uniformSectorBounds,
  "UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"->
    Association@Table[sector["Exponent"]->sector[
       "UniformPrimarySectorOriginalCoefficientLaurentLowerBounds"],
      {sector,uniformSectorBounds}],
  "Method"->"Exact rational Laurent valuations and all directed normal/tangential connection paths, following complete physical seed matching.",
  "Scope"->"Bounds on the complete epsilon-expanded functions and on the explicitly represented generic-exponent coefficient matrices. Bounds on omitted normal coefficients are not inferred from zero finite projections."|>
],"TangentialEndpoint"];

(* Frozen normal-line data enter only through an exact comparison of the
   complete gauges and seed matrices. Rectangular integral embeddings permit
   a family to inherit normalization from a larger closed physical system. *)
FeynFacet`MatchTangentialEndpointBoundaryBasis[endpoint_Association,
 reference_Association] := Catch[Module[
 {z,v,e,v0,n,source,rz,re,ra,sourceInverse,sourceGauge,seed,m,embedding,k,k0,
  targetA,targetR,sourceR,sourceR0,power,index=0,amplitudeMap},
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem",
  tangentialEndpointFail["TangentialEndpointSystemRequired"]];
 {z,v,e,n}=Lookup[endpoint,{"NormalVariable","TangentialVariable","DimensionalRegulator","Dimension"}];
 v0=Lookup[reference,"TangentialBasePoint",None];
 source=Lookup[reference,"NormalizedDifferentialSystem",<||>];
 rz=Lookup[source,"Variable",None];re=Lookup[source,"DimensionalRegulator",None];
 If[!NumericQ[v0] || !FreeQ[v0,_Real|v|z|e] ||
   !MatchQ[{rz,re},{_Symbol,_Symbol}],
  tangentialEndpointFail["FixedPhysicalNormalLineRequired"]];
 ra=tangentialEndpointRegulator[Lookup[source,"ConnectionMatrix",{}]/.{rz->z,re->e},e];
 sourceInverse=tangentialEndpointRegulator[
   Lookup[reference,"OriginalToNormalizedGauge",{}]/.{rz->z,re->e},e];
 sourceGauge=tangentialEndpointRegulator[
   Lookup[reference,"NormalizedToOriginalGauge",None]/.{rz->z,re->e},e];
 seed=tangentialEndpointRegulator[Lookup[reference,"SeedMatrix",{}]/.{rz->z,re->e},e];
 m=Length[ra];
 embedding=tangentialEndpointRegulator[Lookup[reference,"OriginalIntegralEmbedding",
   If[m===n,IdentityMatrix[n],{}]]/.{rz->z,re->e},e];
 If[m<1 || Dimensions[ra]=!={m,m} || Dimensions[sourceInverse]=!={m,m} ||
   !MatrixQ[seed] || Length[seed]=!=m || Dimensions[embedding]=!={n,m} ||
   !FreeQ[{ra,sourceInverse,seed,embedding},v] || !FreeQ[seed,z],
  tangentialEndpointFail["PhysicalNormalLineGaugeSeedOrEmbeddingInvalid"]];
 If[sourceGauge===None,sourceGauge=Quiet[Check[Inverse[sourceInverse],$Failed]]];
 If[sourceGauge===$Failed || !MatrixQ[sourceGauge] ||
   Dimensions[sourceGauge]=!={m,m} ||
   !tangentialEndpointZeroQ[sourceInverse.sourceGauge-IdentityMatrix[m]],
  tangentialEndpointFail["PhysicalNormalGaugeInverseMismatch"]];
 If[!tangentialEndpointRationalQ[{ra,sourceInverse,sourceGauge,seed,embedding},{z,e}],
  tangentialEndpointFail["RationalPhysicalNormalLineDataRequired"]];
 targetA=endpoint["NormalizedNormalConnectionMatrix"]/.v->v0;
 targetR=endpoint["NormalResidue"]/.v->v0;
 k=Quiet[Check[tangentialEndpointMatrix[
    (endpoint["InverseNormalGaugeMatrix"]/.v->v0).embedding.sourceGauge],$Failed]];
 If[k===$Failed || !MatrixQ[k] || !boundaryFiniteQ[k],
  tangentialEndpointFail["PhysicalNormalGaugeComparisonFailed"]];
 If[!tangentialEndpointZeroQ[D[k,z]-targetA.k+k.ra],
  tangentialEndpointFail["PhysicalIntegralEmbeddingDifferentialEquationMismatch"]];
 If[!TrueQ[tangentialEndpointOrder[k,z]>=0],
  tangentialEndpointFail["PhysicalGaugeComparisonRequiresResonantCoefficientMatching"]];
 sourceR=tangentialEndpointJet[z ra,z,0];
 sourceR0=tangentialEndpointMatrix[sourceR/.e->0];
 If[!boundaryFiniteQ[sourceR0],
  tangentialEndpointFail["EpsilonRegularReferenceResidueRequired"]];
 power=IdentityMatrix[m];
 While[index<=m && !tangentialEndpointZeroQ[power],
  power=tangentialEndpointMatrix[power.sourceR0];index++];
 If[index>m,tangentialEndpointFail["IntegerNormalizedReferenceResidueRequired"]];
 k0=tangentialEndpointJet[k,z,0];
 If[!tangentialEndpointZeroQ[targetR.k0-k0.sourceR],
  tangentialEndpointFail["PhysicalResidueIntertwiningFailed"]];
 amplitudeMap=tangentialEndpointMatrix[k0.seed];
 <|"DataType"->"TangentialEndpointBoundaryBasisMatching","SchemaVersion"->1,
  "TangentialBasePoint"->v0,"DimensionalRegulator"->e,
  "NormalVariable"->z,"TangentialVariable"->v,
  "NormalGaugeAtBasePoint"->(endpoint["NormalGaugeMatrix"]/.v->v0),
  "NormalResidueAtBasePoint"->targetR,
  "NormalizedGaugeComparison"->k,"NormalizedLeadingVectorMap"->k0,
  "AmplitudeToInitialVectorMatrix"->amplitudeMap,
  "SourceSeedMatrix"->seed,"SourceAmplitudeCount"->Dimensions[seed][[2]],
  "Verification"-><|"Method"->"ExactSymbolicIdentities",
    "GaugeComparisonDifferentialEquation"->True,"RegularGaugeComparison"->True,
    "IntegerNormalizedSourceResidue"->True,"ResidueIntertwining"->True|>,
  "Convention"->"c(v0,epsilon)=AmplitudeToInitialVectorMatrix.sourceAmplitudes(epsilon), with every source seed column retained before physical amplitude substitution."|>
],"TangentialEndpoint"];

(* Expand rational maps only over the epsilon orders actually needed.
   Missing coefficients inside a declared Laurent range are never zero. *)
tangentialEndpointSeedCoefficientExpressions[construction_,requests_,e_] := Module[
 {known,unknown,reduction,byColumn,sourceRequests,source,values=<||>,j,q,idx},
 known=Lookup[construction,"KnownAmplitudeExpressions",<||>];
 unknown=Lookup[construction,"UnknownAmplitudeDefinitions",{}];
 reduction=Lookup[construction,"AmplitudeReduction",<||>];
 If[!AssociationQ[known] || !ListQ[unknown] ||
   Lookup[reduction,"RemainingUnknownAmplitudeCount",None]=!=0 ||
   !TrueQ[Lookup[reduction,"AllBoundaryInputsPhysicallyDetermined",False]],
  tangentialEndpointFail["CompletePhysicalSeedAmplitudeConstructionRequired"]];
 byColumn=Association@Table[entry["Definition"]["SeedColumn"]->entry["Index"],{entry,unknown}];
 If[AnyTrue[requests,!KeyExistsQ[known,First[#]] && !KeyExistsQ[byColumn,First[#]]&],
  tangentialEndpointFail["PhysicalSeedAmplitudeColumnUnassigned"]];
 sourceRequests=DeleteDuplicates[Map[If[KeyExistsQ[known,First[#]],Nothing,
    {byColumn[First[#]],Last[#]}]&,requests]];
 source=FeynFacetSolution`BoundaryAmplitudeCoefficientExpressions[reduction,sourceRequests];
 If[FailureQ[source],tangentialEndpointFail["PhysicalBoundaryInputOrdersUnavailable",<|"Cause"->source|>]];
 Do[
  {j,q}=pair;
  AssociateTo[values,pair->If[KeyExistsQ[known,j],
    SeriesCoefficient[tangentialEndpointRegulator[known[j],e],{e,0,q}],
    tangentialEndpointRegulator[source[[Key[{byColumn[j],q}]]],e]]],
 {pair,requests}];
 values
];

tangentialEndpointPhysicalConstants[matching_,values_,bounds_,pairs_,e_] := Module[
 {matrix=matching["AmplitudeToInitialVectorMatrix"],c,needed={},rules={},available=values,
  i,q,j,m,val,coefficient,terms,lower,sourceCount},
 sourceCount=Dimensions[matrix][[2]];
 If[!AssociationQ[values] || !VectorQ[bounds,IntegerQ[#]||#===Infinity&] ||
   Length[bounds]=!=sourceCount,
  tangentialEndpointFail["ExplicitPhysicalAmplitudeCoefficientsAndBoundsRequired"]];
 c=Map[solutionValuation[#,e]&,matrix,{2}];
 lower=Table[Min[MapThread[If[#1===Infinity||#2===Infinity,Infinity,#1+#2]&,
   {c[[i]],bounds}]],{i,Length[matrix]}];
 If[KeyExistsQ[values,"PhysicalBoundaryConstruction"],
  needed=DeleteDuplicates[Flatten[Table[
    {i,q}=pair;
    Table[If[c[[i,j]]===Infinity || bounds[[j]]===Infinity,{},
      Table[If[TrueQ[Cancel[Together[SeriesCoefficient[matrix[[i,j]],{e,0,q-m}]]]===0],
        Nothing,{j,m}],{m,bounds[[j]],q-c[[i,j]]}]],{j,sourceCount}],
   {pair,pairs}],2]];
  available=tangentialEndpointSeedCoefficientExpressions[
    values["PhysicalBoundaryConstruction"],needed,e];needed={}];
 Do[
  {i,q}=pair;terms={};
  Do[
   If[c[[i,j]]===Infinity || bounds[[j]]===Infinity,Continue[]];
   epsilonAuditMultiplier[matrix[[i,j]],e,bounds[[j]],
     Max[Prepend[Last/@Select[Keys[available],ListQ[#]&&First[#]===j&],bounds[[j]]-1]],q,
     "Stage3/TangentialBoundaryMatching",{i,j,q}];
   Do[
    coefficient=Cancel[Together[SeriesCoefficient[matrix[[i,j]],{e,0,q-m}]]];
    If[coefficient===0,Continue[]];
    AppendTo[needed,{j,m}];
    If[!KeyExistsQ[available,{j,m}],tangentialEndpointFail["PhysicalEndpointAmplitudeOrderMissing",
      <|"AmplitudeIndex"->j,"EpsilonOrder"->m,"InitialVectorCoefficient"->pair|>]];
    val=available[[Key[{j,m}]]];
    If[!FreeQ[val,e|matching["NormalVariable"]|matching["TangentialVariable"]] ||
       !boundaryFiniteQ[val] || !solutionExplicitExpressionQ[val],
     tangentialEndpointFail["KinematicsIndependentPhysicalAmplitudeCoefficientRequired",
       <|"AmplitudeIndex"->j,"EpsilonOrder"->m|>]];
    AppendTo[terms,coefficient val],
   {m,bounds[[j]],q-c[[i,j]]}],
  {j,sourceCount}];
  AppendTo[rules,FeynFacetSolution`C[i,q]->Total[terms]],
 {pair,pairs}];
 <|"InitialConstantRules"->rules,"InitialConstantLaurentLowerBounds"->lower,
  "RequiredPhysicalAmplitudeCoefficients"->Sort[DeleteDuplicates[needed]]|>
];

Options[FeynFacet`ConstructTangentialEndpointSolution]={"Verbose"->False,
 "HomogeneousSolveTimeLimit"->30};
FeynFacet`ConstructTangentialEndpointSolution[endpoint_Association,
 request_Association,OptionsPattern[]] := Catch[Module[
 {z,v,e,n,base,range,lo,hi,bounds,physical,matching=None,sourceBounds,
  mapVal,entryLow,globalEntryLow,upper,neededRange,solution,system,solverRequest,
  sectors,sector,coefficients,matrices,normalRange,terms={},pairs,constantData=None,
  coefficient,vector,row,j,k,m,l,q,p,lower,cseries,values,allCoefficients,
  connectionValuations,functionBounds,nextBounds,changed,termValuations,termBounds},
 If[Lookup[endpoint,"DataType",None]=!="TangentialEndpointSystem",
  tangentialEndpointFail["TangentialEndpointSystemRequired"]];
 {z,v,e,n}=Lookup[endpoint,{"NormalVariable","TangentialVariable","DimensionalRegulator","Dimension"}];
 base=Lookup[request,"TangentialBasePoint",None];
 range=Lookup[request,"EpsilonOrderRange",None];
 If[!NumericQ[base] || !FreeQ[base,_Real|v|z|e] ||
   !MatchQ[range,{_Integer,_Integer}] || First[range]>Last[range],
  tangentialEndpointFail["TangentialBasePointAndFiniteEpsilonRangeRequired"]];
 {lo,hi}=range;
 physical=Lookup[request,"PhysicalBoundaryValues",None];
 If[physical=!=None,
  If[!AssociationQ[physical],tangentialEndpointFail["PhysicalEndpointBoundaryRecordRequired"]];
  matching=Lookup[physical,"BoundaryBasisMatching",<||>];
  sourceBounds=Lookup[physical,"AmplitudeLaurentLowerBounds",{}];
  If[Lookup[matching,"DataType",None]=!="TangentialEndpointBoundaryBasisMatching" ||
    Lookup[matching,"TangentialBasePoint",None]=!=base ||
    !tangentialEndpointZeroQ[Lookup[matching,"NormalGaugeAtBasePoint",{}]-
       (endpoint["NormalGaugeMatrix"]/.v->base)] ||
    !tangentialEndpointZeroQ[Lookup[matching,"NormalResidueAtBasePoint",{}]-
       (endpoint["NormalResidue"]/.v->base)] ||
    Length[sourceBounds]=!=Lookup[matching,"SourceAmplitudeCount",None] ||
    !VectorQ[sourceBounds,IntegerQ[#]||#===Infinity&],
   tangentialEndpointFail["MatchingPhysicalEndpointBoundaryBasisRequired"]];
  mapVal=Map[solutionValuation[#,e]&,matching["AmplitudeToInitialVectorMatrix"],{2}];
  bounds=Table[Min[MapThread[If[#1===Infinity||#2===Infinity,Infinity,#1+#2]&,
     {mapVal[[i]],sourceBounds}]],{i,n}],
  bounds=Lookup[request,"InitialConstantLaurentLowerBounds",{}]];
 If[Length[bounds]=!=n || !VectorQ[bounds,IntegerQ[#]||#===Infinity&] ||
   AllTrue[bounds,#===Infinity&],
  tangentialEndpointFail["NonzeroTangentialInitialVectorLaurentBoundsRequired"]];
 sectors=endpoint["PrimarySectors"];
 globalEntryLow=Min[solutionValuation[#,e]&/@Flatten[Lookup[sectors,"OriginalCoefficients"]]];
 If[globalEntryLow===Infinity,tangentialEndpointFail["EndpointExpansionContainsNoCoefficient"]];
 (* The initial-vector lower bounds hold at v0. Negative epsilon powers
    in the tangential connection can lower them away from v0; follow every
    connection dependency before bounding the coefficient convolution. *)
 connectionValuations=Map[solutionValuation[#,e]&,
   endpoint["TangentialConnectionMatrix"],{2}];
 functionBounds=bounds;
 Do[
  nextBounds=Table[Min[Prepend[Table[
    If[connectionValuations[[i,j]]===Infinity || functionBounds[[j]]===Infinity,
      Infinity,connectionValuations[[i,j]]+functionBounds[[j]]],{j,n}],
    functionBounds[[i]]]],{i,n}];
  changed=nextBounds=!=functionBounds;functionBounds=nextBounds;
  If[!changed,Break[]],{n}];
 If[TrueQ[changed],tangentialEndpointFail["TangentialLaurentLowerBoundsRequireFurtherReduction"]];
 upper=hi-globalEntryLow;lower=Min[functionBounds];
 If[upper<lower,tangentialEndpointFail["EndpointRequestBelowDeclaredLaurentBounds"]];
 neededRange=Range[lower,upper];
 system=<|"KinematicVariables"->{v},"DimensionalRegulator"->e,
   "ConnectionMatrices"->{endpoint["TangentialConnectionMatrix"]}|>;
 solverRequest=<|"BasePoint"->{base},"RequestedRows"->Range[n],
   "RequestedMasterIntegralEpsilonOrders"->neededRange,
   "InitialConstantLaurentLowerBounds"->bounds,
   "AnalyticDomain"->endpoint["AnalyticDomain"],
   "BranchPrescription"->endpoint["BranchPrescription"]|>;
 solution=FeynFacet`ConstructMasterIntegralSolution[system,solverRequest,
   "FlatnessCheck"->"Exact","Verbose"->OptionValue["Verbose"],
   "HomogeneousSolveTimeLimit"->OptionValue["HomogeneousSolveTimeLimit"]];
 If[FailureQ[solution],tangentialEndpointFail["FiniteTangentialSolutionConstructionFailed",<|"Cause"->solution|>]];
 cseries=Association@Table[k->Table[i/.solution["MasterIntegralCoefficients"][k],{i,n}],
   {k,neededRange}];
 Do[
  normalRange=sector["OriginalNormalOrderRange"];matrices=sector["OriginalCoefficients"];
  Do[
   coefficients=Association@Table[
    q->Table[Total[Flatten[Table[
       coefficient=matrices[[k-First[normalRange]+1,l+1,row,j]];
       If[coefficient===0,{},
        entryLow=solutionValuation[coefficient,e];
        Table[With[{a=Cancel[Together[SeriesCoefficient[coefficient,{e,0,q-m}]]]},
          If[a===0,0,a cseries[m][[j]]]],{m,lower,Min[upper,q-entryLow]}]],
       {j,n}]]],{row,n}],
    {q,lo,hi}];
   termValuations=Map[solutionValuation[#,e]&,
     matrices[[k-First[normalRange]+1,l+1]],{2}];
   termBounds=Table[Min[MapThread[If[#1===Infinity||#2===Infinity,Infinity,#1+#2]&,
     {termValuations[[row]],functionBounds}]],{row,n}];
   AppendTo[terms,<|"NormalPower"->k,"RegulatorExponent"->Cancel[sector["Exponent"]/e],
      "LogarithmPower"->l,"CoefficientEpsilonOrderRange"->range,
      "CoefficientLaurentLowerBounds"->termBounds,
      "Coefficients"->coefficients|>],
   {k,First[normalRange],Last[normalRange]},{l,0,sector["NilpotencyIndex"]-1}],
 {sector,sectors}];
 pairs=Sort[DeleteDuplicates[Cases[terms,FeynFacetSolution`C[i_Integer,k_Integer]:>{i,k},Infinity]]];
 If[physical=!=None,
  constantData=tangentialEndpointPhysicalConstants[matching,
    Lookup[physical,"AmplitudeCoefficients",<||>],sourceBounds,pairs,e];
  terms=terms/.constantData["InitialConstantRules"];
  If[!FreeQ[terms,FeynFacetSolution`C[__]],
   tangentialEndpointFail["PhysicalEndpointConstantsRemain"]]];
 <|"DataType"->"FiniteTangentialEndpointSolution","SchemaVersion"->1,
  "Status"->"FiniteTangentialEndpointFunctionsConstructed",
  "NormalVariable"->z,"TangentialVariable"->v,"DimensionalRegulator"->e,
  "TangentialBasePoint"->base,"Dimension"->n,"EndpointTerms"->terms,
  "EpsilonOrderRange"->range,"OriginalNormalOrderRange"->endpoint["OriginalNormalOrderRange"],
  "TangentialSolution"->solution,
  "TangentialSolutionRole"->"Construction of normalized-vector functions up to constants; any physical substitutions are materialized in EndpointTerms.",
  "KernelDefinitions"->solution["KernelDefinitions"],
  "IntegralDefinitions"->solution["IntegralDefinitions"],
  "AlgebraicDefinitions"->solution["AlgebraicDefinitions"],
  "InitialConstantLaurentLowerBounds"->bounds,
  "TangentialFunctionLaurentLowerBounds"->functionBounds,
  "RequiredInitialConstantCoefficients"->If[physical===None,pairs,{}],
  "PhysicalBoundaryValuesApplied"->(physical=!=None),
  "PhysicalBoundaryApplication"->constantData,
  "BoundaryBasisMatching"->matching,
  "AnalyticDomain"->endpoint["AnalyticDomain"],"BranchPrescription"->endpoint["BranchPrescription"],
  "CoefficientConvention"->"Each term is z^(NormalPower+epsilon RegulatorExponent) Log[z]^LogarithmPower times the vector Sum[epsilon^q Coefficients[q]]. Normal regulator powers are unexpanded.",
  "Scope"->"Finite endpoint expansion on the declared smooth boundary domain; higher normal orders and intersections are not represented."|>
],"TangentialEndpoint"];

FeynFacet`ConstructTangentialEndpointSystem[___] :=
 Failure["TangentialEndpointSystemAndRequestRequired",<||>];
FeynFacet`MatchTangentialEndpointBoundaryBasis[___] :=
 Failure["EndpointAndPhysicalNormalLineReferenceRequired",<||>];
FeynFacet`ConstructTangentialEndpointSolution[___] :=
 Failure["EndpointAndFiniteTangentialRequestRequired",<||>];
FeynFacet`DetermineTangentialEndpointLaurentBounds[___] :=
 Failure["EndpointMatchingAndPhysicalSeedBoundsRequired",<||>];

End[];
