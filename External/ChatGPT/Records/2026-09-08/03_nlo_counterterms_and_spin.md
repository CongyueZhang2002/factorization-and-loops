# NLO counterterms and double incoming spin: GPT-6 Pro review

Outgoing request model: gpt-6-pro; HTTP 200; requestMessageId: 3e516547-12f5-4f34-9612-7ecb126cd710. Conversation: https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4

## Supplied prompt

We now have an authorized overnight campaign to produce full NLO single-inclusive pp->hX, distinct-flavor qq'->q+X (observed outgoing q), from a general card-based framework: generated real qq'->qq'g, one-loop/Born interference, UV renormalization, PDF counterterms for both incoming legs, and an unpolarized FF counterterm for the observed leg. First UU, then LL/TT with BOTH incoming quarks polarized (g1*g1*D1 and h1*h1*D1), explicitly confirmed by the user. Do not confuse this with spin transfer to the final state.

We use D=4-2 epsilon, BMHV gamma5, and the existing physical loop normalization d^Dk/(i pi^(D/2)), with phase-space prefactors explicitly restored. Internal massless coordinates are x=-t/s,y=-u/s with x+y<1. We will present in the literature's v=1+t/s=1-x, w=-u/(s+t)=y/(1-x), endpoint w=1. The user insists that production comes from general code and generated amplitudes/integrals, not copying a reference or manually correcting outputs. All final NLO coefficients must be explicit rational functions/logs/polylogs, no unevaluated integrals.

Please review a general counterterm interface: a contribution card declares the leg, incoming PDF versus outgoing FF, spin channel, active parton species, factorization scale, the LO splitting kernel and optional finite factorization-scheme kernel. The kernel has an explicit delta/plus/regular decomposition on xi in [0,1], and the code must derive the convolution momentum map and its Jacobian from the differential observable/phase-space measure. Use the D-dimensional Born expression with its sufficient epsilon orders, not a prematurely four-dimensional Born. UV coupling renormalization is a separate contribution.

We located Jager et al. hep-ph/0211007, Eqs.20-23: their collinear subtraction is -alpha_s/pi times Hqq convolved with the Born, Hqq=(-1/epsilon+gammaE-ln4pi) Pqq (s/muF^2)^epsilon + fqq, and the BMHV helicity-restoring finite term is Delta fqq=-4 CF(1-x). The current package uses normalized measures, so factors of 2/pi/S_epsilon must be derived rather than copied. We also located Mukherjee et al. hep-ph/0506315, Eq.9, which lists only qq (same flavor), q qbar and related channels for double-transverse polarization: distinct incoming qq' appears absent.

Please give a focused critique:
1. Minimal exact contract for the general incoming and outgoing convolution operators, including delta/plus pullbacks, index direction of PDF/FF kernels and Jacobians; which data are truly observable-specific?
2. A convention-safe way to represent MSbar and arbitrary finite scheme changes, with the BMHV restoring term. How to check signs and scale-log coefficients cheaply through RG identities and pole cancellation?
3. Confirm or challenge that double-transverse distinct-flavor qq'->qX is identically zero at NLO by helicity conservation, and how to establish this by a general symbolic projector check rather than a process-name branch.
4. Any non-obvious needed Born channels in mass factorization for this particular observed-quark channel, and useful reference conventions for a comparison.

User-supplied .m file contains A0,B0,C0,A1,B1,C1,A2,A,B,DD,EE,F,G,H,L,M,CC, no header; accompanying four-page PDF says LL qq' but has some sign discrepancies and omits several EE polynomial terms. Eq.24 of hep-ph/0211007 seems to define the basis, to be checked. We treat these only as independent reference data.

Repository: https://github.com/CongyueZhang2002/factorization-and-loops (new changes local). Please do not propose replacing generated coefficients by a literature table, giant brute-force checks or using AMFlow as boundary data.


## Response

The interface is sound, provided it acts on a precisely defined differential density and closes over all species connected by the kernels. For this channel, the consequential extra Born process is qg→qg, entering through the incoming q
′
 leg. The distinct-flavor TT contribution is zero in the standard transversity factorization scheme; a general fermion-trace check can establish this before integration.

1. Exact convolution contract
Kernel direction and the object being transformed

Use explicit daughter ← parent labels, rather than relying on the meaning of P
ij
	​

. With a
s
	​

=α
s
	​

/(2π), define the conventions by

dlnμ
F
2
	​

df
i
	​

	​

=a
s
	​

j
∑
	​

P
i←j
space
	​

⊗f
j
	​

,
dlnμ
D
2
	​

dD
i
	​

	​

=a
s
	​

j
∑
	​

P
j←i
time
	​

⊗D
j
	​

.

The FF equation has the reversed matrix action because D
i
	​

 describes fragmentation from parent i. Keep space-like/time-like labels separate from the spin labels U,L,T. Catani–Seymour’s Eqs. (6.24)–(6.26) provide a useful convention check, although their index notation differs. 
arXiv

For a Born invariant density

B
ab
c
	​

=E
c
	​

d
D−1
p
c
	​

d
σ
^
ab→cX
B
	​

	​

,

the underlying operators are

L
a
	​

[K]B
L
b
	​

[K]B
L
c
	​

[K]B
	​

=
i
∑
	​

∫
0
1
	​

dξK
i←a
	​

(ξ)B
ib
c
	​

(ξp
a
	​

,p
b
	​

,p
c
	​

),
=
j
∑
	​

∫
0
1
	​

dξK
j←b
	​

(ξ)B
aj
c
	​

(p
a
	​

,ξp
b
	​

,p
c
	​

),
=
k
∑
	​

∫
0
1
	​

dξξ
−(D−2)
K
c←k
	​

(ξ)B
ab
k
	​

(p
a
	​

,p
b
	​

,p
c
	​

/ξ).
	​


Here the Born density includes its flux and support. Do not append an additional incoming 1/ξ to these particular formulas.

The outgoing weight is ξ
−2+2ϵ
, not prematurely ξ
−2
. It follows directly from rescaling the D-dimensional observed-particle measure; the same factor appears explicitly in Catani–Seymour Eq. (6.17). Replacing it by its four-dimensional value before multiplying the collinear pole loses a finite 2lnξ contribution. Other differential-density conventions require transforming the whole operator, not just changing this exponent. 
arXiv

Maps for your observable

The following are derived from the stated momentum rescalings. Set

ζ=1−v+vw=x+y.

For 0<v<1, the Born constraint s
′
+t
′
+u
′
=0 gives:

Counterterm leg	Rescaled invariants (s
′
,t
′
,u
′
)	Selected ξ
∗
	​

	Born v
′

Incoming a	(ξs,ξt,u)	w	v
Incoming b	(ξs,t,ξu)	
1−vw
1−v
	​

	vw
Observed c, FF	(s,t/ξ,u/ξ)	ζ	
ζ
vw
	​


When eliminating ξ using δ(s
′
+t
′
+u
′
), its Jacobian is, respectively,

sv
1
	​

,
s(1−vw)
1
	​

,
s
ζ
	​

.

These are only the constraint Jacobians: combine them with the Born flux, outgoing rescaling weight, and the conversion to the requested density. A Born representation using δ(1−w
′
) carries a different intermediate factor.

Two useful coordinate identities for the comparison layer are

∣dxdy∣=v∣dvdw∣,s
4
	​

=s+t+u=sv(1−w).
Delta and plus distributions

The operator must act on distributions through their test-function definition. In particular,

∫
ξ
0
	​

1
	​

dξ[g(ξ)]
+
	​

F(ξ)=∫
ξ
0
	​

1
	​

dξg(ξ)[F(ξ)−F(1)]−F(1)∫
0
ξ
0
	​

	​

dξg(ξ).

The complete Jacobian, rescaled Born, and observable test function belong inside F. Applying this after pairing with a smooth test function avoids treating the Born delta as an ordinary smooth multiplier.

A small exact fixture for your FF map is especially valuable. Under

ξ=1−v+vw,ξ∈[1−v,1],

the restricted distributional density

dξ[
1−ξ
1
	​

]
+
	​


pushes forward to

dw{[
1−w
1
	​

]
+
	​

+lnvδ(1−w)}.

Thus substituting ξ=ζ into the nonendpoint formula and adding a standard plus prescription is insufficient: it misses the delta term.

The observable-specific data are the differential measure, held-fixed variables, measurement/cut support, observed-particle identification and multiplicity, and spin-axis/azimuth prescription. The collinear momentum rescalings and kernel algebra are universal. The card must also inherit the external-state prescription and spin/color averaging conventions. Its spin type must apply to each active species: a helicity quark splitting into an active gluon requires a helicity-gluon Born projector, not a quark projector.

Finally, define exactly what lies inside each plus bracket. For example, multiplying [1/(1−ξ)]
+
	​

 by 1+ξ
2
 is not interchangeable with putting the whole quotient inside the plus bracket without changing the delta coefficient.

2. Scheme conventions, normalization, and cheap checks
Fix signs by a defining transformation

After converting to a common physical-density convention, a useful representation is

d
σ
^
ℓ
ct
	​

=a
s
	​

L
ℓ
	​

[
ϵ
N(ϵ)
	​

(
μ
ℓ
2
	​

Q
2
	​

)
ϵ
P
ℓ
	​

−Z
ℓ
	​

]B
D
	​

.

Here N(ϵ) and Q are determined by the actual normalization factors already extracted from the calculation. They are not adjustable matching parameters. In a convention retaining the usual dimensional constants,

N(ϵ)=1+ϵ(ln4π−γ
E
	​

)+O(ϵ
2
).

Define the finite kernel by its meaning:

f
new
=(1+a
s
	​

Z
f
	​

)⊗f
old
,

and analogously for FFs with the appropriate index action. Substituting the inverse transformations into the factorized cross section gives

C
new
=C
old
−L
a
	​

[Z
a
	​

]B−L
b
	​

[Z
b
	​

]B−L
c
	​

[Z
c
	​

]B.

This fixes the finite hard-counterterm sign without an ambiguous “subtraction kernel” convention. A finite scheme change must transform the distributions and hard coefficients consistently; this is also the basis of the polarized scheme transformations discussed by Vogelsang. 
arXiv

For your loop convention, the elementary normalization bridge is

μ
2ϵ
∫
(2π)
D
d
D
k
	​

F(k)=
(4π)
D/2
iμ
2ϵ
	​

∫
iπ
D/2
d
D
k
	​

F(k).

Combine this with the actual coupling convention and restored cut measures. Establish the overall collinear normalization from one universal splitting calculation with those measures—not by choosing a factor that matches a hard-channel table.

For a simple collinear pole, the finite counterterm requires the complete mapped Born density through O(ϵ), including its Jacobian and normalization. The real/virtual sectors may require deeper Born information when double poles multiply it.

BMHV restoration

The cited helicity-restoring term is correct:

ΔP
qq
D
	​

−P
qq
D
	​

=4C
F
	​

ϵ(1−ξ),Δf
qq
	​

=−4C
F
	​

(1−ξ).

In the quoted convention, the outer minus sign makes this a positive restoring contribution to the hard coefficient. It applies separately to both incoming helicity-quark legs. It does not belong on the unpolarized D
1
	​

 leg or automatically in TT. 
arXiv

Do not apply it twice when a previous conversion has already removed the evanescent splitting-function difference. That distinction is explicit in the comparison between the unconverted and converted D-dimensional kernels in Vogelsang’s Eqs. (55) and (59). 
arXiv

Checks that isolate the likely mistakes

Write the finite hard density as

H
^
=α
s
2
	​

[B+a
s
	​

C],
dlnμ
R
2
	​

dα
s
	​

	​

=−
4π
β
0
	​

α
s
2
	​

	​

,β
0
	​

=
3
11C
A
	​

−4T
R
	​

n
f
	​

	​

.

Differentiating the factorized observable gives the following tests:

∂
lnμ
Fa
2
	​

	​

C
∂
lnμ
Fb
2
	​

	​

C
∂
lnμ
D
2
	​

	​

C
∂
lnμ
R
2
	​

	​

C
	​

=−L
a
	​

[P]B,
=−L
b
	​

[P]B,
=−L
c
	​

[P]B,
=+β
0
	​

B.
	​


Use the spin-appropriate kernels on each leg. Keeping the incoming scales temporarily independent prevents an error on one leg from hiding behind the other.

Check these identities, and the cancellation of the 1/ϵ
2
 and 1/ϵ coefficients of

R+V+UV+PDF
a
	​

+PDF
b
	​

+FF
c
	​

,

distribution by distribution, including endpoint delta terms. Interior point checks cannot see a missing endpoint contribution.

Neither pole cancellation nor these scale derivatives determines the finite BMHV restoration. That needs the small independent splitting/projector identity above, or an equivalent helicity-conservation fixture.

One additional contract restriction follows from your promised output class: literally arbitrary finite scheme kernels need not produce rational/log/polylog answers. Admit arbitrary kernels within the supported analytic class, or reject unsupported ones explicitly.

3. TT distinct-flavor zero: establish it at the generated numerator

Yes, for massless vector QCD in the standard flavor-preserving transversity scheme. Mukherjee et al.’s Eq. (9) corroborates the absence of distinct incoming qq
′
, but the amplitude-level argument is stronger than the channel list. 
arXiv

Helicity conservation fixes each outgoing quark’s helicity to that of its own incoming flavor line. Double-transverse interference flips both incoming helicities between the amplitude and its conjugate. For distinct flavors, the same summed final-helicity state cannot satisfy both assignments.

A particularly inexpensive symbolic implementation works directly in BMHV. The spin-linear incoming projector is proportional to

ρ
T
	​

(p,s
⊥
	​

)=\slashedpγ
5
	​

\slasheds
⊥
	​

.

A massless vector-QCD open fermion chain Γ has odd ordinary-gamma parity: n vector vertices and n−1 massless propagator numerators give 2n−1 gamma matrices. Sewing it to a conjugate chain and an unpolarized final quark produces a trace of the form

tr[\slashedp
c
	​

Γ\slashedp
a
	​

γ
5
	​

\slasheds
a
	​

Γ
′
].

It contains one γ
5
	​

 and an odd number of other gamma matrices. Replacing the BMHV γ
5
	​

 by its four-barred-gamma definition leaves an odd trace, hence zero exactly in D. The same trace-parity mechanism is used to establish vanishing transversity contributions with two separate fermion lines in the splitting-function calculation. 
arXiv

For the specified channel, each distinct-flavor line contains one transverse insertion. This kills the Born square, real-emission interferences, and virtual/Born interferences before integration. There is no residual O(ϵ) numerator to combine with a pole.

Implement the check on the sewn fermion traces of generated diagram pairs. Identical-flavor exchange can put both transverse insertions into one trace; a blanket “two incoming quarks” rule would therefore be wrong.

Two qualifications matter:

Azimuth: the general TT observable must retain the observed azimuth or specify its normalized cos2ϕ projection. Unweighted full-azimuth integration vanishes even for nonzero TT channels and is not a distinct-flavor selection test. Mukherjee et al.’s Eqs. (7)–(8) specify this distinction. 
arXiv

Arbitrary finite flavor mixing: the zero of the generated amplitude does not justify bypassing arbitrary scheme cards. For example, an admitted finite transversity redefinition with

Z
q←q
′
	​


=0

would shift this labeled hard coefficient by

−L
b
	​

[Z
q←q
′
	​

]B
qq
q
	​

,

which need not vanish. Thus the usual TT zero statement assumes the standard flavor-respecting scheme. Either enforce that scheme contract or execute the finite mixing; do not call an individual flavor coefficient scheme-independently zero.

4. Born-channel closure and comparison conventions

For ordinary 
MS
, with the stated diagonal BMHV helicity restoration, the required nonzero routes for a=q, b=q
′
, c=q are:

Leg	Kernel	Required underlying Born
Incoming q	P
q←q
	​

	qq
′
→qq
′
, observed q
Incoming q
′
	P
q
′
←q
′
	​

	qq
′
→qq
′
, observed q
Incoming q
′
	P
g←q
′
	​

	qg→qg, observed q
Outgoing observed q	P
q←q
time,U
	​

	qq
′
→qq
′
, observed q

The third row comes from q
′
→g+q
′
, with the gluon entering the reduced hard scattering. In LL it requires the double-helicity qg Born, weighted by

ΔP
g←q
′
	​

(ξ)=C
F
	​

(2−ξ),

not an unpolarized qg Born. This LO polarized kernel is given explicitly in Vogelsang’s Eq. (30). 
arXiv

The analogous incoming-q gluon route would require a gq
′
→q+X two-body Born, which flavor conservation excludes. The outgoing gluon-parent route would require qq
′
→g+X at Born level, also absent. No separate FF counterterm belongs to the unobserved q
′
: its final-state collinear configurations are inclusive.

For TT, there is no gluon-transversity mixing for spin-
2
1
	​

 hadrons, while the remaining diagonal Born terms vanish by the trace argument. 
arXiv

Generate this closure from the union of the nonzero pole kernels and finite scheme kernels, rather than encoding the table as a process branch.

Reference matching

Jäger Eq. (24) is the relevant coefficient decomposition. It also contains I,J,K, absent from the supplied name list; that alone does not imply missing physics because coefficients may have been regrouped. For example,

Elnw+K
1−w
lnw
	​

=(E+
1−w
K
	​

)lnw.

The names DD, EE, and CC therefore need an accompanying assembly formula, not an inferred mapping. 
arXiv

Match the observed flavor, incoming ordering, LL spin normalization, differential measure, and scale-log directions before comparing coefficients. Also, Eq. (6) multiplies their dΔ
σ
^
(1)
 by an additional α
s
	​

/π: Eq. (24) is not by itself the complete order-α
s
3
	​

 contribution. 
arXiv

Compare reconstructed expressions in a common distribution/logarithm basis—not individual labels—and do not convert endpoint-finite quotients such as lnw/(1−w) into plus distributions unnecessarily.

The exact headerless .m and four-page PDF pair did not appear in the accessible file results. I verified the published basis, but have not independently verified that pair’s sign discrepancies or omitted EE terms.