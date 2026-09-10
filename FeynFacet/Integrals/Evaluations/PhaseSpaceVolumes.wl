(* Absolute massless n-body phase-space volumes from repeated two-body
   factorization. No amplitude, color, current, flux or coupling factor. *)
BeginPackage["FeynFacet`"];
MasslessPhaseSpaceVolume::usage="MasslessPhaseSpaceVolume[n,s,epsilon] evaluates the Lorentz-invariant phase-space volume for n massless final particles, with positive timelike s=P^2. It follows from dPhi_n=dM^2/(2 Pi) dPhi_2(P;k,K) dPhi_(n-1)(K), continued meromorphically in epsilon.";
MasslessMeasuredPhaseSpace::usage="MasslessMeasuredPhaseSpace[n,s,z,epsilon] evaluates dPhi_n/dz for the null-reference fraction z=p.k1/(p.P), with s>0 and 0<z<1. It contains the measurement Jacobian exactly once and no incoming flux or current factor.";
Begin["`Private`"];
masslessPhaseSpaceConstant[n_Integer,e_]:=Module[{coefficient,clusterExponent},
 coefficient=twoParticleIntegratedPhaseSpace[1,1,e];
 Do[clusterExponent=(particles-2)(1-e)-1;
  coefficient*=twoParticleIntegratedPhaseSpace[1,1,e]/(2Pi)*
   Gamma[clusterExponent+1]Gamma[2-2e]/Gamma[clusterExponent+3-2e],
 {particles,3,n}];
 Factor[coefficient]
];
MasslessPhaseSpaceVolume[n_Integer/;n>=2,s_,e_Symbol]:=
 masslessPhaseSpaceConstant[n,e]s^(n-2-(n-1)e);
MasslessMeasuredPhaseSpace[n_Integer/;n>=2,s_,z_,e_Symbol]:=Module[
 {a=1-e,b=(n-1)(1-e)},
 MasslessPhaseSpaceVolume[n,s,e]Gamma[a+b]/(Gamma[a]Gamma[b])z^(a-1)(1-z)^(b-1)
];
End[];EndPackage[];
