# Exact CF254 to CF305 powered-integral relation

## Result

CF254 and CF305 are not equivalent as complete powered families.  The
complete 23-master CF254 system does, however, embed exactly in the closed
`D6 = 0` subsector of the 32-master CF305 system.  The nine complementary
CF305 masters all have positive sixth power.

The relation requires a crossing of external rays.  It is not an equality in
the same physical chart:

\[
 k_a^{(254)}=-k_c^{(305)},\qquad
 k_b^{(254)}= k_b^{(305)},\qquad
 k_c^{(254)}=-k_a^{(305)},
 \qquad
 k_e^{(254)}=k_e^{(305)},\quad k_f^{(254)}=k_f^{(305)}.
\]

The loop Jacobian is one.  The signed external rays are permuted as
\((k_a,k_b,-k_c)\mapsto(-k_c,k_b,k_a)\), so their sum and hence the total cut
momentum are unchanged.

## Integral and cuts

Work in \(D=4-2\epsilon\) with the common pair-record measure

\[
 -\frac{d^D k_e\,d^D k_f}{\pi^D}.
\]

Both family coefficients are one.  Every ordinary denominator has the stored
Feynman tag `{1,1}`, and the cut convention is
`OrientedPositiveEnergyDelta`.  In pair-record order the source and target cut
data are

\[
 (2,8,1)_{254}\longmapsto(2,9,1)_{305},\qquad
 (k_e,k_a+k_b-k_c-k_e-k_f,k_f),\qquad (1,1,1).
\]

Thus all three cut momenta, their positive-energy orientations, and the
ordinary \(+i0\) prescriptions are retained.  The pair records also have the
same BMHV and dimensional metadata.  No evanescent dimension shift is made by
this scalar-family relation.

## Denominator map

Let the CF254 entries be

\[
\begin{aligned}
D_1&=k_f^2,&D_2&=k_e^2,&D_3&=(-k_a+k_e)^2,\\
D_4&=(-k_a+k_e+k_f)^2,&
D_5&=(-k_a+k_c+k_e+k_f)^2,&D_6&=(-k_c-k_f)^2,\\
D_7&=(k_a-k_c-k_f)^2,&
D_8&=(k_a+k_b-k_c-k_e-k_f)^2,&D_9&=k_b\!\cdot k_e.
\end{aligned}
\]

Let the nine CF305 quadratic denominators be \(E_1,\ldots,E_9\) in their
stored order.  Substitution of the displayed external and loop momenta gives

\[
(q_1,\ldots,q_8)_{254}
=(Q_1,Q_2,-Q_5,-Q_7,-Q_8,-Q_3,-Q_4,Q_9)_{305},
\]

and therefore

\[
\boxed{(D_1,D_2,D_3,D_4,D_5,D_6,D_7,D_8)
=(E_1,E_2,E_5,E_7,E_8,E_3,E_4,E_9).}
\]

The CF254 irreducible scalar product obeys the exact linear identity

\[
\boxed{2D_9=E_6-E_4+E_8-E_9.}
\]

Consequently a nonzero power of \(D_9\) does not become a single powered
CF305 denominator.  This is the obstruction to complete powered-family
equivalence.  Conversely, \(E_6\) is the additional CF305 denominator.

## Powered identity

For every integer power vector with zero CF254 ISP power, the dimensionful
cut integral satisfies

\[
\boxed{
\begin{aligned}
&I_{254}(a_1,a_2,a_3,a_4,a_5,a_6,a_7,a_8,0;
          -k_c,k_b,-k_a)\\
&\hspace{16mm}=
I_{305}(a_1,a_2,a_6,a_7,a_3,0,a_4,a_5,a_8;
          k_a,k_b,k_c).
\end{aligned}}
\]

This identity retains exact \(\epsilon\) dependence and the stated cut and
causal data.  Every one of the 23 CF254 masters has zero ninth power, and its
image occurs exactly once in the CF305 basis.  In CF254 order, the CF305
positions are

\[
p=(32,6,10,28,7,11,12,21,22,23,29,30,13,31,15,16,25,17,18,26,19,27,20).
\]

The complementary positions are

\[
q=(1,2,3,4,5,8,9,14,24).
\]

All entries at \(p\) have zero sixth power; all entries at \(q\) have positive
sixth power.

## Normalized kinematics

For each family define

\[
S=2k_a\!\cdot k_b,\qquad
v=\frac{2k_a\!\cdot k_c}{S},\qquad
w=\frac{2k_b\!\cdot k_c}{S}.
\]

The crossing gives

\[
S_{254}=-w_{305}S_{305},\qquad
v_{254}=-\frac{v_{305}}{w_{305}},\qquad
w_{254}=\frac1{w_{305}}.
\]

Thus the target physical region

\[
v_{305}>0,\qquad w_{305}>0,\qquad v_{305}+w_{305}<1
\]

maps to the crossed source chamber \(v_{254}<0\), \(w_{254}>1\).

For source master \(i\), let \(A_i=\sum_{r=1}^9 a_{ir}\).  Two-loop
homogeneity gives the normalized relation

\[
J_{305,p_i}(v,w)=H_i(v,w)
J_{254,i}\!\left(-\frac vw,\frac1w\right),\qquad
H_i=\exp\!\left[(D-A_i)\,L_\times(-w)\right].
\]

Here \(L_\times\) is the crossed Feynman logarithm inherited from the
dimensionful identity with the unchanged \(+i0\) tags.  It is deliberately
not replaced by an unqualified principal logarithm.  The rational
differential relation uses only \(dL_\times(-w)=dw/w\).  Transfer of boundary
constants must use the same dimensionful continuation; the DE relation alone
does not choose a different boundary value.

## Differential system

Write

\[
d\boldsymbol J_F=\Omega_F\boldsymbol J_F,
\qquad
\Omega_F=A_{F,v}\,dv+A_{F,w}\,dw,
\]

and let \(S\) be the \(23\times32\) selection matrix
\(S_{ij}=\delta_{j,p_i}\).  Let \(Q\) select the complementary positions and
let

\[
\Phi(v,w)=\left(-\frac vw,\frac1w\right),\qquad
H=\operatorname{diag}(H_1,\ldots,H_{23}).
\]

The exact one-form criterion is

\[
\boxed{
S\Omega_{305}=
\left[dH\,H^{-1}+H\,\Phi^*(\Omega_{254})\,H^{-1}\right]S.
}
\]

Equivalently, closure and equality of the selected connection are

\[
S A_{305,\mu}Q^T=0,
\qquad
S A_{305,\mu}S^T=B_\mu,
\qquad \mu\in\{v,w\},
\]

with

\[
\begin{aligned}
B_v&=H\left[-\frac1w A_{254,v}\!\circ\Phi\right]H^{-1},\\
B_w&=\operatorname{diag}\!\left(\frac{D-A_i}{w}\right)
+H\left[\frac{v}{w^2}A_{254,v}\!\circ\Phi
-\frac1{w^2}A_{254,w}\!\circ\Phi\right]H^{-1}.
\end{aligned}
\]

This distinguishes differential closure from denominator-set equality: the
former is exact on the selected master module even though arbitrary powers of
the CF254 ISP do not define a monomial map to CF305.

## Kallen chart

CF254 uses `Kallen13`, while CF305 uses `Kallen23`.  Let \((Y,S)\) denote the
CF254 chart coordinates and \((y,s)\) the CF305 coordinates.  The birational
lift of \(\Phi\) is

\[
\boxed{
Y=\frac{y}{y-1},\qquad
S=-\frac{sy+s-5y+3}{sy-s-y+1}.
}
\]

Its inverse is

\[
y=\frac{Y}{Y-1},\qquad
s=\frac{S+2Y+3}{S+2Y-1}.
\]

For

\[
\lambda_1=(1-v-w)^2-4vw,\qquad
\lambda_2=\lambda_1(-v,w),\qquad
\lambda_3=\lambda_1(v,-w),
\]

the crossing obeys

\[
\lambda_1\!\left(-\frac vw,\frac1w\right)=\frac{\lambda_2(v,w)}{w^2},
\qquad
\lambda_3\!\left(-\frac vw,\frac1w\right)=\frac{\lambda_3(v,w)}{w^2}.
\]

The chart branches used in the transfer record are

\[
\boxed{r_{1,254}=-\frac{r_{2,305}}{w},\qquad
r_{3,254}=+\frac{r_{3,305}}{w}.}
\]

Both chart compositions and both signed root identities vanish exactly.

## Exact tests

`verify_de_relation_maple.py` uses exact rational arithmetic over
\(\mathbb Q(\epsilon,v,w)\); it does not evaluate the integrals at numerical
kinematics.  Its acceptance criterion is stated before calculation.  The
executed result was

- 10 chart, inverse-chart, and root identities equal to zero;
- 414 selected-row/complement closure entries equal to zero;
- 1,058 transformed-connection entries equal to zero;
- every denominator, ISP, cut, causal-tag, and master-map condition satisfied.

Only after these results were obtained did the script write
`CF254ToCF305Transfer.json` and `MapleExactVerification.json`.

The native checker `check_and_build_transfer_cf254_to_cf305.wls` independently
reconstructs the same relations from the pair and DE records and writes
`CF254ToCF305Transfer.wl` atomically only after all named exact conditions are
satisfied.  It was not executed during this calculation because the two
licensed Wolfram master slots were occupied.  No Wolfram kernel or FrontEnd
was launched.
