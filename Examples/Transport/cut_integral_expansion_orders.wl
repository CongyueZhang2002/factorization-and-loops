(* Complete stored input; no process-specific branch exists in the package.
   Run with Scripts/Transport/determine_epsilon_orders.wls. *)
Module[{root,directory,recurrence,previous},
 root=DirectoryName[ExpandFileName[$InputFileName],3];
 directory=FileNameJoin[{root,"ppHX_NNLO_DoubleReal","Results","EpsilonOrderDetermination","CF269"}];
 recurrence=Import[FileNameJoin[{directory,"DimensionalRecurrence.wxf"}],"WXF"];
 previous=Import[FileNameJoin[{directory,"MasterIntegralExpansionOrders.wxf"}],"WXF"];
 <|"Task"->"MasterIntegralExpansion",
   "Data"->previous["PreparedDifferentialSystem"],
   "Request"-><|"BasePoint"->{1/4,1/3},
    "MasterIntegralRepresentations"->AssociationThread[Range[23],recurrence["IntegralRepresentations"]],
    "DimensionalRecurrence"->recurrence,
    "RequestedMasterIntegralOrderRanges"->AssociationThread[Range[23],ConstantArray[{-3,0},23]]|>|>
]
