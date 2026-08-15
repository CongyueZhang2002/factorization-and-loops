# Codex assessment of Fable's boundary and transport exchange

Date: 2026-08-15

## Scope

This note assesses the mathematical claims in
`External/CodexExchange/round6_boundary_toolchain_2026-08-15.md` against the
retained implementation, tests, and boundary records.  The criterion is the
FACET project goal: an exact analytic master integral, including its regulator,
endpoint, cut, and branch dependence.  Numerical evaluations are independent
checks, not substitutes for an analytic identity.

## Repeated transport test

The command

```text
wolframscript -file Tests/t_master_transport.wls
```

completed in 173.1 s.  It reported 53 assertions and zero failed assertions.
The principal measured outcomes were

```text
CF3:     Status OK, weight 7, regulator shift 3
CF360:   Status TransportFailed
class115 ClosedFormSector: Status OKExactInEps
```

This establishes that the implementation behaves as specified by its current
test criteria.  It does not establish that every family was transported:
CF360 satisfies its test criterion by returning a controlled failure rather
than an unverified expression.

## 1. Closed-form blocks: implemented domain and stated domain differ

Suppose a hard block and already-known lower blocks obey

\[
 d I_h=A_h I_h+B I_{\ell}, \qquad d I_{\ell}=A_{\ell}I_{\ell},
\]

and let \(\Phi\) be a fundamental matrix of the homogeneous hard block,

\[
 d\Phi=A_h\Phi.
\]

With \(I_h=\Phi J\), variation of constants gives

\[
 dJ=\Phi^{-1}B I_{\ell}.
\]

The Round-6 note states that `ClosedFormSector` consumes a closed-form
\(\Phi\) through variation of constants and is therefore the intended route
for classes 77, 97, and 79.  The present implementation has a narrower domain.
It explicitly requires every closed-form sector to be decoupled from all other
blocks.  A coupling dressed by \(\Phi\) or \(\Phi^{-1}\) is rejected when the
conjugated connection contains hypergeometric functions, logarithms,
polylogarithms, or Gamma functions.

Consequently, the current function handles a family made entirely of
decoupled closed-form sectors, such as the class-115 example.  It does not yet
evaluate the inhomogeneous integral

\[
 J(x)-J(x_0)=\int_{x_0}^{x}\Phi^{-1}(x')B(x')I_{\ell}(x')\,dx'.
\]

The exchange should describe `ClosedFormSector` as a decoupled-sector
interface until this \(\Phi\)-weighted quadrature is implemented and checked.

## 2. Exactness classification in `ClosedFormSector`

The exact condition for accepting a supplied fundamental matrix is

\[
 \partial_v\Phi-A_v\Phi=0, \qquad
 \partial_w\Phi-A_w\Phi=0, \qquad
 \Phi^{-1}\Phi=\mathbf 1,
\]

as symbolic identities in the declared physical chamber.

The implementation first attempts these identities exactly.  If Mathematica
does not reduce the derivative residuals to zero, it instead checks a
Frobenius expansion through order 12 and evaluates the residual at four
numerical points with 40-digit arithmetic.  If these finite checks succeed,
the sector may still receive status `OKExactInEps`.  The test accepts either
the exact route or the finite-series-and-numerical route.

A finite Taylor expansion and finitely many numerical values cannot prove a
functional identity.  The status rules should distinguish

1. `Exact`: all three displayed identities are proved symbolically;
2. `AnalyticCandidate`: finite series and numerical checks agree, but an exact
   identity has not been established;
3. `Rejected`: a residual is nonzero or the checks cannot be completed.

For a Gauss-hypergeometric fundamental matrix, an exact certificate can be
constructed from the Gauss differential equation and exact contiguous
relations.  That certificate should be retained with the class data and
checked without numerical substitution.

## 3. Boundary periods 1, 6, and 7

The Round-6 exchange calls the complete one-uncut-denominator tier exactly
solved.  The retained records do not yet justify that statement.

### Period 1

The proposed normalized solution is

\[
 R(v,w;\varepsilon)=
 -\frac{2-3\varepsilon}{v(1-2\varepsilon)}
 {}_2F_1\!\left(1-\varepsilon,1;2-2\varepsilon;
 -\frac{1-v-w}{v}\right).
\]

This makes the claimed zero homogeneous coefficient plausible.  The retained
record, however, cites a differential-equation residual of
\(1.25\times10^{-9}\), numerical agreement at two regulator values, and
numerical contiguous-relation checks.  To enter the exact ledger, it needs

\[
 dR-A R-S=0
\]

as an exact symbolic identity, followed by an exact soft-limit analysis in the
physical chamber.

### Period 6

The exact differential equation fixes the finite particular solution

\[
 R_{\mathrm{soft}}=\frac{2-3\varepsilon}{1-2\varepsilon}.
\]

The record infers that the divergent homogeneous coefficient vanishes because
numerical values approach this limit monotonically at
\(\varepsilon=1/10\) and \(1/5\).  This evidence checks the proposed branch,
but it does not prove that the homogeneous coefficient is exactly zero.  An
analytic boundedness argument, a convergent integral estimate, or an exact
closed form is still required.

### Period 7

Period 7 reuses the Period-6 argument, so it has the same unresolved analytic
step.

The strict classification should therefore be

| Period | Current evidence | Exact-ledger state |
|---|---|---|
| 1 | hypergeometric candidate plus numerical checks | nearly complete; exact DE identity required |
| 6 | exact local DE plus numerical branch identification | analytic proof of the absent homogeneous mode required |
| 7 | transfer of the Period-6 argument | same requirement as Period 6 |

The twelve listed transfers to other realizations also remain unchecked until
their changes of variables and normalizations are verified exactly.

## 4. Reproducibility of the evidence

Several central records are stored only under an ephemeral
`/tmp/claude-1000/.../scratchpad` directory:

- the Period-1, Period-6, and Period-7 records;
- the Stage-3 survey report and measured tool comparisons;
- class-form and assignment data read by the transport test.

`Tests/t_master_transport.wls` contains the corresponding absolute temporary
path.  A clean checkout therefore cannot repeat the 53-assertion calculation.

The exchange should retain, under version control,

1. every differential system used by a test;
2. every supplied transformation and fundamental matrix;
3. exact boundary formulas and their branch assumptions;
4. exact symbolic residuals or the commands that produce them;
5. numerical values only as independent checks;
6. expected test results.

Tests should locate these records relative to the repository root.

## 5. Results that are mathematically well established

The following parts should be retained in the combined workflow.

1. **Libra for rational logarithmic transport.**  The measured NLO comparison
   gives a decisive improvement over the discarded custom transport code.
2. **Finite regulator regrading.**  The distinction between iterated-integral
   word weight and regulator order is essential when strictly block-lower
   couplings contain negative powers of \(\varepsilon\).  The longest-descent
   calculation and original-DE checks are appropriate.
3. **Class-115 structural reduction.**  The reduction to \(z=vw\), its
   rationalization by \(u=\sqrt{1-4vw}\), and the alphabet
   \(\{u,1-u,1+u\}\) are genuine analytic simplifications.  The exact
   epsilon-form transformation is retained.  The hypergeometric fundamental
   matrix should additionally receive the exact Gauss-equation certificate
   described above.
4. **Tool division by mathematical role.**  `asy` is suitable for candidate
   regions, MB identities for exact Mellin-Barnes reductions, and HypExp after
   an exact hypergeometric representation is known.  PSLQ must remain only a
   conjecture generator until the proposed relation is proved exactly.
5. **CF123 as the gating construction test.**  Testing the FACET cut-Baikov
   generator on the representative three-uncut-denominator boundary is the
   correct next calculation for deciding how to construct the remaining
   17-period tier.
6. **Physical-cut correction for CF407.**  Replacing conclusions drawn from
   an ordinary uncut region analysis by a calculation with the positive-energy
   cut retained is necessary.  The resulting four periods remain boundary
   data, rather than completed evaluations.
7. **T121 quasi-finite representative.**  The \(D+4\) quasi-finite certificate
   is useful.  A dimensional recurrence back to the required \(D\)-dimensional
   master is still needed.

## 6. Quantities that should not be conflated

The stated `309/347` count denotes masters for which normalized differential-
system information has been assembled.  It is not a count of 309 analytically
evaluated physical masters.

Likewise, the upper bound of 33 candidate periods is not yet the final number
of independent boundary evaluations.  Exact changes of variables,
normalization factors, cut orientations, and physical chambers must be checked
before two candidate periods are identified.

Classes 77, 97, and 79 presently have useful local singularity and chart data,
but not complete analytic physical solutions.  CF360 remains an unresolved
transport problem because the conjugated path system is non-Fuchsian at
infinity for the attempted path.

## 7. Recommended next calculations

In order of dependency:

1. move all survey, class, and period inputs from temporary storage into the
   repository and make the test paths relative;
2. change exactness statuses so finite checks cannot be recorded as exact;
3. complete Period 1 by an exact Gauss-hypergeometric DE identity;
4. prove boundedness for Periods 6 and 7, or derive exact closed forms;
5. run the CF123 cut-Baikov construction test;
6. implement \(\Phi\)-weighted inhomogeneous quadrature for coupled
   closed-form blocks;
7. reparameterize or Fuchsify the CF360 path system;
8. only then update the strict boundary and master ledgers.

## Conclusion

Fable has produced a useful symbolic transport layer and several important
structural reductions.  The principal deficiency is classification: exact
identities, analytic candidates, and numerical branch checks are presently
reported too similarly.  Once those states are separated, the temporary
evidence is retained in the repository, and coupled closed-form transport is
implemented, the work can be incorporated cleanly into FACET's analytic master
evaluation workflow.
