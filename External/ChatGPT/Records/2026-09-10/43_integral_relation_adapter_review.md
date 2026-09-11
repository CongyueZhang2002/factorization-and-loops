# Integral relation adapter review

Model: gpt-6-pro; thinking: standard. HTTP 200.

Conversation: 6aa2eb2d-5588-83e8-bf9d-d35cd8d66f3b
Request: 37b95cc5-1908-410c-988b-227b11b0793d

## Request and code

Please review the implemented reusable adapter below, especially normalization, ordered-basis binding, namespace collisions and exact witness verification. gpt-6-pro review, same regeneration campaign. No request to prove endpoint cancellations.

Actual run: all 27 fresh ghost masters map; the one nonrequested destination CF26 is exactly reidentified with CF13 in the saved global unreduced basis. Its four-term image passes exact witness verification against 7 stored independent constraints, then restores s^(-3), s^(-2), s^(-1), s^0, and closes on the requested saved masters. No numerical identity inference. Runtime 6.1s. 11 synthetic tests pass (including negative numerator powers, source/target label collision, wrong basis/columns, different normalization, wrong coordinates, unequal loop counts, prefactors, fixed masses, eps pole demand).

The relation input is project-owned data constructed from the unchanged original registry and saved global system; no process-specific formulas in code. The API receives an ordered Catalog of full definitions, Basis, ConstraintMatrix, proposed Rules, regulator and coordinates. It retains the original bound source/target catalog and separate affine, constraint, and scale provenance. The assembly reader later rechecks source definitions and integrals against actual fresh coefficient tables.

Questions: any mathematical bypass or accidental wrong coordinate normalization? Any practical simplification that avoids extra computation? Please focus on correctness blockers, not speculative new features.


## Adapter

```wl
(* Reuse exact homogeneous relations after matching independent cut catalogs.
   Affine identities, linear constraints and scale changes retain separate evidence. *)
FeynFacet`ReduceMatchedIntegralCatalog::usage =
 "ReduceMatchedIntegralCatalog[match,relations,request] replaces destinations outside TargetIntegrals by exactly verified linear relations and restores their overall scale. relations binds an ordered Basis, ConstraintMatrix and Rules to a Catalog of original integral definitions. The supported automatic scaling is a common loop dimension with homogeneous mass-dimension-two propagators, particle cuts and no extra kinematic integral prefactors.";
relationIntegralNormalize[x_]:=coefficientCanonicalMasterExpression[x]/.
 m_FeynCalc`GLI:>cutEquivalenceIntegral[m];
relationFail[tag_,data_:<||>]:=Throw[Failure[tag,data],"IntegralRelations"];
relationZeroQ[x_]:=TrueQ[Cancel[Together[x]]===0];

(* All momenta scale by Sqrt[lambda]; parameter dimensions are explicit.
   This establishes the physical scaling separately from the algebraic
   NormalizeIntegralEquationScale change of unknowns. *)
relationScaleWeights[basis_,records_,normalization_,request_]:=Module[
 {dimensions,scale,assumptions,parameterRules,lambda,byName,tops,loopCounts,tags,cutCounts,top,record,gramRules,scaled,conventions,dimensionDeclarations,measures},
 {scale,assumptions,dimensions}=Lookup[request,{"Scale","Assumptions","ParameterMassDimensions"},None];
 If[!MatchQ[scale,_Symbol]||!AssociationQ[dimensions]||
   !AllTrue[Keys[dimensions],MatchQ[#,_Symbol]&]||
   !AllTrue[Values[dimensions],IntegerQ]||Lookup[dimensions,scale,None]=!=2||
   !TrueQ[Quiet[FullSimplify[scale>0,assumptions]]],
  relationFail["PositiveScaleAndParameterMassDimensionsRequired"]];
 byName=Association[(cutEquivalenceFamilyName[#["Topology"][[1]]]->#)&/@records];
 If[!ContainsAll[Keys[byName],First/@basis],relationFail["RelationIntegralDefinitionsMissing"]];
 tops=Association@Map[Function[name,
   record=byName[name];top=cutEquivalenceTopology[record,normalization];
   If[top===$Failed,relationFail["UnsupportedRelationIntegralDefinition",<|"Family"->name|>]];
   conventions=cutDefinitionConventions[record];
   If[!AllTrue[top["CutTypes"],#==="Particle"&]||
     !MemberQ[{None,{},True},Lookup[record,"AdditionalAcceptanceBoundaries",None]]||
     !FreeQ[Values[KeyTake[conventions,{"MeasurePrefactor","MasterIntegralPrefactor"}]],
       Alternatives@@Join[Keys[dimensions],top["Loops"],top["External"]]]||
     !AllTrue[Values[KeyTake[conventions,{"MeasurePrefactor","MasterIntegralPrefactor"}]],#===1&],
    relationFail["BareHomogeneousParticleCutIntegralsRequired",<|"Family"->name|>]];
   lambda=Unique["momentumScale$"];
   parameterRules=KeyValueMap[#1->lambda^(#2/2)#1&,dimensions];
   gramRules=DeleteDuplicates[Thread[Flatten[top["GramMatrix"]]->lambda Flatten[top["GramMatrix"]]]];
   scaled=(top["PropagatorPolynomials"]/.gramRules)/.parameterRules;
   If[!AllTrue[MapThread[#1-lambda #2&,{scaled,top["PropagatorPolynomials"]}],relationZeroQ]||
      !AllTrue[top["KinematicRules"],relationZeroQ[(Last[#]/.parameterRules)-lambda Last[#]]&],
    relationFail["IntegralScaleHomogeneityNotEstablished",<|"Family"->name|>]];
   name->top],DeleteDuplicates[First/@basis]];
 loopCounts=DeleteDuplicates[Length[#["Loops"]]&/@Values[tops]];
 tags=DeleteDuplicates[Lookup[Values[tops],"LorentzDimensionAnnotations"]];
 cutCounts=DeleteDuplicates[Length[#["CutIndices"]]&/@Values[tops]];
 dimensionDeclarations=DeleteDuplicates[
  Lookup[byName[#],"Dimension",tops[#]["LorentzDimensionAnnotations"]]&/@Keys[tops]];
 measures=DeleteDuplicates[Lookup[Values[tops],"Normalization"]];
 If[Length[loopCounts]=!=1||Length[tags]=!=1||Length[cutCounts]=!=1||Length[dimensionDeclarations]=!=1||Length[measures]=!=1,
  relationFail["CommonLoopDimensionAndCutMeasureRequired"]];
 <|"Weights"->Association[(#->-Total[#[[2]]])&/@basis],"LoopCount"->First[loopCounts],
   "LorentzDimensionAnnotations"->First[tags],"CutCount"->First[cutCounts],
   "Scale"->scale,"ParameterMassDimensions"->dimensions,"Assumptions"->assumptions,
   "DefinitionCheck"->"Exact homogeneity under a common positive momentum scaling"|>
];

FeynFacet`ReduceMatchedIntegralCatalog[match_Association,relations_Association,request_Association]:=
 Catch[Module[{target,desired,initial,images,needed,relationCatalog,basis,constraints,proposed,
   secondary,selected,representatives,rows,nonzero,rref,columns,inverse,row,parts,witness,
   witnesses={},proof,weights,lifted,normalization,restored,rhsMasters,rhsMatch,finalMap,
   converted,rules,scale,kinematicRules,records,relationVariables,e},
 If[Lookup[match,"DataType",None]=!="CutIntegralCatalogMatch"||
   Lookup[match,"Status",None]=!="Complete"||!AssociationQ[Lookup[match,"TargetCatalog",None]],
  relationFail["CompleteBoundCatalogMatchRequired"]];
 target=match["TargetCatalog"];
 If[Lookup[match,"Normalization",None]=!=Lookup[target,"Normalization",None],
  relationFail["MatchedCatalogNormalizationMismatch"]];
 initial=relationIntegralNormalize[match["Rules"]];
 desired=relationIntegralNormalize[Lookup[request,"TargetIntegrals",{}]];
 If[desired==={}||!DuplicateFreeQ[desired]||
   !ContainsAll[relationIntegralNormalize[target["Integrals"]],desired],
  relationFail["ExplicitSolutionTargetIntegralsRequired"]];
 images=DeleteDuplicates[Cases[Last/@initial,_FeynCalc`GLI,Infinity]];
 needed=Complement[images,desired];
 If[needed==={},Return[Join[match,<|"IntegralRelationReduction"-><|
   "Status"->"DirectMatchesSuffice","TargetIntegrals"->desired|>|>]]];
 If[!ContainsAll[Keys[relations],{"Catalog","Basis","ConstraintMatrix","Rules","DimensionalRegulator","KinematicVariables"}],
  relationFail["BoundIntegralRelationsRequired"]];
 relationCatalog=relations["Catalog"];
 basis=relationIntegralNormalize[relations["Basis"]];
 If[!AssociationQ[relationCatalog]||basis=!=relationIntegralNormalize[Lookup[relationCatalog,"Integrals",{}]]||
   !DuplicateFreeQ[basis]||Lookup[relationCatalog,"Normalization",None]=!=target["Normalization"],
  relationFail["OrderedRelationBasisAndDefinitionsMismatch"]];
 constraints=Normal[relations["ConstraintMatrix"]];proposed=relationIntegralNormalize[relations["Rules"]];
 e=relations["DimensionalRegulator"];relationVariables=relations["KinematicVariables"];
 If[!MatrixQ[constraints]||Length[constraints]===0||Last[Dimensions[constraints]]=!=Length[basis]||
   !coefficientExactDataQ[{constraints,proposed}]||!MatchQ[proposed,{(_Rule)...}]||
   !DuplicateFreeQ[First/@proposed]||!ContainsAll[basis,First/@proposed]||
   !MatchQ[e,_Symbol]||!MatchQ[relationVariables,{__Symbol}],
  relationFail["ExactOrderedLinearRelationSystemRequired"]];
 If[Lookup[request,"DimensionalRegulator",None]=!=e||
   Lookup[request,"KinematicVariables",None]=!=relationVariables,
  relationFail["RelationRegulatorOrCoordinatesMismatch"]];
 records=Catch[coefficientTopologyRecords[relationCatalog["Families"],True],"CoefficientAssembly"];
 If[FailureQ[records],relationFail["InvalidRelationIntegralDefinitions",<|"Cause"->records|>]];
 secondary=FeynFacet`MatchCutIntegralCatalogs[
  <|"Integrals"->needed,"Families"->target["Families"],"Normalization"->target["Normalization"]|>,
  relationCatalog];
 If[FailureQ[secondary]||secondary["Status"]=!="Complete",
  relationFail["RelationBasisAffineMatchIncomplete",<|"Cause"->secondary|>]];
 representatives=Last/@relationIntegralNormalize[secondary["Rules"]];
 selected=Map[Function[master,
  With[{rule=SelectFirst[proposed,First[#]===master&,None]},
   If[rule===None,relationFail["ProposedIntegralImageMissing",<|"Master"->master|>]];rule]],representatives];
 rref=Select[RowReduce[constraints],!AllTrue[#,relationZeroQ]&];
 If[Length[rref]=!=Length[constraints],relationFail["IndependentConstraintRowsRequired"]];
 columns=Function[r,SelectFirst[Range[Length[r]],!relationZeroQ[r[[#]]]&]]/@rref;
 inverse=Map[Cancel,Inverse[constraints[[All,columns]]],{2}];
 Do[
  parts=linearIntegralSum[First[rule]-Last[rule]];
  If[FailureQ[parts]||!relationZeroQ[parts["Remainder"]]||!ContainsAll[basis,Keys[parts["Terms"]]],
   relationFail["HomogeneousRelationInDeclaredBasisRequired",<|"Rule"->rule|>]];
  row=Lookup[parts["Terms"],basis,0];
  witness=Cancel/@(row[[columns]].inverse);
  If[!AllTrue[witness.constraints-row,relationZeroQ],
   relationFail["ExactIntegralRelationWitnessFailed",<|"Rule"->rule|>]];
  AppendTo[witnesses,<|"Rule"->rule,"ConstraintRowCombination"->witness|>],
 {rule,selected}];
 proof=relationScaleWeights[basis,records,relationCatalog["Normalization"],request];
 weights=proof["Weights"];scale=proof["Scale"];
 rows=AssociationThread[basis,#]&/@constraints;
 rows=Select[#,#=!=0&]&/@rows;
 lifted=Map[Association@KeyValueMap[#1->#2 scale^(-weights[#1])&,#]&,rows];
 normalization=FeynFacet`NormalizeIntegralEquationScale[lifted,weights,scale];
 If[FailureQ[normalization]||!And@@MapThread[AllTrue[Lookup[#1,basis,0]-Lookup[#2,basis,0],relationZeroQ]&,
   {normalization["Rows"],rows}],
  relationFail["ExactRelationScaleNormalizationFailed",<|"Cause"->normalization|>]];
 restored=FeynFacet`RestoreIntegralEquationScale[selected,normalization];
 If[FailureQ[restored],Throw[restored,"IntegralRelations"]];
 rhsMasters=DeleteDuplicates[Cases[Last/@restored,_FeynCalc`GLI,Infinity]];
 rhsMatch=FeynFacet`MatchCutIntegralCatalogs[
  <|"Integrals"->rhsMasters,"Families"->records,"Normalization"->target["Normalization"]|>,
  Join[target,<|"Integrals"->desired,"PreferredIntegrals"->desired|>]];
 If[FailureQ[rhsMatch]||rhsMatch["Status"]=!="Complete",
  relationFail["RelationImagesNeedAdditionalSolutions",<|"Cause"->rhsMatch|>]];
 converted=(First[#]->(Last[#]/.Dispatch[relationIntegralNormalize[rhsMatch["Rules"]]]))&/@restored;
 finalMap=(First[#]->(Last[#]/.Dispatch[converted]))&/@relationIntegralNormalize[secondary["Rules"]];
 kinematicRules=Lookup[request,"KinematicRules",{}];
 If[!MatchQ[kinematicRules,{(_Rule)...}]||!coefficientExactDataQ[kinematicRules],
  relationFail["ExactRelationKinematicRulesRequired"]];
 finalMap=(First[#]->(Last[#]/.kinematicRules))&/@finalMap;
 rules=MapThread[First[#1]->(Last[#2]/.Dispatch[finalMap])&,{match["Rules"],initial}];
 If[!ContainsAll[desired,DeleteDuplicates[Cases[Last/@rules,_FeynCalc`GLI,Infinity]]],
  relationFail["ComposedIntegralRulesNotClosed"]];
 Join[match,<|"Rules"->rules,"Method"->"ExactAffineMatchesAndVerifiedLinearRelations",
  "AffineRules"->match["Rules"],"IntegralRelationReduction"-><|
   "Status"->"ExactRelationsComposed","TargetIntegrals"->desired,
   "RelationCatalog"->relationCatalog,"ConstraintBasis"->basis,"ConstraintMatrix"->constraints,
   "DimensionalRegulator"->e,"KinematicVariables"->relationVariables,
   "Witnesses"->witnesses,"RelationBasisMatches"->secondary,"SolutionTargetMatches"->rhsMatch,
   "PhysicalScaleHomogeneity"->proof,"ScaleNormalization"->normalization,
   "RestoredRules"->restored,"ComposedTargetRules"->finalMap,
   "KinematicRules"->kinematicRules,"EpsilonOrderCoverageClaimed"->False,
   "EndpointDistributionScopeExtended"->False|>|>]
 ],"IntegralRelations"];

```

## Driver

```wl
#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
SetSystemOptions["ParallelOptions"->{"ParallelThreadNumber"->1,"MKLThreadNumber"->1}];
root=DirectoryName[ExpandFileName[$InputFileName],2];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];$PrePrint=.;
args=Rest[$ScriptCommandLine];
If[Length[args]=!=3,Print["Expected RELATION_REQUEST.wl MATCH.wxf OUTPUT.wxf"];Exit[2]];
read[path_]:=If[ToLowerCase[FileExtension[path]]==="wxf",Import[path,"WXF"],Get[path]];
file=ExpandFileName[args[[3]]];
If[ToLowerCase[FileExtension[file]]=!="wxf",Print["Output must have .wxf extension"];Exit[2]];
request=read[ExpandFileName[args[[1]]]];match=read[ExpandFileName[args[[2]]]];
If[!AssociationQ[request]||!ContainsAll[Keys[request],{"Relations","Request"}]||!AssociationQ[match],
 Print["Relations, Request and a bound catalog match are required"];Exit[2]];
seconds=First[AbsoluteTiming[result=FeynFacet`ReduceMatchedIntegralCatalog[
 match,request["Relations"],request["Request"]]]];
If[FailureQ[result],Print[result];Exit[1]];
If[!DirectoryQ[DirectoryName[file]],CreateDirectory[DirectoryName[file],CreateIntermediateDirectories->True]];
temporary=file<>".partial";
If[!StringQ[Quiet[Check[Export[temporary,result,"WXF",PerformanceGoal->"Size"],$Failed]]]||
 Import[temporary,"WXF"]=!=result,
 Print["Integral relation serialization failed"];Exit[1]];
If[!StringQ[Quiet[Check[RenameFile[temporary,file,OverwriteTarget->True],$Failed]]],
 Print["Integral relation output rename failed"];Exit[1]];
summary=<|"Status"->result["IntegralRelationReduction"]["Status"],
 "SourceCount"->result["SourceCount"],"RelationCount"->Length[Lookup[result["IntegralRelationReduction"],"Witnesses",{}]],
 "FinalIntegralCount"->Length[DeleteDuplicates[Cases[Last/@result["Rules"],h_[_,{__Integer}]/;SymbolName[h]==="GLI",Infinity]]],
 "Seconds"->seconds,"OutputBytes"->FileByteCount[file]|>;
Export[file<>".json",summary,"RawJSON"];Print["COMPLETED INTEGRAL RELATIONS ",summary];Exit[0];

```


## Review

The witness algebra, scale-exponent direction, and staged namespace composition are correct. I would fix two mathematical acceptance gaps—binding the restored scale to the saved unit-scale convention, and restricting post-verification kinematic substitutions—plus one driver failure-handling gap. These findings do not establish that the reported CF26→CF13 reduction is wrong; the attachment reports a successful run and test summary, but does not include the actual input records or test bodies for independent replay. 

pending_relation_adapter_review…

1. P1: The requested scale is not bound to the saved normalization scale

relationScaleWeights verifies that the requested scale is a positive symbol of mass dimension two and that the propagator/kinematic polynomials transform homogeneously. It does not verify that this is the scale set to one when the supplied constraints and rules were constructed. The relation metadata checks bind the regulator and coordinate-symbol list, but contain no corresponding unit-scale convention check. 

pending_relation_adapter_review… +1

A concrete accepted wrong-input case is to start from the valid request and change:

Wolfram Language
"Scale" -> q

while adding q -> 2 to "ParameterMassDimensions" and q > 0 to the assumptions. Keep the existing dimensions of s,t,u and the existing coordinate substitutions.

Since q need not occur in any propagator, the physical homogeneity tests remain unchanged. The lifted-row normalization also passes: it is an algebraically valid change of unknowns using q. But restoration now supplies q
−3
,q
−2
,q
−1
,1, although the saved relation was normalized at s=1. 

pending_relation_adapter_review… +1

Minimal fix: bind the relation data to the saved unit-scale convention—its scale symbol, unit normalization, and dimensionless-coordinate definitions—and compare that convention with the request. An explicitly verified coordinate change can be allowed later; it is not needed for this campaign. Checking merely that the chosen scale occurs in a propagator would not be sufficient.

The distinction is:

homogeneity under simultaneous dilation

=identification of the supplied unit-scale functions.

Likewise, a declared additional dimensionful parameter must appear in the unit-scale coefficients through its correctly normalized ratio, or be rejected by this restricted adapter. Passing the propagator-homogeneity test alone does not perform that conversion.

2. P1: KinematicRules can invalidate a verified rule after all proof checks

At lines 148–151, the code checks only that kinematicRules is an exact list of rules, then applies it to the entire restored RHS. There is no restriction to scalar coordinates and no verification that the substitutions describe the same target kinematics. The final check tests only whether the remaining GLIs belong to desired. 

pending_relation_adapter_review…

Two concrete bypasses follow.

A wrong-sign or swapped coordinate map, such as v -> t/s instead of the declared v -> -t/s, changes the rational coefficients while retaining the same target integrals.

More directly, an exact rule

Wolfram Language
targetJ -> 0

for a desired GLI appearing in a restored image removes that term after witness verification. The final subset test still passes because removing a GLI cannot introduce an unwanted destination. ReplaceAll operates on matching subexpressions, not exclusively on scalar coefficients. 
Wolfram Documentation Center

Minimal fix: parse the restored RHS as a linear integral sum, apply coordinate substitutions only to its scalar coefficients, and rebuild it with unchanged GLI keys. Require unique substitution LHSs drawn from the declared coordinate symbols, with scalar RHSs. Then verify the coordinate map against the bound unit-scale convention from item 1.

The last verification matters: restricting the rule grammar alone would still permit v -> 0 or the wrong sign. Substituting the same wrong map into both the witness and constraint matrix would not repair the problem, because the target integral definitions would still describe the original kinematics.

3. P2: The driver can publish an unevaluated adapter call

The driver checks that the outer request has "Relations" and "Request" keys, but not that their values are associations. The adapter’s only shown definition requires both arguments to be associations. Therefore,

Wolfram Language
<|"Relations" -> 42, "Request" -> <||>|>

passes the driver’s initial check but leaves ReduceMatchedIntegralCatalog[...] unevaluated. That expression is not a Failure, so the driver can serialize it, pass exact readback, and rename it into the output location. Subsequent summary-generation errors do not prevent the unconditional Exit[0]. 

pending_relation_adapter_review… +1

Validate the two nested argument shapes before calling the adapter, and require an association with the expected result type/status before writing. A catch-all adapter definition returning Failure is also appropriate. Serialization equality establishes faithful storage, not successful evaluation.

What is correct in the implementation
The exact witness calculation has the right orientation

Writing K for the independent constraint matrix and P for the chosen pivot columns, your calculation is

ω=ℓ
P
	​

(K
:,P
	​

)
−1
,ωK−ℓ=0.

That is correct for row-vector witnesses. Importantly, the final check covers every basis column, not only the pivot columns. The basis is also required to equal the catalog’s ordered integral list. The remaining trust assumption is that the project-owned K contains valid relations in that declared order; this adapter need not rederive those established constraints. 

pending_relation_adapter_review… +1

Scale weights and the algebraic lifting are correct

For the supported bare definitions,

w
i
	​

=−
a
∑
	​

n
ia
	​

,I
i
	​

=s
LD/2+w
i
	​

I
i
	​

,

so restoration of 
I
i
	​

=∑
j
	​

r
ij
	​

I
j
	​

 requires

I
i
	​

=
j
∑
	​

r
ij
	​

s
w
i
	​

−w
j
	​

I
j
	​

.

Signed numerator indices and raised cut powers are included by -Total[powers]. The common-loop/dimension checks and rejection of nonunit integral prefactors support that restricted convention. Lifting constraint coefficients by s
−w
j
	​

, then checking that normalization returns the original rows, is the correct algebraic procedure. The defect in item 1 is the convention binding, not an exponent-sign error. 

pending_relation_adapter_review… +1

The three-stage namespace composition is sound

The code separately performs relation-catalog RHS → solution target, intermediate target → relation image, and original source → final image. Each operation acts on the RHS at the appropriate stage. 

pending_relation_adapter_review…

The single-pass /. semantics are important: an introduced destination is not repeatedly rewritten using another catalog’s coincident label during the same replacement. I do not find a source/target collision defect in that staged construction. Do not replace it with unrestricted //.. 
Wolfram Documentation Center

Two smaller record and efficiency points

The inherited top-level "Mappings" remains an affine-stage record. Join[match,…] replaces "Rules" and "Method" but leaves the original "Mappings" pointing to destinations such as CF26. Preserve those mappings explicitly as affine provenance, or clearly scope the field so consumers cannot reconstruct the effective rules from it. The shown driver reads "Rules", so this is not demonstrated corruption in that driver. 

pending_relation_adapter_review… +1

Deduplicate representatives before selecting and verifying rules. Several needed destinations may affine-match the same relation-basis integral, otherwise producing repeated witness work and duplicate converted rules. Identical duplicates are not a mathematical error. The constraint pivot data and scale normalization can also be prepared once for the same bound relation catalog and scale convention, then reused for the gluon adapter call. 

pending_relation_adapter_review…

Highest-value additions to the tests
Test	Expected result
Replace s by an unrelated positive mass-dimension-two scale q	Reject unless a genuine change of the saved normalization convention is supplied and verified.
Keep coordinate names unchanged but change a ratio’s sign or swap its invariant meaning	Reject before accepting composed rules.
Put a desired GLI -> 0 inside KinematicRules	Reject; kinematic substitution must never modify integral keys.
Supply non-association nested "Relations" or "Request"	Nonzero driver exit, with no published output.
Extend the existing collision test through all three catalog stages, including introduced destinations whose labels equal intermediate rule LHSs	Exact expected final RHS, without repeated cross-stage substitution.

After the normalization binding and substitution restrictions are enforced, this is the intended small adapter: exact established relations, freshly composed coefficient maps, and reuse of already sufficient solutions. No new master solution or endpoint-cancellation argument is required.

## Implemented response

The relation input now binds Scale, ReferenceScale=1, ParameterMassDimensions,
KinematicVariables and CoordinateRules to the saved unit-scale convention.
For the current run, the coordinate map is derived from the saved physical
normalization request by solving its invariant definitions. Arbitrary scale or
coordinate changes are rejected. Every dimensionful parameter must be represented
by the scale or a homogeneous dimensionless coordinate; the unit-scale relation
coefficients cannot retain a dimensionful parameter.

Coordinate substitutions act only on scalar coefficients, preserving integral
keys. Restoring a composed record twice is rejected. AffineMappings is separate
from the effective Rules. Representative identities are deduplicated before
witness checks. The adapter has a Failure fallback; the driver validates nested
associations and completed output before publication.

All 18 focused tests pass. The actual ghost relation passes with the new bound
convention (3.34 seconds in the adapter). The real malformed-request CLI test is
queued with the producer-consumer file regression after the active reduction.
