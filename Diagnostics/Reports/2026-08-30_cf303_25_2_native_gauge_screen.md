# CF303 (25,2): large gauge-screen backend measurement

Date: 2026-08-30

## Input

- chart: `Kallen2Bilinear115`
- strip dimensions: `2 x 1`
- alphabet: 31 one-forms
- conservative screen offset: `{4,4}`
- affine system per image: `6724 x 6692`
- estimated packed matrix bytes: `720,059,712`
- matrix entries: `44,993,728`

## Old route

The screen used two serial Wolfram calls,
`MatrixRank[A, Modulus -> p]` and `MatrixRank[Append[A,b], Modulus -> p]`,
followed by a full left null space for a defect. The first production image
was still unfinished after approximately 14 minutes when the run was stopped;
RSS had plateaued near 7.2 GB. It had not produced a mathematical verdict.

## New route

Commit `14db4f7` size-gates large screens with no candidate columns to the
existing authenticated CFFR1/FLINT affine backend. Small screens, explicit
left-witness requests, and `CandidateOneForms` discovery retain the Wolfram
route.

A forced-native synthetic regression covered:

- consistent image -> defect 0, integer rank, FLINT backend;
- inconsistent image -> defect 1, native affine-inconsistency evidence;
- explicit witness -> Wolfram backend and verified witness.

All 10 assertions passed. The two native toy images took 0.290 s and 0.257 s;
the explicit Wolfram witness toy took 0.009 s.

The physical CF303 screen then completed **two independent images in 359.9 s
total**, including compilation, point assembly, request serialization, and
native elimination. Both images had defect 1:

```text
GaugeImageObstruction
defects {1,1}
images 2
unknowns 6692
```

Thus throughput improved by more than 4.7x relative to the old lower bound
(two complete images in 6.0 min versus no first-image result after ~14 min).
The remaining dominant cost is point assembly/serialization, not modular
elimination.

## Mathematical boundary

This is a high-confidence modular obstruction for the stated 31-form
alphabet and conservative denominator/support ansatz. It is not a theorem
excluding every possible closed rational E1 extension. A fixed-path provider
may be accepted constructively as `ExactPathForcingAccepted` without claiming
`EpsFormObstructionCertified`.
