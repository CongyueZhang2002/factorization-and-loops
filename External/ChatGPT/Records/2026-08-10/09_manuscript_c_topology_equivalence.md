# Manuscript C Topology Equivalence

## Question

The attached file defines cut-aware topology equivalence. Review and rewrite
this appendix only.

Return a short critique and compilable replacement LaTeX. Check that the
allowed affine loop-momentum map, determinant condition, denominator-slot
permutation, external relabeling, cut momenta and energy orientations,
forward/conjugate virtual-side assignment, measurement labels, and index-vector
map are sufficient for an exact equality of dimensionally regulated cut
integrals. Correct the two-loop example if its permutation or orientations are
wrong. Distinguish topology equivalence from positive-denominator equivalence
and from equality of a measured numerator insertion. Do not rewrite another
appendix or section.

## Pro response

Short critique

The current record omits the physical chamber, analytic branch, admissible index domain, and the causal class of ordinary or auxiliary slots. Without these data, equality of denominator polynomials does not by itself establish equality of the corresponding boundary-value integrals. 

C_topology_equivalence

The affine map needs a precise restriction on the phase-space, forward-virtual, and conjugate-virtual sectors. A forward loop may be shifted by phase-space and external momenta, but it may not mix with a conjugate loop; a phase-space integration variable may not acquire virtual-loop dependence. A block-triangular condition is given below.

The determinant condition should be stated as

detA=±1.

The real LD-dimensional Jacobian is ∣detA∣
D
=1; no sign is produced by detA=−1.

An external relabeling is not an arbitrary crossing. It gives direct equality only when it preserves the external particle roles, kinematic ideal, physical chamber, causal boundary values, and analytic branches. Otherwise it relates different analytic continuations rather than equal cut integrals.

Exact slot equality requires more than the denominator polynomial: cut/ordinary/auxiliary type, ordinary causal ownership, cut momentum and energy orientation, and every measurement or distinguished-line label must be transported. The present prose mentions only some of these conditions. 

C_topology_equivalence

The index-vector map in the draft is correct when source slot i maps to target slot π(i). The exact integral identity should nevertheless display the pullback of the external momenta and should be restricted to admissible index vectors.

Topology equivalence does not by itself identify an explicit measured numerator insertion. If the numerator is represented entirely by negative family indices, the index map is sufficient. Otherwise the insertion must also pull back exactly.

The two-loop permutation is correct:

π=(12).

With source cut orientations (+1,−1), the target orientations must be
(−1,+1). The original example is therefore consistent. It also requires the two cut-line labels to be exchanged; if the labels are not exchanged, the records are not equivalent. 

C_topology_equivalence

LaTeX
\section{Exact equivalence of cut-decorated integral families}
\label{app:topology-equivalence}

\subsection{Cut-decorated family records}

Fix the normalized integration measure and oriented-cut convention of
Appendix~\ref{app:conventions}.  A cut-decorated scalar family is specified
by the record
\begin{equation}
 \mathcal T
 =
 \left(
  \boldsymbol\lambda,\boldsymbol p,\boldsymbol d,
  \mathcal K,\mathfrak C,\mathscr S,\mathfrak A_{\mathcal T}
 \right).
 \label{eq:cut-topology-record}
\end{equation}
The integration and external momentum bases are
\begin{equation}
 \boldsymbol\lambda
 =
 (\lambda_1,\ldots,\lambda_L),
 \qquad
 \boldsymbol p
 =
 (p_1,\ldots,p_E).
 \label{eq:topology-momentum-bases}
\end{equation}
The ideal \(\mathcal K\) contains the exact external on-shell,
momentum-conservation, and scalar-product relations.  The symbol
\(\mathfrak C\) denotes the physical chamber together with the chosen
causal boundary values and branches.

The ordered slot list is
\begin{equation}
 \boldsymbol d=(d_1,\ldots,d_N),
 \qquad
 d_i=
 \left(
  \Delta_i,\tau_i,\omega_i,\mathfrak m_i
 \right).
 \label{eq:topology-slot-descriptor}
\end{equation}
Here:

\begin{enumerate}
 \item \(\Delta_i(\boldsymbol\lambda,\boldsymbol p)\) is the exact scalar
 denominator polynomial;

 \item
 \begin{equation}
  \tau_i\in
  \{\mathrm{cut},\mathrm{ordinary},\mathrm{auxiliary}\}
  \label{eq:topology-slot-type}
 \end{equation}
 records whether the slot is a physical cut, a literal ordinary propagator,
 or a completion denominator;

 \item for a cut slot,
 \begin{equation}
  \omega_i=(q_i,\xi_i),
  \qquad
  \Delta_i=q_i^2-m_i^2,
  \qquad
  \xi_i\in\{+1,-1\};
  \label{eq:topology-cut-slot-data}
 \end{equation}

 \item for an ordinary or auxiliary slot,
 \begin{equation}
  \omega_i=\chi_i,
  \qquad
  \chi_i\in\{F,C,S,M\},
  \label{eq:topology-causal-class}
 \end{equation}
 where \(F\), \(C\), \(S\), and \(M\) denote forward-virtual,
 conjugate-virtual, shared real, and mixed forward--conjugate dependence,
 respectively;

 \item \(\mathfrak m_i\) is either the empty label or a tuple containing every
 physical line label that must be preserved, such as particle species,
 observed or unobserved status, cut identity, and measurement role.
\end{enumerate}

The integration variables are ordered according to the sector decomposition
\begin{equation}
 \boldsymbol\lambda
 =
 \left(
  \boldsymbol k,\boldsymbol\ell_F,\boldsymbol\ell_C
 \right),
 \label{eq:topology-sector-ordering}
\end{equation}
where \(\boldsymbol k\) contains the remaining real phase-space integration
momenta, while \(\boldsymbol\ell_F\) and \(\boldsymbol\ell_C\) are disjoint
forward- and conjugate-amplitude virtual-loop sets.  This decomposition is
denoted by \(\mathscr S\).  Every physical cut momentum is required to belong
to the span of \(\boldsymbol k\) and the external momenta; a cut momentum may
not contain a virtual loop.

The set
\begin{equation}
 \mathfrak A_{\mathcal T}\subseteq\mathbb Z^N
 \label{eq:topology-admissible-indices}
\end{equation}
contains the admissible index vectors.  In particular,
\begin{equation}
 \nu_c>0
 \qquad
 \text{for every physical cut slot }c,
 \label{eq:topology-cut-index-condition}
\end{equation}
while an active mixed forward--conjugate auxiliary denominator is forbidden:
\begin{equation}
 \chi_i=M
 \quad\Longrightarrow\quad
 \nu_i\leq0.
 \label{eq:topology-mixed-index-condition}
\end{equation}
A shared-real denominator may have \(\nu_i>0\) only when its
prescription-free meromorphic definition has been established in
\(\mathfrak C\), as described in
Sec.~\ref{subsec:reverse-unitarity-causal}.

For \(\boldsymbol\nu\in\mathfrak A_{\mathcal T}\), define
\begin{align}
 I_{\mathcal T}^{(D)}
 (\boldsymbol\nu;\boldsymbol p)
 :={}&
 \int
 \prod_{r=1}^{L}
 \frac{\dd^D\lambda_r}{i\pi^{D/2}}
 \prod_{\substack{c=1\\\tau_c=\mathrm{cut}}}^{N}
 \mathcal C_{\xi_c}^{(\nu_c)}
 (\Delta_c;q_c)
 \notag\\
 &\times
 \prod_{\substack{i=1\\\tau_i\neq\mathrm{cut}}}^{N}
 \mathscr D_i^{(\nu_i)}(\Delta_i),
 \label{eq:topology-scalar-integral}
\end{align}
where
\begin{equation}
 \mathscr D_i^{(\nu)}(\Delta)
 :=
 \begin{cases}
  (\Delta+i0)^{-\nu},
  &\nu>0,\ \chi_i=F,
  \\[1mm]
  (\Delta-i0)^{-\nu},
  &\nu>0,\ \chi_i=C,
  \\[1mm]
  \Delta^{-\nu},
  &\nu>0,\ \chi_i=S,
  \\[1mm]
  \Delta^{-\nu},
  &\nu\leq0.
 \end{cases}
 \label{eq:topology-ordinary-slot-factor}
\end{equation}
The last line includes \(\Delta^0=1\) and polynomial numerator powers.
The case \(\nu>0,\chi_i=M\) is absent because it is excluded from
\(\mathfrak A_{\mathcal T}\).

\subsection{Allowed external and integration-momentum maps}

Let \(\mathcal G_{\rm ext}\) be a declared group of allowed external
relabelings.  An element
\begin{equation}
 \rho\in\mathcal G_{\rm ext}
 \label{eq:allowed-external-relabeling}
\end{equation}
acts linearly with rational coefficients on the external momentum basis and
on all associated external particle, spin, and measurement labels.  It is
allowed only when
\begin{equation}
 \rho(\mathcal K')=\mathcal K,
 \qquad
 \rho(\mathfrak C')=\mathfrak C,
 \label{eq:external-relabeling-kinematics}
\end{equation}
and when it preserves incoming and outgoing roles, particle species, causal
boundary values, and analytic branches.  A crossing that moves the
invariants to a different physical chamber is not an element of
\(\mathcal G_{\rm ext}\) unless the required analytic-continuation and branch
map has been supplied explicitly.

An affine change of integration variables from a target record
\(\mathcal T'\) to a source record \(\mathcal T\) is
\begin{equation}
 \boldsymbol\lambda
 =
 A\boldsymbol\lambda'
 +
 B\boldsymbol p',
 \qquad
 \boldsymbol p=\rho(\boldsymbol p'),
 \qquad
 A_{rs},B_{ra}\in\mathbb Q.
 \label{eq:topology-affine-map}
\end{equation}
With the sector ordering of Eq.~\eqref{eq:topology-sector-ordering}, the
matrix \(A\) must have the form
\begin{equation}
 A=
 \begin{pmatrix}
  A_{00}&0&0\\
  A_{F0}&A_{FF}&0\\
  A_{C0}&0&A_{CC}
 \end{pmatrix},
 \label{eq:topology-sector-preserving-matrix}
\end{equation}
where
\begin{equation}
 A_{00},\ A_{FF},\ A_{CC}
 \quad\text{are invertible over }\mathbb Q.
 \label{eq:topology-sector-block-invertibility}
\end{equation}
Thus a real phase-space variable may mix only with other real phase-space
variables and external momenta.  A forward loop may additionally be shifted
by real phase-space momenta, but not by a conjugate loop; the corresponding
statement holds for a conjugate loop.  The inverse of
Eq.~\eqref{eq:topology-sector-preserving-matrix} has the same form.

The normalized integration measure is preserved when
\begin{equation}
 \det A=\pm1.
 \label{eq:topology-unit-jacobian}
\end{equation}
Indeed, the real \(LD\)-dimensional Jacobian is
\begin{equation}
 \left|\det A\right|^D=1.
 \label{eq:topology-measure-jacobian}
\end{equation}
No orientation sign is generated when \(\det A=-1\).

\subsection{Definition of topology equivalence}

Let \(\mathfrak T\) denote the set of cut-decorated family records with the
same numbers of phase-space, forward-virtual, and conjugate-virtual
integration variables, the same number of slots, the same normalized
measure, and external data related by \(\mathcal G_{\rm ext}\).

For \(\mathcal T,\mathcal T'\in\mathfrak T\), define
\begin{equation}
 \mathcal T\sim_{\rm top}\mathcal T'
 \label{eq:topology-equivalence-symbol}
\end{equation}
if and only if there exist:

\begin{enumerate}
 \item an allowed external relabeling
 \(\rho\in\mathcal G_{\rm ext}\);

 \item an affine map of the form
 Eqs.~\eqref{eq:topology-affine-map}--
 \eqref{eq:topology-unit-jacobian};

 \item a slot permutation
 \begin{equation}
  \pi\in S_N;
  \label{eq:topology-slot-permutation}
 \end{equation}

 \item signs
 \begin{equation}
  \varepsilon_c\in\{+1,-1\}
  \qquad
  \text{for every cut slot }c;
  \label{eq:topology-cut-momentum-signs}
 \end{equation}
\end{enumerate}

such that the following conditions hold.

First, every denominator polynomial is mapped exactly:
\begin{equation}
 \Delta_i
 \bigl(
  A\boldsymbol\lambda'
  +B\boldsymbol p',
  \rho(\boldsymbol p')
 \bigr)
 \equiv
 \Delta'_{\pi(i)}
 (\boldsymbol\lambda',\boldsymbol p')
 \pmod{\mathcal K'}.
 \label{eq:topology-denominator-map}
\end{equation}
No slot-dependent multiplicative factor is allowed.  If instead
\(\Delta_i\mapsto c_i\Delta'_{\pi(i)}\), the integral acquires the
index-dependent factor \(c_i^{-\nu_i}\) and is not equal in the normalization
defined by Eq.~\eqref{eq:topology-scalar-integral}.

Second, the slot type and ordinary causal class are preserved:
\begin{equation}
 \tau_i=\tau'_{\pi(i)},
 \qquad
 \chi_i=\chi'_{\pi(i)}
 \quad
 \text{for every noncut slot }i.
 \label{eq:topology-slot-causal-map}
\end{equation}

Third, the physical cut set, cut momenta, and energy orientations satisfy
\begin{align}
 \pi(C)&=C',
 \notag\\
 q_c
 \bigl(
  A\boldsymbol\lambda'
  +B\boldsymbol p',
  \rho(\boldsymbol p')
 \bigr)
 &=
 \varepsilon_c q'_{\pi(c)}
 (\boldsymbol\lambda',\boldsymbol p'),
 \notag\\
 \xi'_{\pi(c)}
 &=
 \varepsilon_c\xi_c.
 \label{eq:topology-cut-map}
\end{align}
Equivalently, the oriented cut momentum is mapped without a sign:
\begin{equation}
 \xi_c q_c
 \longmapsto
 \xi'_{\pi(c)}q'_{\pi(c)}.
 \label{eq:oriented-cut-momentum-map}
\end{equation}
The relation in Eq.~\eqref{eq:topology-cut-map} ensures
\begin{equation}
 \mathcal C_{\xi_c}^{(n)}(\Delta_c;q_c)
 \longmapsto
 \mathcal C_{\xi'_{\pi(c)}}^{(n)}
 (\Delta'_{\pi(c)};q'_{\pi(c)})
 \label{eq:cut-operator-under-topology-map}
\end{equation}
for every positive cut power \(n\).

Fourth, every physical line label is transported:
\begin{equation}
 \rho_\ast(\mathfrak m_i)
 =
 \mathfrak m'_{\pi(i)}.
 \label{eq:topology-measurement-label-map}
\end{equation}
The empty label is included in this condition.  Thus an observed line cannot
be mapped to an unobserved line, and distinct measured particles may be
permuted only when the measurement definition permits that permutation.

Finally, the admissible index domains must agree:
\begin{equation}
 \boldsymbol\nu\in\mathfrak A_{\mathcal T}
 \quad\Longleftrightarrow\quad
 \pi_\ast\boldsymbol\nu
 \in\mathfrak A_{\mathcal T'},
 \label{eq:topology-admissible-domain-map}
\end{equation}
where
\begin{equation}
 (\pi_\ast\boldsymbol\nu)_j
 :=
 \nu_{\pi^{-1}(j)}.
 \label{eq:topology-index-permutation}
\end{equation}

The relation \(\sim_{\rm top}\) is an equivalence relation.  Reflexivity is
given by the identity external map, \(A=\boldsymbol1\), \(B=0\), and
\(\pi=\mathrm{id}\).  The inverse witness exists because
\(A^{-1}\) is rational, has determinant \(\pm1\), and has the same
sector-preserving block form; the inverse external relabeling and
\(\pi^{-1}\) give symmetry.  Composition of two witnesses preserves the
block form, unit determinant, exact slot identities, cut signs, labels, and
admissible index domains, proving transitivity.

\subsection{Powered-integral equality}

Let
\begin{equation}
 \mathfrak I
 :=
 \left\{
  (\mathcal T,\boldsymbol\nu)
  \,\middle|\,
  \mathcal T\in\mathfrak T,\ 
  \boldsymbol\nu\in\mathfrak A_{\mathcal T}
 \right\}.
 \label{eq:powered-integral-carrier}
\end{equation}
For two powered scalar integrals in \(\mathfrak I\), define
\begin{equation}
 (\mathcal T,\boldsymbol\nu)
 \sim_{\rm pow}
 (\mathcal T',\boldsymbol\nu')
 \quad\Longleftrightarrow\quad
 \begin{gathered}
  \text{there is a witness for }
  \mathcal T\sim_{\rm top}\mathcal T'
  \text{ with slot map }\pi,
  \\
  \boldsymbol\nu'=\pi_\ast\boldsymbol\nu.
 \end{gathered}
 \label{eq:powered-integral-equivalence}
\end{equation}
This is also an equivalence relation.

For a witness of
Eq.~\eqref{eq:powered-integral-equivalence}, the exact change of variables
gives
\begin{equation}
 \boxed{
 I_{\mathcal T}^{(D)}
 \bigl(
  \boldsymbol\nu;\rho(\boldsymbol p')
 \bigr)
 =
 I_{\mathcal T'}^{(D)}
 \bigl(
  \pi_\ast\boldsymbol\nu;\boldsymbol p'
 \bigr)
 }.
 \label{eq:topology-index-map}
\end{equation}
The proof uses:

\begin{enumerate}
 \item the unit real Jacobian in
 Eq.~\eqref{eq:topology-measure-jacobian};

 \item the exact denominator identities in
 Eq.~\eqref{eq:topology-denominator-map};

 \item preservation of every ordinary causal boundary value;

 \item preservation of the physical chamber and analytic branch;

 \item the cut identity in
 Eq.~\eqref{eq:cut-operator-under-topology-map};

 \item exact transport of every physical line label.
\end{enumerate}

Equation~\eqref{eq:topology-index-map} is the equality that permits one IBP
reduction to be reused for another cut-decorated family.  If
\(\rho=\mathrm{id}\), the external arguments on the two sides are identical.
For a nontrivial physical relabeling, the equality is understood after the
displayed pullback of the external momenta.

\subsection{Positive-denominator equivalence}

For a powered integral
\((\mathcal T,\boldsymbol\nu)\in\mathfrak I\), define its
positive-denominator set by
\begin{equation}
 Z(\mathcal T,\boldsymbol\nu)
 :=
 \left\{
  d_i\ \middle|\ \nu_i>0
 \right\}.
 \label{eq:positive-denominator-set}
\end{equation}
The descriptor \(d_i\) retains the exact denominator polynomial, slot type,
cut orientation or ordinary causal class, and physical line label, but
\(Z\) does not retain the value of a positive power.

For two powered integrals, define
\begin{equation}
 (\mathcal T,\boldsymbol\nu)
 \sim_{\rm den}
 (\mathcal T',\boldsymbol\nu')
 \label{eq:positive-denominator-equivalence-symbol}
\end{equation}
if and only if an allowed affine and external map gives a bijection
\begin{equation}
 Z(\mathcal T,\boldsymbol\nu)
 \longrightarrow
 Z(\mathcal T',\boldsymbol\nu')
 \label{eq:positive-denominator-bijection}
\end{equation}
that obeys the denominator, causal, cut, chamber, branch, and label
conditions above.  The map need not extend to a permutation of inactive
completion slots.

The relation \(\sim_{\rm den}\) classifies denominator geometry.  It does
not imply equality of scalar integrals when positive powers differ, when
negative numerator powers differ, or when explicit numerator insertions
differ.  In particular,
\begin{equation}
 \sim_{\rm pow}
 \quad\Longrightarrow\quad
 \sim_{\rm den},
 \label{eq:powered-implies-denominator-equivalence}
\end{equation}
whereas the converse does not hold in general.

\subsection{Explicit numerator and measurement insertions}

Topology equivalence concerns the scalar family.  Let
\begin{equation}
 I_{\mathcal T}^{(D)}
 [\mathcal O;\boldsymbol\nu]
 \label{eq:integral-with-explicit-insertion}
\end{equation}
denote the same cut integral with an additional numerator or measurement
insertion
\begin{equation}
 \mathcal O
 =
 \mathcal O
 (\boldsymbol\lambda,\boldsymbol p,\boldsymbol S).
 \label{eq:explicit-insertion}
\end{equation}
If \(\mathcal O\) is represented completely by negative powers of the family
slots, Eq.~\eqref{eq:powered-integral-equivalence} already transports it.
Otherwise, equality of the inserted integrals additionally requires
\begin{equation}
 \mathcal O
 \bigl(
  A\boldsymbol\lambda'
  +B\boldsymbol p',
  \rho(\boldsymbol p'),
  \rho(\boldsymbol S')
 \bigr)
 \equiv
 \mathcal O'
 (\boldsymbol\lambda',\boldsymbol p',\boldsymbol S')
 \pmod{\mathcal K'}.
 \label{eq:insertion-map-condition}
\end{equation}
A line label in \(\mathfrak m_i\) prevents an inadmissible permutation of
measured lines, but it does not replace
Eq.~\eqref{eq:insertion-map-condition} for a nontrivial weight, tensor, or
numerator.  Likewise, topology equivalence alone does not identify diagram
coefficients, color factors, or signs from fermion permutations.

\subsection{Two-integration-variable example}

Consider the two ordered families
\begin{align}
 \boldsymbol\Delta_A
 &=
 \bigl(
  \ell_1^2,\,
  \ell_2^2,\,
  (\ell_1-\ell_2)^2,\,
  (\ell_1-p)^2,\,
  (\ell_1+\ell_2-p)^2
 \bigr),
 \notag\\
 \boldsymbol\Delta_B
 &=
 \bigl(
  r_1^2,\,
  r_2^2,\,
  (r_1-r_2)^2,\,
  (r_2-p)^2,\,
  (r_1+r_2-p)^2
 \bigr).
 \label{eq:topology-example-families}
\end{align}
Take the external relabeling to be the identity and define
\begin{equation}
 \ell_1=r_2,
 \qquad
 \ell_2=r_1,
 \qquad
 A=
 \begin{pmatrix}
  0&1\\
  1&0
 \end{pmatrix},
 \qquad
 \det A=-1.
 \label{eq:topology-example-loop-map}
\end{equation}
The denominators map as
\begin{equation}
 \bigl(
  \Delta_{A,1},
  \Delta_{A,2},
  \Delta_{A,3},
  \Delta_{A,4},
  \Delta_{A,5}
 \bigr)
 \longmapsto
 \bigl(
  \Delta_{B,2},
  \Delta_{B,1},
  \Delta_{B,3},
  \Delta_{B,4},
  \Delta_{B,5}
 \bigr).
 \label{eq:topology-example-denominator-map}
\end{equation}
Hence
\begin{equation}
 \pi=(12).
 \label{eq:topology-example-permutation}
\end{equation}

Let slots \(1\) and \(2\) be cuts with
\begin{equation}
 q_{A,1}=\ell_1,
 \qquad
 q_{A,2}=\ell_2,
 \qquad
 q_{B,1}=r_1,
 \qquad
 q_{B,2}=r_2.
 \label{eq:topology-example-cut-momenta}
\end{equation}
The map gives
\begin{equation}
 q_{A,1}\longmapsto q_{B,2},
 \qquad
 q_{A,2}\longmapsto q_{B,1},
 \label{eq:topology-example-cut-map}
\end{equation}
with
\begin{equation}
 \varepsilon_1=\varepsilon_2=+1.
 \label{eq:topology-example-cut-signs}
\end{equation}
Therefore the target orientations must obey
\begin{equation}
 \xi_{B,1}=\xi_{A,2},
 \qquad
 \xi_{B,2}=\xi_{A,1}.
 \label{eq:topology-example-orientations}
\end{equation}
For example,
\begin{equation}
 (\xi_{A,1},\xi_{A,2})=(+1,-1)
 \quad\Longrightarrow\quad
 (\xi_{B,1},\xi_{B,2})=(-1,+1).
 \label{eq:topology-example-oriented-pair}
\end{equation}
Keeping \((+1,-1)\) in both records would violate
Eq.~\eqref{eq:topology-example-orientations}, despite the equality of the
quadratic denominator polynomials.

If the two integration variables have the same sector assignment in the two
records and the physical line labels satisfy
\begin{equation}
 \mathfrak m_{B,1}=\mathfrak m_{A,2},
 \qquad
 \mathfrak m_{B,2}=\mathfrak m_{A,1},
 \qquad
 \mathfrak m_{B,j}=\mathfrak m_{A,j}
 \quad(j=3,4,5),
 \label{eq:topology-example-label-map}
\end{equation}
then the powered integrals obey
\begin{equation}
 I_A^{(D)}
 (\nu_1,\nu_2,\nu_3,\nu_4,\nu_5)
 =
 I_B^{(D)}
 (\nu_2,\nu_1,\nu_3,\nu_4,\nu_5).
 \label{eq:topology-example-identity}
\end{equation}
If the cut labels are physically distinct and are not exchanged as in
Eq.~\eqref{eq:topology-example-label-map}, or if the two loop variables have
different forward/conjugate sector assignments, the map is rejected.

## Sources sent to Pro

- [manuscript_c_topology_equivalence.tex](Sources/09_manuscript_c_topology_equivalence/manuscript_c_topology_equivalence.tex)
