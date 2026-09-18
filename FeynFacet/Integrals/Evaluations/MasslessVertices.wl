(* Universal scalar masters for two null external legs and one spacelike scale.
   Gehrmann, Huber and Maitre, hep-ph/0507061v3, section 2, equations (2)-(6).
   No amplitude or form-factor coefficients from section 3 are used.
   Labels A2, A3, A4, A6 follow that source; values here use normalized loop
   measures d^D k/(i pi^(D/2)), so each two-loop source integral changes sign. *)
BeginPackage["FeynFacet`"];
MasslessVertexMasterDefinition::usage="MasslessVertexMasterDefinition[name,{k,l},{p1,p2},Q2,epsilon] gives exact denominator and scalar-value definitions for massless two-loop three-point masters with p1^2=p2^2=0 and (p1+p2)^2=-Q2. Names A2, A2Squared, A3, A4, A6 refer to hep-ph/0507061 scalar integrals. Loop measures are d^D k/(i pi^(D/2)).";
EvaluateMasslessVertexMaster::usage="EvaluateMasslessVertexMaster[name,Q2,epsilon,{low,high}] returns explicit scalar Laurent coefficients. Gamma-function masters have arbitrary orders; the crossed A6 master uses the exact published expansion through epsilon^3 and rejects deeper requests. Its exact all-order hypergeometric definition is also returned by MasslessVertexMasterDefinition.";
MasslessVertexMasterLibrary::usage="MasslessVertexMasterLibrary[{k,l},{p1,p2},external,kinematicRules,Q2,epsilon] creates a scalar master catalog in the caller's momentum frame, including the interchange of the two null legs of A4. The two A4 entries have the same invariant scalar value.";
Begin["`Private`"];
masslessVertexFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"MasslessVertex"];
masslessVertexGamma[scale_,e_]:=scale^-e Gamma[1+e]Gamma[1-e]^2/(e Gamma[2-2e]);
masslessVertexCrossedBracket[e_]:=
 -Gamma[1-e]^3 Gamma[1+e]Gamma[1-2e]^4 Gamma[1+2e]^3/
  (e^4 Gamma[1-4e]^2 Gamma[1+4e])+
 Gamma[1-e]^4 Gamma[1+e]Gamma[1-2e]Gamma[1+2e]/
  (2e^4 Gamma[1-3e])HypergeometricPFQ[{1,-4e,-2e},{1-3e,1-2e},1]-
 4Gamma[1-e]^4 Gamma[1-2e]Gamma[1+2e]/
  (e^2(1+e)(1+2e)Gamma[1-4e])HypergeometricPFQ[{1,1,1+2e},{2+e,2+2e},1]-
 Gamma[1-e]^5 Gamma[1+2e]/(2e^4 Gamma[1-3e])*
  HypergeometricPFQ[{1,1-e,-4e,-2e},{1-3e,1-2e,1-2e},1];
masslessVertexExact[name_,scale_,e_]:=Switch[name,
 "A2",masslessVertexGamma[scale,e],
 "A2Squared",masslessVertexGamma[scale,e]^2,
 "A2ConjugateProduct",-masslessVertexGamma[scale,e]^2,
 "A3",scale^(1-2e)Gamma[1+2e]Gamma[1-e]^3/(2e(1-2e)Gamma[3-3e]),
 "A4",scale^(-2e)Gamma[1-2e]Gamma[1+e]Gamma[1-e]^2 Gamma[1+2e]/
  (2e^2(1-2e)Gamma[2-3e]),
 "A6",-scale^(-2-2e)masslessVertexCrossedBracket[e]/Gamma[1-e]^2,
 _,masslessVertexFail["MasslessVertexMasterNameRequired"]];
MasslessVertexMasterDefinition[name_String,{k_Symbol,l_Symbol},{p1_,p2_},scale_,e_Symbol]:=
 Catch[Module[{q=p1+p2,momenta,loops,value},
 value=masslessVertexExact[name,scale,e];
 momenta=Switch[name,"A2",{k,k-q},"A2Squared"|"A2ConjugateProduct",{k,k-q,l,l-q},
  "A3",{k,l,k-l-q},"A4",{k,l,k-q,k-l-p1},
  "A6",{k,l,k-q,k-l,k-l-p2,l-p1}];
 loops=If[name==="A2",{k},{k,l}];
 <|"Name"->name,"LoopMomenta"->loops,"PropagatorMomenta"->momenta,
  "Powers"->ConstantArray[1,Length[momenta]],
  "CausalPrescription"->If[name==="A2ConjugateProduct",{1,1,-1,-1},1],
  "LaurentLowerBound"->Switch[name,"A2",-1,"A2Squared"|"A2ConjugateProduct",-2,"A3",-1,"A4",-2,"A6",-4],
  "ExternalNullMomenta"->{p1,p2},"ScaleSquared"->scale,"ExternalInvariant"->-scale,
  "ExactValue"->value,"DimensionalRegulator"->e,"Normalization"->"Product d^D k/(i pi^(D/2))",
  "Source"->"https://arxiv.org/pdf/hep-ph/0507061","SourceEquations"->"(2)-(6), scalar masters only"|>
],"MasslessVertex"];
EvaluateMasslessVertexMaster[name_String,scale_,e_Symbol,range:{_Integer,_Integer}]:=
 If[FeynFacet`$MasterIntegralLibraryMode==="Disabled",
  evaluateMasslessVertex[name,scale,e,range],
  Module[{record,definition,k=FeynFacetLibrary`loop1,l=FeynFacetLibrary`loop2,
   p=FeynFacetLibrary`external1,q=FeynFacetLibrary`external2,eta,pres},
   record=MasslessVertexMasterDefinition[name,{k,l},{p,q},scale,e];
   If[!AssociationQ[record],Return[record]];
   eta=If[ListQ[record["CausalPrescription"]],record["CausalPrescription"],
    ConstantArray[record["CausalPrescription"],Length[record["Powers"]]]];
   pres=If[name==="A2ConjugateProduct",{1,-1},ConstantArray[1,Length[record["LoopMomenta"]]]];
   definition=masterLibraryProviderDefinition[record["PropagatorMomenta"],record["LoopMomenta"],{p,q},
    {FeynCalc`SPD[p]->0,FeynCalc`SPD[q]->0,FeynCalc`SPD[p,q]->-scale/2},
    e,pres,eta,scale>0,(I Pi^(2-e))^-Length[pres]];
   masterLibraryEvaluateVector[definition,range,
    Function[{},evaluateMasslessVertex[name,scale,e,{Min[First[range],record["LaurentLowerBound"]],Last[range]}]],
    <|"Name"->name,"ScaleSquared"->scale,"CausalPrescription"->record["CausalPrescription"],
     "Normalization"->record["Normalization"],"MasterSource"->"hep-ph/0507061 section 2",
     "EvaluationMethod"->"MasslessVertexScalarProvider","FormFactorCoefficientsUsed"->False|>]
  ]];
evaluateMasslessVertex[name_String,scale_,e_Symbol,range:{_Integer,_Integer}]:=
 Catch[Module[{value,poly,record,through=Last[range]},
 If[First[range]>through||!FreeQ[scale,e|_Real],masslessVertexFail["ExactVertexScaleAndFiniteOrdersRequired"]];
 value=masslessVertexExact[name,scale,e];
 If[name==="A6",
  If[through>3,masslessVertexFail["CrossedVertexHigherOrderExpansionRequired",<|"Requested"->through,"KnownThroughOrder"->3|>]];
  poly=e^-4-5Pi^2/(6e^2)-27Zeta[3]/e-23Pi^4/36+
   (8Pi^2 Zeta[3]-117Zeta[5])e+
   (267Zeta[3]^2-19Pi^6/315)e^2+
   (109Pi^4 Zeta[3]/10+40Pi^2 Zeta[5]+6Zeta[7])e^3;
  value=scale^(-2-2e)poly/Gamma[1-e]^2];
 record=FeynFacet`ExpandLaurentCoefficientVector[{value},e,{range}];
 If[!AssociationQ[record],Throw[record,"MasslessVertex"]];
 Join[record,If[name==="A6",<||>,<|"ExactValue"->value|>],
 <|"Name"->name,"ScaleSquared"->scale,"CausalPrescription"->If[name==="A2ConjugateProduct",{1,1,-1,-1},1],
  "Normalization"->"Product d^D k/(i pi^(D/2))",
  "MasterSource"->"hep-ph/0507061 section 2","FormFactorCoefficientsUsed"->False|>]
],"MasslessVertex"];

MasslessVertexMasterLibrary[{k_Symbol,l_Symbol},{p1_,p2_},external:{__Symbol},kin_List,scale_,e_Symbol]:=
 Module[{records,reflected,conjugated,conjugatedExchange},
 records=MasslessVertexMasterDefinition[#,{k,l},{p1,p2},scale,e]&/@{"A2Squared","A3","A4","A6"};
 reflected=Join[MasslessVertexMasterDefinition["A4",{k,l},{p2,p1},scale,e],
  <|"Name"->"A4NullLegExchange","ScalarMasterName"->"A4",
   "ExternalSymmetry"->"Interchange of two null legs; only their fixed total invariant enters the scalar value."|>];
 (* Each disconnected anti-Feynman bubble is the conjugate unnormalized
    integral. With an i*pi^(D/2) denominator for both loop measures,
    J_minus=-Conjugate[J_plus]. The spacelike Gamma value is real. *)
 conjugated=MasslessVertexMasterDefinition["A2ConjugateProduct",{k,l},{p1,p2},scale,e];
 conjugatedExchange=Join[conjugated,<|"Name"->"A2ConjugateProductLoopExchange",
  "ScalarMasterName"->"A2ConjugateProduct","CausalPrescription"->{-1,-1,1,1}|>];
 Map[Function[record,Join[record,<|
  "ScalarMasterName"->Lookup[record,"ScalarMasterName",record["Name"]],
  "Topology"->FeynCalc`FCTopology["MasslessVertex"<>record["Name"],
   MapThread[Function[{momentum,eta},FeynCalc`FeynAmpDenominator[
    FeynCalc`StandardPropagatorDenominator[FeynCalc`Momentum[momentum,D],0,0,{1,eta}]]],
    {record["PropagatorMomenta"],If[ListQ[record["CausalPrescription"]],record["CausalPrescription"],
      ConstantArray[record["CausalPrescription"],Length[record["PropagatorMomenta"]]]]}],{k,l},external,FeynCalc`FCI[kin],{}],
  "MeasurePrefactor"->1|>]],Join[records,{reflected,conjugated,conjugatedExchange}]]
];
End[];EndPackage[];
