# Numerical speedup review

## Question

Please review a numerical-evaluation optimization decision. The 91-family explicit finite epsilon solutions are complete as discussed earlier. GitHub context https://github.com/CongyueZhang2002/factorization-and-loops ; current edits are local. User wants a general NNLO framework, real stored symbolic solutions, numerical evaluation and cheap checks, now authorizes CPU speedups and asks whether GPU helps.

Stored data: explicit acyclic kernels K_i(t;X) built from earlier K by arithmetic, algebraic powers, logarithms and inverse hyperbolic functions; F_i(s;X)=int_0^s g_i(t;X, earlier F_j(t;X))dt; explicit algebraic expressions reconstruct Laurent coefficients and multiply arbitrary boundary C[j,n]. X is endpoint kinematics; the ordinary path runs from fixed X0 to X, t in [0,1]. All F/K definitions are stored, not lazy DE generators. Original raw DEs also remain available.

Implemented now: compile this arithmetic to a reusable straight-line program; C++ FLINT acb evaluates K at Gauss nodes, then F via interpolatory integration matrices with endpoint accumulation across panels. Ball arithmetic bounds arithmetic only; quadrature truncation remains empirical, checked with higher node count, subdivision, higher working precision and cancellation after boundary substitution. 30-digit hard examples CF259/CF303 went from about56s to7-8s including refinements, plus3s one-time preparation. Eight CPU workers batch independent families/points, native threads=1 perworker. A GPU RTX5080 is available but 80-100 working digits make native floating point unsuitable as a drop-in.

Next I proposed reuse of local Taylor expansions for many phase-space points. Important subtlety: K(t;X) depends on target X and there may be X-dependent algebraic prefactors outside F; one cannot simply evaluate the same F at a shorter upper limit and claim the solution at a new endpoint. A general way retaining the stored formulas is to lift their arithmetic to truncated power series in a target displacement z: X=Xc+v*z, use acb_poly for all K/F arithmetic at quadrature nodes, integrate each coefficient in t, reconstruct the master Taylor coefficients including outer algebra and supplied C. Store explicit numerical Taylor coefficients, center/direction/domain and precision/error estimates; evaluate many points by Horner. This costs roughly expansion order times scalar evaluation but then amortizes. Alternative: local series of original sparse coefficient DE, evolving physical boundary vector (not full U), but that requires a separate general DE numerical backend and order closure. We do not need to build unexpanded epsilon systems or rely on AMFlow as both production and independent checker.

Please challenge this plan and recommend a concrete implementation for nearby-point reuse, especially cheap domain/truncation validation, branch issues with acb_poly principal functions, checking sufficient point accuracy after cancellations, and when this is worth implementing versus optimizing only batches. If you recommend direct DE series, explain the smallest general interface preserving required epsilon orders and exact symbolic artifact. Also identify any mathematical correctness trap in the compiled Gauss/interpolatory integration method. Keep advice practical; no broad expensive symbolic verification.

## Pro response

Your compiled evaluator and target-displacement Taylor construction are mathematically sound, subject to consistent branches and analytic dependence on the target. The main corrections are that one directional Taylor expansion only reuses points on that line, and its construction need not cost merely “order times scalar evaluation.”

I would retain the CPU evaluator as the reference implementation and add nearby-point reuse only behind a measured break-even criterion. For dense line scans, a small finite-epsilon DE Taylor recurrence is potentially substantially cheaper than differentiating the entire quadrature computation. It is worth using when the required coefficient-state closure is already available; otherwise, your proposed arithmetic-series extension is the lower-risk implementation.

Do not start a GPU port of the arbitrary-precision kernel evaluator now. The likely next gains come from avoiding repeated integration, not moving the same integration to a different processor.

This reviews the described local implementation; I have not inspected the uncommitted evaluator.

1. The Gauss/interpolatory method is valid—but recognize it as collocation

Let c
a
	​

 be Gauss nodes on [0,1], and let ℓ
a
	​

 be their Lagrange basis. Define

Q
ra
	​

=∫
0
c
r
	​

	​

ℓ
a
	​

(u)du,b
a
	​

=∫
0
1
	​

ℓ
a
	​

(u)du.

On a panel [t
0
	​

,t
0
	​

+h], the appropriate equations are

F
i
	​

(t
0
	​

+hc
r
	​

)=
F
i
	​

(t
0
	​

)+h
a
∑
	​

Q
ra
	​

g
i
	​

(t
0
	​

+hc
a
	​

;X,
F
<i
	​

(t
0
	​

+hc
a
	​

)),

followed by

F
i
	​

(t
0
	​

+h)=
F
i
	​

(t
0
	​

)+h
a
∑
	​

b
a
	​

g
i
	​

(t
0
	​

+hc
a
	​

;X,
F
<i
	​

(t
0
	​

+hc
a
	​

)).

These are Gauss collocation equations for the triangular system F
i
′
	​

=g
i
	​

(t,X,F
<i
	​

). Because the dependencies are acyclic, the stage equations can be evaluated in dependency order rather than solved as a coupled implicit system. Standard n-stage Gauss collocation has endpoint order 2n under the usual smoothness assumptions. Thus using approximate earlier F
j
	​

 at the nodes is not intrinsically an invalid nesting of quadratures. 
arXiv

The important implementation traps are the following.

Trap	Cheap protection
Resetting a nested integral at each panel	Carry every live F
i
	​

(t
0
	​

) into the next panel’s stage and endpoint formulas.
Checking the defining differential equation only at Gauss nodes	Check at a few off-grid points. The collocation residual vanishes at its own nodes by construction.
Treating node or matrix construction as machine-precision preprocessing	Construct nodes, weights, and integration matrices at adequate precision; cache by node count and precision.
Treating small ball radii as integration accuracy	Keep arithmetic radii and empirical discretization errors distinct.
Applying smooth high-order convergence expectations to singular integrands	Detect branch crossings and non-smooth or singular panel endpoints; subdivide or use the existing regularized representation.

For off-grid checks, construct the panel polynomial 
F
i
	​

(t) from the same integrated interpolant and evaluate

r
i
	​

(t)=
F
i
′
	​

(t)−g
i
	​

(t;X,
F
<i
	​

(t))

at fresh points. Use the actual kernel expressions there, not the interpolated kernel values. This is a useful detector, not automatically an error bound.

Two small controls cover much of the integration-matrix logic:

a
∑
	​

Q
ra
	​

c
a
k
	​

=
k+1
c
r
k+1
	​

	​

,0≤k<n,

and the chain F
1
′
	​

=1, F
j+1
′
	​

=F
j
	​

, whose solution is F
j
	​

(t)=t
j
/j!, using enough nodes for the chosen polynomial test.

Your empirical refinement policy is appropriate. FLINT itself distinguishes arithmetic enclosures from heuristic integration accuracy; its rigorous integration routines require additional analytic-domain bounds for the quadrature remainder. Wrapping the existing approximate nested evaluator in acb_calc_integrate would not automatically certify the inner integrals. 
Flint Library
+1

2. Target-displacement series: correct construction and its actual scope

Write

X(z)=X
c
	​

+dz.

Provided the selected branches are holomorphic in z over the patch, with sufficient uniform control along the integration path,

[z
k
]F
i
	​

(1;X(z))=∫
0
1
	​

[z
k
]g
i
	​

(t;X(z),F
<i
	​

(t;X(z)))dt.

Thus coefficientwise integration of the arithmetic series computes the desired target derivatives. Applying the same series arithmetic to all outer prefactors and reconstruction expressions is necessary.

Freeze the quadrature geometry during a jet calculation

Select a suitable panel mesh, then use that fixed mesh and fixed normalized nodes for the whole target-series calculation. You may refine and rebuild the jet, but do not silently use target-dependent panel boundaries while differentiating only the integrand.

With fixed panels, the series code differentiates the discrete collocation approximation. Its coefficients approach the true Taylor coefficients as quadrature is refined. Consequently, convergence at the center alone is insufficient: derivatives can require finer quadrature than the constant coefficient.

FLINT’s acb_poly routines implement truncated series arithmetic, but their coefficient balls do not include a numerical bound for the omitted analytic tail. Polynomial evaluation afterward encloses the computed polynomial, not automatically the original function. 
Flint Library
+1

The geometry limits reuse

A cache for

X=X
c
	​

+dz

does not evaluate arbitrary nearby points X
c
	​

+δX. They must lie on that particular line. Replacing d for each new point requires rebuilding the directional coefficients.

This makes the method attractive for line scans, repeated one-dimensional quadrature grids, and continuation along a prescribed segment. It is much less attractive for unstructured two-dimensional phase-space samples.

A general bivariate Taylor polynomial of total degree m has

2
(m+1)(m+2)
	​


coefficients per output—561 at degree 32, rather than 33. I would not implement that extension before measuring genuine reuse on one-dimensional patches.

Do not assume linear construction cost

The panel integration matrices act coefficientwise, so that part scales approximately with m+1. But multiplication, division, and transcendental series operations require polynomial operations. Their cost and memory behavior depend on degree, coefficient magnitude, and the expression DAG.

Measure

T
jet
	​

(m)

rather than extrapolating it from scalar timing. In particular, propagate constant expressions as constants, truncate at every operation, and release dead temporaries using the existing DAG ordering. Do not expand a shared expression into separate trees for each Taylor coefficient.

3. My preferred nearby-point backend when epsilon closure is available

For many points on an ordinary segment and a supplied boundary vector, the smallest useful DE backend is not a new general ODE solver. It is a sparse Taylor recurrence for a finite vector of epsilon coefficients, initialized by your existing explicit evaluator.

One-dimensional series transport of Feynman integrals from their DEs is established practice; DiffExp explicitly formulates the directional connection and the order-by-order epsilon system. It also states its assumption that negative epsilon powers in the connection have been removed before using the simple finite hierarchy. 
arXiv

Minimal interface

The backend needs only:

Input	Meaning
Ordered states (i,k)	Master index and epsilon order, including necessary internal coefficients
Sparse coefficient connection	Directional DE restricted to those states, with branch-aware numerical series evaluation
Initial values	The states at X
c
	​

, computed from the stored explicit solution with the supplied C
Geometry and accuracy	X
c
	​

,d, ordinary-point domain, branch data, Taylor degree and precision
Output selector	Requested master coefficients or their specified final combination

The exact symbolic artifact remains unchanged. The numerical Taylor coefficients are an optional cache derived from it.

The recurrence is small

Suppose the finite coefficient vector y obeys

dz
dy
	​

=B(z)y,B(z)=
a≥0
∑
	​

B
a
	​

z
a
,y(z)=
n≥0
∑
	​

y
n
	​

z
n
.

Then

y
n+1
	​

=
n+1
1
	​

a=0
∑
n
	​

B
a
	​

y
n−a
	​

.
	​


This uses sparse matrix-vector operations, not a full fundamental matrix. A nonzero A
0
	​

 does not require another homogeneous-preparation solve: the ordinary-point Taylor recurrence already handles it.

The initial vector can be larger than the set of requested outputs, but it need only be the relevant closed coefficient-state set—not every boundary-to-master matrix element.

The epsilon-order trap must be a gate

For

A(z,ϵ)=
r
∑
	​

ϵ
r
A
r
	​

(z),I(z,ϵ)=
k
∑
	​

ϵ
k
I
k
	​

(z),

one has

∂
z
	​

I
k
	​

=
r
∑
	​

A
r
	​

I
k−r
	​

.

Therefore state (i,k) depends on (j,k−r). Negative r can require higher epsilon coefficients.

For example,

I
1
′
	​

=ϵ
−1
I
2
	​


requires I
2,1
	​

 to evolve I
1,0
	​

. Truncating both masters at order zero is wrong.

Do not infer DE-state closure merely from having enough coefficients to evaluate the requested symbolic output. The symbolic formula and the raw-DE recurrence can have different internal requirements.

Use this backend when the existing planner can provide a finite closed state set, possibly after an existing epsilon rescaling. Otherwise, either derive a degree-dependent dependency set with all required initial coefficients available, or decline this route. Do not launch an open-ended order-closure exercise to support a numerical optimization.

This gives a concrete choice:

Use the small DE recurrence for ordinary, epsilon-closed segments. Use the full K/F jet when that closure is unavailable but the accepted symbolic DAG can be differentiated cheaply. Keep scalar batches as the universal fallback.

The DE route also avoids differentiating the entire path from X
0
	​

 for every patch; it needs one accurately evaluated anchor and a short local segment.

4. Branch handling: seed an analytic branch, not repeated principal values

acb_log evaluates the principal logarithm, and the series logarithm uses the logarithm of the constant coefficient to select its integration constant. General series powers are implemented through an exponential of a logarithm. These are branch choices, not continuation instructions supplied by the library. 
Flint Library
+1

A robust local wrapper can preserve a branch using the value already selected at the center. If q(0)=q
0
	​


=0, write

δ(z)=
q
0
	​

q(z)−q
0
	​

	​

.

Then use

log
chosen
	​

q(z)=L
0
	​

+log(1+δ(z)),

where L
0
	​

 is the continued logarithm at the center, and

chosen
q(z)
	​

=s
0
	​

1+δ(z)
	​

,s
0
2
	​

=q
0
	​

.

The second factors are expanded about 1. A nonprincipal root sign multiplies the whole square-root series, not only its constant term.

Similarly, inverse hyperbolic functions can be reconstructed from their derivative series with the correctly continued constant term. For instance,

dz
d
	​

atanhq(z)=
1−q(z)
2
q
′
(z)
	​

.

The derivative alone does not choose the additive branch constant.

This approach can cross an artificial principal cut locally without crossing a genuine zero or branch point. It must nevertheless match the branch of the stored physical solution. A DE residual can pass for the wrong branch or wrong homogeneous constant.

For the full K/F jet, the branch anchors are needed along the original t-path, not just at t=1. In particular, independently choosing principal values at every quadrature node can introduce an artificial discontinuity.

A nearby DE segment must preserve the continuation class

The path

X
0
	​

⟶X
c
	​

⟶X

must represent the same continuation as the stored evaluation at X. Inside a sufficiently small nonsingular patch attached to the anchor, this is the natural local continuation. Do not silently identify different paths winding around a singular locus.

Neither numerical reuse route should bridge an unhandled physical threshold merely because a polynomial evaluates to a finite number there.

5. Cheap domain and truncation validation

Separate two questions:

Is the function analytic on the proposed patch with the selected branch?

Is the chosen degree accurate enough there?

An analytic patch can still require many terms; agreement of a few truncations does not establish analyticity.

Domain checks

For a DE-based segment, restrict the connection denominators and radicands to

X
c
	​

+dz.

Numerically locate the relevant complex zeros and poles, or use existing ball-based exclusion checks. Complex singularities matter even when every requested point is real. Apparent singularities may make this conservative, which is acceptable for selecting a numerical patch. DiffExp uses these restricted singularities to guide segment sizes and rescales the line parameter to control coefficient growth. 
arXiv

For the full K/F jet, the condition is stronger: the representation must remain valid throughout

t∈[0,1],∣z∣≤r.

Checking only endpoint prefactors is insufficient. A denominator or branch argument can encounter a singularity at an interior t as the target moves.

A bounded approach is to reuse the scalar mesh, inspect branch-sensitive arguments on panel intervals over the proposed target patch, and shrink or refuse the patch when exclusion is inconclusive. Successful interval exclusion is meaningful; sampling alone remains a heuristic.

Scale the local parameter before generating coefficients. For example, choose z=ρu so that accepted queries have modest ∣u∣. This avoids large coefficients caused merely by dimensional units or a tiny physical radius.

Truncation checks

For an initial implementation, I recommend:

Build to a bounded degree, such as 32, retaining additional terms or comparing with a higher degree when needed.

Examine the weighted final coefficient contributions a
k
	​

u
k
, using several tail terms rather than the last nonzero term alone.

Validate at the outermost intended query points and one interior point using the scalar evaluator with stricter quadrature settings.

Shrink/recenter when convergence stalls rather than indefinitely increasing degree or precision.

These tests should be applied after reconstruction and the chosen boundary substitution. The same Taylor degree need not serve every master or every final combination.

A rigorous tail estimate would require additional information. For example, if

∣f(z)∣≤M
R
	​

(∣z∣=R)

is proved and r<R, Cauchy’s estimate gives

∣f(z)−P
m
	​

(z)∣≤M
R
	​

1−r/R
(r/R)
m+1
	​

,∣z∣≤r.

Observed coefficient decay does not by itself supply that M
R
	​

. Keep the initial cache honestly labeled as empirically validated unless you actually compute such a bound.

One especially useful inexpensive cross-check is the degree-one target jet:

dz
dI
k
	​

(X
c
	​

+dz)
	​

	​

z=0
	​

=
?
[ϵ
k
]
μ
∑
	​

d
μ
	​

A
μ
	​

(X
c
	​

,ϵ)I(X
c
	​

,ϵ).

It checks target dependence, outer prefactors, and the raw-DE relation without finite-difference step-size tuning.

6. Accuracy must be attached to the final requested quantity

Continue your practice of checking cancellation after substituting C. There is no uniform relative-accuracy promise for arbitrary C: some choices can make a master or hard-function combination arbitrarily small.

For the actual requested quantity H, use a mixed criterion

E
total
	​

≤atol+rtol∣
H
∣,

with separately tracked components:

E
total
	​

=E
arithmetic/input
	​

+E
quadrature
est
	​

+E
Taylor
est
	​

.

The last two are estimates under your present methodology, not rigorous ball radii.

For a final linear combination, a useful precision diagnostic is

κ
sum
	​

=
∣∑
α
	​

c
α
	​

I
α
	​

∣
∑
α
	​

∣c
α
	​

I
α
	​

∣
	​

.

Roughly log
10
	​

κ
sum
	​

 extra decimal digits can be lost in that sum. This helps choose working precision, but does not replace refinement: quadrature errors also need sufficient absolute accuracy before cancellation.

For a Taylor cache with estimated coefficient errors e
k
	​

, propagate them at a query using

E
coeff
	​

(u)≤
k
∑
	​

e
k
	​

∣u∣
k
,

then add the Taylor-tail estimate and evaluation rounding. A cache that meets tolerance near its center need not meet it near its boundary.

Also ensure that endpoint kinematics and numerical boundary constants arrive at sufficient precision. Increasing acb precision cannot recover digits discarded by an earlier conversion through machine doubles.

If Taylor coefficients are stored after boundary substitution, the cache belongs to that particular boundary vector. Changing C requires rebuilding it or retaining the corresponding linear maps. The underlying symbolic solutions can remain fully boundary-parameterized.

7. When reuse pays—and where the GPU fits

Let T
s
	​

 be a scalar evaluation time, T
b
	​

 cache construction, T
v
	​

 validation, and T
h
	​

 a cached query. The break-even count is

N>
T
s
	​

−T
h
	​

T
b
	​

+T
v
	​

	​

.
	​


Use the number of expected queries inside the same valid patch, with the same direction and boundary binding, not the total phase-space sample count.

For example, if a jet costs 25 scalar evaluations and validation costs three more, it needs about 28 usable queries just to break even when Horner cost is negligible. Compare both wall time and CPU work under the same eight-core allocation: 32 independent scalar evaluations can run concurrently, whereas a single expensive cache build may have greater initial latency.

Before adding more numerical machinery, profile the existing evaluator into kernel arithmetic, integration-matrix application, reconstruction, refinement, and allocation. The low-risk CPU optimizations are persistent compiled plans, precision-keyed node/matrix caches, constant-expression hoisting, dead-temporary reuse, and native batches with one thread per worker.

GPU recommendation

At 80–100 working decimal digits, approximately 266–333 significand bits are needed before additional guards. Native double precision is not a replacement, and even a well-conditioned 30-digit final Horner evaluation exceeds ordinary double precision. NVIDIA’s floating-point documentation also emphasizes that operation ordering and cancellation affect results even when individual operations obey IEEE arithmetic. 
NVIDIA Docs

GPU multiprecision is possible, but it would require a suitable arithmetic and transcendental-function implementation. NVIDIA’s CGBN, for example, supplies fixed-size multiprecision integer arithmetic, not an acb replacement with complex logarithms, roots, and ball propagation. 
GitHub

For this workload, defer GPU implementation. Reconsider it only after profiling shows that very large, homogeneous batches of an already simplified operation—such as multiprecision polynomial evaluation—dominate runtime. Low-precision GPU screening can guide scheduling, but must not determine the requested high-precision result or its branch.

Recommended next decision

Keep scalar CPU batches as the default. Run one bounded nearby-point experiment on an actual dense line workload, measuring construction, validation, accepted patch size, and total query throughput.

Use the finite-epsilon DE recurrence when the existing planner supplies its closed state vector without substantial new machinery. Otherwise, test your acb_poly lift with a fixed mesh and bounded degree. Do not generalize it to arbitrary multidimensional neighborhoods or build a GPU arithmetic backend before that experiment demonstrates useful amortization.

The highest-value additions are off-grid collocation residuals, branch-anchored series functions, and final-output error accounting. They protect both reuse strategies without requiring broad symbolic verification or changing the stored exact solutions.
