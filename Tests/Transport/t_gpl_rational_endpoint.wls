#!/usr/bin/env wolframscript
Print["FEYNFACET DRIVER ENTERED"];
$HistoryLength=0;$MaxExtraPrecision=50;
reRoot=FileNameJoin[FileNameSplit[DirectoryName[ExpandFileName[$InputFileName],3]]];
Get[reRoot<>"/Tests/TestKit.wl"];Get[reRoot<>"/FeynFacet/Solution.m"];
Clear[reT,reZ,reA];
reG=FeynFacetSolution`G;
(* Independent local expansions at fixed reA > reZ > 0 give the constants.
   Trailing zero letters contribute logarithms but no negative powers of t. *)
reCases={
 <|"Label"->"a simple rational pole retains the first vanishing GPL coefficient",
   "Primitive"->reG[{reA},reT]/reT,"Endpoint"->-1/reA|>,
 <|"Label"->"a double pole retains the next coefficient after cancellation between words",
   "Primitive"->(reG[{reA},reT]+reT/reA)/reT^2,"Endpoint"->-1/(2reA^2)|>,
 <|"Label"->"one trailing zero retains the finite part after logarithmic cancellation",
   "Primitive"->reG[{reA,0},reT]/reT+Log[reT]/reA,"Endpoint"->1/reA|>,
 <|"Label"->"a leading zero preserves the finite coefficient of a trailing-zero word",
   "Primitive"->reG[{0,reA,0},reT]/reT+Log[reT]/reA,"Endpoint"->2/reA|>,
 <|"Label"->"two trailing zeros retain the constant after both logarithmic orders cancel",
   "Primitive"->reG[{reA,0,0},reT]/reT+Log[reT]^2/(2reA)-Log[reT]/reA,
   "Endpoint"->-1/reA|>};
Do[
 reAnswer=FeynFacetSolution`IntegrateGPL[D[reCase["Primitive"],reT],{reT,0,reZ},
  "Assumptions"->reA>reZ>0];
 reExpected=(reCase["Primitive"]/.reT->reZ)-reCase["Endpoint"];
 reResidual=If[FailureQ[reAnswer],reAnswer,
  (reAnswer-reExpected)/.FeynFacetSolution`G[letters_List,reZ]/;AllTrue[letters,#===0&]:>
   Log[reZ]^Length[letters]/Factorial[Length[letters]]];
 FTTest`FTAssert[reCase["Label"],!FailureQ[reAnswer]&&
  FullSimplify[reResidual,Assumptions->reA>reZ>0]===0];
 If[FailureQ[reAnswer],Print["ENDPOINT FAILURE ",reAnswer]],
 {reCase,reCases}];
reDivergent=FeynFacetSolution`IntegrateGPL[D[reG[{2,0},reT]/reT,reT],{reT,0,reZ},
 "Assumptions"->0<reZ<2];
FTTest`FTAssert["an uncancelled trailing-zero logarithm remains a divergent endpoint",
 MatchQ[reDivergent,Failure["GPLLowerEndpointNotFinite",_Association]]];
reRational=FeynFacetSolution`IntegrateGPL[
 1/(reT^2(1-reT))-1/reT^2-1/reT,{reT,0,reZ},"Assumptions"->0<reZ<1];
FTTest`FTAssert["cancellation across rational summands removes all lower-end poles",
 !FailureQ[reRational]&&FullSimplify[reRational+reG[{1},reZ]]===0];
reUpper=FeynFacetSolution`IntegrateGPL[D[(Log[1+reT]-Log[2])/(reT-1),reT],{reT,0,1}];
FTTest`FTAssert["a removable but nonregular upper substitution requires an explicit endpoint implementation",
 MatchQ[reUpper,Failure["RegularGPLUpperPointRequired",_Association]]];
FTTest`FTReport[];
