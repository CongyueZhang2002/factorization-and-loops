# CF259 Materialization

## Question

Please independently review the attached current `BlockEquationDeferred.wl`, continuing this same Assess Multiquadratic Pipeline conversation.

We are optimizing CF259 block `(27,9)`. Two exact deferred-bundle operands are about 40 MB each. The old Wolfram rational collector took 944.9 s and more than 1066.5 s. Direct Maple `evala(Normal)` reduced each to about 5 s, but Maple merged declared generators such as `Sqrt[d1] Sqrt[d2]` into `Sqrt[d1 d2]`, so the bundle compiler correctly rejected `RadicalOutsideDeclaredFrame`.

The current uncommitted fix is `blockEquationDeferredMapleCanonicalOperandValue`: replace every half-integer power of each distinct base by an independent opaque symbol, ask Maple to normalize the rational function in those symbols, run the existing exact canonical-quotient collector while the symbols are still opaque, and finally substitute the original square-root generators back into the numerator and denominator-factor keys. On the two real operands, the package route now takes 15.2 s and 17.6 s (about 60x faster than the pathological tails); input and output radical bases are identical and `OutsideInputRadicalBases` is empty. Focused suites pass 16/16 and 53/53.

Please assess the actual algorithm and code, especially:

1. Is this an exact formal normalization in the multiquadratic extension, including negative and general half-integer powers?
2. Can placeholder collection or restoration silently change a result, collide, or mishandle nested radicals/repeated bases?
3. Is there a simpler or materially faster exact route that preserves the declared generator spelling? Ignore changes worth only a few percent.
4. Is the fallback scoped generically and safely, or can it affect ordinary rational/easy families?

Focus on mathematical/algorithmic correctness and major performance. Do not recommend additional production symbolic checks; per-block production acceptance is exact arithmetic at fresh random points modulo primes.

## Pro response

Verdict: keep the algorithm, but fix two correctness defects before promotion

The opaque-root strategy is mathematically sound and the reported 15–18-second performance justifies retaining it. The attached implementation is not yet generally correct: root lookup can select a subexpression rather than a complete radicand, and restoration can silently discard denominator multiplicities.

These are small local fixes. Neither requires another canonicalization engine or additional production symbolic checking.

I inspected blockEquationDeferredMapleCanonicalOperandValue, its dispatcher, and the bundle’s frame-canonicalization consumers in the attached file. This is a static review; I did not rerun the Wolfram/Maple suites or inspect newer definitions of the external Maple and rational-collector helpers.

1. The formal normalization is exact—but is not a quotient-field canonical form

For each distinct base b
i
	​

, introduce an independent indeterminate t
i
	​

, and replace

b
i
n/2
	​

⟼t
i
n
	​

,n∈Z odd.

This includes negative and general half-integer powers:

b
−1/2
↦t
−1
,b
−3/2
↦t
−3
,b
5/2
↦t
5
.

The implementation does exactly this through rootImages[[...]]^(2 exponent). 

BlockEquationDeferred

Any rational identity obtained in the independent t
i
	​

 remains valid after substituting

t
i
	​

↦
b
i
	​

	​

,

on the generic open set where the original rational expression is defined, using the same square-root branches as the input. In particular, this does not use the unsafe identity 
ab
	​

=
a
	​

b
	​

. Wolfram itself does not apply that identity generically. 
Wolfram Documentation Center

The distinction is:

Exactness: preserved by rational normalization followed by specialization.

Canonicality in the multiquadratic field: not guaranteed, because Maple was deliberately not told t
i
2
	​

=b
i
	​

.

Consequently, restored factors may become reducible, coincide, or acquire further common factors with the numerator. Leaving such additional cancellation undone is mathematically harmless. Dropping coincident denominator factors is not.

2. Verified defect: FirstPosition searches inside radicands

Location: BlockEquationDeferred.wl:909–913.

The lookup is effectively:

Wolfram Language
FirstPosition[
  radicalBases,
  candidate_ /; SameQ[candidate, base],
  Missing["NoRoot"]
]

It then uses First[position] as the root index. 

BlockEquationDeferred

But FirstPosition defaults to all levels, includes heads, and traverses depth-first. It does not search only the complete elements of radicalBases. 
Wolfram Documentation Center

For example, with

Wolfram Language
radicalBases = {1 + x, x};

looking for x finds the occurrence inside the first base before the second complete element. Taking First[position] then assigns the placeholder for 
1+x
	​

 to a power of x.

Minimal repair
Wolfram Language
position = FirstPosition[
  radicalBases,
  candidate_ /; SameQ[candidate, base],
  Missing["NoRoot"],
  {1},
  Heads -> False
];

The same file already uses this correct complete-element pattern in blockEquationDeferredFrameCanonicalize and blockEquationDeferredFactorRootMask. 

BlockEquationDeferred +1

An exact-key lookup table is another option, but the level restriction is the smallest sufficient change. A failed lookup should refuse the opaque conversion rather than silently leave an unmasked half-integer power for Maple.

3. Verified defect: restoration can lose denominator powers

Location: BlockEquationDeferred.wl:931–932.

The current restoration is:

Wolfram Language
Association @ Map[
  (First[#] /. restoreRules) -> Last[#] &,
  Normal[Last[pair]]
]

Distinct formal denominator factors can become the same expression after restoring the roots. Association retains only the last value for a repeated key. It does not add the exponents. 

BlockEquationDeferred

 
Wolfram Documentation Center

Concrete counterexample

Consider

f(x)=
(x+1)(x
3/2
+
x
	​

)
1
	​

.

The opaque expression is

(x+1)(t
3
+t)
1
	​

=
(x+1)t(t
2
+1)
1
	​

.

A correct formal factor record has three distinct keys:

x+1,t,t
2
+1,

each with exponent one.

After t↦
x
	​

, the first and third keys both become x+1. The current Association construction retains exponent one instead of two, yielding

x
	​

(x+1)
1
	​


instead of

x
	​

(x+1)
2
1
	​

.

At x=4, these are 1/10 and 1/50. Both outputs have the same radical-base census, so the reported OutsideInputRadicalBases check would not detect this error.

Minimal repair

Restore to a list of rules, then merge with Total:

Wolfram Language
restoredFactorRules =
  ((First[#] /. restoreRules) -> Last[#]) & /@
    Normal[Last[pair]];

restoredFactors = Merge[restoredFactorRules, Total];

Merge explicitly combines values belonging to repeated keys. 
Wolfram Documentation Center

Also handle inexpensive specialization cases directly:

restored factor 1: remove it;

restored nonzero rational constant: fold its power into the numerator’s content;

restored factor 0: refuse the result.

Do not perform another general Together or algebraic factorization after restoration. Algebraically equivalent but syntactically distinct factors can remain separate without changing the value; exact duplicate keys simply must have their multiplicities summed.

4. Placeholder and nested-radical handling
Placeholder symbols are not guaranteed fresh

Location: BlockEquationDeferred.wl:904–906.

The code constructs persistent symbols from an eight-character hash prefix:

FeynFacetMapleRoot`facetBEDRoot<8 hex characters>x<index>

It does not localize their definitions or establish that they are absent from the input. 

BlockEquationDeferred

Reusing an undefined symbol across separate calls is not itself wrong. The actual risks are:

an existing OwnValue or UpValue on that symbol;

the same symbol already occurring as an ordinary input variable;

name collisions if the Maple serializer discards contexts.

Use genuinely fresh, undefined placeholders and the serializer’s existing variable-remapping mechanism. This is symbol hygiene, not a reason to add another content-hash scheme. The current Maple serializer is outside this attachment, so I cannot certify its context/name behavior here.

Nested radicals are not inherently broken by the opaque method

ReplaceAll replaces a matching outer subexpression without descending into that replacement. Thus a nested radical can be frozen as one outer atom and later restored using its original complete base. That is exact; recursively expanding or denesting it inside Maple is unnecessary. 
Wolfram Documentation Center

However, opaque normalization does not establish membership in the declared multiquadratic field. That remains the job of the existing frame canonicalizer.

In the bundle path, that ordering is already correct:

blockEquationDeferredFrameCanonicalize rejects unsupported powers and denests into the declared frame;

only its accepted expression enters operand canonicalization. 

BlockEquationDeferred +1

The serial bundle walk enforces the same ordering. 

BlockEquationDeferred

Keep it that way. Do not treat successful opaque Maple normalization as permission to admit an undeclared nested radical.

General half-integer powers need no PowerExpand

The current b
n/2
↦t
n
 rule is the correct one. Avoid replacing it with separate transformations of 
b
	​

, 1/
b
	​

, or 
1/b
	​

, which create needless branch questions.

Preserve the original bases literally and restore them once. The two local defects above—not half-integer exponent arithmetic—are the mathematical problems.

5. Fallback scope and effect on easy families

The dispatcher is:

rationalMaterializationCanonicalValue;

opaque Maple fallback;

rationalMaterializationTogetherValue.

A successful existing rational collector returns immediately. The Maple helper returns $Failed immediately when it finds no half-integer powers. Thus ordinary radical-free rational operands do not incur a Maple process or change their mathematical route. 

BlockEquationDeferred +1

Two qualifications:

The fallback is not literally restricted to “large chartless tails.” It is eligible for any half-integer-containing operand rejected by the accelerated collector. That is generic and reasonable, but the comment is narrower than the executable condition.

Its Maple limit defaults to 900 seconds independently of an outer materialization budget. If Maple fails, the dispatcher proceeds to the old Together path. This is a potentially expensive fallback sequence, not a bounded total operation. 

BlockEquationDeferred +1

No family identifier controls this dispatch. The CF259 references are explanatory comments, not executable specialization.

6. Performance recommendation

Keep the opaque-Maple route after the local repairs. The reported reduction from approximately 945–1067 seconds to 15–18 seconds is large enough to settle the immediate algorithm choice.

Do not now replace it with:

characteristic-zero norm rationalization;

a new four-channel simplifier;

finite-field reconstruction of these operands;

a new native sparse-polynomial backend.

Those approaches solve a broader problem and have no demonstrated advantage over the now-small cost.

The important optimization is already present: run the quotient collector while the roots remain opaque, then restore only the compact numerator and factor keys. Restoring the roots before the collector would recreate the original algebraic normalization problem. The attachment has this ordering right. 

BlockEquationDeferred

The two focused suites are positive evidence, but their reported passes do not close the two specific counterexamples above. Both can be covered by tiny development regressions; no new production symbolic identity layer is needed.

Minimal action

Restrict radicand lookup to level {1}, Heads -> False.

Replace restored-factor Association construction by multiplicity-summing Merge[..., Total].

Use fresh, definition-free placeholders compatible with the existing serializer.

Retain the existing declared-frame preprocessing, rational fast path, and per-block modular acceptance.

After those changes: GO. The mathematical approach is appropriate; the remaining issues are in lookup and factor restoration, not in the normalization strategy.

## Sources sent to Pro

- [blockequationdeferred.wl](Sources/10_cf259_materialization/blockequationdeferred.wl)
