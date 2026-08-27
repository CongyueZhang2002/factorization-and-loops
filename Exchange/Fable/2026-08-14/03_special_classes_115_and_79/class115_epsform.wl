(* ============================================================
   FeynFacet canonicalization campaign -- CLASS 115  (2x2, rep CF299 rows {1,2})
   STATUS: SOLVED.  Exact eps-form + closed form.  All checks exact (sympy 1.14).

   KEY STRUCTURAL FACT
     Av = M[v w]/v ,  Aw = M[v w]/w   with the SAME matrix M depending on v,w
     only through the product  z = v w.   [Av,Aw] = 0.
     => the block is a ONE-VARIABLE system:   z dF/dz = M[z] F.
     => in ANY chart (v,y) whose 2nd variable is a function of z alone,
        A_v == 0 IDENTICALLY.  This is why CANONICA "refuses instantly":
        it is handed a 2-variable system with a null direction, not a
        genuine non-rationalizability obstruction.
   ============================================================ *)

Class115$z       = v*w;                       (* the only variable *)
Class115$u       = Sqrt[1 - 4 v w];           (* rationalizing variable, u^2 = 1-4vw *)

(* ---- ORIGINAL system (as stored in classes.wl) ---- *)
Class115$Av = {{(-1-4 eps)/(2 v), 1/(2 v)},
               {(1+10 eps+24 eps^2)/(2 v (-1+4 v w)), (-1-6 eps-8 v w-8 eps v w)/(2 v (-1+4 v w))}};
Class115$Aw = {{(-1-4 eps)/(2 w), 1/(2 w)},
               {(1+10 eps+24 eps^2)/(2 w (-1+4 v w)), (-1-6 eps-8 v w-8 eps v w)/(2 w (-1+4 v w))}};

(* ---- SCALAR ODE (component F1), x = 4 v w ---- *)
(*  4x(x-1) F1'' + [(10+12 eps) x + 4 eps - 4] F1' + 2(1+4 eps)(1+eps) F1 = 0
    = Gauss hypergeometric with
        a = 1 + eps ,  b = 1/2 + 2 eps ,  c = 1 - eps ,   x = 4 v w
    exponent differences: 1-c = eps ; c-a-b = -1/2-4 eps ; a-b = 1/2-eps
    F2 = 2 x dF1/dx + (1+4 eps) F1                                          *)
Class115$HypergeometricParameters = <|"a"->1+eps, "b"->1/2+2 eps, "c"->1-eps, "x"->4 v w|>;

Class115$ClosedForm = {
  (* general all-orders solution of the block, c1,c2 fixed by boundary data *)
  F1 -> c1 Hypergeometric2F1[1+eps, 1/2+2 eps, 1-eps, 4 v w]
      + c2 (4 v w)^eps Hypergeometric2F1[1+2 eps, 1/2+3 eps, 1+eps, 4 v w],
  F2 -> 2 (4 v w) D[F1, 4 v w] + (1+4 eps) F1
};

(* ---- LOCAL EXPONENT DATA ---- *)
(*  system F' = M[z]/z F :
      z = 0    : {0, eps}
      z = 1/4  : {0, -3/2 - 4 eps}      <-- the half-integer obstruction in (v,w)
      z = Inf  : {1+eps, 1/2+2 eps}
    after u^2 = 1-4 v w  (exponents at u=0 double):
      u = 0    : {0, -3 - 8 eps}        integer part -3, removable by 3 balances
      u = +-1  : {0, eps}
      u = Inf  : {1+4 eps, 2+2 eps}
    NO eps-form exists over Q(v,w): -3/2 is not an integer, so no rational
    gauge can shift it away.  Over Q(u) it does exist -- constructed below.   *)

(* ---- CANONICAL (eps-)FORM ---- *)
(*  J = Class115$Uinv . F        with u = Sqrt[1-4 v w]                       *)
Class115$Uinv = {{ Sqrt[1-4 v w], 0 },
                 { -(1+8 eps)/eps, (1-4 v w)/eps }};
Class115$U    = {{ 1/u, 0 }, { (1+8 eps)/u^3, eps/u^2 }} /. u -> Sqrt[1-4 v w];

(*  dJ = eps ( N0 dlog[u] + N1 dlog[1-u] + Nm1 dlog[1+u] ) J                  *)
Class115$N0  = {{-8, 0}, {0, 0}};                (* eigenvalues {0,-8} *)
Class115$N1  = {{2, 1/2}, {-4, -1}};             (* eigenvalues {0, 1} *)
Class115$Nm1 = {{2, -1/2}, {4, -1}};             (* eigenvalues {0, 1} *)
(*  N0+N1+Nm1 = -{{4,0},{0,2}} = -N_Inf ,  eigenvalues {4,2}                  *)
Class115$Alphabet = { u, 1-u, 1+u } /. u -> Sqrt[1-4 v w];

(* ---- CERTIFICATES (all verified exactly) ----
   C1 (u-chart)  : Uinv.A(u).U - Uinv.dU/du == eps (N0/u + N1/(u-1) + Nm1/(u+1))   -> 0
   C2 (v,w-chart): Uinv.Av.U - Uinv.d_v U == eps (N0 d_v log u + N1 d_v log(1-u) + Nm1 d_v log(1+u)) -> 0
                   same for w                                                       -> 0
   C3            : det U = eps/u^3  (invertible for eps != 0, u != 0)
   C4            : Av = M[vw]/v, Aw = M[vw]/w exactly; [Av,Aw] = 0; integrable.
   C5            : A_v == 0 identically in BOTH charts w=(1+t^2)/(4v) and w=(1-u^2)/(4v).
   ---------------------------------------------------------------------------- *)

(* ---- PHYSICAL CHAMBER / SIGN ----
   identity:  1 - 4 v w == (v-w)^2 + (1-v-w)(1+v+w)
   In the chamber 0<v,w, v+w<1 BOTH terms are >0, so 1-4vw > 0 and
       u = Sqrt[1-4 v w] in (0,1]  is REAL.
   The earlier chart -1+4vw = t^2 gives t = I u : IMAGINARY in the chamber.
   Use  w = (1-u^2)/(4 v).    (This sign error is real but was NOT the cause
   of the CANONICA refusal -- see C5.)
   ---------------------------------------------------------------------------- *)

(* ---- WEIGHT / EXPANSION ----
   Alphabet {u,1-u,1+u} => the eps-expansion of J is harmonic polylogarithms
   H(a1,...,an; u) with a_i in {0,1,-1}.  Natural boundary point u=1 (v w = 0).
   J1 = Sqrt[1-4 v w] F1 ;  J2 = ((1-4 v w) F2 - (1+8 eps) F1)/eps.
   ---------------------------------------------------------------------------- *)
