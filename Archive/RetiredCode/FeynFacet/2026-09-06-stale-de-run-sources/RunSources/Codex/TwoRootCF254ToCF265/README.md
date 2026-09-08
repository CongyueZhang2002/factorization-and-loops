# CF254 to CF265 powered-integral embedding

## Result

There is an exact embedding of the complete 23-master CF254 system into a
23-dimensional subsector of CF265.  There is **not** an equivalence between the
complete CF254 and CF265 families: CF265 has 32 masters and contains one
additional ordinary denominator.

Use `check_and_build_transfer_cf254_to_cf265.wls` to verify the denominator
identity, cut orientation, master permutation, differential-equation closure,
and chart identity.  The script writes `CF254ToCF265Transfer.wl` only if every
exact check is satisfied.

No family/class label enters the proof.  The existing equivalence catalogues
are used only as an independent comparison after the powered-integral identity
has been derived from the denominators.

## Exact identity

Let the CF254 denominator list be \(D_1,\ldots,D_9\), and the CF265 list be
\(E_1,\ldots,E_9\), with the cut prescription and measure fixed as in the pair
records.  Direct inspection gives

\[
D_i=E_i\quad (i=1,\ldots,7),
\qquad D_8=E_9.
\]

The remaining entries are different:

\[
D_9=2k_b\!\cdot k_e,
\qquad
E_8=(k_a+k_b-k_c-k_f)^2.
\]

All 23 CF254 masters have zero power of \(D_9\).  Therefore, for every integer
power vector \(\boldsymbol a=(a_1,\ldots,a_8,0)\) occurring in the CF254
master basis,

\[
\boxed{
 I_{254}(a_1,a_2,a_3,a_4,a_5,a_6,a_7,a_8,0;v,w,\epsilon)
 =
 I_{265}(a_1,a_2,a_3,a_4,a_5,a_6,a_7,0,a_8;v,w,\epsilon)
 }.
\]

The loop-momentum transformation is the identity,

\[
k_e^{(265)}=k_e^{(254)},\qquad
k_f^{(265)}=k_f^{(254)},
\]

so its Jacobian is one.  The three cut momenta map as

\[
k_e\mapsto k_e,\qquad
k_a+k_b-k_c-k_e-k_f\mapsto k_a+k_b-k_c-k_e-k_f,
\qquad k_f\mapsto k_f,
\]

with unchanged positive-energy orientation.  Thus no crossing, sign change,
or causal-prescription change is involved.

## Master permutation

Write \(\boldsymbol I_{254}\) in the 23-entry order stored in
`nnlo_de_CF254.wl`, and \(\boldsymbol I_{265}\) in the 32-entry order stored in
`nnlo_de_CF265.wl`.  The source entries occur at the following CF265 positions:

\[
p=(29,4,5,6,7,9,10,12,13,14,16,17,18,19,20,21,22,24,25,28,30,31,32).
\]

If \(S\) is the \(23\times32\) selection matrix
\(S_{i j}=\delta_{j,p_i}\), then the exact integral relation is

\[
\boldsymbol I_{254}=S\,\boldsymbol I_{265}.
\]

The complementary CF265 positions are

\[
q=(1,2,3,8,11,15,23,26,27).
\]

For differential systems

\[
d\boldsymbol I_F=
\left(A_{F,v}\,dv+A_{F,w}\,dw\right)\boldsymbol I_F,
\]

the identity to be checked is

\[
S A_{265,v}=A_{254,v}S,
\qquad
S A_{265,w}=A_{254,w}S.
\]

Equivalently,

\[
(A_{265,x})_{p,p}=A_{254,x},\qquad
(A_{265,x})_{p,q}=0,qquad x\in\{v,w\}.
\]

These equations prove that the mapped 23-dimensional sector is closed under
the two physical derivatives.  They also specify exactly how a solved CF254
epsilon form is reused: its ordered transformation matrix and epsilon-form
connection apply unchanged to the selected CF265 vector
\(S\boldsymbol I_{265}\).  They do not determine the nine complementary
CF265 masters.

## Chart transformation

Both records use the same `Kallen13` chart.  The physical and chart variables
are therefore identified without an additional substitution:

\[
v_{265}=v_{254},\qquad w_{265}=w_{254},\qquad
y_{265}=y_{254},\qquad s_{265}=s_{254}.
\]

In both records,

\[
v=\frac{(1+s)y(-3+s+2y)}{-1+s^2+4y-4y^2},
\qquad
w=-\frac{2(1-y)^2(1+s+2y)}{1-s^2-4y+4y^2}.
\]

Because the two substitutions and Jacobians are identical, the CF254 epsilon
form in \((y,s)\) transfers to the mapped CF265 sector without another pullback.

## Independent catalogue comparison

The exact block catalogue places the coefficient master

\[
I_{254}(1,1,1,1,0,1,1,1,0)
\]

and

\[
I_{265}(1,1,1,1,0,1,1,0,1)
\]

in the same one-dimensional differential block.  Both member-to-canonical
maps exchange \(v\) and \(w\), so their direct member-to-member kinematic map
is again the identity.  This agrees with, but is not used to establish, the
denominator-level derivation above.

