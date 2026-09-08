
(* SubTropica is optional and loaded only when an Euler integral needs it. *)
Begin["FeynFacet`Private`"];

(* HyperFLINT's mzv tokens use the vendor's multiple-zeta convention.
   System Zeta with two arguments is the Hurwitz zeta function, and with
   three arguments is invalid. Never decode these tokens as System Zeta. *)
boundaryHyperFlintMzvToken[token_String] := Module[{parts},
 If[!StringMatchQ[token,RegularExpression["mzv(?:_m?\\d+)+"]],Return[token]];
 parts=Rest[StringSplit[token,"_"]];
 parts=If[StringStartsQ[#,"m"],"-"<>StringDrop[#,1],#]&/@parts;
 "HyperIntica`mzv["<>StringRiffle[parts,","]<>"]"
];


(* On the real negative dilogarithm axis, this functional identity has no
   branch ambiguity. It also cancels spurious contour-sign placeholders
   introduced by partial fractions of a positive Euler integral. *)
boundarySimplifyHyperlogConstants[input_] := Module[{value=input,normalizeLogs},
 normalizeLogs[x_]:=x//.{
  HyperIntica`Hlog[1,{0,a_}]/;MatchQ[a,_Integer|_Rational]&&a<0:>
    -HyperIntica`Hlog[1,{0,1-a}]+Log[1-1/a]^2/2,
  Log[q_]/;MatchQ[q,_Integer|_Rational]&&q>0:>
    Total[(Last[#]Log[First[#]])&/@FactorInteger[q]],
  Log[q_Times]/;AllTrue[List@@q,NumericQ[#]&&TrueQ[#>0]&]:>Total[Log/@List@@q]};
 If[Head[value]===SeriesData,value[[3]]=Expand[normalizeLogs[#]]&/@value[[3]],
  value=Expand[normalizeLogs[value]]];
 value
];
decodeBoundaryHyperlogResult[input_,vars_,eps_,high_,dir_] := Catch[Module[
 {raw=input,result,unresolved,ep=SubTropica`eps},
 raw=raw/.SubTropica`zeta->HyperIntica`mzv;
 If[!FreeQ[raw,Alternatives@@vars],raw=boundarySimplifyHyperlogConstants[raw]];
 unresolved=Cases[raw,call_/;MemberQ[
   {"STHyperFlint","STHyperForm","HyperInt","STIntegrate","STExpandIntegral","STwrapError","NOLR"},
   SymbolName[Head[call]]],{0,Infinity}];
 If[unresolved=!={}||!FreeQ[raw,_Symbol?(SymbolName[#]==="NOLR"&)]||!FreeQ[raw,$Failed|$Aborted|_Failure|_SubTropica`STIntegrate|Indeterminate|_DirectedInfinity]||
    !FreeQ[raw,Alternatives@@vars],
   boundaryIntegrationFail["SubTropicaBoundaryIntegralUnresolved",<|"Result"->Short[raw,3],"ScratchDirectory"->dir|>]];
 If[Head[raw]===SeriesData&&raw[[5]]/raw[[6]]<=high,
   boundaryIntegrationFail["SubTropicaReturnedInsufficientOrders"]];
 If[Head[raw]===SeriesData,
  epsilonAuditMultiplier[1,raw[[1]],raw[[4]]/raw[[6]],raw[[5]]/raw[[6]]-1,high,
    "Stage3/SubTropicaResultOrders","EulerIntegral"]];
 (* Translate vendor output immediately to the package's standard GPL
    convention. The vendor's multi-index mzv notation uses reversed indices;
    its own MplAsHlog conversion avoids exporting that convention. *)
 result=Block[{HyperIntica`$HyperEvaluatePeriods=True},
   raw/.HyperIntica`Hlog[1,word_List]/;(word=!={}&&First[word]=!=1&&Last[word]=!=0&&
     SubsetQ[{-1,0,1},Union[word]]):>HyperIntica`ZeroOnePeriod[word]];
 result=result//.If[AssociationQ[HyperIntica`mzvAllReductions],
   Normal[HyperIntica`mzvAllReductions],HyperIntica`mzvAllReductions];
 result=result/.HyperIntica`mzv[k_Integer]/;k>1:>Zeta[k];
 result=result/.HyperIntica`mzv[indices__Integer]:>
   HyperIntica`MplAsHlog[Abs/@{indices},Sign/@{indices}];
 result=result/.HyperIntica`Hlog[point_,word_List]:>FeynFacetSolution`G[word,point];
 result=result/.ep->eps;
 If[!FreeQ[result,_HyperIntica`Hlog|_HyperIntica`mzv|_SubTropica`zeta|_HyperIntica`Mpl|_HyperIntica`delta],
  boundaryIntegrationFail["UnconvertedHyperlogarithmFunction"]];

 <|"Expression"->result,"IntegrationBackend"->"SubTropicaHyperFLINT"|>
],"BoundaryIntegration"];

integrateBoundaryWithSubTropica[expr_,vars_,eps_,high_,source_,scratch_,verbose_] :=
 Block[{$Context=$Context,$ContextPath=$ContextPath},Catch[Module[
 {path=source,dir=scratch,automatic=scratch===Automatic,old=Directory[],st,ep,
  newVariables,substitution,jacobian,pulled,raw,result,options,method,loadDirectory,unresolved},
 If[path===Automatic,path=FileNameJoin[{$feynFacetRoot,"Addon","Mathematica_Addon","SubTropica","SubTropica.wl"}]];
 If[!StringQ[path]||!FileExistsQ[path],boundaryIntegrationFail["SubTropicaUnavailable",<|"Path"->path|>]];
 loadDirectory=DirectoryName[path];
 If[Length[DownValues[SubTropica`STIntegrate]]===0,
  Block[{$Path=Prepend[$Path,loadDirectory]},Get[path]]];
 If[Length[DownValues[SubTropica`STIntegrate]]===0,boundaryIntegrationFail["SubTropicaLoadFailed"]];
 ep=SubTropica`eps;
 (* Do the unit-cube substitution here. SubTropica 1.2.9 creates symbols
    containing $, which the installed HyperFLINT parser does not accept. *)
 newVariables=Table[Symbol["FeynFacetEulerVariables`x"<>ToString[j]],{j,Length[vars]}];
 substitution=Thread[vars->(#/(1+#)&/@newVariables)];
 jacobian=Times@@((1+#)^-2&/@newVariables);
 pulled=(expr/.eps->ep/.substitution)jacobian;
 If[dir===Automatic,dir=CreateDirectory[]];
 If[!StringQ[dir]||!DirectoryQ[dir],boundaryIntegrationFail["BoundaryScratchDirectoryRequired"]];
 raw=Internal`WithLocalSettings[
  SetDirectory[dir],
  Internal`InheritedBlock[{SubTropica`STHyperFlint,SubTropica`stMzvTokenToZeta},
   Clear[SubTropica`stMzvTokenToZeta];
   SubTropica`stMzvTokenToZeta[token_String] := boundaryHyperFlintMzvToken[token];
   Unprotect[SubTropica`STHyperFlint];
   (* The upstream zero-dimensional-face sentinel denotes the identity.
      Its BruteForce list fallback otherwise leaves an unevaluated call. *)
   SubTropica`STHyperFlint[constant_,"no_integration_required",___Rule] := constant;
   SubTropica`STIntegrate[pulled,Sequence@@({#,0,Infinity}&/@newVariables),
   "Order"->high,"Integrator"->"HyperFLINT","KernelsAvailable"->1,
   "Parallelization"->"BruteForce","SetupInParallel"->1,"ScoreInParallel"->None,
   "SetProblemID"->"feynfacet_boundary","ReuseExistingResults"->False,
   "ShowTimings"->verbose,"Verbose"->verbose,"ContourHandling"->"Abort"]],
  SetDirectory[old]];
 result=decodeBoundaryHyperlogResult[raw,newVariables,eps,high,dir];
 If[FailureQ[result],Throw[result,"BoundaryIntegration"]];
 If[automatic,DeleteDirectory[dir,DeleteContents->True]];
 result
],"BoundaryIntegration"]];
End[];
