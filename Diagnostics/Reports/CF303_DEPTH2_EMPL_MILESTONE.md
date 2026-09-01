# CF303 first physical mixed GPL/eMPL coefficient

Status: `CF303DepthTwoPhysicalMaster5AcceptedV1`

The first nonconstant elliptic feeder has been reduced to a finite mixed word with no unevaluated integral.  It is the unique chain

\[
I_5\ \longleftarrow\ (F_{23}+F_{24})\ \longleftarrow\ C_{23}^{(0)}
\]

in the assembly slots \(44,45\leftarrow 23,24\leftarrow23\).  Let

\[
Y(u)^2=P_4(p,u),\qquad c=2p(1-p),\qquad u_0=\frac12,
\]

and choose one continued marked-point value \(Y_c\), with

\[
Y_c^2=P_4(p,c)
=16p^2(p-2)^2(p-1)^2(p^2-p-1)^2.
\]

The normalized mixed word is

\[
\mathcal E_{c,c}(u)=
\int_{u_0}^{u}\frac{Y_c\,dt_1}{(t_1-c)Y(t_1)}
\int_{u_0}^{t_1}\frac{dt_2}{t_2-c}.
\]

The inner GPL letter comes from the exact even projection

\[
\left[\epsilon^{-1}(A_{23,23}+A_{24,23})\right]_{\rm even}
=3\,d\log D_{\rm curve}-d\log P_4-d\log(u-c),
\]

where \(D_{\rm curve}=4p^2-4p-u^2\).  The outer raw residues at \(u=c\) are

\[
r_{44,c}=\frac{12(p^2-p-1)p^4}{p-2},\qquad
r_{45,c}=\frac{8(p^2-p-1)p^4}{p-2}.
\]

After applying the exact block-25 source gauge, the contribution to physical master 5 at order \(\epsilon^{-1}\) is

\[
I_5^{(-1)}\supset
\mathcal C_5(p,u)\,C_{23}^{(0)}\,\mathcal E_{c,c}(u),
\]

with

\[
\mathcal C_5(p,u)=
\frac{
2(p^2-p-1)p^2(4p^2-u^2-4p)^4
}{
(p-1)(p-2)u^2(u+2)^2\,D_5(p,u)\,Y_c
},
\]

\[
D_5(p,u)=
8p^5-2p^3u^2-24p^4+4p^3u+2p^2u^2-pu^3
+24p^3-12p^2u-8p^2+8pu-2u^2.
\]

Here \(C_{23}^{(0)}\) is the canonical block-15 boundary constant.  In terms of physical boundary data it is

\[
C_{23}^{(0)}=
\left[ e_{23}^{T}(S^{-1}T_{\rm diagonal}^{-1})(u_0,\epsilon)b
\right]_{\epsilon^0}.
\]

## Acceptance evidence

- The completed quartic reducer retains all previous 40 CF303 reductions unchanged and passes adversarial quadratic-remainder and polynomial-primitive cases.
- The integration-by-parts recursion decreases word length strictly.
- It produces 35 finite mixed words for row 44 and 35 for row 45 in about 1.1 seconds per row.
- Differentiating both complete 35-term results gives the original feeder exactly: residual counts `(0,0)`.
- Quadratic finite-pole factors are kept root-free internally and split only at export; this removes artificial radical blow-up while preserving the standard linear marked-point word displayed above.
- The block-25 source gauge is residual-root even.  Its first-row entries have epsilon support `{0,1}`, so the displayed physical \(\epsilon^{-1}\) term uses precisely the order-zero gauge coefficients.

Artifacts:

- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_mixed_solution.maple`
- `Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_physical_master5.maple`
- `Diagnostics/Scripts/build_cf303_depth2_mixed_solution.mpl`
- `Diagnostics/Scripts/project_cf303_depth2_physical_master5.mpl`

This is one complete, paper-facing physical word coefficient, not yet the full \(I_5^{(-1)}\) coefficient or the full four-block elliptic solution.
