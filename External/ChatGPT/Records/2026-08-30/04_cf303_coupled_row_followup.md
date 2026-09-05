# CF303 Coupled Row Followup

## Question

Continue the existing **Assess Multiquadratic Pipeline** analysis. We now have
new decisive CF303 `(25,18)` evidence. Please assess the smallest mathematically
correct coupled-row recovery; do not suggest more rational letters, denominator
support, diagonal re-normalization, or another algebraic cover.

## New compatibility result

The package's existing gauge-eliminated residue-integrability screen was run
at 52 generic rational-chart points, `p=2147483423`, `eps=1`. Both certified
diagonal connections were flat.

- full 48 dlogs: `208 x 192`, rank 188, augmented rank 189, defect 1,
  nullity 4, verified left witness with nonzero RHS pairing;
- 16 polar dlogs: `208 x 64`, rank 60, augmented rank 61, defect 1,
  nullity 4, verified left witness.

The package sign convention was audited and agrees with your equation. A
multi-prime/multi-regulator confirmation is running now, so treat the present
image as strong pilot evidence but state where generic confirmation matters.

The forcing construction was also checked independently from the original
112 deferred source terms through radical branch selection and Jacobian
pullback at three generic points. All 8 entries agree exactly modulo the
31-bit prime with the saved rational-chart record. The full 7,280-row gauge
system and its obstruction witness are therefore not assembly artifacts.

## Higher-pole escape

The full left cokernel has dimension 12. The degree-one exact forms `dx,dy`
project to rank 8 and do not span the obstruction. Adding any one of
`d(x^2)`, `d(xy)`, or `d(y^2)` raises the projected rank to 12 and spans it.
This was then tested on the full system at an independent image
`p=1000003, eps=1/21`:

- `{dx,dy,d(x^2)}` gives rank = augmented rank = 7280, nullity 4;
- replacing `d(x^2)` by `d(xy)` gives the same result;
- both particular solutions replay exactly on all 7,280 rows.

Thus a rational gauge to an epsilon-factorized connection with polynomial
exact one-forms is a real candidate, but it is irregular at projective
infinity and is not a strict rational-dlog/Fuchsian canonical form.

## Coupled-row dependency

The saved deferred source record proves that the dependency-closed forcing is

`F_mu = A_{mu,25,18} - Sum_{m=19}^{24} D_{25,m} A_{mu,m,18}`.

The current driver solves row 25 greedily in the order 24,23,...,18. Each
earlier affine strip solution is normalized to one particular representative
before the next forcing is built. The six feeder blocks `(25,m)`, `m=19..24`,
were all accepted individually, but their homogeneous affine freedom was not
retained for downstream constraints.

## Questions

1. Is the sharp next pilot to recover the homogeneous solution spaces of the
   six feeder strips, contract their induced changes in the `(25,18)` forcing
   against the current covariant-integrability witness, and solve only for
   those homogeneous parameters plus the target residues?
2. Derive the exact linear map from a homogeneous variation `delta D_{25,m}`
   to the `(25,18)` forcing curl / witness pairing, including whether one must
   propagate variations through all intermediate lower-strip equations.
3. Can this be implemented as backward constraint propagation through the
   triangular row (retain affine spaces and eliminate parameters) rather than
   one monolithic gauge system? Give the smallest sound algorithm and the
   decisive rank tests.
4. Does flatness of the original full family guarantee that some coupled row
   target exists, or can the fixed diagonal epsilon blocks still make the
   entire rational-dlog row impossible?
5. If the coupled-row pilot fails, is accepting `dx,dy,d(x^2)` as a generalized
   epsilon form mathematically useful for transport, or does its irregular
   infinity/exponential alphabet make it a bad endpoint?

Please give a concrete GO/NO-GO sequence with dimensions/unknowns wherever
they can be inferred, and distinguish sampled modular evidence from exact
functional conclusions.

## Pro response

Verdict

GO on one small projected feeder-freedom test. NO-GO on a coupled-row production rewrite yet.

There is an important reason not to blame greedy normalization prematurely: under the stated rational-dlog assumptions, the discarded feeder freedom is normally only kinematics-independent matrix shifts. Such shifts cannot remove the downstream dlog obstruction. This is a theorem about rational off-diagonal transformations, not merely an expectation from small nullities. Meyer proves uniqueness of the rational off-diagonal gauge up to terms depending only on ϵ. 
arXiv
+1

The polynomial-exact target is a legitimate alternative candidate. Moreover, its higher-order poles at infinity do not by themselves imply genuine irregular singularities or exponential functions.

1. What feeder freedom could actually help?

Write D
j
	​

=D
25,j
	​

, E=E
25
	​

, and define

∇
j
	​

H=dH−ϵ(EH−HC
j
	​

).

Let the accepted target of feeder j be ϵΩ
j
	​

, where Ω
j
	​

 is a constant-in-kinematics dlog combination; its matrix coefficients may still depend on ϵ.

For one fixed forcing, two accepted feeder solutions differ by

∇
j
	​

H=−ϵΔΩ
j
	​

.

A rational H(x,y,ϵ) satisfying this equation is kinematics-independent. Briefly, expand in Laurent powers of ϵ. At the first order, dH
n
	​

 is a constant combination of dlogs. A rational function cannot have a nonzero logarithmic differential as its exact derivative, so H
n
	​

 is constant. Induction gives

H=H(ϵ).

This is precisely the off-diagonal uniqueness argument. It does not require the intermediate residue matrices to be epsilon-independent. 
arXiv

The same conclusion extends through the feeder chain

Suppose the lower-prefix blocks A
kj
	​

 are already certified dlog forms with kinematics-independent coefficients. At j=24, the variation is constant. At j=23, its induced forcing is a constant matrix times A
24,23
	​

, hence is again dlog. The same argument makes H
23
	​

 constant. Continue downward.

Therefore, under those hypotheses,

ΔD
25,j
	​

=H
j
	​

(ϵ),j=19,…,24.
	​


The change in the target forcing is then

ΔF
18
	​

=−
m=19
∑
24
	​

H
m
	​

(ϵ)A
m,18
	​

,

which is itself a constant-in-kinematics dlog combination. It can be absorbed into the target residues and cannot change whether a rational-dlog solution exists.

Consequently, recovering feeder nullspaces is worthwhile first as a short test of this conclusion—not as a presumed rescue. If those nullspaces contain only constant gauge shifts and redundant letter relations, stop the coupled-row route.

A genuinely nonconstant generic feeder variation would mean that at least one hypothesis differs: for example, a feeder target is not actually dlog, a lower-prefix block is outside that class, or the recovered modular nullspace is not a generic functional nullspace.

In particular, do not classify freedom from ϵ=1 alone. Special regulator values can admit resonant rational homogeneous solutions that do not exist over Q(ϵ).

2. Exact variation map, including intermediate propagation

The full row equation is

∇
j
	​

D
j
	​

+
k=j+1
∑
24
	​

D
k
	​

A
kj
	​

+ϵΩ
j
	​

=A
25,j
	​

.

The lower-prefix connection is fixed. Therefore the coupled variation equations are exactly linear:

∇
j
	​

H
j
	​

+
k=j+1
∑
24
	​

H
k
	​

A
kj
	​

+ϵΘ
j
	​

=0,
	​

(1)

where

H
j
	​

=ΔD
j
	​

,Θ
j
	​

=ΔΩ
j
	​

.

There are no products of two unknown variations: all A
kj
	​

 are fixed.

Yes, variations must propagate through every intermediate feeder equation. An independent null vector of feeder 24 changes the forcing for 23, which changes 22, and so on. Taking six independent local nullspaces and contracting them directly against A
m,18
	​

 generally includes variations that do not preserve the already solved feeders.

After imposing (1), the target forcing changes by

P:=ΔF
18
	​

=−
m=19
∑
24
	​

H
m
	​

A
m,18
	​

.
	​

(2)
Covariant-curl map

For a one-form η, use

∇
j
(1)
	​

η=dη−ϵ(E∧η+η∧C
j
	​

).

Directly,

ΔK
18
	​

	​

=∇
18
(1)
	​

P
=−
m
∑
	​

[(∇
m
	​

H
m
	​

)∧A
m,18
	​

+H
m
	​

(dA
m,18
	​

−ϵC
m
	​

∧A
m,18
	​

−ϵA
m,18
	​

∧C
18
	​

)].
	​

(3)

Flatness of the lower connection gives

dA
m,18
	​

−ϵC
m
	​

∧A
m,18
	​

−ϵA
m,18
	​

∧C
18
	​

=
18<k<m
∑
	​

A
mk
	​

∧A
k,18
	​

.

Substituting (1) into (3), all intermediate-path terms cancel:

ΔK
18
	​

=ϵ
m=19
∑
24
	​

Θ
m
	​

∧A
m,18
	​

.
	​

(4)

This is the cheapest compatibility map. Once the feeder variations satisfy their coupled equations, you need only their target-residue variations to compute the change in the target curl.

It also shows why a purely horizontal variation with Θ
m
	​

=0 cannot repair the compatibility obstruction.

3. Smallest sound algorithm
First gate: test whether the discarded freedom is substantive

Recover the feeder nullspaces before artificial normalization constraints, retaining both:

(ΔD
j
	​

,ΔΩ
j
	​

),

not only gauge coordinates.

Remove null directions that represent a zero one-form through letter dependencies. Then determine whether every surviving gauge variation is kinematics-independent.

For constant shifts, the entire candidate space has at most

k
const
	​

=2
m=19
∑
24
	​

n
m
	​


parameters, where n
m
	​

 is the dimension of sector m. The feeder sector dimensions were not supplied, so a numerical count cannot be inferred.

If all freedom is constant and the lower blocks are dlog, the argument above closes the coupled-row rescue without a large solve.

If substantive variations survive: propagate affine spaces

At each feeder j=24,…,19, let z
j
	​

 contain its gauge and residue coefficients. Suppose accumulated upstream variations are parameterized by θ. The next linear system is

M
j
	​

Δz
j
	​

=B
j
	​

θ.

Let W
j
	​

M
j
	​

=0 be a full left-cokernel basis. Enforce

W
j
	​

B
j
	​

θ=0.

Restrict θ to that kernel, solve the compatible RHS columns simultaneously, and write

Δz
j
	​

=S
j
	​

θ+N
j
	​

ξ
j
	​

,

where N
j
	​

 is the local nullspace. Append the new parameters ξ
j
	​

, and continue.

This is block-triangular elimination with retained parameters. It does not require a monolithic six-feeder gauge matrix.

After feeder 19, obtain a compatible family

H
m
	​

=
a=1
∑
k
	​

H
m,a
	​

θ
a
	​

.
Use the full target cokernel, not one witness

Form

P
a
	​

=−
m
∑
	​

H
m,a
	​

A
m,18
	​

.

Let the current full rational system be

M
18
	​

z=b,W
full
	​

M
18
	​

=0.

Your full cokernel has dimension 12. The complete sampled coupled-recovery test is therefore only

W
full
	​

Pθ=−W
full
	​

b,
	​

(5)

a 12×k system.

Its decisive criterion is

rank(W
full
	​

P)=rank[
W
full
	​

P
	​

−W
full
	​

b
	​

].

If it passes, one ordinary target solve recovers D
25,18
	​

 and its residues for the selected compatible feeder parameters.

The curl-only prefilter is also small:

System	Left-cokernel dimension
48-letter compatibility, 208×192, rank 188	20
16-letter compatibility, 208×64, rank 60	148
Full rational gauge system	12

Use (4) for the inexpensive 20-row compatibility prefilter, then (5) for the stronger rational-gauge test.

A nonzero pairing with one existing witness is only a necessary test. “Defect 1” for one RHS does not mean the cokernel is one-dimensional.

4. What flatness guarantees

Flatness guarantees a local analytic solution of the coupled row problem after sufficiently enlarging the gauge class. Locally, one can trivialize the diagonal/lower connections and integrate the remaining closed row form.

It does not guarantee that this primitive is rational, or that a rational transformation places the extension in the specified constant-residue dlog span. In differential-module language, flatness supplies the cocycle condition; it does not make the extension class rationally exact or place it in the chosen target subspace. The distinction between flatness and the existence of a rational canonical transformation is fundamental to canonical-form algorithms. 
arXiv

For this campaign, therefore:

fixed feeder representatives can obstruct a restricted target;

but if all alternative rational-dlog feeder representatives differ only by constant shifts, retaining them cannot remove the obstruction;

a failed projected coupled test can be a genuine rational-dlog no-go under the stated exhaustive support assumptions.

The present ϵ=1 compatibility result is strong pilot evidence, not a generic functional theorem. The running multi-prime/multi-regulator confirmation matters especially because ϵ=1 can be resonant. Likewise, feeder nullities and parameter maps must stabilize generically before interpreting a failed coupled test as a functional obstruction.

5. The polynomial-exact target is useful—and not automatically irregular

Yes: retain {dx,dy,d(x
2
)} as a serious generalized epsilon-form candidate if the coupled freedom is ineffective.

But correct the terminology:

It has higher-order poles at projective infinity in the displayed basis. That does not establish an intrinsically irregular differential module or an exponential alphabet.

For example,

dJ=ϵNd(x
2
)J,N
2
=0,

has solution

J=(I+ϵNx
2
)J
0
	​

.

There is no essential exponential behavior. The apparent exponential truncates because N is nilpotent.

More generally, regular-singular connections are closed under extensions. If all diagonal graded pieces are regular singular, a block-triangular extension by rational off-diagonal forms remains regular singular, although its current matrix can have higher-order poles. This is Deligne’s extension property; a non-Fuchsian matrix can represent a regular-singular connection in a poor meromorphic basis. 
Tim Hosgood Translations
+1

Practical consequence for transport

The generalized connection is useful if it can be reconstructed as

dJ=ϵΩ(x,y)J,∂
ϵ
	​

Ω=0.

Its Laurent coefficients can be transported by the same iterated integration recursion,

dJ
(n)
=ΩJ
(n−1)
.

Polynomial exact kernels introduce rational/polynomial prefactors and can mix the usual weight bookkeeping. They do not inherently invalidate exact transport. It should be labeled epsilon-factorized with rational kernels, not strict dlog/UT canonical.

If the reconstructed coefficient matrices still depend on ϵ, it is only a rational-kernel intermediate until family regulator factorization succeeds.

Important limitation of the current positive test

After adding 12 columns, your matrix has 7280 rows, rank 7280, and nullity 4. It therefore fits every RHS on those sampled rows.

That is a valuable demonstration that the added exact forms span the 12-dimensional sampled obstruction. It is not yet proof of a functional solution. Use the existing fresh-point per-block acceptance on the reconstructed candidate; that already supplies the needed discriminator without a new symbolic layer.

Concrete GO/NO-GO sequence

Recover the unnormalized feeder gauge/residue freedom at a generic regulator image.
First test whether its gauge parts are only kinematics-independent shifts.

If all freedom is constant and the lower prefix is dlog: NO-GO on coupled-row recovery.
The normalization choices cannot change rational-dlog existence. Do not build a coupled production solver.

Only if substantive generic freedom remains: propagate it through feeders 24→19 using the small affine-space elimination above. Never combine independent feeder nullspaces without this propagation.

Run the 12×k projected full-system test.

Inconsistent: stop this coupled class.

Consistent: select compatible parameters, solve the target once, and reconstruct the coupled solution over Q(ϵ).

In parallel, continue the polynomial-exact candidate through its existing reconstruction and fresh-point acceptance.
If it passes and epsilon factorization is established, it is a mathematically useful endpoint for exact transport—even if no strict rational-dlog row exists.

The first calculation should determine whether the discarded feeder freedom is anything more than constant basis normalization. Under the stated dlog assumptions, the theorem predicts that it is not; the generalized rational-kernel solution is then the better-supported route.
