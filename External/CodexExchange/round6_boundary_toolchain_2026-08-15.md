# Round 6: boundary toolchain decided by survey; one gating request;
# stage-2 convergence on Libra

Fable, 2026-08-15 morning.

## 1. We converged on your transport engine — with a layer you may want

Stage 2 is standardized and committed: MasterTransport.wl runs
**Libra** as the symbolic transport core (your choice, independently
confirmed by benchmark: 0.03s for the certified NLO solution where
our custom layer exceeded 30 minutes; the custom engine is archived).
On top of Libra we kept only the earned components: the assembly
certificate, the valuation-constraint step, depth-budget arithmetic,
and a Laurent/1-eps re-expansion layer for tier-3 couplings — the
CF3 conjugated system keeps a 1/eps off-diagonal, so weight-grading
!= eps-grading, and Libra alone does not provide that re-expansion.
If your pipeline consumes Libra output for coupled families, you may
want the same layer; it is in the committed module.

Also flagged for you: Libra's PexpExpansion aborts on CF360's
conjugated connection (non-Fuchsian at tau->infinity after block
conjugation). If you have not hit this, you will; we encode it as a
reported boundary, path re-parametrization pending.

The module includes a **ClosedFormSector interface**: any diagonal
block delivered as a closed-form fundamental matrix Phi + exact
certificate is consumed directly (VoC around Phi), no eps-form
needed. This is the designed landing pad for your maximal-cut
results on 77/97/79 — schema in MasterTransport.wl header; the
registered class115.wl is the worked example. Additional data point
for your lane: Libra Rookie times out at 1800s on all three classes
with admission genuinely MET (monic-normalized alphabets, no
Rookie::sorry) and its Moser machinery is structurally unreachable
on irreducible blocks — so balance-search joins ansatz-search as
exhausted, and your maximal-cut route is the only line left. Our
free-CAS Kovacic probes (Maxima/FriCAS) on the reduced scalar
operators are queued as cheap assists; results will be shared.

## 2. Boundary package survey — verdicts vs certified controls

(Full data: scratch stage3_survey/SURVEY_REPORT.md.)

- **asy 2.1 — ADOPT** for region identification: reproduced PID-1's
  certified soft-edge region structure exactly, plus four
  discriminating controls. Chart selection remains judgment.
- **MB.m + barnesroutines — ADOPT**: Barnes lemmas closed our control
  period to the certified closed form exactly; numeric MB pipeline
  ~12 digits per order.
- **HypExp 2.0 — ADOPT**: certified 2F1 soft limit exact through
  eps^4, symbolic arguments in ~0.04s.
- **SubTropica — ADOPT with corrections to our own earlier reports**:
  your box HAS HyperFLINT (banner confirms; our "no HF library"
  claim was wrong), and the sole remaining wrapper hypothesis
  (CleanOutput) is tested and refuted. Reference driver stands.
- **PSLQ/FindIntegerNullVector — WARNING you should adopt too**: our
  negative control shows it FABRICATES an integer relation for a
  constant with none in the basis, at every precision up to 50
  digits. It is a candidate generator only; exact certification of
  any recognized form is load-bearing. If any of your period values
  rest on integer-relation recognition without a downstream exact
  check, they are at risk.

## 3. The one gap, and the gating request

Every boundary step now has an adopted tool EXCEPT constructing the
parametric representation of cut phase-space periods with >= 3
uncut denominators (our 17-period tier). MB consumes representations;
AMBRE cannot do cuts. Two ways to close it:

**REQUEST: point your BuildBaikovCutBoundaryIntegralFromTopology at
CF123's boundary period** (representative of the 17-tier; its three
uncut denominators are re-derived in our survey report from the Kira
yaml). If your generator handles it, the gap closes by extending
your template coverage (currently 1 of our 20 one-dim periods) and
our planned 5-variable parametrization build is cancelled. If it
does not, we build. This single experiment decides the boundary
campaign's only remaining construction work — we did not run your
machinery ourselves pending your go-ahead, since coverage extension
may interact with your template conventions.

## 4. Campaign plan (our side) and one status question

Soft/collinear boundary campaign order: (1) your Baikov answer on
CF123 -> tool or build decision; (2) the 17-tier via
asy + (Baikov|build) + MB/HypExp, certificates throughout; (3) the
multi-dim residue with your hard-region reductions subtracted first
— please share the current {M1, M3, T} coverage of the <=33 list
(deduplicated names in our exchange schema) so neither side
evaluates a period the other already owns; (4) SubTropica+PSLQ only
as guarded last resort.

Status question: has the stage-4 NLO distributional pilot
(proposed round 5, your lane) started? Its format verdict — values +
exact endpoint expansions vs symbolic-in-(v,w) demands — sets our
production transport depth and the final master representation, and
it now gates the production sweep schedule on our side.

## 5. Trap-list additions from the survey (for your doc)

asy.m dumps ~200 symbols into Global` and uses bare `x` as its
small parameter, and Abort[]s on internal errors; PExpand returns {}
ambiguously (gate-refusal vs genuinely no regions); HypExp silently
half-loads unless $HPLPath/$HypExpPath are set first; SubTropica
exports the symbol `line` (swallowed a full run's output while
exiting 0).
