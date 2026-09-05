# Boundary Report

## Question

# Review and rewrite request

Please revise the report draft below as a self-contained analytic physics
explanation, not as a coding log. Preserve precise definitions and concrete
formulae, but improve the narrative, terminology, and pedagogy. The central
question is the number of genuinely distinct boundary integrations that an
agent must evaluate with SubTropica; do not conflate that with the number of
masters or maximal denominator supports.

The following NLO facts have been checked directly against the analytic
evaluator and must remain explicit:

- Kira returns 6 masters: 1 cut bubble and 5 physical top instances.
- Exact support classification gives 3 support orbits and 2 maximal
  nontrivial supports.
- The evaluator makes exactly 2 analytic SubTropica integrations: one bubble
  density and one generic top density.
- All 5 top instances are substitutions of the same generic top function.
- Therefore the full NLO master set needs 2 analytic inputs total, but only 1
  genuinely nontrivial boundary integration if the elementary bubble is
  treated as known.
- The generic top endpoint is normalized by
  lim_{z->0+} [(Lambda1 Lambda2/Pi) T(z,epsilon) + 1/epsilon] = 0.

For NNLO, 342 masters -> 130 powered orbits -> 82 support orbits -> 17 maximal
nontrivial supports is exact. However, 17 is not yet the count of independent
DE systems, SubTropica boundary jobs, scalar boundary coefficients, or new
periods. Explain what additional quotients/checks are required before an agent
queue can be constructed. Keep the solved 83bb/f228/d099 examples and use them
to illustrate why one boundary integral, scalar coefficients, and new periods
are different counts.

Return a complete replacement report, with equations in LaTeX and tables in
Markdown. Do not invent references and do not use unexplained internal hashes
as physical names.

# Draft to revise

# Boundary families in reverse-unitarity master integrals

## Purpose and scope

This report defines precisely what is meant by a master integral, a powered
orbit, a denominator support, a subsector, a maximal support family, a
differential-equation family, a scalar boundary coefficient, and a new hard
period. These objects are not interchangeable.

The concrete calculations are the real-emission reverse-unitarity reductions
for single-inclusive hadron production. The NLO 5 x 5 calculation gives six
Kira masters, three denominator-support orbits, and two maximal nontrivial
support families. Nevertheless, its exact analytic solution requires only two
direct analytic inputs: one cut-bubble normalization and one generic top
boundary. The second input supplies all five non-bubble master instances.
Applying the same support definition to the corrected NNLO double-real basis
gives 342 Kira masters and 17 maximal nontrivial support families.

The number 17 is an exact statement about denominator geometry. It is not yet
the number of independent differential-equation systems, direct SubTropica
boundary evaluations, scalar Frobenius coefficients, or genuinely new
analytic periods. The detailed NLO example shows explicitly why these counts
can differ.

## 1. Integral objects and notation

Let the massless hard momenta be $k_a,k_b,k_c$, with signed hard-leg set

$$
H=\{k_a,k_b,-k_c\}.
$$

Define

$$
s=(k_a+k_b)^2,\qquad
t=(k_a-k_c)^2,\qquad
u=(k_b-k_c)^2,
$$

so that the unobserved recoil momentum is

$$
q=k_a+k_b-k_c,\qquad q^2=s+t+u.
$$

A reverse-unitarity integral is represented by

$$
I_{T,\boldsymbol\nu}(s,t,u;\epsilon)
=\int\prod_{r=1}^{L}\frac{d^D\ell_r}{i\pi^{D/2}}
\prod_{j=1}^{N_T}D_{T,j}^{-\nu_j},
\qquad D=4-2\epsilon.
$$

Some $D_{T,j}$ are ordinary Feynman denominators and some are oriented cut
denominators. For a cut line, a positive index denotes the corresponding
reverse-unitarity cut distribution; an index greater than one denotes a
differentiated cut. The implementation stores the same object as

$$
\operatorname{GLI}[T,\boldsymbol\nu].
$$

The topology label $T$ fixes the ordered denominator list, loop momenta,
external momenta, kinematic rules, and the positions and orientations of the
physical cuts. The exponent vector $\boldsymbol\nu$ fixes the particular
integral inside that topology.

### 1.1 Active denominator support

For a master $I_{T,\boldsymbol\nu}$, its active support is

$$
\operatorname{supp}(I_{T,\boldsymbol\nu})
=\{D_{T,j}:\nu_j>0\}.
$$

The support remembers which denominator hypersurfaces are present. It forgets
their positive powers. Thus $D^{-1}$ and $D^{-2}$ have the same support but are
different powered integrals. A numerator, represented by $\nu_j<0$, is not an
active denominator.

All physical cut lines are retained in the support. A support comparison is
invalid if it silently deletes a cut or changes its positive-energy
orientation.

## 2. Seven distinct levels of equivalence

### 2.1 Diagram equality

Two amplitude or conjugate-amplitude diagrams are equal only if their graph,
field assignments, external ordering, and side of the cut agree. Different
diagrams can nevertheless generate the same loop-integral topology after
color, spin, and numerator algebra. Diagram equality is therefore finer than
integral-family equivalence.

### 2.2 Certified affine topology equivalence

Two `FCTopology` objects are affinely equivalent if there is an invertible
affine loop-momentum transformation

$$
\ell'_r=\sum_s A_{rs}\ell_s+\sum_i B_{ri}p_i,
\qquad \det A=\pm1,
$$

together with an allowed external relabeling, that maps the complete ordered
denominator set of one topology into the other while preserving the physical
cuts. This is tested before Kira with certified FeynCalc topology mappings.
Consequently, the later family count is not a count of diagram names or raw
topology labels.

### 2.3 Powered master-orbit equivalence

Let $G$ be the certified relabeling group. At NLO, the final-state cut momenta
form an $S_2$ permutation orbit; at NNLO they form an $S_3$ orbit. The signed
hard legs $H=\{k_a,k_b,-k_c\}$ form a second $S_3$ orbit for the geometric
classification.

Two masters are power-aware equivalent if an element of $G$ maps every cut and
ordinary denominator into the other master with the same exponent. Dots and
differentiated cuts are retained. This equivalence answers: "Are these the
same powered integral after a certified momentum relabeling?"

### 2.4 Denominator-support equivalence

Two masters are support equivalent if, after replacing every positive
denominator exponent by one, an element of $G$ maps their active denominator
sets into each other. This equivalence answers: "Do these integrals have the
same denominator zero loci, regardless of dots?"

Support equivalence is coarser than powered equivalence. It is essential to
remove powers first and then recanonicalize under all elements of $G$. Merely
deleting powers from a previously chosen powered representative is incorrect:
the group element that minimizes the powered signature need not minimize the
unpowered support signature.

### 2.5 Subsector containment

Containment is a partial order, not an equivalence relation. For support orbits
$[S]$ and $[T]$, define

$$
[S]\preceq[T]
$$

if there exists $g\in G$ such that every active denominator of $gS$ is an
active denominator of $T$. Strict containment, written $[S]\prec[T]$, also
requires that the two supports are not equivalent.

The downward closure of a support $M$ is

$$
\downarrow M=\{S:S\preceq M\}.
$$

It contains the top support and all of its proper subsectors. Different
maximal supports can share lower sectors, so downward closures may overlap.

### 2.6 Differential-equation closure

For a maximal support $M$, define

$$
V_M=\operatorname{span}\{I_j:\operatorname{supp}(I_j)\in\downarrow M\}.
$$

It is a closed differential-equation family only if every independent
kinematic derivative, followed by exact IBP reduction, remains in this space:

$$
\partial_s V_M\subseteq V_M,\qquad
\partial_t V_M\subseteq V_M,\qquad
\partial_u V_M\subseteq V_M.
$$

If a reduced derivative contains a top master from another incomparable
maximal support, those supports belong to one larger DE system. Shared lower
sectors alone do not merge two systems. Conversely, one support family can
split into independent DE blocks.

### 2.7 Equality of boundary periods

Even distinct closed DE systems can reuse the same analytic boundary period.
This is a relation between evaluated functions with a specified normalization,
cut orientation, physical chamber, and branch. It is stronger than equality
of denominator support and cannot be inferred from topology alone.

The three counts

$$
N_{\rm support},\qquad N_{\rm scalar\ boundary},\qquad
N_{\rm new\ periods}
$$

are therefore different. The first is combinatorial. The second follows from
the local Frobenius or Levelt solution after physical constraints. The third
also identifies analytic boundary data shared between different systems.

## 3. Exact canonicalization algorithm

The family inventory was constructed from the exact Kira master list and the
stored topology records as follows.

1. Read each `GLI[T,nu]`, the corresponding `FCTopology`, and the stored cut
   indices and cut momenta. Cuts are never inferred from list position.
2. Convert every active ordinary propagator into its exact polynomial using
   the FeynCalc denominator definition.
3. Impose the massless external relations and the on-shell cut relations.
4. Express the denominator in an independent scalar-product coordinate basis.
5. Normalize each denominator polynomial by a nonzero kinematics-only factor.
   Denominators that differ only by such a factor define the same zero locus.
6. Apply every certified cut-momentum and hard-leg relabeling in $G$.
7. Sort the transformed cut powers and ordinary denominator-polynomial pairs;
   choose the lexicographically smallest exact expression as the canonical
   powered signature.
8. Group equal powered signatures. This gives the powered master orbits.
9. Replace all positive exponents by one, repeat the complete group
   canonicalization, and group the results. This gives support orbits.
10. For every pair of support orbits, test the exact subset condition under all
    elements of $G$. This constructs the finite support partially ordered set.
11. Remove the support containing only the physical cut denominators. Its
    integral is the elementary phase-space normalization.
12. Count the maximal elements of the remaining support poset.

The final step defines the maximal-support count used in this report:

$$
N_{\rm maximal\ support}
=\left|\operatorname{Max}\left(
\mathcal S\setminus\{S_{\rm phase\ space}\}\right)\right|.
$$

This is a geometric screening count. It is an upper-level inventory from
which closed differential systems and analytic boundary tasks are built; it
is not itself a count of boundary integrals.

## 4. Detailed NLO example

### 4.1 NLO cut kinematics

At NLO there is one independent emitted momentum $k_e$ and one dependent
positive-energy cut momentum

$$
k_d=q-k_e.
$$

The two cut denominators are

$$
C_e=k_e^2,\qquad C_d=(q-k_e)^2.
$$

Introduce

$$
a=2k_a\cdot k_e,\qquad
b=2k_b\cdot k_e,\qquad
c=2k_c\cdot k_e.
$$

On the two-cut support,

$$
C_d=0\quad\Longrightarrow\quad
c=a+b-q^2=a+b-(s+t+u).
$$

Up to nonzero overall factors and signs, the canonical ordinary denominator
polynomials in the two nontrivial maximal supports can be represented by

$$
D_a=(k_a-k_e)^2=-a,
$$

$$
D_s=(k_a+k_b-k_e)^2=s-a-b,
$$

and

$$
D_c=(k_c+k_e)^2=c=a+b-(s+t+u).
$$

The three exact NLO support orbits are

$$
S_0=\{C_e,C_d\},
$$

$$
S_A=\{C_e,C_d,D_a,D_s\},
$$

$$
S_B=\{C_e,C_d,D_a,D_c\}.
$$

The two ordinary denominators displayed for each maximal family are canonical
representatives. Individual diagram topologies can display shifted forms, but
certified affine momentum maps and the relabeling group map them to these
representatives.

### 4.2 The six NLO masters

The exact Kira result contains six masters. Their powered and support orbit
sizes are

| Orbit | Support | Number of masters | Interpretation |
|---|---|---:|---|
| 0 | $S_0$ | 1 | Cut-only phase-space normalization |
| A | $S_A$ | 2 | First crossing orbit of top supports |
| B | $S_B$ | 3 | Second crossing orbit of top supports |

All six NLO masters have unit powers on their active denominators, so the
powered-orbit and support-orbit partitions coincide.

The exact containment relations are

$$
S_0\prec S_A,\qquad S_0\prec S_B,
$$

while $S_A$ and $S_B$ are incomparable. The support poset is therefore

```text
        S_A       S_B
          \       /
             S_0
```

The cut-only support $S_0$ is elementary and shared. Removing it leaves two
maximal nontrivial supports. Hence the geometric classification is

$$
6\ \text{Kira masters}
\longrightarrow 3\ \text{support orbits}
\longrightarrow \boxed{2\ \text{maximal nontrivial supports}}.
$$

This result does not yet count analytic boundary evaluations. In particular,
the two incomparable supports turn out to share one generic analytic top
kernel.

### 4.3 Exact NLO analytic boundary workload

The NLO analytic evaluator makes exactly two `STIntegrate` calls. After
normalization, they determine

$$
B(\epsilon)=\frac{2\pi}{1-2\epsilon}
$$

for the cut-only bubble and

$$
T(z,\epsilon;\Lambda_1,\Lambda_2)
=-\frac{\pi}{\epsilon\Lambda_1\Lambda_2}
\,{}_2F_1(1,1;1-\epsilon;z)
$$

for one generic top integral. The generic top obeys a second-order equation,

$$
z(1-z)\,T''+(1-\epsilon-3z)\,T'-T=0,
$$

with normalized endpoint condition

$$
\lim_{z\to0^+}
\left[
\frac{\Lambda_1\Lambda_2}{\pi}T(z,\epsilon)
+\frac{1}{\epsilon}
\right]=0.
$$

The five non-bubble physical masters are not five boundary calculations. They
are obtained from the same function by substituting five physical cross
ratios $z_i$ and scale pairs $(\Lambda_{i1},\Lambda_{i2})$.

The exact NLO workload is therefore:

| Quantity | Exact count | Meaning |
|---|---:|---|
| Kira masters | 6 | One bubble and five physical top instances |
| Maximal nontrivial supports | 2 | Geometric support-poset result |
| Direct analytic inputs needed for the full NLO master set | **2** | $B(\epsilon)$ and the normalized top endpoint |
| Genuinely nontrivial boundary integrations | **1** | The generic top boundary, if the elementary bubble is taken as known |
| Physical top instances generated from that boundary | 5 | Kinematic substitutions, not new integrations |

Thus, when assigning SubTropica work to agents, the NLO baseline is **two
total analytic inputs**, or **one nontrivial boundary task plus one elementary
phase-space normalization**. The current evaluator calls SubTropica twice,
although its generic-top call evaluates the entire one-variable density rather
than only its endpoint value.

## 5. NNLO double-real extension

### 5.1 NNLO cut kinematics

At NNLO double real there are two independent emitted momenta $k_e,k_f$ and a
third dependent cut momentum

$$
k_g=q-k_e-k_f.
$$

The three physical cut denominators are

$$
C_e=k_e^2,\qquad C_f=k_f^2,\qquad
C_g=(q-k_e-k_f)^2.
$$

The scalar-product coordinate set is

$$
a_e=2k_a\cdot k_e,\quad b_e=2k_b\cdot k_e,\quad
c_e=2k_c\cdot k_e,
$$

$$
a_f=2k_a\cdot k_f,\quad b_f=2k_b\cdot k_f,\quad
c_f=2k_c\cdot k_f.
$$

The three cut equations eliminate $k_e^2$, $k_f^2$, and one linear
combination containing $k_e\cdot k_f$. The relabeling group contains all six
permutations of $\{k_e,k_f,k_g\}$ and all six geometric permutations of
$\{k_a,k_b,-k_c\}$.

### 5.2 Exact NNLO counts

The corrected Kira basis contains 342 masters. Exact classification gives

| Level | Count | Precise meaning |
|---|---:|---|
| Individual Kira masters | 342 | Distinct stored `GLI[T,nu]` basis elements |
| Powered master orbits | 130 | Certified relabelings identified; all powers retained |
| Support orbits | 82 | Positive powers removed and supports recanonicalized |
| Cut-only support | 1 | Elementary three-body phase-space normalization |
| Nontrivial support orbits | 81 | Supports containing at least one ordinary denominator |
| Nonmaximal nontrivial supports | 64 | Proper subsectors of at least one maximal support |
| Maximal nontrivial supports | **17** | Exact geometric candidate-family count |

The 130 powered orbits split by orbit size as

$$
14\times1+65\times2+22\times3+21\times4+8\times6=342.
$$

Their canonical cut-power patterns are

$$
92\ \text{orbits with }(1,1,1),\qquad
38\ \text{orbits with }(1,1,2).
$$

The location of the doubled cut is removed by the $S_3$ cut permutation; the
fact that one cut is doubled is retained at the powered level. After all dots
are forgotten and the supports are recanonicalized, 82 support orbits remain.

Every one of the 81 nontrivial supports lies in the downward closure of at
least one of the 17 maximal supports. Downward closures overlap, so their
master counts must not be added.

The maximal-support distribution is

| Number of ordinary denominators, excluding cuts | Number of maximal supports |
|---:|---:|
| 6 | 4 |
| 5 | 12 |
| 4 | 1 |

Therefore, in exactly the same support-hierarchy convention as the NLO result,

$$
342\ \text{Kira masters}
\longrightarrow 130\ \text{powered orbits}
\longrightarrow 82\ \text{support orbits}
\longrightarrow \boxed{17\ \text{maximal nontrivial supports}}.
$$

Unlike at NLO, the 17 supports have not yet been reduced to an exact count of
independent analytic boundary integrations. The NLO reduction from two
maximal supports to one generic nontrivial top boundary proves that simply
assigning one SubTropica job to every maximal support can overcount the work.

### 5.3 Structural inventory of the 17 maximal supports

The identifier is internal to the exact inventory and the key prefix is a
hash of the canonical support. `Descendant supports` includes the top support.
`Family masters` counts masters in the downward closure; closures overlap.

| ID | Key prefix | Ordinary denominators | Direct top masters | Descendant supports | Family masters | Dotted-cut masters |
|---:|---|---:|---:|---:|---:|---:|
| 74 | `17a5135be861` | 6 | 2 | 20 | 71 | 16 |
| 82 | `aa82c3cb4483` | 6 | 1 | 19 | 69 | 16 |
| 80 | `1a6b1463e25b` | 6 | 2 | 17 | 65 | 15 |
| 75 | `ebd2e5286356` | 6 | 1 | 20 | 68 | 14 |
| 61 | `87c5cb61f0f4` | 5 | 4 | 19 | 113 | 31 |
| 65 | `022f1669fd18` | 5 | 2 | 17 | 105 | 26 |
| 68 | `f426f6263f0b` | 5 | 4 | 17 | 93 | 22 |
| 31 | `e4e52e717ccb` | 5 | 4 | 16 | 77 | 20 |
| 63 | `04bd82fb0135` | 5 | 2 | 15 | 77 | 17 |
| 36 | `6fad755c9777` | 5 | 2 | 13 | 59 | 14 |
| 39 | `96984745f2db` | 5 | 2 | 14 | 58 | 14 |
| 64 | `8af7753813cb` | 5 | 4 | 15 | 68 | 8 |
| 67 | `fcba69459ad5` | 5 | 4 | 14 | 65 | 8 |
| 52 | `4bdca617ffd9` | 5 | 4 | 9 | 34 | 5 |
| 50 | `5093f37f62f1` | 5 | 2 | 8 | 24 | 3 |
| 47 | `ec94cf06c55c` | 5 | 1 | 7 | 21 | 3 |
| 19 | `afcc07bf83f8` | 4 | 4 | 6 | 23 | 2 |

These columns provide a structural screening order, not a theorem about
analytic difficulty. Denominator count, family size, and cut dots do not reveal
factorization, resonant Jordan blocks, region counts, or branch-sensitive
endpoint matching.

## 6. From 17 maximal supports to actual boundary tasks

For each maximal support $M$, the next calculation is:

1. construct $V_M$ from the complete downward closure;
2. differentiate in every independent kinematic direction using on-shell
   vector derivatives;
3. reduce every derivative integral with exact closed IBP rules;
4. verify that no top master from another maximal support appears;
5. put the closed system in Fuchsian or epsilon form when possible;
6. compute the local Levelt or Frobenius modes at the chosen boundary;
7. impose regularity, region, corner, symmetry, and lower-sector constraints;
8. count the remaining independent scalar asymptotic coefficients;
9. identify whether any required analytic periods are already known from
   another family with the same normalization and physical branch.

If step 4 fails, construct a graph whose vertices are maximal supports and add
an edge for every derivative leakage. The connected components are the actual
DE superfamilies. The geometric support count remains 17, but the number of
independent DE analyses is then smaller.

After DE closure, a second quotient is still required. Two closed systems can
share a generic parametric density or the same normalized endpoint period,
just as the two NLO maximal supports share the generic function $T$. Only
after this quotient can one make an agent queue in which each item represents
one genuinely distinct analytic boundary evaluation.

## 7. Solved examples and measured boundary difficulty

The exact solved stress families establish the empirical ordering

$$
83\mathrm{bb}>f228>d099.
$$

This order refers to analytic boundary construction, not denominator count.

### 7.1 The 83bb family

The exact family contains eight masters and a genuinely coupled two-master top
block. Its boundary has the modes

$$
x^0,\qquad x^{-\epsilon},\qquad x^{-2\epsilon}.
$$

After all lower-sector data are imposed, exactly one new hard top-corner
period remains. Branch-safe endpoint matching required a nonfactorized corner
analysis. It is the hardest of the three completed families.

### 7.2 The f228 family

This doubled-cut family contains four masters. Its boundary residue has a
repeated Jordan block. One eta-regulated two-region integral determines two
nonuniform asymptotic coefficients. Thus one explicitly evaluated boundary
integral does not imply one scalar boundary coefficient.

### 7.3 The d099 family

This five-master family factorizes into simpler blocks. Its normalized hard
top-boundary period is the same period already required by 83bb. Once the 83bb
period is known, d099 introduces no additional hard period, although it still
requires its own transport and lower-sector bookkeeping.

The remaining 14 maximal supports cannot be ranked honestly until their DE
blocks and local modes are known.

## 8. Physical crossing and branch qualification

The support quotient identifies denominator geometries. A hard-leg crossing
can move the invariants between physical regions. Therefore two
crossing-related supports have the same geometric family, but their physical
boundary values are equal only after the analytic-continuation map is supplied
with the correct $i0$ prescription and branch.

The count 17 is exact as a geometric support count under the declared crossing
group. If a calculation refuses to identify crossed physical chambers until
their branch maps are supplied, the number of separately tabulated physical
boundary expressions can be larger. This does not alter the denominator-poset
result.

## 9. Verification and reproducibility

The same exact support classifier was first run on the archived NLO result.
Its stated acceptance criterion was that it recover the exact three support
orbits and two maximal nontrivial supports. Its result was

$$
6\to3\to2.
$$

The NNLO result was then obtained without changing the definition:

$$
342\to130\to82\to17.
$$

The NNLO coverage check found 81 of 81 nontrivial support orbits in the
downward closure of at least one maximal support. The production reduction had
already merged certified affine-equivalent topologies before Kira. The family
classifier then independently canonicalized all cut and hard-leg relabelings.

The machine-readable records are:

- `NLOMasterKernelOrbitsExactSupport.wl`;
- `MasterKernelOrbitsExactSupport.wl`;
- `BoundaryFamilyRanking.wl`.

They are stored in
`/home/maxzhang/FACET/Codex/ppHX_NNLO_DoubleReal/BoundaryInventory/`.

## 10. Final statement

The NLO calculation has three different exact counts that must not be
collapsed:

$$
N_{\rm maximal\ support,NLO}=2,\qquad
N_{\rm analytic\ input,NLO}=2,\qquad
N_{\rm nontrivial\ boundary,NLO}=1.
$$

Here the two analytic inputs are the elementary bubble normalization and one
generic top endpoint. The NNLO result currently established with the same
geometric classifier is

$$
N_{\rm maximal\ support,NNLO}=17.
$$

The exact NNLO count of direct SubTropica boundary evaluations is not yet
known. It requires DE closure, identification of generic parametric densities,
and equality tests for normalized boundary periods. Reporting 17 as the
number of agent boundary tasks would therefore be premature.

## Follow-up question

# Revision request

Please revise the complete report below for analytic precision and pedagogy.
Do not use the word that commonly denotes the set of active propagators; the
reader rejected it as empty jargon. Always say exactly what is meant, such as
"positive-denominator set", "set inclusion", or "maximal nontrivial
denominator class". Do not turn the exact NNLO count of 17 denominator classes
into a boundary-integral count.

The operational NLO conclusion must remain explicit: six masters require two
analytic inputs in total (the elementary bubble and one generic top endpoint),
or one genuinely nontrivial SubTropica boundary job when the bubble is treated
as known. All five top instances follow by kinematic substitution. Check the
equations and distinctions carefully, then return a complete replacement
report in Markdown with LaTeX equations and tables. Do not invent references.

# Draft

# Counting analytic boundary integrals in reverse unitarity

## Executive answer

The number of Kira master integrals is not the number of analytic boundary
integrals that must be evaluated.

For the complete NLO real-emission reduction studied here:

| Object being counted | Exact number |
|---|---:|
| Kira master integrals | 6 |
| Distinct positive-denominator sets after exact momentum relabeling | 3 |
| Maximal nontrivial denominator sets | 2 |
| Analytic inputs needed to determine all 6 masters | **2** |
| Nontrivial boundary integrals, after treating phase-space volume as known | **1** |

The two analytic inputs are

$$
B(\epsilon)=\frac{2\pi}{1-2\epsilon}
$$

for the elementary cut-bubble normalization and one endpoint value for the
generic top integral

$$
T(z,\epsilon;\Lambda_1,\Lambda_2)
=-\frac{\pi}{\epsilon\Lambda_1\Lambda_2}
\,{}_2F_1(1,1;1-\epsilon;z).
$$

All five non-bubble NLO masters are obtained from this one function by
substituting different cross ratios and scale pairs. Therefore an agent queue
for NLO contains two analytic jobs if the elementary bubble is included, or
one genuinely nontrivial boundary job if that normalization is supplied.

For the current NNLO double-real reduction, the exact bookkeeping result is

$$
342\ \hbox{masters}
\longrightarrow 130\ \hbox{powered equivalence classes}
\longrightarrow 82\ \hbox{denominator-set classes}
\longrightarrow 17\ \hbox{maximal nontrivial denominator classes}.
$$

The number 17 is not yet the number of NNLO boundary integrals. It is the
number of maximal denominator geometries before differential-equation closure,
generic-density identification, and equality tests between normalized
boundary periods.

## 1. Integral being classified

Let

$$
s=(k_a+k_b)^2,\qquad
t=(k_a-k_c)^2,\qquad
u=(k_b-k_c)^2,
$$

and

$$
q=k_a+k_b-k_c,\qquad q^2=s+t+u.
$$

A reverse-unitarity integral is

$$
I_{T,\boldsymbol\nu}(s,t,u;\epsilon)
=\int\prod_{r=1}^{L}\frac{d^D\ell_r}{i\pi^{D/2}}
\prod_{j=1}^{N_T}D_{T,j}^{-\nu_j},
\qquad D=4-2\epsilon.
$$

The topology label $T$ specifies the ordered denominator list, loop momenta,
external momenta, kinematic rules, and physical cuts. The exponent vector
$\boldsymbol\nu$ specifies one integral in that topology. Kira returns these
objects as

$$
\operatorname{GLI}[T,\boldsymbol\nu].
$$

For a given master, define its **positive-denominator set** by listing every
physical cut denominator and every ordinary propagator whose exponent is
positive. Positive powers are ignored in this set. Thus $D^{-1}$ and $D^{-2}$
give the same denominator set, even though they are different master
integrals. A numerator, represented by a negative index, is not included.

The identity and positive-energy orientation of every physical cut remain
part of the definition. No comparison is valid if it deletes a cut or reverses
its energy flow.

## 2. Seven relations that must not be conflated

### 2.1 Equality of diagrams

Two diagrams are equal only when their graphs, field assignments, external
ordering, and side of the cut agree. Distinct diagrams can produce the same
integral after spin, color, and numerator algebra. Diagram counting therefore
does not determine the number of masters or boundary integrals.

### 2.2 Equality after an affine loop-momentum change

Two integral topologies are equivalent if an invertible transformation

$$
\ell'_r=\sum_s A_{rs}\ell_s+\sum_i B_{ri}p_i,
\qquad \det A=\pm1,
$$

together with an allowed external-momentum relabeling, maps every denominator
of one topology to a denominator of the other and preserves each physical
cut. This is the equivalence tested by topology-mapping algorithms before
Kira.

Example at one loop:

$$
\ell\mapsto q-\ell
$$

interchanges the two cut momenta $\ell$ and $q-\ell$. Integrals related by
this change are not independent topology problems.

### 2.3 Equality of powered master integrals

Two masters are power-equivalent if a certified momentum relabeling maps all
their denominators and preserves every exponent. A doubled ordinary
propagator or differentiated cut remains doubled. This relation answers:

> Are these exactly the same integral, including all denominator powers?

At NNLO, the allowed cut relabeling includes all permutations of the three
positive-energy final-state cut momenta. The geometric hard-leg relabeling
includes permutations of $\{k_a,k_b,-k_c\}$, subject to the corresponding
crossing and branch map.

### 2.4 Equality of positive-denominator sets

Now replace every positive exponent by one and repeat the complete momentum
relabeling test. Two masters are equivalent at this level when they contain
the same cut and ordinary denominator hypersurfaces, even if their powers
differ.

The order matters. One must first remove the powers and then search all
allowed relabelings again. The momentum map that gives the smallest powered
representation need not give the smallest unpowered denominator set.

### 2.5 Inclusion between denominator sets

For two equivalence classes $[A]$ and $[B]$, write

$$
[A]\subseteq[B]
$$

when some allowed momentum relabeling maps every denominator in $A$ into the
denominator set $B$. This is inclusion, not equality. A class is maximal when
it is not strictly contained in any other class in the current master list.

For a maximal class $M$, its downward set is

$$
\mathcal D(M)=\{A:A\subseteq M\}.
$$

Two maximal classes can contain the same lower-denominator integral, so their
downward sets can overlap.

### 2.6 Closure under kinematic differentiation and IBP

Let $V_M$ be the vector space spanned by all masters whose denominator sets
belong to $\mathcal D(M)$. It is a self-contained differential-equation system
only if every independent kinematic derivative, followed by exact IBP
reduction, stays in that space:

$$
\partial_s V_M\subseteq V_M,\qquad
\partial_t V_M\subseteq V_M,\qquad
\partial_u V_M\subseteq V_M.
$$

If a derivative produces a top-level master from another incomparable maximal
class, both classes must be solved in one larger differential system. Shared
lower-denominator masters alone do not force such a merger.

### 2.7 Equality of analytic boundary data

Different closed differential systems can require the same normalized
analytic period at a boundary. Equality here means equality after fixing:

- the integral normalization;
- the physical cuts and their energy directions;
- the physical kinematic chamber;
- the causal prescription;
- the analytic branch.

This is why the following numbers are distinct:

$$
N_{\rm master},\quad
N_{\rm maximal\ denominator},\quad
N_{\rm DE\ system},\quad
N_{\rm scalar\ boundary\ coefficient},\quad
N_{\rm boundary\ integral},\quad
N_{\rm new\ period}.
$$

Only $N_{\rm boundary\ integral}$ is the number of independent analytic jobs
to assign to SubTropica agents.

## 3. How the denominator classes were found

The exact classification uses the stored master list and topology definitions:

1. Read each $\operatorname{GLI}[T,\boldsymbol\nu]$, its ordered propagators,
   and the recorded cut positions and cut momenta.
2. Convert every active propagator into its exact scalar-product polynomial.
3. Impose massless external relations and the on-shell equations associated
   with the physical cuts.
4. Express every denominator in an independent scalar-product coordinate
   basis.
5. Divide each denominator polynomial by a nonzero kinematics-only factor.
   Such a factor changes normalization but not the denominator zero locus.
6. Apply every certified cut-momentum and hard-leg relabeling.
7. Sort the transformed cuts, denominator polynomials, and powers, and retain
   the lexicographically smallest exact expression. Equal expressions define
   powered master classes.
8. Set every positive power to one and repeat steps 6 and 7. Equal expressions
   now define positive-denominator-set classes.
9. Test exact set inclusion under every allowed relabeling.
10. Remove the class containing only the physical cuts and identify the
    maximal remaining classes.

Steps 1-10 determine denominator geometry. They do not solve a differential
equation or evaluate a boundary integral.

## 4. NLO in detail

### 4.1 Cut kinematics

At NLO there is one independent emitted momentum $k_e$ and one dependent cut
momentum

$$
k_d=q-k_e.
$$

The physical cuts are

$$
C_e=k_e^2,\qquad C_d=(q-k_e)^2.
$$

Introduce

$$
a=2k_a\cdot k_e,\qquad
b=2k_b\cdot k_e,\qquad
c=2k_c\cdot k_e.
$$

On the two-cut surface,

$$
C_d=0
\quad\Longrightarrow\quad
c=a+b-(s+t+u).
$$

Representative ordinary denominators are

$$
D_a=(k_a-k_e)^2=-a,
$$

$$
D_s=(k_a+k_b-k_e)^2=s-a-b,
$$

and

$$
D_c=(k_c+k_e)^2=c=a+b-(s+t+u).
$$

The six Kira masters occupy three denominator-set classes:

$$
A_0=\{C_e,C_d\},
$$

$$
A_1=\{C_e,C_d,D_a,D_s\},
$$

$$
A_2=\{C_e,C_d,D_a,D_c\}.
$$

The exact master counts are

| Denominator class | Number of masters | Role |
|---|---:|---|
| $A_0$ | 1 | Elementary two-body cut volume |
| $A_1$ | 2 | First maximal nontrivial denominator geometry |
| $A_2$ | 3 | Second maximal nontrivial denominator geometry |

The only strict inclusions are

$$
A_0\subset A_1,\qquad A_0\subset A_2.
$$

Neither $A_1$ nor $A_2$ contains the other. This gives two maximal
nontrivial denominator geometries, but it does not imply two distinct
nontrivial boundary integrals.

### 4.2 Direct analytic calculation

The exact NLO evaluator makes two SubTropica integrations. The first density
is

$$
f_B(r,\epsilon)=r^{-\epsilon}(1+r)^{-2+2\epsilon},
\qquad 0<r<\infty,
$$

and gives the normalized bubble

$$
B(\epsilon)=\frac{2\pi}{1-2\epsilon}.
$$

The second density is

$$
f_T(r,z,\epsilon)=\frac{(1+r)^\epsilon}
{1+(1-z)r},
\qquad 0<z<1,
$$

and gives the generic top function

$$
T(z,\epsilon;\Lambda_1,\Lambda_2)
=-\frac{\pi}{\epsilon\Lambda_1\Lambda_2}
\,{}_2F_1(1,1;1-\epsilon;z).
$$

Its Laurent expansion through the orders displayed by the evaluator is

$$
T=\frac{\pi}{\Lambda_1\Lambda_2}
\left[
-\frac{1}{\epsilon(1-z)}
+\frac{\ln(1-z)}{1-z}
+\epsilon\frac{\operatorname{Li}_2\!\left(\frac{z}{z-1}\right)}{1-z}
+\epsilon^2\frac{\operatorname{Li}_3\!\left(\frac{z}{z-1}\right)}{1-z}
+O(\epsilon^3)
\right].
$$

### 4.3 Differential equation and its boundary

Removing the constant scale factor, the generic top kernel obeys

$$
z(1-z)\,T''(z)+(1-\epsilon-3z)\,T'(z)-T(z)=0.
$$

Its endpoint normalization is

$$
\lim_{z\to0^+}
\left[
\frac{\Lambda_1\Lambda_2}{\pi}T(z,\epsilon)
+\frac{1}{\epsilon}
\right]=0.
$$

Once this one endpoint value is known, the equation determines the generic
function in the physical interval. No new boundary calculation is required
for each physical instance.

### 4.4 The five physical top instances

The five non-bubble masters are obtained by inserting the following cross
ratios and scale pairs into the same $T$:

| Instance | $z_i$ | $(\Lambda_{i1},\Lambda_{i2})$ |
|---|---|---|
| $ac$ | $\dfrac{su}{(s+t)(t+u)}$ | $\left(-\dfrac{s+t}{2},-\dfrac{t+u}{2}\right)$ |
| $ab$ | $\dfrac{tu}{(s+t)(s+u)}$ | $\left(-\dfrac{s+t}{2},-\dfrac{s+u}{2}\right)$ |
| $abb$ | $\dfrac{s(s+t+u)}{(s+t)(s+u)}$ | $\left(-\dfrac{s+t}{2},-\dfrac{s+u}{2}\right)$ |
| $cb$ | $\dfrac{st}{(s+u)(t+u)}$ | $\left(-\dfrac{t+u}{2},-\dfrac{s+u}{2}\right)$ |
| $cbb$ | $\dfrac{u(s+t+u)}{(s+u)(t+u)}$ | $\left(-\dfrac{t+u}{2},-\dfrac{s+u}{2}\right)$ |

The physical assumptions ensure $0<z_i<1$ for every row, fixing a common
real branch.

### 4.5 Exact number of NLO boundary jobs

There are two defensible ways to count, depending on whether the elementary
phase-space normalization is placed in the agent queue:

1. **Complete analytic-input count: 2.** Evaluate $B(\epsilon)$ and the
   normalized endpoint of $T$.
2. **Nontrivial boundary-task count: 1.** Supply $B(\epsilon)$ as an elementary
   known input and assign only the top endpoint to a SubTropica agent.

The project should record both numbers and state which convention is used.
For planning difficult work, the relevant NLO benchmark is

$$
\boxed{N_{\rm difficult\ boundary\ jobs}^{\rm NLO}=1}.
$$

The current direct evaluator calls SubTropica twice because it also computes
the bubble and evaluates the full generic top density, not merely the endpoint.

## 5. NNLO double real

### 5.1 Cut kinematics

At NNLO double real there are two independent emitted momenta $k_e,k_f$ and a
third cut momentum

$$
k_g=q-k_e-k_f.
$$

The physical cuts are

$$
C_e=k_e^2,\qquad C_f=k_f^2,\qquad
C_g=(q-k_e-k_f)^2.
$$

All six permutations of $\{k_e,k_f,k_g\}$ are included when comparing
denominators. The geometric hard-leg relabelings act on
$\{k_a,k_b,-k_c\}$, with the physical branch map retained separately.

### 5.2 Exact bookkeeping result

The corrected NNLO Kira basis gives:

| Object being counted | Exact number | Definition |
|---|---:|---|
| Kira masters | 342 | Stored $\operatorname{GLI}$ basis elements |
| Powered classes | 130 | Momentum relabeling identifies denominators and all powers |
| Positive-denominator-set classes | 82 | Positive powers replaced by one, then recanonicalized |
| Cut-only class | 1 | Three-body phase-space volume |
| Nontrivial denominator classes | 81 | At least one ordinary propagator present |
| Maximal nontrivial denominator classes | **17** | Not contained in another class |

The 130 powered classes account for all masters:

$$
14\times1+65\times2+22\times3+21\times4+8\times6=342.
$$

Their cut-power patterns are

$$
92\ \hbox{classes with }(1,1,1),\qquad
38\ \hbox{classes with }(1,1,2).
$$

Among the 17 maximal denominator classes, four contain six ordinary
propagators, twelve contain five, and one contains four, in addition to the
three physical cuts.

### 5.3 Why 17 is not the boundary workload

NLO already supplies a counterexample to the rule "one maximal denominator
class equals one boundary job": two maximal classes share one generic top
function and one nontrivial endpoint. At NNLO, the following operations remain
before a reliable boundary-agent queue can be produced:

1. Build the exact derivative equations for every maximal denominator class
   and all of its contained classes.
2. Reduce every derivative by IBP and merge classes whenever derivatives mix
   their top-level masters.
3. Transform each closed system near a chosen endpoint and determine its local
   exponents and Jordan blocks.
4. Apply regularity, symmetry, region, corner, and lower-integral constraints.
5. List the scalar coefficients that remain undetermined.
6. Construct an explicit integral representation for each remaining
   coefficient.
7. Identify representations related by changes of variables, crossings with
   a proven branch map, or equality to an already evaluated normalized period.
8. Assign one SubTropica job only to each remaining distinct representation.

Only after step 8 is the exact NNLO boundary workload known.

## 6. What the completed NNLO examples teach

Three difficult systems have been solved analytically and compared with
independent AMFlow values through $O(\epsilon^2)$. Their measured difficulty is

$$
83\mathrm{bb}>f228>d099.
$$

The labels identify stored calculation records; the analytic distinctions are
more important than the labels.

### 6.1 Coupled two-master top block

The eight-master example denoted $83\mathrm{bb}$ contains a coupled
two-master top block with local modes

$$
x^0,\qquad x^{-\epsilon},\qquad x^{-2\epsilon}.
$$

After lower integrals are supplied, one genuinely new top-corner period
remains. Obtaining it requires a nonfactorized corner integral with explicit
branch control.

### 6.2 Repeated local exponent

The four-master example denoted $f228$ contains a repeated Jordan block and a
doubled cut. One eta-regulated, two-region boundary integral determines two
independent nonuniform asymptotic coefficients. Thus one boundary integral
can determine more than one scalar coefficient.

### 6.3 Reused period

The five-master example denoted $d099$ factorizes into smaller blocks. Its hard
top-boundary period equals the normalized period already computed for the
coupled eight-master example. Therefore this system needs its own differential
transport but introduces no new hard period.

These examples show why master count, differential-system count, scalar
coefficient count, boundary-integral count, and new-period count cannot be
identified.

## 7. Recommended agent workflow

Each boundary task assigned to an agent should contain the following exact
data:

1. the normalized cut integral to be evaluated;
2. the endpoint and direction of approach;
3. the required order in $\epsilon$;
4. the allowed physical region and branch;
5. the local scaling modes expected from the differential equation;
6. lower-integral data already known;
7. the scalar coefficients the integral must determine;
8. an independent numerical check point and its required precision.

The agent must return an analytic Laurent expansion, not only numerical
values. SubTropica is the analytic evaluator when it resolves the integral.
AMFlow is an independent numerical check and does not replace the analytic
answer.

At NLO the queue is exactly:

| Job | Integral | Required output | Difficulty |
|---:|---|---|---|
| 0 | Cut-bubble volume $B(\epsilon)$ | $2\pi/(1-2\epsilon)$ | Elementary; may be preloaded |
| 1 | Generic top endpoint | $T(0,\epsilon)=-\pi/(\epsilon\Lambda_1\Lambda_2)$ | The only nontrivial NLO boundary task |

There must not be five additional jobs for the five physical top instances.

## 8. Conclusions

The exact NLO answer to the planning question is:

$$
\boxed{
6\ \hbox{masters require 2 analytic inputs in total, but only 1 nontrivial
boundary integration.}
}
$$

The two maximal nontrivial denominator geometries are a separate bookkeeping
result and do not increase that boundary count.

At NNLO, 342 masters have been reduced exactly to 17 maximal nontrivial
denominator geometries, but the number of distinct boundary integrations is
not yet established. Differential-equation closure and normalized-period
identification must be completed before assigning the remaining work to
agents one integral at a time.

## Follow-up question

Please revise the scientific structure of our boundary-integral report. Use
concrete terms only: positive-denominator set, inclusion of denominator sets,
maximal denominator class, derivative-closed DE system, scalar endpoint
coefficient, boundary integral, and new analytic period. Do not use the word
normally used for the set of active propagators.

The exact NLO facts are:

1. Kira returns 6 masters: one cut bubble and five top instances.
2. Momentum relabeling gives 3 positive-denominator-set classes, of which 2
   are maximal and nontrivial.
3. The exact evaluator makes only 2 SubTropica calls. They determine
   B(epsilon)=2 Pi/(1-2 epsilon) and one generic top function
   T(z)=-Pi Hypergeometric2F1[1,1,1-epsilon,z]/
        (epsilon Lambda1 Lambda2).
4. The generic top endpoint is
   lim_{z->0+}[(Lambda1 Lambda2/Pi)T(z)+1/epsilon]=0.
5. All five physical top masters follow by substituting five cross ratios and
   scale pairs into this one T.

Therefore NLO needs exactly 2 analytic inputs total, or exactly 1 nontrivial
boundary integration if the elementary bubble is preloaded. Explain why this
differs from the count 2 of maximal denominator geometries.

The exact NNLO bookkeeping is 342 masters -> 130 powered classes -> 82
positive-denominator-set classes -> 17 maximal nontrivial denominator
classes. State clearly that 17 is not yet the number of SubTropica boundary
jobs. Explain the required sequence: construct exact DEs and merge derivative
mixing; determine local modes/Jordan blocks; impose regularity and lower
integrals; identify explicit boundary integrals; quotient changes of variables
and shared normalized periods.

Use the solved examples to distinguish counts: the 8-master coupled example
has modes x^0,x^-epsilon,x^-2epsilon and one new hard period; the 4-master
doubled-cut example uses one regulated two-region integral to determine two
scalar coefficients; the 5-master factorized example reuses the first hard
period and adds no new one.

Return a concise but self-contained replacement narrative suitable for a
physics PDF. Include the NLO derivation and an agent-work-queue conclusion.
Do not invent references or internal implementation claims.

## Pro response

Counting Independent Analytic Boundary Integrations in Reverse Unitarity
Executive answer

The number of Kira master integrals is not the number of analytic boundary integrations that must be evaluated independently.

For the complete NLO real-emission reduction considered here, the exact counts are:

Object being counted	Exact number
Kira master integrals	6
Positive-denominator classes after exact momentum relabeling	3
Maximal nontrivial denominator classes	2
Analytic inputs needed to determine all 6 masters	2
Genuinely nontrivial boundary integrations, when the elementary phase-space normalization is treated as known	1

The two analytic inputs are:

B(ϵ)=
1−2ϵ
2π
	​

,

the elementary cut-bubble normalization, and the normalized endpoint of one generic top function,

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

2
	​

F
1
	​

(1,1;1−ϵ;z).

All five non-bubble NLO masters are obtained by substituting different physical cross ratios and scale pairs into this same function. They do not require five separate integrations.

Thus the operational NLO conclusion is

6 masters require 2 analytic inputs in total,or only 1 genuinely nontrivial SubTropica boundary job
	​


when the elementary bubble normalization is supplied as known.

For the corrected NNLO double-real reduction, the exact denominator bookkeeping gives

342 masters⟶130 powered classes⟶82 positive-denominator classes⟶17 maximal nontrivial denominator classes.

The number 17 is not yet the number of NNLO boundary integrations. It counts maximal denominator geometries before differential-equation closure, local boundary analysis, identification of equivalent parametric densities, and comparison of normalized analytic periods.

1. The integrals being classified

Let

s=(k
a
	​

+k
b
	​

)
2
,t=(k
a
	​

−k
c
	​

)
2
,u=(k
b
	​

−k
c
	​

)
2
,

and define the unobserved recoil momentum

q=k
a
	​

+k
b
	​

−k
c
	​

,q
2
=s+t+u.

A reverse-unitarity integral has the form

I
T,ν
	​

(s,t,u;ϵ)=∫
r=1
∏
L
	​

iπ
D/2
d
D
ℓ
r
	​

	​

j=1
∏
N
T
	​

	​

D
T,j
−ν
j
	​

	​

,D=4−2ϵ.

The topology label T specifies:

the ordered denominator list;

the loop and phase-space integration momenta;

the external momenta;

the kinematic relations;

the positions and positive-energy orientations of the physical cuts.

The exponent vector

ν=(ν
1
	​

,…,ν
N
T
	​

	​

)

specifies one integral in that topology. Kira represents it as

GLI[T,ν].
1.1 Positive-denominator set

For a master integral I
T,ν
	​

, define

D
+
	​

(I
T,ν
	​

)={D
T,j
	​

:ν
j
	​

>0},

with the cut identity and cut orientation attached to every physical cut element.

This set records which denominator hypersurfaces are present, but not their positive powers. Consequently,

D
−1
andD
−2

belong to the same positive-denominator set, although they are different integrals. A negative index represents a numerator or irreducible scalar-product insertion and is not included.

No comparison is valid if it:

deletes a physical cut;

maps a cut to an ordinary propagator;

reverses the positive-energy direction of a cut;

changes the declared physical branch without an explicit continuation map.

2. Distinct notions that must not be conflated

Several different equivalence and counting problems occur between diagrams and analytic boundary data.

2.1 Equality of diagrams

Two diagrams are equal only when their:

graph structure;

field assignments;

external ordering;

position on the amplitude or conjugate-amplitude side

all agree.

Distinct diagrams can nevertheless generate the same integral topology after color, spin, polarization, and numerator algebra. Diagram counting therefore determines neither the number of masters nor the number of boundary integrations.

2.2 Equality after an affine loop-momentum transformation

Two integral topologies are equivalent when an invertible affine transformation

ℓ
r
′
	​

=
s
∑
	​

A
rs
	​

ℓ
s
	​

+
i
∑
	​

B
ri
	​

p
i
	​

,detA=±1,

together with an allowed external-momentum relabeling, maps the complete denominator list of one topology into that of the other while preserving every physical cut.

At one loop, for example,

ℓ⟼q−ℓ

interchanges the two cut momenta ℓ and q−ℓ. Integrals related by this transformation are not independent topology problems.

2.3 Equality of powered master integrals

Two masters are power-equivalent if a certified momentum transformation maps:

every ordinary denominator;

every physical cut;

every positive and negative exponent

to the corresponding data of the second master.

A doubled ordinary propagator remains doubled, and a differentiated cut remains differentiated. This relation answers:

Are these exactly the same integral, including all denominator powers?

For the NNLO double-real calculation, the relabeling group includes all permutations of the three positive-energy cut momenta. The geometric hard-leg relabelings act on

{k
a
	​

,k
b
	​

,−k
c
	​

}.

A hard-leg crossing identifies denominator geometry only. Equality of physical values additionally requires the corresponding analytic-continuation and branch map.

2.4 Equality of positive-denominator sets

To classify denominator geometry, replace every positive exponent by one and repeat the full canonicalization over all allowed momentum relabelings.

Two masters belong to the same class at this level if they contain the same cut and ordinary denominator hypersurfaces, even when their powers differ.

The order of operations is essential:

remove the positive powers;

reapply every allowed relabeling;

choose the canonical denominator set.

It is generally incorrect to remove powers only from a powered representative chosen earlier. The relabeling that minimizes a powered description need not minimize the corresponding unpowered denominator description.

2.5 Set inclusion between denominator classes

Let [A] and [B] denote equivalence classes of positive-denominator sets. Define

[A]⪯[B]

when there exists an allowed relabeling g such that

g(A)⊆B.

This is a partial order, not an equivalence relation.

Strict inclusion,

[A]≺[B],

means that [A]⪯[B] but the two classes are not equivalent.

A class is maximal when it is not strictly included in any other class in the master inventory. For a maximal class M, define its downward closure by

↓M={A:[A]⪯[M]}.

This contains the maximal class and all lower-denominator classes contained in it. Two different maximal classes can contain the same lower-denominator class, so their downward closures may overlap.

2.6 Closure under kinematic differentiation and IBP reduction

A maximal denominator class does not automatically define a self-contained differential-equation problem.

Let

V
M
	​

=span{I
j
	​

:D
+
	​

(I
j
	​

)∈↓M}.

Choose independent kinematic coordinates ξ
α
	​

, for example two dimensionless ratios together with an overall scale relation. The class M defines a closed differential-equation family only if

∂
ξ
α
	​

	​

V
M
	​

⊆V
M
	​


for every independent ξ
α
	​

, after exact IBP reduction.

If a derivative of a master in V
M
	​

 produces a top-level master belonging to another incomparable maximal denominator class, the two classes must be included in one larger differential system.

Shared lower-denominator masters do not by themselves force such a merger. Conversely, one maximal denominator class can split into several independent differential-equation blocks.

2.7 Equality of analytic boundary data

Even two closed differential systems can require the same normalized analytic period at a boundary.

Such an identification is valid only after fixing:

integral normalization;

cut identities and positive-energy directions;

physical kinematic chamber;

causal prescription;

endpoint and direction of approach;

analytic branch.

The following counts are therefore distinct:

N
master
	​

,N
maximal denominator
	​

,N
DE system
	​

,N
scalar boundary coefficient
	​

,N
boundary integration
	​

,N
new period
	​

.

Their meanings are:

Count	Meaning
N
master
	​

	Number of individual Kira basis integrals
N
maximal denominator
	​

	Number of maximal nontrivial denominator geometries
N
DE system
	​

	Number of closed coupled differential systems
N
scalar boundary coefficient
	​

	Number of unfixed Frobenius or Levelt coefficients after physical constraints
N
boundary integration
	​

	Number of distinct direct analytic integrations needed to determine those coefficients
N
new period
	​

	Number of normalized analytic quantities not already known from another system

Only N
boundary integration
	​

 directly counts independent SubTropica jobs.

One boundary integration may determine several scalar coefficients. Conversely, one differential system may require several distinct boundary integrations. Two different systems may also reuse the same period.

3. Exact classification of denominator geometries

The exact denominator classification proceeds from the stored Kira master list and the corresponding topology definitions.

Read each

GLI[T,ν],

the ordered denominator list of T, and the recorded cut positions, cut momenta, and cut directions.

Convert every denominator with positive exponent into its exact scalar-product polynomial.

Impose the massless external relations and the on-shell equations associated with the physical cuts.

Express every denominator in an independent scalar-product coordinate basis.

For geometric comparison only, remove an overall kinematics-dependent factor when that factor has been certified nonzero in the declared physical chamber. This does not remove the factor from the actual integral normalization.

Apply every certified cut-momentum and hard-leg relabeling.

Canonically order the transformed denominators, cut data, and powers. The lexicographically minimal exact representation defines the powered master class.

Replace every positive exponent by one and repeat the full relabeling and canonicalization. This defines the positive-denominator class.

For every pair of positive-denominator classes, test exact set inclusion under all allowed relabelings.

Remove the class containing only the physical cuts and identify the maximal remaining classes.

The resulting maximal-class count is

N
maximal denominator
	​

=∣Max(C∖{C
cut only
	​

})∣,

where C is the finite set of positive-denominator classes.

This procedure determines denominator geometry only. It does not construct a differential equation or evaluate any boundary integral.

4. NLO worked example
4.1 Cut kinematics

At NLO there is one independent emitted momentum k
e
	​

 and one dependent cut momentum

k
d
	​

=q−k
e
	​

.

The two physical cut denominators are

C
e
	​

=k
e
2
	​

,C
d
	​

=(q−k
e
	​

)
2
.

Introduce

a=2k
a
	​

⋅k
e
	​

,b=2k
b
	​

⋅k
e
	​

,c=2k
c
	​

⋅k
e
	​

.

On the two-cut surface,

C
d
	​

=0.

Since

q=k
a
	​

+k
b
	​

−k
c
	​

,q
2
=s+t+u,

the cut equation gives

c=a+b−(s+t+u).

Representative ordinary denominators are

D
a
	​

=(k
a
	​

−k
e
	​

)
2
=−a,
D
s
	​

=(k
a
	​

+k
b
	​

−k
e
	​

)
2
=s−a−b,

and

D
c
	​

=(k
c
	​

+k
e
	​

)
2
=c=a+b−(s+t+u).
4.2 Three positive-denominator classes

The six Kira masters occupy three exact positive-denominator classes:

A
0
	​

={C
e
	​

,C
d
	​

},
A
1
	​

={C
e
	​

,C
d
	​

,D
a
	​

,D
s
	​

},
A
2
	​

={C
e
	​

,C
d
	​

,D
a
	​

,D
c
	​

}.

Their master multiplicities are:

Denominator class	Number of masters	Interpretation
A
0
	​

	1	Elementary two-body cut volume
A
1
	​

	2	First maximal nontrivial denominator geometry
A
2
	​

	3	Second maximal nontrivial denominator geometry

The only strict inclusions are

A
0
	​

⊂A
1
	​

,A
0
	​

⊂A
2
	​

.

Neither A
1
	​

 nor A
2
	​

 contains the other. The geometric classification is therefore

6 masters⟶3 positive-denominator classes⟶2 maximal nontrivial denominator classes.

This does not imply two distinct nontrivial boundary integrations.

4.3 The two direct NLO analytic integrations

The exact NLO evaluator invokes SubTropica twice.

Elementary cut bubble

The first direct integration is reduced to the density

f
B
	​

(r,ϵ)=r
−ϵ
(1+r)
−2+2ϵ
,0<r<∞.

With the evaluator’s exact normalization, it gives

B(ϵ)=
1−2ϵ
2π
	​

.

This is the elementary cut-only phase-space normalization.

Generic top function

The second direct integration is reduced to

f
T
	​

(r,z,ϵ)=
1+(1−z)r
(1+r)
ϵ
	​

,0<z<1.

With the evaluator’s normalization, the result is

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

2
	​

F
1
	​

(1,1;1−ϵ;z).

For the real branch 0<z<1,

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)=
Λ
1
	​

Λ
2
	​

π
	​

[
	​

−
ϵ(1−z)
1
	​

+
1−z
ln(1−z)
	​

+ϵ
1−z
Li
2
	​

(
z−1
z
	​

)
	​

+ϵ
2
1−z
Li
3
	​

(
z−1
z
	​

)
	​

+O(ϵ
3
)].
	​


The argument

z−1
z
	​


is negative for 0<z<1, so the displayed logarithms and polylogarithms lie on the common real branch selected by the physical chamber.

4.4 Differential equation and endpoint normalization

Apart from its constant scale factor, the generic top function satisfies the hypergeometric equation

z(1−z)T
′′
(z)+(1−ϵ−3z)T
′
(z)−T(z)=0.

At z=0, the two local Frobenius behaviors are associated with exponents

0andϵ.

The physical solution is the branch analytic in z at z=0. Its remaining normalization is fixed by

z→0
+
lim
	​

[
π
Λ
1
	​

Λ
2
	​

	​

T(z,ϵ;Λ
1
	​

,Λ
2
	​

)+
ϵ
1
	​

]=0
	​

.

Equivalently,

T(0,ϵ;Λ
1
	​

,Λ
2
	​

)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

.

The combination of:

the analytic Frobenius branch at z=0; and

this one normalization

uniquely selects the physical generic top solution. A new boundary calculation is not required for each kinematic instance.

The current direct evaluator computes the full generic one-variable density. In a differential-equation workflow, the independently required information from that integration is the normalized endpoint above.

4.5 Five physical top instances from one generic function

The five non-bubble masters are obtained by substituting the following cross ratios and scale pairs into the same function T:

Instance	Cross ratio z
i
	​

	Scale pair (Λ
i1
	​

,Λ
i2
	​

)
ac	
(s+t)(t+u)
su
	​

	(−
2
s+t
	​

,−
2
t+u
	​

)
ab	
(s+t)(s+u)
tu
	​

	(−
2
s+t
	​

,−
2
s+u
	​

)
abb	
(s+t)(s+u)
s(s+t+u)
	​

	(−
2
s+t
	​

,−
2
s+u
	​

)
cb	
(s+u)(t+u)
st
	​

	(−
2
t+u
	​

,−
2
s+u
	​

)
cbb	
(s+u)(t+u)
u(s+t+u)
	​

	(−
2
t+u
	​

,−
2
s+u
	​

)

In the declared physical chamber used by the calculation,

0<z
i
	​

<1

for all five rows. They therefore use the same physical branch of T.

The five rows are kinematic substitutions, not five new integrations.

4.6 Exact NLO analytic workload

Two counting conventions are useful.

Complete analytic-input count

Include the elementary cut volume:

N
analytic input
NLO
	​

=2.

The two inputs are:

B(ϵ);

the normalized endpoint of T.

Genuinely nontrivial boundary-task count

Treat the elementary cut volume as known:

N
nontrivial boundary job
NLO
	​

=1.

The only nontrivial job is the generic top endpoint.

Quantity	Exact count	Meaning
Kira masters	6	One bubble and five physical top instances
Positive-denominator classes	3	Exact denominator geometries after relabeling
Maximal nontrivial denominator classes	2	Geometric classification only
Analytic inputs needed for all masters	2	Bubble normalization and generic top endpoint
Genuinely nontrivial SubTropica boundary jobs	1	Generic top endpoint, with bubble preloaded
Physical top instances generated from that input	5	Kinematic substitutions

The correct operational statement is therefore

6 NLO masters⇒2 analytic inputs in total⇒1 genuinely nontrivial boundary job.
	​


There must not be five additional jobs for the five top instances.

5. NNLO double-real classification
5.1 Cut kinematics

At NNLO double real there are two independent emitted momenta k
e
	​

,k
f
	​

 and one dependent cut momentum

k
g
	​

=q−k
e
	​

−k
f
	​

.

The three physical cuts are

C
e
	​

=k
e
2
	​

,C
f
	​

=k
f
2
	​

,C
g
	​

=(q−k
e
	​

−k
f
	​

)
2
.

All six permutations of

{k
e
	​

,k
f
	​

,k
g
	​

}

are included when comparing denominator geometries. The geometric hard-leg transformations act on

{k
a
	​

,k
b
	​

,−k
c
	​

}.

The corresponding physical crossing and branch continuation are retained as a separate requirement when analytic values are compared.

5.2 Exact NNLO bookkeeping

The corrected NNLO Kira basis gives:

Object being counted	Exact number	Definition
Kira masters	342	Individual stored GLI basis elements
Powered classes	130	All denominator and cut powers retained
Positive-denominator classes	82	Positive powers replaced by one, followed by complete recanonicalization
Cut-only class	1	Elementary three-body phase-space normalization
Nontrivial denominator classes	81	At least one ordinary propagator is present
Maximal nontrivial denominator classes	17	Not strictly included in another denominator class

The 130 powered classes account for all 342 masters:

14×1+65×2+22×3+21×4+8×6=342.

Their cut-power patterns are

92 classes with (1,1,1),38 classes with (1,1,2).

The location of the doubled cut is identified under permutation of the three cut momenta, while the fact that one cut is doubled remains part of the powered classification.

Among the 17 maximal nontrivial denominator classes:

Number of ordinary denominators, in addition to the three cuts	Number of maximal classes
6	4
5	12
4	1

Thus the exact geometric inventory is

342⟶130⟶82⟶17.
	​


Every one of the 81 nontrivial denominator classes is contained in at least one of the 17 maximal classes. Their downward closures overlap, so master counts associated with different maximal classes must not be added.

5.3 Why the number 17 is not the NNLO boundary workload

The NLO result already disproves the rule

one maximal denominator class=one boundary integration.

At NLO, two maximal nontrivial denominator classes lead to one generic nontrivial top endpoint.

Before an NNLO SubTropica queue can be constructed, the following steps remain.

Construct the exact differential equations.
For each maximal denominator class, include all masters in its downward closure and differentiate with respect to a complete set of independent kinematic variables.

Reduce every derivative by IBP.
Determine whether the resulting equations stay within that downward closure.

Merge classes that are dynamically coupled.
If derivatives connect top-level masters from two incomparable maximal classes, those classes belong to one larger differential system.

Decompose each closed system into coupled blocks.
A single denominator class can contain several independent differential-equation blocks.

Analyze the chosen boundary.
Determine the Frobenius or Levelt exponents, resonant blocks, logarithmic modes, and allowed physical branches.

Impose physical constraints.
Apply:

regularity;

expansion-by-regions information;

corner behavior;

symmetry;

scaleless limits;

lower-integral data;

known normalizations.

Count the remaining scalar boundary coefficients.
This count can be larger or smaller than the number of maximal denominator classes.

Choose explicit analytic integrals that determine those coefficients.
One explicit integration can determine several scalar coefficients.

Identify equivalent generic densities.
Distinct differential systems or denominator classes can reduce to the same parametric integral after a change of variables or a certified crossing.

Identify reused normalized periods.
A boundary quantity already computed for one system need not be reevaluated for another system.

Assign one SubTropica job to each remaining distinct analytic representation.

Only after these steps is the exact NNLO boundary-integration count known.

The number 17 should therefore be described as

17 maximal nontrivial denominator classes,
	​


not as 17 differential systems, 17 scalar constants, or 17 SubTropica jobs.

6. Lessons from three completed NNLO examples

For brevity, the stored record labels 83bb, f228, and d099 are used to distinguish three completed examples. These labels are not physical family names.

Their measured analytic difficulty is

83bb>f228>d099.

This is an empirical ordering based on differential coupling, local boundary structure, and genuinely new analytic information. It is not determined solely by denominator count.

6.1 Coupled eight-master example

The example labeled 83bb contains eight masters and a genuinely coupled two-master top block. Its local boundary analysis contains the modes

x
0
,x
−ϵ
,x
−2ϵ
.

After all lower-integral data are imposed, one genuinely new top-corner period remains.

Determining it requires a nonfactorized corner integration with explicit control of:

endpoint scaling;

physical branches;

the coupling of the top masters;

matching to the lower sectors.

This is the most difficult of the three completed examples.

6.2 Doubled-cut example with a repeated Jordan block

The example labeled f228 contains four masters and a doubled physical cut. Its boundary residue has a repeated Jordan block.

One η-regulated two-region boundary integration determines two independent nonuniform asymptotic coefficients.

Therefore,

1 boundary integration

⇒1 scalar boundary coefficient.
	​


One explicit integral can provide several pieces of boundary information.

6.3 Factorized example with a reused period

The example labeled d099 contains five masters and factorizes into smaller blocks.

Its normalized hard top-boundary period is the same period already required by the coupled eight-master example. Once that period is known, d099:

still requires its own differential transport;

still requires lower-integral bookkeeping;

introduces no additional hard period.

Therefore,

1 new differential system

⇒1 new analytic period.
	​


Together, the three examples demonstrate that the following quantities must remain distinct:

number of masters;

number of maximal denominator classes;

number of closed differential systems;

number of scalar boundary coefficients;

number of explicit boundary integrations;

number of genuinely new periods.

7. Physical crossing and branch qualification

The denominator classification identifies geometric relations. A hard-leg crossing can move the invariants between different physical chambers.

Consequently, two crossing-related denominator classes may have the same geometric form while their physical values differ by analytic continuation.

Before identifying their boundary data, one must specify:

the starting and final kinematic chambers;

the causal i0 prescription;

the path of analytic continuation;

the branches of logarithms, powers, polylogarithms, or more general functions;

the cut orientation.

Thus the count 17 is exact for the declared geometric quotient. If crossing-related physical chambers are kept distinct until their branch maps are proven, the number of separately tabulated physical expressions may be larger. This does not alter the denominator-class count.

8. Recommended SubTropica agent workflow

Each analytic boundary task assigned to an agent should contain:

the exact normalized cut integral to be evaluated;

the boundary point or corner;

the direction of approach;

the required Laurent order in ϵ;

the physical kinematic chamber;

the causal and branch conventions;

the local scaling modes predicted by the differential equation;

all lower-integral data already known;

the scalar boundary coefficients that the integration must determine;

an independent numerical check point and required precision.

The required output is an exact analytic Laurent expansion. A numerical value alone is not a completed task.

SubTropica is used when it produces the analytic integral. AMFlow provides an independent numerical check and does not replace the analytic result.

NLO queue

The exact NLO queue is:

Job	Analytic input	Required result	Status
0	Elementary cut-bubble density	B(ϵ)=
1−2ϵ
2π
	​

	Elementary; may be preloaded
1	Generic top endpoint	T(0,ϵ)=−
ϵΛ
1
	​

Λ
2
	​

π
	​

	The only genuinely nontrivial NLO boundary task

There are no additional jobs for the five physical top instances. They are obtained by kinematic substitution into the same generic function.

9. Conclusions

The NLO calculation establishes three distinct exact facts:

N
master
NLO
	​

=6,
N
maximal denominator
NLO
	​

=2,

and

N
analytic input
NLO
	​

=2.

When the elementary bubble is supplied as known,

N
nontrivial boundary job
NLO
	​

=1.

The operational conclusion is

\boxed{ 6\ \text{masters require 2 analytic inputs in total: one elementary bubble and one generic top endpoint. }

Equivalently,

with the bubble preloaded, NLO requires exactly one genuinely nontrivial SubTropica boundary integration.
	​


All five physical top masters follow from the same generic top function by kinematic substitution.

For NNLO double real, the exact result currently established is

342 masters⟶130 powered classes⟶82 positive-denominator classes⟶17 maximal nontrivial denominator classes.
	​


The number of distinct NNLO boundary integrations is not yet established. It requires:

exact differential-equation closure;

local Frobenius or Levelt analysis;

physical boundary constraints;

identification of equivalent parametric densities;

comparison of normalized boundary periods.

Accordingly, the number 17 must remain a geometric denominator-class count and must not yet be used as the size of the NNLO SubTropica agent queue.
