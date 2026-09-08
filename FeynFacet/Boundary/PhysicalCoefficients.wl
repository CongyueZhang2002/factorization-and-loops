
(* Match justified physical normal/logarithm coefficients to a finite
   primary Frobenius expansion. Geometry hypotheses are owned by the
   integral constructor, not inferred here from a residue spectrum. *)
Begin["FeynFacet`Private`"];
FeynFacet`MatchPhysicalBoundaryCoefficients::usage="MatchPhysicalBoundaryCoefficients[expansion,gauge,definitions,opts] expresses justified leading physical coefficients and vanishing lower powers/logarithms as exact rows in the seed-amplitude basis.";
Options[FeynFacet`MatchPhysicalBoundaryCoefficients]={"GenericRankWitness"->Automatic,"KnownAmplitudeRows"->{}};
FeynFacet`MatchPhysicalBoundaryCoefficients[expansion_Association,gauge_,definitions_Association,OptionsPattern[]] :=
 Catch[Module[{z=expansion["Variable"],eps=expansion["DimensionalRegulator"],
 coeff=expansion["Coefficients"],eigenvalue=expansion["ResidueEigenvalue"],
 order=expansion["MaximumNormalOrder"],logs=expansion["MaximumLogarithmPower"],
 g=Normal[gauge],n,c,witness=OptionValue["GenericRankWitness"],sampleRows,rank,
 clean,valuation,cache=<||>,seriesCoefficient,power,lower,local,relation,rec,
 allHomogeneous={},homogeneous={},observations={},requirements={},sample,newRank,def},
 {n,c}=Dimensions[coeff[[1,1]]];
 If[!MatrixQ[g]||Last[Dimensions[g]]=!=n||
   !AllTrue[Keys[definitions],IntegerQ[#]&&1<=#<=Length[g]&],
   boundaryIntegrationFail["PhysicalCoefficientGaugeDimensionsInvalid"]];
 clean[x_]:=Cancel[Together[x]];
 valuation[x_]:=If[x===0,Infinity,With[{nd=NumeratorDenominator[clean[x]]},
   If[!AllTrue[nd,PolynomialQ[#,z]&],boundaryIntegrationFail["RationalNormalGaugeRequired"]];
   Exponent[nd[[1]],z,Min]-Exponent[nd[[2]],z,Min]]];
 seriesCoefficient[x_,p_]:=If[KeyExistsQ[cache,{x,p}],cache[[Key[{x,p}]]],
   With[{v=clean[SeriesCoefficient[x,{z,0,p}]]},
    If[!FreeQ[v,_SeriesCoefficient|Indeterminate|_DirectedInfinity],
      boundaryIntegrationFail["NormalGaugeCoefficientFailed"]];
    AssociateTo[cache,{x,p}->v];v]];
 If[witness===Automatic,witness=eps->1/97];
 If[!MatchQ[witness,_Rule]||First[witness]=!=eps,boundaryIntegrationFail["GenericRegulatorWitnessRequired"]];
 sampleRows=OptionValue["KnownAmplitudeRows"]/.witness;
 If[sampleRows=!={}&&(!MatrixQ[sampleRows,NumberQ]||Last[Dimensions[sampleRows]]=!=c),
   boundaryIntegrationFail["KnownAmplitudeRowsInvalid"]];
 rank=If[sampleRows==={},0,MatrixRank[sampleRows]];
 Do[
  def=definitions[row];
  If[!TrueQ[Lookup[def,"PhysicalLimitEstablished",False]],
    boundaryIntegrationFail["PhysicalBoundaryLimitNotEstablished",<|"OriginalRow"->row|>]];
  power=clean[def["NormalExponent"]-eigenvalue];
  If[!IntegerQ[power]||Lookup[def,"LogarithmPower",0]=!=0,
   boundaryIntegrationFail["PhysicalCoefficientPrimaryExponentMismatch",<|"OriginalRow"->row|>]];
  lower=Min[valuation/@g[[row]]];
  If[lower===Infinity||power-lower>order,
   boundaryIntegrationFail["PhysicalCoefficientNormalOrdersMissing",<|"OriginalRow"->row,
    "RequiredNormalOrder"->(power-lower),"AvailableNormalOrder"->order|>]];
  AppendTo[requirements,<|"OriginalRow"->row,"IntegerNormalPower"->power,
    "MinimumGaugeNormalPower"->lower,"RequiredFrobeniusNormalOrder"->Max[0,power-lower]|>];
  local=Table[seriesCoefficient[#,q]&/@g[[row]],{q,lower,power}];
  Do[
   relation=If[p<lower,ConstantArray[0,c],
     clean/@Total[Table[local[[q-lower+1]].coeff[[p-q+1,l+1]],{q,lower,p}]]];
   rec=<|"OriginalRow"->row,"IntegerNormalPower"->p,"LogarithmPower"->l,"AmplitudeRow"->relation|>;
   If[p===power&&l===0,AppendTo[observations,rec],
    If[p<power||TrueQ[Lookup[def,"VanishingLogarithmCoefficientsAtThisPower",False]],
     AppendTo[allHomogeneous,rec];sample=clean[#/.witness]&/@relation;
     If[!VectorQ[sample,NumberQ],boundaryIntegrationFail["AmplitudeRankSpecializationInvalid"]];
     newRank=If[sampleRows==={},If[AllTrue[sample,#===0&],0,1],MatrixRank[Append[sampleRows,sample]]];
     If[newRank>rank,rank=newRank;AppendTo[sampleRows,sample];AppendTo[homogeneous,rec]]]],
   {p,Min[lower,power],power},{l,0,logs}],
  {row,Keys[definitions]}];
 <|"DataType"->"PhysicalLeadingBoundaryEquations","HomogeneousAmplitudeRelations"->homogeneous,
  "AllHomogeneousRelations"->allHomogeneous,"LeadingCoefficientRows"->observations,
  "NormalOrderRequirements"->requirements,"HomogeneousRankIncludingKnownRows"->rank,
  "OriginalSeedColumnCount"->c,"GenericRankWitness"->witness,
  "KnownAmplitudeRows"->OptionValue["KnownAmplitudeRows"],
  "Scope"->"Only the coefficients justified by the supplied physical integral definitions and the specified primary exponent are matched."|>
 ],"BoundaryIntegration"];

FeynFacet`ReduceIdenticalBoundaryIntegrals::usage="ReduceIdenticalBoundaryIntegrals[equations,definitions,epsilon,opts] derives exact amplitude relations from declared identical integration measures/integrands and their rational scale ratios, selecting independent equations at a rational regulator value.";
Options[FeynFacet`ReduceIdenticalBoundaryIntegrals]={"GenericRankWitness"->Automatic,"InitialAmplitudeRows"->{}};
FeynFacet`ReduceIdenticalBoundaryIntegrals[equations_Association,definitions_Association,eps_Symbol,OptionsPattern[]] :=
 Catch[Module[{witness=OptionValue["GenericRankWitness"],rows=OptionValue["InitialAmplitudeRows"],
  sampleRows,rank=0,leading,profiles=<||>,relations={},def,key,scale,anchor,ratio,q,sample,next,clean},
 clean[x_]:=Cancel[Together[x]];
 If[witness===Automatic,witness=eps->1/97];
 leading=Association[(#["OriginalRow"]->#["AmplitudeRow"])&/@equations["LeadingCoefficientRows"]];
 sampleRows=rows/.witness;If[sampleRows=!={},rank=MatrixRank[sampleRows]];
 Do[
  def=definitions[row];If[!KeyExistsQ[def,"IntegralEquivalenceKey"]||!KeyExistsQ[def,"IntegralScaleFactor"],Continue[]];
  key=def["IntegralEquivalenceKey"];scale=def["IntegralScaleFactor"];q=leading[row];
  If[KeyExistsQ[profiles,key],
   anchor=profiles[[Key[key]]];ratio=clean[scale/anchor["IntegralScaleFactor"]];
   If[!AllTrue[NumeratorDenominator[ratio],PolynomialQ[#,eps]&],Continue[]];
   q=clean/@(q-ratio anchor["AmplitudeRow"]);sample=clean[#/.witness]&/@q;
   If[!VectorQ[sample,NumberQ],boundaryIntegrationFail["AmplitudeRankSpecializationInvalid"]];
   next=If[sampleRows==={},If[AllTrue[sample,#===0&],0,1],MatrixRank[Append[sampleRows,sample]]];
   If[next>rank,rank=next;AppendTo[sampleRows,sample];
    AppendTo[relations,<|"OriginalRows"->{row,anchor["OriginalRow"]},
     "AmplitudeRow"->q,"IntegralScaleRatio"->ratio,"IntegralEquivalenceKey"->key|>]],
   AssociateTo[profiles,key-><|"OriginalRow"->row,"IntegralScaleFactor"->scale,"AmplitudeRow"->q|>]],
  {row,Intersection[Keys[definitions],Keys[leading]]}];
 <|"DataType"->"IdenticalBoundaryIntegralRelations","AmplitudeRelations"->relations,
   "RankIncludingInitialRows"->rank,"IntegralRepresentatives"->profiles,"GenericRankWitness"->witness|>
 ],"BoundaryIntegration"];

FeynFacet`MatchVanishingPrimaryCoefficients::usage="MatchVanishingPrimaryCoefficients[expansion,gauge,definitions,opts] derives zero amplitude rows when a proved large-real-D physical bound excludes the entire primary exponent. A zero truncated observation never establishes absence of a mode.";
Options[FeynFacet`MatchVanishingPrimaryCoefficients]={"GenericRankWitness"->Automatic};
FeynFacet`MatchVanishingPrimaryCoefficients[expansion_Association,gauge_,definitions_Association,OptionsPattern[]] :=
 Catch[Module[{z=expansion["Variable"],eps=expansion["DimensionalRegulator"],coeff=expansion["Coefficients"],
 eigenvalue=expansion["ResidueEigenvalue"],order=expansion["MaximumNormalOrder"],
 logs=expansion["MaximumLogarithmPower"],g=Normal[gauge],witness=OptionValue["GenericRankWitness"],
 clean,valuation,def,difference,lower,local,q,rec,sampleRows={},sample,rank=0,next,relations={},eligible={}},
 clean[x_]:=Cancel[Together[x]];
 valuation[x_]:=If[x===0,Infinity,With[{nd=NumeratorDenominator[clean[x]]},
   If[!AllTrue[nd,PolynomialQ[#,z]&],boundaryIntegrationFail["RationalNormalGaugeRequired"]];
   Exponent[nd[[1]],z,Min]-Exponent[nd[[2]],z,Min]]];
 If[witness===Automatic,witness=eps->1/97];
 Do[
  def=definitions[row];
  If[!TrueQ[Lookup[def,"PhysicalLimitEstablished",False]]||
    !KeyExistsQ[def,"LargeDimensionConvergenceDomain"],Continue[]];
  difference=clean[def["NormalExponent"]-eigenvalue];
  If[!PolynomialQ[difference,eps]||Exponent[difference,eps]>1||
    !TrueQ[Coefficient[difference,eps,1]<0],Continue[]];
  AppendTo[eligible,row];lower=Min[valuation/@g[[row]]];If[lower===Infinity,Continue[]];
  local=Table[clean[SeriesCoefficient[#,{z,0,k}]]&/@g[[row]],{k,lower,lower+order}];
  Do[
   q=clean/@Total[Table[local[[k-lower+1]].coeff[[power-k+1,l+1]],{k,lower,power}]];
   sample=clean[#/.witness]&/@q;If[!VectorQ[sample,NumberQ],boundaryIntegrationFail["AmplitudeRankSpecializationInvalid"]];
   next=MatrixRank[Append[sampleRows,sample]];
   If[next>rank,rank=next;AppendTo[sampleRows,sample];
    AppendTo[relations,<|"OriginalRow"->row,"IntegerNormalPower"->power,"LogarithmPower"->l,
      "AmplitudeRow"->q,"PhysicalBoundExponent"->def["NormalExponent"],
      "ExcludedPrimaryExponent"->eigenvalue|>]],
   {power,lower,lower+order},{l,0,logs}],
 {row,Keys[definitions]}];
 <|"DataType"->"VanishingPrimaryCoefficientRelations","AmplitudeRelations"->relations,
 "IndependentEquationCount"->rank,"EligiblePhysicalRows"->eligible,"GenericRankWitness"->witness,
 "Scope"->"The physical bound grows faster than this primary exponent as real D increases. Each stored nonzero coefficient must vanish; no conclusion is inferred from a zero finite truncation."|>
 ],"BoundaryIntegration"];
End[];
