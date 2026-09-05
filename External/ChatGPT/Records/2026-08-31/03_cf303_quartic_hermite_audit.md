# CF303 Quartic Hermite Audit

## Question

# Continue the established Assess Multiquadratic Pipeline conversation

Please independently audit the current CF303 elliptic-transport direction and the attached exact Maple reducer. We want a decisive mathematical **GO / CORRECT FIRST / STOP** judgment before implementing the mixed GPL/eMPL word engine. Focus on the shortest correct route; do not propose extra hashes, provenance layers, or redundant validation.

## Where the calculation stands

The rational downward-closed CF303 subsystem (21 blocks / 37 masters) is already transported into a paper-facing GPL operator. The remaining algebraic blocks are 15, 17, 21, and 25. Blocks 15, 17, and 21 have accepted epsilon forms in algebraic frames; block 25 is retained in integral form. The first nontrivial exact feeder slice now extracted is the four entries from block 15 into row block 25, at source indices

```
{44,23}, {44,24}, {45,23}, {45,24}
```

for epsilon orders -3 through 6.

After the production path pullback, the odd part lies on the quartic

```
Y^2 = P4(p,u)
P4 = 16 p^6 - 8 p^4 u^2 + p^2 u^4 + 16 p^3 u^2 - 4 p u^4
     - 32 p^4 + 48 p^3 u - 24 p^2 u^2 - 12 p u^3 + 4 u^4
     - 64 p^2 u + 16 p u^2 + 8 u^3 + 16 p^2 + 16 p u + 4 u^2.
```

The square class is generically genus one: gcd(P4,dP4/du)=1 and

```
Disc_u(P4) = 2^22 p^4 (p-1)^4 (p^2-p-1)^2
  (16p^8-64p^7+32p^6+128p^5+24p^4-336p^3+216p^2-16p+1).
```

At the representative production section p=4/11 and path u: 1/2 -> 5/7, the curve is smooth, all four branch roots are nonreal, and the path crosses neither a branch point nor a kernel pole. With

```
rho1 = Y / Dcurve,   Dcurve = 4 p^2 - 4 p - u^2,
```

the conversion used is exactly

```
rho1 * odd(u) du = (P4 * odd(u) / Dcurve) du/Y.
```

There are 36 nonzero elliptic kernels (the four epsilon^-3 odd parts vanish). Their denominators factor over seven nonbranch factors of degree <=2 in u and powers <=3; none shares a factor with P4.

## Implemented exact reduction

For each elliptic kernel R(u) du/Y, the attached Maple code solves for rational F and a squarefree remainder H:

```
R = P4 F' + (P4'/2) F + H,
```

using

```
F = A / gcd(D,D'),
H = B / (D/gcd(D,D')) + c0 + c1 u.
```

This is based on

```
d(FY) = (P4 F' + (P4'/2)F) du/Y.
```

It then splits the squarefree remainder into simple finite poles and records the normalized kernels

```
omega0       = du/Y,
omegaInf     = u du/Y,
omega(c)     = Y(c) du / ((u-c)Y(u)),
```

so a raw pole A du/((u-c)Y) has coefficient A/Y(c). The accepted batch covers all 40 order records, and for every record the exact Hermite residual and exact pole reconstruction vanish. Total Maple wall time was 75.232 s; each linear solve took 0.116--0.400 s. No modular reconstruction or Weierstrass conversion was used.

An independent local audit agrees that direct quartic Hermite reduction is the smallest route, but notes a possible missing polynomial differential: after reduction on a quartic, a general remainder may require a second-kind-at-infinity basis element, e.g.

```
(u^2 + a3/(2 a4) u) du/Y,
```

in addition to du/Y and u du/Y. The current particular batch happened to fit only c0+c1 u because the ansatz solved exactly; we need to know whether that is an accidental property of this feeder slice or a basis assumption that will fail for later blocks.

## Intended mixed GPL/eMPL continuation

The rational/even remainders join the existing GPL alphabet. The elliptic simple-pole and first/second-kind forms become eMPL letters. Exact derivative pieces should not be kept as artificial letters. When an exact term multiplies an already-solved lower function J, we intend to use the terminating blockwise integration-by-parts recursion

```
Integral d(FY) J
  = FY J |_(u0)^u - Integral FY dJ.
```

Since dJ is known from a lower block or preceding epsilon order, this should lower word/block depth. Any resulting algebraic rational differential is converted back to a polynomial-over-Y kernel and Hermite-reduced in the same quartic basis. The proposed topological order is rational subsystem -> 15 -> 17 -> 21 -> 25, subject to an exact edge census.

## Questions requiring a concrete answer

1. Is the conversion to R du/Y and the exact identity d(FY) above correct with no missing factor or sign?
2. Is the attached global ansatz F=A/gcd(D,D') mathematically complete for these rational quartic kernels, or should it be replaced by the local pole-lowering recurrence modulo each q? If both are correct, which is the smaller and safer production algorithm?
3. What is the minimal complete differential basis on a quartic for the reduced remainder? In particular, must we include a second-kind-at-infinity u^2 combination even though all 36 current kernels solve with only c0+c1 u?
4. Is splitting quadratic denominator factors into algebraic pole labels c acceptable for paper-facing eMPLs, or should production retain root-free quadratic pairs?
5. Does the integration-by-parts recursion above really terminate without increasing the functional class or reintroducing uncontrolled repeated poles? State the exact recursion/invariant that the implementation should use.
6. Is it legitimate to build the remaining solution in the topological order 15 -> 17 -> 21 -> 25, or is a full coupled elliptic fundamental matrix needed somewhere?
7. What is the smallest next implementation milestone that would prove this route on an actual nontrivial coefficient, rather than merely producing a kernel catalogue?

Please separate mandatory mathematical corrections from optional presentation or performance improvements. The user wants a paper-usable GPL/eMPL result up to boundary constants, not unevaluated integrals.

## Pro response

Verdict: CORRECT FIRST, then GO

Keep the 40 accepted reductions. An undersized ansatz does not invalidate a decomposition whose exact residual is zero. But the current reducer is not complete enough for recursive transport: it needs a quadratic remainder and, for polynomial inputs of sufficiently high degree, a polynomial part in the primitive.

The shortest correct route is:

Complete the present quartic reducer, then implement integration by parts with strictly decreasing word length. Demonstrate one actual depth-two feeder contribution before expanding all four algebraic blocks.

I read the full attached 135-line Maple script. Its externally loaded kernel file and generated reduction records were not attached, so I treat the reported batch results as supplied. I independently reproduced the displayed discriminant from the given P
4
	​

.

1. The conversion and derivative identity are correct

With p held fixed along the u-path,

Y
2
=P
4
	​

,ρ
1
	​

=
D
curve
	​

Y
	​

,

gives

ρ
1
	​

odd(u)du=
D
curve
	​

P
4
	​

odd(u)
	​

Y
du
	​

.
	​


There is no missing factor or sign. Likewise,

d(FY)=(P
4
	​

F
′
+
2
P
4
′
	​

	​

F)
Y
du
	​

.
	​


The Maple implementation uses precisely this operator and subtracts it with the correct sign in both construction and residual evaluation. 

reduce_cf303_row25_elliptic_her…

These are identities on the selected sheet; they do not involve replacing 
H
2
	​

 by H. They remain valid under Y↦−Y if that change is applied consistently.

Scope: this is fixed-p transport. If a later segment has p=p(u), the derivative becomes a total derivative and includes p
′
(u)∂
p
	​

P
4
	​

. The present Maple diff(...,u) cannot be reused unchanged for that segment.

2. The finite-pole denominator is right; the infinity ansatz is incomplete

Write the reduced rational input as R=N/D, with

gcd(D,P
4
	​

)=1,Q=gcd(D,D
′
),S=D/Q.

For nonbranch poles, the rational primitive has finite denominator dividing Q. Thus the current choice

F
proper
	​

=
Q
A
	​

,degA<degQ

correctly accommodates all finite repeated-pole reductions.

However, the attached code restricts the remainder to

S
B
	​

+c
0
	​

+c
1
	​

u

and restricts F to a proper rational function. Those restrictions are explicit in hermiteElliptic. 

reduce_cf303_row25_elliptic_her…

A quadratic remainder is mandatory—even for a proper input

Consider the smooth quartic

Y
2
=u
4
+1,R=
u
2
1
	​

.

Then

u
2
Y
du
	​

=d(−
u
Y
	​

)+
Y
u
2
du
	​

.
	​


The input has only a repeated nonbranch finite pole. Nevertheless, reducing it necessarily produces the quadratic differential. The current c
0
	​

+c
1
	​

u ansatz cannot represent this example.

Thus the absence of that coefficient in your 36 kernels is a property of this slice, not a quartic reduction theorem.

A polynomial primitive is also necessary in general

For example,

R=
2
P
4
′
	​

	​


has primitive Y, requiring F=1. The present proper-rational ansatz excludes it.

For a quartic with leading coefficient a
4
	​

,

(P
4
	​

∂
u
	​

+
2
P
4
′
	​

	​

)u
k
=(k+2)a
4
	​

u
k+3
+lower powers.

Therefore polynomial terms of degree at least three can be removed recursively, leaving degree at most two.

Minimal patch

Keep the existing global linear solve, but use

F=
Q
A
	​

+F
pol
	​

,H=
S
B
	​

+c
0
	​

+c
1
	​

u+c
2
	​

u
2
.
	​


Use

degA<degQ,degB<degS.

If the polynomial part of R has degree d≥3, allow

degF
pol
	​

≤d−3;

otherwise omit F
pol
	​

.

That is a complete reduction ansatz for rational R whose finite denominator is coprime to the squarefree quartic. No new general-purpose solver is needed.

Local reduction is an alternative, not tonight’s prerequisite

For a nonbranch factor q and a leading term α/q
m
, m≥2, choose

F
q
	​

=
q
m−1
a
	​

,

where, in the residue field modulo q,

a≡−α[(m−1)P
4
	​

q
′
]
−1
(modq).
	​


Subtracting d(F
q
	​

Y) lowers the q-pole order. This yields a deterministic local algorithm.

But with reported linear solves of 0.116–0.400 seconds, replacing the global solve is not the highest-value change. Add the missing columns and retain it.

If a future input contains a factor q∣P
4
	​

, the nonbranch formula no longer applies: branch-point poles require a separate lowering rule, and generally F may need the same q-denominator order as R. Do not send such a pole to the present Y(c)-normalized simple-pole path.

3. The complete quartic remainder basis has three polynomial differentials

Write

P
4
	​

=a
4
	​

u
4
+a
3
	​

u
3
+a
2
	​

u
2
+a
1
	​

u+a
0
	​

.

A convenient complete odd basis, modulo exact algebraic differentials and allowing the specified nonbranch finite poles, is

ω
0
	​

=
Y
du
	​

,ω
∞
	​

=
Y
udu
	​

,η
2
	​

=(u
2
+
2a
4
	​

a
3
	​

	​

u)
Y
du
	​

,
	​


together with

ω
c
	​

=
(u−c)Y
Y
c
	​

du
	​

.

Their roles are different:

ω
0
	​

 is holomorphic.

ω
∞
	​

 is third kind, with opposite nonzero residues at the two points above infinity.

η
2
	​

 is second kind, with double poles but zero residues at infinity.

Each nonbranch ω
c
	​

 is third kind, with residues +1,−1 at the two points above u=c.

The quartic distinction between udu/Y and the second-kind quadratic combination is explicitly discussed by Broedel–Duhr–Dulat–Tancredi, Part I, §7, equations (113)–(116). 
arXiv

For your polynomial,

a
4
	​

=(p−2)
2
,a
3
	​

=8−12p,

so

η
2
	​

=(u
2
+
(p−2)
2
4−6p
	​

u)
Y
du
	​

.

At p=4/11, this becomes

η
2
	​

=(u
2
+
81
55
	​

u)
Y
du
	​

.
	​


A constant multiple of ω
0
	​

 can be added to η
2
	​

 to match a preferred period normalization.

Do not confuse a complete differential basis with the standard E
4
	​

 alphabet

An internal word alphabet containing η
2
	​

 defines valid elliptic iterated integrals, but η
2
	​

 is not one of the standard simple-pole E
4
	​

 kernels.

For standard paper-facing E
4
	​

 notation, the second-kind primitive is expressed using the conventional Z
4
	​

 function and a holomorphic-period correction. Iterations then introduce the corresponding Z
4
	​

-dependent kernels. Only finitely many are needed at fixed integration depth. 
arXiv

The economical implementation is:

Keep the complete algebraic differential basis internally. Translate the actually occurring second-kind words to the established E
4
	​

,Z
4
	​

 representation at output.

Do not discard η
2
	​

 as an “exact piece”: it is not dA for an algebraic A∈Q(p,u,Y). Introducing its transcendental primitive is a different operation from removing d(FY).

4. Quadratic pole labels are legitimate

The script’s simple-pole coefficient is

A
c
	​

=
D
′
(c)
N(c)
	​

,

and the normalized coefficient is

Y
c
	​

A
c
	​

	​

.

That is correct for a reduced proper rational function with squarefree denominator and P
4
	​

(c)

=0. The implemented reconstruction sums A
c
	​

/(u−c), exactly as required. 

reduce_cf303_row25_elliptic_her…

Splitting quadratic factors into algebraic labels c
±
	​

 is entirely acceptable. At fixed p, these are algebraic constants/marked points, not new u-dependent covers.

Store a pole as a marked point

(c,Y
c
	​

),Y
c
2
	​

=P
4
	​

(c).

Changing Y
c
	​

 to −Y
c
	​

 changes both the normalized kernel and its coefficient by a sign, leaving the term unchanged. The same choice must be used in both places; separately reevaluating principal square roots during later analytic continuation is not a reliable label convention.

Root-free quadratic pairs are an optional engineering improvement:

q(u)Y
du
	​

,
q(u)Y
udu
	​


can be retained internally and split only during export. There is no mathematical reason to replace the current successful quadratic splitting now.

Also, use the actual base point u
0
	​

=1/2. Standard zero-based E
4
	​

 functions require base-point conversion constants; simply renaming the endpoint variable does not perform that conversion.

5. Integration by parts terminates if it lowers word length

The proposed identity

∫d(FY)J=FYJ
	​

u
0
	​

u
	​

−∫FYdJ

is correct. But “the derivative refers to a lower block or epsilon order” is not, by itself, a sufficient implementation invariant.

The clean invariant is the length of an already constructed iterated-integral word.

Exact recursive algorithm

Let E(w;u) denote base-u
0
	​

 iterated integrals, with

dE(av;u)=ω
a
	​

(u)E(v;u),E(∅;u)=1.

For an algebraic differential η, perform complete rational/elliptic reduction

η=dA+
b
∑
	​

c
b
	​

ω
b
	​

,A∈K=Q(p,u,Y),

where the c
b
	​

 are independent of u. Define

J(η,w)=∫
u
0
	​

u
	​

ηE(w).

For the empty word,

J(η,∅)=A(u)−A(u
0
	​

)+
b
∑
	​

c
b
	​

E(b;u).

For w=av,

J(η,av)=
	​

A(u)E(av;u)−A(u
0
	​

)E(av;u
0
	​

)
+
b
∑
	​

c
b
	​

E(b,a,v;u)−J(Aω
a
	​

,v).
	​

	​


The only recursive integral has tail length ∣v∣=∣w∣−1. This proves termination.

If a lower coefficient is

J=
w
∑
	​

a
w
	​

(u)E(w;u),

first absorb a
w
	​

(u) into η. Do not differentiate the full algebraically weighted expression and assume its word length decreases.

Products of lower words can first be shuffled into sums of words. Rational/even kernels then become GPL letters inside the mixed elliptic words; integrating a rational kernel against an elliptic lower function does not generally produce a pure GPL.

Repeated poles can return, but do not cause an infinite recursion

The product Aω
a
	​

 may have higher pole order. Reduce it again. Pole order need not decrease between recursive calls; word length does. At any fixed word depth, only finitely many such reductions occur.

All this stays on the same elliptic curve if the coefficients and kernels belong to K. This is the algebraic foundation of the integration algorithms in BDDT Part I, §§6 and 7.4. Their standard E
4
	​

,Z
4
	​

 formulation uses a refined total-length filtration when Z
4
	​

-powers are present. 
arXiv
+1

Do not implement generic repeated IBP on opaque master functions. Implement the displayed recursion on words, using the existing sparse word representation.

6. Block order is legitimate under two explicit conditions

The order

rational subsystem→15→17→21→25

is legitimate if the exact edge census establishes that block-triangular dependency order.

For a block in a genuine epsilon form,

dJ
i
	​

=ϵA
ii
(1)
	​

J
i
	​

+
j<i
∑
	​

A
ij
	​

(ϵ)J
j
	​

,

its coefficient equation is

dJ
i
(n)
	​

=A
ii
(1)
	​

J
i
(n−1)
	​

+
j<i,k
∑
	​

A
ij
(k)
	​

J
j
(n−k)
	​

.

Thus same-block dependence lowers epsilon order, and cross-block dependence goes to an already solved block. Negative off-diagonal orders affect the required Laurent depth of lower blocks; they do not invalidate topological integration.

Two conditions remain essential:

Common function field. Every coefficient entering a mixed word must lie on this same quartic, or be mapped to it. The four inspected feeder entries establish this for the slice, not automatically for all entries in blocks 15, 17, 21 and 25. A different independent u-dependent radical cannot silently be treated as another marked point of the same curve.

No unresolved order-zero diagonal system. If block 25’s diagonal is still the certified epsilon-linear diagonal from the preceding campaign, coefficientwise recursion applies despite the unsolved off-diagonal normalization. If a genuinely nontrivial ϵ
0
 diagonal remains, solve that block’s homogeneous fundamental matrix first and use variation of constants.

There is no need to construct one giant coupled elliptic fundamental matrix merely because several blocks use elliptic kernels.

The current reducer also leaves evenKernel only normalized and stored; it does not perform its rational Hermite/partial-fraction reduction. Reuse the GPL-side rational reducer for that part before mixed-word insertion. 

reduce_cf303_row25_elliptic_her…

7. Smallest meaningful implementation milestone

Produce one actual depth-two feeder contribution, not another catalogue and not a constant-boundary integral.

Choose one of the four recorded entries for which:

the exact primitive A=FY is nonzero; and

an actual needed lower-block coefficient contains a nonconstant word.

For a first lower word E(a), reduce

η=dA+
b
∑
	​

c
b
	​

ω
b
	​

,Aω
a
	​

=dB+
b
∑
	​

d
b
	​

ω
b
	​

.

Then the contribution is explicitly

∫
u
0
	​

u
	​

ηE(a)=A(u)E(a;u)−[B(u)−B(u
0
	​

)]+
b
∑
	​

c
b
	​

E(b,a;u)−
b
∑
	​

d
b
	​

E(b;u).
	​


There is no unevaluated feeder integral. This exercises precisely the currently missing operation: an exact algebraic primitive multiplying and then differentiating a nonconstant lower function.

For the physical milestone, collect all terms contributing to one selected row-25 coefficient multiplying one block-15 boundary constant, including any other paths required by the edge census and the row-25 diagonal recurrence. Keep the output as sparse algebraic-prefactor/GPL/E
4
	​

 words, and export only that coefficient first.

Minimal changes before that run
Item	Judgment
Rdu/Y conversion and d(FY) identity	GO: correct
Existing 40 exact reductions	Keep: valid for the reported batch
Remainder restricted to c
0
	​

+c
1
	​

u	CORRECT FIRST: add c
2
	​

u
2

Primitive restricted to proper A/Q	CORRECT FIRST: add the degree-bounded polynomial part
Replacing the fast global solve by local lowering	Optional; not needed now
Algebraic quadratic pole labels	GO, with one consistent marked-point convention
Treating every new differential as a standard simple-pole E
4
	​

 letter	CORRECT FIRST, especially the second-kind form
IBP based only on block names/order	Replace by the explicit word-length recursion
Full coupled elliptic matrix for all remaining blocks	Not required if diagonal epsilon recursion and field closure hold

The route is viable. The mandatory correction is a complete quartic reduction at infinity and a word-length-decreasing integration engine. The next deliverable should be one nonconstant physical coefficient expressed in finite GPL/E
4
	​

,Z
4
	​

 terms—not a larger alphabet or a new normalization framework.

## Sources sent to Pro

- Original source reference: `../../../../factorization-and-loops-codex/Diagnostics/Scripts/reduce_cf303_row25_elliptic_hermite.mpl` (not archived with this exchange)
