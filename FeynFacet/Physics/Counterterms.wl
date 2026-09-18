(* Splitting and finite operator kernels for collinear factorization.
   Kernels use a_s=alpha_s/(2 Pi) and explicit daughter <- parent labels.
   Finite scheme kernels mean f_new=(1+a_s Z) convolution f_old. *)
BeginPackage["FeynFacet`"];
LeadingSplittingKernel::usage="LeadingSplittingKernel[daughter,parent,spin,xi,parameters] gives LO delta/plus/regular kernels for individual species {q,flavor}, {qb,flavor}, or g. Parameters declares CA, CF, TR, and FlavorCount. Spin is U, L, or T. Plus[k] means [Log[1-xi]^k/(1-xi)]_+.";
FactorizationSchemeKernel::usage="FactorizationSchemeKernel[name,daughter,parent,spin,xi,parameters,order] supplies the coefficient of (alpha_s/(2 Pi))^order in the finite PDF/FF redefinition Z. The default order is one; order zero is the identity. HelicityMSbar provides the full-flavor Larin-to-MSbar PDF coefficients through order two; using them requires a matching raw operator definition. MSbar has no finite corrections. Cards may supply FiniteKernelsByOrder or a channel kernel with an explicit PerturbativeOrder. An optional request association declares Evolution; unsupported timelike defaults are rejected after resolving every matrix fallback.";
Begin["`Private`"];
ClearAll[collinearKernelFail,collinearKernelSpeciesQ,collinearKernelRecord,
 collinearKernelValidate];
collinearKernelFail[tag_,details_:<||>]:=Throw[Failure[tag,details],"CollinearCounterterms"];
collinearKernelSpeciesQ[x_]:=x==="g"||MatchQ[x,{"q"|"qb",_Integer|_String}];
collinearKernelRecord[x_,delta_,plus_,regular_]:=<|"Variable"->x,
 "DeltaCoefficient"->delta,"PlusCoefficients"->plus,"RegularCoefficient"->regular|>;
collinearKernelValidate[k_]:=Module[{x,plus},
 If[!AssociationQ[k]||!ContainsAll[Keys[k],{"Variable","DeltaCoefficient","PlusCoefficients","RegularCoefficient"}],
  collinearKernelFail["SplittingKernelDecompositionRequired"]];
 x=k["Variable"];plus=k["PlusCoefficients"];
 If[!MatchQ[x,_Symbol]||!AssociationQ[plus]||!AllTrue[Keys[plus],IntegerQ[#]&&#>=0&]||
  !FreeQ[{k["DeltaCoefficient"],Values[plus]},x]||
  !FreeQ[KeyTake[k,{"Variable","DeltaCoefficient","PlusCoefficients","RegularCoefficient"}],
    _Real|_SeriesData|_Integrate|_Inactive|_Failure|_Missing|Indeterminate|_DirectedInfinity],
  collinearKernelFail["ExplicitCollinearKernelRequired"]];k
];
LeadingSplittingKernel[daughter_,parent_,spin_,xi_Symbol,parameters_Association]:=Catch[Module[
 {ca,cf,tr,nf,beta,delta=0,plus=<||>,regular=0,sameQuark},
 If[!collinearKernelSpeciesQ[daughter]||!collinearKernelSpeciesQ[parent]||!MemberQ[{"U","L","T"},spin],
  collinearKernelFail["PartonSpeciesAndSpinRequired"]];
 If[!ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}],collinearKernelFail["ColorAndFlavorParametersRequired"]];
 {ca,cf,tr,nf}=Lookup[parameters,{"CA","CF","TR","FlavorCount"}];beta=(11ca-4tr nf)/3;
 sameQuark=daughter===parent&&daughter=!="g";
 Which[
  sameQuark,delta=3cf/2;plus=<|0->2cf|>;regular=If[spin==="T",-2cf,-cf(1+xi)],
  spin==="T",Null,
  daughter==="g"&&parent==="g",delta=beta/2;plus=<|0->2ca|>;
   regular=2ca If[spin==="U",1/xi-2+xi(1-xi),1-2xi],
  daughter==="g",regular=cf If[spin==="U",(1+(1-xi)^2)/xi,2-xi],
  parent==="g",regular=tr If[spin==="U",xi^2+(1-xi)^2,2xi-1],
  True,Null];
 Join[collinearKernelRecord[xi,delta,plus,regular],<|"Daughter"->daughter,"Parent"->parent,
  "Spin"->spin,"PerturbativeParameter"->"alpha_s/(2 Pi)","KernelOrder"->0|>]
 ],"CollinearCounterterms"];

(* Coefficient of (alpha_s/(2 Pi))^order in f_new = Z convolution f_raw.
   The NNLO helicity entries are the conventional Larin -> MSbar finite PDF
   operator renormalization in the full flavor basis. Production may use them
   only with a matching raw operator contract; this provider does not assert
   equivalence of arbitrary gamma5 calculations.
   Bonino et al., arXiv:2510.00100v1, Appendix A (113)-(116);
   independent singlet/non-singlet checks: arXiv:1409.5131, Appendix A. *)
helicityFinitePDFCoefficient[daughter_,parent_,xi_,parameters_,order_]:=Module[
 {ca,cf,tr,nf,valence,antiquark,sea,sameFlavor},
 If[order===1,Return[If[daughter===parent&&parent=!="g",-4parameters["CF"](1-xi),0]]];
 If[order=!=2,collinearKernelFail["FiniteHelicityPDFOrderUnsupported",<|"Order"->order|>]];
 If[!ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}],
  collinearKernelFail["ColorAndFlavorParametersRequired"]];
 If[daughter==="g"||parent==="g",Return[0]];
 {ca,cf,tr,nf}=Lookup[parameters,{"CA","CF","TR","FlavorCount"}];
 sea=cf tr(2(1-xi)+(3-xi)Log[xi]+(2+xi)Log[xi]^2/2);
 sameFlavor=Last[daughter]===Last[parent];
 If[!sameFlavor,Return[sea]];
 If[First[daughter]===First[parent],
  valence=cf tr nf(1-xi)(20/9+4Log[xi]/3)-
   cf^2(4(1-xi)+(2(2+xi)-4(1-xi)Log[1-xi])Log[xi])-
   cf ca(148(1-xi)/9-Pi^2(1-xi)/3+2(10-xi)Log[xi]/3+(1-xi)Log[xi]^2);
  valence+sea,
  antiquark=-cf(cf-ca/2)(-14(1-xi)+2Pi^2(1+xi)/3-2(1+xi)Log[xi]^2-
   (1+xi)(6-8Log[1+xi])Log[xi]+8(1+xi)PolyLog[2,-xi]);
  antiquark+sea]
];
FactorizationSchemeKernel[name_,daughter_,parent_,spin_,xi_Symbol,parameters_Association]:=
 FactorizationSchemeKernel[name,daughter,parent,spin,xi,parameters,1];
FactorizationSchemeKernel[name_,daughter_,parent_,spin_,xi_Symbol,parameters_Association,
 order_Integer,request_Association:<||>]:=Catch[Module[{record,orders,channel},
 If[!MemberQ[{None,"SpaceLike","TimeLike"},Lookup[request,"Evolution",None]],
  collinearKernelFail["FiniteKernelEvolutionRequired"]];
 If[!collinearKernelSpeciesQ[daughter]||!collinearKernelSpeciesQ[parent]||
   !MemberQ[{"U","L","T"},spin]||order<0,
  collinearKernelFail["PartonSpeciesSpinAndNonnegativeSchemeOrderRequired"]];
 If[order===0,Return[collinearKernelRecord[xi,If[daughter===parent,1,0],<||>,0]]];
 If[AssociationQ[name]&&KeyExistsQ[name,"FiniteKernelsByOrder"],
  orders=name["FiniteKernelsByOrder"];
  If[!AssociationQ[orders]||!AllTrue[Keys[orders],IntegerQ[#]&&#>0&]||
    !AllTrue[Values[orders],AssociationQ],collinearKernelFail["FiniteSchemeKernelsIndexedByPositiveOrderRequired"]];
  channel=Map[If[AssociationQ[#]&&!KeyExistsQ[#,"PerturbativeOrder"],
    Append[#,"PerturbativeOrder"->order],#]&,Lookup[orders,order,<||>]];
  Return[FactorizationSchemeKernel[<|"FiniteKernels"->channel,
   "DefaultScheme"->Lookup[name,"DefaultScheme","MSbar"]|>,daughter,parent,spin,xi,parameters,order,request]]];
 If[AssociationQ[name]&&KeyExistsQ[name,"FiniteKernels"],
  If[!AssociationQ[name["FiniteKernels"]],collinearKernelFail["FiniteSchemeKernelMatrixRequired"]];
  record=Lookup[name["FiniteKernels"],Key[{daughter,parent,spin}],Missing["NoFiniteKernelOverride"]];
  If[MissingQ[record],Return[FactorizationSchemeKernel[Lookup[name,"DefaultScheme","MSbar"],
    daughter,parent,spin,xi,parameters,order,request]]];
  Return[FactorizationSchemeKernel[record,daughter,parent,spin,xi,parameters,order,request]]];
 If[AssociationQ[name],record=collinearKernelValidate[name];
  If[record["Variable"]=!=xi,collinearKernelFail["KernelVariableMismatch"]];
  If[Lookup[record,"PerturbativeOrder",1]=!=order,
   collinearKernelFail["ExplicitFiniteSchemeOrderMismatch",<|"RequestedOrder"->order|>]];
  Return[record]];
 If[!MemberQ[{"MSbar","HelicityMSbar"},name],
  collinearKernelFail["FactorizationSchemeUnsupported",<|"Scheme"->name|>]];
 If[order===2&&spin==="L"&&name==="HelicityMSbar"&&Lookup[request,"Evolution",None]==="TimeLike",
  collinearKernelFail["ExplicitTimelikeFiniteHelicityKernelRequired"]];
 If[name==="HelicityMSbar"&&spin==="L"&&!KeyExistsQ[parameters,"CF"],
  collinearKernelFail["ColorAndFlavorParametersRequired"]];
 collinearKernelRecord[xi,0,<||>,If[name==="HelicityMSbar"&&spin==="L",
  helicityFinitePDFCoefficient[daughter,parent,xi,parameters,order],0]]
],"CollinearCounterterms"];

FeynFacet`EnumerateNLOCollinearChannels::usage="EnumerateNLOCollinearChannels[channel,request] enumerates the Born channels required by nonzero LO splitting and finite scheme kernels for two incoming partons and one observed parton. Request supplies Species, Polarization, Schemes, SplittingVariable and KernelParameters. The unobserved recoil is summed over the declared species and exact quark-flavor conservation is imposed. Diagram generation must still confirm each allowed Born channel.";
FeynFacet`EnumerateNLOCollinearChannels[channel_Association,request_Association]:=Catch[Module[
 {species,spins,schemes,xi,parameters,incoming,observed,flavors,charge,rows={},leg,original,spin,candidate,
  daughter,parent,pole,finite,bornIncoming,bornObserved,scheme,recoil,conserved,nonzero,freeFlavor,probe},
 If[!ContainsAll[Keys[channel],{"Incoming","Observed"}]||
  !ContainsAll[Keys[request],{"Species","Polarization","Schemes","SplittingVariable","KernelParameters"}],collinearKernelFail["CollinearChannelEnumerationRequestRequired"]];
 {species,spins,schemes,xi,parameters}=Lookup[request,{"Species","Polarization","Schemes","SplittingVariable","KernelParameters"}];
 incoming=channel["Incoming"];observed=channel["Observed"];
 If[!ListQ[species]||!DuplicateFreeQ[species]||!AllTrue[species,collinearKernelSpeciesQ]||
  !MatchQ[incoming,{_,_}]||!AssociationQ[spins]||!MatchQ[Lookup[spins,"Incoming",None],{"U"|"L"|"T","U"|"L"|"T"}]||!MemberQ[{"U","L","T"},Lookup[spins,"Observed",None]]||
  !AllTrue[Join[incoming,{observed}],MemberQ[species,#]&],collinearKernelFail["CompleteDeclaredPartonSpeciesRequired"]];
 If[Lookup[request,"FlavorSummation",None]==="MasslessQCD",
  qcdRequireConjugateSpecies[species];
  If[!AllTrue[Values[schemes],MemberQ[{"MSbar","HelicityMSbar"},#]&],
   collinearKernelFail["FlavorSymmetricFiniteSchemesRequired"]];
  If[Complement[qcdFlavorLabels[species],qcdFixedFlavors[channel]]==={}&&
   !TrueQ[parameters["FlavorCount"]-Length[qcdFixedFlavors[channel]]===0],
   freeFlavor=ToString[Unique["flavor"],InputForm];
   probe=FeynFacet`EnumerateNLOCollinearChannels[channel,Join[request,<|
    "Species"->Join[species,{{"q",freeFlavor},{"qb",freeFlavor}}],
    "FlavorSummation"->None|>]];
   If[!AssociationQ[probe],collinearKernelFail["FlavorCompletenessEnumerationFailed"]];
   If[!FreeQ[probe["Channels"],freeFlavor],
    collinearKernelFail["AdditionalUnobservedFlavorRepresentativeRequired"]]]];
 flavors=DeleteDuplicates[Last /@ Select[species,#=!="g"&]];
 charge[parton_]:=If[parton==="g",ConstantArray[0,Length[flavors]],
   If[First[parton]==="q",1,-1](Boole[#===Last[parton]]& /@ flavors)];
 nonzero[k_]:=!TrueQ[k["DeltaCoefficient"]===0&&AllTrue[Values[k["PlusCoefficients"]],#===0&]&&k["RegularCoefficient"]===0];
 Do[
  original=Switch[leg,"IncomingA",incoming[[1]],"IncomingB",incoming[[2]],"Observed",observed];
  spin=Switch[leg,"IncomingA",spins["Incoming"][[1]],"IncomingB",spins["Incoming"][[2]],"Observed",spins["Observed"]];
  scheme=Lookup[schemes,leg,Missing["FactorizationSchemeRequired"]];If[MissingQ[scheme],collinearKernelFail["FactorizationSchemeForEveryLegRequired"]];
  If[AssociationQ[scheme]&&!KeyExistsQ[scheme,"FiniteKernels"],collinearKernelFail["ChannelEnumerationNeedsFiniteKernelMatrix"]];
  Do[
   {daughter,parent}=If[leg==="Observed",{original,candidate},{candidate,original}];
   pole=LeadingSplittingKernel[daughter,parent,spin,xi,parameters];
   finite=FactorizationSchemeKernel[scheme,daughter,parent,spin,xi,parameters];
   If[FailureQ[pole]||FailureQ[finite],collinearKernelFail["CollinearEnumerationKernelFailed"]];
   If[!nonzero[pole]&&!nonzero[finite],Continue[]];
   bornIncoming=Switch[leg,"IncomingA",ReplacePart[incoming,1->candidate],"IncomingB",ReplacePart[incoming,2->candidate],"Observed",incoming];
   bornObserved=If[leg==="Observed",candidate,observed];
   Do[
    conserved=Total[charge /@ bornIncoming]===charge[bornObserved]+charge[recoil];
    If[conserved,AppendTo[rows,<|"Leg"->leg,"Daughter"->daughter,"Parent"->parent,"Spin"->spin,"Scheme"->scheme,
     "BornChannel"-><|"Incoming"->bornIncoming,"Observed"->bornObserved,"Recoil"->recoil|>,
     "SplittingKernel"->pole,"FiniteKernel"->finite|>]],{recoil,species}],{candidate,species}],
  {leg,{"IncomingA","IncomingB","Observed"}}];
 If[Lookup[request,"FlavorSummation",None]==="MasslessQCD",
  rows=qcdFlavorSummedRows[rows,channel,parameters["FlavorCount"],"BornChannel"]];
 <|"Channels"->rows,"Species"->species,"Channel"->channel,"Polarization"->spins,
  "Coverage"->"All nonzero kernels within the declared flavor basis, with quark-flavor conservation; confirm the remaining Born channels by diagram generation"|>
 ],"CollinearCounterterms"];

End[];EndPackage[];
