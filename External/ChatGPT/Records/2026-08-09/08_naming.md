# Naming

## Question

We are naming the research program and software workflow currently called
FACET/FeynFacet. Its demonstrated calculation path starts from a process card
and produces exact perturbative-QCD hard functions, including their epsilon,
endpoint, and distributional dependence. It presently combines FeynArts
amplitudes, twist-2 collinear factorization, reverse unitarity, cut-preserving
partial fractions, topology construction and completion, BMHV dimensional
shifts, Kira IBP, Ratracer/FireFly coefficient reconstruction, agent-derived
analytic master integrals assisted by SubTropica, and numerical verification
with AMFlow. Evolution, PDF/FF convolution, uncertainty propagation, data
comparison, and broader phenomenology are intended later, but are not yet the
demonstrated system.

We expect to present the project in October to Larry Leinweber and the
Leinweber theoretical-physics network. Their public presentation emphasizes
long-horizon fundamental theory, ambitious ideas, collaboration across several
institutes, fellows and workshops, and stronger connections between theory and
experiment. Larry is a software entrepreneur. We therefore want a large but
scientifically defensible picture: a shared scientific instrument that makes
exact QFT calculations cumulative, reproducible, and reusable for
phenomenology, rather than merely "AI automates NLO."

Naming constraints:

1. OpenQCD is already the established Luescher/Schaefer lattice-QCD package.
2. FACET is already the name of a proposed CMS forward detector.
3. The current proof is perturbative collider QCD, so a name must not falsely
   imply that lattice QCD, hadron structure, or all nonperturbative QCD have
   already been automated.
4. The name should nevertheless leave room for future higher-order analytics,
   resummation, evolution, global phenomenology, and theory-to-data workflows.
5. It should be memorable, searchable, credible to QCD theorists, and not rely
   on a strained acronym.

Our current two-level proposal is:

- scientific initiative: QCD Foundry;
- engine/package: QCDForge;
- mission: an open analytic compiler from process definitions to exact QCD
  kernels and phenomenology-ready predictions;
- possible talk title: "QCD Foundry: A Shared Analytic Infrastructure from
  Quantum Fields to Collider Predictions."

Other candidates considered are QCD Synthesis, QCD Commons, StrongForge,
TheoryForge, QCD Nexus, and FACET-QCD.

Please act as a critical scientific adviser, not as an advertising copywriter.
Challenge the two-name architecture, rank these candidates, and propose better
alternatives where appropriate. In particular assess whether "QCD Foundry" is
too broad, whether "QCDForge" is too software-like, and whether the initiative
and package should instead share one name.

Return:

1. one recommended public initiative name;
2. one recommended software package name;
3. a one-sentence scientific mission;
4. an October talk title;
5. a 30-second spoken pitch;
6. a ranked shortlist of at most five alternatives with concise reasons; and
7. collision, searchability, and overclaiming risks for the recommendation.

The framing should be ambitious enough to interest a software entrepreneur
funding fundamental theoretical physics, while stating exactly what has and has
not yet been demonstrated.

## Pro response

The recommended structure is one public brand with a descriptive distinction between the initiative and its software, not two synonymous brands. “QCD Foundry” and “QCDForge” compete for the same conceptual space; people will not reliably remember which is the program and which is the package.

1. Recommended public initiative name
QCD Foundry

Use the formal descriptor:

QCD Foundry — Open Infrastructure for Exact Perturbative QCD

“QCD Foundry” is somewhat broad, but it is defensible at the initiative level because the ambition is larger than the current package: a shared body of amplitudes, cut topologies, IBP reductions, master integrals, boundary data, analytic-continuation information, and eventually evolution and prediction machinery.

The qualification “Exact Perturbative QCD” should appear in the subtitle, website header, repository description, and first sentence of every talk. Without that qualification, “QCD Foundry” could be read as claiming lattice QCD, hadron spectroscopy, or nonperturbative QCD more generally.

The name is well matched to the intended audience. The Leinweber network explicitly emphasizes collaboration through fellows, workshops, visiting scholars, and cross-institutional programs; its current public page lists nine participating theoretical-physics centers. Larry Leinweber’s background is in building large-scale software systems, while the foundation frames theoretical physics as a long-term investment in shared scientific capacity.

2. Recommended software package name
QCDFoundry

Public description:

QCDFoundry is the versioned software engine of the QCD Foundry initiative.

For a Wolfram Language package, the public context could eventually be:

Wolfram Language
QCDFoundry`

For repositories and documentation:

qcd-foundry
QCDFoundry

This is intentionally not a second brand. It is the same name rendered as a package identifier.

I would retire QCDForge. “Foundry” and “forge” are near-synonyms, so the proposed two-level architecture creates needless ambiguity:

Was the calculation performed by QCD Foundry or QCDForge?

Which name should appear in a paper citation?

Which term should a user search?

Does QCDForge contain QCD Foundry, or vice versa?

A single root name gives the scientific program, package, paper series, documentation, and eventual community registry one cumulative identity.

3. One-sentence scientific mission

QCD Foundry builds open, exact analytic infrastructure that turns perturbative-QCD process definitions into reusable hard-scattering kernels while preserving dimensional-regulator, cut, causal, branch, endpoint, and distributional information, with evolution and theory-to-data prediction as an explicit future direction.

“Builds” is preferable to “is” because it distinguishes the demonstrated system from the complete long-term vision. The project’s existing scientific contract already requires exact ϵ, endpoint, and distributional dependence, with numerical values used only for verification. 

AGENTS

4. October talk title
QCD Foundry: From Process Definitions to Exact QCD Kernels—and Toward Collider Predictions

This is stronger and more accurate than:

“A Shared Analytic Infrastructure from Quantum Fields to Collider Predictions.”

The proposed original title sounds as though evolution, convolution, uncertainty propagation, and data comparison are already part of the demonstrated end-to-end system. “And Toward Collider Predictions” states the intended destination without claiming it has already been reached.

A more institutional alternative is:

QCD Foundry: Building Shared Analytic Infrastructure for Perturbative Collider Theory

The first title is more memorable; the second is more conservative.

5. Thirty-second spoken pitch

Higher-order QCD calculations are still built as fragile, one-off chains. QCD Foundry is turning that chain into a shared scientific instrument. We have demonstrated a process-card-to-exact-hard-kernel workflow at NLO and key NNLO stages, preserving epsilon dependence, physical cuts, branches, BMHV information, and endpoint distributions. The goal is cumulative infrastructure: every verified topology, reduction, master integral, and boundary condition becomes reusable for the next calculation, and ultimately for evolution and theory-to-data predictions.

The important phrase is “shared scientific instrument.” It is more credible than “AI automates QCD,” and it makes the software analogy useful without reducing the project to a coding demonstration.

6. Ranked shortlist
1. Perturbative QCD Foundry

The most scientifically precise alternative.

Advantages: It removes almost all risk of implying lattice or nonperturbative automation.

Disadvantages: It is cumbersome in speech, produces the awkward identifier PerturbativeQCDFoundry, and may become unnecessarily restrictive if the project later incorporates perturbative electroweak effects or broader collider-theory components.

Best use: the formal subtitle to QCD Foundry, not the primary name.

2. QCD Synthesis

Scientifically respectable and less industrial than “Foundry.” It communicates the assembly of amplitudes, reductions, masters, and endpoint data into a complete hard function.

Its weakness is that it does not naturally denote a shared computational instrument. It sounds more like a research program or review topic than a package, and the phrase is generic enough to be difficult to own in searches.

3. QCD Commons

The strongest community-oriented name. It fits a future shared registry of amplitudes, integral families, exact master integrals, benchmarks, and phenomenological assets.

It is weaker for the present engine: a “commons” stores and shares objects but does not clearly compute them. I would reserve this phrase for a possible future public knowledge layer inside QCD Foundry:

QCD Foundry Commons: verified reusable analytic assets.

4. QCD Kernel Foundry

More precise than QCD Foundry because the demonstrated output is an exact hard-scattering kernel.

Its disadvantages are length and premature narrowing. “Kernel” can also be interpreted specifically as an evolution or matching kernel, whereas the current outputs include complete hard coefficients and master-integral data.

5. QCD Loom

Memorable and conceptually appropriate: amplitudes, cuts, reductions, differential equations, and boundary data are woven into a reusable analytic result.

It is less immediately serious to a conservative QCD audience, and “loom” already has a specialized use in high-energy theory through the “loom” construction for fishnet conformal field theories.

Candidates I would reject

QCDForge: redundant with QCD Foundry and too suggestive of a generic software-development forge.

TheoryForge: much too broad and already used by an AI venture fund, a gaming-media identity, and an academic theory-elaboration tool.

StrongForge: insufficiently explicit about QCD and already used commercially; an unrelated registered UK word mark also exists.

QCD Nexus: broad, generic, and semantically weak; it says that things are connected but not what scientific work is done.

FACET-QCD: retains the detector-name collision and sounds like a modification of the existing FACET project rather than a durable independent identity.

TheoryForge or ColliderForge: both imply a domain much wider than the present demonstration.

7. Risks and mitigations
Collision risk

A targeted search did not reveal a prominent physics package or scientific initiative already using the exact names “QCD Foundry” or “QCDFoundry.” That is a preliminary search result, not trademark clearance.

Before public launch, check at minimum:

GitHub organizations and repositories;

Wolfram Paclet Repository;

PyPI and conda-forge, even if the first package is Wolfram-based;

INSPIRE and arXiv titles;

Zenodo communities;

domain and social-handle availability;

US and international trademark databases, particularly software and scientific-service classes.

“Foundry” by itself is extremely crowded in software, AI, manufacturing, and semiconductor contexts. The protectable/searchable object is the complete phrase QCD Foundry, not “Foundry.”

Searchability risk

“QCD” also appears outside physics as “qualified charitable distribution,” and “foundry” is a common commercial term. Searchability depends on consistently using:

QCD Foundry
QCDFoundry
exact perturbative QCD
analytic hard functions

Avoid alternating among:

QCDFoundry
QCD-Foundry
QCD Forge
QCDForge
FACET
FeynFacet

after the public transition. Keep old names only in a migration note.

Overclaiming risk

The largest risk is not the word “Foundry”; it is an unqualified mission such as:

“automating QCD from quantum fields to experiment.”

The demonstrated system currently covers the analytic production of perturbative hard functions and substantial ingredients of higher-order calculations. It does not yet demonstrate:

lattice QCD;

general nonperturbative hadron structure;

arbitrary all-process NNLO automation;

resummation and evolution as a complete automatic stage;

PDF/FF convolution and uncertainty propagation;

end-to-end comparison with experimental data.

The public scope line should therefore remain:

Exact analytic infrastructure for perturbative collider QCD.

The longer horizon can then be stated separately:

Designed to connect exact kernels to evolution, phenomenology, and data.

Cultural risk with theorists

“Foundry” can sound like industrialized mass production, which may provoke resistance if the presentation centers on autonomous agents. Counter that by emphasizing:

exact analytic outputs rather than generated prose;

physical cuts, branches, and regularization schemes;

independently checkable derivations;

reusable mathematical assets;

explicit failure conditions;

human-controlled scientific contracts;

cumulative collaboration rather than replacement of theorists.

The initiative should be presented as infrastructure that lets theorists spend more time on the genuinely new physics, not as a machine that has “solved QCD.”

Final recommendation

Use one public identity:

QCD Foundry
	​


with the package:

QCDFoundry
	​


and the permanent scope descriptor:

Open Infrastructure for Exact Perturbative QCD

That combination is ambitious enough for the Leinweber audience, technically meaningful to QCD theorists, and bounded tightly enough not to claim lattice, nonperturbative QCD, or a completed theory-to-data system.
