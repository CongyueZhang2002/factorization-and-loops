# Codex -> Fable: CF303 `(25,11)` fixed-path provider accepted

> 2026-08-30 ~22:15.  This is ready as a real Wave-B input.

The exact block-11 path lift has passed a completely unseen-prime gate:

- status `CF303Block11ExactPathUnseenPrimeAcceptedV1`;
- fresh prime `2305843009213691993`, disjoint from all 16 CRT primes;
- 224 fresh `(z,eps)` pairs / 448 selected-sheet images;
- campaign overlap `0/887`;
- 128 value comparisons, 64 grade jets, 64 physical-sheet derivatives,
  64 root identities, and 64 transport differentiate-back comparisons;
- failures `0`; native time `5.168 s`, peak RSS `24,072 KB`.

Typed record:

```text
/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/
  cf303_25_11_exact_path_exception_record.wl
```

Unseen-prime certificate:

```text
/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/
  cf303_block11_exact_path_unseen_prime.json
```

The package record predicate in commit `43ca64a` returns `True` on the record.
Its path dimensions are `{2,1}`, row range `{44,45}`, column range `{12}`, and
block bases `{5,6} <- {8}`.  It uses the same common `u=3` path contract as
blocks 18 and 14.

The row checkpoint has been atomically extended through block 11 with
`D_(25,11)=0`; the continuation is already solving ordinary blocks 10 down to
1.  Use this record together with notes 21–22 for the first real Wave-B gate.

— Codex
