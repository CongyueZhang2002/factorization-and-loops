# CF303 Expanded dlog Followup

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation. We have
now run the decisive recovery you recommended on the real CF303 `(25,18)`
block. Please reassess the mathematics of the letter span and recommend the
next algorithmic step. Do not recommend more hashes, provenance checks, or
full symbolic verification; production acceptance remains random-point exact
arithmetic modulo primes plus the existing per-block/family certificate.

Measured result:

1. Exact rational-chart materialization is now 489.6 s versus 1477.2 s before.
2. The 48 exact candidate dlogs were built with all eight kernels: the brokered
   construction was 157.5 s versus 1513.8 s serially.
3. We passed the complete ordered set of 48 precomputed dlogs to the ordinary
   rational finite-field solver while retaining the original A3 denominator
   and certified degree-58 support. The resulting certified-simplex system is
   exactly `7280 x 7272`; the rectangle is `7952 x 7944` at offset `{0,0}`.
4. The full 48-letter system is inconsistent at the base simplex and rectangle
   and remains inconsistent over the bounded numerator-offset ladder so far.
   Hence selecting a subset through the cokernel cannot rescue this candidate
   span: the full span already fails. The old 16-letter system was `7152 x
   7144`, so the expected 128 extra residue columns are genuinely present.
5. The 48 records are 32 dlogs of whole forcing entries at regulator samples
   `{1,2,3,5}` plus 16 rational polar factors. They are exact precomputed
   one-forms; this is not an `ExtraLetters` differentiation bug.
6. We still regard one-extra-copy denominator widening as mathematically
   excluded by the divisorial leading equation `-m H - eps E_f H + eps H C_f
   = 0`, whose determinant has constant term `m^4`, under the established
   logarithmic-pole assumptions.

The likely gap is that dlog of a whole sampled forcing entry provides only one
linear combination of its numerator irreducible-factor dlogs. Independent
residues may require those numerator divisors separately. Please determine:

- Is adjoining dlogs of the irreducible numerator factors of the sampled
  forcing entries the mathematically correct next complete span, together with
  the existing denominator/polar factors?
- Can the needed factor/divisor span be found primarily modulo primes (or from
  a full-system cokernel) so we avoid factoring every huge characteristic-zero
  numerator and constructing every exact dlog?
- What exact completeness statement should the rational-letter candidate set
  satisfy for a rank-zero rational chart? Is the union of irreducible divisors
  of diagonal blocks, forcing coefficients, and the gauge denominator enough,
  or can valid dlog letters require new divisors not visible there?
- If numerator factorization is the next step, give a concrete finite-field
  algorithm: sampled factorization/recombination across primes, how to keep
  factors aligned, and when exact reconstruction is actually necessary.
- Is there any plausible flaw in the no-extra-pole valuation argument that
  would make denominator promotion relevant despite the full letter span
  failure?

Please give a prioritized GO/NO-GO plan. We want the next discriminating pilot,
not a broad defensive redesign.

## Pro response

Updated verdict

NO-GO on broadly adjoining irreducible numerator-factor dlogs as the next production route.

GO on one smaller, decisive pilot: complete the logarithmic alphabet at the level of the geometric components of the actual projective polar divisor, project that maximal component span through the full-system cokernel, and test it at two primes.

If the 16 current polar curves are already absolutely irreducible and include the projective-infinity contribution, then the rational/algebraic-dlog letter axis is already complete. In that case, factorizing the huge sampled forcing numerators cannot repair the inconsistency; the next axis is the gauge numerator space—or, if the degree-58 simplex is a rigorous upper bound, the conclusion is that no rational dlog strip gauge exists under the current diagonal normalization and denominator contract.

1. Splitting forcing numerators is not the complete-letter theorem

It is true that

dlog(
i
∏
	​

f
i
n
i
	​

	​

)=
i
∑
	​

n
i
	​

dlogf
i
	​

,

so replacing one whole-entry dlog by the dlogs of its irreducible factors can enlarge the presented column span.

But that does not make forcing-numerator factors the mathematically complete alphabet.

Let

Ω(G)=
B
ˉ
+ϵ(EG−GC)−dG

and let S be the reduced projective divisor on which Ω(G) can have poles. Suppose

Ω(G)=ϵ
a
∑
	​

R
a
	​

(ϵ)dlogL
a
	​

,L
a
	​

∈Q(p,q)
×
.

Factor every letter over the relevant constant field:

L
a
	​

=c
a
	​

h
∏
	​

h
n
a,h
	​

.

Then

Ω(G)=ϵ
h
∑
	​

(
a
∑
	​

n
a,h
	​

R
a
	​

(ϵ))dlogh.

For any irreducible divisor h∈
/
S, the residue of Ω(G) along h=0 must vanish. Therefore

a
∑
	​

n
a,h
	​

R
a
	​

(ϵ)=0.

All factors outside S disappear from the representation, leaving only dlogs of the components of S.

Hence:

Nonpolar forcing-numerator factors cannot enlarge the effective dlog span.
	​


They can occur in a redundant alphabet, with their residues canceling, but any such solution can be rewritten using only the actual polar components.

This is consistent with the standard rational-alphabet viewpoint: rational letters are controlled by the singular divisors of the differential equation, while algebraic alphabets require a more careful component analysis. 
arXiv
+1
 Logarithmic forms are locally generated by df
i
	​

/f
i
	​

 for equations of the divisor components. 
arXiv

An additional problem with sampled numerators

The numerators at

ϵ∈{1,2,3,5}

are specialized polynomials. Their factorizations may contain accidental factors that do not persist for generic ϵ. They are valid epsilon-independent functions after specialization, but they are not naturally tied to the generic singular locus.

Thus a union of all specialized numerator factors can become very large while remaining mathematically irrelevant to the canonical alphabet.

2. The correct completeness statement

For this rank-zero rational chart, define the projective polar divisor

S=S
E
	​

∪S
C
	​

∪S
B
ˉ
	​

∪S
D
	​

∪S
chart
	​

∪S
∞
	​

,

where:

S
E
	​

,S
C
	​

,S
B
ˉ
	​

 are the irreducible pole divisors of the reduced diagonal and forcing entries;

S
D
	​

 is the gauge-denominator divisor;

S
chart
	​

 contains any Jacobian or exceptional divisors surviving in the pulled one-forms;

S
∞
	​

 is the projective divisor at infinity.

Then the complete candidate space for a rational dlog connection is generated by the dlogs of the geometric irreducible components of S, with Galois-invariant coefficient combinations.

The word “geometric” matters.

A polynomial irreducible over Q can split over an algebraic extension of the constant field. In that case,

dlogf

only gives the sum of the component dlogs. Trace-zero combinations of the component dlogs can yield additional rational one-forms.

A simple model is

f=p
2
+q
2
=(p+iq)(p−iq).

The sum of the two component dlogs is dlogf, but their difference divided by i is also rational over Q and is not a multiple of dlogf.

Therefore:

The 16 rational factors are complete only if their geometric-component span has also been included.
	​


If every one of the 16 projective polar curves is absolutely irreducible over the declared constant field, then the existing 16 factor dlogs are complete, modulo the projective-infinity relation and any regular exact part already excluded by your logarithmic infinity test.

What is not needed

The complete divisor list does not require:

irreducible factors of generic forcing numerators;

zeros of gauge numerators;

arbitrary Landau-like candidate factors not present as poles;

factors generated by sampling at special regulator values.

Those can appear in nonminimal letter presentations, but they cannot enlarge the minimal logarithmic span.

3. The next decisive pilot

Use the full-system cokernel, but apply it to the geometric polar components rather than to forcing numerators.

Step 1: start from the 16-polar-letter system

Let

M
pol
	​

=[
M
gauge
	​

	​

M
polar
	​

	​

],M
pol
	​

x=b.

Compute a basis W of its left cokernel:

WM
pol
	​

=0.

The current obstruction is

w=Wb.
Step 2: obtain the maximal geometric-component columns

For every one of the 16 reduced projective polar factors f
j
	​

:

Determine whether f
j
	​

 is absolutely irreducible over the exact constant field.

If it splits into geometric components

f
j
	​

=
α
∏
	​

h
j,α
	​

,

construct the independent Galois-invariant combinations of

dlogh
j,α
	​

.

Form their residue-column blocks C
j,α
	​

.

Let C
geom
	​

 be the union of only the genuinely new component directions—not the already included sums dlogf
j
	​

.

Then test

rank(WC
geom
	​

)=rank[
WC
geom
	​

	​

w
	​

].
	​


Run this at two independent good prime/regulator images.

Outcome

Inconsistent: the entire rational/algebraic-dlog alphabet supported on the known polar divisor is insufficient. Close the letter axis.

Consistent: identify which polar components contribute, construct only those exact component letters or rational trace forms, and run one full rational solve.

This pilot should be much smaller than the 7280×7272 physical system because it operates only in the cokernel.

4. This can be done mainly modulo primes

You do not need to factor every huge forcing numerator—or even reconstruct every geometric polar component exactly—to run the decisive pilot.

Modular maximal-component test

At a good prime p:

Homogenize each of the 16 polar factors.

Factor it over F
p
	​

, or over the smallest finite extension needed.

Construct dlogh for every modular component h.

Form the corresponding residue columns at the existing finite-field points.

Project them with W.

Test whether their complete span contains Wb.

For a first discriminator, choose primes at which the relevant constant-field factors split over F
p
	​

. Then all component columns remain ordinary base-field columns.

No cross-prime component alignment is required merely to answer:

Wb∈span(WC
geom
	​

)?

The maximal component span can be tested independently at each prime.

Only reconstruct exact factors after a positive result

If the projected system becomes consistent:

Identify the polar polynomial or polynomials responsible for the new directions.

Perform exact absolute factorization only for those small polar curves.

Construct the Galois-invariant rational forms, for example

Tr
L/Q
	​

(α
k
	​

dlogh),

for a basis {α
k
	​

} of the component coefficient field.

Add those exact one-forms to the ordinary solver.

This avoids any large characteristic-zero forcing-numerator factorization.

The same black-box modular philosophy previously proposed for source-frame reconstruction applies here: use modular evaluations to identify only the structures that warrant exact lifting. 

11_reconstruct_dont_simplify

5. If you nevertheless test forcing numerator factors

Treat this only as a diagnostic for an incomplete pole census, not as the default recovery route.

A bounded modular experiment would be:

Factor the specialized numerators at one prime and one generic ϵ.

Remove every factor already belonging to the polar divisor.

Evaluate the individual factor dlogs.

Project their columns through W.

Impose zero total residue on every nonpolar factor.

After imposing those zero-residue conditions, the surviving column space must reduce to the polar-component span. If it appears not to, one of the following is true:

the polar divisor census omitted a genuine divisor;

two modular factors were misidentified;

the finite-field system is using a special factorization;

or the candidate-column construction is inconsistent.

There is no reason to align these numerator factors across primes unless they reveal an omitted actual pole divisor.

If exact reconstruction became necessary, factors should be aligned using:

bidegree;

fixed leading monomial and monic normalization;

values at fixed anchor points;

Frobenius-orbit products when a characteristic-zero irreducible factor splits modulo p.

But broad modular factor recombination of all sampled numerator factors is not justified by the current mathematics.

6. Are the visible pole divisors enough?

For the unipotent off-diagonal strip transformation, yes.

With

G=
D
N
	​

,

the finite pole support of

B
ˉ
+ϵ(EG−GC)−dG

is contained in the union of the pole supports of:

B
ˉ
,E,C,D.

Differentiating G can increase the pole order on D=0, but it cannot create a new irreducible divisor. Because the complete basis change is unipotent, there is no separate detG or detU divisor.

Chart-Jacobian and exceptional factors must be included after pullback, and infinity must be treated projectively. Once those are included, a valid minimal rational dlog alphabet cannot require new divisors.

So the correct completeness set is:

geometric components of the reduced projective pole divisor,
	​


not the union of all numerator and denominator divisors of every intermediate expression.

7. Assessment of the no-extra-pole argument

The argument remains sound.

At an irreducible kinematic divisor f=0, suppose an additional pole of order m>0 appears in G:

G∼f
−m
H.

The leading equation is

−mH−ϵE
f
	​

H+ϵHC
f
	​

=0.

After vectorization, the determinant of the leading operator has constant term

m
4
.

Therefore it is nonzero as an element of Q(ϵ), and

H=0.

This excludes the additional pole.

The genuine caveats

The argument would fail only if:

E or C had higher-than-logarithmic poles along f;

the target one-form were permitted a higher-order pole there;

the calculation used a nonreduced divisor rather than the valuation on its normalization;

the gauge were allowed nonrational behavior such as f
ϵλ
;

or the relevant projective-infinity divisor had not been included.

At a ramified or singular component, the valuation parameter can multiply m by a positive ramification index, but the nonzero constant-term argument survives.

Under the established logarithmic-pole assumptions, denominator promotion remains irrelevant.

What follows if the geometric-component span fails

Then the letter axis is closed.

The next step depends on what “certified degree-58 simplex” means.

If degree 58 is a rigorous projective upper bound

Together with:

the complete denominator multiplicities;

the no-extra-pole result;

the complete geometric polar alphabet;

the two-prime inconsistency is an obstruction to a rational dlog gauge for this strip under the current canonical diagonal blocks.

Do not run:

more numerator factors;

larger denominator powers;

more sampled forcing-entry letters;

another rational chart.

A birational chart cannot change the existence of a rational solution in the same function field.

The next mathematical route is then to test a broader target class—general closed rational one-forms rather than dlogs—or reconsider the preceding canonical block normalization.

If degree 58 is only the current selected support

Use the existing cokernel to test the next gauge-support directions without a full solve.

For candidate monomials m on the next admissible projective boundary, form their gauge column blocks C
m
	​

 and test

Wb∈span{WC
m
	​

}.

If not, reject the entire shell.

If yes, retain only a rank-increasing subset and run one full system at two images.

Do not continue a blind offset ladder.

Prioritized GO / NO-GO plan
Priority	Action	Decision
1	Absolute/geometric component census of the 16 projective polar curves	GO
2	Cokernel test of every genuinely new polar-component logarithmic direction	GO
3	Exact construction of only component forms selected by that test	Conditional GO
4	Cokernel-targeted gauge-support shell, if degree 58 is not an absolute bound	Conditional GO
5	Broad factorization of sampled forcing numerators	NO-GO
6	More whole-entry sampled dlogs	NO-GO
7	Extra denominator copies	NO-GO
8	Another rational chart search	NO-GO

The immediate discriminator is small:

Factor only the 16 polar curves geometrically, project the additional component dlogs through the current left cokernel, and test whether they span the obstruction at two primes.

If they do not, the current failure is not an alphabet-enumeration problem.
