(* Reader for finite solution records; independent of their constructor. *)
readData[path_] := Block[{$Context="Global`",$ContextPath={"System`","Global`"}},Get[path]];
Options[ReadMasterIntegralSolution]={"BoundaryCoefficientValues"->Automatic};
ReadMasterIntegralSolution[directory_String,OptionsPattern[]] := Module[
 {c,coeff,masterCoefficients,orderData,boundaryValues=OptionValue["BoundaryCoefficientValues"],record},
 If[boundaryValues=!=Automatic&&!AssociationQ[boundaryValues],
   Return[Failure["NumericalBoundaryCoefficientAssociationRequired",<||>]]];
 If[FileExistsQ[FileNameJoin[{directory,"solution.wxf"}]],
  record=Import[FileNameJoin[{directory,"solution.wxf"}],"WXF"];
  Return[If[AssociationQ[boundaryValues],
    FeynFacetSolution`ApplyNumericalBoundaryCoefficients[record,boundaryValues],
    sharedBoundaryRead[record,directory]]]];
 c=readData[FileNameJoin[{directory,"conventions.m"}]];
 If[!AssociationQ[c],Return[Failure["ConventionsNotReadable",<||>]]];
 coeff=Association@Table[k->readData[FileNameJoin[{directory,
   "coefficients_order_"<>ToString[k]<>".m"}]],{k,c["RequestedEpsilonOrders"]}];
 masterCoefficients=If[KeyExistsQ[c,"RequestedMasterIntegralEpsilonOrders"],
  Association@Table[k->readData[FileNameJoin[{directory,"master_integrals_order_"<>ToString[k]<>".m"}]],
   {k,c["RequestedMasterIntegralEpsilonOrders"]}],None];
 orderData=If[FileExistsQ[FileNameJoin[{directory,"order_determination.wxf"}]],
  Import[FileNameJoin[{directory,"order_determination.wxf"}],"WXF"],None];
 Join[c,If[AssociationQ[masterCoefficients],<|"MasterIntegralCoefficients"->masterCoefficients|>,<||>],
  If[AssociationQ[orderData],<|"ExpansionOrderDetermination"->orderData|>,<||>],
  <|"IntegralDefinitions"->readData[FileNameJoin[{directory,"functions.m"}]],
  "KernelDefinitions"->If[FileExistsQ[FileNameJoin[{directory,"kernel_functions.m"}]],
    readData[FileNameJoin[{directory,"kernel_functions.m"}]],{}],
  "AlgebraicDefinitions"->readData[FileNameJoin[{directory,"algebraic_expressions.m"}]],
  "Coefficients"->coeff|>]
];

