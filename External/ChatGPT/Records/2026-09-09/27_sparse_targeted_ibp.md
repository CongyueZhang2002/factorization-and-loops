# Sparse exact IBP reduction of physical targets

Verified outgoing model gpt-6-pro; conversation 6aa0f5dd-de10-83e8-b032-74f47d77da2a, message 7452b964-0324-41f4-884f-ee2bcb57c5ea. Mathematics retains the bridge line-break artifacts.

## Question

We need a concrete fast exact IBP strategy before launching corrected SIDIS NNLO RR reduction. The source decomposition bug is fixed and cheap source/coordinate checks pass. Numerators are now real GLI index shifts, not free loop-coordinate coefficients. The corrected inventory of only 20/40 RR components already has 132 typed families, 9435 targets, and 1,549,606 seeds under the old global rectangular r<=rmax, s<=smax selection (L=2,E=2; four mandatory cuts, three free scalar products, eight momentum IBP operators/seed). Many seeds put the maximal high numerator rank together with excessive lower-sector cut dots. Completing this rectangle would dominate computation.

Existing exact affine-loop cut equivalence (positive oriented particle momenta, determinant +/-1, measured cuts retained, original uncut prescriptions and normalized measure retained) groups these 132 top-support prototypes into 66 classes. We can map full original numerators to each representative's inverse-propagator basis, combining coefficients; this is polynomial linear-algebra transformation, no unit-cut substitution when mapping dotted cuts. That alone halves redundant families.

We have an earlier valid 55-master DE + physical boundary solution through epsilon0. Its physical target coverage was incomplete, but each stated scalar integral and DE is valid. We hope corrected high-rank numerator targets reduce to those 55 (plus any genuinely new channel topology masters). The old simple top-support denominator products were present, but the initial seed numerator bound was small.

Proposed strategy:
1. Canonicalize whole typed families BEFORE IBP with exact affine maps; map all target numerator polynomials without changing cuts or i0.
2. Seed exact IBPs locally around actual targets and a preferred known master list, rather than enumerating the r/s rectangle. Start targets plus bounded index-shift neighbors; include necessary lower-complexity/subsector seeds. Kira handles sparse linear algebra.
3. Order preferred existing scalar masters as simplest; require every physical target to reduce by explicit equations into the preferred span. If other unpivoted integrals remain, do not claim them independent: enlarge seeds near that frontier, with bounded complexity and per-sector bounds, then retry.
4. Once every target reduces into a known DE-closed span, exact witnessed identities suffice; no separate global master-minimality proof needed. If extra directions persist, include them and construct a closed DE, without equating finite-seed survivors with mathematically irreducible masters.

Please critique this and suggest the most effective concrete seed shape or recurrence for high numerator degree with mandatory particle+measurement cuts. Is a local frontier strategy likely to fail because the needed relations necessarily require higher-rank intermediates? What inexpensive diagnostic tells us to enlarge r vs s vs a sector? Would direct Baikov/parametric syzygies be genuinely worth adding now, or avoid a larger detour? We need the general workflow, not SIDIS-specific reduction identities, and verification should stay cheaper than production. Do not endorse minimality from a small finite seed set.

## Pro response

Your four-step strategy is sound. Do not launch the global rectangle. The essential change is to make seeding a bounded search for target-to-known-span identities, not a search for the complete reduction of every integral inside a large r/s region.

I would begin with per-sector dot caps and target-derived numerator profiles, then expand the seed set using the unresolved target frontier. Add narrow paths through numerator-index space only where the targets are sparse and high rank. A general syzygy implementation is not the next prerequisite.

The old rectangle would generate up to 8×1,549,606=12,396,848 momentum-IBP equations before simplification. Much of that work is avoidable independently of whether the preferred 55 integrals span the corrected targets.

1. Canonicalize first, and reuse exact old relations—not truncated values

Your family canonicalization is the right first step. Apply it to the entire numerator polynomial, collect coefficients in the representative’s inverse-propagator coordinates, and only then rebuild the target list.

Three details matter.

A top-support equivalence is not necessarily a monomial map on numerator slots. Preserve the resulting linear combination of GLIs. The number of representative families should decrease, but the number of distinct targets need not decrease by exactly the same factor.

Choose a reasonably sparse representative. Among equally valid affine routings, prefer one that keeps the active denominators literal and makes the numerator-coordinate transformation sparse. A lexicographically canonical choice can be much more expensive than another representative of the same class. This is an optimization of an already proved equivalence, not an additional equivalence criterion.

Import existing exact algebraic relations. In addition to the preferred integral list, reuse trusted old reduction equations. Your exact old DEs also give useful relations: differentiate each old master with the current typed derivative generator and equate that GLI combination to its known DE row. These relations can supply inexpensive connections between dotted cuts and the known span.

Do not use the old ϵ
0
 values to generate reduction relations. The reduction must remain over the generic rational field, for example

K=Q(x,z,D),

with the declared normalizations and prescriptions.

Keep your existing typed equation generator and config:false Kira route. Kira’s user-system interface expressly permits solving externally generated equations without loading topology definitions; the new seed policy need not reopen unaudited native symmetry identifications. 
arXiv

2. Use the exact IBP shifts to generate the frontier

For each of the eight momentum generators

D
rv
	​

=∂
ℓ
r
μ
	​

	​

v
μ
,r=1,2,v∈{ℓ
1
	​

,ℓ
2
	​

,p,q},

precompute

v⋅∂
ℓ
r
	​

	​

D
i
	​

=c
ri,v,0
	​

+
j
∑
	​

c
ri,v,j
	​

D
j
	​

.

Then each seed ν produces

0=
	​

Dδ
v,ℓ
r
	​

	​

I
ν
	​

−
i
∑
	​

ν
i
	​

c
ri,v,0
	​

I
ν+e
i
	​

	​

−
i,j
∑
	​

ν
i
	​

c
ri,v,j
	​

I
ν+e
i
	​

−e
j
	​

	​

.
	​

	​

(1)

This remains the rule for the linear measurement slot. Apply only your justified mandatory-cut zero rule when a required cut power becomes nonpositive.

The generic shift support is

Δ∈{0,e
i
	​

,e
i
	​

−e
j
	​

}.
	​

(2)

Use the actual nonzero coefficient support of each generator to make it smaller.

Generate candidate seeds backward from unresolved integrals

If an unresolved integral I
μ
	​

 is to occur in an equation, candidate seeds are

ν=μ−Δ,
	​

(3)

subject to:

the seed is admissible;

all mandatory cuts remain present;

the coefficient of I
μ
	​

 in that seed’s equation is nonzero.

This inverse-incidence search is sharper than adding an arbitrary box of neighbors around every unresolved integral. You already possess everything needed to implement it.

Distinguish seed limits from equation-column limits

A seed cap controls which equations you generate. It must not delete terms in an equation that land outside the seed cap.

For example, e
i
	​

−e
j
	​

, with i an active denominator and j a numerator slot, can raise both the dot count and numerator degree. Those harder integrals must remain as unknowns even when they are not yet seeded.

Never truncate an IBP equation by discarding out-of-envelope integrals. That would change an exact identity into a false one.

Conversely, do not recursively seed every integral that appears in an equation. That closure rule recreates the large rectangle. Seed only the auxiliaries needed to resolve the requested target remainders.

3. Replace global r
max
	​

 by sector-local dot and numerator profiles

For a sector Σ, define

t
Σ
	​

=∣Σ∣,s(ν)=
ν
i
	​

<0
∑
	​

(−ν
i
	​

),

and distinguish

d
p
	​

=
particle cuts
∑
	​

(ν
i
	​

−1),d
m
	​

=
measurement cuts
∑
	​

(ν
i
	​

−1),
d
o
	​

=
ordinary slots
ν
i
	​

>0
	​

∑
	​

(ν
i
	​

−1).

Thus

r=t
Σ
	​

+d
p
	​

+d
m
	​

+d
o
	​

.

The old global r
max
	​

 automatically grants a sector one extra dot whenever an ordinary denominator is removed. There is no reason to make that your default. The published Kira 3 seeding strategy addresses precisely this problem by explicitly restricting dots and reducing inherited numerator rank in lower sectors. Its numerical benchmarks support this as an effective heuristic, not a universal sufficiency bound for your measured families. 
arxiv.org

3.1 A concrete initial seed shape

For each sector, collect the actual target profiles

(d
p
	​

,d
m
	​

,d
o
	​

,s).

Keep their union of downward profiles, rather than combining the largest component of each into one box.

For example, targets with profiles

(0,0,0,8),(0,0,2,2)

justify the initial union

or
	​

d
p
	​

=d
m
	​

=0,d
o
	​

=0,s≤8,
d
p
	​

=d
m
	​

=0,d
o
	​

≤2,s≤2.
	​

	​

(4)

They do not initially justify d
o
	​

≤2,s≤8.

Within a sparse numerator profile, use the union of componentwise numerator downsets:

0≤n
j
	​

≤n
j
(τ)
	​


for actual target monomials τ, where n
j
	​

=−ν
j
	​

 on absent slots. This connects high-rank targets to lower-rank integrals without filling every distribution of the maximum total degree. When this union is already dense, use the simpler total-degree simplex s≤s
max,Σ
	​

.

Include the actual targets and needed old anchors explicitly, even if they lie outside a profile inferred from another sector.

Initial cut-dot policy: if all direct targets and old anchors in a sector have unit cuts, start its seed set with d
p
	​

=d
m
	​

=0. Equations generated from those seeds will still contain singly raised cuts. That is permitted. Add dotted-cut seeds only when the pilot identifies a need for them.

This is a starting heuristic, not a promise that unit-cut seeds suffice.

3.2 Do not propagate maximal numerator degree to every subsector

For a sector with no direct demand, a useful initial inherited bound is

s
seed,Σ
	​

=max(1,
Σ
0
	​

⊇Σ
max
	​

[s
target,Σ
0
	​

	​

−(t
Σ
0
	​

	​

−t
Σ
	​

)]).
	​

(5)

Override it with every direct target or subsequently unresolved demand in that sector.

Keep the dot caps independent of this inheritance. In particular, do not hold r
max
	​

 fixed while descending.

Equation (5) is deliberately a pilot seed policy, not a theorem about the integral. Its purpose is to avoid paying for high numerator degree in a lower sector until some requested reduction actually needs it.

For scale, a four-cut sector with three numerator coordinates and numerator degree at most eight contains

(
3
8+3
	​

)=165

unit-cut seeds. Allowing three arbitrary additional dots on the four cuts multiplies this by

(
4
3+4
	​

)=35,

giving 5,775 seeds. This illustrative factor arises before increasing numerator degree or considering more sectors.

3.3 Expand with a staircase, not another rectangle

For a seed profile (d,s), with d=d
p
	​

+d
m
	​

+d
o
	​

, a first enlargement can use

d
′
≤d+1,s
′
≤s+1,d
′
+s
′
≤d+s+1.
	​

(6)

This adds a dot shell or a rank shell without immediately adding their full Cartesian product.

Split that shell into particle-dot, measurement-dot, ordinary-dot, and numerator components for diagnostics. Directly requested integrals always remain explicit exceptions.

If the first shell fails, allow the required joint shell. The inequality in (6) is not a restriction on valid intermediate integrals or on the final theorem.

4. Local frontier reduction can need harder intermediates

A target need not be reducible by an equation in which it is the hardest integral. The elementary linear-algebra example is

X−T=0,X−M=0,

where X is harder than T. Together these prove T=M; neither alone eliminates T without retaining X.

The same phenomenon occurs in IBP systems. Consequently:

a one-step neighborhood is not a completeness guarantee;

rank never has to decrease at every intermediate step;

a useful seed bundle can introduce new auxiliaries before eliminating them;

an equation with no immediate reduction of a target can still be necessary.

The high-numerator strategy should therefore connect targets to simpler sectors or known anchors, rather than place isolated small balls around the two ends.

Sparse high-rank tails: use paths, not large downsets

When a small number of targets have unusually large numerator degrees, construct an axis-aligned path in the numerator multi-index lattice from a simpler seed region to each target, then add a narrow transverse neighborhood. Merge overlapping paths.

Start with a small width and enlarge it where the pilot stalls; add wider “shoulders” at path turns. Do not assume a universal width.

This is closely aligned with the June 2026 tube-seeding study: it demonstrates sparse high-rank reductions and explicitly finds cases where an additional lower-sector tube is needed. Its finite-field examples are evidence that the strategy can work, not a proof that your cut families close at a prescribed width. 
arXiv

With only up to three numerator coordinates, I would implement this after the sector-local profile policy. If the actual targets densely fill their rank simplex, a tube for every target may reconstruct the same dense set with more bookkeeping.

5. Measure target coverage, not the number of free columns

Let the current exact equations be

AI=0.

Let E
B
	​

 select the preferred known integrals and E
T
	​

 select all requested targets.

The exact stopping condition is

row(E
T
	​

)⊆row(A)+row(E
B
	​

).
	​

(7)

Equivalently,

d
T
	​

=rank
	​

A
E
B
	​

E
T
	​

	​

	​

−rank(
A
E
B
	​

	​

)=0.
	​

(8)

Adding E
B
	​

 in this rank test means taking a quotient by the desired span; it does not set the physical master values to zero.

In practice, put the known integrals last in the elimination ordering. Reduce the target rows and collect their coefficients on nonpreferred free columns. The rank of those residual rows is the unresolved target dimension.

This is more useful than either:

the total number of unpivoted columns;

the number of targets with a nonempty printed remainder.

Many unpivoted auxiliaries may never contribute to a target. Conversely, many target remainders may represent the same one-dimensional obstruction.

Use finite fields for selection, not as a physical independence claim

A generic finite-field pilot is appropriate for rank and pivot selection. Such probabilistic equation selection is established in IBP workflows. 
arXiv

Keep D,x,z generic. Do not sample at D=4, an endpoint, or a special symmetry locus. Typed cuts and prescriptions are preserved by the exact equation generator; the finite-field sample is not evaluating the physical period.

Use a fresh point or prime to catch unlucky specialization before launching full rational reconstruction. A successful pilot identifies a candidate sufficient subsystem. The final accepted reduction still needs exact identities.

Expansion diagnostics

Classify the live nonpreferred target remainders and the omitted inverse-incidence seeds from (3):

Observed obstruction	First expansion to try
High numerator powers at or above the local rank boundary	Add that sector’s rank shell or widen the numerator path
Particle-cut dots dominate the relevant boundary columns	Add particle-dot seeds near those columns, not all dot placements globally
Measurement-cut dots dominate	Add the measurement-dot shell; reuse known z-derivative identities where available
Ordinary dots dominate	Increase the ordinary-dot cap in the affected sector
Remainder lies in a lower sector that was barely seeded	Add a local seed region in that sector; do not enlarge every top sector
Obstruction is inside all caps and insensitive to separate shells	Try combined shells, a different path/order, or existing cross-family/higher-sector relations

The diagnostic should use the actual shift support: “this unresolved column can occur in omitted seeds of these types” is more informative than its own r,s values alone.

Test candidate bundles of seeds, generating all eight equations for each. Compare reduction of d
T
	​

 against added nonzero entries and memory. If no individual shell improves d
T
	​

, try their combination before concluding that another master is required. A greedy rule that permanently discards every zero-immediate-gain bundle can miss the two-equation mechanism above.

Higher sectors remain a possible source of relations

Basic IBPs seeded in a sector do not create a new positive ordinary slot from an index zero: the would-be raising coefficient is proportional to that zero index. Nevertheless, equations in a higher sector can combine to give additional lower-sector relations.

Therefore, a search restricted forever to target sectors and their subsectors is not complete for every possible preferred basis. If a stable obstruction remains, first inspect existing, correctly typed supersectors and cross-family relations. Do not promote an arbitrary numerator coordinate to a new denominator without defining its prescription and physical integral.

This is another reason to call persistent survivors provisional additional directions, not irreducible masters.

6. A bounded implementation loop

The following is the algorithmic structure I recommend; it does not require a new reducer.

Canonicalize families and map/collect all target polynomials.
Load applicable exact old reductions and DE-derived relations.
Build sector-local seed profiles.

repeat:
    Emit all eight exact IBPs for newly selected seeds.
    Keep every resulting integral column; apply only justified zero rules.

    Run a finite-field target-oriented elimination.
    Form the nonpreferred target remainder space.

    if target remainder space is zero:
        retain the target dependency subsystem
        solve/reconstruct it over Q(x,z,D)
        verify the exact target identities
        return the target-to-known-span map

    Generate omitted predecessor seeds of the live remainder columns.
    Group candidates by sector and rank/dot direction.
    Add the cheapest useful shell/path bundle.
    If individual bundles stall, test a joint enlargement.

    if a declared budget is exhausted:
        return the unresolved directions and diagnostics, not a reduction claim

Retain generator/seed IDs so every equation can be regenerated. A row discarded by a finite-field selection should not be permanently declared an exact algebraic dependency unless that has been established.

For the final solver input, order equations approximately by their largest integral and then by sparsity. Kira’s on-the-fly user-system documentation specifically warns that badly ordered input can substantially increase runtime. 
arXiv

Do not restart rational reconstruction after every small seed adjustment. Do the seed search at one or a few finite-field points, stabilize the target subsystem, and then reconstruct.

7. Exact witnesses make global minimality unnecessary

Once the result is

I
T
	​

=R
T
	​

(x,z,D)M
known
	​

,
	​

(9)

with exact witnesses from the accepted equations, the requested target reduction is complete.

It does not matter whether the known list is globally minimal, whether it contains redundant integrals, or whether unrelated auxiliaries in the pilot system remain unresolved.

A useful exact certification form is

E
T
	​

−R
T
	​

E
B
	​

=ΛA.
	​

(10)

You need not materialize a dense global Λ. Preserve a sparse elimination dependency graph or verify reconstructed block relations. For a solved block

A
b
	​

X
b
	​

+B
b
	​

Y
b
	​

=0,X
b
	​

=R
b
	​

Y
b
	​

,

the check is

A
b
	​

R
b
	​

+B
b
	​

=0.
	​

(11)

Exact sparse polynomial/rational residual checks can be much cheaper than repeating the solve. Fresh-prime agreement is a useful diagnostic, but without degree/coefficient bounds it is not itself an exact identity certificate.

Trim verification to the target dependency closure. There is no need to validate a full million-seed rectangle that you never used.

The known DE closes the mapped targets automatically

If

∂
ξ
	​

M
known
	​

=A
ξ
	​

M
known
	​

,

then an exact map (9) implies

∂
ξ
	​

I
T
	​

=(∂
ξ
	​

R
T
	​

+R
T
	​

A
ξ
	​

)M
known
	​

.
	​


You do not need a new independent DE solution for each high-rank target.

If additional directions are retained, differentiate those and build their closure, retaining the known block and its physical boundary data.

The old solution through ϵ
0
 is not automatically deep enough for the corrected amplitude. The new rational coefficients can contain epsilon poles. After reduction, rerun the existing order planner on the complete amplitude coefficient combinations. Do not spend on higher integral orders during the seed search.

8. Syzygies: a useful fallback, not the next large project

The current bottleneck is chiefly excessive seeding. Fixing that does not require changing the mathematical source of the equations.

Syzygy-generated vector fields can prevent unwanted dots and yield smaller systems; NeatIBP implements this approach, including a Kira user-system interface. It introduces its own module-generation and selection work, however, so it is not automatically cheaper for this already small seven-coordinate geometry. 
arXiv
+1

If the pilot shows that cut-dot proliferation remains the dominant obstruction, add a small supplemental generator rather than a full new Baikov pipeline. Seek polynomial combinations of your existing momentum generators satisfying

r
∑
	​

v
r
	​

⋅∂
ℓ
r
	​

	​

D
c
	​

=f
c
	​

D
c
	​

for each mandatory cut c.
	​

(12)

A bounded low-degree ansatz can be solved as polynomial linear algebra and checked exactly. These equations preserve the cut powers.

Importantly, their action on a cut is

−ν
c
	​

f
c
	​

D
c
	​

C
ν
c
	​

+1
	​

(D
c
	​

)=−ν
c
	​

f
c
	​

C
ν
c
	​

	​

(D
c
	​

),

not zero. Retain that normal contribution and the derivatives of the polynomial vector-field coefficients.

This is the same no-power-raising principle used in syzygy-constrained IBPs, with the measurement cut included in the constraint set. It can feed your existing solver as additional exact equations. 
arXiv

A fully symbolic numerator-index recurrence is attractive when many targets occupy a long high-rank sequence. But deriving it is another optimization step; it should not delay a target-oriented Laporta pilot that may already close.

Recommended next launch

Canonicalize the 132 prototypes and rebuild the collected representative targets. Then run a pilot using:

explicit sector-local dot caps, initially no extra particle/measurement dots where the targets have unit cuts;

unions of actual numerator profiles, with decreased inherited rank in untouched subsectors;

the applicable exact old reductions and DE identities;

target-directed inverse-incidence expansion of the remaining frontier.

Keep one bounded resource pool across seed generation and Kira; do not run large family jobs concurrently merely because 66 representatives exist. Group neighboring numerator targets within a family so they share equations, and cache completed lower-sector reductions.

The desired stopping statement is “every corrected physical target has an exact reduction into this DE-closed span,” not “this finite seed set has found all masters.” That gives you a rigorous completion criterion while allowing an aggressively small, adaptively enlarged equation system.