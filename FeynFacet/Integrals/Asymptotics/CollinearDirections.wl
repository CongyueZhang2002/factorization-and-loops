
(* One angular cap containing two approaching null directions. Exact
   energy-angle factorization reduces its complete leading coefficient
   to a Euclidean massless bubble in D-2 dimensions. *)
Begin["FeynFacet`Private`"];
FeynFacet`ConstructTwoDirectionCollinearBoundaryIntegral::usage="ConstructTwoDirectionCollinearBoundaryIntegral[definition,boundary] constructs the complete collinear coefficient for two distinct null directions coupled to one unit-cut particle, with positive total powers. Other angular or energy factors remain unresolved.";
FeynFacet`ConstructTwoDirectionCollinearBoundaryIntegral[definition_Association,boundary_Association] :=
 Catch[Module[{base,descriptors,eikonals,groups,directions,powers,particle,eps=definition["DimensionalRegulator"],
 dim=definition["Dimension"],alpha,beta,totalPower,z,edge,dot,total,separation,normalization,c2,value,
 routing,minor,det,normalPower,positive,fullDot,finiteScale=1,kappa,desc,tau,finiteValue},
 If[!AllTrue[definition["PropagatorPowers"][[definition["CutIndices"]]],#===1&],
   boundaryIntegrationFail["UnitCutsRequiredForTwoDirectionCollinearCoefficient"]];
 base=FeynFacet`ConstructCoalescingNullBoundaryIntegral[definition,boundary];
 If[FailureQ[base],Throw[base,"BoundaryIntegration"]];
 descriptors=base["PropagatorLimits"];
 If[!AllTrue[descriptors,
   Lookup[#,"Type",None]==="RecoilInvariant"||
    (Lookup[#,"Type",None]==="ExternalSubsetInvariant"&&MemberQ[{1,3},Length[#["Subset"]]])&],
   boundaryIntegrationFail["ExactSingleParticleAngularFactorizationRequired"]];
 eikonals=Select[descriptors,Lookup[#,"Type",None]==="ExternalSubsetInvariant"&&Length[#["Subset"]]===1&];
 If[eikonals==={}||Length[DeleteDuplicates[Lookup[eikonals,"Subset"]]]=!=1,
   boundaryIntegrationFail["OneCommonCutParticleRequired"]];
 groups=GroupBy[eikonals,#["ExternalMomentum"]&];directions=Keys[groups];
 powers=Total[Lookup[#,"Power"]]&/@Values[groups];
 If[Length[directions]=!=2||!AllTrue[powers,IntegerQ[#]&&#>0&],
   boundaryIntegrationFail["TwoPositiveDirectionPowersRequired"]];
 particle=First[First[Lookup[eikonals,"Subset"]]];
 z=base["NormalVariable"];edge=base["BoundaryKinematicRules"];
 dot[p_,q_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[p,q]]]/.edge];
 total=Expand[Total[definition["OrientedCutMomenta"]]];
 separation=Cancel[2dot[Sequence@@directions]/Times@@(dot[#,total]&/@directions)];
 If[!NumberQ[separation]||!TrueQ[0<separation<Infinity],boundaryIntegrationFail["DistinctPositiveNullDirectionSeparationRequired"]];
 routing=Table[Coefficient[m,l],{m,definition["OrientedCutMomenta"]},{l,definition["LoopMomenta"]}];
 minor=SelectFirst[Subsets[Range[3],{2}],Det[routing[[#]]]=!=0&];
 det=Abs[Det[routing[[minor]]]];
 alpha=Cancel[(dim-2)/2];beta=dim-3;totalPower=Total[powers];
 normalization=definition["MeasurePrefactor"]definition["MasterIntegralPrefactor"]/det^dim;
 c2=Pi^((dim-1)/2)/(2^(dim-2)Gamma[(dim-1)/2]);
 value=normalization base["ExternalScaleFactor"] c2 2^(2totalPower-dim+1)Pi^alpha *
   separation^(alpha-totalPower) Gamma[totalPower-alpha] *
   Times@@(Gamma[alpha-#]&/@powers) Gamma[alpha]/
    (Times@@(Gamma/@powers) Gamma[3alpha-totalPower]);
 normalPower=Cancel[base["NormalExponent"]+alpha-totalPower];
 fullDot[p_,q_]:=Cancel[FeynCalc`ExpandScalarProduct[FeynCalc`FCI[FeynCalc`SPD[p,q]]]/.definition["KinematicRules"]];
 Do[
  If[Lookup[desc,"Type",None]==="RecoilInvariant",finiteScale*=z^-desc["Power"];Continue[]];
  If[Length[desc["Subset"]]===1,
   kappa=desc["Scale"]/dot[desc["ExternalMomentum"],total];
   finiteScale*=(kappa fullDot[desc["ExternalMomentum"],total])^-desc["Power"],
   finiteScale*=definition["InversePropagators"][[desc["PropagatorIndex"]]]^-desc["Power"]],
 {desc,descriptors}];
 If[!FreeQ[finiteScale,Alternatives@@definition["LoopMomenta"]],
   boundaryIntegrationFail["FiniteAngularScaleContainsLoopMomentum"]];
 tau=Cancel[z fullDot[Sequence@@directions]/(2Times@@(fullDot[#,total]&/@directions))];
 finiteValue=normalization c2 Pi^alpha z^beta finiteScale/2 *
  Times@@(Gamma[alpha-#]&/@powers)/Gamma[3alpha-totalPower] *
  Hypergeometric2F1[powers[[1]],powers[[2]],alpha,1-tau];
 <|"DataType"->"TwoDirectionCollinearBoundaryIntegral","Representation"->"UnitCube",
 "DimensionalRegulator"->eps,"OriginalIntegralDefinition"->definition,"NormalVariable"->z,
 "NormalExponent"->normalPower,"LogarithmPower"->0,"VanishingLogarithmCoefficientsAtThisPower"->True,
 "Terms"->{<|"IntegrationVariables"->{},"Prefactor"->value|>},
 "AnalyticExpression"->value,"DirectionPowers"->powers,"NullDirections"->directions,
 "CommonCutParticle"->particle,"SquaredScaledAngularSeparation"->separation,
 "InitialConvergenceStrip"->Max[powers]<alpha<totalPower,
 "ExactEnergyIntegral"->Beta[2alpha-totalPower,alpha],
 "AngularIntegral"->"Euclidean massless two-propagator integral in D-2 dimensions.",
 "PhysicalRegionCompleteness"->"Exact energy-angle factorization; the whole angular cap converges at both centers and at infinity in the stated strip. The angular complement vanishes after scaling and the energy endpoints are integrable.",
 "PhysicalLimitEstablished"->True,
 "ExactFiniteKinematicsExpression"->finiteValue,"HalfAngleSineSquared"->tau,
 "AngularCompletenessProof"->"Global stereographic rescaling gives a Euclidean bubble times (1+delta^2*u^2)^(S-2alpha)<=1 for max(a,b)<alpha<S. Dominated convergence applies over the full angular domain, including real noninteger D in a parallel-coordinate/perpendicular-radius representation.",
 "NormalizationChanged"->False|>
 ],"BoundaryIntegration"];
End[];
