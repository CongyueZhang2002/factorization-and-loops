# Dimensional recurrence laurent bounds

Model: gpt-6-pro. Date: 2026-09-05 (America/Los_Angeles).
Conversation: 6a9c64ec-3cc4-83e8-b40c-9b568241fd3b.

## Question

Thank you. We will implement the positive-mass deformation certificate, with fixed EXTERNAL null vectors as anchors in two-sided cone proofs (a cut momentum may become timelike under deformation). Pure future-causal sum proofs remain valid under nonnegative cut-mass deformations. Fallback QE will use the full deformed domain, not just the on-shell slice.

We have now tested dimensional recurrence at one ordinary rational point, since the dimension-counting bounds range -4 to -5 even for some finite lower-sector masters. A fresh one-variable Kira reduction for all Gram-polynomial insertions in the 23-master representative took 148 seconds; the exact table is only 374 KB. Assembling and inverting R took about 1.2 seconds total. The inverse has potential even dimension poles >=4 only at D=4 and 6. Exact matrix products give entrywise row lower bounds
{-3,-3,-3,-3,0,0,-1,-1,-3,-3,-3,-3,-3,-3,-1,-2,-2,-3,-2,-3,-3,-3,-3}.
These are much tighter than -4/-5, so avoiding multiple unnecessary solution orders is worth this one-time per-family reduction. No AMFlow or master values were used.

Please check this SHORT further argument, which avoids calculating a numerical convergence dimension at all:
1. Compact positive-mass deformation + uniform Lojasiewicz establishes existence of D_star such that every bare master is holomorphic for all sufficiently large real D (no UV in compact pure phase space).
2. Compute S(D)=R(D)^-1 exactly as a rational matrix at the fixed kinematic point, factoring all actual denominators after cancellations.
3. Choose D_safe=4+2K strictly beyond every EVEN integer >=4 at which S(D) has a pole. In this example D_safe=8. Thus S(D_safe+2j-2eps) is epsilon-regular for all nonnegative integers j.
4. There exists some finite J with D_safe+2J>D_star. The exact recurrence expresses I(D_safe-2eps) as a FINITE product of epsilon-regular S matrices times the holomorphic high-dimensional I(D_safe+2J-2eps). Hence I(D_safe-2eps) is holomorphic, even though J is not calculated.
5. Therefore the explicit finite product S(4-2eps)...S(D_safe-2-2eps) supplies a proved lower bound at 4-2eps. We do not claim the bound is sharp; relations among high-dimensional constants may improve it.

Is there any gap? Gamma/phase factors analytic nonzero in epsilon are kept outside the rational matrix. With AMFlow phase normalization and L phase loops, our convention is I(D+2)=(2 Pi)^(-L) R(D) I(D), where R is Gram insertion divided by Product[D-E-j+1,{j,L}]. Additional explicit master prefactors are accounted separately; the recurrence is for bare GLI definitions. A rational inverse matrix, complete master basis and genuine meromorphic recurrence identity are all required. At physical threshold points, noncompact/mixed virtual cases or failed mass-deformation certificates this method refuses a bound.

Please focus on confirming or correcting the eventual-holomorphy/finite-critical-dimension argument, not repeating the broad method comparison.


## Pro response

Your argument is correct under the stated assumptions. No numerical convergence dimension or explicit value of J is required. The only necessary clarification is that step 1 must establish holomorphy in complex-D neighborhoods of all sufficiently large even dimensions, not merely convergence or finite values at real integer dimensions.

The positive-mass deformation argument, with uniform integrable domination in an open convergence half-plane, supplies precisely that stronger statement.

1. Finite descent proves holomorphy at D
safe
	​


Write

I
d
	​

(ϵ):=I(d−2ϵ),S
d
	​

(ϵ):=S(d−2ϵ).

Your normalization gives

I
d
	​

(ϵ)=(2π)
L
S
d
	​

(ϵ)I
d+2
	​

(ϵ).
	​


Choose d
s
	​

=D
safe
	​

 so that every entry of

S
d
s
	​

+2j
	​

(ϵ),j≥0,

is holomorphic at ϵ=0.

By eventual holomorphy, there exists a finite J such that I
d
s
	​

+2J
	​

 is holomorphic. Repeated application of the genuine meromorphic recurrence gives

I
d
s
	​

	​

=(2π)
JL
S
d
s
	​

	​

S
d
s
	​

+2
	​

⋯S
d
s
	​

+2J−2
	​

I
d
s
	​

+2J
	​

.

Every factor on the right is holomorphic at ϵ=0. Therefore

I(D
safe
	​

−2ϵ)∈C[[ϵ]]
r
.
	​


The unknown J is not a gap: the proof uses the existence of one finite product, not a limit of products as J→∞. No growth estimate, convergence of an infinite product, or high-dimensional master value is needed.

Likewise, S(d
s
	​

+2j) need not be invertible at the exact integer dimension. It may lose rank or have zeros there. Holomorphy of its entries suffices because the argument only multiplies by it.

2. The explicit prefix supplies the bound at four dimensions

For D
safe
	​

=4+2K, define

M
K
	​

(ϵ)=S(4−2ϵ)S(6−2ϵ)⋯S(D
safe
	​

−2−2ϵ),

with increasing dimensions ordered from left to right. Then

I(4−2ϵ)=(2π)
KL
M
K
	​

(ϵ)I(D
safe
	​

−2ϵ).

Since the final vector is holomorphic,

ν
ϵ
	​

I
i
	​

(4−2ϵ)≥
j
min
	​

ν
ϵ
	​

(M
K
	​

)
ij
	​

.
	​


That proves your entrywise row bounds. Exact cancellation in the finite matrix product legitimately improves them; relations or zeros among the high-dimensional master coefficients can improve the actual valuations further.

For your reported pole set {4,6},

I(4−2ϵ)=(2π)
2L
S(4−2ϵ)S(6−2ϵ)I(8−2ϵ),
	​


and the preceding argument establishes that I(8−2ϵ) is holomorphic—even without proving that the defining integral already converges at D=8.

That last distinction is important: D
safe
	​

 is an analyticity point established by recurrence, not necessarily a convergence dimension for the original integral representation.

3. Normalization and the qualifications that matter

Your stated phase-space shift factor is consistent with the supplied measure. Under D↦D+2, its dimension-dependent factors contribute

(2π)
−2L
π
L
∏
j=1
L
	​

(D−E−j+1)
2
L
	​

=
∏
j=1
L
	​

(D−E−j+1)
(2π)
−L
	​

.

Thus, with the Gram insertion and the rational denominator included in R(D), the backward multiplier is indeed (2π)
L
S(D). Keeping the dimension-dependent normalization when deriving a Baikov dimensional recurrence is essential. 
arXiv

Three qualifications remain, all compatible with what you stated:

Scan the complete backward multiplier. Any additional factored D-dependent scalar or matrix must be holomorphic at every tail center used by the argument. Being analytic and nonzero near D=4 alone is insufficient. Your constant (2π)
L
 causes no issue.

The recurrence must hold meromorphically for the complete vector. A relation verified only at integer dimensions would not suffice. Nor would a sector recurrence with an omitted inhomogeneous lower-sector contribution. Including all required lower sectors makes the system homogeneous; alternatively, their contributions must be treated explicitly. Dimensional-recurrence treatments distinguish these two forms. 
arXiv
+1

The result is at the specified kinematic point. Exact specialization can produce additional cancellations, and those cancellations are valid for bounding the physical constants at that point. They do not by themselves establish a uniform bound over kinematics.

Only poles at the relevant even integer centers matter for these local Laurent bounds. Odd, noninteger, or complex poles do not obstruct holomorphy in a sufficiently small neighborhood of an even center. Rationality ensures that the exceptional set is finite.

4. Eventual holomorphy is the essential physical input

The recurrence alone would not prove the result. For example,

f(D)=cot(
2
πD
	​

)

satisfies f(D+2)=f(D), so its inverse recurrence coefficient has no poles, but f has poles at every even dimension. Your high-dimensional holomorphy hypothesis excludes exactly this possibility.

Thus the method is not inferring physical analyticity from the recurrence alone. It combines a convergence-based existence theorem with a finite rational calculation.

Given your reported exact factorization and matrix product, the 23-component vector is therefore a proved set of lower bounds for the bare masters at that ordinary point, conditional on the certified hypotheses—not merely numerical evidence. I have not independently recomputed the local matrix. The two zero bounds establish holomorphy there; the −3 entries establish at most triple poles, not necessarily triple poles.

This closes the convergence-dimension issue: establish eventual holomorphy once, locate the finite exceptional even dimensions of the backward recurrence, and compute only the prefix below them.