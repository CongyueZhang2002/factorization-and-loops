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
