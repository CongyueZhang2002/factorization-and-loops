# CF48 Tool Followup

## Question

Follow-up with measured results from the exact CF48 connection.

I compiled current C++ FUCHSIA and exported both exact 27x27 connection matrices after the rational chart. The attached denominator census is from those matrices. It contains no residual algebraic powers, but it has repeated nonlinear factors: two in the p equation with active-variable degree 2 and denominator power 3, and six in the s equation with active-variable degree 2 and powers 3 or 4. Even `fuchsia show -x p` aborts at row 8 with `pfmatrix(): can't solve equations of 2nd degree or higher`. Thus the documented missing feature is encountered before reduction starts.

I then tested CANONICA 1.0.3 `RecursivelyTransformSectors` on exact leading block prefixes, with the declared 20-sector partition and zero numerator/denominator ansatz degrees. The measured results are:

- sectors 1--2, dimension 2: transformation returned in 0.35 s;
- sectors 1--5, dimension 6: transformation returned in 0.61 s;
- sectors 1--10, dimension 14: transformation returned in 15.08 s;
- sectors 1--12, dimension 16: transformation returned in 13.57 s;
- sectors 1--13, dimension 18: timed out at 180.03 s;
- sectors 1--15, dimension 20: timed out at 300.04 s;
- all 20 sectors, dimension 27: timed out at 300.04 s.

Sector 13 is a two-master block with non-epsilon couplings from sectors 1,2,3,4,5,7,9,10,11,12. It is the first sharp cost jump. The package clearly represents the problem correctly through sector 12; the bottleneck is the exact rational linear solve for this densely coupled new sector.

Given these measurements, please answer decisively:

1. Is the best next experiment to use CANONICA's continuation arguments so sectors 1--12 are frozen and solve only sector 13, or does `RecursivelyTransformSectors` already do essentially that internally?
2. Which low-level CANONICA object/function exposes the sector-13 linear ansatz equations before Mathematica solves them, so we can measure unknown count/rank and export that linear system?
3. Is there an existing exact sparse/modular linear solver that can replace only CANONICA's symbolic solve without reimplementing its ansatz construction: FiniteFlow, FireFly, SpaSM, Fermat, or another current tool? Give the most concrete integration route you know.
4. Would Libra's `FuchsifyDependentBlocks` or `BlockTriangularToFuchsian` be expected to avoid this same linear system, or merely formulate an equivalent solve?
5. Is there a rational change of variables or factor splitting that can convert the listed repeated nonlinear factors into linear divisors without introducing algebraic extensions? If this cannot be inferred generically, state the exact algebraic test.
6. Propose the shortest exact experiment that distinguishes symbolic coefficient swell from genuinely insufficient ansatz degree at sector 13. The required final object remains an exact analytic epsilon-form transformation; numerical fitting alone is not acceptable.

Please do not restate the general package ranking. Use the attached factor list and measured sector breakpoint to prescribe the next calculation.

## Pro response

Decisive recommendation

The next calculation should be:

freeze sectors 1–12⟶capture sector-13’s exact linear systems⟶replace CANONICA’s private linear solver by modular sparse RREF.
	​


The continuation call will not make the sector-13 equations smaller; RecursivelyTransformSectors already processes sectors recursively within a run. Its value is that it isolates sector 13, removes the repeated 1–12 work, and permits checkpointing and instrumentation. The more important restart mechanism is CANONICA's TransformOffDiagonalBlock[...,userProvidedD,...], which can resume inside sector 13 after some of its ten incoming subsector strips have been completed.

The attached denominator census also settles the variable-change question more strongly than expected: the two repeated quadratic factors obstructing C++ FUCHSIA define genus-one curves. They cannot be globally converted into linear divisors by a rational birational change of (p,s). CF48 denominator census

1. Continue from sector 12, but do not expect a faster sector-13 solve

CANONICA's exact public signature is

Wolfram Language
RecursivelyTransformSectors[
    aFull,
    invariants,
    sectorBoundaries,
    {nSecStart, nSecStop},
    trafoPrevious,
    aPrevious,
    opts
]

where trafoPrevious and aPrevious are specifically provided for resuming at a later sector. 

06_nlo_example

Use the 18-dimensional prefix ending at sector 13:

Wolfram Language
res12 = (* retained successful result through sector 12 *);


res13 = RecursivelyTransformSectors[
    aFull13,
    {p, s},
    sectorBoundaries13,
    {13, 13},
    res12[[1]],
    res12[[2]],
    TDeltaNumeratorDegree -> 0,
    TDeltaDenominatorDegree -> 0,
    DDeltaNumeratorDegree -> 0,
    FinalConstantNormalization -> False,
    VerbosityLevel -> 12
];

This avoids recomputing the approximately 13.6 seconds spent on sectors 1–12. It does not alter the sector-13 linear ansatz: inside the original {1,13} run, CANONICA had already retained and reused the transformations of sectors 1–12. The same dense sector-13 equations will be generated.

The continuation run is nevertheless the correct next setup because it:

makes the sector-13 timing unambiguous;

permits exact capture of its equations;

avoids simplification of sectors 14–20;

allows a custom solver to be inserted without touching successful earlier work.

Resume within sector 13

This is more useful than sector-level continuation. The public function

Wolfram Language
TransformOffDiagonalBlock[
    invariants,
    sectorBoundaries,
    trafoPrevious,
    aPrevious,
    userProvidedD,
    opts
]

accepts previously computed D
k
	​

 data and resumes the off-diagonal recursion. The source explicitly initializes from userProvidedD when it is nonempty. CANONICA then processes the lower sectors one at a time, updating the complete extension rather than treating strips independently. 

06_nlo_example

Sector 13 receives nonzero couplings from ten preceding sectors. Run with VerbosityLevel -> 12 and persist the accumulated D after each successful incoming sector. This will identify whether the jump comes from one particular source block—likely one of sectors 10–12—or from the combined accumulated extension.

So the answer to question 1 is:

	​

Yes, resume from sector 12;
no, this does not change the mathematical sector-13 solve;
also checkpoint within sector 13 using userProvidedD.
	​

	​

2. The exact linear system is built in CalcNextDn

The relevant CANONICA call chain is

RecursivelyTransformSectors
	​

→TransformNextSector
→TransformOffDiagonalBlock
→CalculateNextSubsectorD
→FindD
→CalcNextDn
→LinearSystemSolver.
	​


The public helper

Wolfram Language
FindAnsatzSubsectorD

does not expose the equations. It returns the rational-function basis used in the D-ansatz. The actual equations are generated in the private function

Wolfram Language
CANONICA`Private`CalcNextDn

at a fixed order in ϵ. Its source constructs:

Wolfram Language
vars = Join[
    Select[Variables[equationSet], Head[#] === \[Alpha] &],
    Select[Variables[equationSet], Head[#] === \[Beta] &],
    Select[Variables[equationSet], Head[#] === g &]
];


linearSystem =
    (# == 0 &) /@
      Flatten[
        RatFunctionZeroCoeffs[#, invariants] & /@ equationSet
      ];


preSol = LinearSystemSolver[linearSystem, vars, 0];

The source prints only the number of equations at verbosity 12 and immediately sends them to the private solver. 

06_nlo_example

CANONICA's LinearSystemSolver performs repeated simple-equation elimination and forward solving, then finishes with Mathematica Solve on the residual system. 

06_nlo_example

What to export

Export both levels:

Wolfram Language
<|
  "RawEquations"       -> linearSystem,
  "RawVariables"       -> vars,
  "ReducedEquations"   -> preforwardSolved[[1]],
  "PreRules"           -> preforwardSolved[[2]],
  "RemainingVariables" ->
      Variables[First /@ preforwardSolved[[1]]],
  "EpsilonOrder"       -> nOrder
|>

The most relevant matrix is the one associated with ReducedEquations, because that is the system passed to the final expensive Solve. But also retain the raw system in case ForwardSolve itself is responsible for the timeout.

Minimal source patch

The cleanest method is to add an optional capture immediately before

Wolfram Language
preSol = LinearSystemSolver[linearSystem, vars, 0];

inside CalcNextDn:

Wolfram Language
If[TrueQ[$CANONICACaptureLinearSystem],
    Put[
      <|
        "Order" -> nOrder,
        "Equations" -> linearSystem,
        "Variables" -> vars,
        "AnsatzD" -> ansatzD,
        "PreviousSolution" -> previousSolution
      |>,
      $CANONICACaptureFile
    ];
    Throw["Captured", "CANONICALinearSystem"]
];

No ansatz logic has to be reproduced.

Capture without editing the package

A temporary interception also works:

Wolfram Language
captured = Catch[
  Internal`InheritedBlock[
    {CANONICA`Private`LinearSystemSolver},


    ClearAll[CANONICA`Private`LinearSystemSolver];


    CANONICA`Private`LinearSystemSolver[
      eqs_List, vars_List, max_Integer
    ] :=
      Throw[
        <|
          "Equations" -> eqs,
          "Variables" -> vars,
          "MaxLength" -> max
        |>,
        "CF48Capture"
      ];


    CalculateNextSubsectorD[
      a13,
      {p, s},
      sectorBoundaries13,
      previousD,
      {},
      DDeltaNumeratorDegree -> 0,
      VerbosityLevel -> 12
    ]
  ],
  "CF48Capture"
];

For production, the source patch is preferable because it also records nOrder and can capture successive systems rather than aborting at the first one.

3. Replace only the linear solver

First convert the captured equations into a sparse affine system. If

Wolfram Language
eqs

is the list of equations and vars the unknowns:

Wolfram Language
lhs = eqs /. Equal -> Subtract;


coeffs = CoefficientArrays[lhs, vars];


If[Length[coeffs] =!= 2,
    Abort[]  (* the system is not linear *)
];


rhs = -SparseArray[coeffs[[1]]];
mat =  SparseArray[coeffs[[2]]];

Record:

Wolfram Language
<|
  "Equations" -> Length[lhs],
  "Unknowns" -> Length[vars],
  "Nonzeros" -> Length[ArrayRules[mat]] - 1,
  "MatrixBytes" -> ByteCount[mat],
  "CoefficientVariables" ->
      Complement[Variables[{mat, rhs}], vars]
|>

Because CalcNextDn works at a fixed ϵ-order and then applies RatFunctionZeroCoeffs in the kinematic variables, I expect the captured matrix to be over Q, but this must be checked explicitly:

Wolfram Language
FreeQ[{mat, rhs}, p | s | eps]
If the matrix is over Q: use SpaSM or LinBox

For a large sparse rational system, the shortest route is:

reduce the matrix modulo several 31-bit primes;

compute sparse RREF/PLUQ;

determine a stable pivot/free-column pattern;

reconstruct the affine rational solution by CRT and rational reconstruction;

verify it in the original exact equations.

SpaSM is designed specifically for sparse Gaussian elimination modulo word-sized primes. It provides rank, RREF, kernel bases, PLUQ factorization, linear-system solving, and rank certificates. 
GitHub
 LinBox is the broader mature exact-linear-algebra alternative and supports sparse systems over integers and finite fields. 
GitHub
+1

For this one captured CANONICA system, SpaSM is the more direct experiment.

Preserve the free parameters

Do not reconstruct only one particular solution.

CANONICA intentionally carries free ansatz parameters into later ϵ-orders and then uses CheckNextDsVanish to select combinations for which the transformation terminates. Setting all free variables to zero at sector-13's first order can destroy a valid finite solution.

The external solver must return an affine solution space:

x
P
	​

=x
0
	​

+Nx
F
	​

,

where P and F are pivot and free columns. In practice:

fix the pivot pattern at a generic prime;

solve once for the inhomogeneous RHS;

solve once for each free-column RHS;

reconstruct x
0
	​

 and N;

return CANONICA rules expressing pivot variables in terms of the original free symbols.

The required return format is the same as LinearSystemSolver:

Wolfram Language
{{pivotVar1 -> expr1, pivotVar2 -> expr2, ...}}
If parameters remain: use Ratracer or FiniteFlow

If the captured matrix still depends on eps or another exact parameter, the most concrete route in your current environment is Ratracer plus FireFly. Ratracer explicitly supports tracing solutions of linear systems, with FireFly supplying rational-function reconstruction. 
arXiv
+1

The workflow is:

export the sparse matrix entries as rational functions of the remaining parameter;

have the black-box evaluator reduce them modulo a prime and evaluate the parameter;

solve the modular sparse system;

output the affine solution coefficients;

reconstruct those coefficients as rational functions with FireFly;

import the rules into CANONICA;

verify every original equation exactly.

FiniteFlow can perform the same modular-evaluation and rational-reconstruction workflow using its dataflow-graph and linear-solver infrastructure, but it requires more adapter code from the captured Mathematica matrix. 
GitHub

Role of the other candidates

FireFly alone: reconstruction engine, not a sparse linear solver.

SpaSM: ideal per-prime sparse solver, but requires an external CRT/reconstruction layer.

Fermat: potentially useful for a direct exact solve over a rational-function field, but less attractive than modular sparse elimination for a large constant sparse system.

Mathematica Solve: precisely the component currently exhibiting coefficient swell.

Minimal drop-in replacement

Override only:

Wolfram Language
CANONICA`Private`LinearSystemSolver

with a wrapper that:

runs CANONICA's cheap simple-equation preprocessing;

exports the reduced sparse matrix;

calls the modular backend;

imports the affine rules;

verifies them;

returns {{rules}}.

That preserves all ansatz construction and all later termination logic.

4. Libra may avoid this particular matrix, but not the mathematical problem

Libra exposes native block-aware functions including

BlockTriangularToFuchsian
FuchsifyDependent
FuchsifyDependentBlocks
FactorOut
FactorDependence
IntertwiningMatrix

in its current public source. 

02_factorization

Libra's dependent-block reduction is not CANONICA's global rational-function ansatz. It works through Fuchsian balances, projectors, invariant subspaces, and subsequent epsilon factorization. Therefore it may avoid the exact large coefficient matrix that is stalling CANONICA.

However, it still solves the same extension problem:

dX−ϵ(Ω
top
	​

X−XΩ
low
	​

)=B−ϵdlog terms.

So it cannot eliminate the intrinsic coupling complexity. It changes the computational representation:

CANONICA: one rational ansatz and a large linear coefficient solve;

Libra: iterative pole-by-pole/block-by-block balances and intertwining operations.

For sector 13, Libra is worth one bounded 18-dimensional test because the abrupt CANONICA jump could be caused specifically by symbolic coefficient swell in the ansatz solve. If the higher poles admit low-rank balances, Libra may be much faster.

Use only the sector-13 prefix and the already canonical diagonal blocks. Stop if:

no Poincaré-rank reduction occurs quickly;

balances begin cycling between p- and s-components;

FactorOut reaches a comparably large unresolved intertwining problem;

the exact two-variable reconstruction gate fails.

Libra supports multivariable systems and block-aware Fuchsian/epsilon-form operations, but it is an interactive transformation framework rather than a guaranteed unattended replacement for CANONICA's sector recursion. 
GitHub

5. The two repeated quadratic divisors cannot be rationally linearized

The two factors that obstruct fuchsia show -x p are

q
1
	​

(p,s)=p
2
−ps−ps
2
+s,
q
2
	​

(p,s)=sp
2
−(1+s)p+s
2
.

Consider them as quadratics in p. Their discriminants are

Δ
p
	​

(q
1
	​

)=s(s−1)(s
2
+3s+4),
	​

Δ
p
	​

(q
2
	​

)=−(s−1)(4s
2
+3s+1).
	​


Neither is a square in Q(s). Thus neither polynomial splits into linear factors over the rational function field Q(s).

Changing the active variable does not help:

Δ
s
	​

(q
1
	​

)=(p+1)(4p
2
−3p+1),
Δ
s
	​

(q
2
	​

)=p(p+1)(p
2
−3p+4),

which are likewise nonsquares in Q(p).

There is a stronger obstruction. Each discriminant is squarefree of degree three or four. Therefore the normalization of q
i
	​

=0 has function field

Q(s)(
Δ
i
	​

(s)
	​

)

and geometric genus one. A rational birational change of (p,s) preserves the genus of the strict transform of the divisor. Hence:

no rational birational chart can convert either q
1
	​

=0 or q
2
	​

=0 into a linear divisor.
	​


Splitting them requires passing to an algebraic genus-one extension. It is not another ordinary square-root rationalization.

The other repeated factors that are quadratic in s, such as

s
2
−p,s
2
+p,

are linear in p, so choosing p as active variable handles those. The two genus-one factors remain the unavoidable obstruction for C++ FUCHSIA.

This does not imply that the master system is elliptic. CANONICA can treat q
1
	​

 and q
2
	​

 directly as irreducible polynomial dlog letters. The obstruction is to FUCHSIA's one-variable partial-fraction representation, not necessarily to an MPL epsilon form.

6. Shortest conclusive sector-13 experiment
Stage A: isolate the exact stalled call

Resume through sector 12 and run only sector 13 with VerbosityLevel -> 12.

Checkpoint the partial D-list after every incoming lower sector. Identify:

the lower sector currently being processed;

the ϵ-order nOrder;

equation count;

unknown count;

matrix nonzero count;

equation-generation time;

solve time.

This distinguishes “sector 13” from the precise troublesome D
k
	​

 and ϵ-order.

Stage B: modular rank and consistency at degree zero

For the first stalled system form

Ax=b.

At three good primes compute

r=rankA,r
aug
	​

=rank[A∣b].
Outcome 1: r=r
aug
	​


The degree-zero ansatz is consistent at that order. Compute the full affine solution modularly, reconstruct it, and require

Ax
0
	​

=b,AN=0

exactly over Q.

If these identities hold, the timeout was coefficient swell, not insufficient ansatz degree.

Outcome 2: r<r
aug
	​


Construct a left-null certificate

y
T
A=0,y
T
b

=0.

Reconstruct y exactly and verify both identities over Q. This proves that the degree-zero ansatz is insufficient at that order. Then—and only then—rerun sector 13 with

Wolfram Language
DDeltaNumeratorDegree -> 1

or with a targeted user-provided ansatz.

Repeated modular inconsistency alone is diagnostic; the exact left-null vector is the final analytic certificate.

Stage C: reinsert the modular solver

Override LinearSystemSolver, let sector 13 complete at degree zero, and require:

T
13
−1
	​

A
μ
	​

T
13
	​

−T
13
−1
	​

∂
μ
	​

T
13
	​

=ϵ
a
∑
	​

R
a
	​

∂
μ
	​

logϕ
a
	​

,μ=p,s,

with exact constant residues.

This is the decisive full test. A consistent first linear system does not by itself prove that the full finite D(ϵ) series terminates; completing sector 13 with the modular backend does.

Stop conditions

Stop and change the ansatz only if:

an exact inconsistency certificate is obtained;

the modularly reconstructed rules fail exact substitution;

the later CheckNextDsVanish proves that the degree-zero series cannot terminate.

Do not raise the ansatz degree merely because Mathematica Solve exceeded 300 seconds.

Immediate run order

Resume {13,13} from the retained sector-12 result.

Enable VerbosityLevel -> 12.

Capture the exact CalcNextDn system at the first slow call.

Check whether its coefficients are constant rationals.

Run SpaSM modular RREF if they are; otherwise use Ratracer/FireFly.

Reconstruct the full affine solution, including the nullspace.

Replace CANONICAPrivateLinearSystemSolver and complete sector 13.

Run the exact 18-dimensional epsilon-form gate.

Test Libra on the same 18-dimensional prefix only if modular CANONICA does not complete.

The measurements currently favor the interpretation

degree-zero ansatz may be adequate; Mathematica’s exact symbolic solve is the bottleneck.
	​


The modular rank test will settle that before any further multi-minute ansatz search.

## Sources sent to Pro

- Original source reference: `/home/maxzhang/FACET/Codex/General/ToolStudy/CF48Fuchsia/CF48FuchsiaAudit.wl` (not archived with this exchange)
