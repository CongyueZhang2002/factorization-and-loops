<!-- Migrated into version control 2026-08-15 (stage-3 rework), from the
     ephemeral scratch path stage3_survey/SURVEY_REPORT.md, per section 4 of
     Exchange/Codex/2026-08-15/02_assessment_of_fable_round6.md.

     Placed in Design/ rather than Exchange/ because Exchange/ holds
     documents exchanged WITH Codex and Fable, whereas
     this is our own measured evidence, and it is the cited decision basis
     for Design/Stage3BoundaryToolchain.md -- the normative doc it backs.
     Keeping evidence next to the design decision it justifies is the
     consistent rule applied here. -->

# Stage-3 package survey — which boundary-solving steps are already solved by existing packages

**Question decided here:** before any period is solved by hand, which steps of
boundary-solving are greatly simplified by EXISTING packages, and which are not.
Measured with probes against certified ground truth, in the style of
`pkg_benchmark/BENCHMARK_REPORT.md`.

Date: 2026-08-15. Timebox: 5 h active. Wolfram 14.2.1, 20 processors, 2-seat licence.
Codex idle throughout (no writes under `~/FACET` during the session); never more
than 2 kernels ours, mostly 1. Nothing was written under `/home/maxzhang/FACET`.
Nothing was installed into the repo `Addon`.

---

## 0. Headline

| step | package | verdict |
|---|---|---|
| **S1** region identification at ordered limits | **asy 2.1** | **ADOPT** — reproduced the certified region structure; the load-bearing step of the `period = 0` argument is now mechanical |
| **S2-A** period evaluation by MB (control) | **MB.m + barnesroutines** | **ADOPT** — reproduced the certified closed form exactly and the certified series to ~12 digits/order |
| **S2-B** period evaluation by MB (the 17-tier) | AMBRE | **REJECT for this role** — see §3. **The 5-variable build is NOT obsolete.** |
| **S3** pFq eps-expansion | **HypExp 2.0** | **ADOPT** — certified soft limit exact through `eps^4`; symbolic-argument 2F1 to `eps^4` in 0.037 s |
| **S4** high-precision numerics + integer relations | SubTropica + `FindIntegerNullVector` | **ADOPT WITH A MANDATORY GUARD** — the recogniser never fails, so exact certification is not optional |
| **S5** inventory | pySecDec/FIESTA, MZV mine, PolyLogTools, HyperInt | §6 |

**The S2-B answer, stated explicitly as required: the planned 5-variable
parametrization build is NOT made obsolete by Mellin-Barnes.** MB *consumes* a
parametric representation; it does not *produce* one for a cut phase-space
integral. AMBRE — the tool whose entire job is producing MB representations —
has no notion of a cut, a delta function, or a phase space. See §3 for the
measurement and for the one route that might still obsolete the build (Baikov),
which I did **not** test and therefore do not claim.

---

## 1. Provenance of everything fetched (scratch only)

All under `stage3_survey/pkgs/`. Nothing entered the repo `Addon`.

| package | source URL | SHA-256 (as fetched) |
|---|---|---|
| MB 1.2 | `https://mbtools.hepforge.org/downloads/MB-1.2.tar.gz` | `a8a34676…907d` |
| MBresolve 1.0 | `…/downloads/MBresolve-1.0.tar.gz` | `57201e1f…7463` |
| MBasymptotics 1.0 | `…/downloads/MBasymptotics-1.0.tar.gz` | `37c24bad…21d2` |
| barnesroutines 1.0 | `…/downloads/barnesroutines-1.0.tar.gz` | `b8f6e1d4…a6b0` |
| AMBRE 1.2 | `…/downloads/AMBRE-1.2.tar.gz` | `f080b032…f636` |
| HypExp 2.0 (bundles HPL 2) | `https://www.physik.uzh.ch/data/HypExp/HypExp-2.0.tar.gz` | `d6275525…9a60` |
| **asy 2.1** | **`https://raw.githubusercontent.com/ndeutschmann/RER/master/asy2.1.m`** | `013b4acb…727a` |
| qhull 2020.2 (asy dependency) | `http://www.qhull.org/download/qhull-2020-src-8.0.2.tgz` | `b5c2d7eb…8b7e` |

**Provenance caveat on asy, stated plainly.** The canonical KIT page
(`ttp.kit.edu/Progdata/ttp14/ttp14-045/`) serves only a rendered wiki page; I
could not obtain a raw file from it, and `theory.sinp.msu.ru` 404s. The copy
used is therefore a **third-party GitHub mirror** (the `RER` project, which
describes itself as "based on A. Smirnov's asy.m and UF.m"). The file
self-identifies as `ASYVERSION="Asy2.1"` and behaves correctly on a textbook
control (§2), but **it is a mirror, not the upstream distribution**, and should
be replaced with an upstream copy before anything is registered on its output.

Note also `mbtools.hepforge.org` requires the `/downloads/<file>` path; the URLs
printed on the project page (`hepforge.org/downloads/mbtools/…`) silently return
an HTML page with HTTP 200, which `curl -O` will happily save as a `.tar.gz`.
Two of my first fetches were HTML masquerading as tarballs.

---

## 2. S1 — region identification at ordered limits (asy 2.1): **PASS**

### 2.1 Setup cost, honestly

| item | cost |
|---|---|
| locate a live asy source (KIT dead, MSU dead, mirror found) | ~25 min |
| build qhull from source (`qhull-bin` not installed, no sudo; top-level `make qhull` has no such target; `bin/` and `lib/` must be created by hand or `ar` fails) | ~15 min |
| point asy's `QHull` at the built binary, verify `Fv` output format | ~5 min |
| **total** | **~45 min** |

asy 2.1 itself loads in **0.0013 s**.

### 2.2 The probe, and the certified truth it had to reproduce

PeriodID 1's integral (PILOT §2):

```
T = Int_0^1 Int_0^1 dX dY  X^(1-2eps) (1-X)^(-eps) (Y(1-Y))^(-eps) / J
J = v(1 - X Y) + X s (1 - Y)
```

The certified determination that the period **is exactly 0** rests on PILOT
§3.2 argument 1: as `s -> 0` the only degeneration is the corner `X = Y = 1`,
where `J ~ v u + (v+s) t`; the `s`-dependence merely shifts a coefficient and
**introduces no second scaling region**, so there is no `s^(2eps-1)` branch and
the period vanishes. That "exactly one region" statement is the whole analytic
content, and it was done by hand.

Substituting `u1 = 1-X`, `u2 = 1-Y` puts the corner at the origin, where a
Newton-polytope region finder looks:
`J = v u1 + (v+s) u2 - (v+s) u1 u2` (substitution verified in-script, `True`).

### 2.3 Results

| probe | result | expected |
|---|---|---|
| **TARGET** `WilsonExpand[J, 1, {u1,u2}, {sp -> x sp}]` | **`{{0,0}}` — one region**, leading `F -> u1 v + u2 v - u1 u2 v` | **one region** ✓ |
| same via `PExpand[…, IntegralDim->2]` | `{{0,0}}` | ✓ |
| control A: 1-loop propagator, small mass | **`{{0,0},{0,1}}` — 2 regions** | textbook hard + small-mass ✓ |
| control B (negative): no small parameter | `{}` | ✓ |
| positive control P1: `sp` as standalone term | **`{{0,0},{1,1}}` — 2 regions** | ≥2 ✓ |
| positive control P2: `sp*u2^2` | **`{{0,-1},{0,0}}` — 2 regions** | ≥2 ✓ |

**This is a genuine pass, not a gate artefact.** The target passes asy's own
rank gate (`IntegralDim == PRank-1`, i.e. `2 == 3-1`), so the full geometric
algorithm ran — a real 3-D convex hull plus the bottom-facet filter — and
returned one region, while two structurally similar perturbations of the *same*
polynomial in the *same* variables returned two. The finder discriminates.

### 2.4 The honest limit: the chart is hand-work, and it is load-bearing

Feeding the *naive* chart (variables scaling from `X, Y -> 0` rather than from
the corner `X = Y = 1`) returns `{{-1,1}}` — a different and, for our purpose,
wrong answer. asy finds regions **at the origin of the variables you hand it**.
Knowing that the degeneration sits at `X=Y=1` is exactly the local analysis our
counter currently does by hand, and asy does not do it.

**Score against the question asked ("does it mechanize what our counter/local
analysis currently does by hand?"): it mechanizes the *polytope* half, not the
*chart* half.** Given the chart, the region count — and hence the
`period = 0` conclusion — is now a 1-second mechanical check instead of a
by-hand power-counting argument. That is a real and repeatable saving across
the 17-tier, where the same argument would otherwise be made 17 more times.

### 2.5 Traps recorded

| # | trap | signature |
|---|---|---|
| A1 | **asy is not a package.** It dumps ~200 symbols into `Global\``, including `F, U, x, y, s, a, b, c, n, i, j, dim, delta, Delta, Vector, Matrix, Scalar, Prod`. Our own `x, y, s` are exactly the PILOT's variable names. | silent capture of physics variables |
| A2 | **asy's small parameter is the bare symbol `x`**, while its alpha parameters are `x[i]`. Any script using `x` as a physics variable is broken before it starts. | regions computed w.r.t. the wrong scale |
| A3 | `UF` declares vectors as `Union[Variables[LHS of cs], ks]`. An external momentum that appears in no `cs` rule stays a **scalar**, and UF aborts with `Error in revealing vectors`. Passing `cs = {}` is fatal. | `-2*p*Vector[k]` residue, then `Abort[]` |
| A4 | **asy calls `Abort[]` on internal errors**, which kills the entire script, not just the probe. Every call needs `CheckAbort`. My first S1 run died at control A and produced nothing. | `$Aborted`, no output |
| A5 | `PExpand` silently returns `{}` ("scaleless") whenever `IntegralDim != PRank-1`. Degenerate 2-point polytopes also make qhull fail with `dimension 1 … should be at least 2`. An empty result means "gate not satisfied", **not** "no regions". | `{}` misread as a physics answer |

A5 is the dangerous one: `{}` is both the negative-control answer and the
gate-refusal answer. My first four calibration polynomials returned `{}` for the
*gate* reason and I nearly recorded them as failures of the finder.

---

## 3. S2 — period evaluation via Mellin-Barnes

### 3.1 S2-A (control, PeriodID 1): **PASS**

**The MB representation had to be derived by hand.** I did it in ~20 min:

```
1 - X Y  =  (1-X) + X(1-Y)          both non-negative on the unit square
  =>  J  =  v(1-X) + (v+s) X (1-Y)   a two-term split, fit for MB
split 1/(A+B) = 1/(2 pi i) Int dz Gamma[-z]Gamma[1+z] B^z A^(-1-z)
both parametric integrals are then Beta functions, and Gamma[2-2eps+z]
CANCELS between them, leaving a ONE-FOLD MB integral:

  T = (1/v) Gamma[1-eps]/Gamma[2-3eps]
        * (1/2 pi i) Int dz Gamma[-z]Gamma[1+z]Gamma[-eps-z]Gamma[1-eps+z] r^z
      r = (v+s)/v        (r = 3 at v=w=1/4; r = 1 is the soft density)
```

| check | result |
|---|---|
| ground truth reproduces PILOT's own quoted series `1 + 5eps + (38-Pi^2)/2 eps^2` | **True** |
| ground truth reproduces PILOT's `T` at `eps^0` | **`Log[9]`**, exact |
| **`barnesroutines` closes the `r=1` integral automatically** | `Barnes1[MBint[…], z]` returned `Gamma[1-2eps]Gamma[1-eps]^2/Gamma[2-2eps]` **with the z-integration list emptied** — the lemma fired |
| the resulting closed form vs the certified closed form | **exactly equal** (`FullSimplify` and `FunctionExpand` both close it to `0`) |
| MB.m numeric pipeline (`MBcontinue`→`MBexpand`→`MBintegrate`) on `T`, `r=3` | ran in seconds, no residues crossed |
| `T` at `eps^0` | 2.19722457733682 vs certified 2.19722457733621938 → **12.6 digits** |
| `T` at `eps^1` | 11.13171023875585 vs certified 11.13171023873080 → **11.6 digits** |
| `T` at `eps^2` | 31.73564841871514 vs certified 31.73564841867119 → **11.9 digits** |

The certified `eps^1` and `eps^2` values reproduce PILOT §5's table digit for
digit, so this harness is anchored to the certified numbers, not to itself.

**Digit metric was calibrated** (identical → `Indeterminate`, which per PILOT §3
is the significance-arithmetic signature of agreement below comparison
precision; `1e-20` → 20.0; `1e-5` → 5.0; non-numeric → `$Failed`).

**Two faults, both mine:** I first called `Barnes1[integrand, z]` on a bare
integrand — it requires an `MBint[...]` object, so it returned unevaluated and I
briefly recorded the package as not firing. And `Simplify` alone does **not**
close my Barnes form against the certified form; `FullSimplify` does. Reported
as a **simplifier failure, never as a disagreement** — the same call PILOT §3
had to make.

**Verdict S2-A: ADOPT.** For a period whose parametric integrand is already in
hand and whose denominators split into two non-negative pieces, the MB route is
excellent: exact closed form automatically via Barnes, ~12 digits/order
numerically with no tuning.

### 3.2 S2-B (the money question, CF123): **MB does not reach it**

**Target selection.** From `NullityPeriods.wl` and PILOT §10.1, the simplest
members of the 17-tier are **PeriodIDs 2 and 3 (CF123)** — 3 uncut denominators,
3 driving masters, the least of any unresolved period.

**I re-derived the topology from the Kira config rather than trusting the
summary**, and it confirms PILOT §14 exactly. `CF123/config/integralfamilies.yaml`:
`loop_momenta [ke,kf]`, `cut_propagators [1,2,7]`, and for the period master
`gli[CF123,{1,1,1,1,0,1,1,0,0}]` the three uncut denominators are

```
#3  (kf - ka)^2                 -> -2 ka.kf
#4  (ke + kf - ka)^2            -> -w - 2 kg.(kb-kc)   [ke+kf-ka = kb-kc-kg]
#6  (ke - ka - kb + kc)^2       -> (ke - P)^2 = s(1 - x_e)
```

`#6` depends only on an energy. `#3` and `#4` carry angular dependence against
**two different reference directions** (`ka`, and `kb-kc`). Two energies plus two
orientation angles: the 4-fold parametrization PILOT §14 describes, and the
reason the 2-variable `(X,Y)` chart that solved PIDs 1/6/7 cannot close it.

**The measurement.**

| question | answer |
|---|---|
| Does MB.m build representations? | **No.** MB.m analyses an MB integral that already exists: contours, continuation, expansion, integration. Every function takes an integrand. |
| Does AMBRE build representations for this? | **No.** Its only input interface is `Fullintegral[{numerator},{propagators},{internal momenta}]` — an **uncut** loop integral. |
| Does AMBRE have any notion of a cut? | **No.** A grep of `AMBRE.m` for `cut`, `delta`, `DiracDelta`, `phase.space`, `on-shell` returns **zero genuine hits** (the two `cut` matches are substrings of "exe**cut**ed" and "a**c**tivates"). |
| Is AMBRE 1.2 otherwise adequate? | Separately limited: 1.2 is the planar one-/two-loop version; non-planar needs AMBRE 2/3, which I did not fetch. |

**So: the 5-variable parametrization build is NOT obsoleted by Mellin-Barnes.**
Stated as the directive requires. MB is a consumer of parametric
representations. For PID 1 the representation existed (PILOT §2 built it by
hand); for CF123 it does not, and no MB-family package will produce it.

**The one route that might still obsolete the build — and which I did not test.**
The representation problem for *cut* integrals is mechanised, but by **Baikov**,
not by MB. Codex's tree carries

```
FeynFacet/Private/MasterBoundaryBaikov.wl
  BuildStandardBaikovDataFromTopology[topology_FeynCalc`FCTopology]
  BuildBaikovCutBoundaryIntegralFromTopology[topology, data]
Codex/MasterEvaluationWorkflow/ProbeBaikovThreeBodyCut.wls   (our exact cut structure)
Codex/…/ExternalProbe/BaikovPackage/BaikovPackage.m
```

i.e. a topology-in, cut-boundary-integrand-out pipeline, and PILOT §11 records
that it already produced a fully rationalized 4-fold density for PID 30 (T121).
If that pipeline accepts CF123, the parametrization build is obsolete — but
obsoleted by Baikov, and as a **dependency/port decision**, not an MB result.

Two facts bound the optimism, and I record them rather than assume past them:

1. **This machinery is not in our tree.** `find` over
   `/home/maxzhang/factorization-and-loops` returns **no** Baikov file; our
   `FeynFacet/Private/` has no `MasterBoundaryBaikov.wl`. It exists only under
   `~/FACET`.
2. **Template coverage is 1 of 20** (PILOT §9.2): of the 11 representative
   families behind our 20 one-dimensional periods, only `CF267`, `CF384`,
   `CF385` appear at all, and only T121 matches a period master including
   indices. **`CF123` is absent entirely.**

**I did not run the Baikov pipeline on CF123.** It is the single highest-value
next test in this survey and it is cheap; until it is run, "Baikov obsoletes the
build" is a hypothesis, not a finding. Recording it as a hypothesis is the whole
lesson of PILOT §19.7.

---

## 4. S3 — pFq epsilon-expansion (HypExp 2.0): **PASS**

### 4.1 Setup cost

| item | cost |
|---|---|
| locate a live host (`krone.physik.unizh.ch` no longer resolves) | ~10 min |
| fetch + extract (bundles its own HPL 2) | ~5 min |
| **the `$HPLPath` / `$HypExpPath` trap** (below) — one wasted run | ~25 min |
| **total** | **~40 min** |

### 4.2 Results, against the certified CF1 2F1

Certified (PILOT §3):
`R = -(2-3eps)/(v(1-2eps)) * 2F1(1-eps, 1; 2-2eps; -s/v)`, at `v=w=1/4` → argument `-2`.

**First, my reading of the certified closed form was checked against PILOT's own
30-digit numbers**, before HypExp was used at all:

| eps | my evaluation | PILOT certified | agreement |
|---|---|---|---|
| 1/10 | `-4.70239817296299795173232397463414800…` | `-4.7023981729629979517323239746341481689` | **~34 digits** |
| 1/5 | `-5.20598759470933106178308045328833098…` | `-5.2059875947093310617830804532883315775` | **~34 digits** |

| probe | result |
|---|---|
| **unit argument** `2F1(1, 1-eps; 3-3eps; 1)` to `eps^4` | `2 + eps + 2eps^2 + eps^3(11 - 32ψ''(1)+140ψ''(2)-108ψ''(3))/12 + eps^4(155 + …)/24` |
| vs certified soft limit `(2-3eps)/(1-2eps) = 2 + eps + 2eps^2 + 4eps^3 + 8eps^4` | **exact**: the PolyGamma bracket `-32ψ''(1)+140ψ''(2)-108ψ''(3)` equals `37`, so the `eps^3` coefficient is `(11+37)/12 = 4` and the `eps^4` coefficient is `(155+37)/24 = 8`. Confirmed by `FunctionExpand` (exact) and numerically to 30 digits — **`Simplify` alone does not close it**, the third simplifier failure of this survey |
| independent numeric check at `eps=1/50` | residual `-5.33e-8`, vs the predicted `16*(1/50)^5 = -5.12e-8` ✓ |
| **symbolic argument** `2F1(1-eps,1;2-2eps;zz)` to `eps^4` | **succeeded, 0.037 s**, 559 leaves |
| verification: residual/`eps^5` at `eps = 1e-2, 1e-3, 1e-4` | `0.008317, 0.008266, 0.008261` → **converges to a constant**, so every coefficient through `eps^4` is correct |

That unit-argument case is exactly the `₃F₂` collapse PILOT §3 Verification 1
did by hand and that Mathematica's `Integrate` stalled on. HypExp does it in
milliseconds.

**Caveat worth carrying:** the `eps^3`/`eps^4` coefficients of the full `R` come
back carrying explicit `I Pi` terms (from `PolyLog`s at argument `-2`, `3`,
`2/3`). They cancel — the numeric imaginary part is `0` to 34 digits — but a
production use must check reality rather than assume it.

### 4.3 Trap recorded

| # | trap | signature |
|---|---|---|
| H1 | **`$HPLPath` and `$HypExpPath` must be set before `Get`.** Unset, the rule tables (`nmzv.m`, `rulesalgorithm.m`, `.known.m`, `collectedfunctions.out`) never load; the package then *announces itself as loaded* and every symbolic-argument expansion fails with `ReplaceAll::reps` / `ReplaceRepeated::reps` and returns a `String`. | "HypExp loaded!" followed by nothing working |

The unit-argument case worked *even with the tables missing*, which is precisely
the shape of trap that produces a confident partial result.

---

## 5. S4 — high-precision numerics + integer-relation recognition

### 5.1 Target substitution, stated openly

The directive names "the S2 probe-B period". §3.2 establishes that **no
parametric integrand for that period exists in our tree**, so running S4 on it
is not possible. The full loop was therefore scored on the **PID-1 soft
density**, which has a certified exact value — which is what makes the loop's
reliability measurable at all. This is a substitution, not a result about CF123.

### 5.2 SubTropica via the §19.4 reference driver

Driver used exactly as written in PILOT §19.4: regulator `SubTropica\`eps`
(verified in-script: `eps_is_SubTropica = True`), variables `u1,u2`,
`"KernelsAvailable" -> 1`, `"Parallelization" -> "BruteForce"`,
`"SetupInParallel" -> 1`, `"Integrator"`/`"LROrderBackend" -> "HyperIntica"`.

- Loads in **1.36 s**; no `ConnectKernel::failinit`, no `LinkObject::linkd`.
- Each order returns in **0.6–1.1 s**.
- **It computed the right answer.** The internal result surfaced in a warning:
  `{{{1,{}}}, {{5 eps,{}}}, {{-2 eps^2, {{0,-eps^2}}}, {eps^2 (19 - Pi^2/6), {}}}}`.
  With the weight-1 word evaluating to `Zeta[2] = Pi^2/6`, the `eps^2`
  coefficient is `19 - Pi^2/6 - 2*Pi^2/6 = 19 - Pi^2/2 = (38-Pi^2)/2` — **the
  certified value.**
- **`"CleanOutput" -> True` does NOT fix the `{coefficient, word}` pair
  structure.** PILOT §19.7 left this queued as an untested hypothesis
  ("the documented option for this is `"CleanOutput" -> True` … recorded here as
  a hypothesis, not a result"). **Tested now: refuted.** With `CleanOutput->True`
  the aggregation still fails with `Total::tllen: Lists of unequal length …
  cannot be added`. That closes a pilot open item.
- Environment change worth noting: SubTropica's banner now reports
  **`[✓] HyperFLINT`** and `[✓] polymake`, `[✓] ginsh`, `[✓] msolve`. PILOT
  §19.2 recorded no HF library in the tree. Something changed; I did not chase it.

### 5.3 Integer-relation recognition — works, and is **not safe alone**

Target: recognise the `eps^2` coefficient from its number alone against the
basis `{c2, 1, Pi^2, Zeta[3], Log[2]^2}`. True relation: `2 c2 - 38 + Pi^2 = 0`.

| input precision | `FindIntegerNullVector` result |
|---|---|
| 12 digits | **`{2,-38,1,0,0}`** ✓ |
| 20 digits | **`{2,-38,1,0,0}`** ✓ |
| 30 digits | **`{2,-38,1,0,0}`** ✓ |
| 50 digits | **`{2,-38,1,0,0}`** ✓ |

It recovers the correct relation even at **12 digits** — which is exactly what
MB.m's numeric pipeline delivers (§3.1). That is the good news.

**The negative control is the finding.** Feeding `c2 + Log[3]`, a constant
genuinely outside the span:

| precision | result |
|---|---|
| 20 digits | `{143553, 1079168, -764597, 2179431, 3476909}` |
| 30 digits | `{3665539, 2254250, -6657009, 5851904, 1727404}` |
| 50 digits | `{1098862735, -3079266838, -1339125953, 1091272176, -3494216485}` |

**`FindIntegerNullVector` never returns "no relation". It always returns
something.** At every precision it fabricated a relation for a constant that has
none. The only discriminants are (a) coefficient magnitude — the true relation
has coefficients `{2,-38,1}`, the fabrications have 6–10 digit coefficients —
and (b) exact certification afterwards, which closed here (`cert/exact_match =
True`).

**Score of the full loop's reliability, which is what was asked:** the numerics
are reliable and cheap; the recogniser is a *generator of candidates, not a
decision procedure*; the certification step is **load-bearing and mandatory**. A
pipeline that recognises and reports without certifying will publish fabricated
constants, and will do so more confidently at higher precision.

### 5.4 Traps recorded

| # | trap | signature |
|---|---|---|
| S1 | **SubTropica exports `line`.** My reporting helper was named `line` and defined *before* `Needs["SubTropica\`"]`; afterwards `line[...]` resolved to `SubTropica\`line` and **every result line silently vanished**, while the script ran to completion, exited 0, and printed its `DONE` marker. Confirmed: `Context[line]` after load is `"SubTropica\`"`. | a green run that reports nothing |
| S2 | `Check[expr, "ERR"]` fired on the **benign** `Total::tllen` warning, so my second run recorded `"ERR"` for calls that had in fact succeeded. This is PILOT §19.5 item 5 repeating verbatim. | success recorded as failure |

S1 is the same family as `BENCHMARK_REPORT` traps P1/B4 and it is the most
dangerous kind: exit code 0, `DONE` printed, zero output. Per the seat rules'
own warning — *exit codes lie*.

---

## 6. S5 — inventory (no probe run)

| tool | role | status here |
|---|---|---|
| **AMFlow** | high-precision numeric master evaluation, auxiliary-mass flow | **already in our `Addon`**, unused by this survey; the natural numeric cross-check for any recognised boundary constant |
| **pySecDec** | numeric checks; also `make_regions`, a genuine S1 alternative | **not installed** (no module); FeynCalc's `FeynHelpers/Interfaces/pySecDec/PSDLoopRegions.m` is in our tree and would drive it |
| **FIESTA** | numeric checks, sector decomposition, `SDExpandAsy` | not installed; FeynHelpers interface present (`FSASDExpandAsy`) |
| **MZV data mine** | constants for the recognition basis in S4 | `Addon/…/SubTropica/mzv.wl` is present in-tree — this is the natural basis source to widen §5.3 beyond `{1, Pi^2, Zeta[3], Log[2]^2}` |
| **PolyLogTools** | GPL-valued periods | in `Addon`; scored in the stage-2 benchmark |
| **HyperInt** | linear reducibility | **Maple-blocked**; SubTropica's banner confirms `[-] maple` on this box. User decides licences. |
| **FeynCalc 10.2.1** | `FCTopology`, `FCFeynmanParametrize`, `FCFeynmanProjectivize` | in `Addon`; it is the input format Codex's Baikov builder expects, and `FCFeynmanProjectivize` is the obvious remedy for asy's projective-chart assumption (§2.4) |

---

## 7. Proposed boundary-campaign toolchain, with the hand-work delimited

```
  per period
  ----------
  [1] REPRESENTATION   cut phase-space integrand in parametric form
      -> HAND (2-var chart) for the 1-denominator tier: DONE, 3/3 solved
      -> Baikov (Codex's BuildBaikovCutBoundaryIntegralFromTopology)
         for >=3 denominators  ** UNTESTED ON CF123 — the gating experiment **
      -> otherwise the 4-fold/5-var parametrization build, still required
  [2] REGIONS          asy 2.1 on the polytope        MECHANICAL (~1 s)
      -> chart selection (where the degeneration sits) remains HAND
  [3] EVALUATION       MB.m + barnesroutines           MECHANICAL when the
                       (exact via Barnes; ~12 digits    denominators split into
                        numerically)                    two non-negative pieces
                       SubTropica  (0.7 s/order, exact symbolic)
  [4] SPECIAL FUNCTIONS HypExp 2.0                      MECHANICAL (0.04 s)
  [5] RECOGNITION      FindIntegerNullVector            CANDIDATES ONLY
  [6] CERTIFICATION    exact DE check / region check    MANDATORY, and ours
```

**Residual hand-work, honestly delimited:**

1. **Chart selection** (§2.4) — deciding which corner degenerates. asy needs it
   as input. Cheap per period once the pattern is known, but not automated.
2. **The MB split** (§3.1) — spotting `1-XY = (1-X) + X(1-Y)` and noticing the
   `Gamma` cancellation was ~20 min of my time and is not mechanised by anything
   fetched here. AMBRE would do this automatically **for uncut loop integrals**;
   for our cut integrals nothing does.
3. **The representation for >=3 denominators** (§3.2) — the actual blocker for
   17 of 20 periods. Not solved by MB. Possibly solved by Baikov; untested.
4. **Certification** (§5.3) — non-negotiable, and it is our own DE/region
   machinery, not a package.

**What this survey changes about the plan.** Steps [2], [3], [4] were all going
to be hand-work and are now mechanical, which is a real reduction. Step [1] —
the 5-variable build — is **not** removed by MB, and it remains the item that
gates 17 of 20 periods. The next action is therefore not "start the 5-var
build" and not "adopt MB for the tier"; it is **the one cheap experiment that
decides whether the build is needed at all**: point Codex's
`BuildBaikovCutBoundaryIntegralFromTopology` at CF123's `FCTopology` and see
whether a density comes out.

---

## 8. Honest status of every protocol item

| item | status |
|---|---|
| S1 asy — PID-1 soft-edge regions | **done, PASS**, with same-shape positive controls |
| S1 asy — NLO edge conditions | **NOT RUN** — timebox; the PID-1 probe plus controls consumed it |
| S1 — upstream asy provenance | **mirror only**, flagged in §1 |
| S2-A MB — PID-1 control | **done, PASS** (exact closed form + ~12 digits/order) |
| S2-B — CF123 | **structural verdict delivered**; MB does not reach it. No integrand was built, by design — that is the finding |
| S2-B — Baikov route on CF123 | **NOT RUN** — the single highest-value follow-up |
| S3 HypExp — 2F1 to `eps^4` | **done, PASS**, unit and symbolic argument |
| S3 — HYPERDIRE | **NOT RUN** (was "if trivially available"; it was not) |
| S4 SubTropica via §19.4 driver | **done**; computed correctly; `"CleanOutput"->True` hypothesis **refuted** |
| S4 — 50+ digits from SubTropica | **NOT OBTAINED**: the `{coefficient, word}` pair structure still blocks automatic extraction (§5.2). The value was confirmed by reading the coefficients, not by a scored extraction |
| S4 integer relations + controls | **done**; recogniser fabricates without certification |
| S4 exact certification | **done**, closes (`True`) |
| S5 inventory | **done**, no probes |

**Files:** `pkgs/` (fetched packages + checksums), `build/qhull-2020.2/bin/qhull`,
`load_test.wls`, `s1_asy.wls`, `s1_control.wls`, `s2a_mb.wls`, `s2a_mb2.wls`,
`s3_hypexp.wls`, `s3_hypexp2.wls`, `s4_subtropica.wls`, `s4b.wls`, and the
corresponding `.log` files.

---

## 9. What would change these verdicts

- **Running Baikov on CF123.** It decides §3.2 outright and it is cheap. If it
  produces a density, the 5-var build is dead and steps [1]–[3] become a single
  mechanical chain; if it refuses, the build is confirmed necessary and should
  be budgeted immediately.
- **An upstream asy copy.** Every S1 number here comes from a third-party
  mirror. The controls passed, but nothing should be registered on mirror output.
- **Widening the S4 recognition basis** using the in-tree `mzv.wl`. The current
  basis is 4 constants; real boundary constants at this weight will need more,
  and §5.3 shows the false-positive rate rises with basis size, not falls.
- **A period whose denominators do NOT split into two non-negative pieces.** The
  entire S2-A success rests on that split existing. I did not test a case where
  it fails, so the MB verdict is "excellent where it applies", with the domain
  of applicability untested beyond one period.
- **`FCFeynmanProjectivize`.** If it converts our hypercube Euler integrals to
  asy's projective convention automatically, the chart hand-work of §2.4 may
  also be mechanisable — untested.
