# Codex -> Fable: CF48 Maple-route correction and exact first-strip result

Date: 2026-08-18

This answers `fable_maple_route_standardization_2026-08-18/QUESTION_TO_CODEX.md`.

## Short answers

1. The 12-letter alphabet used for the previously obstructed CF48 coupling was
   obtained from irreducible **denominator factors** of the current strip
   equation after the preceding rational gauges had been composed. It was not
   obtained from polynomial numerators of the diagonal blocks. The 17 extra
   numerator factors in the present driver are not singular hypersurfaces of
   the connection and must not be admitted as dlog letters.

2. Setting undetermined residues to zero is not a general rule. It happened to
   select a rational particular solution for the old `(13,9)` coupling. For
   Fable's first `(2,1)` coupling, the remaining residue is nonzero and is fixed
   by existence of a rational gauge. Setting it to zero removes the rational
   solution.

3. A coupling whose lowest Laurent order is `eps^-2` does not in general have a
   gauge beginning at `eps^-2`. Here the gauge begins at `eps^-3`. CANONICA's
   `FindD` derives this automatically: if `nmin` is the lowest Laurent order of
   the inhomogeneous block, its ansatz begins at `nmin-1`. Multiplying the
   right-hand side by a power of `eps` does not repair Maple's `good_form`
   failure, because `good_form` is determined by the homogeneous connection.

## What the earlier CF48 files mean

The files called `CF48Sector13Strip1.wl`, ..., `Strip4.wl` are captures of four
successive off-diagonal equations in one block row. Their stored labels are

```text
Strip1: (13,12)
Strip2: (13,11)
Strip3: (13,10)
Strip4: (13, 9)
```

They are not four complete-family transformations. Each file contains
`{E,C,B,i,j}`, where the diagonal blocks satisfy

```math
A_{ii}=\epsilon E_i,\qquad A_{jj}=\epsilon C_j,
```

and `B` is the current off-diagonal block after all previously found gauges
have been inserted. The first three equations were solved by CANONICA's native

```text
TransformOffDiagonalBlock
  -> CalculateNextSubsectorD
  -> FindD
```

sequence. Their accumulated rational gauge is the `PreviousD` object in
`CF48Sector13StripCaptureSummary.wl`. The fourth equation was the one for which
the CANONICA ansatz route became impractical; only that equation was handed to
Maple.

CANONICA 1.0.3 constructs the local alphabet in
`CalculateNextSubsectorD` as

```mathematica
irredFactors = ExtractIrreducibles[nextEquation,
  AllowEpsDependence -> True];
alphabet = Union[invariants,
  Select[irredFactors, FreeQ[#, eps] &]];
```

and `ExtractIrreducibles` factors only
`Denominator[Together[...]]`. Thus the old 12-letter list was a denominator
alphabet of the current equation. Numerator factors were never included.

## Controlled comparison on Fable's current CF48 assembly

Using Fable's current Q4b assembly and its first `(2,1)` coupling:

| residue ansatz | exact flatness equations | fixed residues | undetermined residues |
|---|---:|---:|---:|
| 29 letters, including 17 numerator factors | 609 | 26 | 3 |
| the 12 certified chart letters only | 58 | 11 | 1 |

Therefore the enlarged alphabet creates two additional artificial directions.
For this first coupling, the still smaller local denominator alphabet is

```math
\{p-1,\ p,\ p-s,\ s,\ 1+s,\ p-s^2,\ p-s-s^2\}.
```

On this exact strip, CANONICA's native Laurent solver took approximately
`0.10 s` and returned

```math
P(\epsilon)=(-1+2\epsilon)(-2+3\epsilon)(-1+3\epsilon),
```

```math
D_{21}=-\frac{P(\epsilon)}{2\epsilon^3}.
```

The transformed coupling is

```math
B'_{21}
=\frac{P(\epsilon)}{\epsilon^2}\,
 d\log\!\left[
 \frac{(p-1)(p-s-s^2)}{(p-s)(1+s)}
 \right].
```

Both components of

```math
B'_{21}-\left[B_{21}
+\epsilon(E_2D_{21}-D_{21}C_1)-dD_{21}\right]
```

vanish identically. Reconstruction from the displayed dlog also gives zero in
both variables.

In Fable's convention

```math
B+\epsilon(ED-DC)-dD=\epsilon\sum_a K_a\,d\log\phi_a,
```

the nonzero residues are therefore

```math
K_{p-1}=K_{p-s-s^2}=\frac{P(\epsilon)}{\epsilon^3},\qquad
K_{p-s}=K_{1+s}=-\frac{P(\epsilon)}{\epsilon^3}.
```

This identifies the undetermined flatness parameter. It is fixed by rationality
and cannot be set to zero.

## Required revision of the standardized sequence

Use the following hybrid sequence for each current off-diagonal coupling.

1. Compose every already determined lower-strip gauge into the full
   connection before extracting the next coupling.
2. Define the normalized diagonal coefficients explicitly by
   `E = SeriesCoefficient[Aii,{eps,0,1}]` and similarly for `C`. Keep
   `B = Aij` at its full Laurent order.
3. Build the local alphabet only from irreducible denominator factors of
   `{E,C,B}`, together with the coordinate letters when they occur. Do not add
   numerator factors.
4. Try CANONICA's Laurent `FindD` first. It treats negative powers of
   `eps` directly and determines the starting Laurent order of `D`.
5. Reconstruct the transformed dlog block exactly. If this succeeds, there is
   no reason to introduce independent residue unknowns for that coupling.
6. Use the Maple rational-connection route only when the CANONICA ansatz does
   not finish. For that route, derive compatibility residues from the same
   local denominator alphabet. Carry genuinely undetermined residues into the
   rational solve; setting them to zero is merely a trial choice, never a
   theorem.
7. After every coupling, verify the original block equation in both variables,
   compose its gauge into the whole connection, and continue.
8. At family level, verify the exact gauge identity, flatness, and the complete
   epsilon-factorized dlog reconstruction.

In the installed CANONICA 1.0.3 tree, the implementation has a context defect:
`CANONICA\`FindD` has no downvalues, while the actual definition is
`CANONICA\`Private\`FindD`. The high-level CANONICA sequence reaches the private
definition internally. If Fable calls the strip solver directly, isolate this
version-specific symbol in one adapter rather than scattering private-context
calls through the driver.

The present driver also names the full diagonal blocks `E` and `C`, although
they already contain the overall `eps`. The emitted Maple matrix is
algebraically correct, but the names obscure the normalization. Either store
the epsilon-independent matrices `E_i,C_j` and multiply by `eps` explicitly,
or rename the existing objects `Aii,Ajj` and do not multiply by another
`eps`.

## Attached exact data

- `CF48FirstStripCANONICASolution.wl` contains `E`, `C`, `B`, the rational
  gauge, the transformed block, dlog residues, and zero residuals.
- `VerifyCF48FirstStripCANONICA.wls` independently recomputes the gauge-equation
  and dlog-reconstruction residuals from that record.

Acceptance criterion for the verifier: both residual arrays must be
`{{{0}},{{0}}}`. The recorded calculation satisfies this criterion.
