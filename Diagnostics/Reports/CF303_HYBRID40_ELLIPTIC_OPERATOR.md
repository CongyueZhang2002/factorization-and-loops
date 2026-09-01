# CF303 hybrid 40-master elliptic operator

Date: 2026-08-31

Status: accepted scratch result; package source is unchanged.

## Result

The 37-master rational subsystem and the three masters of block 15
(`23,24,25`) now form one exact, lazy Chen operator on the direct path
`z : 1/2 -> uFinal`.  Its accepted Wolfram artifact is

`Runtime/2026-08-31_cf303_native_dlog_residues/cf303_hybrid40_elliptic_operator.wl`.

The operator contains the full block-15 connection from feeder masters
`{1,6,10,12,13,14,15,16,21,22}` and its 3x3 homogeneous connection.  It
does not enumerate iterated-integral words.  A requested coefficient is a
sparse residue-matrix product multiplying a word in the stored one-form
alphabet.

Construction took 0.019 s after provider loading.  The accepted probe at
epsilon order -1 returned the three block-15 rows with one empty-word term.

## Exact reduction facts

- 39 block-15 path entries were reduced.
- 36 are nonzero and all 36 contain both rational and elliptic pieces.
- Every entry is exactly epsilon-linear.
- Every Hermite primitive is zero.
- No `E4Eta2` / second-kind-at-infinity kernel occurs.
- The uncompressed alphabet has 23 one-form letters and 410 sparse residue
  coordinates.
- The reusable reduction and the earlier physical depth-two coefficient both
  pass exact algebraic-function-field derivative residuals.

Thus block 15 needs no per-word Hermite reduction: integration is exactly
letter prepending.

## Homogeneous-alphabet compression

Fifteen of the 23 one-forms occur in the 3x3 homogeneous block.  Their
residue matrices span a five-dimensional algebraic-function-field vector
space.  Expanding the p dependence still leaves a five-dimensional space
over constant rational matrices.  The accepted preferred representation is

`A_15,15(z) dz = Sum[a=1..5, B_a Omega_a(z)]`,

where all five `B_a` are constant rational 3x3 matrices and every `Omega_a`
is an explicitly stored linear combination of standard GPL/E4 kernels.
The exact reconstruction is recorded in

`Runtime/2026-08-31_cf303_native_dlog_residues/cf303_block15_constant_generators.maple`.

The matrices do not commute (79 of 105 pairs in the original 15-residue
presentation have nonzero commutators), so replacing the path-ordered
solution by an ordinary exponential would be wrong.  The five-generator
compression is nevertheless exact and reduces the structural word bound at
weight five from

`15^5 = 759375` to `5^5 = 3125`,

a factor of 243.  This is also the representation that keeps the existing
constant-residue sparse traversal on its fast path.

## Alphabet and convention

The hybrid operator has:

- 21 direct-u images of the accepted rational GPL letters;
- 23 standard root-free block-entry forms (`GPLPole`, `GPLFactor`,
  `E4Omega0`, `E4OmegaInf`, `E4Pole`, `E4Factor`);
- five composite homogeneous elliptic forms, each explicitly resolved into
  the preceding standard forms.

For a polynomial factor `q`, `GPLFactor[q,k]` means `z^k dz/q(z)` and
`E4Factor[q,k]` means `z^k dz/(q(z) Y(z))`.  These root-free forms are finite
sums of standard simple-pole GPL/E4 kernels after splitting `q`; splitting is
deferred until a paper-facing word is requested.  A marked `E4Pole[c]` uses
one inert sheet value `Yc[c]` throughout the word, with `Yc[c]^2=P4(c)`.

## Scope remaining

This artifact completes the rational subsystem plus block 15.  Blocks 17,
21, and 25 are not yet included.  Their targeted exact path exports and
Hermite censuses determine whether they enter the same pure-letter operator
or require the already implemented primitive/IBP recursion.  The final
physical gauge and boundary projection are also still to be composed.
