# Overleaf Section02

## Question

The attached LaTeX source contains the complete existing NLO cut-master,
differential-equation, endpoint, and boundary-equivalence derivation. The
current main_collinear.tex was attached in the preceding turn.

We are now rewriting the paper section by section. Draft exact replacement
LaTeX for:

Section 2: Factorized observable, kinematics, and hard-function definition

  2.1 Hadronic cross section and perturbative expansion
  2.2 Hadronic and partonic kinematics
  2.3 Leading-twist correlators and UU, LL, TT projections
  2.4 Definition and required analytic content of the hard function

and Appendix A: Conventions, normalizations, and symbol table.

Requirements:

1. Write at ordinary QCD-paper level, as a connected physics definition, not
   as software documentation.
2. Define the measured single-inclusive observable and the partonic hard
   function order by order. Do not invent a normalization that is absent from
   the sources. If the exact convention cannot be inferred, introduce one
   clearly labelled convention parameter or state the unresolved normalization
   explicitly rather than guessing.
3. Define k_a=x_a P_a, k_b=x_b P_b, P_h=z_h k_c, the partonic Mandelstam
   invariants, Q^2=s+t+u, and the variables v,w used in the endpoint analysis.
4. State the physical chamber and the endpoint w -> 1 from below.
5. Give the quark and antiquark leading-twist PDF/FF correlators, the BMHV
   gamma_5 convention, and explicit definitions of UU, LL, and TT projections.
   Do not mix hadronic transverse spin vectors with partonic ones.
6. Define exactly what is divided out of the hard coefficient: distribution
   functions, fragmentation functions, convolution measure, declared
   momentum-fraction monomial, and any common coupling/phase-space factor.
7. State the exact fraction-independence criterion: after those universal
   factors are removed, the hard coefficient is independent of x_a, x_b,
   z_h and auxiliary hadronic basis vectors.
8. Define the distributional decomposition in delta(1-w), D_m(w), and a
   regular remainder. Preserve the exact endpoint factors before expanding in
   epsilon.
9. Use one notation consistently: D=4-2 epsilon, z_h for fragmentation, and
   call the inclusive invariant Q^2=s+t+u unless the attached NLO derivation
   requires another symbol. Explain any conflict rather than silently changing
   it.
10. Do not claim a complete NLO fixed-order result in this section.
11. Keep equation labels systematic and avoid labels tied to old section
    numbers. Cite only references already present in references.bib.

Return only:

(A) a short list of notation decisions or source ambiguities that must be
resolved by the authors; and
(B) compilable LaTeX for Section 2 and Appendix A.

Do not rewrite any later section in this turn.

## Pro response

(A) Notation decisions and source ambiguities requiring author confirmation

Perturbative coupling normalization. The current source defines the factorization formula only schematically and does not fix whether perturbative coefficients multiply α
s
	​

, α
s
	​

/(2π), α
s
	​

/(4π), or another convention. The replacement therefore uses a formal expansion parameter a
s
	​

 and keeps every remaining common normalization in N
com
(n)
	​

. The authors should fix a
s
	​

 once, globally, before submission. 

main_collinear(3)

Overall partonic normalization. Flux factors, initial-state spin/color averages, powers of 4π, renormalization-scale factors, and the precise separation between the partonic phase-space factor and the hard coefficient are not defined consistently in the supplied manuscript. The replacement distinguishes the physical hard function H
(n)
 from a temporarily reduced coefficient 
H
(n)
 through

H
(n)
=N
com
(n)
	​

H
(n)
.

The endpoint-dependent part of N
com
(n)
	​

, such as (Q
2
)
−ϵ
, must be restored before the distributional expansion.

Meaning of the polarization labels. The cards and correlator structure indicate that the second incoming hadron is unpolarized and that the two letters in UU, LL, and TT refer to the polarization of hadron A and the observed hadron h. The authors should confirm this convention explicitly. The replacement adopts it. The correlator signs follow the existing quark/antiquark convention in which only the helicity term changes sign. 

main_collinear(3)

Longitudinal distribution product and fraction monomial. The demonstrated UU and TT reductions have the exact momentum-fraction valuation

x
a
−1
	​

x
b
−1
	​

z
h
−2
	​

.

The supplied sources do not provide an equally explicit stored LL normalization. The replacement therefore denotes the LL monomial by m
LL
	​

 until the authors confirm it, while recording the verified UU and TT monomial.

Measured-observable convention. The old source writes only dσ. The replacement uses the invariant one-particle observable

E
h
	​

d
3
σ/d
3
P
h
	​

.

A change to dP
hT
	​

dη
h
	​

, dP
hT
2
	​

dy
h
	​

, or another experimental representation changes only the explicitly displayed Jacobian J
h
	​

, but the authors should choose one convention for the final manuscript.

Inclusive invariant. The replacement uses

Q
2
=(k
a
	​

+k
b
	​

−k
c
	​

)
2
=s+t+u

everywhere. The old symbol W=s+t+u should be removed. The physical chamber and the variables v,w are taken directly from the complete NLO derivation. 

Boundary_Integrals_and_Equivale… +1

Factorization and renormalization schemes. The sources do not yet specify the final 
MS
 conventions, the equality or independence of μ
R
	​

 and μ
F
	​

, or the precise treatment of finite scheme terms. The replacement retains μ
R
	​

 and μ
F
	​

 as arguments without asserting a complete fixed-order result.

(B) Replacement LaTeX
LaTeX
\section{Factorized observable, kinematics, and hard-function definition}
\label{sec:factorized-observable}

\subsection{Hadronic cross section and perturbative expansion}
\label{subsec:hadronic-factorization}

We consider single-inclusive hadron production,
\begin{equation}
  A(P_A,S_A)+B(P_B,S_B)
  \longrightarrow
  h(P_h,S_h)+X,
  \label{eq:hadronic-process}
\end{equation}
at leading power in the hard scale.  Hadron masses are neglected throughout
the partonic calculation.  As a representative invariant observable, we use
\begin{equation}
  \mathcal I_h^{\mathsf P}(P_h)
  :=
  E_h\frac{\dd^3\sigma^{\mathsf P}}{\dd^3\bm P_h},
  \qquad
  \mathsf P\in\{\mathsf{UU},\mathsf{LL},\mathsf{TT}\}.
  \label{eq:invariant-hadron-observable}
\end{equation}
For the polarization channels considered below, hadron \(B\) is
unpolarized.  The two letters in \(\mathsf P\) refer respectively to the
polarization of hadron \(A\) and of the observed hadron \(h\).

At leading twist, collinear factorization takes the form
\begin{equation}
  \mathcal I_h^{\mathsf P}(P_h)
  =
  \sum_{a,b,c}
  \int \dd\Xi_h\,
  \mathscr F_{ab\to c}^{\mathsf P}(x_a,x_b,z_h;\mu_F)\,
  \mathfrak m_{\mathsf P}(x_a,x_b,z_h)\,
  \mathcal H_{ab\to c}^{\mathsf P}
  (s,t,u;\mu_R,\mu_F,\eps),
  \label{eq:single-inclusive-factorization}
\end{equation}
where
\begin{equation}
  \dd\Xi_h
  :=
  \dd x_a\,\dd x_b\,\dd z_h\,
  \mathcal J_h(x_a,x_b,z_h;P_h)
  \label{eq:convolution-measure}
\end{equation}
contains the chosen one-particle phase-space Jacobian but does not contain
the distribution product \(\mathscr F^{\mathsf P}\) or the separately
declared Laurent monomial \(\mathfrak m_{\mathsf P}\).  The latter convention
makes the separation between convolution kinematics and the partonic hard
coefficient explicit.  Equation~\eqref{eq:single-inclusive-factorization}
is the leading-power collinear factorization formula used throughout this
work~\cite{Collins:1989gx}.

The precise normalization of the perturbative coupling has not yet been
fixed globally in the manuscript.  We therefore introduce a formal
renormalized expansion parameter \(a_s(\mu_R)\) and write
\begin{equation}
  \mathcal H_{ab\to c}^{\mathsf P}
  =
  a_s^{\,n_0}
  \sum_{n=0}^{\infty}
  a_s^{\,n}\,
  H_{ab\to c}^{\mathsf P,(n)}
  (s,t,u;\mu_R,\mu_F,\eps).
  \label{eq:hard-perturbative-expansion}
\end{equation}
For a purely QCD \(2\to2\) Born subprocess, \(n_0=2\).  The replacement
\[
  a_s=\alpha_s,\qquad
  a_s=\frac{\alpha_s}{2\pi},
  \qquad\text{or}\qquad
  a_s=\frac{\alpha_s}{4\pi}
\]
is a convention choice and must be made once for the complete manuscript.
All equations below are independent of that choice provided the same
definition is used in every real, virtual, renormalization, and collinear
counterterm contribution.

The coefficient \(H_{ab\to c}^{\mathsf P,(n)}\) is the physical hard
function at relative order \(n\) in the chosen convention.  It is not a
fixed-kinematics number: it is required as an exact analytic function of the
partonic invariants and of
\begin{equation}
  D=4-2\eps.
  \label{eq:dimension-definition}
\end{equation}
No claim about a complete NLO or NNLO fixed-order result is made in this
section; the purpose here is to define the object that the later calculation
must produce.

\subsection{Hadronic and partonic kinematics}
\label{subsec:kinematics}

Define the hadronic Mandelstam invariants
\begin{equation}
  S=(P_A+P_B)^2,
  \qquad
  T=(P_A-P_h)^2,
  \qquad
  U=(P_B-P_h)^2.
  \label{eq:hadronic-mandelstam}
\end{equation}
At leading power,
\begin{equation}
  P_A^2=P_B^2=P_h^2=0,
  \qquad
  S>0,
  \qquad
  T<0,
  \qquad
  U<0.
  \label{eq:hadronic-physical-region}
\end{equation}

The incoming and fragmenting parton momenta are related to the hadronic
momenta by
\begin{equation}
  k_a=x_aP_A,
  \qquad
  k_b=x_bP_B,
  \qquad
  P_h=z_h k_c,
  \qquad
  0<x_a,x_b,z_h<1.
  \label{eq:collinear-momentum-map}
\end{equation}
The partonic Mandelstam invariants are
\begin{equation}
  s=(k_a+k_b)^2,
  \qquad
  t=(k_a-k_c)^2,
  \qquad
  u=(k_b-k_c)^2.
  \label{eq:partonic-mandelstam}
\end{equation}
In the massless approximation, Eqs.~\eqref{eq:hadronic-mandelstam} and
\eqref{eq:collinear-momentum-map} imply
\begin{equation}
  s=x_ax_bS,
  \qquad
  t=\frac{x_a}{z_h}T,
  \qquad
  u=\frac{x_b}{z_h}U.
  \label{eq:hadronic-partonic-invariants}
\end{equation}

The total momentum carried by the unobserved partonic final state is
\begin{equation}
  q^\mu:=k_a^\mu+k_b^\mu-k_c^\mu,
  \qquad
  Q^2:=q^2=s+t+u.
  \label{eq:inclusive-invariant}
\end{equation}
For real emission in the interior of the physical region,
\begin{equation}
  s>0,
  \qquad
  t<0,
  \qquad
  u<0,
  \qquad
  Q^2>0,
  \qquad
  s+t>0,
  \qquad
  s+u>0,
  \qquad
  t+u<0.
  \label{eq:partonic-physical-chamber}
\end{equation}
Every noninteger power of a positive invariant is defined with the real
logarithm; in particular,
\begin{equation}
  (Q^2)^\alpha
  :=
  \exp\!\bigl[\alpha\log Q^2\bigr],
  \qquad
  Q^2>0,
  \qquad
  \log Q^2\in\mathbb R.
  \label{eq:positive-invariant-power}
\end{equation}

For the endpoint analysis, it is convenient to introduce
\begin{equation}
  v:=1+\frac{t}{s},
  \qquad
  w:=-\frac{u}{s+t},
  \qquad
  x:=1-w.
  \label{eq:vw-variables}
\end{equation}
The inverse relations are
\begin{equation}
  t=-s(1-v),
  \qquad
  u=-svw=-sv(1-x),
  \qquad
  Q^2=sv(1-w)=svx.
  \label{eq:vw-inverse-map}
\end{equation}
The chamber in Eq.~\eqref{eq:partonic-physical-chamber} is equivalently
described by
\begin{equation}
  s>0,
  \qquad
  0<v<1,
  \qquad
  0<w<1.
  \label{eq:vw-physical-chamber}
\end{equation}
The real-emission endpoint is approached from inside that chamber:
\begin{equation}
  w\longrightarrow1^-,
  \qquad
  x=1-w\longrightarrow0^+,
  \qquad
  v\ \text{fixed}.
  \label{eq:partonic-endpoint}
\end{equation}
At the endpoint \(Q^2\to0^+\), while \(s\) and \(v\) remain finite and
positive.

\subsection{Leading-twist correlators and the \(\mathsf{UU}\),
\(\mathsf{LL}\), and \(\mathsf{TT}\) projections}
\label{subsec:twist-two-projectors}

For each collinear direction \(r\in\{A,B,h\}\), introduce lightlike vectors
\(n_r^\mu\) and \(\bar n_r^\mu\) satisfying
\begin{equation}
  n_r^2=\bar n_r^2=0,
  \qquad
  n_r\cdot\bar n_r=1.
  \label{eq:lightcone-normalization}
\end{equation}
At leading power, the corresponding hadron momentum is proportional to one
of these null directions.  The physical transverse-spin vectors are
hadronic vectors,
\begin{equation}
  S_{AT}\cdot n_A
  =
  S_{AT}\cdot\bar n_A
  =
  0,
  \qquad
  S_{hT}\cdot n_h
  =
  S_{hT}\cdot\bar n_h
  =
  0.
  \label{eq:hadronic-transverse-spin}
\end{equation}
They are not identified with independent partonic spin four-vectors.  The
partonic polarization information is carried by the leading-twist density
matrices.

We use the BMHV decomposition~\cite{Breitenlohner:1977hr}
\begin{equation}
  g_D^{\mu\nu}
  =
  \bar g^{\mu\nu}
  +
  \widehat g^{\mu\nu},
  \qquad
  \bar g^\mu{}_\mu=4,
  \qquad
  \widehat g^\mu{}_\mu=D-4=-2\eps,
  \label{eq:bmhv-metric-split}
\end{equation}
and
\begin{equation}
  \gamma^\mu
  =
  \bar\gamma^\mu
  +
  \widehat\gamma^\mu.
  \label{eq:bmhv-gamma-split}
\end{equation}
The four-dimensional chirality matrix is defined by
\begin{equation}
  \gamma_5
  :=
  \frac{i}{4!}
  \varepsilon_{\mu\nu\rho\sigma}
  \bar\gamma^\mu
  \bar\gamma^\nu
  \bar\gamma^\rho
  \bar\gamma^\sigma,
  \qquad
  \varepsilon^{0123}=+1,
  \label{eq:bmhv-gamma5}
\end{equation}
so that
\begin{equation}
  \{\gamma_5,\bar\gamma^\mu\}=0,
  \qquad
  [\gamma_5,\widehat\gamma^\mu]=0.
  \label{eq:bmhv-gamma5-algebra}
\end{equation}
All external hadron momenta, light-cone vectors, polarization vectors, and
measured transverse-spin vectors are four dimensional:
\begin{equation}
  \widehat P_A
  =
  \widehat P_B
  =
  \widehat P_h
  =
  \widehat n_r
  =
  \widehat{\bar n}_r
  =
  \widehat S_{AT}
  =
  \widehat S_{hT}
  =
  0.
  \label{eq:external-vectors-four-dimensional}
\end{equation}
Loop and phase-space integration momenta remain \(D\)-dimensional until the
appropriate BMHV tensor and dimension recurrences have been applied.

Let
\begin{equation}
  \eta_\chi
  :=
  \begin{cases}
    +1,&\chi=q,\\
    -1,&\chi=\bar q.
  \end{cases}
  \label{eq:quark-antiquark-helicity-sign}
\end{equation}
For a quark or antiquark \(\chi\) in hadron \(H\), the leading-twist
collinear distribution correlator is
\begin{align}
  \Phi_{\chi/H}(x;\lambda_H,S_{HT})
  =\frac12\Bigl[
   &f_1^{\chi/H}(x)\,\not\!n_H
   +\eta_\chi\lambda_H
      g_{1L}^{\chi/H}(x)\,
      \gamma_5\not\!n_H
   \notag\\
   &+
   h_1^{\chi/H}(x)\,
   i\sigma^{n_HS_{HT}}\gamma_5
  \Bigr].
  \label{eq:leading-twist-pdf-correlator}
\end{align}
For fragmentation of \(\chi\) into the observed hadron \(h\),
\begin{align}
  \Delta_{h/\chi}(z_h;\lambda_h,S_{hT})
  =\frac12\Bigl[
   &D_1^{h/\chi}(z_h)\,\not\!n_h
   +\eta_\chi\lambda_h
      G_{1L}^{h/\chi}(z_h)\,
      \gamma_5\not\!n_h
   \notag\\
   &+
   H_1^{h/\chi}(z_h)\,
   i\sigma^{n_hS_{hT}}\gamma_5
  \Bigr].
  \label{eq:leading-twist-ff-correlator}
\end{align}
Our Dirac convention is
\begin{equation}
  i\sigma^{ab}
  :=
  -\frac12[\not\!a,\not\!b].
  \label{eq:sigma-slash-convention}
\end{equation}
Thus the antiquark convention reverses the helicity term while preserving
the unpolarized and transversity structures.  These are the standard
leading-twist collinear correlators~\cite{Bacchetta:2006tn}.

For later use, separate the three components of each correlator:
\begin{equation}
  \Phi_{\chi/H}
  =
  \Phi_{\chi/H}^{U}
  +\lambda_H\Phi_{\chi/H}^{L}
  +\Phi_{\chi/H}^{T},
  \qquad
  \Delta_{h/\chi}
  =
  \Delta_{h/\chi}^{U}
  +\lambda_h\Delta_{h/\chi}^{L}
  +\Delta_{h/\chi}^{T},
  \label{eq:correlator-component-decomposition}
\end{equation}
with
\begin{align}
  \Phi_{\chi/H}^{U}
  &=
  \frac12 f_1^{\chi/H}(x)\not\!n_H,
  &
  \Phi_{\chi/H}^{L}
  &=
  \frac12\eta_\chi
  g_{1L}^{\chi/H}(x)\gamma_5\not\!n_H,
  \notag\\
  \Phi_{\chi/H}^{T}
  &=
  \frac12 h_1^{\chi/H}(x)
  i\sigma^{n_HS_{HT}}\gamma_5,
  \label{eq:pdf-correlator-components}
\end{align}
and
\begin{align}
  \Delta_{h/\chi}^{U}
  &=
  \frac12D_1^{h/\chi}(z_h)\not\!n_h,
  &
  \Delta_{h/\chi}^{L}
  &=
  \frac12\eta_\chi
  G_{1L}^{h/\chi}(z_h)\gamma_5\not\!n_h,
  \notag\\
  \Delta_{h/\chi}^{T}
  &=
  \frac12H_1^{h/\chi}(z_h)
  i\sigma^{n_hS_{hT}}\gamma_5.
  \label{eq:ff-correlator-components}
\end{align}

Let
\(\mathscr W_{ab\to c}[\Gamma_a,\Gamma_b,\Gamma_c]\)
denote the Dirac- and color-contracted amplitude--conjugate-amplitude
interference with density matrices \(\Gamma_a,\Gamma_b,\Gamma_c\):
\begin{align}
  \mathscr W_{ab\to c}[\Gamma_a,\Gamma_b,\Gamma_c]
  :={}&
  \mathcal N_{\rm av}
  \sum_X\int\dd\Phi_X\,
  (\Gamma_a)_{\alpha'\alpha}
  (\Gamma_b)_{\beta'\beta}
  (\Gamma_c)_{\gamma\gamma'}
  \notag\\
  &\times
  \mathcal M_{\alpha\beta\to\gamma X}
  \left(
  \mathcal M_{\alpha'\beta'\to\gamma'X}
  \right)^* .
  \label{eq:projected-interference-functional}
\end{align}
The indices in Eq.~\eqref{eq:projected-interference-functional} denote the
Dirac and color indices appropriate to each external parton, and
\(\mathcal N_{\rm av}\) denotes the convention-dependent initial-state
average and flux normalization.  Its final placement is included in the
common normalization defined below.

The three projections used in this work are
\begin{align}
  \mathscr W_{\mathsf{UU}}
  &:=
  \mathscr W[
    \Phi_{a/A}^{U},
    \Phi_{b/B}^{U},
    \Delta_{h/c}^{U}
  ],
  \label{eq:UU-projection}\\
  \mathscr W_{\mathsf{LL}}
  &:=
  \mathscr W[
    \Phi_{a/A}^{L},
    \Phi_{b/B}^{U},
    \Delta_{h/c}^{L}
  ],
  \label{eq:LL-projection}\\
  \mathscr W_{\mathsf{TT}}
  &:=
  \mathscr W[
    \Phi_{a/A}^{T},
    \Phi_{b/B}^{U},
    \Delta_{h/c}^{T}
  ].
  \label{eq:TT-projection}
\end{align}
The full longitudinal contribution is proportional to
\(\lambda_A\lambda_h\mathscr W_{\mathsf{LL}}\).  The transverse contribution
is bilinear in the physical hadronic spin vectors:
\begin{equation}
  \mathscr W_{\mathsf{TT}}
  =
  h_1^{a/A}(x_a)
  f_1^{b/B}(x_b)
  H_1^{h/c}(z_h)\,
  S_{AT}^{\mu}S_{hT}^{\nu}\,
  \mathscr K_{\mu\nu}^{\mathsf{TT}}.
  \label{eq:TT-tensor-decomposition}
\end{equation}
The tensor \(\mathscr K_{\mu\nu}^{\mathsf{TT}}\) may subsequently be
decomposed into a chosen physical azimuthal basis.  The scalar coefficient of
each independent azimuthal tensor is treated as a separate hard coefficient.
Auxiliary light-cone vectors are not physical angular structures and must
cancel from those scalar coefficients.

The distribution and fragmentation products appearing in
Eq.~\eqref{eq:single-inclusive-factorization} are therefore
\begin{align}
  \mathscr F_{ab\to c}^{\mathsf{UU}}
  &=
  f_1^{a/A}(x_a)
  f_1^{b/B}(x_b)
  D_1^{h/c}(z_h),
  \label{eq:UU-distribution-product}\\
  \mathscr F_{ab\to c}^{\mathsf{LL}}
  &=
  g_{1L}^{a/A}(x_a)
  f_1^{b/B}(x_b)
  G_{1L}^{h/c}(z_h),
  \label{eq:LL-distribution-product}\\
  \mathscr F_{ab\to c}^{\mathsf{TT}}
  &=
  h_1^{a/A}(x_a)
  f_1^{b/B}(x_b)
  H_1^{h/c}(z_h).
  \label{eq:TT-distribution-product}
\end{align}

\subsection{Definition and required analytic content of the hard function}
\label{subsec:hard-function-definition}

The hard function is defined only after all universal collinear factors have
been identified.  At relative perturbative order \(n\), write the projected
partonic coefficient as
\begin{equation}
  \widehat{\mathcal C}_{ab\to c}^{\mathsf P,(n)}
  =
  \mathfrak m_{\mathsf P}(x_a,x_b,z_h)\,
  H_{ab\to c}^{\mathsf P,(n)}
  (s,t,u;\mu_R,\mu_F,\eps).
  \label{eq:hard-function-factorization}
\end{equation}
Here the distribution product
\(\mathscr F_{ab\to c}^{\mathsf P}\) and the convolution measure
\(\dd\Xi_h\) have already been placed outside
\(\widehat{\mathcal C}^{\mathsf P,(n)}\) in
Eq.~\eqref{eq:single-inclusive-factorization}.  The declared
momentum-fraction factor is a Laurent monomial,
\begin{equation}
  \mathfrak m_{\mathsf P}(x_a,x_b,z_h)
  :=
  x_a^{\lambda_{a,\mathsf P}}
  x_b^{\lambda_{b,\mathsf P}}
  z_h^{\lambda_{h,\mathsf P}},
  \qquad
  \lambda_{r,\mathsf P}\in\frac12\mathbb Z.
  \label{eq:declared-fraction-monomial}
\end{equation}
For the exact UU and TT reductions demonstrated in this work,
\begin{equation}
  \bigl(
   \lambda_{a,\mathsf{UU}},
   \lambda_{b,\mathsf{UU}},
   \lambda_{h,\mathsf{UU}}
  \bigr)
  =
  \bigl(
   \lambda_{a,\mathsf{TT}},
   \lambda_{b,\mathsf{TT}},
   \lambda_{h,\mathsf{TT}}
  \bigr)
  =
  (-1,-1,-2).
  \label{eq:verified-fraction-valuation}
\end{equation}
The LL valuation must be fixed by the same exact calculation and convention
before the final LL hard function is quoted.

For analytic manipulations it is often useful to remove a further common
factor,
\begin{equation}
  H_{ab\to c}^{\mathsf P,(n)}
  =
  \mathcal N_{\rm com}^{\mathsf P,(n)}
  (s,t,u;\mu_R,\mu_F,\eps)\,
  \widetilde H_{ab\to c}^{\mathsf P,(n)}
  (s,t,u;\mu_R,\mu_F,\eps).
  \label{eq:reduced-hard-coefficient}
\end{equation}
The factor \(\mathcal N_{\rm com}^{\mathsf P,(n)}\) records every common
scalar normalization that has been removed temporarily, including any
common phase-space normalization, powers of \(2\), powers of \(\pi\), factors
of \(i\), and convention-dependent coupling normalization not already
included in \(a_s\).  It must be stated explicitly for each calculation.
The physical hard function is
\(H^{\mathsf P,(n)}\), not
\(\widetilde H^{\mathsf P,(n)}\).  In particular, any factor such as
\((Q^2)^{-\eps}\) must be restored before the endpoint expansion.

After the substitutions in
Eqs.~\eqref{eq:collinear-momentum-map} and
\eqref{eq:hadronic-partonic-invariants}, exact collinear factorization
requires
\begin{equation}
  \left.
  \frac{\partial\widetilde H_{ab\to c}^{\mathsf P,(n)}}{\partial x_a}
  \right|_{s,t,u}
  =
  \left.
  \frac{\partial\widetilde H_{ab\to c}^{\mathsf P,(n)}}{\partial x_b}
  \right|_{s,t,u}
  =
  \left.
  \frac{\partial\widetilde H_{ab\to c}^{\mathsf P,(n)}}{\partial z_h}
  \right|_{s,t,u}
  =0.
  \label{eq:fraction-independence}
\end{equation}
The same statement holds for the restored hard function because
\(\mathcal N_{\rm com}^{\mathsf P,(n)}\) is independent of
\(x_a,x_b,z_h\) at fixed \(s,t,u\).

Let
\begin{equation}
  \mathcal V_{\rm aux}
  :=
  \{
   P_A,P_B,P_h,
   n_A,\bar n_A,
   n_B,\bar n_B,
   n_h,\bar n_h
  \}.
  \label{eq:auxiliary-hadronic-vectors}
\end{equation}
For UU and LL, the exact hard coefficient must satisfy
\begin{equation}
  H_{ab\to c}^{\mathsf P,(n)}
  (s,t,u;\mathcal V_{\rm aux})
  =
  H_{ab\to c}^{\mathsf P,(n)}(s,t,u),
  \qquad
  \mathsf P\in\{\mathsf{UU},\mathsf{LL}\}.
  \label{eq:auxiliary-vector-independence}
\end{equation}
For TT, the same condition applies to every scalar coefficient in the
physical azimuthal decomposition of
\(S_{AT}^{\mu}S_{hT}^{\nu}H_{\mu\nu}^{\mathsf{TT},(n)}\).
Dependence on the physical spin directions is retained only through those
explicit azimuthal tensors; dependence on
\(\mathcal V_{\rm aux}\) is forbidden.

Before expanding in \(\eps\), the exact real-emission endpoint behavior must
be retained in its noninteger-power form.  We write
\begin{equation}
  H_{ab\to c}^{\mathsf P,(n)}(v,w,\eps)
  =
  V_{ab\to c}^{\mathsf P,(n)}(v,\eps)\,
  \delta(1-w)
  +
  H_{{\rm reg},ab\to c}^{\mathsf P,(n)}(v,w,\eps)
  +
  \sum_{r=1}^{N_{\rm end}}
  C_{r,ab\to c}^{\mathsf P,(n)}(v,\eps)\,
  (1-w)^{-1-a_r\eps},
  \label{eq:unexpanded-endpoint-decomposition}
\end{equation}
where \(a_r>0\), and every power is defined for \(0<w<1\) by
\begin{equation}
  (1-w)^{-1-a_r\eps}
  :=
  \exp\!\left[-(1+a_r\eps)\log(1-w)\right],
  \qquad
  \log(1-w)\in\mathbb R.
  \label{eq:endpoint-real-branch}
\end{equation}
The set of endpoint branches and the Laurent depth of each
\(C_r(v,\eps)\) must be determined from the exact reconstructed expression,
not from a numerical fit.

For \(m\in\mathbb Z_{\geq0}\), define
\begin{equation}
  \mathcal D_m(w)
  :=
  \left[
    \frac{\log^m(1-w)}{1-w}
  \right]_+,
  \label{eq:plus-distribution-definition-section2}
\end{equation}
with
\begin{equation}
  \int_0^1\dd w\,
  \mathcal D_m(w)\varphi(w)
  =
  \int_0^1\dd w\,
  \frac{\log^m(1-w)}{1-w}
  \bigl[\varphi(w)-\varphi(1)\bigr]
  \label{eq:plus-distribution-test-function}
\end{equation}
for every smooth test function \(\varphi\).  Meromorphic continuation in
\(\eps\) gives
\begin{equation}
  (1-w)^{-1-a\eps}
  =
  -\frac{\delta(1-w)}{a\eps}
  +
  \sum_{m=0}^{\infty}
  \frac{(-a\eps)^m}{m!}\,
  \mathcal D_m(w),
  \qquad a>0.
  \label{eq:general-endpoint-distribution-identity}
\end{equation}
Only after inserting the complete Laurent series of the coefficients
\(C_r(v,\eps)\) is Eq.~\eqref{eq:general-endpoint-distribution-identity}
expanded to the order required by the hard function.

The final analytic form at a specified perturbative and Laurent order is
therefore
\begin{align}
  H_{ab\to c}^{\mathsf P,(n)}(v,w,\eps)
  ={}&
  H_{\delta,ab\to c}^{\mathsf P,(n)}(v,\eps)\,
  \delta(1-w)
  \notag\\
  &+
  \sum_{m=0}^{m_{\rm max}}
  H_{m,ab\to c}^{\mathsf P,(n)}(v,\eps)\,
  \mathcal D_m(w)
  +
  H_{{\rm reg},ab\to c}^{\mathsf P,(n)}(v,w,\eps).
  \label{eq:hard-distributional-decomposition}
\end{align}
The coefficients
\(H_\delta\), \(H_m\), and \(H_{\rm reg}\) remain exact analytic functions
of \(v\), \(\eps\), the color factors, and the renormalization and
factorization scales.  Fixed-kinematics numerical values may verify these
functions but do not define them.

% ---------------------------------------------------------------------------
% Appendix A
% Insert the following after \appendix.
% ---------------------------------------------------------------------------

\section{Conventions, normalizations, and symbol table}
\label{app:conventions}

\subsection{Spacetime and Dirac conventions}
\label{app:spacetime-conventions}

The metric convention is
\begin{equation}
  g^{\mu\nu}
  =
  \operatorname{diag}(1,-1,-1,-1),
  \qquad
  a\cdot b=g_{\mu\nu}a^\mu b^\nu.
  \label{eq:metric-convention}
\end{equation}
Dimensional regularization is defined by
\begin{equation}
  D=4-2\eps.
  \label{eq:appendix-dimension}
\end{equation}
For any vector \(a^\mu\),
\begin{equation}
  \not\!a:=\gamma_\mu a^\mu,
  \qquad
  i\sigma^{ab}:=-\frac12[\not\!a,\not\!b].
  \label{eq:slash-and-sigma}
\end{equation}
The BMHV metric and chirality conventions are those of
Eqs.~\eqref{eq:bmhv-metric-split}--\eqref{eq:bmhv-gamma5-algebra}.
The Levi-Civita tensor satisfies
\begin{equation}
  \varepsilon^{0123}=+1.
  \label{eq:levi-civita-convention}
\end{equation}

The light-cone normalization is
\begin{equation}
  n_r^2=\bar n_r^2=0,
  \qquad
  n_r\cdot\bar n_r=1,
  \qquad
  r\in\{A,B,h\}.
  \label{eq:appendix-lightcone-convention}
\end{equation}
For a pair \(n,\bar n\), the transverse metric is
\begin{equation}
  g_\perp^{\mu\nu}
  :=
  g^{\mu\nu}
  -n^\mu\bar n^\nu
  -\bar n^\mu n^\nu.
  \label{eq:transverse-metric}
\end{equation}

\subsection{Perturbative and factorization normalizations}
\label{app:hard-normalization}

The perturbative expansion is
\begin{equation}
  \mathcal H^{\mathsf P}
  =
  a_s^{\,n_0}
  \sum_{n=0}^{\infty}a_s^{\,n}H^{\mathsf P,(n)}.
  \label{eq:appendix-perturbative-expansion}
\end{equation}
The symbol \(a_s\) is a formal renormalized coupling until the manuscript
chooses one of the conventions
\begin{equation}
  a_s=\alpha_s,
  \qquad
  a_s=\frac{\alpha_s}{2\pi},
  \qquad\text{or}\qquad
  a_s=\frac{\alpha_s}{4\pi}.
  \label{eq:coupling-normalization-options}
\end{equation}
For pure-QCD \(2\to2\) Born subprocesses, \(n_0=2\).

The factors entering the hadronic integrand are separated as
\begin{equation}
  \underbrace{\dd\Xi_h}_{\text{convolution measure}}
  \,
  \underbrace{\mathscr F^{\mathsf P}}_{\text{PDF/FF product}}
  \,
  \underbrace{\mathfrak m_{\mathsf P}}_{\text{fraction monomial}}
  \,
  \underbrace{\mathcal N_{\rm com}^{\mathsf P,(n)}
  \widetilde H^{\mathsf P,(n)}}_{H^{\mathsf P,(n)}}.
  \label{eq:normalization-factor-ledger}
\end{equation}
The first three factors are outside the hard function.  The common factor
\(\mathcal N_{\rm com}^{\mathsf P,(n)}\) may be removed temporarily during
exact algebraic reduction, but it is part of the physical hard function and
must be restored before endpoint powers are expanded.

The demonstrated UU and TT fraction monomial is
\begin{equation}
  \mathfrak m_{\mathsf{UU}}
  =
  \mathfrak m_{\mathsf{TT}}
  =
  \frac{1}{x_ax_bz_h^2}.
  \label{eq:appendix-verified-fraction-monomial}
\end{equation}
The LL monomial is denoted by \(\mathfrak m_{\mathsf{LL}}\) until its
normalization is fixed in the same convention.

\subsection{Physical and IBP integration normalizations}
\label{app:integration-normalizations}

The physical positive-energy delta function is
\begin{equation}
  \delta_+(p^2):=\theta(p^0)\delta(p^2).
  \label{eq:positive-energy-delta}
\end{equation}
For a two-particle massless final state of total momentum \(q\),
\begin{equation}
  \dd\Phi_2(q;k,q-k)
  :=
  (2\pi)^{2-D}
  \dd^Dk\,
  \delta_+(k^2)
  \delta_+\!\bigl((q-k)^2\bigr).
  \label{eq:appendix-two-body-measure}
\end{equation}
Its integrated value is
\begin{equation}
  \Phi_2(Q^2,\eps)
  =
  \frac{(4\pi)^\eps}{8\pi}
  \frac{\Gamma(1-\eps)}{\Gamma(2-2\eps)}
  (Q^2)^{-\eps}.
  \label{eq:appendix-integrated-two-body-phase-space}
\end{equation}
The reduced normalization used for the NLO angular masters is
\begin{equation}
  \mathcal P_2(Q^2,\eps)
  :=
  \frac{(4\pi)^\eps\Gamma(1-\eps)}
       {16\pi^2\Gamma(1-2\eps)}
  (Q^2)^{-\eps},
  \qquad
  \Phi_2
  =
  \frac{2\pi}{1-2\eps}\mathcal P_2.
  \label{eq:appendix-reduced-two-body-factor}
\end{equation}
Neither \(\Phi_2\) nor \(\mathcal P_2\) includes an additional hidden
\(\mu^{2\eps}\) factor.  Any renormalization-scale factor is displayed
separately.

The integration measure used in IBP systems is
\begin{equation}
  [\dd^D\ell]_{\rm IBP}
  :=
  \frac{\dd^D\ell}{i\pi^{D/2}},
  \label{eq:ibp-loop-measure}
\end{equation}
whereas the physical loop or phase-space convention uses
\begin{equation}
  [\dd^D\ell]_{\rm phys}
  :=
  \frac{\dd^D\ell}{(2\pi)^D}.
  \label{eq:physical-loop-measure}
\end{equation}

For a cut momentum \(q_c\), denominator \(D_c=q_c^2\), and energy
orientation \(\xi_c=\pm1\), define
\begin{align}
  \mathcal C_{\xi_c}^{(n)}(D_c)
  :={}&
  \frac{\theta(\xi_cq_c^0)}{2\pi i}
  \left[
   \frac{1}{(D_c-i0)^n}
   -
   \frac{1}{(D_c+i0)^n}
  \right]
  \notag\\
  ={}&
  \theta(\xi_cq_c^0)
  \frac{(-1)^{n-1}}{(n-1)!}
  \delta^{(n-1)}(D_c),
  \qquad
  n\in\mathbb Z_{\geq1}.
  \label{eq:appendix-cut-convention}
\end{align}
The derivative in Eq.~\eqref{eq:appendix-cut-convention} acts on the real
argument \(D_c\), while the energy theta function is held fixed.

If an \(L\)-fold cut integral contains \(N_C\) physical cuts, and the physical
convention assigns \(2\pi\mathcal C\) to each cut, then
\begin{equation}
  I_{\rm phys}
  =
  \left(
   \frac{i\pi^{D/2}}{(2\pi)^D}
  \right)^L
  (2\pi)^{N_C}
  I_{\rm IBP}.
  \label{eq:ibp-to-physical-conversion}
\end{equation}
This conversion concerns only the integration and cut normalization.  It
does not alter the cut energy orientation, the causal prescription of an
ordinary propagator, or the branch of a noninteger power.

\subsection{Endpoint distributions}
\label{app:endpoint-distributions}

On \(0\leq w\leq1\),
\begin{equation}
  \mathcal D_m(w)
  =
  \left[
   \frac{\log^m(1-w)}{1-w}
  \right]_+,
  \qquad
  m\in\mathbb Z_{\geq0},
  \label{eq:appendix-plus-distribution}
\end{equation}
with the test-function definition in
Eq.~\eqref{eq:plus-distribution-test-function}.  For \(a>0\),
\begin{equation}
  (1-w)^{-1-a\eps}
  =
  -\frac{\delta(1-w)}{a\eps}
  +
  \sum_{m=0}^{\infty}
  \frac{(-a\eps)^m}{m!}\mathcal D_m(w).
  \label{eq:appendix-endpoint-identity}
\end{equation}
The identity is first defined for \(\operatorname{Re}\eps<0\) and then
continued meromorphically as a distribution.  The coefficients multiplying
Eq.~\eqref{eq:appendix-endpoint-identity} must remain unexpanded until every
endpoint branch has been identified.

\subsection{Symbol table}
\label{app:symbol-table}

\begin{table}[htbp]
\centering
\small
\begin{tabular}{@{}p{0.19\textwidth}p{0.72\textwidth}@{}}
\toprule
Symbol & Meaning \\
\midrule
\(P_A,P_B\)
& Incoming hadron momenta. \\
\(P_h\)
& Momentum of the identified hadron. \\
\(S_A,S_B,S_h\)
& Hadronic spin vectors; \(S_{AT}\) and \(S_{hT}\) denote their physical
  transverse components. \\
\(k_a,k_b,k_c\)
& Incoming and observed outgoing parton momenta,
  \(k_a=x_aP_A\), \(k_b=x_bP_B\), \(k_c=P_h/z_h\). \\
\(x_a,x_b,z_h\)
& Collinear momentum fractions, with \(0<x_a,x_b,z_h<1\). \\
\(S,T,U\)
& Hadronic Mandelstam invariants. \\
\(s,t,u\)
& Partonic Mandelstam invariants. \\
\(q\)
& Total momentum of the unobserved partonic final state,
  \(q=k_a+k_b-k_c\). \\
\(Q^2\)
& Inclusive recoil invariant,
  \(Q^2=q^2=s+t+u\). \\
\(v,w\)
& Dimensionless single-inclusive variables,
  \(v=1+t/s\) and \(w=-u/(s+t)\). \\
\(x\)
& Endpoint variable \(x=1-w\); this symbol is distinct from the momentum
  fractions \(x_a,x_b\). \\
\(D,\eps\)
& Dimensional-regularization variables, \(D=4-2\eps\). \\
\(\mu_R,\mu_F\)
& Renormalization and collinear-factorization scales. \\
\(a_s\)
& Formal perturbative expansion parameter; its normalization relative to
  \(\alpha_s\) must be fixed globally. \\
\(\Phi_{\chi/H}\)
& Leading-twist collinear distribution correlator for
  \(\chi=q,\bar q\). \\
\(\Delta_{h/\chi}\)
& Leading-twist collinear fragmentation correlator. \\
\(f_1,g_{1L},h_1\)
& Unpolarized, helicity, and transversity collinear distributions. \\
\(D_1,G_{1L},H_1\)
& Unpolarized, helicity, and transversity collinear fragmentation functions. \\
\(\mathscr F^{\mathsf P}\)
& PDF/FF product associated with polarization channel \(\mathsf P\). \\
\(\dd\Xi_h\)
& Convolution-fraction measure, including the chosen hadronic Jacobian. \\
\(\mathfrak m_{\mathsf P}\)
& Declared Laurent monomial in \(x_a,x_b,z_h\), placed outside the hard
  function. \\
\(\mathcal N_{\rm com}^{\mathsf P,(n)}\)
& Common scalar normalization temporarily removed from the order-\(n\) hard
  function and restored before endpoint expansion. \\
\(\widetilde H^{\mathsf P,(n)}\)
& Reduced analytic coefficient after removal of
  \(\mathcal N_{\rm com}^{\mathsf P,(n)}\). \\
\(H^{\mathsf P,(n)}\)
& Physical partonic hard function at relative perturbative order \(n\). \\
\(\mathcal D_m(w)\)
& Plus distribution
  \(\bigl[\log^m(1-w)/(1-w)\bigr]_+\). \\
\(\delta_+(p^2)\)
& Positive-energy on-shell distribution
  \(\theta(p^0)\delta(p^2)\). \\
\(\mathcal C_\xi^{(n)}\)
& Oriented reverse-unitarity cut of power \(n\). \\
\(\mathcal P_2(Q^2,\eps)\)
& Reduced two-body phase-space factor used in the NLO master normalization. \\
\bottomrule
\end{tabular}
\caption{Kinematic, polarization, normalization, and distribution symbols
used throughout the manuscript.}
\label{tab:symbol-table}
\end{table}

## Sources sent to Pro

- Original source reference: `C:\Users\congyue zhang\Desktop\Mathematica\Hard Function\EvaluateMasters\NNLOFull\Boundary_Integrals_and_Equivalence_Levels.tex` (not archived with this exchange)
