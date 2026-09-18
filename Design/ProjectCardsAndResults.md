# Raw contributions and assembled results

A project is defined by Wolfram Language cards:

```text
Projects/<project>/
  Common-Card.wl
  Raw/<order>/<channel>/<contribution>/
    Card.wl
    Results.wl
    Work/
  Results/<order>/<channel>/
    Result_Card.wl
    Results.wl
    RunReport.wl
    Timing.json
    Validation/
```

Project names identify the process and polarization, without an LO/NLO/NNLO
suffix: `ppHX_UU`, `ppHX_LL_SpinTransfer`, `SIDIS_UU`, or `DrellYan_UU`.
Antiquarks use `qb` (`qpb` for a different flavor), and explicit flavors use
`ub` and `db`. The species tuple is `{"qb", "u"}` for an up antiquark.

Old results belong in the repository-level `Archive/Results/`; a project has
no private archive.

Order precedes channel because a higher-order coefficient can involve several
lower-order physical channels. Raw means contributions before the selected
sum: bare densities, UV counterterms, PDF/FF counterterms and finite scheme terms.

## Common physics and contribution cards

`Common-Card.wl` owns the physical channel catalog, polarization, momenta,
measurements, normalization, scales, operator schemes, complete density templates
and execution allocation. Automatic flavor closure and minimum-order derivation
remain in the common physics compiler.

A raw card selects a density/interference contribution and its explicit
components. State and flavor factors are derived from these definitions by
[the normalization layer](../FeynFacet/Normalization/README.md), rather than
supplied as independent multipliers. It never adds a factor of two merely
because a contribution is called virtual. Example ordinary card:

```wl
<|"Contribution" -> "Real", "EpsilonRange" -> {-2, 0}|>
```

A counterterm belongs to the channel of its underlying perturbative amplitude.
The source channel is the enclosing Raw directory, so it is not repeated in the
card. For example, Raw/NLO/qqp-qqp/Counter-PDFB/Card.wl contains:

```wl
<|
  "Contribution" -> "Counterterm",
  "EpsilonRange" -> {-1, 0},
  "OperatorInsertions" -> {
    <|"IncomingB" -> <|"Distribution" -> "PDFCounterterm",
      "PerturbativeOrder" -> 1, "Operation" -> "Factorization"|>|>
  }
|>
```

For an NLO counterterm, the compiler infers `SourceOrder -> "LO"`,
`SourceContribution -> "Born"` and `SourceRenormalizationStage -> "Bare"`.
Those redundant fields are omitted from generated NLO cards. Conflicting
explicit definitions are still rejected. NNLO cards retain the source-order
and source-density information needed to distinguish their contributions.

Counterterm folders are named Counter-PDFA, Counter-PDFB, Counter-FF or
Counter-UV under their source channel. A single incoming PDF uses Counter-PDF.
Source-channel suffixes do not appear in these names. At higher orders a source
density/order and operator powers distinguish genuinely different contributions.

A source amplitude can feed several target channels through splitting. Its
Results.wl is an explicit FeynFacet-PartonicChannelResults collection:
Results[targetChannel] is an ordinary FeynFacet-PartonicResult, with exactly
the same normalization and coefficient schema used for real and virtual
contributions. No coefficient conversion, unevaluated convolution or generator
is inserted. OutputChannels optionally narrows the raw card's output scope.

A result card selects a source-owned operator and its target component:

```wl
<|"Path" -> "../../../Raw/NLO/qqp-qqp/Counter-PDFB",
  "OutputChannel" -> "qg-qg", "Weight" -> 1|>
```

This input belongs in Results/NLO/qg-qg/Result_Card.wl. Ordinary real and virtual
inputs must match the result channel. Counterterm inputs can come from other
raw channels in the same project and perturbative order; OutputChannel must
match the result channel. Duplicate mathematical terms, wrong target components,
incomplete coverage and mismatched normalization remain errors.

In operator associations, IncomingA/B identify the two incoming PDF legs,
Observed identifies the fragmenting outgoing FF leg, and Coupling identifies
the strong coupling. Thus FF counterterms subtract final-state collinear poles;
UV counterterms renormalize the strong coupling.

Each list entry is a term; insertions in one association form a product.
Automatic card preparation writes one card per source/operator product and
reuses that card when another result needs a different channel component.
Flavor multiplicities are derived for each component by the shared planner.
Explicitly named groupings are allowed. Mathematical coverage uses resolved
weighted operators, not filenames or a fixed number of cards.

Counterterm sources are regenerated from common physics under their source-owned
operator directory, in Work/Channels/<target>/Sources/<source-order>/<source>.
This keeps every intermediate product with the perturbative amplitude that
owns it. Result selection compiles only its requested target component. Components own
`Work/Components/<component>/`. Their internal results also use the common
partonic result format. Kira and reconstruction workspaces remain under the
nearest contribution `Work` directory. No sibling LO/NLO result is an input.

## Explicit result selection

A result card specifies its inputs, for example:

```wl
<|
  "ResultType" -> "SelectedSum",
  "EpsilonRange" -> {-2, 0}, "RequireFinite" -> False,
  "Inputs" -> {
    <|"Path" -> "../../../Raw/NLO/qqp-qqp/Real", "Weight" -> 1|>,
    <|"Path" -> "../../../Raw/NLO/qqp-qqp/Virtual", "Weight" -> 1|>
  }
|>
```

`PrepareProjectChannel[projectDirectory, order, channel]` creates a complete
initial LO/NLO selection from declared common physics, including all required
counterterms. It refuses to overwrite existing cards. Edit the explicit result
card to select another sum.

`"SelectedSum"` allows selected contributions and retained poles. Extracting
epsilon zero does not establish finiteness or completeness.
`"CompleteCoefficient"` requires the complete ordinary density definitions,
exact counterterm coverage and exact pole cancellation. Missing contributions,
unsupported terms and absent files are never interpreted as zero.

Weights are exact scalars independent of epsilon, the coupling and the
distribution/convolution coordinates. A coordinate-dependent weight needs
distribution algebra; multiplying only stored plus coefficients is incorrect.

## Epsilon orders and normalization

`PlanProjectResult` resolves every input before generation, raises each raw
upper order as needed and invokes the existing operator/source order planner.
All Laurent coefficients down to each established lower bound are retained
until cancellation is checked. Requested output slicing happens afterward.

For a product/convolution T B through epsilon^q, B is required through
q - valuation(T). A simple NLO PDF/FF pole needs Born through epsilon^1 for a
finite result; pure LO needs only epsilon^0. Endpoint extraction, numerator
contraction, loop integration and analytic normalization retain their existing
sufficient-order and labelled-remainder checks. Unknown coefficients are not zero.

The bare coupling convention is derived once from the common card's explicit
C_epsilon. Coupling-renormalization powers use the source density's actual
coupling power. Source projectors and incoming averages use the source species.
Raw results must agree on exact normalization, measured density, distribution
basis, physical channel, polarization and perturbative power before addition.
Association key order is immaterial.

A nontrivial finite scheme conversion defined at epsilon^0 does not define
positive-epsilon coefficients; requests beyond that contract are rejected.
A dimensionally defined reference-scheme result can be expanded further.
Pole cancellation and completeness are separate acceptance checks.

## Execution and storage

- ReadContributionCard[rawChannelDirectory, name] composes common physics with
  name/Card.wl. A source-owned counterterm resolves its explicit target components.
  A third target-channel argument compiles just that component. Dotted names
  continue to select ordinary real/virtual components.
- `RunRawContribution[compiledCard, "all"|"resume"]` executes only that raw
  contribution, without cross-contribution cancellation or completeness gates.
- `PlanProjectResult[resultCardFile]` performs coverage and order planning.
- `AssembleProjectResult[plan]` only reads selected raw results; it never
  launches missing calculations.
- `RunProjectResult[resultCardFile, "all"|"resume"|"assemble"]` coordinates these
  stages. At NLO, `all` regenerates ordinary diagrams/reduction/evaluation; at
  NNLO it reevaluates prepared solved integral inputs. `resume`
  reuses exactly matching consumer-owned inputs with sufficient orders.

Ordinary and final Results.wl files contain self-contained FeynFacet-PartonicResult
associations. A source counterterm file is an explicit channel collection whose
entries are that same common result schema. Accepted finite NLO files contain
explicit scalar functions and delta/plus/regular coefficients, without
unevaluated integrals or deferred source reads. Artifact readback is checked.

`RunReport.wl` records planning, each raw contribution and assembly.
`Timing.json` contains compact channel calculation timing. The Python campaign
report separately records startup/supervisor wall time and failed attempts.

## Supported execution and retained inputs

The NLO workflow generates ordinary contributions from diagrams and automatic
counterterm sources. SIDIS NNLO uses the same Raw/Results organization, with
ordinary contributions evaluated from bound solved endpoint coefficients or
reduced virtual integrals. The old NLO outputs and their archive copies were
deleted. Retained NNLO master-DE/boundary and endpoint records provide upstream
inputs; they are not copied final hard functions.

For current coverage and pending work, consult STATUS.md and the dated campaign
report. A prepared NNLO replay is distinct from a fresh master calculation.

## Resumed input provenance

Resumption matches declared physical definitions and epsilon coverage. After
a change to amplitude algebra, use `all` to regenerate amplitudes; matching
cards do not establish that an older implementation had no algebraic bug.

Family canonicalization produces new artifacts. Their `AnalyticContext` records
the current canonicalizer's source version and retains every input physical
convention verbatim. `OriginalAnalyticContext` preserves the original pair
producer and conventions. This permits pairs retained during an interrupted
run to join newly generated pairs after workflow-only code changes, without
weakening Kira's exact common-context validation.


Parallel result jobs can request different components of the same source-owned
counterterm. Updates to its result collection are protected by a POSIX file
lock; each component has its own working directory. Cancellation releases the
lock automatically. Writing one component preserves other completed components.
The reader validates each selected component's actual physics and epsilon range.

## Displayed mathematics and machine metadata

All generated Wolfram text uses the [shared readable format](ReadableRecords.md).
The displayed partonic association starts with Coefficients; exact symbol
contexts and omitted execution metadata live in the .meta.wxf companion.
The framework reader restores the complete schema described above. Native
solver inputs/outputs and explicit binary products retain their native formats.

## Prepared NNLO integral inputs

`Work/IntegrationPlan.wl` selects the integration method. For `EndpointProfiles`,
it points to `Work/IntegrationInput.wxf`. The latter contains explicit bulk and
face coefficients, endpoint projection conditions, original amplitude/assembly
definitions, independent bulk and face row selections, and the physical-to-normal
coordinate map. These are solved coefficients, not unevaluated integral generators.

The producer calls `CreateEndpointIntegrationInput` while its source definition
is available. `CreateContributionIntegrationPlan` then checks the physical
definition in the actual saved input against the consuming card. Changing only a
description in the plan cannot make a different saved input compatible. Bulk and
profile rows are selected by their own labels; their order need not coincide.
The measured one-loop producer retains the integration definition when reducing
and normalizing, and checks that same definition when constructing endpoints.

`VirtualMasterLibrary` evaluates stored reduced virtual integrals, including
their recorded loop measure and the current declared scalar library. The actual
stored process definition must agree with the current card; renamed species
require the original model-field map.

Summation and finite extraction retain analytic conventions. Additional domains
and assumptions intersect existing ones; changes to a real-letter prescription
or GPL continuation require an explicit analytic transformation. Numerical pole
checks remain labelled numerical evidence. Explicit GPL words are permitted;
unevaluated integrals and malformed GPL objects are refused.

Initial non-LO card preparation requires a contribution-specific established
Laurent lower bound. The bound applies to the integrated amplitude with its
measure and every prefactor, not just the scalar master integrals.

This prepared endpoint interface currently requires independent affine normal
coordinates on the unit interval, with distance x or 1-x. Unsupported nonlinear
charts are rejected; a future chart implementation must also establish its
physical domain and branch. Saved input paths are resolved once against the
contribution Work directory and retained as absolute paths.

For multi-output endpoint plans, run `record_endpoint_assembly_sources.wls`
before producing the bulk/profile files. It preserves an existing original
snapshot and refuses to overwrite its normalization from a later card, or to
retroactively label already solved data without an original snapshot.

## Removable kinematic limits in explicit results

A result card may declare `"RemovableKinematicLimits" -> {x -> z}`. Assembly
retains ordinary finite substitutions and fills undefined ones only after
`RegularAnalyticLimit` verifies exact cancellation of all apparent negative
Laurent powers and equality from both real sides. It stores explicit Piecewise
values, with no Limit or integration instruction left in the coefficient.
Linear rational exceptional points of the returned limit are checked by the
same procedure. Genuine poles and unequal side limits fail. This is a local
real-limit construction; uniform joint behavior still needs the physical
integral's analyticity/bounds or a separate resolved-domain argument.
