# Community Ff Exact Certificate Followup

## Question

The deterministic identity you recommended has now completed.

After setting the already certified monomial variables
q2 = qp = s = ya = yb = yh = 1, the normalized source composition contains
851 top-level rational terms and occupies 11,690,712 Mathematica bytes. The
reconstructed five-variable candidate occupies 15,968,416 Mathematica bytes.

The attached script evaluated

  Together[source - candidate]

over Q(CA, CF, epsilon, x, y). Mathematica returned the exact integer zero in
298.930534 s. The wrapper elapsed time was 5:02.26; observed WolframKernel
resident memory reached about 649 MB. The retained result is

  <|"ExactDifferenceZero" -> True,
    "Seconds" -> 298.930534,
    "DifferenceBytes" -> 16|>

This is in addition to the two independently seeded reconstructions and the 48
held-out direct source-record evaluations.

Please answer only these closing questions:

1. Does this exact rational identity supply the deterministic source-composition
   certificate you requested for master 64?
2. Is direct Together acceptable as the retained certificate for this measured
   851-term case, even though the denominator-grouping method may scale better
   to harder columns?
3. Name any remaining mathematical identity required before this one coefficient
   can be called an exact analytic post-IBP coefficient.

## Pro response

Yes. Under the already established conditions—complete coverage of the 1,129 source contributions, exact Kira rows, the separately certified monomial factor, and a rational grammar in

Q(C
A
	​

,C
F
	​

,ϵ,x,y),

the calculation

Together(C
64
source
	​

−C
64
rec
	​

)=0

is the deterministic source-composition certificate requested for master 64. Unlike the two reconstructions and the 48 held-out modular comparisons, this is an exact characteristic-zero identity, not a probabilistic interpolation check.

The attached script performs precisely that test after replacing the independently certified common variables by one:

Wolfram Language
{seconds, difference} =
  AbsoluteTiming[Together[source - candidate]];

and accepts only the literal exact integer zero through

Wolfram Language
TrueQ[difference === 0]

before exiting successfully.

Yes. Direct Together is fully acceptable as the retained certificate for this measured case. With 851 terms, roughly 11.7 MB of source expression, about 16.0 MB for the candidate, approximately five minutes elapsed time, and about 649 MB resident memory, it is simpler and more transparent than introducing denominator-group machinery solely for this coefficient.

The retained certificate should include:

the exact script;

hashes of the source composition and reconstructed candidate;

the variable ordering and definitions;

the independently established monomial-factor certificate;

the Mathematica version;

the result

ExactDifferenceZero→True;

the exact zero object, whose ByteCount is 16.

Denominator grouping remains the appropriate fallback when a harder column makes direct Together exceed the available time or memory. It is not mathematically superior when the direct exact calculation already completes.

No further scalar algebraic identity is required, provided the independent monomial certificate already proves the restoration

C
64
full
	​

=
y
a
2
	​

y
b
2
	​

y
h
4
	​

q
2
4
	​

q
π
2
	​

s
	​

C
64
rec
	​

(C
A
	​

,C
F
	​

,ϵ,x,y),x=−
s
t
	​

,y=−
s
u
	​

.
	​


The complete proof is then the composition of:

C
64
source
	​

=
y
a
2
	​

y
b
2
	​

y
h
4
	​

q
2
4
	​

q
π
2
	​

s
	​

C
64
source
	​

,
C
64
source
	​

=C
64
rec
	​

,

where the second equality is the exact Together result just obtained.

To call it an exact analytic post-IBP coefficient, the accompanying artifact must still retain—not re-prove algebraically—the established physical definitions and metadata:

q
2
	​

 and q
π
	​

 as the declared analytic normalization factors;

y
a
2
	​

=x
a
	​

, y
b
2
	​

=x
b
	​

, and y
h
2
	​

=z
h
	​

 with the positive-root branch;

the physical x,y chamber;

the dimension rule D=4−2ϵ;

the master identity and topology;

cut orientations, causal data, and BMHV context;

the stripped distribution and coupling factors, if they belong to the final hard-function normalization.

Those are restoration and provenance requirements, not additional rational identities. Master 64 can now be classified as a deterministically certified exact analytic post-IBP coefficient.

## Sources sent to Pro

- Original source reference: `../../ppHX_NNLO_DoubleReal/FiniteFieldReconstruction/Overnight_2026-08-09/certify_nnlo_master0064_exact.wls` (not archived with this exchange)
