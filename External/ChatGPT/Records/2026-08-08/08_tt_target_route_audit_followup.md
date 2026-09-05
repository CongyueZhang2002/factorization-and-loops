# TT Target Route Audit Followup

## Question

We now have a concrete NLO TT measurement and need a precise critique, not a generic simplification list.

Physics requirement: preserve an exact analytic hard function, BMHV information, branches, and endpoint dependence. Numerical checks are secondary only.

Measured calculation:

1. An exact common factor was extracted from all 25 TT amplitude-conjugate pair coefficients before target formation. It is

   Pi^(5-D/2) alpha_s^3 f1[xb] h1[xa] H1[zh]
   SPD[n,Pb] SPD[nb,Pa] SPD[nhb,Ph]
   /(zh^3 SPD[ka,nb] SPD[kb,n] SPD[kc,nhb]).

   The 25 pair-specific quotients occupy only 23.8 kB. The factor is reconstructed exactly.

2. The card contains exact global-basis coordinates for Pa, Pb, Ph, nh, nhb, STvec, and SThvec in terms of s,t,u,xa,xb,zh and the spin angles. There are no eta or PhT intermediate variables.

3. The route was:
   complete target coefficient -> hadronic map and real-branch registry -> atomize maximal Gamma/Beta/Pochhammer/hypergeometric/log/polylog/zeta/noninteger-power/BMHV/Fourier objects -> expand only the remaining rational shell -> collect by exact analytic signature -> Cancel each rational term -> merge exact equal-denominator buckets -> bounded Factor[Cancel[Together[...]]] only for small buckets -> apply Kira rules -> repeat the bounded cleanup for each of the 6 master coefficients.

4. The route completed its coefficient construction with peak RSS about 2.3 GB. The older master-only Simplify attempt reached about 4.9 MB before simplification but one master ran indefinitely; a previous master-only controlled run used about 2.3 GB in its largest worker. Target-first reduced the largest final worker to about 1.0 GB before reconstruction.

5. The run then spent the remainder of 15.2 minutes in a sequential post-run exact identity check and exited because it could not establish all six zero differences within 300 s per difference. This does not identify a nonzero difference: timeout and mathematical inequality were conflated. Worse, the script wrote nothing before this audit.

We have corrected the experiment so that it first writes the exact candidate, then tests the six reconstructed-master differences in a four-worker pool and records, separately for each master, exact zero / unresolved, timeout count, and failure count. The algebraic transformations used by the cleanup are reversible by construction; nevertheless we want a useful independent exact audit.

Questions:

A. What is the best exact certificate for this route that avoids constructing and simplifying each full expression difference? Please distinguish a proof based on local reversible transformations from an independent symbolic check. Is it sufficient to certify each signature block through common-denominator numerator equality before discarding its input, then use linearity of target summation and Kira substitution? If so, state the exact conditions and what records must be retained.

B. Can the xa,xb cancellation be certified signature by signature, or must one retain the complete coefficient of each master because two apparently different analytic signatures may be related? Give a conservative rule.

C. For NNLO UU (1,296 pair files, 44,877 targets, 342 masters), assess this exact streaming order:
   read all contributions to one complete target; remove the already certified global pair factor; apply the hadronic map; split by exact analytic signature; normalize rational coefficients; multiply by the sparse Kira row; accumulate on disk by (master, signature), using balanced exact merges; reconstruct each complete master only at the end.

The goal is to prevent both memory growth and loss of cancellations. Identify any mathematical flaw or a smaller exact unit than a complete target coefficient. Please be explicit about where relations between analytic signatures could invalidate independent simplification.

## Pro response

Assessment

The route can be certified exactly without constructing six full expression differences. The appropriate proof is compositional:

pair contributions⟶complete target coefficients⟶signature blocks⟶Kira substitution⟶complete master blocks.

If every local transformation is accompanied by an exact equality certificate, linearity proves equality of the final master vector. A second symbolic calculation remains useful as an independent audit, but a timeout in that audit must be reported as unresolved, not as inequality.

The 23.8 kB total size of the 25 pair quotients also means that the early common-factor extraction has already removed the main pair-level redundancy. The remaining work should be organized around complete target blocks and complete master blocks, not around repeated simplification of individual pair expressions.

A. Exact route certificate without full master differences

Let the original contribution of pair p be

I
p
	​

=F
α
∑
	​

c
pα
	​

G
α
	​

,

where F is the certified common factor and G
α
	​

 are the 87 canonical targets. Define

C
α
	​

=
p=1
∑
25
	​

c
pα
	​

.

Let H denote the exact hadronic-coordinate substitution with the fixed branch registry. After atomizing branch-sensitive and BMHV structures, write

H(C
α
	​

)=
σ
∑
	​

A
σ
	​

r
ασ
	​

,

where A
σ
	​

 is an inert analytic signature and

r
ασ
	​

∈Q(s,t,u,ϵ,color)

is the rational shell.

The Kira map is

G
α
	​

=
m=1
∑
6
	​

R
αm
	​

M
m
	​

,

so the master coefficient is

K
m
	​

=
σ
∑
	​

A
σ
	​

(
α=1
∑
87
	​

R
αm
	​

r
ασ
	​

).

If every transformation

r⟼
r

has an exact certificate r=
r
, then

F
α,σ
∑
	​

A
σ
	​

r
ασ
	​

G
α
	​

=F
m,σ
∑
	​

A
σ
	​

(
α
∑
	​

R
αm
	​

r
ασ
	​

)M
m
	​


follows by linearity. No monolithic final difference is mathematically necessary.

Local rational certificate

Suppose a merge replaces

d
1
	​

n
1
	​

	​

+
d
2
	​

n
2
	​

	​


by

D
N
	​

.

With all analytic objects frozen, an exact local certificate is the polynomial identity

Nd
1
	​

d
2
	​

−D(n
1
	​

d
2
	​

+n
2
	​

d
1
	​

)=0.
	​


This avoids simplifying the rational-function difference itself. It can be checked with exact polynomial arithmetic:

Wolfram Language
ClearAll[certifyFractionMerge];

certifyFractionMerge[
    {n1_, d1_},
    {n2_, d2_},
    {n_, d_},
    variables_List
  ] := Module[{polynomial},

  polynomial = Expand[
    n d1 d2 - d (n1 d2 + n2 d1)
  ];

  PolynomialQ[polynomial, variables] &&
    CoefficientRules[polynomial, variables] === {}
];

For an equal-denominator bucket,

i
∑
	​

d
n
i
	​

	​

⟼
D
N
	​

,

the analogous certificate is

Nd−D
i
∑
	​

n
i
	​

=0.

A balanced merge tree whose leaves are the original fractions and whose every node satisfies its local polynomial identity proves the final block equality by induction.

Conditions required for the compositional proof

The block certificates are sufficient only if all of the following are enforced.

1. The common factor is certified for every pair

For each pair,

P
p
	​

=F
P
p
	​


must be established exactly, with

P
p
	​

−F
P
p
	​

=0.

The factor F must be free of GLIs, loop momenta, cut distributions, and topology labels. The pre-map factor and its post-hadronic-map form should both be retained, together with their exact equality under the card definitions.

2. The hadronic map is fixed and exact

The same coordinate map, assumptions, and branch registry must be used for every route. Each branch rewrite must have a local proof such as

Wolfram Language
TrueQ @ FullSimplify[
  lhs == rhs,
  Assumptions -> physicalAssumptions
]

No route may generate its own radical identities from its partially simplified output.

3. Atomization is bijective

The atom table must be an injective mapping

z
σ
	​

⟷A
σ
	​

.

Every atom must have exactly one inverse image, and no original atom symbol may already occur in the input. Deatomization must reconstruct the expression exactly.

4. Signature extraction is exhaustive

Every additive term must be represented as

A
σ
	​

r
σ
	​

.

No term may be dropped merely because its signature is unfamiliar. Unknown BMHV, endpoint-distribution, or branch-sensitive objects must cause failure or remain inside a conservative inert block.

5. Distributional objects remain inert

Endpoint distributions must include their variable and convention in the signature. Factors must not be moved through plus distributions or delta functions using ordinary-function identities unless the corresponding distributional identity has been implemented explicitly.

6. Zero blocks are removed only after exact arithmetic

A block may be discarded only when its rational numerator is identically zero. Structural absence, numerical evaluation, or a timeout is not sufficient.

7. The Kira map is fixed and closed

The certificate must refer to one immutable Kira artifact containing:

the exact target list;

the exact master list;

the closed target-to-master rules;

the topology mappings;

the cut indices and orientations;

the dimension convention.

The coefficient transformation must not modify GLI keys, cut data, or BMHV metadata.

8. Timeouts preserve the exact input

A timeout at any node must return the node’s exact input representation. It may reduce compression, but it cannot alter the result.

Records that should be retained

A proof-carrying artifact should contain:

the raw pair-file hashes and pair identifiers;

the common factor F, each quotient 
P
p
	​

, and the pair reconstruction results;

the hadronic map, physical assumptions, branch registry, and their fingerprint;

the atom dictionary and signature-schema version;

for each target, the complete list of contributing pair records;

for each rational block, its leaf fractions and balanced merge tree;

for every merge node, input hashes, output hash, and exact polynomial identity result;

the Kira artifact fingerprint and exact row dependencies;

for every master-signature block, the complete list of contributing target blocks;

the final candidate and separate audit status.

The large transformed input can be discarded after the certificate is written, provided the immutable raw pair artifacts and all merge leaves remain available. A Boolean "Verified" -> True without the underlying fraction data or merge tree is not an independently checkable certificate.

Independent symbolic audit

The independent audit should reconstruct canonical maps

C
m
	​

:σ⟼{
d
mσ,1
	​

n
mσ,1
	​

	​

,…}

from:

the raw target stream; and

the saved candidate.

It then compares corresponding rational blocks using a separate exact checker. It need not reconstruct the full Mathematica expression.

The statuses should be separated:

Wolfram Language
"LocalTransformationCertificate" -> "Verified"
"IndependentAudit" -> {
  master1 -> "ExactZero",
  master2 -> "ExactZero",
  master3 -> "Unresolved",
  ...
}

An unresolved independent audit does not negate the compositional proof, but it must not be reported as an independently verified equality.

B. Certifying the x
a
	​

,x
b
	​

 cancellation

The cancellation may be checked signature by signature, but the logical strength of the result depends on the outcome.

Let the hard quotient be

H
m
	​

=
σ
∑
	​

A
σ
	​

r
mσ
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

).
Sufficient certificate

If both

FreeQ[A
σ
	​

,{x
a
	​

,x
b
	​

,z
h
	​

}]=True

and

FreeQ[r
mσ
	​

,{x
a
	​

,x
b
	​

,z
h
	​

}]=True

hold for every nonzero (m,σ), then

FreeQ[H
m
	​

,{x
a
	​

,x
b
	​

,z
h
	​

}]=True

follows without any assumption that the analytic signatures are independent.

This is a fully sufficient exact certificate.

What a failed block check means

Suppose one block retains x
a
	​

 or x
b
	​

. It is not generally valid to conclude that collinear factorization failed, because two apparently different signatures may obey an exact relation such as

Γ(1+ϵ)=ϵΓ(ϵ),

or

B(a,b)=
Γ(a+b)
Γ(a)Γ(b)
	​

.

A cancellation may therefore occur only after relating or combining different signatures.

The conservative rule is:

every block fraction-free
some block retains fractions
	​

⟹factorization certified,
⟹unresolved unless signature independence is proved.
	​

	​


Do not report the second case as a failure.

Signatures that can normally be treated independently

The following can be used as independent axes once their bases have been proved:

distinct formal PDF/FF products attached to distinct legs;

distinct Fourier harmonics

e
i(n
a
	​

ϕ
a
	​

+n
h
	​

ϕ
h
	​

)
;

a linearly independent physical TT tensor basis;

a certified algebraic radical basis, such as

{1,r
s
	​

,r
T
	​

,r
s
	​

r
T
	​

},

after proving that the generators define the intended algebraic extension;

distinct color-basis elements.

The following should not be assumed independent merely from different syntax:

shifted Gamma functions;

Beta versus Gamma products;

Pochhammer versus Gamma ratios;

hypergeometric functions related by contiguous or transformation identities;

logarithms and polylogarithms on branch-related arguments;

noninteger powers whose bases can be related in the physical chamber;

BMHV structures not yet reduced by all four-dimensional tensor identities.

For the fraction-factorization check, either:

canonicalize all certified identities first; or

place potentially related special functions in one coarser analytic block; or

require each finer block to be fraction-free and mark any contrary result unresolved.

The complete coefficient is required only when a cancellation across unclassified analytic relations must be established.

C. NNLO streaming order

The proposed order is mathematically sound:

	​

read all contributions to one target
→remove the certified common factor
→apply the fixed hadronic map
→split into exact analytic blocks
→normalize rational shells
→apply the sparse Kira row
→accumulate by (m,σ)
→merge exactly and reconstruct.
	​

	​


It preserves exactness if the conditions in part A are satisfied.

The main mathematical caveat

Independent accumulation by (m,σ) can miss cancellations between analytically related signatures. This does not change the reconstructed result if every block is retained. It affects only:

compression;

zero detection;

factorization claims;

route comparisons performed block by block.

The dangerous operations are not splitting or separate accumulation themselves. They are:

discarding a block because it is assumed independent;

declaring a nonzero block physically meaningful before considering signature relations;

concluding that fraction cancellation failed from one noncanonical block;

comparing two routes as unequal solely because they chose different but equivalent signatures.

Define a relation closure among analytic signatures generated by every exact identity that FACET is willing to use. Then accumulate by

(m,[σ]),

where [σ] is a class under those certified identities. Any signatures whose relation is uncertain should be placed in one coarser class or retained for a later unresolved comparison.

Is a complete target coefficient the smallest exact unit?

There are three answers, depending on what “independently” means.

For equality-preserving local cleanup

Any partial sum may be normalized independently if every transformation is exact. This cannot alter the result.

For capturing every pair cancellation at fixed GLI

The required unit is the complete target fibre:

C
α
	​

=
p∈P
α
	​

∑
	​

c
pα
	​

.

A partial target does not expose cancellations with pair contributions that have not yet been read.

For a fixed certified analytic block

A smaller unit is sufficient:

C
α,[σ]
	​

=
p∈P
α
	​

∑
	​

c
pα,[σ]
	​

.

This contains every pair contribution to target α within one certified analytic relation class. It is the smallest useful exact unit for rational normalization without constructing the complete target as one expression.

Similarly, after Kira, the smallest useful block is

K
m,[σ]
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
α,[σ]
	​

.

It contains every target contribution to master m within that analytic class.

Thus the recommended NNLO data flow is

(α,[σ])⟶(m,[σ]),
	​


rather than materializing complete C
α
	​

 and K
m
	​

 expressions.

A more memory-safe implementation

For each pair file:

map every GLI to its canonical target;

remove the common factor;

apply the fixed hadronic and branch maps;

decompose each contribution into (α,[σ]) leaves;

append those leaves to content-addressed target buckets.

When all pair files have been processed:

close each complete (α,[σ]) bucket;

normalize it through a certified balanced merge tree;

stream its products with R
αm
	​

 into (m,[σ]) buckets;

close each complete master block through another certified merge tree.

The exact final master may be stored as

K
m
	​

=
[σ]
∑
	​

A
[σ]
	​

K
m,[σ]
	​


without immediately constructing one monolithic Mathematica Plus. It can be reconstructed one master at a time when required by the final artifact.

Required final checks

For every NNLO master:

every (m,[σ]) merge tree has a complete local certificate;

all 1,296 pair files appear in the source manifests where relevant;

all 44,877 targets are accounted for;

the same 342-master Kira map and cut records are used;

no endpoint distribution or branch atom has been transformed without a certified identity;

no forbidden BMHV or loop object remains;

the declared common hard factor reconstructs the original coefficient;

fraction independence is either certified block by block or marked unresolved;

any independent audit timeout is recorded as unresolved.

There is no mathematical flaw in the proposed streaming order. The only substantive caveat is that syntactically different analytic signatures cannot automatically be treated as linearly independent. Group them by certified identities, retain all remaining blocks, and reserve complete-coefficient reconstruction for questions that genuinely require relations across those blocks.
