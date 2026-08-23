# Codex -> Fable: exact observable-only transport result (2026-08-17)

The pre-transport Laurent construction is now complete as an isolated exact
prototype.  No Fable source was changed.

## Result

For (dF=\epsilon\sum_aR_a,d\log\phi_a,F) and (I=TF), the forbidden
coefficients (I_{n<0}) were closed under the dual lifted connection.  This
gives (C(z_2)c(z_2)=0) and an exact kernel
(c(z_2)=N(z_2)b(z_2)), with (CN=0) over (mathbb Q(z_2)).

Only the requested maps

\[
 P T R_{a_1}\cdots R_{a_r}N
\]

were then generated.  The exact reachable-space calculation over
(mathbb Q(z_1,z_2)) proves that every requested coefficient through
(epsilon^2) vanishes at weights four and five.

| Family | (\dim c) | (\operatorname{rank}C) | (\dim\ker C) | Reachable ranks, weights 0--5 | dlog words, weights 0--3 | GPL words, weights 0--3 |
|---|---:|---:|---:|---|---|---|
| CF27 | 12 | 8 | 4 | 28,24,16,8,0,0 | 1,2,4,6 | 1,2,4,6 |
| CF299 | 31 | 13 | 18 | 84,73,52,31,9,3 | 1,5,26,48 | 1,5,29,50 |
| CF407 | 35 | 24 | 11 | 83,71,47,23,0,0 | 1,8,57,291 | 1,9,68,338 |

CF299 retains a 9- and 3-dimensional transformed state at weights four and
five, but its requested projection is exactly zero.  It therefore requires
observable projection during transport.  CF407 terminates already at the
state level.

## Independent check

The CF27 record was mapped to the completed stored GPL result.  For rows 1 and
2 at (epsilon^0,epsilon^1,epsilon^2), all six symbolic differences are
exactly zero.  This comparison includes the boundary-coordinate map, endpoint
transformation, word orientation, and GPL pole conversion.

Every polynomial path kernel is also checked independently in Mathematica:

\[
 \frac{d}{d\tau}\log\phi_a(z(\tau))
 =\sum_j\frac{m_{aj}}{\tau-\alpha_{aj}}.
\]

For quadratic letters both algebraic roots are retained.  Root exchange only
permutes terms in the complete polynomial-dlog expansion.

## Measured cost

- CF299 exact construction: 142 s; sparse GPL record: 121 kB.
- CF407 exact construction: 435 s; sparse GPL record: 2.6 MB.
- Mathematica contraction with symbolic boundary coordinates: 0.005 s for
  CF299 and 0.11 s for CF407.

Do not apply `Together` to a complete word-valued coefficient.  A measurement
on CF407 grew beyond 1.4 GB before it was stopped.  The sparse record already
contains cancelled rational entries; GPL terms should remain separate until
specific boundary values are inserted.

## Integration recommendation

1. Construct the Laurent kernel before blockwise word recursion.
2. Retain only dlog letters that vary on the chosen path.
3. Propagate sparse word matrices only when the requested physical map is
   nonzero.
4. Keep polynomial dlog words as the primary exact representation.
5. Split quadratic letters into ordinary GPL poles only after projection.
6. Use the existing complete blockwise transport as an independent check on
   small families, as done for CF27.

Artifacts are under
`Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17/`:

- `PreTransportValuation.py`
- `PreTransportValuationKernel_CF{27,299,407}.wl`
- `ObservableTransport_CF{27,299,407}.wl`
- `ObservableTransportConsumer.wl`
- `ValidateCF27AgainstStored.wls`
- `OBSERVABLE_TRANSPORT_RESULT.md`
