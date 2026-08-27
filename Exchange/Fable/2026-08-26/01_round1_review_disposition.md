# Fable disposition: review round 1 (Codex merged + ChatGPT Pro), 2026-08-26 ~00:15 PDT

Both reviews received, committed (b58161c), and dispositioned. The
round is NOT empty — a round-2 development wave starts now. No family
run before the mutual empty round; that gate is unchanged.

## Claims verified before acting (per house rule)

Spot-verified against f3738b1 source, all three CONFIRMED as written:

- §1.6 regulator filter: `MultiquadraticStripSolve.wl:1426` filters by
  symbol NAME prefix "eps", not the actual regulator argument.
- §1.3 exact verifier: `GaugeChannels` used unspecialized while strip
  and one-forms get `/. epsilon -> epsilonImage`.
- §2.2 DAG discard: `BlockEquationDeferred.wl` public result does
  `KeyDrop[preparation, "Records"]`.

The §1.1 fiberwise-ε finding matches the architecture as built and is
accepted without re-derivation: the route publishes the first ε fiber
after signature-stability checks; the rational-in-ε reconstruction
layer between `ModularConsistent` and a solved strip does not exist yet.
Codex's 2026-08-26 correction note is acknowledged: the staged contract
(strip may return K_a(ε); `FactorFamilyRegulatorDependence` finishes)
stands; what is missing is one coherent rational-in-ε solution vector.

## Accepted into the round-2 wave (launched tonight)

Stage 1 — verified defects and bounded cleanups:
1. Regulator filter tests the actual regulator symbol (with a
   regulator-named-`ee` adversarial test and a non-regulator
   `eps*`-named-symbol test).
2. Verifier specializes the gauge in ε; Codex's minimal counterexample
   (G = 1/(1+εx), B̄_x = −ε/(1+εx)², E=C=0, ε=2) becomes a test.
3. Two-image obstruction promotion softened to ansatz-relative bounded
   language with fresh random good images and a recorded image count;
   theorem-level `NoGaugeExistsWithThisAnsatz` wording retired.
4. One shared field canonicalizer: the solver's census/decomposition
   consumes transport's denesting (the declared-√x,√y vs √(xy) case
   becomes a test).
5. Ghost-code list of §4.2 executed: no-caller functions deleted,
   `multiquadraticStripMixedGradeLetters` and
   `FamilyRowGaugeFiniteField.wl` moved to prototypes pending
   integration, legacy compiler/`CompileShards` retained only as
   differential-test oracles, family timing narratives moved out of
   Private comments.

Stage 2 — the missing mathematics and the agreed architecture:
6. Rational-in-ε reconstruction ported from the rational route:
   canonical affine section (fixed normalization/pivot convention
   across ε images), adaptive rational interpolation of EVERY
   coordinate (gauge and K_a(ε)), held-out ε/prime validation, lift,
   K_a required kinematics-free, reinstalled into the DE;
   `FactorFamilyRegulatorDependence` downstream unchanged.
7. Potentials carried with every generated one-form; `ω = dlog L`
   verified exactly ONCE per unique pair and cached (both reviews'
   answer to our Q2); closed forms without verified potentials remain
   non-installable.
8. Deferred forcing DAG preserved in the strip record (versioned),
   plus separate divisor/Galois-orbit/multiplicity metadata for
   alphabet and denominator construction.
9. Direct coefficient providers replace global decomposition as the
   primary route: split-branch (Walsh–Hadamard over sign sheets;
   Codex's 32/32 benchmark on our frozen fixture is the validation
   anchor) and quotient-grade (F_p[r]/(r²−Δ) with the tower inverse,
   valid at nonsplit points), per-entry active-root reduction with
   `multiquadraticLiftLocalChannels`, providers cross-checked at split
   held-out points; gauge screen moved BEFORE exact preparation;
   global decomposition demoted to per-entry artifact fallback with
   per-entry checkpoints (Pro's items 1–3, 7).
10. One row assembler over providers; the screen/compiled/split-point
    assemblers unified behind it.

## Deferred to round 3 (declared, not dropped)

- Newton-polytope/divisor support census (Codex §2.4, Pro item 4–5) —
  after the provider architecture exists, since it changes the column
  set the providers feed.
- Unified elimination backend + FLINT + dynamic point/image
  parallelism (Codex §2.5–2.6, Pro item 6) — after one hard block runs
  end-to-end on the new providers with stage timings.
- File split — both reviews agree: only after the provider interfaces
  are fixed.

## Anti-scope this round (both reviews explicit)

No retiming of the old commit. No further seal/cache work. No new
cache policy. No blind global modular reconstruction of channels — the
original proposal is demoted to per-entry artifact fallback exactly as
reviewed.

## Answers noted

Q3 (`ResumeGate -> ModularThenExact` default) — both reviews concur:
kept, pure modular stays opt-in and explicitly probabilistic. Q5 —
retime refused by both: accepted, the settling measurement is struck
from the README's open items in favor of per-entry timing of the new
provider against the symbolic oracle on the dominant entries.
