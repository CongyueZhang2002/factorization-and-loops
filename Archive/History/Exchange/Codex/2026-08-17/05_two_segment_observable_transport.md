# Exact observable-only two-segment transport for CF299 and CF407

Codex, 2026-08-17 evening PDT.

## Result

The observable-only construction now covers the full two-segment path, not
only the first segment.  Write the canonical family equation as

\[
 dF=\varepsilon\left(A_p\,dp+A_u\,du\right)F,
\]

and let \(X\) denote the finite Laurent lift needed for the requested physical
coefficients.  The pre-transport valuation constraints define an exact
invariant subspace

\[
 X(p_0,u)=N(u)b(u).
\]

The induced spectator equation was obtained from

\[
 N'(u)+N(u)B(u)=A_u^{\mathrm{lift}}(p_0,u)N(u).
\]

For both hard families, the residual of this identity is identically zero.
The physical first-path maps \(M_\alpha(p,u)\) are then composed only with the
constant matrices \(K_a\) in

\[
 B(u)=\sum_a k_a(u)K_a.
\]

Thus the physical answer is represented directly by matrices

\[
 M_\alpha K_{a_1}\cdots K_{a_s},
 \qquad |\alpha|+s\leq 3,
\]

multiplied by the corresponding first-path and spectator-path iterated
integrals.  No undemanded row or column of the full fundamental matrix is
transported.

### CF299

- Induced Laurent system: \(84\times84\), 398 nonzero entries.
- Spectator kernels: 5.
- First-path physical maps by weight: \(\{1,5,26,48\}\).
- Complete two-segment maps by total weight: \(\{1,9,67,172\}\).
- Total: 249 sparse maps, 139 kB in the Python record and 131 kB in the
  Wolfram-generated record.
- Physical contributions at total weights 4 and 5 vanish exactly.

### CF407

- Induced Laurent system: \(83\times83\), 475 nonzero entries.
- Spectator kernels: 9.
- First-path physical maps by weight: \(\{1,8,57,291\}\).
- Complete two-segment maps by total weight: \(\{1,16,164,1006\}\).
- Total: 1,187 sparse maps and 2.6 MB.
- Physical contributions at total weights 4 and 5 vanish exactly.

The Wolfram composition takes about 13 s and 112 MB for CF407.  This replaces
the full 17-block word closure that was multiplying by roughly five or six per
epsilon order.

## Exact checks

1. The induced-subspace identity above is zero entry by entry.
2. The spectator connections reconstruct exactly from their listed kernels
   and constant matrices.
3. CF27 and CF299 were generated independently in Python and Wolfram.  Their
   word keys and every rational matrix entry agree exactly: 41/41 maps for
   CF27 and 249/249 maps for CF299.
4. For CF407, all 357 maps with an empty spectator word agree exactly with the
   certified first-path maps.
5. All 1,187 CF407 maps satisfy

   \[
   M_{\alpha;\beta a}=M_{\alpha;\beta}K_a
   \]

   entry by entry.

## Files

The records are in
`Codex/ppHX_NNLO_DoubleReal/TransportProjection_2026-08-17/`:

- `SpectatorSystem_CF299.wl`
- `SpectatorSystem_CF407.wl`
- `TwoSegmentObservableTransport_CF299_Wolfram.wl`
- `TwoSegmentObservableTransport_CF407.wl`
- `ComposeTwoSegment.wls`
- `ValidateTwoSegmentRecurrence.wls`

The spectator records now include the Laurent-coordinate embedding \(N(u)\),
which is needed for matching to endpoint periods.

## Important correction

An intermediate experiment computed row ranks over
\(\mathbb{Q}(p,u)\).  Such a rank measures rational functional dependence of
the output rows at generic kinematics.  It is **not** the number of constant
endpoint periods: for example, a row \(a(u)e_1+b(u)e_2\) has rank one over
\(\mathbb{Q}(u)\) but can depend on two independent constants.  Do not use the
previously quoted CF299 rank 28 as a boundary-period count.

The next step is endpoint matching: put the induced system into its local
Frobenius form at \(u=0\), map the regularized local constants through the
stored embedding \(N(u)\), and identify them with the existing period
certificates.  The transport itself no longer requires the full-column word
closure.
