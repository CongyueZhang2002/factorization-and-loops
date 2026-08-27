# SPECIALS_REPORT — classes 79 and 115

Date: 2026-08-14. Agent: specials (lowest seat priority).
Scratch: `/tmp/claude-1000/-home-maxzhang/bea0d1fd-3a94-4522-a5be-62bcb0070578/scratchpad/specials/`

**Headline: class 115 is fully SOLVED and certified. Class 79 is not solved
(Codex owns it) but three concrete, previously-unrecorded findings are delivered.**

**No Wolfram kernel was used at any point.** The single seat was occupied for the
entire session by `hardclasses.wls` (priority 1) and, from ~11:30, by Codex's
`run_quadratic_chart_attempt.wls`. Everything below was done in exact rational
arithmetic with sympy 1.14 in a local venv (`specials/venv`). This means the
planned "CANONICA at degree 0 with a long cap" for class 79 was **not executed**.

---

## A. Class 115 (2x2, rep CF299 rows {1,2}) — SOLVED

### A.1 The structural discovery

The stored matrices satisfy, exactly,

```
Av = M(vw)/v ,    Aw = M(vw)/w
```

with the **same** `M`, depending on `v,w` only through the product `z = vw`, and
`[Av,Aw] = 0`. So this "2-variable 2x2 block" is really a **one-variable** system

```
z dF/dz = M(z) F ,        z = v w .
```

### A.2 It is Gauss hypergeometric

Eliminating `F2 = 2x dF1/dx + (1+4eps) F1` gives, in `x = 4vw`,

```
4x(x-1) F1'' + [(10+12 eps) x + 4 eps - 4] F1' + 2(1+4 eps)(1+eps) F1 = 0
```

i.e. `2F1` with

```
a = 1 + eps ,   b = 1/2 + 2 eps ,   c = 1 - eps ,   argument x = 4 v w
```

Local exponents (independently confirmed as residue eigenvalues of the system):

| locus | exponents |
|---|---|
| `z = 0` | `{0, eps}` |
| `z = 1/4` | `{0, -3/2 - 4 eps}` |
| `z = inf` | `{1+eps, 1/2+2 eps}` |

The `-3/2 - 4 eps` reproduces the recorded CANONICA non-rationality certificate
exactly. At `eps=0` the ODE degenerates to `2F1(1,1/2;1;x) = (1-x)^{-1/2}`, so the
leading order is algebraic — the classic square-root-letter signature.

### A.3 Why no eps-form exists in (v,w), and why CANONICA refused *instantly*

These are two **different** things, and the recorded hypothesis conflated them.

- **No eps-form over Q(v,w)**: the exponent `-3/2` is not an integer, and a
  rational gauge can only shift exponents by integers. Genuine, and permanent.
- **The instant refusal**: *not* the sign, and *not* the non-rationality. Because
  `F` depends only on `z=vw`, in **any** chart whose second variable is a function
  of `z` alone, the first connection matrix vanishes identically. Verified:

```
chart w=(1+t^2)/(4v)  [old]  ->  A_v == 0   (4 zero entries)
chart w=(1-u^2)/(4v)  [new]  ->  A_v == 0   (4 zero entries)
```

  CANONICA was being handed a 2-variable system with a null direction. **The sign
  fix alone would not have helped** — this is the correction to the working
  hypothesis in the task brief.

### A.4 The sign question, settled

The brief asked whether `1-4vw > 0` in the chamber. It does, via the identity

```
1 - 4 v w  ==  (v-w)^2 + (1-v-w)(1+v+w)
```

Both terms are strictly positive for `0<v,w, v+w<1`, so `u = sqrt(1-4vw)` is
**real**, in `(0,1]`. The earlier chart `-1+4vw = t^2` forces `t = i u`, i.e.
**imaginary in the physical chamber** — a real bug for transport and boundary
work, just not the cause of the CANONICA refusal. Use `w = (1-u^2)/(4v)`.

### A.5 The eps-form (the deliverable)

Constructed by three Lee balances between `u=0` and `u=inf` (two-sided
projectors: right-eigenvector at `u=0`, left-eigenvector at `u=inf`), then one
constant transformation. Exponents normalize as

```
u=0: {0,-3-8eps} -> {0,-8eps}      u=+-1: {0,eps}      u=inf: {1+4eps,2+2eps} -> {4eps,2eps}
```

**Canonical basis** (`u = sqrt(1-4vw)`):

```
J1 = u  F1
J2 = ( u^2 F2 - (1+8 eps) F1 ) / eps
```

**Canonical form**:

```
dJ = eps [ N0 dlog(u) + N1 dlog(1-u) + Nm1 dlog(1+u) ] J

N0  = {{-8,0},{0,0}}        eigenvalues {0,-8}
N1  = {{2,1/2},{-4,-1}}     eigenvalues {0,1}
Nm1 = {{2,-1/2},{4,-1}}     eigenvalues {0,1}
N0+N1+Nm1 = -diag(4,2)
```

### A.6 Certificates (all exact, residual identically zero)

1. u-chart: `U^-1 A U - U^-1 dU/du - eps(N0/u + N1/(u-1) + Nm1/(u+1)) = 0`.
2. **(v,w)-chart, both directions**: `U^-1 Av U - U^-1 d_v U - eps(...) = 0`
   and the same for `w`. This is the certificate the engine should check.
3. `det U = eps/u^3` — invertible for `eps != 0`, `u != 0`.
4. `Av = M(vw)/v`, `Aw = M(vw)/w`, `[Av,Aw] = 0`, integrability holds.

### A.7 Consequences for the engine

The alphabet `{u, 1-u, 1+u}` means the eps-expansion is **harmonic
polylogarithms** `H(a1..an; u)` with `a_i` in `{0,1,-1}` — no new function class,
no GPL alphabet extension. Natural boundary point `u=1` (`vw=0`). The all-orders
closed form is also available if preferred as a "closed-form sector":

```
F1 = c1 2F1(1+eps, 1/2+2eps; 1-eps; 4vw) + c2 (4vw)^eps 2F1(1+2eps, 1/2+3eps; 1+eps; 4vw)
F2 = 2 (4vw) dF1/d(4vw) + (1+4 eps) F1
```

Artifact: `specials/class115_epsform.wl`.

---

## B. Class 79 (4x4, rep CF231 rows {1,2,3,4}) — verification + local data only

Per coordinator instruction, no attempt was made to race Codex's derivation.

### B.1 Codex's chart is correct (independent verification)

`w = -t(1+t+v)/(1+t)` gives **exactly**

```
Q  ->  ( (v + (1+t)^2) / (1+t) )^2      =>   sqrt(Q) = (v + (1+t)^2)/(1+t)
```

a perfect square. Confirmed symbolically. Also verified `Q == (1+v+w)^2 - 4w ==
(v+w-1)^2 + 4v`, `disc_w(Q) = -16v`, and that `Q > 0` throughout the physical
chamber (no interior branch point).

### B.2 Local exponent data (the thing Codex asked for)

Pole orders in the stored basis, and residue eigenvalues at the simple poles:

| letter | ord(Av) | ord(Aw) | exponents |
|---|---|---|---|
| `v` | 1 | 1 | `{eps, -1-2eps, -2-2eps, -2-2eps}` |
| `w` | 0 | 1 | — |
| `v+w` | **2** | **2** | undefined — non-Fuchsian, needs Moser reduction |
| `1+v+w` | 1 | 1 | `{0,0,0,-5-6eps}` |
| `Q` | 1 | 1 | `{0,0,0, 1/2+eps}` (rank-1 residue) |
| `L=(3+5eps)(v+w)-3(1+eps)` | 1 | 1 | `{0,0,0,1}` (rank-1, eps-independent) |

*Retraction:* an earlier pass of mine reported `v+w=0` exponents
`{0,0,±(1+4eps/3)}`. Those are **invalid** — the pole there is order 2, so the
simple-pole residue formula does not apply. Discard them.

### B.3 Two defects of the stored basis — the likely cause of the timeouts

**(D1) Non-Fuchsian double pole at `v+w=0`** (order 2 in both `Av` and `Aw`). Any
rational-ansatz canonicalizer asked to reproduce a double pole needs a much
higher ansatz degree — consistent with CANONICA timing out at degrees 0 *and* 1.

**(D2) Apparent eps-dependent singularity at `L = (3+5eps)(v+w) - 3(1+eps) = 0`**,
i.e. the moving locus `v+w = 3(1+eps)/(3+5eps)`. Master integrals cannot have
singular loci that move with eps (Landau loci are eps-independent), so this is
spurious. Evidence: `R_L` is rank 1 with eigenvalues `{0,0,0,1}` — integer and
eps-independent — identical at `w=1/7` and `w=2/5`.

**Explicit removal, verified.** Rank 1 with trace 1 forces `R_L^2 = R_L`, so
`R_L` *is* the spectral projector `P`. The balance

```
T = (1-P) + L P ,      T^-1 = (1-P) + P/L        (exact, no matrix inverse)
```

satisfies `T T^-1 = 1`, `det T ∝ L`, and after `A -> T^-1 A T - T^-1 dT` the
letter `L` **no longer divides any denominator** (pole order 0). Checked at
`(eps,w) = (1/11,1/7), (2/13,2/5), (-3/7,1/3)`.

This is my best guess at what is behind Codex's own note that the CF231_B1 system
is "Fuchsian in `z` but not in `u`".

### B.4 The genuine obstruction, and the recommended order of operations

The `Q=0` exponent `1/2 + eps` is a **half-integer** offset — structurally the
same obstruction as class 115's `-3/2-4eps`, so no eps-form exists over `Q(v,w)`.
Under any rationalizing chart the exponent **doubles to `1+2eps`**: integer part
1, removable by a single balance. So an eps-form should exist in the chart,
provided the basis defects are cleared first:

1. Moser-reduce the `v+w=0` double pole.
2. Balance away `L` (recipe in B.3).
3. Change to Codex's chart (or `v=-m^2`).
4. One balance at the doubled `Q` exponent.
5. *Then* run CANONICA — with an eps-independent alphabet, a low ansatz degree
   becomes plausible for the first time.

### B.5 Not done

No CANONICA run; no 4x4 chart transformation; no eps-form; no reducibility /
invariant-subspace analysis. The (D2) removal is verified at three rational
`(eps,w)` points plus a general structural argument, not as one closed symbolic
identity — sympy could not complete the symbolic 4x4 gauge transformation in
reasonable time.

---

## C. Files

| file | contents |
|---|---|
| `class115_epsform.wl` | class 115: eps-form, canonical basis, 2F1 data, certificates |
| `class79_localdata.wl` | class 79: chart verification, exponents, pole orders, defect diagnosis + removal |
| `c115_stage1..6.py`, `c115_certify.py`, `c115_vw_certify.py` | class 115 derivation + certificates |
| `c79_chart.py`, `c79_targeted.py`, `c79_apparent.py`, `c79_qexp.py`, `c79_poleorders.py`, `c79_removal_check.py`, `tinv.py` | class 79 verification chain |
| `venv/` | sympy 1.14 environment |

## D. Message to Codex

1. Your `CF231_B1` chart `w=-t(1+t+v)/(1+t)` is independently confirmed to
   rationalize the quadratic: `sqrt(Q) = (v+(1+t)^2)/(1+t)`.
2. Before further chart work, please check the two stored-basis defects in B.3.
   The eps-dependent letter `(3+5eps)(v+w)-3(1+eps)` is an apparent singularity
   with exponents `{0,0,0,1}` and I give an explicit rank-1 balance that removes
   it. If your `u`-non-Fuchsianity survives that removal plus a Moser reduction
   at `v+w=0`, then the obstruction is elsewhere and worth reporting.
3. Local exponent data at all simple poles is in B.2; the `Q=0` exponent is
   `1/2+eps`, doubling to `1+2eps` in your chart.
4. Class 115 (`CF299` rows {1,2}) is solved in closed form — it is a one-variable
   `2F1` in `z=vw`, not a genuine 2-variable block. If any of your 173 orbits
   share that connection, they inherit the solution.
