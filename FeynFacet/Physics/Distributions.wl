(* Twist-2 collinear distribution and fragmentation correlators. *)

\[CapitalPhi]::usage =
  "\[CapitalPhi][x,P,lambda,ST,n] is the incoming quark correlator.";

\[CapitalDelta]::usage =
  "\[CapitalDelta][z,P,lambda,ST,n] is the outgoing quark correlator.";

\[CapitalPhi]b::usage =
  "\[CapitalPhi]b[x,P,lambda,ST,n] is the incoming antiquark correlator.";

\[CapitalDelta]b::usage =
  "\[CapitalDelta]b[z,P,lambda,ST,n] is the outgoing antiquark correlator.";

f1::usage = "f1[x] is the unpolarized collinear parton distribution.";
g1L::usage = "g1L[x] is the longitudinal-helicity parton distribution.";
h1::usage = "h1[x] is the transversity parton distribution.";
D1::usage = "D1[z] is the unpolarized collinear fragmentation function.";
G1L::usage = "G1L[z] is the longitudinal-helicity fragmentation function.";
H1::usage = "H1[z] is the transversity fragmentation function.";

f1g::usage = "f1g[x] is the unpolarized gluon parton distribution.";
g1g::usage = "g1g[x] is the gluon helicity distribution.";
D1g::usage = "D1g[z] is the unpolarized gluon fragmentation function.";
G1g::usage = "G1g[z] is the gluon helicity fragmentation function.";

SyntaxInformation[\[CapitalPhi]] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalDelta]] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalPhi]b] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalDelta]b] = {"ArgumentsPattern" -> {_, _, _, _, _}};

PartonicSpinDensity::usage = "PartonicSpinDensity[leg] constructs the normalized hard-side spin insertion and incoming color average for a PDF or unpolarized FF leg. Role, Species, Polarization, Momentum and MomentumSpace are explicit. Integrated tagged momenta retain their D-dimensional cut spin sum.";

Begin["`Private`"];

ClearAll[iSigmaSlash];
ClearAll[twist2Correlator, twist2GluonCorrelator];
Clear[\[CapitalPhi], \[CapitalDelta], \[CapitalPhi]b, \[CapitalDelta]b];

(* The twist-2 quark and gluon distribution heads this front end declares.
   This is the default of the coefficient layer, not its definition: a card whose channel carries other correlators lists
   their heads under the "DistributionHeads" key of its Setup and
   BuildSimplificationContext carries them from there (generality pass
   2026-08-23). *)
$twist2DistributionHeads = {f1, g1L, h1, D1, G1L, H1, f1g, g1g, D1g, G1g};

iSigmaSlash[a_, b_] := I (I/2) (
  FeynCalc`GS[a] . FeynCalc`GS[b] -
  FeynCalc`GS[b] . FeynCalc`GS[a]
);

twist2Correlator[
    variable_, lambda_, ST_, n_,
    {unpolarized_, longitudinal_, transverse_},
    helicitySign : (1 | -1)
  ] := (
  FeynFacet`DeclareScalar[{
    variable, lambda, unpolarized, longitudinal, transverse
  }];
  1/2 (
    unpolarized[variable] FeynCalc`GS[n] +
    helicitySign lambda longitudinal[variable]
      FeynCalc`GA[5] . FeynCalc`GS[n] +
    transverse[variable] iSigmaSlash[n, ST] . FeynCalc`GA[5]
  )
);

\[CapitalPhi][x_, P_, lambda_, ST_, n_] :=
  twist2Correlator[x, lambda, ST, n, {f1, g1L, h1}, 1];

\[CapitalDelta][z_, P_, lambda_, ST_, n_] :=
  twist2Correlator[z, lambda, ST, n, {D1, G1L, H1}, 1];

\[CapitalPhi]b[x_, P_, lambda_, ST_, n_] :=
  twist2Correlator[x, lambda, ST, n, {f1, g1L, h1}, -1];

\[CapitalDelta]b[z_, P_, lambda_, ST_, n_] :=
  twist2Correlator[z, lambda, ST, n, {D1, G1L, H1}, -1];

(* The incoming gluon density is the physical transverse polarization
   projector times f_g/x, averaged over D-2 states. Helicity uses the
   four-dimensional antisymmetric tensor in the BMHV prescription. The
   two tensor indices follow epsilon(+I) epsilon(-I), as in FCFAConvert.
   With epsilon_+=(0,-1,-I,0)/Sqrt[2] along +z, the helicity
   density has xy component -I/2, fixing the antisymmetric sign.
   These tensors are inserted before the interference tensor algebra. *)
twist2GluonCorrelator[
    variable_, k_, lambda_, reference_, mu_, nu_,
    side : ("Incoming" | "Outgoing")
  ] := Module[{unpolarized, helicity, norm},
  {unpolarized, helicity, norm} = If[side === "Incoming",
    {f1g[variable], lambda g1g[variable], 1/variable},
    {D1g[variable], lambda G1g[variable], 1/variable^2}
  ];
  norm (unpolarized If[side==="Incoming",1/(D-2),1]
    FeynFacet`GluonPolarizationProjector[k,reference,{mu,nu}]
    -I helicity If[side==="Incoming",1/2,-1]
      FeynCalc`LC[mu,nu][k,reference]/FeynCalc`SP[k,reference])
];


(* Hard-side embeddings are dual to scalar PDF/FF operator extraction.
   They contain no momentum-fraction measure and no observed-spectrum flux. *)
PartonicSpinDensity[leg_Association] := Catch[Module[
 {role,species,polarization,k,space,reference,indices,mu,nu,spin,color,nc,sign},
 {role,species,polarization,k,space}=Lookup[leg,
  {"Role","Species","Polarization","Momentum","MomentumSpace"},Missing[]];
 If[!MemberQ[{"PDF","FF"},role]||!MemberQ[{"Physical4","IntegratedD"},space]||
  !MatchQ[k,_Symbol]||!MemberQ[{"U","L"},polarization]||
  !(species==="g"||MatchQ[species,{"q"|"qbar",_String|_Integer}]),
  Throw[Failure["PartonicSpinDensityRequestRequired",<||>],"PartonicSpinDensity"]];
 If[role==="PDF"&&space=!="Physical4",
  Throw[Failure["PhysicalIncomingCollinearMomentumRequired",<||>],"PartonicSpinDensity"]];
 If[role==="FF"&&polarization=!="U",
  Throw[Failure["UnpolarizedIntegratedFragmentationRequired",<||>],"PartonicSpinDensity"]];
 nc=Lookup[leg,"NumberOfColors",FeynCalc`CA];
 color=If[role==="PDF",If[species==="g",1/(nc^2-1),1/nc],1];
 If[species==="g",
  reference=Lookup[leg,"ReferenceMomentum",Missing[]];indices=Lookup[leg,"Indices",Missing[]];
  If[!MatchQ[reference,_Symbol]||!MatchQ[indices,{_Symbol,_Symbol}]||!DuplicateFreeQ[indices],
   Throw[Failure["GluonReferenceAndIndicesRequired",<||>],"PartonicSpinDensity"]];
  {mu,nu}=indices;
  spin=If[polarization==="U",
   If[role==="PDF",1/(D-2),1]FeynFacet`GluonPolarizationProjector[k,reference,{mu,nu}],
   -I/2 FeynCalc`LC[mu,nu][k,reference]/FeynCalc`SP[k,reference]],
  spin=If[space==="IntegratedD",FeynCalc`GSD[k],FeynCalc`GS[k]];
  If[role==="PDF",spin=If[polarization==="U",spin/2,
   sign=If[First[species]==="q",1,-1];sign FeynCalc`GA[5].spin/2]]
 ];
 <|"SpinDensity"->spin,"ColorAverage"->color,"Role"->role,"Species"->species,
  "Polarization"->polarization,"Momentum"->k,"MomentumSpace"->space,
  "IncomingSpinAverageIncluded"->(role==="PDF"),
  "PolarizationIndexOrder"->"AmplitudeThenConjugate",
  "DiracScheme"->"BMHV","SpinContinuation"->If[species==="g"&&polarization==="U",
   "D-dimensional transverse states","Physical helicity for incoming polarization; declared momentum dimension for unpolarized cuts"]|>
],"PartonicSpinDensity"];

End[];
