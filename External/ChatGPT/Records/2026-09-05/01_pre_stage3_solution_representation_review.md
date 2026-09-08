# Pre-stage-3 solution representation review

New ChatGPT Pro conversation requested by the user. Model verified by the bridge: gpt-6-pro.

Conversation: https://chatgpt.com/c/6a9c64ec-3cc4-83e8-b40c-9b568241fd3b

The response below is the retrieved plain-text rendering; displayed equations and source links may lose formatting. The local assessment independently checks the relevant primary sources.

## Question

Please independently challenge the current design of FeynFacet and recommend what should count as an actually solved multivariate master-integral differential equation up to integration constants, stored in realistic disk/memory size. This is a NEW conversation requested by the user; do not assume any earlier plan is correct. Use standard mathematics and amplitude terminology, with definitions, not workflow nicknames.

User's question: How far are we from pre-stage 3 (DE solved up to constants)? What format genuinely contains the solution, rather than a lazy generator? Think outside the current plan and compare how amplitude papers publish results.

Repository: https://github.com/CongyueZhang2002/factorization-and-loops (check access before claiming to have read it). Working tree has a newer terminology correction not yet committed. Facts verified locally:
- Package solves NNLO cut master integrals in two kinematic variables by DEs. It has epsilon-form diagonal/off-diagonal transformations, square-root rationalizations or algebraic coefficients, formal iterated integrals, and boundary-mode matching.
- Fresh V2 files include family dlog epsilon forms for CF269 (~175 KB text) and CF48 (~670 KB text). CF259/CF265 regeneration is unfinished; no current family has a demonstrated complete portable solution to all requested epsilon orders up to kinematics-independent constants.
- CF303 is the difficult 45-master family. In the preserved V2 directory: a reconstructed local matching map (~1.59 MB), tangential boundary evolution (~1.19 MB), and a normal-direction coefficient operator (~1.38 MB). There is also a compressed finite-field normal-action sample (~100 KB). These files are intermediates, not evidence of a complete characteristic-zero elliptic solution.
- The physical soft boundary is positive dimensional: normal Frobenius coefficients c(p,eps) satisfy their own tangential DE. Leaving them arbitrary functions is not 'up to constants'. Current approach insists on physical-boundary normalization and tangential/normal composition before calling stage 2 complete.
- Retained historical sizes: CF299 sparse GPL record 121 KB, CF407 2.6 MB; CF48 expanded requested-output result ~636 MB vs exact finite-state representation 59 MiB; CF303 direct exact final-row recurrence grew to 36 GiB and was terminated after ~4h. Later finite-field circuit evaluation took ~76s at ~125MiB, but that is not a stored solved expression.
- Current MasterIntegralSolution constructor can still return factorized coefficient operators without enumerating final coefficients, despite 'solution' naming. The user rejects this as completion.
- Older notes demanded sums of explicit iterated integrals with fully specified kernels, paths, branches, and a table of unknown physical boundary quantities. That requirement conflated a boundary stratum with constants, later corrected.
- All current wording must separate graph SCC blocks from differential irreducibility, dlog coefficients from general elliptic kernel coefficients, finite-field evidence from characteristic-zero reconstruction, and original basis from physical branch choices.

Please analyze:
1. Is physical-boundary normalization unnecessarily entangling stage 2 with stage 3? Could an ordinary Euclidean/base point and c(eps)=I(x0,eps) provide a rigorous stage-2 deliverable, with singular-boundary matching as a separate map? Discuss utility for stage 3 and what this does NOT solve.
2. Compare explicit sparse Chen-word sums; master integrals in a finite shared function basis with explicit integral definitions; finite arithmetic expressions with shared subexpressions; finite products of already-solved path-segment matrices; finite-state/lazy coefficient generators; and truncated Taylor/Frobenius series. Draw a sharp boundary between an actual solved analytic expression and merely repackaging the DE.
3. Recommend a concrete mathematical formula and portable file schema that contains every requested epsilon coefficient, is linear in genuinely constant initial data, and needs no coefficient reconstruction or DE solving on read. Numerical evaluation of explicitly defined special functions is of course allowed.
4. For CF303, can an explicit finite variation-of-constants quadrature using known homogeneous solutions be a legitimate compact answer even without a global dlog epsilon form? What are the pitfalls with elliptic kernels, path regularization, epsilon poles, and all independent variable equations?
5. Explain whether independence/minimality of a function basis is required before publishing a finite spanning set, and whether shuffle reduction should be a later optimization.
6. Give a realistic short sequence of decisive experiments, with measurable size/completeness checks, not speculative percentage completion or an unsupported ETA.
7. Cite concrete primary amplitude papers AND, when possible, ancillary-file repositories whose storage conventions support the recommendation. Distinguish symbolic data, initial values, and numerical evaluators.

Please disagree with the premises where warranted. No vague 'lazy but exact equals solved' argument, no promise that compression solves a remaining mathematical obstruction. Aim for a detailed but focused critical review.


## Pro response

Assessment

On the evidence you supplied, no current family has yet demonstrated the requested “DE solved up to constants” deliverable. But I would change the completion criterion in two directions: remove mandatory physical-boundary normalization, and require a stored expression for every requested Laurent coefficient—not an operator that can construct those coefficients.

I checked repository access and inspected the pushed constructor and coefficient-construction code on codex/scientific-terminology-and-math-fixes, at e8c62cce…. The constructor explicitly describes retaining a graded coefficient circuit or separate normal and tangential sequence-indexed operators. The coefficient-extraction routine subsequently constructs the requested coefficient map. That supports your distinction between the existing object and a coefficient-complete result. This is an inspection of pushed code, not your uncommitted correction; the artifact sizes and local completion status below are taken from your supplied facts, not remeasured.

One qualification matters immediately: not expanding a Cartesian product of words is not, by itself, incompleteness. A product of already-solved functions can be a perfectly explicit answer. The defect is leaving coefficient construction unresolved, not leaving ordinary multiplication undistributed.

My recommendation is therefore:

An explicit Laurent solution on a specified analytic domain, expressed as a finite linear map from constant initial-data coefficients to finite expressions in explicitly defined functions. Physical-boundary matching is a separate connection problem.

1. Ordinary-point normalization is a legitimate stage-2 endpoint

Let X=(x,y), and write the closed master-integral system as

dI(X,ϵ)=A(X,ϵ)I(X,ϵ),A=A
x
	​

dx+A
y
	​

dy.

Assume the connection is flat,

dA−A∧A=0,

on the domain under consideration.

Choose a nonsingular point X
0
	​

, an analytic branch, and a simply connected domain on the relevant algebraic covering—or specify continuation paths and their homotopy classes. The normalized fundamental matrix satisfies

dF=AF,F(X
0
	​

,X
0
	​

;ϵ)=1.

Then

I(X,ϵ)=F(X,X
0
	​

;ϵ)c(ϵ),c(ϵ)=I(X
0
	​

,ϵ),dc=0.
	​


This is exactly “up to integration constants.” It is not necessary that X
0
	​

 be a physical soft limit. However, writing this equation with F defined only as a path-ordered exponential establishes the problem’s structure; it does not satisfy your requested stored-expression criterion.

Use an ordinary point, not necessarily a Euclidean point

For cut integrals, “choose a Euclidean point” needs care. A physical phase-space integral with positive-energy constraints is not automatically the same object as the analytically continued cut function evaluated outside its real support. In particular, “there is no real phase space here, so the boundary value is zero” is not a valid way to initialize that analytic continuation. Cuts can satisfy the same differential equations while selecting different boundary data. 
arXiv

An ordinary point inside a suitable physical chamber is equally legitimate. The essential conditions are nonsingularity, well-defined normalization, and a specified analytic branch.

A particularly useful alternative to the present boundary composition is a single endpoint-dependent path

γ
X
	​

(t)=X
0
	​

+t(X−X
0
	​

),0≤t≤1,

on a star-shaped nonsingular patch. Algebraic roots are continued along this path. There is no mathematical requirement to rationalize every root globally or to introduce separate tangential and normal paths before obtaining an explicit iterated-integral answer.

This does not magically cover the whole physical region. A solution on one declared patch is a solution there; broader coverage requires specified continuation paths or additional patches.

Why the positive-dimensional boundary is a different problem

Suppose q=0 is the soft boundary and p parametrizes it. Normal Frobenius analysis produces coefficients c
∂
	​

(p,ϵ). If

∂
p
	​

c
∂
	​

(p,ϵ)=B
∂
	​

(p,ϵ)c
∂
	​

(p,ϵ),

then the actual constants are introduced only after solving

c
∂
	​

(p,ϵ)=V
∂
	​

(p,p
∗
	​

;ϵ)b(ϵ).

Thus your correction is essential: an arbitrary c
∂
	​

(p,ϵ) is not a constant.

But this does not imply that the entire boundary-normalized construction must precede ordinary-point completion. If F
0
	​

 and F
∂
	​

 are fully solved fundamental matrices on an overlap, then

F
∂
	​

(X,ϵ)=F
0
	​

(X,ϵ)C(ϵ),dC=0.

The connection matrix C is separate from the bulk solution. When only a physically admissible subset of modes is retained, the corresponding map may be rectangular rather than an invertible fundamental-matrix connection.

Moreover, stage 3 need not expand the entire normal–tangential product into every bulk output. Enough independent asymptotic information can instead be imposed directly as linear constraints on the ordinary-point constants. Which asymptotic coefficients suffice is a rank question, not a requirement to materialize every boundary-series term.

What this helps—and what it does not solve

It separates construction of the kinematic functions from determination of the physical solution. It also permits independent numerical checks, reuse under different boundary conditions, and boundary matching without repeatedly rewriting the bulk expressions.

The tradeoff is real: generic-point constants may be harder to determine analytically than soft-limit constants, and useful vanishing modes become less manifest. Ordinary normalization does not determine physical constants, physical support, causal continuation, or endpoint distributions. Numerical initial values would produce numerical solutions, not the final exact boundary data your project seeks.

Physical-boundary normalization should remain an available advantageous normalization, not a mandatory definition of “DE solved up to constants.”

2. The boundary between a solution and a generator

There is no representation-independent mathematical distinction between “an implicitly defined function” and “a named special function.” For this project, the distinction should therefore be an explicit deliverable contract.

I would accept a finite expression whose leaves are rational/algebraic functions, known periods or special functions, and fully specified finite quadratures. Dependencies may be shared, but must terminate without invoking an unknown master, solving a differential equation, generating additional Laurent coefficients, or reconstructing coefficients from samples.

Representation	Accept as completed?	Decisive condition
Explicit sparse Chen-word sums	Yes	Every requested coefficient, word, kernel, path, and constant multiplier is supplied.
Masters in a finite shared function set	Yes	Every function has an explicit definition; every master coefficient is supplied.
Finite arithmetic expressions with shared subexpressions	Yes	A fixed finite expression graph exists for every requested coefficient.
Products of already-solved path-segment matrices	Yes, conditionally	Segment entries are explicit functions, and the required Laurent-order combinations are already specified.
Finite-state or lazy coefficient generators	No, as currently described	They still require constructing words, coefficient maps, or Laurent coefficients.
Truncated Taylor/Frobenius expansions in kinematics	Not as the requested exact kinematic answer	They are local approximations or asymptotic data unless termination or an exact remainder representation is established.
Shared arithmetic is not laziness

For two solved path segments, an explicit coefficient can be stored as

U
[2]
=U
2
[2]
	​

U
1
[0]
	​

+U
2
[1]
	​

U
1
[1]
	​

+U
2
[0]
	​

U
1
[2]
	​

.

There is no reason to distribute every matrix entry into every Chen word. Fixed matrix contractions and multiplication of known functions are ordinary arithmetic.

By contrast, storing

[ϵ
2
](U
2
	​

(ϵ)U
1
	​

(ϵ))

with instructions to generate either segment’s coefficients does not meet your requirement.

The distinction is particularly important for the current constructor: its factors are described as coefficient operators, not necessarily matrices whose requested coefficient entries have already been resolved. Its mathematical status cannot be upgraded merely by placing those factors inside an object called MasterIntegralSolution.

Explicit quadratures must not conceal the original problem

A definition such as

Φ(X)=∫
γ
X
	​

	​

ω
1
	​

∫ω
2
	​

K(m)

can be complete when the kernels, period, nesting, endpoints, and branches are explicit.

The following are not equivalent deliverables:

“Φ is the solution of this remaining DE.”

“Φ is the original dimensionally regulated master integral under a new name.”

An integral equation containing Φ itself.

A recurrence whose requested outputs have not been constructed.

Numerical quadrature may internally use recursion or adaptive subdivision. That is evaluation of an already-defined function, not reconstruction of the analytic coefficient.

Likewise, truncating in ϵ is your requested approximation; truncating additionally in x or y changes the answer’s scope.

3. A concrete mathematical deliverable and file schema

Let

D={(i,n):requested master i at Laurent order n}

and let S contain the finitely many required initial-data slots

c
a,m
	​

=[ϵ
m
]I
a
	​

(X
0
	​

,ϵ).

The exported result should contain

I
i
[n]
	​

(X)=
(a,m)∈S
∑
	​

c
a,m
	​

E
i,n;a,m
	​

(X),(i,n)∈D.
	​


Every E
i,n;a,m
	​

 must be an already-stored finite expression. Conceptually, one may write

E
i,n;a,m
	​

(X)=
α
∑
	​

R
i,n;a,m;α
	​

(X)Φ
α
	​

(X),

with rational/algebraic coefficients and a finite shared function set. Products of functions may remain products in the stored expression; this formula should not impose a global shuffle expansion.

The Φ
α
	​

 must not conceal any of the unknown c
a,m
	​

. Known normalization constants may occur in function definitions, but unknown physical initial data remain visibly linear.

For a genuine dlog ϵ-form

Suppose

dJ=ϵ
ℓ
∑
	​

M
ℓ
	​

ω
ℓ
	​

J,ω
ℓ
	​

=dlogW
ℓ
	​

,

where the M
ℓ
	​

 are independent of both kinematics and ϵ. The normalized transport coefficient is

U
[k]
(X,X
0
	​

)=
ℓ
1
	​

,…,ℓ
k
	​

∑
	​

M
ℓ
1
	​

	​

⋯M
ℓ
k
	​

	​

C
ℓ
1
	​

⋯ℓ
k
	​

	​

(γ
X
	​

).

Writing γ
X
∗
	​

ω
ℓ
	​

=f
ℓ
	​

(t;X)dt, define

C
ℓ
1
	​

⋯ℓ
k
	​

	​

(γ
X
	​

)=∫
0<t
k
	​

<⋯<t
1
	​

<1
	​

j=1
∏
k
	​

f
ℓ
j
	​

	​

(t
j
	​

;X)dt
1
	​

⋯dt
k
	​

.

This establishes finite explicit quadratures at every fixed order. The export must contain the actual requested combinations, not merely this general summation rule. The iterated-integral construction from an ϵ-form is standard; the stronger coefficient-complete storage requirement is the additional contract proposed here. 
arXiv

For an original basis I=TJ,

F
I
	​

(X,X
0
	​

;ϵ)=T(X,ϵ)U(X,X
0
	​

;ϵ)T(X
0
	​

,ϵ)
−1
.

All required Laurent convolutions with these transformations must be included before export. The required depth follows from their valuations, the initial-data valuations, and the eventual reduction coefficients—not simply from “NNLO means weight four.”

Suggested portable layout

These are proposed filenames, not claims about existing repository artifacts.

File	Required contents
manifest.json	Master definitions and normalization; variables and fixed parameters; requested (i,n) pairs; constant slots and assumed Laurent valuations; declared analytic domain.
geometry.json	Base point; root-defining equations and initial branches; path families; continuation prescriptions; elliptic curves and cycle conventions where needed.
kernels.jsonl	Explicit differential forms or path pullbacks. General period-valued kernels must not be mislabeled as dlogs.
functions.jsonl	Actual finite words or finite nested-integral definitions, with all dependencies resolved.
expressions.jsonl	A directed acyclic graph of exact arithmetic and calls to the explicitly defined functions. Shared subexpressions are stored once.
coefficients.jsonl	One record for every requested (i,n), mapping constant slots to expression roots; zero coefficients are explicit.
checks.json	Normalization and differential-equation checks, applicable orders and domains, and clearly distinguished numerical/modular checks.

Use exact integers and rationals, documented algebraic extensions, and a restricted expression grammar—not executable package state. A compressed text archive with independently loadable chunks is sufficient. A Mathematica or Maple companion representation is useful, but the mathematical definitions should remain understandable without that program.

Crucially, the expression grammar should have no coefficient-generator, DE-solver, path-ordered-exponential, or reconstruction node. A reader may traverse an existing expression graph; it must not discover a new one.

A boundary connection matrix and a table of physical constants should be separate optional files at this stage. Also keep basis identification separate from analytic branch identification: an original-basis transformation does not itself specify the physical continuation.

4. CF303: finite variation-of-constants quadratures can be the answer

Yes. A global dlog ϵ-form is not necessary. For CF303, I would explicitly test whether it is being pursued beyond what the mathematical deliverable requires.

Suppose the regulator expansion and a valid block ordering give

dJ
b
[n]
	​

=A
bb
[0]
	​

J
b
[n]
	​

+f
b,n
	​

,

where f
b,n
	​

 is already explicit in earlier regulator orders and solved lower blocks.

If an invertible homogeneous fundamental matrix is known,

dH
b
	​

=A
bb
[0]
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

)=1,

then

J
b
[n]
	​

(X)=H
b
	​

(X)[d
b,n
	​

+∫
γ
X
	​

	​

H
b
−1
	​

f
b,n
	​

].
	​


Once the known source expressions are inserted or referenced through a finite acyclic function graph, this is a genuine finite quadrature solution. It need not be converted into a particular named elliptic-polylogarithm class.

There is a direct amplitude-integral precedent: Adams, Chaubey, and Weinzierl solve the massive planar double-box system in a form

dJ=(A
(0)
+ϵA
(1)
)J

with A
(0)
 strictly lower triangular, rather than insisting on eliminating it. Their kernels involve three elliptic curves, and their ancillary result contains explicit master-integral expressions. 
arXiv
+1

The actual conditions that must be checked

The homogeneous solutions must really be known. For a second-order elliptic equation, one solution or one maximal-cut contour is not automatically a full fundamental system. The independent periods, normalization, and nonvanishing Wronskian must be specified. Maximal cuts are a powerful source of homogeneous solutions, but do not by themselves complete all inhomogeneous integrations. 
arXiv

Both independent-variable equations must be satisfied. A homogeneous solution in q with arbitrary p-dependent coefficients is not the needed H
b
	​

. Alternatively, already-solved coordinate segments can be composed, with flatness and the junction data establishing the second equation. Solving one fixed slice alone does not suffice.

For a fully multivariate variation-of-constants construction, the transformed source H
b
−1
	​

f
b,n
	​

 must obey the corresponding compatibility condition. Individual iterated integrals need not be homotopy invariant; the correct complete combination must be. This distinction appears explicitly in elliptic top-pair amplitude calculations. 
arXiv

The regulator ordering must terminate. The formula assumes that the source depends only on already-resolved quantities. Negative powers of ϵ in the connection can invalidate that assumption unless a gauge or valuation analysis controls them. For example,

∂
x
	​

f=ϵ
−1
f

has an essential exponential dependence, not a finite-lower-bounded Laurent fundamental solution for arbitrary initial data. This is a mathematical warning, not a claim that CF303 has that behavior.

The kernels and regularization must be explicit. Elliptic curves, cycles, root branches, period conventions, and any endpoint subtraction must be provided. A divergent integral does not become a finite special function merely by adding “regularized” to its name. Tangential regularization requires a local coordinate, tangent/scale convention, and specified logarithm branch.

The coefficients must exist in characteristic zero. Finite-field samples can test rational or algebraic identities of an already specified formula. They neither supply the missing reconstructed formula nor determine analytic periods and branches.

Finally, terminology must not prejudge the mathematics. A graph strongly connected component is a property of the nonzero-entry graph in a chosen basis. Differential irreducibility means absence of a proper invariant differential submodule over a stated field. Neither a graph block nor a count of square roots establishes ellipticity. Even algebraic dlog representations do not generally guarantee multiple polylogarithms, as Brown and Duhr demonstrate. 
arXiv

Thus the decisive CF303 question is not “can we compress the normal operator?” It is:

Can every required homogeneous block and inhomogeneous coefficient be supplied as a finite characteristic-zero expression in explicit kernels and known functions, compatible with both variable equations?

Your listed intermediates and finite-field timing do not yet establish that.

5. Independence and shuffle reduction are not prerequisites

A finite spanning set is enough. Its functions need not be linearly independent, algebraically independent, or minimal.

Call it a function basis only with the appropriate qualification: independence over Q, over a rational-function field, and algebraic independence are different claims. None is necessary merely to publish exact expressions in a finite explicitly defined set.

I would initially remove identical definitions and share common subexpressions. Shuffle reduction, argument identities, and more ambitious basis minimization should normally be later optimizations. Targeted identities can be used earlier when measurements show a real benefit; they should not become a blanket completion gate.

This is not merely permissive bookkeeping. Badger, Chaubey, Hartanto, and Marzucca publish elliptic finite remainders while identifying further functional relations and more robust continuation over the entire physical region as subsequent work. Their example separates an analytic result from a fully minimized function space and a production-quality evaluator. 
arXiv

A symbol alone would still be insufficient: it can omit constants and lower-weight products that your coefficient-complete answer must retain.

6. What concrete amplitude publications actually store

The most useful precedent is separation of symbolic expressions, function definitions, initial values, and numerical evaluation—not a requirement that every paper print expanded GPL sums.

Abreu et al., five-parton QCD amplitudes

In Analytic Form of the Planar Two-Loop Five-Parton Scattering Amplitudes in QCD, arXiv:1904.00945, the remainders are distributed through rational coefficient functions r
i
	​

, a matrix M
ij
	​

, and pentagon functions h
j
	​

. This is a finite shared-function decomposition, not a demand to substitute and expand every transcendental function. 
arXiv

The arXiv ancillary index separately lists TwoLoopRemainders/*.txt, Numerics/InitialConditions.m, Numerics/FunctionValues.m, Numerics/EvaluateFunctionBasis.m, and assembly tools. The initial-value files and evaluator are not substitutes for the symbolic remainder files. 
arXiv

Chicherin and Sotnikov, massless pentagon functions

Pentagon Functions for Scattering of Five Massless Particles, arXiv:2009.07803, documents MI_in_G.m, GtoF_weight*.m, separate constants and initial-value files, and explicit function definitions—including one-fold representations at higher weights. The authors deliberately make the symbolic data understandable as plain text outside the Mathematica package. The associated repository is PentagonMI on GitLab. 
arXiv
+2
arXiv
+2

This supports sharing intermediate function combinations across many masters and treating the evaluator as a separate component.

Chicherin, Sotnikov, and Zoia, one-mass pentagon functions

Pentagon Functions for One-Mass Planar Scattering Amplitudes, arXiv:2110.10111, makes the separation especially explicit:

mi2pfuncs.m gives master-to-function expressions; pfuncs_iterated_integrals.m defines the functions through Chen integrals and constants; pfuncs_expressions.m supplies evaluation-oriented representations, including one-fold integrals at weights three and four. The ancillary repository is PentagonFunctions-m1-datafiles. 
arXiv
+1

That is close to the proposed FeynFacet layout.

Adams, Chaubey, and Weinzierl, elliptic double-box masters

Analytic results for the planar double box integral relevant to top-pair production with a closed top loop, arXiv:1806.04981, describes an ASCII ancillary file in Maple syntax containing
I_basis, U, Uinv, A, integration_kernels, and J.

The important distinction is that A contains the differential system, whereas J contains the master-integral results through ϵ
4
 in iterated integrals, including boundary constants. Having the former is not presented as a replacement for distributing the latter. 
arXiv

These are documented storage conventions, not size predictions for FeynFacet. In particular, a published physical amplitude or boundary-fixed master solution can be much smaller than a fundamental matrix acting on arbitrary initial data. Physical constraints can remove entire combinations. Their compactness does not prove that a generic 45-master solution will be comparably small.

7. Decisive experiments and an honest distance-to-completion assessment

I would replace percentage estimates with the following sequence.

Experiment 1: complete CF269 at an ordinary point

Freeze the requested original-master/order table, including the depth implied by all basis transformations. Choose a nonsingular base point and a declared two-dimensional domain.

Export every requested coefficient using explicit functions and shared arithmetic, without requiring physical-boundary normalization.

Acceptance requires zero missing outputs, zero unresolved function definitions, zero arbitrary kinematic “constants,” and no coefficient-construction call during a cold read. Check base-point normalization and both differential equations through the required orders. Verification can exploit the defining differential identities of the functions; it need not flatten every expression into one enormous symbolic sum.

This tests completion rather than another intermediate representation.

Experiment 2: compare three completed CF48 representations

For exactly the same requested coefficients, compare sparse Chen sums, shared-function arithmetic graphs, and coefficient-resolved products of solved path matrices.

Measure compressed and uncompressed bytes, distinct functions and expression nodes, peak construction memory, cold-reader memory, and evaluation cost. Compare representations at nonsingular points using several initial-data vectors, not just one physical combination that might hide missing columns.

Set a resource target before running—for example, a 1 GiB archive and 4 GiB reader-memory target per family. These are proposed engineering thresholds, not forecasts that every family will fit.

Your historical 636 MB CF48 text is not inherently unrealistic disk storage. Its construction or parsing may be problematic, but that is a separate issue. Conversely, the 59 MiB finite-state object does not win this comparison unless it supplies the same completed mathematical outputs.

Experiment 3: resolve CF303’s mathematical uncertainty before another large expansion

Select the hardest unresolved differential block, not merely the largest graph component.

Produce its characteristic-zero homogeneous system of solutions, then explicit variation-of-constants expressions through the first nontrivial required orders. Verify the second variable equation and the regulator dependency ordering. Record size and memory growth by order.

The outcome should identify one of two different situations: either the finite quadrature construction exists and expression storage is the remaining problem, or a specific homogeneous solution, kernel definition, regulator filtration, or compatibility step remains missing. The 36 GiB terminated recurrence distinguishes neither situation by itself.

Only then extend the same construction to all requested CF303 outputs.

Experiment 4: attach physical-boundary information as a separate map

Using a completed ordinary-point solution, impose enough independent soft-limit data to determine the required connection or constant constraints. Check the predicted powers and logarithms, and verify that any claimed connection matrix is independent of both running kinematic variables.

A separately solved tangential boundary system may help. It should not be mandatory when the necessary constant constraints can be obtained more directly from the ordinary-point solution.

Where this leaves each family

For CF269 and CF48, complete characteristic-zero strict ϵ-forms would already guarantee finite Chen-integral expressions at every fixed order. No additional special-function discovery would be needed merely to write those quadratures. What remains undemonstrated is the complete requested-coefficient export, with correct Laurent depth, original-basis dependence, domain, and constant data. That is a concrete next test, not evidence that it will automatically be small.

For CF259 and CF265, unfinished regeneration prevents that conclusion from being applied to the current files.

For CF303, the supplied evidence does not yet distinguish a remaining analytic construction problem from an expression-representation problem. The compact intermediates and fast finite-field evaluation are useful, but do not settle it.

The endpoint should be neither “everything expanded” nor “a compact program that knows how to solve it.” It should be every requested coefficient already present, built from explicitly defined functions, linear in genuine constants, readable without FeynFacet’s solving machinery, and valid on a stated analytic domain. Physical-boundary normalization and further compression should improve that result—not define whether it exists.
