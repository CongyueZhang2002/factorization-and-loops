{<|"Locus" -> -1 + v, "OrdAv" -> 1, "OrdAw" -> 0, "Fuchsian" -> True, 
  "EpsDependent" -> False, "Residue" -> {{eps, 0, 0, 0}, 
    {(1 + 6*eps + 8*eps^2)/(1 - w), -2*(1 + eps), 0, 0}, 
    {-((eps*(1 + 4*eps))/w), 0, -2*(1 + eps), 0}, 
    {(1 + 6*eps + 8*eps^2)/(-1 + w), 0, 0, -2*(1 + eps)}}, 
  "Spectrum" -> <|"Status" -> "ok", "Eigenvalues" -> 
     {eps, -2*(1 + eps), -2*(1 + eps), -2*(1 + eps)}, "Rank" -> 4, 
    "Trace" -> -6 - 5*eps, "Detail" -> 
     {<|"Eigenvalue" -> eps, "Algebraic" -> 1, "Geometric" -> 1, 
       "Jordan" -> "diagonalizable"|>, <|"Eigenvalue" -> -2*(1 + eps), 
       "Algebraic" -> 3, "Geometric" -> 3, "Jordan" -> "diagonalizable"|>}, 
    "CharPoly" -> -((eps - HCT$lam)*(2 + 2*eps + HCT$lam)^3)|>, 
  "Exponents" -> {eps, -2*(1 + eps), -2*(1 + eps), -2*(1 + eps)}, 
  "ExponentClasses" -> {"integer", "integer", "integer", "integer"}, 
  "Balance" -> Missing["not rank-1"]|>, <|"Locus" -> v, "OrdAv" -> 1, 
  "OrdAw" -> 1, "Fuchsian" -> True, "EpsDependent" -> False, 
  "Residue" -> {{-1/2*((1 + eps)*(-1 + w))/w, ((1 + eps)*(-1 + w))/
      (2 + 8*eps), 0, -1/2*((1 + eps)*(-1 + w))/(w + 4*eps*w)}, 
    {-1/2*(1 + 7*eps + 12*eps^2)/w, (1 + 3*eps)/2, 0, -1/2*(1 + 3*eps)/w}, 
    {((1 + 4*eps)*(1 + w + eps*(2 + 3*w)))/w^2, 
     -((1 + eps + 2*w + 3*eps*w)/w), -1, (1 + 2*eps*(1 + w))/w^2}, 
    {-1/2*(1 + 5*eps + 4*eps^2)/w, (1 + eps)/2, 0, -1/2*(1 + eps)/w}}, 
  "Spectrum" -> <|"Status" -> "ok", "Eigenvalues" -> {0, 0, -1, eps}, 
    "Rank" -> 2, "Trace" -> -1 + eps, "Detail" -> 
     {<|"Eigenvalue" -> 0, "Algebraic" -> 2, "Geometric" -> 2, 
       "Jordan" -> "diagonalizable"|>, <|"Eigenvalue" -> -1, 
       "Algebraic" -> 1, "Geometric" -> 1, "Jordan" -> "diagonalizable"|>, 
      <|"Eigenvalue" -> eps, "Algebraic" -> 1, "Geometric" -> 1, 
       "Jordan" -> "diagonalizable"|>}, "CharPoly" -> 
     HCT$lam^2*(1 + HCT$lam)*(-eps + HCT$lam)|>, 
  "Exponents" -> {0, 0, -1, eps}, "ExponentClasses" -> 
   {"integer", "integer", "integer", "integer"}, 
  "Balance" -> Missing["not rank-1"]|>, <|"Locus" -> v - w, "OrdAv" -> 1, 
  "OrdAw" -> 1, "Fuchsian" -> True, "EpsDependent" -> False, 
  "Residue" -> {{-1/2*(1 + eps + v + 3*eps*v)/v, 
     -(((1 + eps)*(-2 + v + v^2))/(2 + 8*eps)), 
     -(((1 + eps)*(-1 + v)*v)/(2 + 8*eps)), ((-1 + v)*(1 + eps + 4*eps*v))/
      (2*(v + 4*eps*v))}, {((1 + 4*eps)*(1 + eps + v + 3*eps*v))/
      (2*(-1 + v)*v), ((1 + eps)*(2 + v))/2, ((1 + eps)*v)/2, 
     -1/2*(1 + eps + 4*eps*v)/v}, 
    {-1/2*((1 + 4*eps)*(1 + eps + v + 3*eps*v))/v^2, 
     -1/2*((1 + eps)*(-2 + v + v^2))/v, -1/2*((1 + eps)*(-1 + v)), 
     ((-1 + v)*(1 + eps + 4*eps*v))/(2*v^2)}, 
    {-1/2*((1 + 4*eps)*(1 + eps + v + 3*eps*v))/((-1 + v)*v), 
     -1/2*((1 + eps)*(2 + v)), -1/2*((1 + eps)*v), 
     (1 + eps + 4*eps*v)/(2*v)}}, "Spectrum" -> 
   <|"Status" -> "ok", "Eigenvalues" -> {0, 0, 0, 1 + 2*eps}, "Rank" -> 1, 
    "Trace" -> 1 + 2*eps, "Detail" -> {<|"Eigenvalue" -> 0, "Algebraic" -> 3, 
       "Geometric" -> 3, "Jordan" -> "diagonalizable"|>, 
      <|"Eigenvalue" -> 1 + 2*eps, "Algebraic" -> 1, "Geometric" -> 1, 
       "Jordan" -> "diagonalizable"|>}, "CharPoly" -> 
     -((1 + 2*eps - HCT$lam)*HCT$lam^3)|>, 
  "Exponents" -> {0, 0, 0, 1 + 2*eps}, "ExponentClasses" -> 
   {"integer", "integer", "integer", "integer"}, 
  "Balance" -> <|"Projector" -> {{-((1 + eps + v + 3*eps*v)/(2*v + 4*eps*v)), 
       -(((1 + eps)*(-2 + v + v^2))/((1 + 2*eps)*(2 + 8*eps))), 
       -(((1 + eps)*(-1 + v)*v)/((1 + 2*eps)*(2 + 8*eps))), 
       ((-1 + v)*(1 + eps + 4*eps*v))/(2*(1 + 2*eps)*(v + 4*eps*v))}, 
      {((1 + 4*eps)*(1 + eps + v + 3*eps*v))/(2*(1 + 2*eps)*(-1 + v)*v), 
       ((1 + eps)*(2 + v))/(2 + 4*eps), ((1 + eps)*v)/(2 + 4*eps), 
       -((1 + eps + 4*eps*v)/(2*v + 4*eps*v))}, 
      {-1/2*((1 + 4*eps)*(1 + eps + v + 3*eps*v))/((1 + 2*eps)*v^2), 
       -1/2*((1 + eps)*(-2 + v + v^2))/(v + 2*eps*v), 
       -(((1 + eps)*(-1 + v))/(2 + 4*eps)), ((-1 + v)*(1 + eps + 4*eps*v))/
        (2*(1 + 2*eps)*v^2)}, {-1/2*((1 + 4*eps)*(1 + eps + v + 3*eps*v))/
         ((1 + 2*eps)*(-1 + v)*v), -(((1 + eps)*(2 + v))/(2 + 4*eps)), 
       -(((1 + eps)*v)/(2 + 4*eps)), (1 + eps + 4*eps*v)/(2*v + 4*eps*v)}}, 
    "Trace" -> 1 + 2*eps, 
    "T" -> {{(1 - v^2 + w + v*(2 + w) + eps*(1 - 3*v^2 + w + 3*v*(2 + w)))/
        (2*(v + 2*eps*v)), -1/2*((1 + eps)*(-2 + v + v^2)*(-1 + v - w))/
         (1 + 6*eps + 8*eps^2), -1/2*((1 + eps)*(-1 + v)*v*(-1 + v - w))/
         (1 + 6*eps + 8*eps^2), ((-1 + v)*(1 + eps + 4*eps*v)*(-1 + v - w))/
        (2*(1 + 2*eps)*(1 + 4*eps)*v)}, 
      {((1 + 4*eps)*(1 + eps + v + 3*eps*v)*(-1 + v - w))/
        (2*(1 + 2*eps)*(-1 + v)*v), (2 + 4*eps - (1 + eps)*(2 + v) + 
         (1 + eps)*(2 + v)*(v - w))/(2 + 4*eps), ((1 + eps)*v*(-1 + v - w))/
        (2 + 4*eps), -1/2*((1 + eps + 4*eps*v)*(-1 + v - w))/(v + 2*eps*v)}, 
      {-1/2*((1 + 4*eps)*(1 + eps + v + 3*eps*v)*(-1 + v - w))/
         ((1 + 2*eps)*v^2), -1/2*((1 + eps)*(-2 + v + v^2)*(-1 + v - w))/
         (v + 2*eps*v), 1 + ((1 + eps)*(-1 + v))/(2 + 4*eps) - 
        ((1 + eps)*(-1 + v)*(v - w))/(2 + 4*eps), 
       ((-1 + v)*(1 + eps + 4*eps*v)*(-1 + v - w))/(2*(1 + 2*eps)*v^2)}, 
      {-1/2*((1 + 4*eps)*(1 + eps + v + 3*eps*v)*(-1 + v - w))/
         ((1 + 2*eps)*(-1 + v)*v), -(((1 + eps)*(2 + v)*(-1 + v - w))/
         (2 + 4*eps)), -(((1 + eps)*v*(-1 + v - w))/(2 + 4*eps)), 
       -((1 + eps - 3*v - eps*v - 4*eps*v^2 + w + eps*w + 4*eps*v*w)/
         (2*v + 4*eps*v))}}, "Tinv" -> 
     {{1 + (1 + eps + v + 3*eps*v)/(2*v + 4*eps*v) - (1 + eps + v + 3*eps*v)/
         (2*(v + 2*eps*v)*(v - w)), ((1 + eps)*(-2 + v + v^2)*(-1 + v - w))/
        (2*(1 + 2*eps)*(1 + 4*eps)*(v - w)), 
       ((1 + eps)*(-1 + v)*v*(-1 + v - w))/(2*(1 + 2*eps)*(1 + 4*eps)*
         (v - w)), -1/2*((-1 + v)*(1 + eps + 4*eps*v)*(-1 + v - w))/
         ((1 + 2*eps)*(1 + 4*eps)*v*(v - w))}, 
      {-1/2*((1 + 4*eps)*(1 + eps + v + 3*eps*v)*(-1 + v - w))/
         ((1 + 2*eps)*(-1 + v)*v*(v - w)), 1 - ((1 + eps)*(2 + v))/
         (2 + 4*eps) + ((1 + eps)*(2 + v))/((2 + 4*eps)*(v - w)), 
       -1/2*((1 + eps)*v*(-1 + v - w))/((1 + 2*eps)*(v - w)), 
       ((1 + eps + 4*eps*v)*(-1 + v - w))/(2*(1 + 2*eps)*v*(v - w))}, 
      {((1 + 4*eps)*(1 + eps + v + 3*eps*v)*(-1 + v - w))/
        (2*(1 + 2*eps)*v^2*(v - w)), ((1 + eps)*(-2 + v + v^2)*(-1 + v - w))/
        (2*(1 + 2*eps)*v*(v - w)), 1 + ((1 + eps)*(-1 + v))/(2 + 4*eps) - 
        ((1 + eps)*(-1 + v))/((2 + 4*eps)*(v - w)), 
       -1/2*((-1 + v)*(1 + eps + 4*eps*v)*(-1 + v - w))/
         ((1 + 2*eps)*v^2*(v - w))}, 
      {((1 + 4*eps)*(1 + eps + v + 3*eps*v)*(-1 + v - w))/
        (2*(1 + 2*eps)*(-1 + v)*v*(v - w)), ((1 + eps)*(2 + v)*(-1 + v - w))/
        (2*(1 + 2*eps)*(v - w)), ((1 + eps)*v*(-1 + v - w))/
        (2*(1 + 2*eps)*(v - w)), (1 + 2*v^2 + w + eps*(1 + 3*v + w) - 
         v*(1 + 2*w))/(2*(1 + 2*eps)*v*(v - w))}}, "IdempotentCheck" -> True, 
    "WARNING" -> 
     "do NOT apply before a rational-ansatz search (measured destructive)"|>|>\
, <|"Locus" -> -v - w + v*w, "OrdAv" -> 1, "OrdAw" -> 1, "Fuchsian" -> True, 
  "EpsDependent" -> False, "Residue" -> 
   {{(-1 - eps)/2, 0, ((1 + eps)*v^2)/(2*(1 + 4*eps)*(-1 + v)), 
     -((1 + eps)/(2 + 8*eps))}, {((1 + 6*eps + 8*eps^2)*(-1 + v))/v^2, 0, 
     -1 - 2*eps, ((1 + 2*eps)*(-1 + v))/v^2}, 
    {-1/2*((1 + 5*eps + 4*eps^2)*(-1 + v))/v^2, 0, (1 + eps)/2, 
     -1/2*((1 + eps)*(-1 + v))/v^2}, {0, 0, 0, 0}}, 
  "Spectrum" -> <|"Status" -> "ok", "Eigenvalues" -> {0, 0, 0, 0}, 
    "Rank" -> 1, "Trace" -> 0, "Detail" -> 
     {<|"Eigenvalue" -> 0, "Algebraic" -> 4, "Geometric" -> 3, 
       "Jordan" -> "NON-diagonalizable"|>}, "CharPoly" -> HCT$lam^4|>, 
  "Exponents" -> {0, 0, 0, 0}, "ExponentClasses" -> 
   {"integer", "integer", "integer", "integer"}, 
  "Balance" -> Missing["not rank-1"]|>, <|"Locus" -> v + w, "OrdAv" -> 1, 
  "OrdAw" -> 1, "Fuchsian" -> True, "EpsDependent" -> False, 
  "Residue" -> {{0, 0, 0, 0}, {(1 + 6*eps + 8*eps^2)/v^2, -3 - 4*eps, 
     1 + 2*eps, eps*(2 + 2/v^2) + v^(-2)}, {-((1 + 6*eps + 8*eps^2)/v^2), 
     3 + 4*eps, -1 - 2*eps, (-1 - 2*eps*(1 + v^2))/v^2}, {0, 0, 0, 0}}, 
  "Spectrum" -> <|"Status" -> "ok", "Eigenvalues" -> {0, 0, 0, -4 - 6*eps}, 
    "Rank" -> 1, "Trace" -> -4 - 6*eps, "Detail" -> 
     {<|"Eigenvalue" -> 0, "Algebraic" -> 3, "Geometric" -> 3, 
       "Jordan" -> "diagonalizable"|>, <|"Eigenvalue" -> -4 - 6*eps, 
       "Algebraic" -> 1, "Geometric" -> 1, "Jordan" -> "diagonalizable"|>}, 
    "CharPoly" -> HCT$lam^3*(4 + 6*eps + HCT$lam)|>, 
  "Exponents" -> {0, 0, 0, -4 - 6*eps}, "ExponentClasses" -> 
   {"integer", "integer", "integer", "integer"}, 
  "Balance" -> <|"Projector" -> {{0, 0, 0, 0}, 
      {(1 + 6*eps + 8*eps^2)/((-4 - 6*eps)*v^2), (3 + 4*eps)/(4 + 6*eps), 
       -((1 + 2*eps)/(4 + 6*eps)), (eps*(2 + 2/v^2) + v^(-2))/(-4 - 6*eps)}, 
      {(1 + 6*eps + 8*eps^2)/(4*v^2 + 6*eps*v^2), -((3 + 4*eps)/(4 + 6*eps)), 
       (1 + 2*eps)/(4 + 6*eps), (1 + 2*eps*(1 + v^2))/(2*(2 + 3*eps)*v^2)}, 
      {0, 0, 0, 0}}, "Trace" -> -4 - 6*eps, 
    "T" -> {{1, 0, 0, 0}, {-1/2*((1 + 6*eps + 8*eps^2)*(-1 + v + w))/
         ((2 + 3*eps)*v^2), (1 + 3*v + 3*w + eps*(2 + 4*v + 4*w))/
        (4 + 6*eps), -(((1 + 2*eps)*(-1 + v + w))/(4 + 6*eps)), 
       -1/2*((1 + 2*eps*(1 + v^2))*(-1 + v + w))/((2 + 3*eps)*v^2)}, 
      {((1 + 6*eps + 8*eps^2)*(-1 + v + w))/(2*(2 + 3*eps)*v^2), 
       -(((3 + 4*eps)*(-1 + v + w))/(4 + 6*eps)), 
       (3 + v + w + 2*eps*(2 + v + w))/(4 + 6*eps), 
       ((1 + 2*eps*(1 + v^2))*(-1 + v + w))/(2*(2 + 3*eps)*v^2)}, 
      {0, 0, 0, 1}}, "Tinv" -> {{1, 0, 0, 0}, 
      {((1 + 6*eps + 8*eps^2)*(-1 + v + w))/(2*(2 + 3*eps)*v^2*(v + w)), 
       (3 + v + w + 2*eps*(2 + v + w))/(2*(2 + 3*eps)*(v + w)), 
       ((1 + 2*eps)*(-1 + v + w))/(2*(2 + 3*eps)*(v + w)), 
       ((1 + 2*eps*(1 + v^2))*(-1 + v + w))/(2*(2 + 3*eps)*v^2*(v + w))}, 
      {-1/2*((1 + 6*eps + 8*eps^2)*(-1 + v + w))/((2 + 3*eps)*v^2*(v + w)), 
       ((3 + 4*eps)*(-1 + v + w))/(2*(2 + 3*eps)*(v + w)), 
       (1 + 3*v + 3*w + eps*(2 + 4*v + 4*w))/(2*(2 + 3*eps)*(v + w)), 
       -1/2*((1 + 2*eps*(1 + v^2))*(-1 + v + w))/((2 + 3*eps)*v^2*(v + w))}, 
      {0, 0, 0, 1}}, "IdempotentCheck" -> True, 
    "WARNING" -> 
     "do NOT apply before a rational-ansatz search (measured destructive)"|>|>\
, <|"Locus" -> w, "OrdAv" -> 1, "OrdAw" -> 1, "Fuchsian" -> True, 
  "EpsDependent" -> False, "Residue" -> 
   {{-1/2*((1 + eps)*(-1 + v))/v, ((1 + eps)*(-1 + v))/(2 + 8*eps), 0, 
     -1/2*((1 + eps)*(-1 + v))/(v + 4*eps*v)}, 
    {-1/2*(1 + 7*eps + 12*eps^2)/v, (1 + 3*eps)/2, 0, -1/2*(1 + 3*eps)/v}, 
    {((1 + 4*eps)*(1 + v + eps*(2 + 3*v)))/v^2, 
     -((1 + eps + 2*v + 3*eps*v)/v), -1, (1 + 2*eps*(1 + v))/v^2}, 
    {-1/2*(1 + 5*eps + 4*eps^2)/v, (1 + eps)/2, 0, -1/2*(1 + eps)/v}}, 
  "Spectrum" -> <|"Status" -> "ok", "Eigenvalues" -> {0, 0, -1, eps}, 
    "Rank" -> 2, "Trace" -> -1 + eps, "Detail" -> 
     {<|"Eigenvalue" -> 0, "Algebraic" -> 2, "Geometric" -> 2, 
       "Jordan" -> "diagonalizable"|>, <|"Eigenvalue" -> -1, 
       "Algebraic" -> 1, "Geometric" -> 1, "Jordan" -> "diagonalizable"|>, 
      <|"Eigenvalue" -> eps, "Algebraic" -> 1, "Geometric" -> 1, 
       "Jordan" -> "diagonalizable"|>}, "CharPoly" -> 
     HCT$lam^2*(1 + HCT$lam)*(-eps + HCT$lam)|>, 
  "Exponents" -> {0, 0, -1, eps}, "ExponentClasses" -> 
   {"integer", "integer", "integer", "integer"}, 
  "Balance" -> Missing["not rank-1"]|>, <|"Locus" -> -1 + w, "OrdAv" -> 0, 
  "OrdAw" -> 1, "Fuchsian" -> True, "EpsDependent" -> False, 
  "Residue" -> {{eps, 0, 0, 0}, {(1 + 6*eps + 8*eps^2)/(1 - v), -2*(1 + eps), 
     0, 0}, {-((eps*(1 + 4*eps))/v), 0, -2*(1 + eps), 0}, 
    {(1 + 6*eps + 8*eps^2)/(-1 + v), 0, 0, -2*(1 + eps)}}, 
  "Spectrum" -> <|"Status" -> "ok", "Eigenvalues" -> 
     {eps, -2*(1 + eps), -2*(1 + eps), -2*(1 + eps)}, "Rank" -> 4, 
    "Trace" -> -6 - 5*eps, "Detail" -> 
     {<|"Eigenvalue" -> eps, "Algebraic" -> 1, "Geometric" -> 1, 
       "Jordan" -> "diagonalizable"|>, <|"Eigenvalue" -> -2*(1 + eps), 
       "Algebraic" -> 3, "Geometric" -> 3, "Jordan" -> "diagonalizable"|>}, 
    "CharPoly" -> -((eps - HCT$lam)*(2 + 2*eps + HCT$lam)^3)|>, 
  "Exponents" -> {eps, -2*(1 + eps), -2*(1 + eps), -2*(1 + eps)}, 
  "ExponentClasses" -> {"integer", "integer", "integer", "integer"}, 
  "Balance" -> Missing["not rank-1"]|>}
