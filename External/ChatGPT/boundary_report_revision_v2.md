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
