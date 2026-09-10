(* Local Fuchsian normalization over rational functions of the regulator.
   The returned finite gauge factors mean I=T1.T2...Tq.J. No solution
   generator or truncated kinematic series is used. *)
Clear[NormalizeRegularSingularSystem];
ClearAll[localNormalizeMatrix,localNormalizeResidue,localNormalizePoleOrder,
 localNormalizeSpectralProjector,localNormalizeDiagonalBlock];
localNormalizeMatrix[a_] := Map[Cancel[Together[#]]&,Normal[a],{2}];
localNormalizePoleOrder[a_,z_] := Module[{orders},
 orders=DeleteCases[Flatten[Map[boundaryLocalOrder[#,z]&,a,{2}]],Infinity];
 If[MemberQ[orders,$Failed],Return[$Failed]];
 If[orders==={},0,Max[0,-Min[orders]]]];
localNormalizeResidue[a_,z_] := localNormalizeMatrix[Map[
 Function[x,If[x===0,0,Cancel[z x]/.z->0]],a,{2}]];
localNormalizeSpectralProjector[r_,e_,choose_] := Module[
 {x=Unique["eigenvalue"],poly,factors,selected={},other={},lambda,integer,
  f,g,bezout,p,coefficients,n=Length[r],answer},
 poly=Numerator[Together[CharacteristicPolynomial[r,x]]];
 factors=Select[FactorList[poly],Exponent[First[#],x]>0&];
 Do[
  If[Exponent[First[q],x]=!=1,Return[Failure["NonlinearResidueFactor",<||>],Module]];
  lambda=Cancel[-Coefficient[First[q],x,0]/Coefficient[First[q],x,1]];
  integer=Cancel[lambda/.e->0];
  If[!IntegerQ[integer],Return[Failure["NonintegerUnregulatedExponent",
    <|"Exponent"->lambda|>],Module]];
  If[TrueQ[choose[integer]],AppendTo[selected,q],AppendTo[other,q]],{q,factors}];
 If[selected==={},Return[ConstantArray[0,{n,n}]]];
 If[other==={},Return[IdentityMatrix[n]]];
 f=Times@@(First[#]^Last[#]&/@selected);g=Times@@(First[#]^Last[#]&/@other);
 bezout=PolynomialExtendedGCD[f,g,x];
 p=PolynomialRemainder[bezout[[2,2]] g/bezout[[1]],f g,x];
 coefficients=CoefficientList[p,x];answer=ConstantArray[0,{n,n}];
 Do[answer=localNormalizeMatrix[answer.r+coefficients[[k]] IdentityMatrix[n]],
  {k,Length[coefficients],1,-1}];
 answer];

(* An Euler-derivative cyclic vector supplies a companion frame. Accept it
   only if its exact transformed connection is Fuchsian. Failure of this
   finite set of cyclic vectors makes no irregularity/nonexistence claim. *)
localNormalizeCyclicGauge[a_,z_] := Module[
 {n=Length[a],candidates,rows,row,c,ci,b,result=None},
 candidates=Join[IdentityMatrix[n],{ConstantArray[1,n],Range[n]}];
 Do[
  rows={candidate};row=candidate;
  Do[row=Cancel/@(z D[row,z]+z row.a);AppendTo[rows,row],{n-1}];
  c=rows;If[TrueQ[Cancel[Det[c]]===0],Continue[]];
  ci=localNormalizeMatrix[Inverse[c]];
  b=localNormalizeMatrix[c.a.ci+D[c,z].ci];
  If[localNormalizePoleOrder[b,z]<=1,
   result=<|"Gauge"->ci,"InverseGauge"->c,"Connection"->b|>;Break[]],
 {candidate,candidates}];
 result
];

localNormalizeDiagonalBlock[a_,z_,e_,limit_] := Catch@Module[
 {b=localNormalizeMatrix[a],n=Length[a],data,g,gi,p,t,ti,r,sign,steps=0,
  zero=ConstantArray[0,{Length[a],Length[a]}],factors={}},
 data=boundaryBlockDiagonalGauge[b,z];
 If[data===None,
  data=localNormalizeCyclicGauge[b,z];
  If[data===None,Throw[Failure["LocalFuchsianGaugeNotFound",
   <|"Methods"->{"DiagonalPowers","EulerCyclicVectors"}|>]]];
  {g,gi,b}=Lookup[data,{"Gauge","InverseGauge","Connection"}],
  g=DiagonalMatrix[z^(-data["DiagonalPowers"])];
  gi=DiagonalMatrix[z^data["DiagonalPowers"]];
  b=localNormalizeMatrix[gi.b.g-gi.D[g,z]]];
 If[g=!=IdentityMatrix[n],AppendTo[factors,<|"Matrix"->g,"Inverse"->gi|>]];
 Do[
  While[True,
   r=localNormalizeResidue[b,z];
   p=localNormalizeSpectralProjector[r,e,If[sign===1,(#>0&),(#<0&)]];
   If[FailureQ[p],Throw[p]];If[p===zero,Break[]];
   steps++;If[steps>limit,Throw[Failure["LocalNormalizationStepLimit",<||>]]];
   t=IdentityMatrix[n]+(z^sign-1)p;
   ti=IdentityMatrix[n]+(z^(-sign)-1)p;
   b=localNormalizeMatrix[ti.b.t-ti.D[t,z]];
   g=localNormalizeMatrix[g.t];gi=localNormalizeMatrix[ti.gi];
   AppendTo[factors,<|"Matrix"->t,"Inverse"->ti|>];
   If[localNormalizePoleOrder[b,z]>1,
     Throw[Failure["SpectralShiftLostFuchsianForm",<||>]]]],
  {sign,{1,-1}}];
 <|"Connection"->b,"Gauge"->g,"InverseGauge"->gi,
   "Residue"->localNormalizeResidue[b,z],"Factors"->factors|>
];

Options[NormalizeRegularSingularSystem]={"MaximumNormalizationSteps"->64,
 "VerificationPoints"->Automatic,"ParameterVerificationRules"->{},"Verbose"->False};
NormalizeRegularSingularSystem[system_Association,OptionsPattern[]] := Catch@Module[
 {a,z,e,n,positions,components,order,remaining,ready,rows,blockCount,
  blockOf,connections=<||>,gauges,inverses,residues,diag,fail,progress,
  i,j,p,k,c,x,op,ni,nj,s,old,updates,factors={},firstGauge,firstInverse,
  initial,original,final,fullResidue,pointRules,parameterRules,checks={},low,nonzero,sampleStarted,
  steps,maxSteps=OptionValue["MaximumNormalizationSteps"]},
 fail[tag_,data_:<||>]:=Throw[Failure[tag,data]];
 progress[t_]:=If[TrueQ[OptionValue["Verbose"]],Print[t]];
 z=Lookup[system,"Variable",None];e=Lookup[system,"DimensionalRegulator",None];
 a=localNormalizeMatrix[Lookup[system,"ConnectionMatrix",{}]];n=Length[a];
 If[!MatchQ[z,_Symbol]||!MatchQ[e,_Symbol]||z===e||n===0||
   Dimensions[a]=!={n,n},fail["UnivariateDifferentialSystemRequired"]];
 If[!AllTrue[Flatten[a],PolynomialQ[Numerator[#],{z,e}]&&
   PolynomialQ[Denominator[#],{z,e}]&],fail["RationalNormalConnectionRequired"]];
 positions=Position[a,value_/;value=!=0,{2},Heads->False];
 components=ConnectedComponents[Graph[Range[n],DirectedEdge@@#&/@positions]];
 remaining=Range[Length[components]];order={};
 While[remaining=!={},
  ready=Select[remaining,Function[q,AllTrue[positions,Function[pos,
    !MemberQ[components[[q]],First[pos]]||MemberQ[components[[q]],Last[pos]]||
      !MemberQ[Flatten[components[[remaining]]],Last[pos]]]]]];
  If[ready==={},fail["BlockDependencyOrderingFailed"]];
  order=Join[order,ready];remaining=Complement[remaining,ready]];
 rows=components[[order]];blockCount=Length[rows];
 progress["Normalizing "<>ToString[blockCount]<>" diagonal blocks."];
 diag=Table[
  progress["Normalizing diagonal rows "<>ToString[rr,InputForm]<>"."];
  old=localNormalizeDiagonalBlock[a[[rr,rr]],z,e,maxSteps];
  If[FailureQ[old],fail["DiagonalLocalNormalizationFailed",<|"Rows"->rr,"Cause"->old|>]];
  old,{rr,rows}];
 gauges=Lookup[diag,"Gauge"];inverses=Lookup[diag,"InverseGauge"];
 residues=Lookup[diag,"Residue"];
 firstGauge=IdentityMatrix[n];firstInverse=IdentityMatrix[n];
 Do[firstGauge[[rows[[i]],rows[[i]]]]=gauges[[i]];
    firstInverse[[rows[[i]],rows[[i]]]]=inverses[[i]],{i,blockCount}];
 AppendTo[factors,<|"Type"->"BlockDiagonal","Rows"->rows,
   "Matrices"->gauges,"InverseMatrices"->inverses|>];
 Do[
  old=a[[rows[[i]],rows[[j]]]];
  If[i===j,AssociateTo[connections,{i,j}->diag[[i]]["Connection"]],
   If[!AllTrue[Flatten[old],#===0&],
    AssociateTo[connections,{i,j}->localNormalizeMatrix[inverses[[i]].old.gauges[[j]]]]]],
  {i,blockCount},{j,i}];
 Do[
  i=j+distance;
  If[!KeyExistsQ[connections,{i,j}],Continue[]];
  ni=Length[rows[[i]]];nj=Length[rows[[j]]];
  steps=0;
  While[True,
  old=connections[[Key[{i,j}]]];p=localNormalizePoleOrder[old,z];
   If[p===$Failed,fail["LocalPoleOrderUndetermined",<|"Rows"->rows[[i]],"Columns"->rows[[j]]|>]];
  If[p<=1,Break[]];k=p-1;steps++;
   progress["Removing normal pole order "<>ToString[p]<>" between rows "<>
     ToString[rows[[i]],InputForm]<>" and "<>ToString[rows[[j]],InputForm]<>"."];
   If[steps>maxSteps,fail["OffDiagonalLocalNormalizationStepLimit"]];
   c=localNormalizeMatrix[Map[Cancel[z^p #]/.z->0&,old,{2}]];
   op=KroneckerProduct[residues[[i]],IdentityMatrix[nj]]-
      KroneckerProduct[IdentityMatrix[ni],Transpose[residues[[j]]]]+
      k IdentityMatrix[ni nj];
   x=Quiet[Check[Partition[LinearSolve[op,-Flatten[c]],nj],$Failed]];
   If[x===$Failed||!MatrixQ[x],fail["SingularLocalSylvesterEquation",
     <|"Rows"->rows[[i]],"Columns"->rows[[j]],"PoleOrder"->p|>]];
   x=localNormalizeMatrix[x];s=z^(-k)x;
   updates=<||>;
   Do[
    If[KeyExistsQ[connections,{h,i}],
     AssociateTo[updates,{h,j}->localNormalizeMatrix[connections[[Key[{h,i}]]].s]]],
    {h,i,blockCount}];
   Do[
    If[KeyExistsQ[connections,{j,h}],
     c=localNormalizeMatrix[-s.connections[[Key[{j,h}]]]];
     AssociateTo[updates,{i,h}->(Lookup[updates,Key[{i,h}],ConstantArray[0,Dimensions[c]]]+c)]],
    {h,j}];
   AssociateTo[updates,{i,j}->(updates[[Key[{i,j}]]]+k z^(-k-1)x)];
   KeyValueMap[Function[{key,value},
     old=Lookup[connections,Key[key],ConstantArray[0,Dimensions[value]]];
     AssociateTo[connections,key->localNormalizeMatrix[old+value]]],updates];
   AppendTo[factors,<|"Type"->"OffDiagonal","Rows"->rows[[i]],"Columns"->rows[[j]],
    "Power"->-k,"Matrix"->x|>];
   If[localNormalizePoleOrder[connections[[Key[{i,j}]]],z]>=p,
    fail["LocalPoleCancellationFailed",<|"Rows"->rows[[i]],"Columns"->rows[[j]]|>]]],
  {distance,1,blockCount-1},{j,1,blockCount-distance}];
 final=ConstantArray[0,{n,n}];
 KeyValueMap[Function[{key,value},final[[rows[[key[[1]]]],rows[[key[[2]]]]]]=value],connections];
 fullResidue=localNormalizeResidue[final,z];
 If[localNormalizePoleOrder[final,z]>1,fail["FullConnectionNotFuchsian"]];
 pointRules=Replace[OptionValue["VerificationPoints"],Automatic->{
   {z->2/17,e->1/97},{z->3/19,e->2/101}}];
 parameterRules=OptionValue["ParameterVerificationRules"];
 If[!MatchQ[parameterRules,{Rule[_Symbol,_]...}] ||
   !DuplicateFreeQ[First/@parameterRules] ||
   !FreeQ[Last/@parameterRules,_Real] || !AllTrue[Last/@parameterRules,NumericQ] ||
   MemberQ[First/@parameterRules,z] || MemberQ[First/@parameterRules,e] ||
   !AllTrue[pointRules,Intersection[First/@#,First/@parameterRules]==={}&],
  fail["ExactIndependentParameterVerificationRulesRequired"]];
 pointRules=Join[#,parameterRules]&/@pointRules;
 Do[
  progress["Verifying the composed normal gauge at "<>ToString[point,InputForm]<>"."];
  sampleStarted=AbsoluteTime[];
  original=a/.point;initial=firstGauge/.point;
  original=(firstInverse/.point).(original.initial-(D[firstGauge,z]/.point));
  Do[
   s=(z^factor["Power"] factor["Matrix"])/.point;
   c=(factor["Power"] z^(factor["Power"]-1) factor["Matrix"])/.point;
   original[[All,factor["Columns"]]]+=original[[All,factor["Rows"]]].s;
   original[[factor["Rows"],All]]-=s.original[[factor["Columns"],All]];
   original[[factor["Rows"],factor["Columns"]]]-=c,
   {factor,Rest[factors]}];
  (* Parameters such as a tangential scattering variable can remain
     symbolic at these normal-coordinate/regulator samples. Canonicalize
     the rational residual before testing exact zero. *)
  AppendTo[checks,AllTrue[Flatten[localNormalizeMatrix[original-(final/.point)]],#===0&]];
  progress["Finished the exact rational sample check in "<>
    ToString[N[AbsoluteTime[]-sampleStarted],InputForm]<>" seconds."],
  {point,pointRules}];
 If[!And@@checks,fail["LocalGaugeVerificationFailed",<|"Checks"->checks|>]];
 <|"DataType"->"NormalizedRegularSingularSystem","SchemaVersion"->1,
  "Variable"->z,"DimensionalRegulator"->e,"Dimension"->n,
  "ConnectionMatrix"->final,"Residue"->fullResidue,
  "BlockRows"->rows,"DiagonalResidues"->residues,"GaugeFactors"->factors,
  "GaugeConvention"->"Original solution = ordered product of GaugeFactors times normalized solution.",
  "Verification"-><|"Method"->"ExactRationalPoints","ExactIdentity"->False,
    "ParameterVerificationRules"->parameterRules,"Points"->pointRules,"Checks"->checks|>|>
];

(* Primary decomposition of a block-triangular residue. Generalized
   eigenspaces are retained in full; no numerical eigenvector matching. *)
Clear[DecomposeResidueEigenspaces];
DecomposeResidueEigenspaces[record_Association] := Catch@Module[
 {r=record["Residue"],e=record["DimensionalRegulator"],rows=record["BlockRows"],
  n=record["Dimension"],x=Unique["eigenvalue"],diag,small,values,cols,counts,
  s=IdentityMatrix[record["Dimension"]],si,indices={},eigenvalues={},
  blocks={},cursor,transformed,rr,ni,nj,op,c,t,steps={},original,
  check,groups,point=Join[{record["DimensionalRegulator"]->1/97},
   Lookup[Lookup[record,"Verification",<||>],"ParameterVerificationRules",{}]],i,j,group,offset},
 Do[
  small=r[[rr,rr]];
  values=DeleteDuplicates[(-Coefficient[#[[1]],x,0]/Coefficient[#[[1]],x,1])&/@
    Select[FactorList[Numerator[Together[CharacteristicPolynomial[small,x]]]],
      Exponent[First[#],x]===1&]];
  cols=Table[NullSpace[MatrixPower[small-lambda IdentityMatrix[Length[rr]],Length[rr]]],
    {lambda,values}];
  counts=Length/@cols;
  If[Total[counts]=!=Length[rr],Throw[Failure["ResiduePrimaryDecompositionIncomplete",<|"Rows"->rr|>]]];
  s[[rr,rr]]=Transpose[Join@@cols];
  offset=0;
  Do[AppendTo[indices,Take[rr,{offset+1,offset+counts[[k]]}]];
    AppendTo[eigenvalues,values[[k]]];offset+=counts[[k]],{k,Length[values]}],
  {rr,rows}];
 si=localNormalizeMatrix[Inverse[s]];
 transformed=localNormalizeMatrix[si.r.s];original=transformed;
 (* The primary subblocks of one original diagonal block are already
    decoupled. All remaining nonzero unequal-eigenvalue couplings point
    from an earlier original block to a later one. *)
 Do[
  i=j+distance;
  If[eigenvalues[[i]]===eigenvalues[[j]],Continue[]];
  c=transformed[[indices[[i]],indices[[j]]]];
  If[AllTrue[Flatten[c],#===0&],Continue[]];
  ni=Length[indices[[i]]];nj=Length[indices[[j]]];
  op=KroneckerProduct[transformed[[indices[[i]],indices[[i]]]],IdentityMatrix[nj]]-
     KroneckerProduct[IdentityMatrix[ni],Transpose[transformed[[indices[[j]],indices[[j]]]]]];
  t=Quiet@Check[Partition[LinearSolve[op,-Flatten[c]],nj],$Failed];
  If[t===$Failed,Throw[Failure["UnequalExponentSylvesterEquationFailed",<||>]]];
  t=localNormalizeMatrix[t];
  transformed[[All,indices[[j]]]]=localNormalizeMatrix[
    transformed[[All,indices[[j]]]]+transformed[[All,indices[[i]]]].t];
  transformed[[indices[[i]],All]]=localNormalizeMatrix[
    transformed[[indices[[i]],All]]-t.transformed[[indices[[j]],All]]];
  s[[All,indices[[j]]]]=localNormalizeMatrix[s[[All,indices[[j]]]]+s[[All,indices[[i]]]].t];
  si[[indices[[i]],All]]=localNormalizeMatrix[si[[indices[[i]],All]]-t.si[[indices[[j]],All]]];
  AppendTo[steps,<|"Rows"->indices[[i]],"Columns"->indices[[j]],"Matrix"->t|>],
  {distance,1,Length[indices]-1},{j,1,Length[indices]-distance}];
 values=DeleteDuplicates[eigenvalues];
 groups=Table[
  rr=Join@@indices[[Select[Range[Length[eigenvalues]],eigenvalues[[#]]===lambda&]]];
  <|"Exponent"->lambda,"Columns"->rr,
    "NilpotentPart"->localNormalizeMatrix[transformed[[rr,rr]]-lambda IdentityMatrix[Length[rr]]]|>,
  {lambda,values}];
 check=And[Total[Length/@Lookup[groups,"Columns"]]===n,
  AllTrue[Flatten[(r/.point).(s/.point)-(s/.point).(transformed/.point)],#===0&],
  AllTrue[Flatten[(si/.point).(s/.point)-IdentityMatrix[n]],#===0&]];
 If[!check,Throw[Failure["ResiduePrimaryDecompositionVerificationFailed",<||>]]];
 <|"DataType"->"ResiduePrimaryDecomposition","SchemaVersion"->1,
   "DimensionalRegulator"->e,"BasisTransformationMatrix"->s,
   "InverseBasisTransformationMatrix"->si,"ResidueInPrimaryBasis"->transformed,
   "Eigenspaces"->groups,
   "LocalPrimaryBlockColumns"->indices,"LocalPrimaryBlockExponents"->eigenvalues,
   "Verification"-><|"Method"->"ExactRationalPoint","Point"->point,"Passed"->check|>|>
];

Clear[RegularSingularGaugeMatrix,RegularSingularInverseGaugeMatrix,
 RemoveCoalescingApparentSingularities];
Clear[localNormalizeCoalescingDivisors];
localNormalizeCoalescingDivisors[matrix_,z_,e_] := Module[
 {denominators,factors},
 denominators=DeleteDuplicates[Denominator /@
   DeleteCases[Flatten[Normal[matrix]],0]];
 factors=DeleteDuplicates[Flatten[
   (First/@Rest[FactorList[#]])&/@denominators]];
 Select[factors,!FreeQ[#,z]&&!FreeQ[#,e]&&
   TrueQ[(#/.{z->0,e->0})===0]&]
];
RegularSingularGaugeMatrix[record_Association] := Module[
 {z=record["Variable"],n=record["Dimension"],g=IdentityMatrix[record["Dimension"]]},
 Do[
  Switch[f["Type"],
   "BlockDiagonal",
    Do[g[[All,f["Rows"][[i]]]]=localNormalizeMatrix[
      g[[All,f["Rows"][[i]]]].f["Matrices"][[i]]],{i,Length[f["Rows"]]}],
   "OffDiagonal",
    g[[All,f["Columns"]]]=localNormalizeMatrix[g[[All,f["Columns"]]]+
      g[[All,f["Rows"]]].(z^f["Power"] f["Matrix"])],
   _,Return[Failure["UnrecognizedLocalGaugeFactor",<||>],Module]],
   {f,record["GaugeFactors"]}];
 g];

(* Compose the inverse from the exact inverse factors already constructed.
   A disjoint off-diagonal block shear has square zero, so its inverse
   changes only the sign. Left multiplication reverses the product order. *)
RegularSingularInverseGaugeMatrix[record_Association] := Module[
 {z=record["Variable"],g=IdentityMatrix[record["Dimension"]]},
 Do[
  Switch[f["Type"],
   "BlockDiagonal",
    Do[g[[f["Rows"][[i]],All]]=localNormalizeMatrix[
      f["InverseMatrices"][[i]].g[[f["Rows"][[i]],All]]],
      {i,Length[f["Rows"]]}],
   "OffDiagonal",
    If[Intersection[f["Rows"],f["Columns"]]=!={},
      Return[Failure["OverlappingLocalGaugeShearUnsupported",<||>],Module]];
    g[[f["Rows"],All]]=localNormalizeMatrix[g[[f["Rows"],All]]-
      (z^f["Power"] f["Matrix"]).g[[f["Columns"],All]]],
   _,Return[Failure["UnrecognizedLocalGaugeFactor",<||>],Module]],
   {f,record["GaugeFactors"]}];
 g];

Options[RemoveCoalescingApparentSingularities]={"Verbose"->False,"ParameterVerificationRules"->{}};
RemoveCoalescingApparentSingularities[system_Association,OptionsPattern[]] := Catch@Module[
 {z=system["Variable"],e=system["DimensionalRegulator"],
  a=localNormalizeMatrix[system["ConnectionMatrix"]],factors,locations={},
  q,xp,rho=Unique["localCoordinate"],allFactors={},converted,steps=0,selected,
  progress,initial=system["ConnectionMatrix"],n,normalizationChecks={}},
 n=Length[a];progress[t_]:=If[TrueQ[OptionValue["Verbose"]],Print[t]];
 While[True,
  factors=localNormalizeCoalescingDivisors[a,z,e];
  If[factors==={},Break[]];
  selected=SelectFirst[factors,Exponent[#,z]===1&,None];
  If[selected===None,Throw[Failure["NonlinearCoalescingDivisor",
    <|"Factors"->factors|>]]];
  xp=Cancel[-Coefficient[selected,z,0]/Coefficient[selected,z,1]];
  If[!TrueQ[(xp/.e->0)===0],Throw[Failure["CoalescingPointLimitUndetermined",<||>]]];
  steps++;If[steps>16,Throw[Failure["CoalescingPoleRemovalDidNotTerminate",<||>]]];
  progress["Removing the apparent singularity at "<>ToString[xp,InputForm]<>"."];
  q=NormalizeRegularSingularSystem[<|"Variable"->rho,"DimensionalRegulator"->e,
   "ConnectionMatrix"->localNormalizeMatrix[a/.z->rho+xp]|>,
   "VerificationPoints"->{{rho->1/13,e->1/97},{rho->1/17,e->2/101}},
   "ParameterVerificationRules"->OptionValue["ParameterVerificationRules"],
   "Verbose"->OptionValue["Verbose"]];
  If[FailureQ[q],Throw[q]];
  If[!AllTrue[Flatten[q["Residue"]],#===0&],
    Throw[Failure["CoalescingSingularityNotRemoved",
      <|"Location"->xp,"RemainingResidue"->q["Residue"]|>]]];
  AppendTo[normalizationChecks,<|"Location"->xp,"Verification"->q["Verification"]|>];
  converted=Map[Function[f,Switch[f["Type"],
    "BlockDiagonal",f/.rho->z-xp,
    "OffDiagonal",Join[f,<|"Matrix"->(z-xp)^f["Power"] f["Matrix"],"Power"->0|>],
    _,f]],q["GaugeFactors"]];
  allFactors=Join[allFactors,converted];AppendTo[locations,xp];
  progress["Re-expressing the normalized connection in the original normal coordinate."];
  a=localNormalizeMatrix[q["ConnectionMatrix"]/.rho->z-xp];
  progress["Finished re-expressing the normalized connection."]];
 <|"DataType"->"CoalescingApparentSingularitiesRemoved","SchemaVersion"->1,
  "Variable"->z,"DimensionalRegulator"->e,"Dimension"->n,
  "ConnectionMatrix"->a,"RemovedLocations"->locations,
  "NormalizationVerifications"->normalizationChecks,
  "GaugeFactors"->allFactors,
  "Convention"->"Original solution = RegularSingularGaugeMatrix[result].new solution.",
  "Scope"->"Only singularities with zero residue after integer-exponent normalization are removed."|>
];
