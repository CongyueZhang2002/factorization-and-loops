(* Twist-2 collinear distribution and fragmentation correlators. *)

\[CapitalPhi]::usage =
  "\[CapitalPhi][x,P,lambda,ST,n] is the incoming quark correlator.";

\[CapitalDelta]::usage =
  "\[CapitalDelta][z,P,lambda,ST,n] is the outgoing quark correlator.";

\[CapitalPhi]b::usage =
  "\[CapitalPhi]b[x,P,lambda,ST,n] is the incoming antiquark correlator.";

\[CapitalDelta]b::usage =
  "\[CapitalDelta]b[z,P,lambda,ST,n] is the outgoing antiquark correlator.";

f1::usage = "f1[x] is the unpolarized collinear parton distribution.";
g1L::usage = "g1L[x] is the longitudinal-helicity parton distribution.";
h1::usage = "h1[x] is the transversity parton distribution.";
D1::usage = "D1[z] is the unpolarized collinear fragmentation function.";
G1L::usage = "G1L[z] is the longitudinal-helicity fragmentation function.";
H1::usage = "H1[z] is the transversity fragmentation function.";

SyntaxInformation[\[CapitalPhi]] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalDelta]] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalPhi]b] = {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[\[CapitalDelta]b] = {"ArgumentsPattern" -> {_, _, _, _, _}};

Begin["`Private`"];

ClearAll[iSigmaSlash];
ClearAll[twist2Correlator];
Clear[\[CapitalPhi], \[CapitalDelta], \[CapitalPhi]b, \[CapitalDelta]b];

$twist2DistributionHeads = {f1, g1L, h1, D1, G1L, H1};

iSigmaSlash[a_, b_] := I (I/2) (
  FeynCalc`GS[a] . FeynCalc`GS[b] -
  FeynCalc`GS[b] . FeynCalc`GS[a]
);

twist2Correlator[
    variable_, lambda_, ST_, n_,
    {unpolarized_, longitudinal_, transverse_},
    helicitySign : (1 | -1)
  ] := (
  FeynFacet`DeclareScalar[{
    variable, lambda, unpolarized, longitudinal, transverse
  }];
  1/2 (
    unpolarized[variable] FeynCalc`GS[n] +
    helicitySign lambda longitudinal[variable]
      FeynCalc`GA[5] . FeynCalc`GS[n] +
    transverse[variable] iSigmaSlash[n, ST] . FeynCalc`GA[5]
  )
);

\[CapitalPhi][x_, P_, lambda_, ST_, n_] :=
  twist2Correlator[x, lambda, ST, n, {f1, g1L, h1}, 1];

\[CapitalDelta][z_, P_, lambda_, ST_, n_] :=
  twist2Correlator[z, lambda, ST, n, {D1, G1L, H1}, 1];

\[CapitalPhi]b[x_, P_, lambda_, ST_, n_] :=
  twist2Correlator[x, lambda, ST, n, {f1, g1L, h1}, -1];

\[CapitalDelta]b[z_, P_, lambda_, ST_, n_] :=
  twist2Correlator[z, lambda, ST, n, {D1, G1L, H1}, -1];

End[];
