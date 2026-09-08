(* Two independent squared-propagator massive vacuum integrals.
   The measure is d^D k d^D l/(i Pi^(D/2))^2, D=4-2 epsilon.
   No U, F, Gamma prefactor, pole bound or boundary value is supplied. *)
<|"Task"->"MasterIntegralExpansion",
 "Data"-><|"KinematicVariables"->{x},"DimensionalRegulator"->eps,
   "OriginalMasterIntegralBasis"->{FeynCalc`GLI[vacuumProduct,{2,2}]},
   "Topology"->FeynCalc`FCTopology[vacuumProduct,
     {FeynCalc`SFAD[{k1,x}],FeynCalc`SFAD[{k2,x}]},{k1,k2},{},{},{}],
   "ConnectionMatrices"->{{{-2eps/x}}}|>,
 "Request"-><|"BasePoint"->{1/4},
   "RequestedMasterIntegralOrderRanges"-><|1->{-2,0}|>,
   "BoundaryNormalization"-><|"Type"->"Frobenius",
     "NormalVariable"->x,"SingularPoint"->0|>|>|>
