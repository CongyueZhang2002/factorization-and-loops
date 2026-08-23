# CF231 `(8,7)` rational extension

## Differential system

In the Kallen23 chart with coordinates `(y,s)`, the adjacent blocks obey

```text
d J8 = epsilon E J8 + Bbar J7,
d J7 = epsilon C J7,
```

where `E`, `C`, and `Bbar` are pairs of exact `4 x 4` rational matrices. A
rational matrix `R(epsilon,y,s)` must satisfy

```text
partial_mu R - epsilon (E_mu R - R C_mu)
  = Bbar_mu - epsilon Sum_a K_a partial_mu log(W_a),  mu = y,s.
```

The `K_a` are constant in `(y,s)` but may be rational functions of epsilon.
The 13 letters `W_a` are those in the exact audit record.

## Constant-dlog compatibility

Before solving for `R`, the right-hand side must be closed under the induced
connection on `Hom(J7,J8)`. Since the original strip is flat, the unknown
part is the homogeneous linear identity

```text
Sum_a [
  dlog_s(W_a) (E_y K_a - K_a C_y)
  - dlog_y(W_a) (E_s K_a - K_a C_s)
] = 0.
```

There are `13 x 4 x 4 = 208` rational unknowns. Evaluation at generic points
over two different prime fields gives rank 191 in both cases. An independent
set of 191 rows was then evaluated over the rationals; its exact nullspace has
dimension 17. Substitution of every nullspace vector into the complete
rational identity gives zero entrywise. Therefore the exact residue space is
17-dimensional and the reconstructed basis is complete.

## Local pole bounds

Let an irreducible divisor `q=0` have forcing order `m`, and write the
diagonal connections locally as

```text
E = E_q dlog(q) + regular,
C = C_q dlog(q) + regular.
```

For a candidate gauge term `q^(-k) R_k`, the highest normal pole is governed
by

```text
(k Identity + epsilon (E_q # - # C_q)) R_k.
```

Its determinant has nonzero constant term `k^16` at epsilon zero. Hence it is
invertible for generic epsilon and the gauge pole order is at most `m-1`.
For CF231 the exact orders are

```text
divisor        f3  f4  f6  f8  f10  qeps
forcing order   2   2   2   3    2     2
gauge order     1   1   1   2    1     1
```

The mixed divisor `qeps(y,s,epsilon)` is retained. Its leading-pole operator
has determinant one, so its apparent double pole in the forcing requires at
most a simple pole in `R` and must disappear from the final dlog system.

The common gauge denominator has bidegree `(6,10)`. The forcing grows as
`y^0` in the y equation and as `s^(-1)` in the s equation, which bounds the
gauge growth by `(1,0)`. Thus the numerator bidegree is at most `(7,10)`.

## Simultaneous gauge system

Each of the 16 matrix entries has 88 numerator monomials, giving 1408 gauge
coefficients. Adding the 17 residue coordinates gives 1425 unknowns. Fifty
generic chart points provide 1600 equations over each prime field. At

```text
(epsilon, prime) = (1/7, 1000003),
                   (2/9, 1000033),
                   (-3/11, 1000037),
```

the coefficient and augmented matrices both have rank 1409. The affine system
is therefore consistent at all three independent samples and has a
16-dimensional homogeneous space. At the first point, `LinearSolve` and
`NullSpace` reproduce this result and their residuals vanish modulo the prime.

## Epsilon reconstruction and exact closure

The 16 homogeneous directions are fixed by setting the independent residue
coordinates 1409 through 1424 to zero. The resulting affine vector has 1425
coordinates. Each coordinate is reconstructed over a prime field as a reduced
rational function of `epsilon`. Twenty epsilon values determine the function
and eight further values test it. The degree census is identical in all ten
prime fields, and no coordinate is unresolved.

Chinese remaindering followed by rational reconstruction requires ten 31-bit
primes. Reconstructions from six through nine primes fail exact substitution
into the original PDEs; the ten-prime reconstruction satisfies it. The final
modulus is

```text
2085923794610875369776750139383320387986754400640138955555557254976418353002205521810353434403.
```

The reconstructed residue coordinates are

```text
rho[1] = ... = rho[16] = 0,
rho[17] = -746123874557 /
  (28786734537662830815129519000 epsilon (1+epsilon)^2
   (3+23 epsilon+54 epsilon^2+40 epsilon^3)).
```

Three exact rational chart points are checked before symbolic work. After
those checks vanish, the 32 entries

```text
partial_mu R - epsilon (E_mu R - R C_mu)
  - Bbar_mu + epsilon Sum_a K_a partial_mu log(W_a),
```

for `mu=y,s` are reduced exactly. Every numerator is zero. The complete
symbolic closure took 9.43 seconds with four independent entry calculations
running concurrently. This establishes the rational gauge and the constant
dlog residues for the CF231 `(8,7)` extension.
