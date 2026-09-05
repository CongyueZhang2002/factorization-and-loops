# CF303 Source GPL Operator Audit

## Question

Continue the established **Assess Multiquadratic Pipeline** conversation. Please audit the following current `CanonicalWordTransport.wl` algorithm and tell us whether the present CF303 paper-facing GPL construction is mathematically on the right track. Focus on the algorithm and the minimum necessary correction; do not propose more hashes, provenance gates, or redundant validation layers.

Current result

- The maximal downward-closed rational subsystem of CF303 has 21 blocks / 37 masters; algebraic blocks 15, 17, 21, 25 are excluded.
- Its canonical one-dimensional connection was reconstructed as a 21-letter dlog system with 99 nonempty couplings. The raw residue matrices are accepted at nine 61-bit primes plus a fresh prime/chart target.
- We now compose those residues with the exact source gauge. With the package convention
  
  `I_source = T F_canonical`, `T = TDiagonal . S`,
  `T^-1 = SInverse . TDiagonalInverse`.
- The selected 37-by-37 slices each have 244 nonzero entries. There is no selected-source <- excluded-canonical leakage, and the chosen path rationalizes the only roots present in this slice.
- The source-gauge exporter formerly used literal `Sqrt[Delta]` rules, leaving ten algebraically identical radicals unconverted. It now uses the package's exact square-class branch application after path pullback. All 488 entries are radical-free scalars. The branch reduction took 3.6 s; Maple exact normalization plus Laurent extraction took about 19 s.

The implemented physical-boundary formula is

`[I_source]_eps^n = Sum_{r+q+|w|=n} T_r(z) R_w H_q b G(w;z)`

where

`H_q = [eps^q]( T^-1(0,eps) Sum_m eps^m b_m )`,

and `R_w = R_{a1} ... R_{ak}` in the same order as `G(a1,...,ak;z)`. The new `masterTransportCanonicalSourceCoefficient` deliberately traverses the raw residues and does not use the earlier canonical `ActiveRowsByOrder` mask; a negative-order source gauge can require words beyond that old demand schedule.

Implementation skeleton: for each integer triple `(r,q,weight)` with `weight=n-r-q>=0`, start from the requested rows of sparse `T_r`; at each depth right-multiply every live sparse row matrix by every sparse residue `R_a`, append letter `a` to the word, merge identical words, and prune exact sparse zeroes. At depth `weight`, right-multiply by sparse `H_q` and add the resulting source-boundary coefficient matrix under that word. The expression layer contracts each such matrix with symbolic source-boundary columns and emits one `TransportWord[letters[[word]],z]` (or 1 for the empty word).

For physical source boundary orders `m={0,1,2}`, we extracted `T_r` for `r=-3..2`, `T^-1_s(0)` for `s=0..5`, and formed `H_q` for `q=0..5`. A row-1, order-0 empty-word probe now reproduces the source boundary exactly. The only earlier failure was a Wolfram context mismatch when substituting the imported Maple path variable `u=1/2`; replacing the actual imported symbol fixed it, with zero residual support.

Please answer concretely:

1. Is the matrix orientation and residue-word ordering in the attached implementation correct?
2. For requested source orders 0,1,2 and source boundary orders 0,1,2, are the Laurent windows above sufficient? If not, derive the exact minimal windows. In particular, check whether `H_q` really needs only q=0..5 and whether T orders above 2 can ever enter.
3. Is taking the 37-by-37 gauge slice before multiplication/inversion mathematically safe under the stated one-way closure, or must we form the full `T` and `T^-1` first and then slice? State the exact support condition needed for each direction.
4. Does the source traversal correctly avoid the old canonical schedule, or is some additional reachability condition mathematically required?
5. What is the smallest next step to turn this accepted lazy operator into actual paper-facing GPL coefficients without causing a combinatorial materialization explosion?

Please distinguish a genuine mathematical defect from optional engineering. We want a decisive audit, not a broader redesign.

## Pro response

Verdict: GO, with one mandatory closure condition

The attached implementation is mathematically on the right track. The matrix orientation and GPL word ordering are correct for

I
source
	​

(z,ϵ)=T(z,ϵ)F
canonical
	​

(z,ϵ).

The extracted Laurent windows are sufficient for source orders 0,1,2, assuming the established exact valuations

ord
ϵ
	​

T=−3,ord
ϵ
	​

[T
−1
(0,ϵ)B(ϵ)]=0.

The only material correctness trap is premature restriction to the 37×37 subsystem. The selected canonical indices must be closed under every residue matrix, and factorwise slicing of T=T
Diagonal
	​

S requires the intermediate basis to respect the same selection. With those conditions, forming the full gauge first is unnecessary.

1. Matrix orientation and residue-word ordering

Let

T(z,ϵ)=
r
∑
	​

ϵ
r
T
r
	​

(z),

and let the canonical boundary embedding be

T
−1
(0,ϵ)B(ϵ)=
q
∑
	​

ϵ
q
H
q
	​

.

For the epsilon-form system

dF
canonical
	​

=ϵ
a
∑
	​

R
a
	​

dlog(z−a)F
canonical
	​

,

the Chen solution is

F
canonical
	​

(z)=
w
∑
	​

ϵ
∣w∣
R
w
	​

G(w;z)F
canonical
	​

(0),

where, for

w=(a
1
	​

,…,a
k
	​

),
R
w
	​

=R
a
1
	​

	​

R
a
2
	​

	​

⋯R
a
k
	​

	​

.

Consequently,

[I
source
	​

]
ϵ
n
	​

=
r+q+∣w∣=n
∑
	​

T
r
	​

(z)R
w
	​

H
q
	​

bG(w;z).

This is exactly the orientation encoded by masterTransportCanonicalSourceCoefficient: it starts with a source-to-canonical gauge row T
r
	​

, successively right-multiplies it by the residues while appending the corresponding letters to the GPL word, and finally right-multiplies by H
q
	​

. 

CanonicalWordTransport

For example, the internal path for the word (a
1
	​

,a
2
	​

) is

T
r
	​

⟶T
r
	​

R
a
1
	​

	​

⟶T
r
	​

R
a
1
	​

	​

R
a
2
	​

	​

,

and the emitted function is

G(a
1
	​

,a
2
	​

;z).

That ordering agrees with the declared convention

G(a
1
	​

,…,a
k
	​

;z)=∫
0
z
	​

t−a
1
	​

dt
	​

G(a
2
	​

,…,a
k
	​

;t).

The canonical accessor uses a reverse fold only because it starts from the boundary selector and left-multiplies the residues; it produces the same ordered product R
a
1
	​

	​

⋯R
a
k
	​

	​

. 

CanonicalWordTransport +1

Thus there is no residue reversal defect.

The only convention condition is that the stored Letters really denote the singularities a of dlog(z−a), rather than unreduced functions L
a
	​

(z). The lazy Chen constructor explicitly assumes this GPL convention. 

CanonicalWordTransport

2. Exact Laurent windows

Let the requested source orders be

n∈{0,1,2},n
max
	​

=2.

Let

r
min
	​

=−3

be the lowest nonzero order of T, and let the lowest canonicalized boundary order be

q
min
	​

=0.

Every contribution satisfies

n=r+q+k,k=∣w∣≥0.

It follows immediately that

r≤n
max
	​

−q
min
	​

=2,

and

q≤n
max
	​

−r
min
	​

=5.

The maximum GPL weight is likewise

k
max
	​

=n
max
	​

−r
min
	​

−q
min
	​

=5.

Therefore the required common windows are:

Object	Minimal common window
Source gauge T
r
	​

(z)	r=−3,…,2
Canonical boundary embedding H
q
	​

	q=0,…,5
GPL word weight	k=0,…,5
Source boundary input b
m
	​

	m=0,1,2
Base-point inverse gauge [T
−1
(0)]
s
	​

	s=0,…,5

To see the last line, write

B(ϵ)=
m=0
∑
2
	​

ϵ
m
B
m
	​

,T
−1
(0,ϵ)=
s≥0
∑
	​

ϵ
s
U
s
	​

.

Then

H
q
	​

=
s+m=q
0≤m≤2
	​

∑
	​

U
s
	​

B
m
	​

.

For q≤5, no U
s
	​

 with s>5 can enter. Explicitly,

H
5
	​

=U
5
	​

B
0
	​

+U
4
	​

B
1
	​

+U
3
	​

B
2
	​

.
Can T
r
	​

 with r>2 ever enter?

No, under the stated boundary valuation. Since

q≥0,k≥0,

one has

r=n−q−k≤n≤2.

Thus T
3
	​

,T
4
	​

,… cannot contribute to source orders 0,1,2.

The qualification is precise: this conclusion depends on the actual absence of negative H
q
	​

. If T
−1
(0)B had a negative epsilon valuation, positive T
r
	​

 above order two could contribute. Likewise, coefficients of T below −3 would require extending H
q
	​

 and the maximum GPL weight. The relevant conditions are the Laurent valuations of the products, not merely the ranges chosen for extraction.

The windows currently used are therefore both sufficient and generically minimal.

3. When the 37×37 slices are safe

Let P
s
	​

 project onto the 37 selected source masters and P
c
	​

 onto the 37 selected canonical masters.

Forward source gauge

The selected source solution depends only on the selected canonical subsystem precisely when

P
s
	​

T(1−P
c
	​

)=0.
	​


Then

P
s
	​

I
source
	​

=(P
s
	​

TP
c
	​

)P
c
	​

F
canonical
	​

.

This is exactly the stated absence of selected-source ← excluded-canonical leakage.

Boundary inverse

To calculate the selected canonical boundary from only the selected source boundary, one needs

P
c
	​

T
−1
(0)(1−P
s
	​

)=0,
	​


unless the excluded source boundary components are already known to vanish.

If T is invertible, the selected and excluded partitions have matching dimensions, and

P
s
	​

T(1−P
c
	​

)=0,

then T is block lower triangular:

T=(
T
ss
	​

T
es
	​

	​

0
T
ee
	​

	​

).

It follows that

T
−1
=(
T
ss
−1
	​

−∗
	​

0
T
ee
−1
	​

	​

),

so that

P
c
	​

T
−1
P
s
	​

=(P
s
	​

TP
c
	​

)
−1

and the inverse-direction condition follows automatically.

Slicing the factors before multiplication

The final no-leakage condition alone does not, in complete generality, permit slicing arbitrary factors before multiplication. For

T=T
Diagonal
	​

S,

the omitted intermediate contribution is

P
s
	​

T
Diagonal
	​

(1−P
m
	​

)SP
c
	​

,

where P
m
	​

 projects the selected indices in the intermediate basis.

Thus factorwise slicing is safe when

P
s
	​

T
Diagonal
	​

(1−P
m
	​

)SP
c
	​

=0.
	​


A simple sufficient condition is

P
s
	​

T
Diagonal
	​

(1−P
m
	​

)=0.

This holds if T
Diagonal
	​

 is block diagonal and the 37-master selection is a union of its complete blocks. Under that condition,

(P
s
	​

T
Diagonal
	​

P
m
	​

)(P
m
	​

SP
c
	​

)=P
s
	​

TP
c
	​

.

Similarly, for

T
−1
=S
−1
T
Diagonal
−1
	​

,

factorwise slicing requires

P
c
	​

S
−1
(1−P
m
	​

)T
Diagonal
−1
	​

P
s
	​

=0,

which again follows if T
Diagonal
−1
	​

 preserves the selected subspace.

Residue closure is independently required

The canonical GPL subsystem must also satisfy

P
c
	​

R
a
	​

(1−P
c
	​

)=0for every one of the 21 letters a.
	​


Otherwise a word can leave the selected 37-dimensional space through one residue and return through another. A 37×37 residue slice would then omit contributions even though the initial and final vectors lie in the selected space.

The phrase “maximal downward-closed subsystem” normally means precisely this row-closure condition. It should hold letter by letter, not merely after summing the full connection at one value of the path variable.

With these conditions, forming the full T, T
−1
, or full residue products is unnecessary.

4. The source traversal is correct not to use ActiveRowsByOrder

The old ActiveRowsByOrder mask belongs to the canonical-demand accessor: it suppresses output rows that were outside the original epsilon-order schedule. The code applies that mask only in masterTransportCanonicalChenWordCoefficient. 

CanonicalWordTransport

The source coefficient has a different demand relation:

n=r+q+∣w∣.

A negative source-gauge order r can make a higher canonical order or longer word contribute to a low physical source order. Reapplying the old canonical schedule would therefore be mathematically wrong. The source routine deliberately bypasses it and traverses the raw residues instead. 

CanonicalWordTransport

No additional epsilon-order mask is required.

The additional support condition is the residue/path closure described above. A weaker finite-weight version is sufficient here:

Every canonical index lying on a nonzero residue path of length at most five from a nonzero column of some selected T
r
	​

 to a nonzero row of some H
q
	​

 must be included in the 37-master subsystem.

Full downward closure under every R
a
	​

 implies this automatically.

The implementation then explores every word of the required length, discards products that are exactly zero, and combines contributions with the same word. 

CanonicalWordTransport

 That is complete.

5. Smallest next step for paper-facing GPL coefficients

Do not materialize the complete 37-vector at all three orders as one Wolfram expression.

Recommended sequence

Contract the physical boundary first.

If the physical source-boundary vector b is fixed, replace

H
q
	​


by

h
q
	​

=H
q
	​

b

before word traversal. This reduces the boundary dimension to one and exposes many zero paths before GPL words are created.

If the paper must retain symbolic boundary constants, first reduce them to the physically independent boundary basis and contract that projection.

Request one source row and one epsilon order at a time.

Use

Rows -> {row}

for n=0, then 1, then 2. The routine already returns a sparse list

w⟼c
n,w
	​

(z)

rather than a fully expanded GPL sum.

Use the returned Terms as the paper-facing intermediate.

Each record already contains:

the GPL word;

its exact coefficient;

the boundary-column action.

Convert only these nonzero records into

c
n,w
	​

(z)G(w;z).

Do not initially call masterTransportCanonicalSourceExpression.

That function converts all records to TransportWord objects and then forms one large Total. 

CanonicalWordTransport

 It is suitable only after the term count is known to be small.

Group the final output by GPL weight.

For each requested order,

[I
i
	​

]
ϵ
n
	​

=
k=0
∑
5
	​

∣w∣=k
∑
	​

c
i,n,w
	​

(z)G(w;z).

This is directly suitable for a paper appendix or machine-readable ancillary file.

Only if the current traversal reaches its cap

The first optimization should be exact reachability pruning, not a larger MaxVisitedPrefixes.

For every q and remaining word length ℓ, precompute the canonical indices that can reach the support of h
q
	​

 in exactly ℓ residue steps. During forward traversal, discard a prefix matrix whose column support has empty intersection with that backward-reachable set.

This cannot remove a contributing word and usually avoids attempting all 21 letters from every prefix. It is optional unless the present weight-five extraction reaches the default prefix or term cap.

Final assessment
Issue	Decision
Matrix orientation	Correct
Residue order versus GPL word order	Correct
T
r
	​

=−3,…,2	Sufficient and minimal given q
min
	​

=0
H
q
	​

=0,…,5	Sufficient and minimal
T
s
−1
	​

(0)=0,…,5	Sufficient for boundary orders 0,1,2
T
r
	​

 above 2	Cannot contribute under the stated valuations
Ignoring ActiveRowsByOrder	Correct and necessary
37×37 slicing	Safe only with gauge, inverse, and residue closure as stated
Next output route	Row/order-local sparse GPL coefficient tables; contract physical boundaries first

The present construction is mathematically suitable for paper-facing GPL coefficients. The minimum necessary correction is to make the 37-master closure statement explicit at the residue and factor-product levels; the lazy source traversal itself does not need redesign.

## Sources sent to Pro

- Original source reference: `../../../../factorization-and-loops/FeynFacet/Private/CanonicalWordTransport.wl` (not archived with this exchange)
