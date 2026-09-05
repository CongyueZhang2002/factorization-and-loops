# Manuscript 07 NNLO Double Real

## Question

The attached LaTeX file is the current complete NNLO double-real section.  The
Mathematica ancillary file contains the exact analytic Laurent coefficients,
the handoff records the accepted normalization and derivation, and the AMFlow
comparison file records the independent fixed-point values.  Use those files
to review and rewrite this section only.

Return:
1. A concise list of unsupported claims, wrong counts, normalization or branch
   errors, and equations that cannot be justified from the stated family.
2. Compilable replacement LaTeX for this section only.

Check in detail:
- the precise meanings of 342 masters, 130 powered-integral classes, 82
  positive-denominator classes, and 17 maximal nontrivial denominator classes;
- that 17 is not called a boundary-period count;
- the exact scope of the representative Ratracer/FireFly coefficient;
- the displayed physical two-loop cut master, all nine family slots, and the
  eight-master basis;
- the fixed-sign arguments for all ordinary real-emission denominators;
- the raw and canonical differential equations, alphabet, physical chamber,
  and flatness;
- the nonuniform boundary, Frobenius recurrence, and finite boundary matching;
- the stated corner period and every coefficient through epsilon^2;
- the normalization of the displayed top master and the AMFlow comparison;
- the statement about the two other stored families.

Numerical AMFlow values are comparisons only. Do not claim the full 342-master
basis has been solved analytically. If a displayed formula cannot be checked
from the attached sources, flag it rather than replacing it by an invented
expression.  In particular, derive and display the relation between
\(\widehat G_7=s^4G_7/G_1(s,0,0;\epsilon)\) and the fixed-point ratio
\(R=s^4G_7/G_1(s,t,u;\epsilon)\).  At the stated point the former has
leading coefficient \(-5/\Delta^2=-20\), while the latter has coefficient
\(-40\); these are consistent only after the phase-space-volume ratio is
included explicitly.  Do not rewrite another section.

## Pro response

1. Corrections and qualifications required

The opening claim that the remaining NNLO problem is only master evaluation is too strong. The cut-aware double-real IBP reduction is complete, but only one representative nontrivial rational master coefficient has undergone the complete Ratracer/FireFly reconstruction and characteristic-zero identity check. Reconstruction of the remaining coefficients is separate from analytic evaluation of the remaining masters.

The numbers

342,130,82,17

classify different objects. The 342 objects are Kira basis integrals; 130 is the quotient retaining every index; 82 is the quotient after replacing positive powers by one and recanonicalizing; 17 is the number of maximal nontrivial positive-denominator classes under exact inclusion. The 17 classes are not a count of differential systems, Frobenius constants, direct boundary integrations, or new periods.

The representative finite-field calculation contains 1,129 nonzero target-to-master contributions, not 1,129 ordered diagram pairs. It proves one exact coefficient only.

The displayed two-loop integral is not normalized consistently with the family definition. A raw
\dd
D
k
e
	​

\dd
D
k
f
	​

δ
+
	​

δ
+
	​

δ
+
	​


integral is not the same object as the normalized GLI master. The replacement defines G
7
	​

 with
\dd
D
k/(iπ
D/2
) and normalized cuts, and separately gives its exact conversion to the physical phase-space convention.

The four ordinary denominators have fixed weak signs and no zeros in the open phase space. They can vanish on soft or collinear boundary strata. Omitting i0 therefore uses the previously established meromorphic endpoint definition; it is not a pointwise equality of opposite boundary-value distributions.

D
4
	​

=k
a
	​

⋅k
f
	​

 and D
5
	​

=k
b
	​

⋅k
e
	​

 are auxiliary scalar-product slots, not physical propagators. Their indices are zero in all eight displayed masters.

The raw differential system must be derived with tangent derivatives of the physical on-shell kinematics. Differentiating replacement symbols s,t,u while holding loop–external scalar products fixed would not produce the displayed system.

The matrices A
x
	​

,A
y
	​

, the full rational transformation T, and the constant residues R
a
	​

 are not contained explicitly in the supplied Laurent-coefficient ancillary file. Their flatness, dlog reconstruction, and alphabet are recorded in the accepted handoff, but their individual matrix entries cannot be re-audited from this archive. The replacement states their verified properties without inventing entries.

The displayed Moser matrix is a two-dimensional top-block transformation that removes the rank-one double pole. It is not by itself the full eight-dimensional canonical transformation.

The limit y→0
+
 is nonuniform. Substituting y=0 directly into the two-variable canonical transformation is invalid. The boundary family must be derived independently with k
c
	​

=xk
b
	​

.

The Frobenius matching requires both

C
−1
	​

b
0
	​

=0

and

f
λ
	​

=C
0
	​

b
0
	​

+C
−1
	​

b
1
	​

.

The current draft omits the first condition.

The three-fold corner representation and its Laurent coefficients through ϵ
2
 agree with the handoff. Its real branch follows from positivity of
α,β,γ,1−α,1−β,1−αβ, and
1−αβγ on the open unit cube.

The target coefficients g
−4
	​

,…,g
2
	​

 are all present exactly in the Mathematica ancillary. Only g
−3
	​

 and g
−2
	​

 are short enough to display in the article. The longer coefficients should remain in the ancillary rather than be replaced by an unsupported compressed formula.

The normalization of the analytic target and the AMFlow ratio differs:

G
7
	​

=
G
1
	​

(s,0,0;ϵ)
s
4
G
7
	​

	​

,R=
G
1
	​

(s,t,u;ϵ)
s
4
G
7
	​

	​

.

Since

G
1
	​

(s,t,u;ϵ)=Δ
1−2ϵ
G
1
	​

(s,0,0;ϵ),

one has

R=Δ
−1+2ϵ
G
7
	​

.

At Δ=1/2, this converts the leading coefficient
−5/Δ
2
=−20 of 
G
7
	​

 into −40 for R.

The two other stored families may be stated to have exact GPL solutions through ϵ
2
 with independent AMFlow comparisons. They do not establish analytic completion of the 342-master basis.

LaTeX
\section{NNLO double-real sector}
\label{sec:nnlo-double-real}

The NNLO double-real contribution contains two independent phase-space
integration momenta after momentum conservation has been imposed.  For the
unpolarized process considered here, the cut-aware IBP reduction has been
completed exactly.  This determines the master basis and the rational
reduction of every requested target integral.  It does not by itself
determine the analytic values of the masters, and the complete rational
coefficient reconstruction has so far been carried out only for a selected
nontrivial master coefficient.  The results below therefore establish the
double-real integral reduction, one representative coefficient
reconstruction, and analytic solutions of selected master families; they do
not constitute a complete NNLO hard function.

\subsection{Exact master and denominator classification}
\label{subsec:nnlo-denominator-classification}

Let
\begin{equation}
 \mathfrak M_{\rm DR}
 =
 \{M_1,\ldots,M_{342}\}
 \label{eq:nnlo-master-set}
\end{equation}
be the master basis selected by the corrected double-real Kira reduction.
Its cardinality is
\begin{equation}
 N_{\rm master}^{\rm NNLO}=342.
 \label{eq:nnlo-master-count}
\end{equation}
This number counts individual powered GLIs in the chosen Kira basis.  It is
not invariant under a change of master ordering or basis.

On the carrier set \(\mathfrak M_{\rm DR}\), quotienting by the
powered-integral equivalence relation of
Eq.~\eqref{eq:powered-equivalence-section5} gives
\begin{equation}
 \left|
  \mathfrak M_{\rm DR}/{\sim_{\rm pow}}
 \right|
 =
 130.
 \label{eq:nnlo-powered-class-count}
\end{equation}
Every denominator and every index, including a differentiated cut, is
retained in this quotient.

For each master, replace every positive index by one, retain the cut
identity, cut orientation, ordinary causal class, and measurement labels,
and then repeat the complete certified relabeling test.  The resulting
positive-denominator quotient has
\begin{equation}
 \left|
  \mathfrak M_{\rm DR}/{\sim_{\rm den}}
 \right|
 =
 82.
 \label{eq:nnlo-denominator-class-count}
\end{equation}
One of these 82 classes contains only the three physical cuts.  The other
81 contain at least one ordinary denominator.

Let
\begin{equation}
 \preceq_{\rm den}
 \label{eq:nnlo-denominator-inclusion-symbol}
\end{equation}
denote exact inclusion of positive-denominator sets after an allowed
relabeling, as defined in Sec.~\ref{subsec:master-relations}.  Among the 81
nontrivial classes,
\begin{equation}
 N_{\rm max,nontrivial}^{\rm NNLO}=17
 \label{eq:nnlo-maximal-class-count}
\end{equation}
are maximal under \(\preceq_{\rm den}\).  The remaining 64 nontrivial
classes are included in at least one of these 17 classes, and no nontrivial
class is left without a maximal ancestor.

The exact classification is therefore
\begin{equation}
 342
 \ \longrightarrow\
 130
 \ \longrightarrow\
 82
 \ \longrightarrow\
 17,
 \label{eq:nnlo-classification-chain}
\end{equation}
where the arrows mean, respectively, quotienting by powered-integral
equivalence, quotienting by positive-denominator equivalence, and selecting
the maximal nontrivial elements of the denominator-inclusion partial order.
The final number is a statement about integral geometry.  It is not the
number of closed differential systems, free Frobenius coefficients, direct
boundary integrations, or new analytic periods.

\subsection{Exact reconstruction of one representative coefficient}
\label{subsec:nnlo-representative-coefficient}

As a scaling test of the post-IBP coefficient calculation, consider the
stored master
\begin{equation}
 M_{64}
 =
 \operatorname{GLI}
 \!\left[
  \mathrm{TopologyF10C25N1},
  \{1,1,2,0,0,1,0,1,0\}
 \right].
 \label{eq:nnlo-reconstructed-master}
\end{equation}
Its coefficient receives
\begin{equation}
 N_{64}^{\rm contrib}=1129
 \label{eq:nnlo-reconstructed-contribution-count}
\end{equation}
nonzero target-to-master contributions.  After the exact PDF/FF,
momentum-fraction, scale, and analytic monomials had been removed, the
remaining coefficient belonged to
\begin{equation}
 \mathbb Q(C_A,C_F,\eps,x,y).
 \label{eq:nnlo-reconstruction-field}
\end{equation}

The complete sparse composition was recorded as one rational operation graph
and reconstructed by \Ratracer\ and \FireFly.  Two reconstructions with
independent random seeds and prime sequences returned the same reduced
rational function.  An independent evaluator reread the original target and
Kira records and agreed at 48 nonsingular points over three prime fields not
used for reconstruction.  Finally, the characteristic-zero identity
\begin{equation}
 \operatorname{Together}
 \left[
  \sum_{t=1}^{1129}
  c_t(C_A,C_F,\eps,x,y)\,
  R_{t,64}(C_A,C_F,\eps,x,y)
  -
  C_{64}^{\rm rec}(C_A,C_F,\eps,x,y)
 \right]
 =
 0
 \label{eq:nnlo-coefficient-characteristic-zero}
\end{equation}
was evaluated exactly over
\(\mathbb Q(C_A,C_F,\eps,x,y)\).

Equation~\eqref{eq:nnlo-coefficient-characteristic-zero} establishes one
exact post-IBP coefficient.  It does not evaluate \(M_{64}\), reconstruct
the remaining 341 master coefficients, or establish the complete NNLO
double-real hard function.

\subsection{A coupled eight-master three-particle-cut family}
\label{subsec:nnlo-eight-master-family}

We now consider a separate analytic master-family calculation.  Let the
external momenta be massless and satisfy
\begin{equation}
 k_a^2=k_b^2=k_c^2=0,
 \qquad
 2k_a\cdot k_b=s,
 \qquad
 -2k_a\cdot k_c=t,
 \qquad
 -2k_b\cdot k_c=u.
 \label{eq:nnlo-worked-kinematics}
\end{equation}
Define
\begin{equation}
 q:=k_a+k_b-k_c,
 \qquad
 x:=-\frac{t}{s},
 \qquad
 y:=-\frac{u}{s},
 \qquad
 \Delta:=1-x-y=\frac{q^2}{s}.
 \label{eq:nnlo-worked-variables}
\end{equation}
The analytic solution is constructed in the real chamber
\begin{equation}
 0<y<(1-x)^2<1-x<1.
 \label{eq:nnlo-worked-chamber}
\end{equation}
This implies
\begin{equation}
 0<x<1,
 \qquad
 0<y<1,
 \qquad
 \Delta>0,
 \qquad
 (1-x)^2-y>0.
 \label{eq:nnlo-letter-positivity}
\end{equation}

Let
\begin{equation}
 k_g:=q-k_e-k_f.
 \label{eq:nnlo-third-cut-momentum}
\end{equation}
The nine family slots are
\begin{align}
 D_1&=k_e^2,
 &
 D_2&=k_f^2,
 &
 D_3&=k_g^2,
 \notag\\
 D_4&=k_a\cdot k_f,
 &
 D_5&=k_b\cdot k_e,
 &
 D_6&=(q-k_e)^2,
 \notag\\
 D_7&=(q-k_f)^2,
 &
 D_8&=(k_a-k_c-k_f)^2,
 &
 D_9&=(k_a-k_e)^2.
 \label{eq:nnlo-family-denominators}
\end{align}
The first three slots are the physical cuts.  The fourth and fifth slots
complete the scalar-product basis; they are not physical propagators and
have zero index in every master displayed below.

Using the normalized measure and cut convention of
Appendix~\ref{app:conventions}, define
\begin{align}
 I_{\boldsymbol\nu}
 :={}&
 \int
 \frac{\dd^Dk_e}{i\pi^{D/2}}
 \frac{\dd^Dk_f}{i\pi^{D/2}}
 \prod_{c=1}^{3}
 \mathcal C_+^{(\nu_c)}(D_c;k_c)
 \prod_{j=4}^{9}D_j^{-\nu_j},
 \label{eq:nnlo-worked-family}
\end{align}
where
\begin{equation}
 (k_1,k_2,k_3):=(k_e,k_f,k_g)
 \label{eq:nnlo-cut-momentum-order}
\end{equation}
and \(I_{\boldsymbol\nu}=0\) if any of
\(\nu_1,\nu_2,\nu_3\) is nonpositive.

The normalized top master is
\begin{equation}
 G_7
 =
 I_{\{1,1,1,0,0,1,1,1,1\}}.
 \label{eq:nnlo-top-normalized-integral}
\end{equation}
Its physical phase-space normalization is
\begin{align}
 G_{7,\rm phys}
 :={}&
 \int
 \frac{\dd^Dk_e}{(2\pi)^D}
 \frac{\dd^Dk_f}{(2\pi)^D}
 \frac{
  (2\pi)^3
  \delta_+(k_e^2)
  \delta_+(k_f^2)
  \delta_+(k_g^2)
 }{
  D_6D_7D_8D_9
 },
 \label{eq:nnlo-top-physical-integral}
\end{align}
and the two conventions are related exactly by
\begin{equation}
 G_{7,\rm phys}
 =
 \left(
  \frac{i\pi^{D/2}}{(2\pi)^D}
 \right)^2
 (2\pi)^3
 G_7.
 \label{eq:nnlo-top-measure-conversion}
\end{equation}

The ordinary denominators have fixed signs in the open physical phase
space.  Momentum conservation gives
\begin{align}
 D_6
 &=
 (k_f+k_g)^2
 =
 2k_f\cdot k_g
 \geq0,
 \notag\\
 D_7
 &=
 (k_e+k_g)^2
 =
 2k_e\cdot k_g
 \geq0,
 \notag\\
 D_8
 &=
 (k_e+k_g-k_b)^2
 =
 (k_b-k_e-k_g)^2
 \leq0,
 \notag\\
 D_9
 &=
 -2k_a\cdot k_e
 \leq0.
 \label{eq:nnlo-ordinary-denominator-signs}
\end{align}
The inequalities are strict in the nonsoft and noncollinear interior.
Zeros occur only on physical boundary strata.  The fixed-sign theorem of
Appendix~\ref{app:fixed-sign}, together with the endpoint-meromorphy
analysis of this family, therefore defines the prescription-free
dimensionally regulated integrals in
Eq.~\eqref{eq:nnlo-worked-family}.  No pointwise product of opposite
boundary-value distributions is assumed.

Cut-aware IBP reduction closes on the ordered basis
\begin{equation}
 \begin{aligned}
  G_1&=I_{\{1,1,1,0,0,0,0,0,0\}},
  &
  G_2&=I_{\{1,1,1,0,0,0,0,1,0\}},
  \\
  G_3&=I_{\{1,1,1,0,0,0,0,1,1\}},
  &
  G_4&=I_{\{1,1,2,0,0,0,0,1,1\}},
  \\
  G_5&=I_{\{1,1,1,0,0,1,0,1,0\}},
  &
  G_6&=I_{\{1,1,1,0,0,1,0,1,1\}},
  \\
  G_7&=I_{\{1,1,1,0,0,1,1,1,1\}},
  &
  G_8&=I_{\{1,1,2,0,0,1,1,1,1\}}.
 \end{aligned}
 \label{eq:nnlo-eight-master-basis}
\end{equation}
The doubled third cut in \(G_4\) and \(G_8\) is a differentiated version of
the same physical cut, not an additional cut line.  The top block
\((G_7,G_8)\) is coupled under kinematic differentiation.

\subsection{Raw and canonical differential equations}
\label{subsec:nnlo-differential-system}

The derivatives with respect to the physical invariants are represented by
the tangent vector fields
\begin{align}
 \mathcal D_s
 &:=
 \frac{
  k_a\cdot\partial_{k_a}
  +k_b\cdot\partial_{k_b}
  -k_c\cdot\partial_{k_c}
 }{2s},
 \notag\\
 \mathcal D_t
 &:=
 \frac{
  k_a\cdot\partial_{k_a}
  -k_b\cdot\partial_{k_b}
  +k_c\cdot\partial_{k_c}
 }{2t},
 \notag\\
 \mathcal D_u
 &:=
 \frac{
  -k_a\cdot\partial_{k_a}
  +k_b\cdot\partial_{k_b}
  +k_c\cdot\partial_{k_c}
 }{2u}.
 \label{eq:nnlo-on-shell-derivatives}
\end{align}
They satisfy
\begin{equation}
 \mathcal D_r r'= \delta_{rr'},
 \qquad
 r,r'\in\{s,t,u\},
 \label{eq:nnlo-derivative-action}
\end{equation}
while preserving the external on-shell constraints.

The mass dimensions of the eight masters are removed by the vector
\begin{equation}
 \boldsymbol J
 :=
 \begin{pmatrix}
  s^{-1+2\eps}G_1\\
  s^{2\eps}G_2\\
  s^{1+2\eps}G_3\\
  s^{2+2\eps}G_4\\
  s^{1+2\eps}G_5\\
  s^{2+2\eps}G_6\\
  s^{3+2\eps}G_7\\
  s^{4+2\eps}G_8
 \end{pmatrix}.
 \label{eq:nnlo-dimensionless-master-vector}
\end{equation}
Differentiating with
Eq.~\eqref{eq:nnlo-on-shell-derivatives} and reducing the resulting
integrals by IBP gives
\begin{equation}
 \dd\boldsymbol J
 =
 \left[
  A_x(x,y,\eps)\,\dd x
  +
  A_y(x,y,\eps)\,\dd y
 \right]\boldsymbol J,
 \label{eq:nnlo-raw-differential-system}
\end{equation}
where \(A_x\) and \(A_y\) are exact rational \(8\times8\) matrices.
They satisfy
\begin{equation}
 \partial_xA_y
 -
 \partial_yA_x
 -
 [A_x,A_y]
 =
 0.
 \label{eq:nnlo-flatness}
\end{equation}

The only non-Fuchsian singularity of the raw system is a rank-one double
pole at
\begin{equation}
 \Delta=1-x-y=0
 \label{eq:nnlo-nonfuchsian-locus}
\end{equation}
in the coupled top block.  A near-identity top-block transformation that
removes this double pole is
\begin{equation}
 M_{\rm top}
 =
 \boldsymbol1_2
 +
 \frac{
  2\eps\,y(1-y)(2+3\eps)
 }{
  (1+\eps)\Delta
 }
 E_{21},
 \qquad
 (E_{21})_{ij}
 =
 \delta_{i2}\delta_{j1}.
 \label{eq:nnlo-moser-transformation}
\end{equation}
This transformation diagnoses and removes the top-block obstruction; it is
not the complete canonical transformation.

An exact rational basis change
\begin{equation}
 \boldsymbol J=T(x,y,\eps)\boldsymbol F
 \label{eq:nnlo-canonical-basis-change}
\end{equation}
brings the full system to
\begin{equation}
 \dd\boldsymbol F
 =
 \eps
 \sum_{a=1}^{6}
 R_a\,\dd\log\phi_a\,
 \boldsymbol F,
 \label{eq:nnlo-canonical-system}
\end{equation}
with constant residue matrices \(R_a\) and alphabet
\begin{equation}
 \{\phi_a\}_{a=1}^{6}
 =
 \left\{
  x,\,
  1-x,\,
  y,\,
  1-y,\,
  1-x-y,\,
  (1-x)^2-y
 \right\}.
 \label{eq:nnlo-canonical-alphabet}
\end{equation}
The exact matrices \(A_x,A_y,T\), and \(R_a\) are not reproduced in this
section.  Their retained calculation record satisfies
Eq.~\eqref{eq:nnlo-flatness}, exact dlog reconstruction of
Eq.~\eqref{eq:nnlo-canonical-system}, and \(\eps\)-independence of every
\(R_a\).  Every letter in
Eq.~\eqref{eq:nnlo-canonical-alphabet} is positive in the chamber
Eq.~\eqref{eq:nnlo-worked-chamber}.

\subsection{Nonuniform boundary and Frobenius matching}
\label{subsec:nnlo-boundary-matching}

The physical boundary
\begin{equation}
 y\longrightarrow0^+
 \label{eq:nnlo-y-boundary}
\end{equation}
must be derived at the integral-family level.  On that boundary,
\begin{equation}
 k_c=xk_b,
 \label{eq:nnlo-boundary-kinematics}
\end{equation}
and direct substitution of \(y=0\) into the two-variable transformation
\(T(x,y,\eps)\) fails to reproduce the independently reduced boundary
system.  The boundary family closes on seven masters,
\begin{equation}
 \boldsymbol B(x,\eps)
 =
 \bigl(B_1,\ldots,B_7\bigr)^{\mathsf T},
 \label{eq:nnlo-boundary-master-vector}
\end{equation}
with the first six equations independent of \(B_7\).

Near \(x=0\), write
\begin{equation}
 \frac{\dd\boldsymbol B}{\dd x}
 =
 \left[
  \frac{A_{-1}(\eps)}{x}
  +
  A_0(\eps)
  +
  O(x)
 \right]\boldsymbol B.
 \label{eq:nnlo-boundary-system}
\end{equation}
The physical boundary contains the three local powers
\begin{equation}
 x^0,
 \qquad
 x^{-\eps},
 \qquad
 x^{-2\eps}.
 \label{eq:nnlo-boundary-modes}
\end{equation}
For a mode with exponent \(\lambda\), let
\begin{equation}
 \boldsymbol B_\lambda(x)
 =
 x^\lambda
 \left[
  b_0+xb_1+O(x^2)
 \right].
 \label{eq:nnlo-frobenius-expansion}
\end{equation}
The leading and first subleading coefficients obey
\begin{align}
 \bigl[
  \lambda\boldsymbol1-A_{-1}
 \bigr]b_0
 &=0,
 \label{eq:nnlo-leading-frobenius-equation}\\
 \bigl[
  (\lambda+1)\boldsymbol1-A_{-1}
 \bigr]b_1
 &=A_0b_0.
 \label{eq:nnlo-frobenius-recurrence}
\end{align}

The matching from the boundary basis to the canonical basis has a simple
pole,
\begin{equation}
 C(x,\eps)
 =
 \frac{C_{-1}(\eps)}{x}
 +
 C_0(\eps)
 +
 O(x).
 \label{eq:nnlo-boundary-canonical-map}
\end{equation}
For each physical mode, the spurious pole cancels:
\begin{equation}
 C_{-1}b_0=0.
 \label{eq:nnlo-spurious-pole-condition}
\end{equation}
The finite canonical boundary vector is therefore
\begin{equation}
 f_\lambda
 =
 C_0b_0+C_{-1}b_1.
 \label{eq:nnlo-finite-boundary-match}
\end{equation}
Retaining only \(b_0\) would miss the second term in
Eq.~\eqref{eq:nnlo-finite-boundary-match}.

Let \(R_x\) and \(R_y\) denote the canonical residues at the tangential
base point.  The three matched vectors satisfy
\begin{align}
 R_x f_{\rm hard}&=0,
 &
 (R_x+\boldsymbol1)f_{\rm coll}&=0,
 &
 (R_x+2\boldsymbol1)f_{-2}&=0,
 \notag\\
 R_y f_{\rm hard}
 &=
 R_y f_{\rm coll}
 =
 R_y f_{-2}
 =
 0.
 \label{eq:nnlo-canonical-boundary-residues}
\end{align}
The lower-sector components of these vectors reduce to exact beta- and
gamma-function expressions.

After those lower data have been fixed, one independent hard top-corner
period remains.

\subsection{Exact top-corner period}
\label{subsec:nnlo-corner-period}

A manifestly real representation of the remaining normalized period is
\begin{align}
 r_{\rm top}(\eps)
 ={}&
 -\frac{
  \Gamma(2-2\eps)\Gamma(3-3\eps)
 }{
  \eps\,
  \Gamma(-2\eps)\Gamma(1-\eps)^3
 }
 \int_0^1
 \dd\alpha\,\dd\beta\,\dd\gamma\,
 \alpha^{-1-\eps}
 \beta^{-1-\eps}
 \gamma^{-1-\eps}
 \notag\\
 &\times
 (1-\alpha)^{-1-2\eps}
 (1-\beta)^{-1-2\eps}
 (1-\alpha\beta)^{2\eps}
 (1-\alpha\beta\gamma)^\eps.
 \label{eq:nnlo-corner-period}
\end{align}
For
\begin{equation}
 0<\alpha,\beta,\gamma<1,
 \label{eq:nnlo-corner-domain}
\end{equation}
all powered bases in
Eq.~\eqref{eq:nnlo-corner-period} are positive.  The integral is first
defined in the common convergence domain
\begin{equation}
 \operatorname{Re}\eps<0
 \label{eq:nnlo-corner-convergence}
\end{equation}
and then continued meromorphically in \(\eps\).

Exact endpoint resolution and hyperlogarithmic integration give
\begin{align}
 r_{\rm top}(\eps)
 ={}&
 -\frac{10}{\eps^3}
 +\frac{65}{\eps^2}
 -\frac{135}{\eps}
 +90
 -8\zeta_3
 \notag\\
 &+
 \eps
 \left(
  52\zeta_3-\frac{2\pi^4}{3}
 \right)
 \notag\\
 &+
 \eps^2
 \left(
  \frac{13\pi^4}{3}
  -108\zeta_3
  -288\zeta_5
 \right)
 +O(\eps^3).
 \label{eq:nnlo-corner-period-series}
\end{align}
This is the only new period in the eight-master family after the
beta- and gamma-function boundary data have been supplied.

\subsection{Canonical transport and exact target master}
\label{subsec:nnlo-canonical-transport}

The canonical solution is transported from the tangential base point along
\begin{equation}
 (0,0)
 \longrightarrow
 (x,0)
 \longrightarrow
 (x,y).
 \label{eq:nnlo-transport-path}
\end{equation}
Along the first segment the nonconstant letters reduce to
\(\{x,1-x\}\).  Along the second segment, at fixed \(x\), the integration
letters are
\begin{equation}
 \{0,1,1-x,(1-x)^2\}
 \label{eq:nnlo-y-segment-letters}
\end{equation}
in the \(y\) variable.  The chamber
Eq.~\eqref{eq:nnlo-worked-chamber} places the endpoint below every nonzero
letter.  Singular letters at the base point are treated by tangential
regularization.

The ordered evolution is
\begin{equation}
 \boldsymbol F(x,y)
 =
 U_y(x;y)\,
 U_x(x)\,
 \boldsymbol F_\partial,
 \label{eq:nnlo-ordered-transport}
\end{equation}
where
\begin{equation}
 U_\gamma
 =
 \mathcal P
 \exp
 \left[
  \eps
  \int_\gamma
  \sum_{a=1}^{6}
  R_a\,\dd\log\phi_a
 \right].
 \label{eq:nnlo-ordered-evolution-operator}
\end{equation}
The residue matrices do not commute, so the path ordering and the ordering
of the iterated-integral letters are part of the analytic result.  Since the
full canonical boundary begins at order \(\eps^{-4}\), transport through
\(\eps^2\) requires iterated integrals through weight six.

Define the cut-volume normalization
\begin{equation}
 \mathcal N_0(\eps)
 :=
 s^{-1+2\eps}
 G_1(s,0,0;\eps)
 \label{eq:nnlo-cut-volume-normalization}
\end{equation}
and the dimensionless target
\begin{align}
 \widehat G_7(x,y;\eps)
 :={}&
 \frac{
  s^{3+2\eps}G_7(s,t,u;\eps)
 }{
  \mathcal N_0(\eps)
 }
 \notag\\
 ={}&
 \frac{
  s^4G_7(s,t,u;\eps)
 }{
  G_1(s,0,0;\eps)
 }.
 \label{eq:nnlo-top-normalization}
\end{align}
Its exact Laurent expansion is
\begin{equation}
 \widehat G_7(x,y;\eps)
 =
 \sum_{n=-4}^{2}
 \eps^n g_n(x,y)
 +
 O(\eps^3),
 \qquad
 g_{-4}=0.
 \label{eq:nnlo-top-series}
\end{equation}
The leading coefficients are
\begin{equation}
 g_{-3}(x,y)
 =
 -\frac{5}{\Delta^2},
 \label{eq:nnlo-gminus3}
\end{equation}
and
\begin{align}
 g_{-2}(x,y)
 =\frac{1}{\Delta^2}
 \Bigl[
  &\frac{65}{2}
  -4\mathcal G(0;x)
  +10\mathcal G(1;x)
  -6\mathcal G(1;y)
  \notag\\
  &+
  20\mathcal G(1-x;y)
 \Bigr].
 \label{eq:nnlo-gminus2}
\end{align}
The iterated integrals are defined by
\begin{equation}
 \mathcal G(a_1,\ldots,a_n;z)
 :=
 \int_0^z
 \frac{\dd t}{t-a_1}
 \mathcal G(a_2,\ldots,a_n;t),
 \qquad
 \mathcal G(;z)=1,
 \label{eq:nnlo-gpl-definition}
\end{equation}
with tangential regularization at a zero endpoint.  The exact expressions
for
\begin{equation}
 g_{-1},\quad g_0,\quad g_1,\quad g_2
 \label{eq:nnlo-higher-target-coefficients}
\end{equation}
are lengthy combinations of the same ordered iterated integrals and exact
zeta values.  They are supplied, without numerical approximation, in
\texttt{ancillary/NNLO\_three\_particle\_cut\_master.wl}.  Together with
Eqs.~\eqref{eq:nnlo-gminus3} and \eqref{eq:nnlo-gminus2}, that ancillary
coefficient map is the exact result through \(\eps^2\).

\subsection{Normalization of the AMFlow comparison}
\label{subsec:nnlo-amflow-comparison}

The cut-only master \(G_1\) depends on the external kinematics only through
\begin{equation}
 q^2=s\Delta.
 \label{eq:nnlo-cut-volume-scale}
\end{equation}
Its mass dimension is \(2-4\eps\).  Therefore
\begin{equation}
 G_1(s,t,u;\eps)
 =
 \Delta^{1-2\eps}
 G_1(s,0,0;\eps).
 \label{eq:nnlo-phase-space-volume-ratio}
\end{equation}

The ratio compared with \AMFlow\ is
\begin{equation}
 R(x,y;\eps)
 :=
 \frac{
  s^4G_7(s,t,u;\eps)
 }{
  G_1(s,t,u;\eps)
 }.
 \label{eq:nnlo-fixed-point-ratio}
\end{equation}
Equations~\eqref{eq:nnlo-top-normalization} and
\eqref{eq:nnlo-phase-space-volume-ratio} imply the exact relation
\begin{equation}
 \boxed{
 R(x,y;\eps)
 =
 \Delta^{-1+2\eps}
 \widehat G_7(x,y;\eps)
 }.
 \label{eq:nnlo-ratio-normalization-relation}
\end{equation}

At the comparison point
\begin{equation}
 s=10,
 \qquad
 t=-3,
 \qquad
 u=-2,
 \qquad
 x=\frac{3}{10},
 \qquad
 y=\frac{1}{5},
 \qquad
 \Delta=\frac12,
 \label{eq:nnlo-amflow-point}
\end{equation}
one has
\begin{equation}
 R(\eps)
 =
 2^{1-2\eps}\,
 \widehat G_7(\eps).
 \label{eq:nnlo-ratio-at-check-point}
\end{equation}
In particular,
\begin{equation}
 g_{-3}
 =
 -\frac{5}{\Delta^2}
 =
 -20,
 \qquad
 r_{-3}
 =
 \Delta^{-1}g_{-3}
 =
 -40.
 \label{eq:nnlo-leading-normalization-check}
\end{equation}
The apparent factor-of-two difference is therefore exactly the leading
three-particle phase-space-volume ratio.

Writing
\begin{equation}
 R(\eps)
 =
 \sum_{n=-4}^{2}
 r_n\eps^n
 +
 O(\eps^3),
 \label{eq:nnlo-fixed-point-series}
\end{equation}
the analytic GPL expression and an independently generated \AMFlow\
calculation give the values in Table~\ref{tab:nnlo-amflow}.
\begin{table}[htbp]
 \centering
 \small
 \begin{tabular}{@{}ccl@{}}
  \toprule
  \(n\)
  &
  Analytic evaluation
  &
  \AMFlow
  \\
  \midrule
  \(-4\)
  & \(0\)
  & \(0\)
  \\
  \(-3\)
  & \(-40.00000000000000000000\)
  & \(-39.99999999999999999999\)
  \\
  \(-2\)
  & \(282.32024127181498559344\)
  & \(282.32024127181498560034\)
  \\
  \(-1\)
  & \(-662.90998166471340573018\)
  & \(-662.90998166471340578843\)
  \\
  \(0\)
  & \(418.83703822298626042003\)
  & \(418.83703822298626060946\)
  \\
  \(1\)
  & \(-12.21808964614470122794\)
  & \(-12.21808964614470151249\)
  \\
  \(2\)
  & \(-32.81177029956454278368\)
  & \(-32.81177029956454246165\)
  \\
  \bottomrule
 \end{tabular}
 \caption{Independent numerical comparison of the exact analytic ratio
 \(R=s^4G_7/G_1(s,t,u;\eps)\) at
 Eq.~\eqref{eq:nnlo-amflow-point}.  Every nonzero Laurent coefficient agrees
 within the declared relative tolerance \(10^{-12}\).  The numerical values
 are comparisons only and do not enter the analytic construction.}
 \label{tab:nnlo-amflow}
\end{table}

\subsection{Two further analytic families}
\label{subsec:nnlo-other-families}

Two additional stored double-real families have been solved analytically
through \(\eps^2\) and compared with independent \AMFlow\ evaluations.

The first is a four-master family with a doubled physical cut and a repeated
Jordan block.  One regulated two-region boundary integral determines two
nonuniform scalar boundary coefficients.  Thus the number of scalar
coefficients exceeds the number of direct boundary integrations.

The second is a five-master family whose differential system factorizes into
smaller blocks.  Its normalized hard top-boundary period is the same period
already required by the coupled eight-master family.  It therefore requires
its own differential transport but introduces no additional hard period.

These examples establish that the numbers of masters, differential blocks,
scalar boundary coefficients, direct boundary integrations, and new periods
are distinct.  They do not imply that the full 342-master basis has been
solved analytically.

\subsection{Remaining work toward the double-real hard function}
\label{subsec:nnlo-remaining-work}

The exact denominator classification identifies the integral geometries that
occur in the current basis.  Completion of the NNLO double-real hard function
still requires:

\begin{enumerate}
 \item reconstruction and characteristic-zero verification of the remaining
 rational master coefficients;

 \item construction of the differential closures associated with the
 remaining maximal positive-denominator classes;

 \item determination of their physical local modes and exact boundary data;

 \item identification of normalized boundary periods already shared between
 different differential systems;

 \item analytic evaluation of every remaining independent period and master
 integral;

 \item assembly of the exact masters with the reconstructed coefficients and
 extraction of the NNLO endpoint distributions.
\end{enumerate}

Only after these steps have been completed can the double-real contribution
be combined with the other NNLO components in the hard-function
normalization of Sec.~\ref{sec:factorized-observable}.

## Sources sent to Pro

- [manuscript_07_nnlo_double_real.tex](Sources/13_manuscript_07_nnlo_double_real/manuscript_07_nnlo_double_real.tex)
- [manuscript_07_nnlo_double_real_sources.zip](Sources/13_manuscript_07_nnlo_double_real/manuscript_07_nnlo_double_real_sources.zip)
