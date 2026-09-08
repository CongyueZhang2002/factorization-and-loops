# Assessment of Fable note 10: path seam approved with two required corrections

Timestamp: 2026-08-30 PDT

Fable,

The record-layer direction is good: port the existing scratch adapter, keep family data in typed records, install after path restriction, and leave the ordinary route unchanged when no exception plan is supplied. Please proceed, but **do not implement the proposed `MasterTransport.wl:4664` insertion literally**. Two mathematical mismatches must be corrected first.

## 1. The exceptional path must define the path of the whole connection

`MasterTransport.wl:4523-4556` currently constructs and admits one of its own axis-aligned paths through `masterTransportPathMatrix`. By line 4664, `ahat`, the basepoint-zero gate, the rationality gate, and the monic/algebraic-letter gate have already been computed for that default path.

The accepted CF303 artifacts do **not** live on that path. Their shared contract is

`/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_u3_common_path_contract.wl`:

```text
a(z) = [4 z (1-z)-6]/[9+4 z (1-z)]
x(z) = -a(z) z
y(z) = [1-a(z)] [1-z]
u = 3
```

Both source coordinates move nonlinearly. Replacing only one subblock of an `ahat` built on the ordinary axis path would combine differential forms pulled back along two different curves and is mathematically wrong.

Required design:

- make the option one typed plan, conceptually

  ```text
  <|"PathContract" -> contract-or-file,
    "Endpoints" -> {z0,z1},
    "Records" -> {exception records...}|>
  ```

- require every record to reference the same path contract, family, hard sector, path variable, and branch convention;
- construct the **entire** path connection from the contract before any path gate:

  ```text
  ztau = z0 + tau (z1-z0)
  ahat = (Av /. source-root-rules /. source-path /. z->ztau) dx/dtau
       + (Aw /. source-root-rules /. source-path /. z->ztau) dy/dtau
  ```

  Apply the declared source-root rules while the source root squares are still in their exact catalog form, then apply the source path.
- install the exceptional path blocks into that common `ahat`;
- only then run the rationality/basepoint/letter-capability gates and the depth/shift analysis.

If the first implementation is intentionally a lower-level API which receives a complete, already path-restricted connection, keep it out of `TransportFamily` for now and state that precondition in the function type. Do not expose a `TransportFamily` option that silently uses its ordinary axis path.

## 2. The current blockwise integrator does not support the real `(25,14)` extension

The phrase “quadratic extension” means degree two over the base field: `r^2=Delta(tau)`. It does **not** imply that `Delta` is a quadratic polynomial in `tau`.

The current algebraic-letter implementation in `BlockwiseTransport.wl:218-267` supports only denominator factors of degree one or two in `tau`; `masterTransportBWLinearize` throws `DenominatorDegreeAboveTwoInTau` for degree three or higher. That machinery handles roots of irreducible quadratic denominator factors. It is not an integrator for arbitrary functions on a quadratic cover.

CF303 `(25,14)` has

```text
r2^2 = (16 z^6 - 104 z^4 + 288 z^3 - 311 z^2
        - 456 z + 576)/(4 z^2 - 4 z - 9)^2,
```

a residual sextic/genus-2 cover. A coefficient `B0 + r2 B1` generally produces hyperelliptic integrals. Feeding it to the existing rational partial-fraction recursion is outside that recursion's proven representation class.

Required split:

1. The package-general record/path installation layer may accept arbitrary exact rational or declared algebraic path forcing.
2. After installation, perform a capability decision:
   - if every required epsilon coefficient is admitted by the existing blockwise decomposition, use `masterTransportBlockwiseSolve`;
   - otherwise return an inert `TransportQuadrature`/typed `AlgebraicQuadratureRequired` representation with the exact variation-of-constants differentiate-back certificate.
3. Do not add a new hyperelliptic integration engine in this small seam.

The toy quadratic test with a linear root square is too weak by itself. Keep it as a unit test, but the actual `(25,14)` artifact must exercise the unsupported-capability branch. It must either return a certified formal quadrature or a typed refusal—never an ordinary blockwise-word success.

For `(25,18)`, test the actual rational denominator factorization before assuming the word backend admits it. If a factor of degree above two remains, it takes the same formal-quadrature branch. Higher powers of admitted linear/quadratic factors are already supported.

## 3. Let the installed mathematics determine regulator depth

Do not separately alter `budget["Need"]` using a trusted record valuation. `masterTransportDepthBudget` at `MasterTransport.wl:2581-2601` already computes the minimum epsilon order of every installed coupling and propagates the demand down the block DAG:

```text
need[j] = Max[need[j], need[i] - rmin[i,j]].
```

Thus a coupling beginning at `eps^-3` automatically asks its source block for three additional orders. Installing before line 4664 is sufficient. A declared record valuation may be checked against the observed `masterTransportEpsOrder` as a fail-closed consistency assertion and reported diagnostically, but must not be added a second time.

## 4. Keep the derivative rule local and minimal

The scratch adapter substitutes `root -> Sqrt[rootSquare(tau)]`. Ordinary `D` already gives `rootSquare'/(2 root)`. Verify that identity in the focused quadratic test, but do not install a global derivative upvalue or a second rewrite rule unless an actual failure demonstrates it is needed. This keeps the seam smaller and avoids two competing derivative conventions.

## 5. Actual file count and default-path test

A new private module also requires registration in `FeynFacet/FeynFacet.m:393-411`; therefore the clean port touches three package files, not two:

1. new `Private/PathTransportException.wl`;
2. `Private/MasterTransport.wl`;
3. `FeynFacet.m` load list.

Load it through the normal package list—never through a mid-run `Get` or loader injection.

For option-absent compatibility, use structural `SameQ` on the small fixture rather than a hash comparison. No hash contributes to this mathematical seam.

## Revised focused acceptance

- common-path contract pulls the complete toy/source connection and the exceptional block along exactly one curve;
- mixed path contracts or branch conventions refuse before assembly;
- endpoint Jacobian is applied exactly once to both ordinary and exceptional blocks;
- negative epsilon valuation is detected from installed `ahat` and propagated once by the existing budget;
- rational toy passes the ordinary blockwise recursion certificate;
- simple quadratic toy verifies the branch derivative and takes blockwise only if its factors are admitted;
- actual CF303 `(25,18)` takes blockwise or formal quadrature according to the real factorization;
- actual CF303 `(25,14)` takes certified formal quadrature / `AlgebraicQuadratureRequired`, not an unsupported word decomposition;
- absent option is `SameQ` to the existing small ordinary result and has negligible measured overhead.

With those corrections, proceed on the record/common-path/formal-quadrature seam. It remains independent of the finite-field solver and does not compete with the active CF259 solve.
