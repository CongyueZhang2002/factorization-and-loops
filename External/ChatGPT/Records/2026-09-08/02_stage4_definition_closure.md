# Stage 4 final definition-check review

```json
{
  "conversationUrl": "https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4",
  "model": "gpt-6-pro",
  "thinkingEffort": "standard",
  "requestMessageId": "b4142c0e-aa5a-494f-98a0-a984765ab870",
  "requestHttpStatus": 200,
  "sentAt": "2026-09-08T08:13:04.591Z"
}
```

The reviewer identified a conditional-evaluation counterexample. The implementation now uses the optimized check only for an explicit set of mathematical expression heads and retains the prior full graph check for all other expression forms. Both out-of-range and self-reference counterexamples are regression tests. This is a review of the provided implementation description, not unprovided source files.

## Question

Please review one concrete follow-up change to the actual production path, especially for a counterexample. Your first design review is saved. The early-color prototype was slower and has been withdrawn. The retained speedups are epsilon coefficient extraction before restoring the large coefficient field, independent coefficient workers, and late color collection that preserves color-free references.

The next measured cost is a redundant final graph check: 97.54 s after 126.28 s of interior input checks/mapping, 22.90 s of endpoint checks, 19.42 s of distribution extraction, and 2.46 s of assembly. We propose to replace only that final graph traversal as follows.

Each input has already been verified: scalar a[i] definitions reference only earlier a[j]; F[i,t] integrands only earlier F[j,t]; K[i,t] expressions only earlier K[j,t]. Every a/F/K reference anywhere in each input and its selected output expressions has an integer index in that input's namespace range. Forbidden epsilon, unresolved boundary/initial constants, failed or unevaluated series objects and undefined values are absent.

The assembly applies coordinate replacements only to the interior, then concatenates the verified input graphs, translating every namespace index by that block's accumulated offset. All references are rewritten using a recursive data rewrite which preserves association/rule keys. The coordinates are scalar symbols from the declared KinematicVariables. The replacement RHS cannot contain a/F/K/B/C, epsilon, rules, associations, missing/failed/undefined values or unevaluated series. The existing capture check prohibits bound integration/kernel variables appearing in the map.

The new final check verifies:
1. Total definition lengths equal accumulated namespace lengths.
2. A full FreeQ scan of all transformed definitions and final coefficients still rejects epsilon, unresolved B/C, failed/unevaluated series and undefined values (thus a coordinate substitution yielding 1/0 is caught).
3. Every a/F/K reference in the newly assembled coefficients has an integer index in the final namespace range.
It does not rescan every edge of every definition graph a second time: offset translation preserves both dependency order and valid range, and the restricted scalar coordinate substitutions cannot create indexed references.

No graphs are pruned or reordered here; no trust is placed in a caller's "validated" flag; every input is actually checked on every call. No lower-bound or endpoint-uniformity proof is weakened. This has exact fixtures showing that invalid input graphs, an injected a[999] in the coordinate map, and a coordinate map producing infinity are rejected. We will compare the complete output with the prior implementation.

Is this sufficient to preserve the old checks? Identify any missing way that these operations could create a bad definition/reference; distinguish limitations already present in the old validator (e.g. it never certified arbitrary cross-namespace cycles) from regressions in this proposed change. Keep your response focused. Repository: https://github.com/CongyueZhang2002/factorization-and-loops ; proposed changes are local.


## Pro response

Conditionally yes: the offset argument preserves the old graph invariants, but the listed checks are not sufficient for arbitrary Wolfram Language expressions. The missing condition is that evaluation during rewriting cannot construct new references. A reference-free coordinate-map RHS does not establish that condition.

1. The structural argument is correct

For namespace T∈{a,F,K}, let block b have length n
b,T
	​

 and offset o
b,T
	​

. Correct translation gives

1≤j≤n
b,T
	​

⟹o
b,T
	​

<o
b,T
	​

+j≤o
b,T
	​

+n
b,T
	​

.

For a same-namespace dependency j<i,

o
b,T
	​

+j<o
b,T
	​

+i.

Thus concatenation and namespace-specific translation preserve range and strict dependency order. Scalar substitution cannot change the literal integer indices of existing reference nodes. For a reference-preserving expression language, the second graph traversal is redundant.

2. A concrete evaluation counterexample

Consider one block with two scalar definitions, stored as data rather than assigned as downvalues:

Wolfram Language
ClearAll[a, x];

aDefs = {
  1,
  If[x == 0, Head[a[1]][999], 1]
};

coefficient = a[2];
coordinateMap = {x -> 0};

Before substitution, the only indexed reference inside the second definition is a[1]: an earlier, in-range reference. The map RHS is simply zero. With symbolic x, If leaves its branches unevaluated; after x -> 0, the selected branch evaluates, and Head[a[1]] supplies the head a, producing a[999]. This follows from the documented behavior of If and Head. 
Wolfram Documentation
+1

The transformed data are therefore

Wolfram Language
aDefs = {1, a[999]};
coefficient = a[2];

Your three proposed final checks pass: the length remains two, none of the forbidden objects occurs, and the newly assembled coefficient references valid index two. The old definition-reference check rejects a[999].

Replacing 999 by 2 gives an in-range self-reference instead, showing that the missing protection concerns dependency order as well as range.

This is a contract-level counterexample, not a claim that your actual input grammar accepts it. An existing grammar restriction or input-validation behavior may already exclude it.

The appropriate guard: admitted expressions must remain reference-preserving under the actual evaluator—not just under syntactic replacement. In particular, do not admit expression-inspection/construction or evaluation hooks that can reinterpret reference nodes. Merely banning bare a/F/K symbols is insufficient: the example initially uses a only as the head of a valid reference. Wolfram Language normally evaluates reconstructed expressions, so a recursive data walker alone does not establish this property. 
Wolfram Documentation

Enforce this during the existing input walk. If your production expression language already guarantees it, no additional graph traversal is needed. Otherwise, retain the old checks at the transformation boundary for definitions outside that guaranteed language.

3. Two implementation boundaries—and what is not a regression

Preserved keys must be metadata, not reference-bearing expression positions. Otherwise “preserve every key” and “translate every reference” conflict. Also, ordinary FreeQ scans association values, not keys, so it is not literally an everywhere scan of arbitrary association data. 
Wolfram Documentation

An untranslated key containing a[1] can silently refer to an earlier block while remaining globally in range. The old range/order validator would generally miss that too; it is not necessarily a regression from removing the final traversal. Reference-free metadata keys avoid the issue.

Offset correctness remains an implementation obligation. Use separate accumulated offsets for each namespace and translate each occurrence exactly once. Total lengths alone do not prove correct translation. A small exact fixture with two blocks, unequal a/F/K lengths, and references nested in all supported expression positions directly tests this. Your complete-output comparison should include every definition, not only the selected coefficients.

Arbitrary cross-namespace cycles remain an old limitation under the validator you describe. Correct renaming neither introduces such cycles nor repairs them; removing the redundant traversal does not weaken a guarantee that traversal never supplied.

Conclusion: approve the removal once reference-preserving evaluation is an established input-language invariant. Without that invariant, the held-branch example is a genuine old-rejects/new-accepts regression; with it, I find no graph-theoretic reason to retain the final edge rescan.