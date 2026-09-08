# Completing finite DE solutions up to constants

Conversation: https://chatgpt.com/c/6a9c64ec-3cc4-83e8-b40c-9b568241fd3b

## Question

Please challenge the remaining mathematical gaps in solving multivariate Feynman-integral differential equations up to kinematics-independent constants, and propose a concrete general solution strategy. Do not confuse this with physically fixing constants. User wants general NNLO code, not special cases or a lazy generator.

Since our previous discussion I implemented finite explicit nested quadratures for dJ=A J, I=T J, choosing an ordinary fixed point X0 and C=I(X0,eps). It computes every requested U coefficient in I=U C and both T(X), T^-1(X0) epsilon convolutions. Each stored F_i(s)=integral_0^s g_i(t) dt has an explicit finite integrand in known kernels and earlier F_j(t), j<i. Fixed arithmetic expressions share repeated subexpressions. No word enumeration or DE solve is needed on reading. Exact flatness and local fresh-reader checks pass for CF269/48 all columns, up to eps^4 (transformed order7), 3.5/14.3 MB text, 0.27/0.80 MB gzip.

Current restriction: optionally transform by a supplied known eps-independent H, then require B=H^-1 A H-H^-1dH regular in eps with B0 strictly lower triangular. I think this is too restrictive: Laurent poles confined to acyclic interblock couplings can terminate after assigning epsilon shifts to blocks/rows, while cycles need positive total epsilon weight. Can one generalize to a weighted dependency graph, or equivalently find a diagonal eps shearing to make all entries nonnegative and zero-order graph acyclic? What are the exact necessary/sufficient conditions for that finite nested-integral construction, and a robust general algorithm? Explain counterexamples where this does not suffice.

We also need to handle truly nontrivial diagonal A0 blocks without an unspecified H. Is there a useful general automatic route for algebraic scalar blocks and 2x2 Picard-Fuchs blocks, using rational gauge solutions or identified elliptic periods? Can finite definite integrals solve more of this without disguising an infinite Peano series or unknown fundamental solution as an answer? Give equations and practical implementation steps.

CF303: its old path-operator packaging said full fixed-rho tangential connection/exact coefficients missing. I am rebuilding its original two-variable rational DE directly from preserved Kira/reduction inputs rather than relying on those old operators. There may be no genuine elliptic A0 obstruction after appropriate blocks/gauges; earlier classifications may conflate an algebraic elliptic integration kernel with an elliptic homogeneous system. Please specifically challenge that distinction.

Finally, what validation is sufficient beyond checking first derivatives at X0? I want coefficient-level identities against original DE, and an independent finite-integral numerical evaluation (not a DE solver used as reader). We should accept finite nested quadratures but not declare all NNLO orders complete using unproved lower bounds.

Please give an actionable critical mathematical review, no generic plan or invented terminology. GitHub base code is https://github.com/CongyueZhang2002/factorization-and-loops but current edits are local; use this message as implementation description, not claims that GitHub has the new code.


## Pro response

Your weighted-graph extension is correct, with an important qualification: it gives a necessary-and-sufficient criterion for diagonal ϵ-shearing followed by an acyclic coefficient construction, not for every possible finite-quadrature solution. Non-diagonal gauges, matrix cancellations, and explicitly solvable homogeneous blocks can handle systems that fail that graph test.

Taking your implementation description as given, the CF269/48 exports address the earlier representation objection: they contain the requested finite expressions, rather than instructions for constructing them. The remaining mathematical issues are admission of more general connections, construction of homogeneous solutions, justified Laurent-order bounds, and verification throughout a multivariate domain.

1. The exact weighted-graph criterion

Work over a differential field K of explicitly specified functions of X, independent of ϵ. Initially, K can be a rational or algebraic function field. Assume the connection entries are meromorphic in ϵ, with finite integer valuations:

dJ=A(X,ϵ)J,A=
μ=1
∑
d
	​

A
μ
	​

dX
μ
	​

.

For each nonzero matrix entry, define

w
ij
	​

=
μ
min
	​

val
ϵ
	​

(A
μ,ij
	​

),

and draw the directed edge j→i with weight w
ij
	​

.

The minimum must be taken over all independent-variable equations, at generic symbolic kinematics. An accidental zero at X
0
	​

, or on a special slice, must not remove an edge.

Set

J=SZ,S=diag(ϵ
s
1
	​

,…,ϵ
s
r
	​

),

where s
i
	​

∈Z. Since S is kinematics-independent,

B=S
−1
AS,val
ϵ
	​

B
ij
	​

=w
ij
	​

+s
j
	​

−s
i
	​

.
Theorem

The following conditions are equivalent:

Every directed cycle in the weighted graph has strictly positive total weight.

There are integer shifts s
i
	​

 such that every transformed entry has nonnegative valuation and the graph of zero-valuation entries is acyclic.

After diagonal ϵ-shearing and one common permutation of rows and columns, B is regular in ϵ and B
[0]
 is strictly lower triangular.

This includes self-loops: a diagonal entry of valuation zero fails the strict criterion.

Proof. The shifts telescope around every cycle, so cycle weights are invariant. Nonnegative transformed weights with no zero-weight cycle imply strictly positive cycle weights.

Conversely, strictly positive cycle weights imply that there are no negative cycles. Introduce a source connected to every vertex by a zero-weight edge, and let s
i
	​

 be shortest-path distances. Then

s
i
	​

≤s
j
	​

+w
ij
	​

,

so every transformed weight is nonnegative. A cycle consisting of zero-weight edges would have original total weight zero, contradicting the hypothesis. Topologically ordering the zero graph gives strict triangularity.

This is a complete proof for the proposed diagonal-shearing construction; no conjecture about Feynman integrals is needed.

A practical algorithm

There is no need to enumerate cycles.

Compute exact generic epsilon valuations in every coordinate equation.
Run Bellman–Ford with a zero-edge source connected to all vertices.

If a negative cycle exists:
    Return the actual cycle as an obstruction to diagonal regularization.

Otherwise:
    Use shortest-path distances as epsilon shifts.
    Form the zero-weight graph.
    Compute its strongly connected components.

If every component is a singleton without a self-loop:
    Topologically order it and construct finite coefficient integrals.
Otherwise:
    Solve the zero-order diagonal blocks, as described below.

The graph work is inexpensive compared with symbolic manipulation of the connection. The expensive requirement is obtaining correct valuations and exact zero decisions in the coefficient field.

For acyclic interblock couplings, negative valuations are harmless once the diagonal blocks are handled: a cycle cannot accumulate those poles. Your proposed relaxation is therefore substantive, not merely a different presentation of the existing regularity requirement.

For example,

A=(
0
ϵ
2
	​

ϵ
−1
0
	​

)dx

has cycle weight 1. With S=diag(1,ϵ),

S
−1
AS=(
0
ϵ
	​

1
0
	​

)dx.

The zero-order edge is acyclic, despite the original pole.

2. Why this gives a finite expression at every fixed order

After shearing and ordering, write

B=
k≥0
∑
	​

ϵ
k
B
[k]
,B
[0]
 strictly lower triangular.

Pull back to a specified path γ
X
	​

(s), starting at X
0
	​

, and denote the resulting matrices by b
[k]
(s;X). Let

V(s,ϵ)=
n≥0
∑
	​

ϵ
n
V
[n]
(s),V(0,ϵ)=1.

Writing V
i
[n]
	​

 for row i, the construction is

V
i
[n]
	​

(s)=δ
n0
	​

e
i
T
	​

+∫
0
s
	​

[
j<i
∑
	​

b
ij
[0]
	​

(t)V
j
[n]
	​

(t)+
k=1
∑
n
	​

j
∑
	​

b
ij
[k]
	​

(t)V
j
[n−k]
	​

(t)]dt.
	​


Order the construction first by n, then by the topological row order. Every integrand refers only to already-constructed functions.

There is also a useful explicit termination bound. At order n, there can be at most n positive-order insertions. Between them, at most r−1 consecutive zero-order insertions survive. Thus a sufficient upper bound on nesting depth is

L
max
	​

(n)≤n+(n+1)(r−1)=r(n+1)−1.

A shorter longest path in the zero graph sharpens this bound.

This proves finiteness; it does not require expanding words. Your shared finite-integral representation is a natural implementation of this recurrence. The recurrence belongs in the constructor and proof; the file contains its already-instantiated finite outputs.

Where the graph test is not necessary

Two counterexamples prevent overinterpreting its failure.

A negative cycle can be a basis artifact. Let

N=(
1
−1
	​

1
−1
	​

),N
2
=0,A=ϵ
−1
Ndx.

The entry graph has negative self-loops and negative cycles, but

U(x,x
0
	​

;ϵ)=1+
ϵ
x−x
0
	​

	​

N

is already a finite exact answer. A constant similarity transformation makes N strictly triangular.

A genuine parameter singularity is different.

df=ϵ
−1
fdx⟹f(x)=e
(x−x
0
	​

)/ϵ
f(x
0
	​

).

This does not have a Laurent expansion with a finite lower bound. No diagonal shearing can repair that fact. A general solver must distinguish this from the nilpotent example, rather than interpreting every negative cycle as either harmless or fatal.

Also, pointwise nilpotence is insufficient. For instance,

N(x)=(
x
1
	​

−x
2
−x
	​

)

satisfies N(x)
2
=0, but products N(x
1
	​

)N(x
2
	​

)⋯ need not vanish. Finite truncation requires a common filtration, not a nilpotence test at each point.

3. The more general criterion: regularize, then solve the leading blocks

Strict positivity of every cycle is stronger than necessary once explicit homogeneous functions are allowed.

If every cycle has nonnegative total weight, shortest-path shearing makes B regular in ϵ. Its zero-order graph may still have nontrivial strongly connected components. Order those components so that

B
[0]
=
	​

D
1
	​

∗
⋮
	​

0
D
2
	​

⋮
	​

⋯
⋯
⋱
	​

	​

.

Because B is regular and flat, B
[0]
 is flat. Each diagonal block D
b
	​

 is therefore a flat connection.

Suppose an explicit, normalized fundamental matrix has been constructed for each:

dH
b
	​

=D
b
	​

H
b
	​

,H
b
	​

(X
0
	​

)=1.

Then with H=diag(H
b
	​

),

B
=H
−1
BH−H
−1
dH

has zero diagonal blocks at order zero and only acyclic zero-order interblock couplings. The finite construction above applies.

The resulting general statement is:

A finite meromorphic gauge to an ϵ-regular connection, together with explicit fundamental matrices for its leading diagonal blocks, suffices to construct every fixed Laurent coefficient by finitely many nested quadratures.

No global dlog form or fully ϵ-factorized connection is required.

The issue is making the hypotheses constructive. “Let H
b
	​

 solve the homogeneous system” remains unacceptable as an output. The following procedures actually construct it.

3.1 First try a common constant triangularization

Before solving differential equations, test whether a complicated-looking leading block is simultaneously strictly triangularizable by a constant matrix.

Express all coordinate components as

D
μ
	​

(X)=
α
∑
	​

f
μα
	​

(X)N
α
	​

,

with constant matrices N
α
	​

. For rational entries, clearing denominators and collecting monomials supplies a finite such set.

Construct

W
0
	​

={0},W
k+1
	​

={v:N
α
	​

v∈W
k
	​

 for every α}.

If W
r
	​

=K
const
r
	​

, bases adapted to this flag simultaneously strictly triangularize the matrices.

This is an exact linear-algebra test. It detects cancellations hidden by the entry graph, including the constant nilpotent counterexample. Apply the same idea to leading negative-order matrices before escalating to more complicated parameter regularization.

For genuinely non-diagonal parameter regularization, the invariant object is an ϵ-adic lattice stable under all operators ∂
μ
	​

−A
μ
	​

. Diagonal shearing searches only lattices generated by ϵ
s
i
	​

e
i
	​

. More general gauges search a larger class. Moser-type algorithms exist for parameter-rank reduction of singularly perturbed ordinary differential systems, but applying one directionally does not establish simultaneous multivariate regularization; any resulting finite gauge must be checked in every coordinate equation. 
arXiv

3.2 Scalar blocks are broader than algebraic solutions

For a scalar leading block,

dh=a(X)h,

flatness gives da=0. On the declared simply connected patch,

h(X)=exp(∫
γ
X
	​

	​

a).
	​


That is one explicit quadrature and an elementary exponential—not an unknown fundamental solution or an infinite Peano expansion.

Consequently, a representation restricted to arithmetic and primitive nodes, with no elementary exponential operation, would unnecessarily reject even h
′
=h.

An algebraic coefficient a does not imply an algebraic h. To certify an algebraic solution, a useful exact target is

a=
m
1
	​

dlogr,h(X)=(
r(X
0
	​

)
r(X)
	​

)
1/m
.

The identity must hold in all variables. Residue checks alone are not a general substitute, especially over an algebraic function field.

For rational matrix blocks, use rational-solution algorithms with pole and degree bounds, rather than only increasing an arbitrary ansatz degree. Barkatou’s rational-system algorithm is an established route that avoids mandatory conversion of the whole system to one large scalar equation. A failed bounded ansatz is not an impossibility certificate unless its bound has been proved sufficient. 
ScienceDirect
+1

3.3 Rank-two blocks: factor first, then identify periods

For a 2×2 block, obtain a scalar second-order equation using a cyclic vector:

f
′′
+p(x)f
′
+q(x)f=0,

with the remaining kinematic variables kept symbolic.

First test rational/algebraic factorization and Liouvillian solutions. Kovacic-type methods decide Liouvillian solvability for second-order equations over the appropriate rational-function field. Their scope is not “all second-order equations have elementary solutions”; the useful output is an explicit solution or a genuine obstruction within that class. 
Department of Mathematics

A particularly useful point is that one explicit nonzero solution is enough to finish the ordinary homogeneous problem by a further finite quadrature:

f
2
	​

(x)=f
1
	​

(x)∫
x
0
	​

x
	​

f
1
	​

(t)
2
exp[−∫
x
0
	​

t
	​

p(u)du]
	​

dt.
	​


On a patch where f
1
	​


=0, this produces an independent second solution. Reconstruct the original two-component vectors using the cyclic-vector transformation.

Thus finding one maximal-cut period can be sufficient after performing this additional construction. It is not necessary to insist on independently recognizing two named elliptic functions.

When factorization fails, search for equivalence to a known hypergeometric or elliptic equation. Hypergeometric pullback algorithms provide useful candidate generators, but the general algorithms of Imamoglu and van Hoeij explicitly include heuristic steps. Success can be certified by substitution; an unsuccessful search should not be reported as proof that no pullback exists. 
arXiv

3.4 A concrete elliptic-period construction, without an unspecified H

If the block geometry supplies an elliptic curve, put it into a model such as

E
X
	​

:y
2
=4z
3
−g
2
	​

(X)z−g
3
	​

(X),

away from its discriminant.

Choose a de Rham basis, for example

ω
1
	​

=
y
dz
	​

,ω
2
	​

=
y
zdz
	​

,

and specified independent cycles Γ
1
	​

(X),Γ
2
	​

(X). Define the actual finite integrals

P
iα
	​

(X)=∮
Γ
α
	​

(X)
	​

ω
i
	​

.

Algebraic reduction of differentiated forms gives

∂
μ
	​

ω
i
	​

=
j
∑
	​

G
μ,ij
	​

ω
j
	​

+d
z
	​

η
μ,i
	​

,

hence

∂
μ
	​

P=G
μ
	​

P.

Now solve for a rational or algebraic matrix R:

∂
μ
	​

R=D
μ
	​

R−RG
μ
	​

for every μ,detR

=0.
	​


These are linear differential equations for the entries of R. Once the identities and rank are certified,

H(X)=R(X)P(X)[R(X
0
	​

)P(X
0
	​

)]
−1
	​


is an explicit normalized fundamental matrix.

This supplies a reusable algorithmic interface: curve and forms, finite cycle integrals, algebraic de Rham reduction, equivalence map, normalization. It is not a family-specific formula hardcoded into the solver. Maximal-cut methods and period-matrix normalization provide established amplitude precedents for this construction. 
arXiv
+1

The period values at X
0
	​

 are specified mathematical constants, defined by these integrals. They are not undetermined physical boundary constants.

4. Multivariate homogeneous solutions cannot leave spectator functions unresolved

Solving the x-equation with arbitrary functions of y would repeat the earlier boundary-stratum mistake.

There is, however, a constructive alternative to finding a simultaneous closed form immediately. Suppose an explicit matrix H
x
	​

(x,y) satisfies

∂
x
	​

H
x
	​

=D
x
	​

H
x
	​

,H
x
	​

(x
0
	​

,y)=1.

Define

E
y
	​

=H
x
−1
	​

D
y
	​

H
x
	​

−H
x
−1
	​

∂
y
	​

H
x
	​

.

Flatness implies ∂
x
	​

E
y
	​

=0, while the normalization gives

E
y
	​

(y)=D
y
	​

(x
0
	​

,y).

Therefore solve the second, ordinary homogeneous problem

∂
y
	​

H
y
	​

=D
y
	​

(x
0
	​

,y)H
y
	​

,H
y
	​

(y
0
	​

)=1,

and set

H(x,y)=H
x
	​

(x,y)H
y
	​

(y).
	​


When both factors are explicit finite expressions, this is a complete multivariate homogeneous solution. No arbitrary function remains.

This also means that a common global H or common graph ordering is not always necessary. Explicitly solved coordinate segments, composed with the correct endpoint dependence and verified using flatness, can be a legitimate broader construction. But the spectator dependence must remain symbolic during construction; solving a few fixed numerical slices does not supply these factors.

What finite definite integrals genuinely add

A primitive in a kinematic variable and a parameter-dependent definite integral are different operations.

For example,

K(m)=∫
0
1
	​

(1−t
2
)(1−mt
2
)
	​

dt
	​


is an explicit finite parameter integral. It satisfies

m(1−m)K
′′
+(1−2m)K
′
−
4
1
	​

K=0.

Its integrand, interval, and branch specify the function without solving this equation numerically. These are the standard elliptic-integral and hypergeometric representations. 
DLMF
+1

Allowing such integrals substantially enlarges the solvable class. But

H(X)=“a period matrix for this block”

is not a completed expression until the integrands, cycles, normalization, and equivalence to the block have actually been supplied.

Nor does every second-order rational equation automatically define a genus-one Picard–Fuchs system. An extracted scalar differential operator is not evidence of ellipticity by itself.

5. CF303: challenge the homogeneous classification before solving an elliptic problem

Nothing in the current implementation description establishes that CF303 has a genuinely elliptic leading homogeneous obstruction. Rebuilding its original two-variable rational connection is the appropriate way to settle that question.

The distinction can be demonstrated exactly. Let z=x+y, let P
4
	​

 be a fixed nonsingular quartic, and let N=E
21
	​

. Consider

dJ=ϵN
P
4
	​

(z)
	​

dz
	​

J.

This connection is flat, A
[0]
=0, and N
2
=0. Its normalized solution is

U=1+ϵN∫
z
0
	​

z
	​

P
4
	​

(t)
	​

dt
	​

.

There is an elliptic Abelian integral in the answer. There is no nontrivial order-zero homogeneous system to solve.

Thus these are separate questions:

Question	What establishes it?
Does an algebraic kernel involve a genus-one curve?	The algebraic curve and its nondegeneracy.
Do solution coefficients contain elliptic integrals?	The actual finite integrations or equivalent function identities.
Does the leading homogeneous module require elliptic periods?	A leading differential block and a demonstrated period-system interpretation, after relevant gauge simplifications.

The last conclusion cannot be inferred from the first.

For the rebuilt CF303 connection, I would require the following evidence before retaining an elliptic-homogeneous label:

Generic-ϵ rank and exact flatness of the original A
x
	​

,A
y
	​

, with no premature specialization to four dimensions.

Exact entry valuations, negative-cycle witnesses if present, and the zero-order blocks after successful shearing or other finite gauges.

Constant common-flag tests, rational/algebraic reduction attempts with stated scope, and only then scalar-operator or period analysis of the remaining blocks.

Specializing ϵ=0 before regularizing the basis can lose directions whose independence is visible only at generic ϵ. Conversely, a large graph component can conceal a reducible differential module.

The old missing fixed-ρ tangential operator is missing intermediate data, not a theorem about CF303’s function class. Your reconstruction bypasses that packaging issue; it does not yet prove either the presence or absence of an elliptic obstruction.

“General NNLO” cannot stop at scalar and elliptic rank-two blocks

Scalar and rank-two algorithms are valuable first implementations, but they are not a complete mathematical envelope for arbitrary NNLO families. A recent classification of two-loop geometries with standard quadratic propagators finds, in addition to elliptic curves, genus-two and genus-three curves and K3 surfaces. That is evidence against building “two loops implies at most elliptic” into the code. It is not a claim that CF303 realizes those geometries. 
arXiv
+1

The same period-matrix construction extends conceptually to higher-rank de Rham systems: explicit forms and cycles produce P, and a certified equivalence map produces H. What grows is the task of constructing the forms, cycles, and rank certificate—not the form of the subsequent finite-quadrature algorithm.

There is also directly relevant recent work by Bree et al. on filtration-compatible Laurent connections. It provides a systematic route toward ϵ-factorization, but two qualifications matter here: the universal production of the required starting filtration is reported as an observation rather than a general proof, and the factorization procedure still contains coupled homogeneous systems, including elliptic period equations. It is therefore a promising source of better starting bases, not a replacement for your explicit homogeneous-function construction. 
arXiv
+1

6. Laurent lower bounds must be proved separately from requested upper orders

The graph construction gives useful lower bounds without guessing physical master-integral poles.

For the diagonally sheared system,

U
A
	​

=SVS
−1
,V∈K[[ϵ]],

so

val
ϵ
	​

(U
A
	​

)
ij
	​

≥s
i
	​

−s
j
	​

.

A sharper bound is the shortest-path weight from j to i in the original weighted graph, including the empty path for i=j. Cancellations may raise the true valuation, but cannot invalidate this lower bound.

For the complete change of basis, write

I=QZ,U
I
	​

(X,X
0
	​

;ϵ)=Q(X,ϵ)V(X,X
0
	​

;ϵ)Q(X
0
	​

,ϵ)
−1
.

Here Q includes all basis changes, shears, and explicitly constructed homogeneous factors, in their actual order.

Let

q
ia
	​

=val
ϵ
	​

Q
ia
	​

(X,ϵ),r
bj
	​

=val
ϵ
	​

[Q(X
0
	​

,ϵ)
−1
]
bj
	​

.

Since V starts at nonnegative order, a sufficient required upper order for a contributing V
ab
	​

 in U
I,ij
[n]
	​

 is

n−q
ia
	​

−r
bj
	​

.

This is a computable dependency bound. It should determine the internal expansion depth, rather than a fixed “NNLO depth.”

Three claims must remain separate:

Transport completeness. Every declared U
I,ij
[n]
	​

 has been constructed. This needs no physical values of C.

Completeness of I
i
[n]
	​

 in constant coefficients. If

C
j
	​

(ϵ)=
m≥ℓ
j
	​

∑
	​

ϵ
m
C
j
[m]
	​

,

then

I
i
[n]
	​

=
j
∑
	​

k
∑
	​

U
I,ij
[k]
	​

C
j
[n−k]
	​


requires transport through k=n−ℓ
j
	​

. A finite output therefore requires a justified lower bound ℓ
j
	​

, or an explicitly declared conditional assumption about the allowed constant series.

Completeness for an observable. Reduction coefficients can introduce additional poles and require deeper master expansions.

A theorem establishing that every finite order is constructible is not a statement that a particular file already contains every order needed by an unspecified NNLO observable.

Structural pole bounds may come from a justified regulated-integral analysis. Resolution/sector-decomposition methods provide a rigorous basis for Laurent expansions in appropriate settings, but their assumptions must be checked for the integrals and continuation under consideration. Do not replace that analysis by “two loops usually means ϵ
−4
.” 
arXiv

7. Validation: generic coefficient identities, not derivatives at one point

First derivatives at X
0
	​

 are inadequate. For example,

U
(X)=U(X)+(x−x
0
	​

)
2
(y−y
0
	​

)
2
M

has the same value and first derivatives there, but generally fails the differential equations.

7.1 Check against the independently reconstructed original connection

Let M
μ
	​

 denote the original-basis connection reconstructed from differentiation and reduction. For every requested entry, order, and independent variable, establish

R
μ
[n]
	​

=∂
μ
	​

U
I
[n]
	​

−
k
∑
	​

M
μ
[k]
	​

U
I
[n−k]
	​

=0,
	​


together with

U
I
[n]
	​

(X
0
	​

)=δ
n0
	​

1.

The original M
μ
	​

 must not be defined retrospectively as
(∂
μ
	​

U
I
	​

)U
I
−1
	​

; that would make the check tautological.

Negative powers in M
μ
	​

 require additional coefficients for verification. For example, a term M
μ
[−3]
	​

 can make the residual at order n depend on U
I
[n+3]
	​

. Construct the exact dependency table for these checks, or prove the corresponding identities through the transformed regular system and the exact gauge identity. Do not silently treat unavailable coefficients as zero.

7.2 Differentiate the actual integral expressions

For a stored definition

F
α
	​

(s;X)=∫
0
s
	​

g
α
	​

(t;X)dt,

there are two different derivative rules:

∂
s
	​

F
α
	​

=g
α
	​

,∂
X
μ
	​

	​

F
α
	​

=∫
0
s
	​

∂
X
μ
	​

	​

g
α
	​

(t;X)dt

when s is fixed.

The second includes all endpoint-parameter dependence of kernels, periods, algebraic branches, and earlier functions. A correct s-derivative does not automatically verify either kinematic equation.

An expression-graph checker can apply these rules without word enumeration. Integration-by-parts and zero-initial-value identities can supply certificates when treating the function nodes as formally independent would be too strong.

7.3 Flatness supplies a rigorous multivariate proof

For a path family with fixed starting point, define

a=A(∂
s
	​

γ),b
μ
	​

=A(∂
X
μ
	​

	​

γ).

If V is the path transport, let

E
μ
	​

=∂
X
μ
	​

	​

V−b
μ
	​

V.

Direct differentiation gives

∂
s
	​

E
μ
	​

=aE
μ
	​

+(∂
X
μ
	​

	​

a−∂
s
	​

b
μ
	​

+[a,b
μ
	​

])V.

The parenthesis vanishes by flatness. Since the starting point is fixed,
E
μ
	​

(0)=0. Hence E
μ
	​

=0; at the endpoint this is the desired kinematic differential equation.

In your finite construction, this argument can be implemented coefficient by coefficient using the same well-founded order, rather than invoking an unspecified infinite solution.

Thus exact flatness, exact gauge identities, generic path-coefficient identities, and normalization can constitute a rigorous multivariate proof. Local numerical derivatives alone cannot.

7.4 Independently evaluate the finite integrals

The independent reader should evaluate the stored integrals and arithmetic only. It may evaluate earlier functions by quadrature or controlled interpolation, but must not replace the whole construction with an ODE solve.

A useful test combines:

Direct finite-integral evaluation at nonsingular points, with increased precision and quadrature resolution.

Numerical kinematic derivatives obtained independently from those values—for example by a Cauchy differentiation contour inside an analytic patch—not by setting the derivative equal to M
μ
	​

U.

Comparison of the resulting residuals against the original connection, and comparison of homotopic path choices.

For elliptic functions, an independent route is direct algebraic contour integration rather than the same period-DE evaluator used during construction. Rigorous ball-arithmetic quadrature is available for suitable piecewise analytic integrands, although nested error propagation and endpoint singularities still need explicit treatment. 
arXiv

Numerical agreement supports the implementation and branch handling. The coefficient identities and justified truncation bounds establish the mathematical completion claim.

Recommended implementation priority

The next extension should be weighted shearing plus automatic treatment of zero-order blocks, not another attempt to force every family into a global dlog ϵ-form.

Implement the exact valuation graph, shortest-path shifts, zero-block decomposition, and constant common-flag test first. These have clear success criteria and explicit obstruction witnesses. Add scalar integrating factors and rational homogeneous solutions next, followed by rank-two factorization and explicit period constructions, with simultaneous multivariate verification.

Then run that machinery on the rebuilt CF303 connection. The decisive output is either a finite coefficient-complete solution, or a precisely identified remaining block together with the exact missing object: a finite regularizing gauge, a homogeneous function representation, a period-equivalence map, or a justified order bound.

The mathematical target is a finite, verified solution of a filtered linear system—not necessarily a canonical form. Your current finite-integral representation can already express the answer; the main remaining work is to make the filtering and homogeneous-block construction sufficiently general, while keeping their success conditions explicit.