Verdict: CONDITIONAL GO

The proposed repair is mathematically sound, with three mandatory qualifications:

The ancillary must contain a self-contained exact arithmetic circuit, not merely pointers to package routines or finite-field evaluators.

The two path-segment operators need an explicit junction/mode-matching map and the correct tangential intertwining equation; matrix multiplication alone is insufficient unless the interface bases already coincide.

The terminal object should be called a MasterIntegralSolutionInTermsOfBoundaryConstants, or an equivalently explicit subtype/status of MasterIntegralSolution. It is not yet a PhysicalRegionMasterIntegralSolution.

This is consistent with the terminology principle that scientific objects must be separated from implementation caches and that “transport” should refer specifically to propagation along a path.

02_community_vocabulary_revisio…



community_terminology_rename_pl…

 It also fits the actual CF303 history: the mathematical exception was localized, while the dominant practical problem was the pathological symbolic representation of otherwise cheap exact functions.

Pasted markdown

 The project explicitly identified modular black-box evaluation as the appropriate alternative to swollen symbolic composition, and measured post-solve canonicalization—not modular evaluation—as the bottleneck.

11_reconstruct_dont_simplify



08_three_root_slowdown_and_reco…

 The deferred-leaf/channel architecture was designed for exactly this situation.

codex_overnight_optimization_tr…

1. Exact arithmetic/Hermite DAG
Decision: GO, provided the Hermite nodes have fixed mathematical semantics

An expanded numerator and denominator are not required for exactness. A finite straight-line program or arithmetic circuit over an exact coefficient field is itself an exact representation of the resulting rational or algebraic function. Such representations are standard in exact computer algebra precisely because expanded polynomials can be exponentially larger than their circuits.
ACM Digital Library
+1

For the CF303 object, declare a coefficient field of the form

K=Q(p,z,ϵ)[r
1
	​

,…,r
s
	​

,Y]/(r
i
2
	​

−Δ
i
	​

,Y
2
−P
4
	​

),

or the appropriate localization of this ring. A portable exact DAG may then have nodes for:

+,−,×,(⋅)
−1
,∂
z
	​

,∂
p
	​

,substitution,matrix multiplication,

together with a precisely specified Hermite-reduction operation.

The Hermite node must mean an exact map

Herm
K,z
0
	​

	​

(ω)=(H,{c
α
	​

})

such that

ω=dH+
α
∑
	​

c
α
	​

κ
α
	​

,H(z
0
	​

)=0.
	​


The following data are part of that definition:

the algebraic curve and function field;

the chosen differential basis {κ
α
	​

};

the treatment of finite poles and infinity;

the normalization of second- and third-kind kernels;

the base point z
0
	​

=1/2;

the algebraic branch convention at that base point;

the convention for primitive constants.

Without these, “apply Hermite reduction” is not a unique mathematical operation: H is defined only up to a constant, and the remainder depends on the chosen basis modulo exact differentials.

What is not sufficient

The following would leave only an intermediate construction:

a node meaning “call the current Maple/Wolfram reducer” without defining the mathematical output convention;

a node whose result is known only through modular values;

a reference to 112 inert H-nodes or 180 one-forms whose defining expressions are absent;

a finite-field reconstruction operation used as part of the object’s semantics rather than only to discover or validate an exact object.

The clean portable choices are either:

store the exact primitive and remainder output of every Hermite node; or

include a self-contained deterministic exact reducer whose mathematical conventions are those above.

With either choice, the circuit is a complete exact coefficient representation. There is no mathematical need to print its expanded rational functions.

2. Product of the tangential and normal operators
Decision: GO; Chen deconcatenation need not be expanded

Let

U
∥
	​

(p,p
0
	​

;ϵ)

be the tangential operator for the 13 boundary functions,

∂
p
	​

U
∥
	​

=Ω(p,ϵ)U
∥
	​

,U
∥
	​

(p
0
	​

,p
0
	​

)=I.

Let

N(z,p;ϵ)

be the complete normal boundary-to-bulk factor, including:

the regularized boundary-mode embedding or junction map;

normal GPL/eMPL evolution;

the rational-in-ϵ final-layer construction;

the path gauge F
25
	​

=G
25
	​

+HL;

the physical transformation I
25
	​

=T
25
	​

F
25
	​

.

Then the solution is

I(z,p;ϵ)=N(z,p;ϵ)U
∥
	​

(p,p
0
	​

;ϵ)c
0
	​

(ϵ).
	​

(1)

The rightmost segment acts first: tangential evolution from p
0
	​

 to the boundary point, followed by regularized normal evolution into the bulk.

For ordinary parallel transport, path concatenation is represented exactly by the ordered product of the segment evolution operators. Chen’s concatenation formula expands the coefficient of a sequence as a sum over all cuts of that sequence between the two paths, but this expansion is a coordinate formula for the product—not a requirement for defining it.
Inspire
+2
Duke Mathematics Department
+2

Therefore a sparse representation indexed by

(w
∥
	​

,w
⊥
	​

)

is complete. It is honestly described as a finite sum of products

I
∥
	​

(w
∥
	​

)I
⊥
	​

(w
⊥
	​

),

not as one GPL or eMPL with a concatenated index sequence. Elliptic multiple polylogarithms are themselves iterated integrals on an elliptic curve with a specified kernel basis and marked points, so retaining their segment-specific curve and alphabet is the correct representation.
arXiv
+1

Mandatory interface condition

The two factors may be multiplied directly only if the codomain of U
∥
	​

 is exactly the boundary-coordinate domain of N.

Otherwise an explicit matching map is required:

I(z,p)=N
amb
	​

(z,p)M
junction
	​

(p)U
∥
	​

(p,p
0
	​

)c
0
	​

.
	​

(2)

Here M
junction
	​

 maps the 13 boundary-function coordinates into the normal Frobenius/Levelt coordinates used by the normal operator.

That map must not be hidden in naming or assumed from matching dimensions.

Full two-variable compatibility

Because the normal factor depends parametrically on p, it must satisfy

∂
z
	​

N=A
z
	​

N,
	​

(3)

and

∂
p
	​

N=A
p
	​

N−NΩ.
	​

(4)

Then equation (1) obeys

∂
p
	​

I=(A
p
	​

N−NΩ)U
∥
	​

c
0
	​

+NΩU
∥
	​

c
0
	​

=A
p
	​

I.

Equation (4) is the essential junction/intertwining condition. Without it, the product may solve the ODE along each segment separately while failing the original two-variable differential equation.

3. Minimal nonredundant acceptance

Because the source operator, tangential operator, final-layer recurrence, and endpoint machinery already have their own accepted records, the portable repair does not require replaying every internal proof.

The minimum mathematical acceptance consists of four items.

A. Definition closure

Every node reachable from a demanded output must resolve to:

an exact leaf;

an explicitly defined kernel;

or another included DAG node.

This would have caught the discarded 112 H-nodes and 180 deferred one-forms. It is a completeness property, not an additional numerical certificate.

B. One end-to-end differential identity

For the composed coefficient operator

S(z,p)=N(z,p)U
∥
	​

(p,p
0
	​

),

check both original differential-equation components:

∂
z
	​

S−A
z
	​

S=0,∂
p
	​

S−A
p
	​

S=0.
	​

(5)

Under the stated production policy, these may be evaluated in exact finite-field arithmetic at unused primes and generic points, for a basis of retained boundary-constant columns and every demanded epsilon order.

This single composed test supersedes separate new checks of every intermediate product.

C. One regularized boundary identity

Let Φ(ρ,p,ϵ) be the declared local Frobenius/Levelt embedding. Depending on the interface convention, require either

Reg
ρ=0
	​

[Φ
−1
N]=I
	​

(6)

when N already accepts the declared boundary coordinates, or

Reg
ρ=0
	​

[Φ
−1
N
amb
	​

]=M
junction
	​

	​

(7)

when a separate junction map is used.

This must include the required logarithmic/Jordan terms and enough regular Frobenius jets to reach the demanded finite part. It is not ordinary substitution at the singular point.

The normal path-gauge convention additionally requires

H(1/2,ϵ)=0.
	​

(8)
D. Demand closure

The stored epsilon windows and sequence depths must be closed under:

negative epsilon valuations;

multiplication by H and T
25
	​

;

normal and tangential sequence concatenation;

all reachable boundary-coordinate columns.

A graph-only reachability calculation gives a conservative superset. To call the Stage-3 worklist exact, reachability must be performed after exact-zero coefficient branches have been removed. Otherwise the ledger is safe but may contain unnecessary boundary constants.

No Chen deconcatenation expansion and no dense characteristic-zero residual are required.

4. When this is a master-integral solution
Recommended terminal name

Use

MasterIntegralSolutionInTermsOfBoundaryConstants

for the terminal pre-Stage-3 object.

A bare MasterIntegralSolution may remain an umbrella type, but its subtype or status must state that the boundary constants are undetermined. Differential-equation solutions of Feynman integrals are conventionally fixed by boundary data, and the iterated-integral representation together with symbolic boundary constants is a valid general solution.
arXiv
+1

The following may remain unknown:

the numerical or analytic values of the boundary constants;

boundary integrals that Stage 3 will evaluate;

relations not yet supplied by regions or direct integration, provided each missing relation is explicitly listed.

The following may not remain unknown.

A. Boundary-coordinate meaning

Every BoundaryConstantID must have:

its tangential base point;

its mode or coordinate normalization;

its epsilon order range;

all known relations and known-zero conditions.

If an unresolved quantity is still a function of a boundary-stratum variable rather than a constant at a tangential base point, the result is only a solution in terms of boundary functions.

B. Junction map

The map from boundary-function coordinates to normal boundary coordinates must be part of the object or explicitly absorbed into N.

C. Exact coefficient semantics

The difficult H/K layer must be represented by the exact DAG or exact lifted coefficient deck. A modular provider alone is insufficient as the analytic object.

D. Analytic definitions

The record needs:

every path segment and orientation;

base points and tangential base points;

all GPL and eMPL kernel definitions;

the elliptic curve and marked points;

algebraic branches and the physical chamber;

regularization conventions;

the final H and T
25
	​

 multiplication order.

Without these, the same formal index sequence can denote different analytic functions.

E. Full requested scope

The object must say which master rows and epsilon orders it solves. Complete demand coverage is enough for a demand-scoped result, but it must not be presented as a complete 45-master family solution if only selected rows were constructed.

F. Stage-3 requirements

The worklist must give the exact independent boundary constants actually appearing in the solution, their required epsilon orders, and the mathematical definition or mode associated with each.

A list of file dependencies or structurally reachable IDs without those meanings is not yet a boundary-determination problem specification.

G. Physical-region status

To call the result a PhysicalRegionMasterIntegralSolution, one additionally needs:

every independent boundary constant determined or eliminated;

the physical analytic continuation and +i0/−i0 prescription;

the physical branch on every algebraic/elliptic segment.

The proposed distinction between the parameterized solution and physical-region completion is correct.

Decisive edit to the proposed repair
Proposed item	Ruling
Preserve the exact arithmetic/Hermite DAG	ACCEPT
Treat modular images as validation only	ACCEPT
Omit expanded global rational functions	ACCEPT
Store tangential and normal coefficient operators as an ordered product	ACCEPT
Expand Chen deconcatenation	NOT REQUIRED
Treat the two operators as directly composable without declaring the interface basis	REJECT
Omit the p-intertwining equation for the normal factor	REJECT
Derive Stage-3 needs by raw structural reachability	CONSERVATIVE ONLY; exact-zero pruning is needed for an exact worklist
Call the pre-Stage-3 object bare MasterIntegralSolution	CONDITIONAL
Call it MasterIntegralSolutionInTermsOfBoundaryConstants	ACCEPT
Call it a physical-region solution before constants and continuation are fixed	REJECT
Bottom line

The repair can yield a mathematically complete, publishable ancillary result without printing the pathological rational functions.

The exact final object should be understood as

S(z,p)=N
exactDAG
	​

(z,p)U
∥
	​

(p,p
0
	​

),
	​


with:

∂
z
	​

N=A
z
	​

N,∂
p
	​

N=A
p
	​

N−NΩ,

and the declared regularized boundary normalization.

Once all reachable DAG definitions are included, the junction basis is explicit, equations (5)–(8) hold on the demanded scope, and every unresolved boundary constant is named and normalized, the object is an exact master-integral solution in terms of boundary constants. The Cartesian expansion of its two path-segment index sequences is optional presentation, not part of mathematical completeness.