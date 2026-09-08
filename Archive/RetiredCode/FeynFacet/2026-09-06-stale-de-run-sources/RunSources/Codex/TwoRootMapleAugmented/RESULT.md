# CF254 `(9,8)` augmented two-variable Maple test

Date: 2026-08-19

## Result

`IntegrableConnections:-RationalSolutions` is present in the installed Maple
archive and, when it returns, its output is an exact rational function of the
declared variables and parameters. It is not a numerical evaluator.

The documented affine semantics and the augmented-connection construction were
established on a synthetic integrable system by exact substitution into both
PDEs. For the exact CF254 `(9,8)` strip, the 18-dimensional augmented
connection was constructed with all nine free residue parameters and was found
to be exactly flat. The full two-variable calls were

```maple
RationalSolutions([A_x,A_y],[x,y],['param',[eps]])
RationalSolutions([A_y,A_x],[y,x],['param',[eps]])
```

Both calls terminated with an implementation error rather than a rational
basis or `{}`. Direct traces of the first internal ordinary-system stage give

```text
direct_ratsol: calling Mpolsolde :
Mpolsolde: calling good_form :
Error, (in IntegrableConnections:-good_form) numeric exception: division by zero
```

Thus the installed `RationalSolutions` procedure is available and works on the
synthetic exact problem, but it is not useful for deciding this CF254 fixture
in its present build. This result neither constructs a rational gauge nor
proves that no such gauge exists.

This investigation is restricted to the augmented IntegrableConnections
route. It does not run or duplicate the simultaneous finite-field system or
its rational reconstruction.

## Inputs

The following files were read without modification.

| Input | Bytes | SHA-256 |
|---|---:|---|
| `FeynFacet/Private/EpsFormStrip.wl` | 41,345 | `8568b49375e812445e1572f8692997ab7710a53bafdbea38e9b25659ff2063a1` |
| `FeynFacet/Private/TransportCharts.wl` | 16,196 | `5dcac93dfb15dfec8c6e89f7110d39eff3c647143bd4d32ef962ce34fd196361` |
| `Scripts/family_epsform_sector.wls` | 17,309 | `416769e07806fce813fb7d23200878717fb1488904ae132f19c7204b15478a5a` |
| `PRO_REVIEW_REQUEST.md` | 7,583 | `6167efa98fcb4caa2bd58c730801c9a4ac8b96d5ffe3736259f00d0241f4c8cf` |
| `PRO_RESPONSE.md` | 30,097 | `e8e62bc3b65bbd1ed76e326a348027cd54837451c146d6479c7763f210caa357` |
| `two_root_hard_strip_sources.txt` | 963,509 | `0c8230adc2d6e11b112e89f0f5339f26d5a67f593717f0673be42fe2ff30f310` |
| `CF254_9_8_unsolved.wl` | 869,068 | `59d3b2850a4446c6fde153d9f5754fc61481e5ce8eb9703e56fc612d5d2335fb` |

The concatenated source record contains copies whose hashes agree with the
three repository sources and the exact CF254 record above.

## Installed API

The executable is Maple 2026.1 for X86-64 Linux, build 2018217, dated
2026-06-04. The loaded archive is

```text
/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections/IntegrableConnections.mla
```

It has 523,271 bytes and SHA-256
`1edc24de93ad8858fa960cea2e16ea9a42a019cb46fc9c79105c09af8d163abe`.
`exports(IntegrableConnections)` contains both `RationalSolutions` and
`TestIntegrabilityConditions`.

The procedure recovered from the archive with `interface(verboseproc=3)` has
the signature

```maple
RationalSolutions(A::list, x::list, opts::list)
```

and accepts these modes:

```maple
RationalSolutions(A,x)
RationalSolutions(A,x,['param',par])
RationalSolutions(A,x,['rhs',b])
RationalSolutions(A,x,['param',par,'rhs',b])
RationalSolutions(A,x,['rhs',b,'param',par])
```

The `param` declaration matters here: without `['param',[eps]]`, the procedure
classifies symbols other than `x,y` as integration constants when it separates
the first-variable solution family.

No Maple help topic is registered for either `IntegrableConnections` or
`IntegrableConnections[RationalSolutions]`; both help queries return `help ...
not found`. The local XML worksheet `RightHandSideExample.mw` is therefore the
available usage document. Its exact extracted text states that right-hand-side
mode returns `[H,p]`, where the columns of `H` span the homogeneous rational
solutions and `p` is one particular rational solution. A solution is
`H c + p`.

The recovered implementation first invokes `Mratsolde` on the first variable
and then recursively imposes the remaining equations. The main CF254 tests
called the whole-Pfaffian `RationalSolutions` interface. Direct `Mratsolde`
calls were made only after those tests, to identify the internal error.

## Synthetic Test

Consider

```text
A_x = 1/x,                  A_y = 1/y,
p   = eps*x^2 + x + y,
b_x = (eps*x^2-y)/x,        b_y = -x*(eps*x+1)/y.
```

Then `partial_mu p = A_mu p + b_mu`. The exact call

```maple
RationalSolutions([A_x,A_y],[x,y],
    ['param',[eps],'rhs',[b_x,b_y]])
```

returned

```text
H = [x*y],                  p = [eps*x^2+x+y].
```

Every entry of `partial_mu H-A_mu H` and
`partial_mu p-A_mu p-b_mu` simplified exactly to zero for both `mu=x,y`.

For the homogeneous augmentation, let

```text
Y = (u,1,k)^T,
Ahat_x(top row) = (1/x,-y/x,eps*x),
Ahat_y(top row) = (1/y,-x/y,-eps*x^2/y),
```

with zero lower rows. The full two-variable procedure returned

```text
       [ x*y   x+y   eps*x^2 ]
S  =   [  0     1       0    ].
       [  0     0       1    ]
```

Both matrices `partial_x S-Ahat_x S` and
`partial_y S-Ahat_y S` are exactly zero. Relative to the expected basis, the
basis-change matrix is the identity, its determinant is one, and its
derivatives in `x,y` vanish. The second coordinate therefore selects the
affine section, the third retains the residue parameter, and the first column
retains independent homogeneous rational freedom.

## CF254 Connection

Write the exact adjacent-strip equation for the unknown `4 x 2` rational gauge
`R(x,y,eps)` as

```text
partial_mu R = eps*(E_mu R-R C_mu) + f_mu,
f_mu = Bbar_mu-eps*sum_a K_a partial_mu log(l_a),   mu in {x,y}.
```

The existing exact residue calculation gives 928 linear equations and nine
free constants `kappa1,...,kappa9`. The reconstructed source is affine in all
nine constants with an identically zero reconstruction remainder. Every
`kappa_a` has a nonzero coefficient in each of the two PDE sources.

The epsilon-independent dlog alphabet has twelve letters:

```text
x-1, x, 2*x-y-1, y, y+1, 2*x+y-3,
2*x+y-1, 2*x+y+1,
4*x^2-8*x-y^2-2*y-1,
4*x^2-y^2+2*y+3,
2*x*y+6*x+y^2-1,
4*x^2+4*x*y+4*x+y^2-2*y-3.
```

The exact source also retains the epsilon-dependent irreducible divisor

```text
q_eps = -9-11*eps+12*x+24*eps*x+12*x^2+12*eps*x^2
        -6*y-6*eps*y+12*x*y+16*eps*x*y+3*y^2+5*eps*y^2.
```

It occurs squared in the inspected `Bbar` denominators. It was never deleted,
specialized, or sampled.

With row-major vectorization `r=vec(R)`, the eight-dimensional homogeneous
connection is

```text
M_mu = eps*(E_mu tensor I_2-I_4 tensor transpose(C_mu)).
```

Writing `f_mu=f_mu,0+F_mu kappa`, the augmented vector and connection are

```text
Y = (r,1,kappa1,...,kappa9)^T,

       [ M_mu  f_mu,0  F_mu ]
A_mu = [  0       0      0  ].
       [  0       0      0  ]
```

Hence `dim(Y)=8+1+9=18`, rather than the dimension 10 estimated in the review
from a single residue parameter. Exact simplification gave

```text
partial_x A_y-partial_y A_x+A_y A_x-A_x A_y = 0_(18 x 18).
```

The independent Wolfram calculation took 242.000762 s for residue construction
and 56.837833 s for the augmented curvature; total internal time was
817.062949 s. Maple independently returned `"The connection is integrable!"`
in 3.870 s for `(x,y)` and 3.489 s for `(y,x)`.

## CF254 Solver Result

For variable order `(x,y)`, `RationalSolutions` terminated after 98.906 s;
the process wall time was 103.01 s and maximum resident memory was 411,788 KiB.
For `(y,x)`, it terminated after 46.379 s; wall time was 50.11 s and maximum
resident memory was 261,852 KiB.

The package's caught exception object did not carry a useful message. An
uncaught direct trace of its first internal `Mratsolde` stage reached the full
denominator and indicial analysis, including `q_eps`, and then produced the
division-by-zero error quoted above. The corresponding direct traces took
94.841 s for `x` first and 43.046 s for `y` first. Source recovered from the
archive identifies the call chain

```text
RationalSolutions -> Mratsolde -> direct_ratsol -> Mpolsolde
                    -> good_form -> super_form -> ratsuper.
```

The shell exit status is zero for the caught calls because the test script
records the Maple exception and exits normally. The scientific status in both
ledgers is `rationalsolutions_status=ERROR`; no `.result.txt` file exists.

## Exact Acceptance Criterion

A claimed solution requires a returned rational basis `S` satisfying, entry by
entry,

```text
partial_x S-A_x S = 0,      partial_y S-A_y S = 0.
```

It must contain a kinematically constant lower-coordinate combination whose
constant coordinate is exactly one. After reshaping its first eight entries to
`R`, exact substitution must also give, for both variables,

```text
partial_mu R-eps*(E_mu R-R C_mu)-f_mu = 0
```

and the equivalent transformed dlog identity. The verifier implements all of
these symbolic checks before writing an accepted gauge.

Since Maple returned no basis, the verifier result for each order is
`MISSING_MAPLE_RESULT` with exit status 3. The acceptance criterion was not
satisfied. No fixed-kinematics or numerical substitution was used as a
replacement.

## Why the right-hand-side interface does not replace augmentation

The smaller `rhs` interface was tested on the scalar closed system

```text
partial_x r = k1/x + k2,       partial_y r = 0.
```

A rational solution exists precisely on the affine subspace `k1=0`, where
`r=k2*x+constant`. Both calls that left `k1,k2` symbolic returned `{}`:

```maple
RationalSolutions(A,[x,y],['param',[eps],'rhs',b])
RationalSolutions(A,[x,y],['param',[eps,k1,k2],'rhs',b])
```

After imposing `k1=0`, the same interface returned the exact particular
solution `r=k2*x`. Thus the `rhs` interface can solve a specified source, but
it does not determine the linear conditions on unknown source parameters.
The augmented constant coordinates, or an equivalent simultaneous affine
linear solve, are necessary for the residue problem.

## Artifacts

All generated material is confined to this directory. `FILES_CREATED.tsv`
lists every created file with its byte count and SHA-256 digest.
