
root="/home/maxzhang/factorization-and-loops";
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
residue={{-2eps,1,0},{0,-2eps,0},{0,0,-3eps}};
connection=residue/z+{{0,0,1},{1,0,0},{0,1,0}}/(1-z);
system=<|"Variable"->z,"DimensionalRegulator"->eps,"ConnectionMatrix"->connection|>;
seed=<|"Basis"->IdentityMatrix[3],"LeftInverse"->IdentityMatrix[3]|>;
request=<|"ResidueEigenvalue"->-2eps,"SpectralVariable"->lambda,
 "ResidueAnnihilatingPolynomial"->(lambda+2eps)^2(lambda+3eps),"MaximumNormalOrder"->2|>;
r=FeynFacet`ConstructPrimaryFrobeniusExpansion[system,seed,request,"Verbose"->True];
If[FailureQ[r],Print[r];Exit[1]];
poly=Sum[z^n Log[z]^l Normal[r["Coefficients"][[n+1,l+1]]],{n,0,2},{l,0,1}];
res=z D[poly,z]-2eps poly-z connection.poly;
check=Map[Cancel[Together[Normal[Series[#,{z,0,2}]]]]&,res,{2}];
If[check=!=ConstantArray[0,{3,3}],Print["FAIL RESIDUAL ",check];Exit[1]];
bad=FeynFacet`ConstructPrimaryFrobeniusExpansion[system,seed,Join[request,<|"ResidueAnnihilatingPolynomial"->lambda+2eps|>]];
If[!FailureQ[bad],Print["FAIL ANNIHILATOR"];Exit[1]];
Print["PASS GENERIC FROBENIUS RECURRENCE AND ANNIHILATOR REJECTION"];Exit[0];
