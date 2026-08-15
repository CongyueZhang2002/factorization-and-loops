<|"ClassID" -> 115, "RepFamily" -> "CF299", "RepRows" -> {1, 2}, "Dim" -> 2, 
 "Variables" -> {u}, "Transformation" -> 
  {{u^(-1), 0}, {(1 + 8*eps)/u^3, eps/u^2}}, "TransformationInverse" -> 
  {{u, 0}, {(-1 - 8*eps)/eps, u^2/eps}}, 
 "EpsForm" -> {{{eps*(2/(-1 + u) - 8/u + 2/(1 + u)), 
     eps*(1/(2*(-1 + u)) - 1/(2*(1 + u)))}, {eps*(-4/(-1 + u) + 4/(1 + u)), 
     eps*(-(-1 + u)^(-1) - (1 + u)^(-1))}}}, "Alphabet" -> {u, 1 - u, 1 + u}, 
 "Residues" -> <|"u" -> {{-8, 0}, {0, 0}}, "1-u" -> {{2, 1/2}, {-4, -1}}, 
   "1+u" -> {{2, -1/2}, {4, -1}}|>, "AnsatzDegree" -> 
  "hand-constructed (3 Lee balances + constant eps-factorisation)", 
 "Validated" -> True, "OneVariable" -> True, 
 "Chart" -> <|"ChartVariable" -> u, "Definition" -> u^2 == 1 - 4*v*w, 
   "Inverse" -> w -> (1 - u^2)/(4*v), "PhysicalRange" -> 
    "0 < u <= 1 on 0<v,w, v+w<1", "RealityIdentity" -> 
    1 - 4*v*w == (v - w)^2 + (1 - v - w)*(1 + v + w)|>, 
 "Convention" -> "Original = Transformation . Canonical, both as functions of \
the chart variable u (u^2 = 1-4vw).  EpsForm is dJ/du.  Differentiate the \
gauge term with respect to u only.  Do not confuse u with x = 4vw or z = vw."\
, "Structure" -> "Av = M[vw]/v and Aw = M[vw]/w with the SAME M; [Av,Aw] = 0. \
 The block is one-variable in z = vw.  A_v vanishes identically in any chart \
whose second variable is a function of z alone -- this is why CANONICA \
refuses instantly, and it is not a non-rationalisability obstruction.", 
 "ScalarODE" -> 
  "Gauss hypergeometric in x = 4 v w with a = 1+eps, b = 1/2+2eps, c = 1-eps"\
, "HypergeometricParameters" -> <|"a" -> 1 + eps, "b" -> 1/2 + 2*eps, 
   "c" -> 1 - eps, "x" -> 4*v*w|>, "ClosedForm" -> 
  {c1*Hypergeometric2F1[1 + eps, 1/2 + 2*eps, 1 - eps, 4*v*w], 
   c1*(1 + 4*eps)*Hypergeometric2F1[1 + eps, 1/2 + 2*eps, 1 - eps, 4*v*w] + 
    (8*c1*(1 + eps)*(1/2 + 2*eps)*v*w*Hypergeometric2F1[2 + eps, 3/2 + 2*eps, 
       2 - eps, 4*v*w])/(1 - eps)}, "LocalExponents" -> 
  <|"z=0" -> {0, eps}, "z=1/4" -> {0, -3/2 - 4*eps}, 
   "z=Infinity" -> {1 + eps, 1/2 + 2*eps}, "u=0" -> {0, -8*eps}, 
   "u=1" -> {0, eps}, "u=-1" -> {0, eps}, "u=Infinity" -> {4*eps, 2*eps}|>, 
 "FunctionClass" -> 
  "Harmonic polylogarithms H(a1,...,an; u) with a_i in {0,1,-1}", 
 "Provenance" -> "specials agent 2026-08-14; exact gate in this file", 
 "ClosedFormSector" -> <|"RepFamily" -> "CF299", "RepRows" -> {1, 2}, 
   "Variables" -> {v, w}, "Regulator" -> eps, 
   "Av" -> {{(-1 - 4*eps)/(2*v), 1/(2*v)}, 
     {(1 + 10*eps + 24*eps^2)/(2*v*(-1 + 4*v*w)), 
      (-1 - 6*eps - 8*v*w - 8*eps*v*w)/(2*v*(-1 + 4*v*w))}}, 
   "Aw" -> {{(-1 - 4*eps)/(2*w), 1/(2*w)}, 
     {(1 + 10*eps + 24*eps^2)/(2*w*(-1 + 4*v*w)), 
      (-1 - 6*eps - 8*v*w - 8*eps*v*w)/(2*w*(-1 + 4*v*w))}}, 
   "Phi" -> {{Hypergeometric2F1[1 + eps, 1/2 + 2*eps, 1 - eps, 4*v*w], 
      4^eps*(v*w)^eps*Hypergeometric2F1[1 + 2*eps, 1/2 + 3*eps, 1 + eps, 
        4*v*w]}, {-(((1 + 4*eps)*(Hypergeometric2F1[1 + eps, 1/2 + 2*eps, 
           1 - eps, 4*v*w] - eps*Hypergeometric2F1[1 + eps, 1/2 + 2*eps, 
            1 - eps, 4*v*w] + 4*v*w*Hypergeometric2F1[2 + eps, 3/2 + 2*eps, 
            2 - eps, 4*v*w] + 4*eps*v*w*Hypergeometric2F1[2 + eps, 
            3/2 + 2*eps, 2 - eps, 4*v*w]))/(-1 + eps)), 
      (2^(2*eps)*(1 + 6*eps)*(v*w)^eps*(Hypergeometric2F1[1 + 2*eps, 
          1/2 + 3*eps, 1 + eps, 4*v*w] + eps*Hypergeometric2F1[1 + 2*eps, 
           1/2 + 3*eps, 1 + eps, 4*v*w] + 4*v*w*Hypergeometric2F1[2 + 2*eps, 
           3/2 + 3*eps, 2 + eps, 4*v*w] + 8*eps*v*w*Hypergeometric2F1[
           2 + 2*eps, 3/2 + 3*eps, 2 + eps, 4*v*w]))/(1 + eps)}}, 
   "PhiConstruction" -> "Columns are the two Frobenius branches at z = 4 v w \
= 0 with exponents {0, eps}: column 1 is 2F1(a,b;c;4vw), column 2 is \
(4vw)^(1-c) 2F1(a-c+1,b-c+1;2-c;4vw), with (a,b,c) = (1+eps, 1/2+2eps, \
1-eps).  The SECOND component of each column is fixed by row 1 of the block \
system, (dy/dv - Av[[1,1]] y)/Av[[1,2]], so the matrix uses no identity \
beyond the block differential equation itself.  Stored in the (v,w) frame, \
which is the frame Av and Aw live in -- not in the chart variable u.", 
   "ExactCertificate" -> <|"Method" -> "GaussODE+PochhammerTower", 
     "Statement" -> "dPhi/dv - Av.Phi = 0 and dPhi/dw - Aw.Phi = 0 as \
symbolic identities in the physical chamber 0 < v, w, v + w < 1, together \
with Phi^-1.Phi = 1.  Proved with no series truncation and no numerical \
substitution.", "Identities" -> 
      {"d^n/dz^n 2F1(a,b;c;z) = ((a)_n (b)_n/(c)_n) 2F1(a+n,b+n;c+n;z)", 
       "z(1-z) f'' + [c-(a+b+1) z] f' - a b f = 0"}, 
     "Towers" -> {<|"Base" -> {1 + eps, 1/2 + 2*eps, 1 - eps}, 
        "Argument" -> 4*v*w, "Shifts" -> {0, 1}, "MaxReducedOrder" -> 5|>, 
       <|"Base" -> {1 + 2*eps, 1/2 + 3*eps, 1 + eps}, "Argument" -> 4*v*w, 
        "Shifts" -> {0, 1}, "MaxReducedOrder" -> 5|>}, 
     "GaussEquation" -> "z(1-z) f'' + [c - (a+b+1) z] f' - a b f = 0 with z = \
4 v w and (a,b,c) = (1+eps, 1/2+2eps, 1-eps); solved for f'' and \
differentiated to reduce every f^(m), m >= 2, to {f, f'} with exact rational \
coefficients.", "TowerIdentity" -> "d^n/dz^n 2F1(a,b;c;z) = ((a)_n \
(b)_n/(c)_n) 2F1(a+n,b+n;c+n;z), used RIGHT TO LEFT so that every \
parameter-raised instance produced by differentiation collapses onto \
derivatives of one tower base.", "Reproduce" -> "FeynFacet`Private`masterTran\
sportHypergeometricCertificate[Phi, {{Av, v}, {Aw, w}}, eps, record, \
timeLimit], or simply hand the sector to TransportFamily, which \
re-establishes it and refuses a stored verdict.", "Numerics" -> "none", 
     "Provenance" -> "Fable 2026-08-15, in response to Codex assessment \
section 2; supersedes the series-plus-numeric route that could only earn \
AnalyticCandidate."|>|>|>
