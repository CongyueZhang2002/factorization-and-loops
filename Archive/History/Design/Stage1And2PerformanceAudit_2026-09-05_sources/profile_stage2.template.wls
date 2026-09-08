
$HistoryLength=0;
root=__REPOSITORY_ROOT__;
Block[{Print},Get[FileNameJoin[{root,"Addon","Load","LoadFACET.wl"}]]];

Block[{$ContextPath={"System`","FeynFacet`"}},
 Get["__FINITE_PROFILE__"];
 Get["__ORDER_PROFILE__"]];


SpeedAudit`records=<||>;SpeedAudit`events={};
SpeedAudit`mark[msg_] := (AppendTo[SpeedAudit`events,
 <|"Seconds"->N[AbsoluteTime[]-SpeedAudit`start],"Phase"->msg|>];Print[Last[SpeedAudit`events]]);

SetAttributes[SpeedAudit`wrap,HoldFirst];
SpeedAudit`wrap[symbol_] := Module[{original=Unique["SpeedAudit`original"]},
 With[{f=symbol,o=original},
  Options[o]=Options[f];Attributes[o]=Attributes[f];
  DownValues[o]=DownValues[f]/.f->o;
  DownValues[f]={};
  f[args___] := Module[{start=AbsoluteTime[],value,elapsed,name=ToString[Unevaluated[f],InputForm],old},
   value=o[args];elapsed=N[AbsoluteTime[]-start];
   old=Lookup[SpeedAudit`records,name,<|"Calls"->0,"InclusiveSeconds"->0.|>];
   AssociateTo[SpeedAudit`records,name-><|"Calls"->old["Calls"]+1,
     "InclusiveSeconds"->old["InclusiveSeconds"]+elapsed|>];value]
 ]];
SpeedAudit`wrap[FeynFacet`DetermineMasterIntegralExpansionOrders];
SpeedAudit`wrap[FeynFacet`Private`epsOrderPrepareFrame];
SpeedAudit`wrap[FeynFacet`Private`solutionGaugeChecks];
SpeedAudit`wrap[FeynFacet`Private`solutionFlatness];
SpeedAudit`wrap[FeynFacet`Private`solutionConnectionCoefficientConjugation];
SpeedAudit`wrap[FeynFacet`Private`solutionLaurentCoefficients];
SpeedAudit`wrap[FeynFacet`MasterIntegralSolutionQ];
SpeedAudit`wrap[FeynFacet`Private`solutionMasterCoefficientsFromOrders];
input=Import[__INPUT_FILE__,"WXF"];
family=Lookup[input["Data"],"Family","Unspecified"];
SpeedAudit`start=AbsoluteTime[];
sol=ConstructMasterIntegralSolution[input["Data"],input["Request"],Sequence@@Normal[input["Options"]]];
total=N[AbsoluteTime[]-SpeedAudit`start];
report=<|"Family"->family,"TotalSeconds"->total,"Success"->AssociationQ[sol],
 "Phases"->SpeedAudit`events,"Functions"->SpeedAudit`records,
 "MaximumWolframMemoryBytes"->MaxMemoryUsed[]|>;
Export[__REPORT_FILE__,report,"RawJSON"];
Print[InputForm[report]];
If[!AssociationQ[sol],Print[sol];Exit[1]];
