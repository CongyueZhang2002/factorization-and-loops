(* Ordinary i0 limits on compact massless phase space. Cut orientations and
   delta derivatives are separate data and are never removed by this module. *)
BeginPackage["FeynFacet`"];
CertifyOrdinaryPrescriptionRemoval::usage="CertifyOrdinaryPrescriptionRemoval[source,master,request] uses the shared compact-cut convergence proof for positive integer cut powers and finite ordinary integer powers. It returns the generic-kinematic certificate or explicit unresolved conditions; JointExternalDomain requests the same proof on compact external intervals, with a uniform timelike reference, unit cuts and checked spatial coefficient divisors. Endpoint coefficients and their orders remain separate.";
RequireOrdinaryPrescriptionCertificate::usage="RequireOrdinaryPrescriptionCertificate[definition,scope] requires an ordinary-prescription proof at GenericKinematics or EndpointDistributions scope; a bulk proof cannot authorize endpoint contact terms.";
Begin["`Private`"];
ordinaryPrescriptionUnresolved[reason_,data_:<||>]:=Join[<|"Status"->"NotCertified",
 "Reason"->reason,"OrdinaryPrescriptionRemoved"->False,
 "EndpointDistributionStatus"->"NotCertified","CutPrescriptionsRemoved"->False|>,data];
ordinaryPrescriptionCertificate[definition_] := Module[{result,ordinary},
 ordinary=Select[Complement[Range[Length[definition["PropagatorPowers"]]],
   definition["CutIndices"]],definition["PropagatorPowers"][[#]]>0&];
 If[ordinary==={},Return[<|"Status"->"NoOrdinaryDenominators",
   "OrdinaryPrescriptionRemoved"->False,"CutPrescriptionsRemoved"->False,
   "EndpointDistributionStatus"->"NoOrdinaryPrescriptionLimitRequired"|>]];
 result=Catch[cutIntegralConvergenceCertificate[definition],"EpsilonOrders"];
 If[FailureQ[result],ordinaryPrescriptionUnresolved[result[[1]],result[[2]]],result]
];
(* The production real-radiation reduction is an identity between generic
   meromorphic integrals. Establish the whole-term limit before its algebraic
   partial fractions; keep the original prescribed product for endpoint work. *)
preIBPOrdinaryPrescription[config_,factorized_]:=Module[
 {loops=factorized["LoopMomenta"],cuts,ordinary,objects,units,powers,ext,kin,source,master,definition,certificate,algebraic,numerator,products,remaining},
 If[setupVirtualLoopMomenta[config]=!={},Return[<|"Propagators"->factorized["Propagators"]|>]];
 If[!FreeQ[factorized["Propagators"],Power[_Cut,power_/;power=!=1]],
   Return[<|"Propagators"->factorized["Propagators"]|>]];
 numerator=FeynCalc`FCI[factorized["Integrand"]];
 products=DeleteDuplicates[Cases[numerator,p_FeynCalc`Pair /;
   !FreeQ[p,Alternatives@@loops]:>p,{0,Infinity}],SameQ];
 remaining=numerator/.Thread[products->Table[Unique["loopScalarProduct"],{Length[products]}]];
 If[!PolynomialQ[numerator,products]||!FreeQ[remaining,Alternatives@@loops],
   Return[<|"Propagators"->factorized["Propagators"],
     "Certificate"->ordinaryPrescriptionUnresolved["PolynomialLoopNumeratorRequired"]|>]];
 cuts=cutData[factorized["Propagators"]];
 If[!ListQ[cuts]||Length[cuts]=!=Length[loops]+1,Return[<|"Propagators"->factorized["Propagators"]|>]];
 objects=propagatorFactors[factorized["Propagators"]];
 ordinary=propagatorDescriptor /@ objects;
 If[MemberQ[ordinary,$Failed],Return[<|"Propagators"->factorized["Propagators"]|>]];
 units=FeynCalc`ToSFAD /@ objects;
 units=units/.FeynCalc`StandardPropagatorDenominator[q_,sp_,mass_,{_,eta_}]:>
   FeynCalc`StandardPropagatorDenominator[q,sp,mass,{1,eta}];
 powers=If[ordinary==={},{},Lookup[ordinary,"Power"]];
 ext=Join[First[config["PartonMomentum"]],Complement[Last[config["PartonMomentum"]],config["PhaseSpaceMomentum"]]];
 kin=Flatten[Table[FeynCalc`FCI[FeynCalc`SPD[ext[[i]],ext[[j]]]]->
   SimplifyAssum[FeynCalc`SPD[ext[[i]],ext[[j]]],config],{i,Length[ext]},{j,i,Length[ext]}]];
 source=<|"Topology"->FeynCalc`FCTopology[preIBPIntegral,
   Join[FeynCalc`SFAD[#[[1]]]& /@ cuts,units],loops,ext,kin,{}],
   "CutIndices"->Range[Length[cuts]],"CutMomenta"->First /@ cuts,"CutDirections"->Last /@ cuts,
   "Prescription"->ConstantArray[0,Length[loops]],"Setup"->config,
   "KinematicConditions"->cardAssumptions[config,cardHadronicVariables[config]]|>;
 master=FeynCalc`GLI[preIBPIntegral,Join[ConstantArray[1,Length[cuts]],powers]];
 definition=Catch[Block[{$constructingPrescriptionCertificate=True},miRepDefinition[source,master,Global`Epsilon]],"EpsilonOrders"];
 If[!AssociationQ[definition],Return[<|"Propagators"->factorized["Propagators"]|>]];
 certificate=ordinaryPrescriptionCertificate[definition];
 If[!TrueQ[certificate["OrdinaryPrescriptionRemoved"]],Return[<|"Propagators"->factorized["Propagators"],"Certificate"->certificate|>]];
 (* +1 here is the algebra package's required placeholder for the already
    prescription-free rational polynomial. It is not a new causal prescription. *)
 algebraic=FeynCalc`FCI[factorized["Propagators"]]/.
   FeynCalc`StandardPropagatorDenominator[q_,sp_,mass_,{power_,_}]:>
     FeynCalc`StandardPropagatorDenominator[q,sp,mass,{power,1}];
 <|"Propagators"->algebraic,"Certificate"->certificate,
   "OriginalPrescribedPropagators"->factorized["Propagators"]|>
];
FeynFacet`RequireOrdinaryPrescriptionCertificate[data_Association,scope_String]:=Module[{c},
 c=Lookup[data,"OrdinaryPrescriptionCertificate",data];
 Which[
   !MemberQ[{"GenericKinematics","EndpointDistributions"},scope],Failure["UnknownPrescriptionScope",<|"Scope"->scope|>],
   c["Status"]==="NoOrdinaryDenominators",True,
   scope==="GenericKinematics"&&MemberQ[{"CertifiedGenericKinematics","CertifiedJointEndpointDistributions"},c["Status"]],True,
   scope==="EndpointDistributions"&&c["Status"]==="CertifiedJointEndpointDistributions"&&
    TrueQ[c["JointMeasureHasNoEndpointAtoms"]]&&TrueQ[c["CommonConvergenceDomainExists"]],True,
   True,Failure["OrdinaryPrescriptionCertificateRequired",<|"Scope"->scope,"Certificate"->c|>]]
];
measuredOrdinaryPrescriptionCertificate[input_,master_,request_]:=Module[
 {family,top,z,reference,tagged,conditions,cuts,measurement,nu,slot,polynomial,jacobian,
  total,observable,ordinary,keep,parentCuts,descriptors,parent,certificate,coordinates,
  variables,compiled,particleCuts,normalOrders,referenceCoordinates},
 family=FeynFacet`CreateCutIntegralDefinition[input];
 If[!AssociationQ[family],epsOrderFail["TypedMeasuredCutFamilyRequired"]];
 If[!ContainsAll[Keys[request],{"MeasurementVariable","ReferenceMomentum","TaggedMomentum","ExternalKinematicConditions"}],
  epsOrderFail["MeasuredPrescriptionGeometryRequired"]];
 {z,reference,tagged,conditions}=Lookup[request,
  {"MeasurementVariable","ReferenceMomentum","TaggedMomentum","ExternalKinematicConditions"}];
 top=family["Topology"];measurement=family["MeasurementCutIndices"];particleCuts=family["ParticleCutIndices"];
 referenceCoordinates=cutOrderVector[reference,top[[4]]];
 If[!cutConvergenceProve[Element[referenceCoordinates,Reals],conditions],
  epsOrderFail["RealExternalMeasurementReferenceRequired"]];
 If[Length[measurement]=!=1||!MatchQ[z,_Symbol]||!FreeQ[conditions,z]||
  !MatchQ[master,FeynCalc`GLI[_,{__Integer}]]||master[[1]]=!=top[[1]]||
  Length[master[[2]]]=!=Length[top[[2]]]||validateCutGLIs[{master},{family}]=!=True,
  epsOrderFail["SingleMeasuredVariableAndMatchingIntegralRequired"]];
 nu=master[[2]];slot=First[measurement];
 cuts=Select[family["Cuts"],#["Type"]==="Particle"&];
 total=Expand[Total[Lookup[cuts,"Momentum"]Lookup[cuts,"EnergyDirection"]]];
 If[!MemberQ[Lookup[cuts,"Momentum"]Lookup[cuts,"EnergyDirection"],tagged],
  epsOrderFail["TaggedForwardParticleCutRequired"]];
 polynomial=family["InversePropagators"][[slot]];
 If[!PolynomialQ[polynomial,z]||Exponent[polynomial,z]=!=1,
  epsOrderFail["AffineMeasurementVariableRequired"]];
 jacobian=-Coefficient[Expand[polynomial],z];
 If[!FreeQ[jacobian,Alternatives@@Join[{z},top[[3]]]]||
  !cutConvergenceProve[jacobian>0,conditions],epsOrderFail["PositiveExternalMeasurementJacobianRequired"]];
 observable=Factor[polynomial/jacobian+z];
 If[!epsOrderZero[Factor[jacobian-(2FeynCalc`ExpandScalarProduct[
     FeynCalc`FCI[FeynCalc`SPD[reference,total]]]/.top[[5]])]]||
   !epsOrderZero[cutOrderSquare[reference,top[[5]]]]||
   !epsOrderZero[Factor[observable-(2FeynCalc`ExpandScalarProduct[
     FeynCalc`FCI[FeynCalc`SPD[reference,tagged]]]/.top[[5]])/jacobian]],
  epsOrderFail["NormalizedNullReferenceMeasurementRequired"]];
 ordinary=Complement[Range[Length[nu]],family["CutIndices"]];
 If[!FreeQ[{family["InversePropagators"][[Select[ordinary,nu[[#]]=!=0&]]],
   family["MeasurePrefactor"]/jacobian,top[[5]]},z],
  epsOrderFail["ExplicitMeasurementDependenceOutsideCutRequiresProductDerivativeProof"]];
 keep=DeleteCases[Range[Length[nu]],slot];
 parentCuts=(First[FirstPosition[keep,#]]&/@particleCuts);
 descriptors=propagatorDescriptor/@top[[2,keep]];
 parent=<|"LoopMomenta"->top[[3]],"ExternalMomenta"->top[[4]],
  "InversePropagators"->family["InversePropagators"][[keep]],
  "PropagatorMomenta"->Lookup[descriptors,"Momentum",Missing["NotQuadratic"]],
  "PropagatorPowers"->nu[[keep]],"CutIndices"->parentCuts,
  "OrientedCutMomenta"->(Lookup[cuts,"Momentum"]Lookup[cuts,"EnergyDirection"]),
  "VirtualLoopCount"->0,"KinematicRules"->top[[5]],"KinematicConditions"->conditions,
  "TimeDirection"->family["TimeDirection"],"Dimension"->D,
  "DimensionalRegulator"->Lookup[request,"DimensionalRegulator",Global`Epsilon]|>;
 certificate=cutIntegralConvergenceCertificate[parent];
 coordinates=cutConvergenceCoordinates[parent];variables=Table[Unique["measuredCoordinate$"],{Length[coordinates]}];
 compiled=Expand[observable/.Thread[coordinates->variables]];
 If[!PolynomialQ[compiled,variables]||
  !AllTrue[First/@CoefficientRules[compiled,variables],Total[#]<=1&]||
  !FreeQ[compiled,Alternatives@@top[[3]]],
  epsOrderFail["AffineScalarProductTestFunctionInsertionRequired"]];
 normalOrders=nu[[particleCuts]]-1;
 Join[certificate,<|"Scope"->"Fixed external kinematics; equality as a distribution in the measurement variable.",
  "MeasurementVariable"->z,"MeasurementCutIndex"->slot,"MeasurementCutOrder"->nu[[slot]],
  "ParticleCutIndicesInSource"->particleCuts,"ParticleCutDerivativeOrders"->normalOrders,
  "MeasurementTestFunctionDerivativeOrder"->nu[[slot]]-1,
  "MeasurementTestFunctionCoefficient"->(-1)^(nu[[slot]]-1)jacobian^(1-nu[[slot]])/(nu[[slot]]-1)!,
  "MeasurementObservable"->observable,"MeasurementJacobian"->jacobian,
  "SmoothInsertionDerivativeOrder"->Total[normalOrders]+nu[[slot]]-1,
  "MeasurementSupportProof"->"The tagged and complementary forward momenta are future causal, p is future null, and their fractions sum to one throughout nonnegative particle-mass increments.",
  "MeasurementTestFunctions"->"Smooth compactly supported functions on the real measurement line, including a neighborhood of both physical endpoints.",
  "MeasurementCutRemovedFromDefinition"->False,
  "PointwiseRegulatedConvergenceEstablished"->False,"ExternalEndpointUniformityEstablished"->False,
  "EndpointDistributionStatus"->"Measurement distribution only; external kinematic endpoints are not certified",
  "ParentProof"->"The same compact-cut convergence certificate acts on the smooth affine scalar-product insertion and all required normal derivatives."|>]
];
(* A whole prepared source is certified before algebraic partial fractions.
   The common maximum powers dominate all its finite polynomial numerators on
   the compact cut domain. The coefficient denominator is cleared structurally. *)
FeynFacet`CertifyOrdinaryPrescriptionRemoval[prepared_Association,Automatic,request_Association]/;
 Lookup[prepared,"Format",None]==="FeynFacet-MeasuredCutIntegrand":=Module[
 {source=prepared["SourceDefinition"],variables,numerators,external,common,master,result,powers},
 variables=prepared["FreeScalarProductVariables"];numerators=Lookup[prepared["Terms"],"Numerator"];
 If[!AllTrue[numerators,PolynomialQ[#,variables]&],
  Return[Failure["PolynomialPreparedSourceNumeratorsRequired",<||>]]];
 external=Join[Keys[request["JointExternalDomain"]["ExternalIntervals"]],{request["MeasurementVariable"]}];
 common=FeynFacet`CommonKinematicDenominator[numerators,external];
 If[!AssociationQ[common],Return[common]];
 powers=Join[prepared["CutPowers"],prepared["OrdinaryPowerBounds"]];
 master=FeynCalc`GLI[source["Topology"][[1]],powers];
 result=FeynFacet`CertifyOrdinaryPrescriptionRemoval[source,master,
  Join[request,<|"ScalarCoefficients"->{1/common["CommonDenominator"]}|>]];
 If[!AssociationQ[result],Return[result]];
 Join[result,<|"PreparedSourcePolynomialDomination"-><|
   "SourceDefinition"->source,"TermCount"->Length[prepared["Terms"]],
   "DominatingIntegralPowers"->powers,"CommonExternalCoefficientDenominator"->common["CommonDenominator"],
   "NumeratorVariables"->variables,"PolynomialNumeratorsVerified"->True,
   "Argument"->"All scalar products of the cut momenta are uniformly bounded in the fixed timelike frame on the declared compact external domain. Multiplication by the common external denominator makes every unit-cut numerator polynomial there. Larger ordinary powers dominate lower powers up to bounded polynomial factors.",
   "PartialFractionsUsedForCertification"->False|>|>]
];
FeynFacet`CertifyOrdinaryPrescriptionRemoval[input_Association,master_,request_Association:<||>]:=
 Catch[Module[{s,def,e,family,measured},
 If[KeyExistsQ[request,"JointExternalDomain"],
  family=FeynFacet`CreateCutIntegralDefinition[input];
  If[!AssociationQ[family],epsOrderFail["TypedJointCutDefinitionRequired"]];
  measured=measuredOrdinaryPrescriptionCertificate[family,master,request];
  s=Join[family,<|"Prescription"->ConstantArray[0,Length[family["Topology"][[3]]]],
    "KinematicConditions"->request["ExternalKinematicConditions"]&&0<request["MeasurementVariable"]<1|>];
  e=Lookup[request,"DimensionalRegulator",Global`Epsilon];
  def=Block[{$constructingPrescriptionCertificate=True},miRepTypedDefinition[s,master,e]];
  Return[cutIntegralJointConvergenceCertificate[def,measured,request],Module]];
 If[MemberQ[{"FeynFacet-CutIntegralFamily","FeynFacet-CutIntegralDefinition"},Lookup[input,"Format",None]]&&
    Lookup[input,"MeasurementCutIndices",{}]=!={},
  With[{measured=measuredOrdinaryPrescriptionCertificate[input,master,request]},
   Return[If[Lookup[request,"PrescriptionScope","GenericKinematics"]==="GenericKinematics",
    measured,FeynFacet`RequireOrdinaryPrescriptionCertificate[measured,Lookup[request,"PrescriptionScope"]]]]]];
 If[!MemberQ[{"GenericKinematics","EndpointDistributions"},Lookup[request,"PrescriptionScope","GenericKinematics"]],
   epsOrderFail["UnknownPrescriptionScope"]];
 s=miRepFamilyData[miRepFC[Join[input,request]],miRepFC[master]];
 e=Lookup[s,"DimensionalRegulator",Global`Epsilon];
 def=Block[{$constructingPrescriptionCertificate=True},miRepDefinition[s,miRepFC[master],e]];
 With[{certificate=ordinaryPrescriptionCertificate[def]},
   If[Lookup[request,"PrescriptionScope","GenericKinematics"]==="EndpointDistributions",
     FeynFacet`RequireOrdinaryPrescriptionCertificate[certificate,"EndpointDistributions"],certificate]]],"EpsilonOrders"];
End[];EndPackage[];
