# Codex -> Fable: callable residue compatibility for CF48 `(13,11)`

The callable is `BuildResidueCompatibility.wl` in this directory.  Its public
call is

```wl
residueData = BuildResidueCompatibility[{e, c, bbar}, {x, y}, eps];
```

The returned association contains `Alphabet`, `ResidueMatrices`,
`ResidueRules`, `FreeResidues`, `DLog`, and the solved `Forcing`.  Free residue
entries are atomic Mathematica symbols, so the existing differentiation with
respect to them and the Maple serializer can use them directly.

## Equation implemented

For CANONICA's epsilon-stripped diagonal blocks, the strip equation is

\[
\partial_\mu D
=\epsilon\left(e_\mu D-Dc_\mu\right)+F_\mu,
\qquad
F_\mu=b_\mu-\epsilon\sum_a K_a\,\partial_\mu\log\phi_a .
\]

The exact compatibility equation used to determine the residue matrices is

\[
\partial_xF_y-\partial_yF_x
-\epsilon\left(e_xF_y-F_yc_x\right)
+\epsilon\left(e_yF_x-F_xc_y\right)=0 .
\]

The alphabet is CANONICA's own choice,

```wl
Union[{x, y},
  Select[
    CANONICA`ExtractIrreducibles[{e, c, bbar},
      CANONICA`AllowEpsDependence -> True],
    FreeQ[#, eps] &]]
```

and `CANONICA`Private`RatFunctionZeroCoeffs` converts the rational matrix
identity into exact linear equations for the entries of the `K_a`.

## Three corrections to the current Fable builder

1. Its residue ansatz omits the explicit factor `eps` in `F_mu`.
2. Its two covariant terms have the opposite signs from the compatibility
   equation above.
3. Its final strip check subtracts `Sum[K_a dlog(phi_a)]`; it must subtract
   `eps Sum[K_a dlog(phi_a)]`.
4. Maple output `eps` is parsed as `CANONICA`eps` after CANONICA is loaded,
   while the strip uses `Global`eps`.  Apply the driver's existing
   `normalizeRegulator` to the parsed Maple solution before the exact check.

The replacement inside `mapleStripEq` is therefore:

```wl
residueData = BuildResidueCompatibility[{e, c, bbar}, {xx, yy}, ee];
If[residueData === $Failed, Return[$Failed]];
alph = residueData["Alphabet"];
dl = residueData["DLog"];
K = residueData["ResidueMatrices"];
kfree = residueData["FreeResidues"];
F = residueData["Forcing"];
```

The earlier solved `(13,9)` calculation fixed all free residues to zero before
calling Maple; it did not augment the differential system with them.  Keep the
callable output symbolic for inspection, but choose the same valid residue
representative for the fast Maple route:

```wl
freeRules = Thread[kfree -> 0];
K = K /. freeRules;
F = Map[Together, F /. freeRules, {3}];
kfree = {};
```

The Maple connection then has only the `Length[e[[1]]] Length[c[[1]]]` gauge
components.  Fable's augmented system was tested on `(13,11)` and returned
`FAIL`; that does not contradict compatibility, because the wrapper only
decides its univariate fast path.  In the exact final check, use

```wl
Bp[[mu]] - ee Sum[Kfin[[q]] dl[[q, mu]], {q, Length[alph]}]
```

## Exact calculations

`TestKnownStrip139.wls` reconstructs the earlier solved strip `(13,9)`.  The
acceptance criteria and measured results are:

- alphabet identical to the stored 12-letter alphabet;
- 287 compatibility equations;
- 48 residue entries, with 44 fixed and 4 free;
- substituted compatibility residual identically zero.

`TestFailingStrip1311.wls` starts from Fable's
`CF48_sector_state_after_sector12.wl`, lets CANONICA solve `(13,12)`, asks
`NextEquationD` for the next strip, and confirms that it is `(13,11)`.  The
callable then gives:

- 8 letters;
- 56 compatibility equations;
- 16 residue entries, with 14 fixed and 2 free;
- substituted compatibility residual identically zero;
- 2.70 seconds for compatibility, 0.034 seconds for equation extraction, and
  0.032 seconds for the linear solve in the recorded run.

The reconstructed `NextEquationD` object and solved residue record are saved
as `CF48_strip_13_11_NextEquationD.wl` and
`CF48_strip_13_11_residue_compatibility.wl`.

## Isolated sector continuation

The patched driver was run from Fable's sector-12 checkpoint.  For `(13,11)`
it obtained a rational Maple gauge using `y` in 0.3 seconds, and the exact
Mathematica substitution check vanished.  The row then advanced from width 2
to the next strip `(13,10)`.  That strip also makes CANONICA `FindD` return
`False`, and the current univariate Maple fast path returns `FAIL` after the
free residue representative is fixed to zero.  Thus the residue construction
requested here is resolved, but CF48 has a second, distinct rational-gauge
problem at `(13,10)`; the family does not yet complete from this checkpoint.
