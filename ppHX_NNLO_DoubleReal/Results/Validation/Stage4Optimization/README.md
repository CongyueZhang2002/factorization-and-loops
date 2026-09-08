# Stage 4 optimization and saved epsilon-order checks

All timings are elapsed seconds on this WSL host. Unless stated otherwise,
assembly timings exclude input loading and final serialization.

| Work | Before | Retained implementation | Scope |
|---|---:|---:|---|
| Interior coefficient assembly | about 1,204 through the last coefficient | 257.06 | Full 345 masters / 2,220 coefficients; new time includes source loading, excludes final save; old value is a progress timestamp, not an identical end-to-end timer |
| Late color collection | 644 | 455.37 | Full ten-component result, eight workers; input load 70.04 s separately |
| Endpoint assembly | 268.66 | 217.61 | Same full input, 345 masters / 92 endpoint contributions; exact equality of every mathematical output field |
| Repeated final endpoint graph checks | 97.54 | 45.61 | Replaced repeated edge/order checks by preserved-offset closure and output checks |
| Saved Stage 4 order audit | — | 0.053 | 345 interior, 317 regular-endpoint and 607 moment checks; no integrations |
| Saved Stage 3 order audit | — | 0.102 | 33 inputs, 565 requested amplitude coefficients, 775 contributing reduction checks |

The coefficient pilots CF1, CF12 and CF21 fell from 23.47/11.33/28.29 s
to 11.52/6.21/11.86 s. Each passed coefficientwise checks at three rational
kinematic points at 70-digit precision. See coefficient_baseline.json and
coefficient_optimized.json.

The retained improvements extract epsilon coefficients before restoring the
large kinematic coefficient field, distribute independent coefficient jobs,
avoid default per-coefficient checkpoint write/read, reuse identical exact
multiplier checks, and preserve color-free shared references during late color
collection. All outputs remain explicit finite expressions.

The full late-color comparison has 29 structurally identical component/category
groups; the remaining regular group agrees at a generic rational kinematic and
formal-factor assignment at 70-digit precision. All original mathematical fields
are preserved. The first benchmark comparison omitted parameter substitutions;
the independent recheck of the same saved output corrects that harness issue.
See color_optimized.json and color_verification.json.

The endpoint output is exactly identical with the prior implementation after
removing only timing metadata; see endpoint_optimized.json. Every input graph
is checked on each call. Disjoint offsets preserve valid indices and ordering.
Coordinate rules are restricted to declared scalar coordinates and cannot
inject finite-reference symbols. Final checks still reject undefined
transformed values and invalid references in assembled coefficients.

The saved audits use actual stored cutoffs, under the declared Laurent lower
bounds and endpoint uniformity classes; they do not re-evaluate integrals or
prove those declarations. The current independent boundary-value reference
coverage is still incomplete, separately from this passing order audit.
saved_stage3_short.wxf is an intentionally FAILED negative test: the driver
exits 1 and exposes the omitted coefficient in the requested output.

The final nine regression files pass 159 assertions, including deliberate
shortening in stages 2, 3 and 4, a Gamma pole times an endpoint moment, missing
stored orders, invalid color factors, worker failure propagation and coordinate
map failures. See regression_tests.json and individual logs. The package
layout audit now passes 165 registered sources after the NLO additions.

The early-color prototypes were withdrawn after slow large-input pilots.
They are not production code or a claimed speedup. The retained method keeps
color collection after epsilon expansion.

Verified GPT-6 Pro reviewed the color/remainder design:
[exchange](../../../../External/ChatGPT/Records/2026-09-08/01_stage4_color_and_epsilon_orders.md).
The outgoing request model was gpt-6-pro, HTTP 200. It is a review of the supplied
mathematical/design description, not unprovided source files. The second review of the final definition-check optimization is complete:
[exchange](../../../../External/ChatGPT/Records/2026-09-08/02_stage4_definition_closure.md).
The final safe-head grammar added 8.91 s on the full actual data; the 217.61 s
endpoint benchmark predates this additional check. All mathematical output
fields still match exactly. Held programming constructs take the full check.

Canonical Assembly/Stage4_2026-09-07 outputs remain the accepted process results.
The complete temporary benchmark copies and temporary compaction maps have
been removed after verification: 380,906,128 bytes. Small reports and logs remain
in this directory; see benchmark_cleanup.json.
Old coefficient checkpoints outside this directory were not removed.

## Compact final storage

The accepted bare double-real result also has a compact color-resolved version:
`../../Assembly/Stage4_2026-09-07/BareDoubleRealDistributions.compact.wxf`.
Both files use compressed WXF. The original is 317,049,147 bytes; the compact
version is 104,939,642 bytes (66.90% smaller). These are actual file sizes,
not sums of Mathematica ByteCount values. It remains the same bare double-real
contribution, with the original domains, excluded points and branch information.

The retained representation stores the ten explicit color components and a
closed set of 79,757 algebraic definitions, 34,618 scalar integral definitions
and 431,261 kernel definitions. Redundant uncolored expressions, interior and
singular-model views are omitted. K, F and a are shared definitions of already
constructed finite expressions; this change introduces no lazy DE solver or
coefficient generator. The NNLO result still uses its general finite-integral
representation. Only the new NLO hard functions have fully elementary/polylog
expressions with no unevaluated integrals.

Exact compaction took 157.38 s; independent comparison and packaging took
73.60 s; compressed export took 32.34 s. Source loading was separate. The fresh
kernel serialization check passed: original load 71.61 s, compact load 22.96 s,
full post-serialization correspondence check 104.94 s. Its report is beside
the compact file. The independent
check compares the complete output, every retained source definition, semantic
contexts and retained metadata without numerical integral evaluation.

Definitions with different source path scopes cannot merge. All defining fields
are compared, with no bound-variable renaming. Approximate semantic values and
reference-bearing association keys are rejected. Seventeen focused tests include
altered paths, changed endpoints, omitted definitions, changed output/domain,
serialization and invalid indices. Verified GPT-6 Pro review:
[exchange](../../../../External/ChatGPT/Records/2026-09-08/06_stage4_compaction.md).

A bounded rational-cancellation pilot restored full formal atom identities
before comparison: a 236,800-byte algebraic expression cancelled to 136,544
bytes in 0.019 s. Other sampled expressions contained 57–106 formal variables,
beyond the pilot's 50-variable limit. This is an exploratory opportunity, not
an applied transformation or a claimed additional reduction. Sampling actual
integral values for rational reconstruction would obscure algebraic relations
and does not determine coefficients of independent formal atoms. Existing
finite-field coefficient reconstruction remains in production; exact graph
compaction was the clear first improvement here.
