# TT Target Whole Together

## Question

We are continuing the same FACET pp->hX NLO TT coefficient-simplification study. Please assess the new exact measurements below and advise on the next mathematical test. Do not propose fixed-point numerical output as the deliverable; the required result is exact analytic.

Context and measured results

1. The NLO TT reduction has 87 complete target coefficients, 8 topology classes, and 6 masters. The hadronic substitution is exact and card-defined. A common physical prefactor is stripped before coefficient work.

2. The newer "controlled" routine atomized Gamma/Beta/hypergeometric/log/noninteger-power/BMHV objects, split each additive term into a rational factor times an analytic signature, and merged rational factors only within an identical syntactic signature. On the full TT calculation this left denominators such as u xa + t xb and therefore left xa, xb in the six master coefficients.

3. On the largest sampled physical target coefficient (position 9), exact measured results are:

   Input: 4,279,848 bytes, 323 additive terms.

   Whole rational merge
      Factor[Cancel[Together[canonical]]]
      kernel time 0.195264 s
      output 72,136 bytes, one additive term
      no xa, xb, or zh
      exact symbolic data retained.

   Signature-separated rational merge
      kernel time 2.818939 s
      output 1,109,176 bytes, 896 additive terms
      xa and xb remain.

Thus the syntactic signature split is too fine and blocks cancellations required at fixed target. It is not merely slower; it gives an unresolved expression.

4. The initial real-emission notebook used more than one generic Simplify. Before integration it collected by a kinematic basis and applied FactorTerms[Cancel[Together[...]]]. After integration it first collected composite Beta*Hypergeometric2F1 objects, then individual Beta and hypergeometric objects, applying Factor[Cancel[Together[#]]] locally, followed by an outer Simplify. This suggests the physical ordering is: expose required rational cancellation first, then collect by genuine analytic basis, then simplify coefficients.

5. A previous full target-first TT run using the controlled signature split took about 175 s for the hadronic map, 99 s for target cleanup, and 241 s for final master cleanup, but left xa, xb. A master-only Simplify was unbounded and reached about 1.9 GB without finishing. A monolithic post-master rational merge also grew beyond 7 GB. Therefore the complete target is currently the smallest measured place where the momentum-fraction cancellation is both exposed and cheap.

Questions

A. Does the whole-target result justify the route
   exact hadronic map -> Factor[Cancel[Together[target coefficient]]] -> Kira linear composition -> collect by master -> bounded coefficient cleanup,
or should the target rational merge be modified before applying it to all 87 targets?

B. Is there a mathematically safer two-level version modeled on the initial notebook: first merge the entire rational target coefficient, then identify a genuine analytic basis (including relations among Gamma/Beta/hypergeometric objects rather than syntactic signatures), collect by that basis, and simplify each coefficient? Please state a concrete Wolfram Language ordering.

C. What exact local certificate should accompany Factor[Cancel[Together[target]]] without recomputing a giant difference? We can cross-multiply old and new rational expressions after atomizing analytic objects, but the largest-target result shows that atomizing too early may block needed identities. Should canonical FunctionExpand/GammaReduce/PiecewiseExpand under physical assumptions occur before atomization?

D. For NNLO streaming, should the unit be one complete target coefficient followed by this whole rational merge, then sparse Kira accumulation? The target files are manageable, whereas a full master coefficient is not.

Please focus on the exact algebra and measured scaling. Point out any branch-sensitive operation that Factor/Cancel/Together could perform incorrectly in the presence of noninteger powers or special functions, and give a guarded implementation if needed.

## Pro response

Conclusion

The measured target at position 9 changes the recommendation. The syntactic-signature split should not precede the first complete rational cancellation. It separated terms that had to remain in one algebraic expression for the x
a
	​

,x
b
	​

,z
h
	​

 dependence to cancel.

The next route to test on all 87 targets is

C
α
	​

	​

=complete coefficient of target G
α
	​

hadronic map and fixed branch rules
	​

C
α
phys
	​

narrow special-function canonicalization
	​

C
α
	​

one global rational merge
	​

C
α
	​

optional analytic-basis collection
	​

C
α
	​

Kira
	​

K
m
	​

=
α
∑
	​

R
αm
	​

C
α
	​

bounded exact cleanup
	​

K
m
	​

.
	​

	​


Here “global” means global within one complete target coefficient, not over all 87 targets or over a complete large master vector.

A. Whether to use the whole-target rational merge

Yes. The measured result justifies testing

Wolfram Language
Factor[Cancel[Together[canonicalTarget]]]

on all 87 complete targets, with three guards:

apply the exact hadronic and branch canonicalization first;

place a finite time and memory boundary around each target;

accompany every changed result by an exact local certificate.

The evidence is unusually strong:

4.28 MB, 323 terms⟶72.1 kB, 1 term

in 0.195 s, with exact removal of x
a
	​

,x
b
	​

,z
h
	​

. By contrast, the signature-separated route took 2.82 s, produced 1.11 MB and 896 terms, and retained x
a
	​

,x
b
	​

. This is not merely a compression difference: the earlier decomposition prevented the algebra needed for the physical cancellation.

Together forms a single rational expression and cancels common factors; Cancel cancels a numerator–denominator gcd. Thus the explicit Cancel after Together is often algebraically redundant, but retaining the measured sequence is harmless and avoids changing two variables in the next benchmark. 
Wolfram Documentation Center
+1

Guarded target transformation

Use one fixed routine:

Wolfram Language
ClearAll[normalizeCompleteTarget];

normalizeCompleteTarget[
    coefficient_,
    context_Association,
    timeLimit_
  ] := Module[
  {
    canonical, functionCanonical,
    frozenData, frozen, merged, certificate
  },

  canonical = applyExactHadronicMap[
    coefficient,
    context["HadronicVariables"]
  ];

  canonical = applyFixedBranchRegistry[
    canonical,
    context["BranchRegistry"]
  ];

  canonical = reduceToFixedFourierBasis[
    canonical,
    context
  ];

  functionCanonical = canonicalizeMeromorphicFunctions[
    canonical,
    context
  ];
  If[FailureQ[functionCanonical], Return[$Failed]];

  frozenData = freezeMaximalAnalyticObjects[
    functionCanonical,
    context
  ];
  If[FailureQ[frozenData], Return[$Failed]];

  frozen = frozenData["Expression"];

  merged = TimeConstrained[
    Factor[
      Cancel[
        Together[
          frozen,
          Extension -> None,
          Trig -> False
        ]
      ]
    ],
    timeLimit,
    frozen
  ];

  certificate = certifyRationalTransformation[
    frozen,
    merged,
    frozenData["AlgebraicVariables"]
  ];

  If[! TrueQ[certificate["Verified"]],
    Return[$Failed]
  ];

  merged /. frozenData["InverseRules"]
];

The important correction is:

freeze analytic objects globally, but do not separate the sum by signature before ‘Together‘.
	​


Atomization was not the mathematical error. Treating the atoms as separate, independently merged sectors was the error. A single globally atomized expression still permits cancellation among every additive term.

Bounds and fallback

The result from one target does not prove that all 87 targets will behave equally well. Use, for example, a 30–60 second whole-target limit in dedicated workers:

Wolfram Language
TimeConstrained[
  exactWholeTargetMerge[input],
  60,
  input
]

A timeout retains the exact canonical target. It should be counted as "UnchangedAfterTimeout", not as a failed equality.

Record for each target:

input and output bytes;

input and output additive-term counts;

elapsed time;

whether the whole merge changed the expression;

local certificate status;

whether x
a
	​

,x
b
	​

,z
h
	​

 remain;

timeout and worker-recycle status.

Do not require each individual target to be fraction-independent unless the factorization formula proves that target by target. The authoritative requirement remains the complete master coefficient after Kira.

B. The safer two-level method

The mathematically safer version of the historical ordering is:

canonicalize known identities→merge the complete target rationally→collect in a declared analytic basis→normalize each collected coefficient.
	​


This reverses the order used by the unsuccessful syntactic-signature routine.

Level 1: expose rational cancellation across the complete target

Let

C
α
	​

=
i=1
∑
n
α
	​

	​

t
i
	​


be the complete physical target coefficient after the branch registry and a narrow special-function canonicalizer.

Replace maximal branch-sensitive objects by distinct symbols,

F
j
	​

⟷z
j
	​

,

but retain the full sum:

C
α
	​

⟼
C
α
fr
	​

∈Q(s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

,z
1
	​

,…,z
N
	​

).

Then perform

C
α
fr
	​

=Factor[Cancel[Together(
C
α
fr
	​

)]].

This operation is allowed to combine terms carrying different z
j
	​

. That is what the earlier implementation prevented.

By default, Together and Cancel treat trigonometric functions as independent rather than applying trigonometric identities, and algebraic extensions are not inferred unless requested. For this calculation, retain Trig -> False and Extension -> None; the Fourier and radical canonicalization should already have occurred through the fixed physical registry. 
Wolfram Documentation Center
+1

Level 2: collect after the cancellation

After the whole rational merge, inspect

C
α
fr
	​

=
Q
α
	​

(s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

;z)
P
α
	​

(s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

;z)
	​

.

The favorable case is

Q
α
	​

∈Q[s,t,u,ϵ,x
a
	​

,x
b
	​

,z
h
	​

],

so the analytic atoms occur only polynomially in the numerator. Then use the exponent vectors of the atom monomials as the analytic basis:

P
α
	​

=
n
∑
	​

p
α,n
	​

z
1
n
1
	​

	​

⋯z
N
n
N
	​

	​

.

Each coefficient is

R
α,n
	​

=
Q
α
	​

p
α,n
	​

	​

.

Now apply the local historical cleanup,

R
α,n
	​

⟼Factor[Cancel[Together(R
α,n
	​

)]],

with a bound for large blocks.

In Wolfram Language:

Wolfram Language
num = Numerator[mergedFrozen];
den = Denominator[mergedFrozen];

If[! FreeQ[den, Alternatives @@ analyticAtoms],
  (* Keep this target as one conservative analytic block. *)
  collected = mergedFrozen,

  rules = CoefficientRules[
    Expand[num],
    analyticAtoms
  ];

  collected = Total @ Map[
    Function[rule,
      With[
        {
          powers = First[rule],
          rationalCoefficient =
            boundedLocalRationalNormalize[
              Last[rule]/den,
              context
            ]
        },
        Times @@ MapThread[
          Power,
          {analyticAtoms, powers}
        ] rationalCoefficient
      ]
    ],
    rules
  ]
];

This is better defined than a Collect basis containing both

Wolfram Language
Beta[...] Hypergeometric2F1[...]

and the individual Beta[...] and Hypergeometric2F1[...] objects. Those basis elements overlap. In an atom-monomial representation, the product is simply the exponent vector (1,1), while the individual terms have (1,0) and (0,1).

Which analytic identities should precede the first merge?

Use only a declared finite list of meromorphic identities, such as:

B(a,b)=
Γ(a+b)
Γ(a)Γ(b)
	​

,
Γ(z+n)=(z)
n
	​

Γ(z),n∈Z,

and

2
	​

F
1
	​

(a,b;c;z)=
2
	​

F
1
	​

(b,a;c;z).

Choose one direction for each identity and use it everywhere. For example, either use a Gamma basis or retain Beta as primitive; do not repeatedly convert in both directions.

Leave the following untouched:

hypergeometric contiguous transformations;

Euler/Pfaff transformations;

Gamma reflection and duplication;

logarithm and polylogarithm identities;

transformations of noninteger powers;

relations that change an argument across a branch cut.

There is no generally complete canonical basis for all Gamma, hypergeometric, logarithmic, and polylogarithmic expressions relevant here. The purpose of this stage is deterministic identification of the identities FACET has explicitly accepted, not general special-function simplification.

C. Exact certification and the order of function canonicalization
Do not globally apply FunctionExpand

A global

Wolfram Language
FunctionExpand[coefficient, assumptions]

is not the appropriate precursor. FunctionExpand uses a large collection of transformations, and Wolfram’s documentation explicitly notes that some transformations are only generically valid. It can also transform elementary and special functions in ways unrelated to the narrow Gamma/Beta normalization needed here. 
Wolfram Documentation Center

Use FunctionExpand only as a candidate generator on an isolated atom, and accept its output only when the chosen physical assumptions and an independent identity check certify it. Do not use it on the complete target.

Likewise:

do not add a broad “Gamma reduction” stage;

do not globally apply PiecewiseExpand;

do not expand ConditionalExpression;

do not rewrite logarithms, polylogarithms, or noninteger powers across different arguments.

A Piecewise or ConditionalExpression should remain one maximal inert object unless the physical assumptions prove that exactly one branch applies. In the latter case, record the selected condition as part of the analytic context.

Atomization timing

The correct timing is:

branch rules→narrow meromorphic canonicalization→global atomization→whole rational merge.
	​


Atomizing before known Gamma/Beta/Pochhammer identities have been put into one basis can miss a cancellation. But atomizing after that narrow canonicalization does not reproduce the earlier error as long as the whole target remains one expression.

Local exact certificate

Suppose the frozen input is

E=
i=1
∑
n
	​

b
i
	​

a
i
	​

	​


and the whole-target routine returns

E
′
=
B
A
	​

.

Do not certify this by constructing and simplifying E−E
′
 globally. Use a balanced exact fraction tree.

For a merge

b
1
	​

a
1
	​

	​

+
b
2
	​

a
2
	​

	​

⟼
b
a
	​

,

verify

ab
1
	​

b
2
	​

−b(a
1
	​

b
2
	​

+a
2
	​

b
1
	​

)=0.
	​


All quantities are polynomials in the rational variables and the frozen atom symbols. Test the polynomial by exact coefficient extraction.

Wolfram Language
ClearAll[certifyMergeNode];

certifyMergeNode[
    left : {a1_, b1_},
    right : {a2_, b2_},
    output : {a_, b_},
    variables_List
  ] := Module[{identity},

  identity = Expand[
    a b1 b2 -
      b (a1 b2 + a2 b1)
  ];

  PolynomialQ[identity, variables] &&
    CoefficientRules[identity, variables] === {}
];

Repeat this in a balanced tree until one independently constructed fraction

E
tree
	​

=
b
tree
	​

a
tree
	​

	​


remains. Then compare it with the direct Together result by

a
tree
	​

B−Ab
tree
	​

=0.
	​


This gives an exact certificate without simplifying the original full difference.

Conditions on the certificate

The proof is valid provided that:

the atom map is injective and reversible;

the same canonicalization and atom dictionary are used for input and output;

all denominators are nonzero polynomials, not identically zero;

every term is included;

all arithmetic is exact;

no Piecewise, distribution, branch condition, or BMHV tensor has been opened by the rational algebra;

the result is interpreted as a meromorphic identity.

Treating analytic atoms as algebraically independent makes this check sufficient but not necessary. If the polynomial identity is zero, equality is proved. If it is nonzero, the original expressions might still be equal through an analytic identity not included in the declared canonicalizer; report that case as unresolved rather than unequal.

Branch risk from Factor, Cancel, and Together

The guarded form is branch safe because these functions see only rational variables and inert atom symbols. They are not allowed to rewrite inside

X
a+bϵ
,logX,Li
n
	​

(X),
2
	​

F
1
	​

(…;X),

or BMHV structures.

Do not use:

Wolfram Language
PowerExpand
Together[..., Trig -> True]
Together[..., Extension -> Automatic]

in this stage.

Cancellation may remove a factor that vanishes on a kinematic hypersurface. The resulting expression is then equal as a meromorphic function, even though the two syntactic expressions may differ pointwise at a removable 0/0 form. That is the appropriate notion for the exact hard coefficient. Distributional objects and endpoint prescriptions must remain frozen so that no ordinary rational cancellation is performed inside them.

D. NNLO streaming unit

For the NNLO calculation, the complete target coefficient is now the smallest unit justified by the measurements:

C
α
	​

=
p∈P
α
	​

∑
	​

P
p
	​

c
pα
	​

.
	​


The position-9 result demonstrates that the required cancellation can mix terms placed into different syntactic analytic signatures. Therefore no smaller signature block has presently been shown to be sufficient.

An individual pair coefficient may still be canonicalized through exact local identities, but it should not be treated as the final algebraic simplification unit.

Recommended NNLO order

For each of the 44,877 targets:

read all contributing pair terms;

remove the already certified common pair factor;

form the complete target coefficient;

apply the exact hadronic map;

apply the fixed branch registry;

apply the narrow special-function canonicalizer;

freeze maximal analytic, distributional, and BMHV objects globally;

perform the whole-target rational merge;

write its exact local certificate;

optionally collect the merged result by atom monomials;

stream the result through the sparse Kira row.

For target α,

G
α
	​

=
m=1
∑
342
	​

R
αm
	​

M
m
	​

,

so stream

R
αm
	​

C
α
	​


to the corresponding master accumulator without constructing the full master vector.

Master accumulation

Do not return to the failed fine syntactic-signature partition. Accumulate either:

the complete frozen algebraic expression for each master; or

coarse classes for which independence has actually been established, such as distinct PDF/FF channels or distinct Fourier harmonics.

Within each master, combine target contributions in a balanced merge tree. Each partial merge remains an exact rational expression in the same global analytic atom ring and receives the same local certificate.

The final master coefficient is

K
m
	​

=
α∈T
m
	​

∑
	​

R
αm
	​

C
α
	​

.

Different targets can still cancel after multiplication by R
αm
	​

, so a bounded final cleanup remains useful. It must not be the first serious simplification stage.

Is there a smaller exact unit?

A smaller unit exists only after proving a direct decomposition

C
α
	​

=
λ
∑
	​

F
λ
	​

C
αλ
	​


over a basis {F
λ
	​

} that is linearly independent over the rational coefficient field. The failed syntactic grouping did not establish such a basis. Until that proof exists, the complete target coefficient is the conservative unit.

Next mathematical test

Run the following exact test over all 87 NLO TT targets:

complete target→fixed canonicalization→global atomization→whole rational merge→local merge-tree certificate.
	​


The acceptance criteria are:

every changed target has a verified local certificate;

a timeout returns the unchanged canonical target;

no branch or BMHV object is altered internally;

the Kira composition uses the same 87 targets, 8 topology classes, and 6 masters;

the reconstructed master vector is exact by composition of the target certificates and Kira linearity;

after restoring the common physical factor, all six master coefficients satisfy the required x
a
	​

,x
b
	​

,z
h
	​

 independence;

any separate master-level identity check that times out is recorded as unresolved, not nonzero.

This directly tests the route indicated by the position-9 measurement while keeping the analytic proof local, exact, and scalable to the NNLO target stream.
