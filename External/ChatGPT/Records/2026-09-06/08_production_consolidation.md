# Production consolidation review, 2026-09-06

Model: gpt-6-pro. Conversation: 6a9d1440-ba18-83e8-a2e8-f3ba1425bbf5.
Request message: edb431f0-b097-4264-bc2b-886b27dc68e9.
The request was delivered and answered. This review covers the architectural
description below, not a published diff or an inspection of the working code.

## Request

Review a bounded code-retirement decision for FeynFacet, a general NNLO master-integral framework. We now construct explicit finite epsilon coefficients up to ordinary-point constants from raw DEs using epsilon-order bounds, rescaling and solvable zero-order blocks. All 91 current families solved this way; strict epsilon form is optional. FLINT numerics and optional finite Taylor vectors evaluate these stored results. Physical boundary constants and general singular matching/continuation remain open.

User explicitly wants superseded code moved to backup, no backward compatibility, one general production path. Proposed retirement: old lazy requested-output coefficient operators, rational-epsilon-block lazy variation-of-constants/operator maps, old lazy boundary composition and singular-junction map adapters, CF303-specific and old physical-boundary campaigns depending on those formats, associated launchers/tests. Keep general Frobenius expansions, residue extraction, boundary-function DE derivation, exact boundary mode matching, epsilon-order mathematics, algebraic GPL/elliptic kernel conversion, and all optional canonicalization algorithms. Nothing retired is deleted or loaded; preserve exact current sources and historical mathematics in a dated backup manifest. Remove obsolete public exports and compatibility stubs.

Dependency scan shows no current finite-solution or order module uses the retiring operators. Boundary adapters are indexed by unexpanded letter sequences and are incompatible with the explicit solution format. It seems better to retire them and later connect the retained local mathematics to the same finite solver, rather than keep a second nominal production path.

Challenge this separation: is there a mathematical capability we would accidentally lose by retiring lazy composition adapters while retaining their source and the Frobenius/residue algorithms? Give a concise review; do not suggest implementing physical boundary evaluation during this cleanup. This is an uncommitted working-tree restructuring, so no published diff is available. Repository link may be obtained separately; review the description only.

## Response

The separation is justified. Retire the legacy production path, remove its exports and compatibility stubs, and keep the backup outside all loading and discovery paths. Nothing in the description requires a second production representation to preserve the current deliverable: explicit finite coefficients up to ordinary-point constants.

The qualification is that some “composition adapters” may contain mathematical operations, not merely format conversion. Retaining their sources preserves that mathematics for recovery, but does not preserve an executable capability in the active package.

The boundary to check

Three kinds of functionality deserve explicit classification before retirement:

Iterated-integral composition and transport. Path concatenation, reversal, ordered-word composition, and endpoint basis transformations can implement genuine connection-map mathematics. Retiring their legacy implementation is reasonable, but retaining kernel conversion or residue extraction does not replace these operations.

Regularized boundary semantics. Tangential-base-point prescriptions, finite-part extraction, branch conventions, and normalization of resonant logarithmic modes can reside inside otherwise format-specific adapters. Frobenius expansions determine local solution structure; they do not, by themselves, specify a normalized connection to an ordinary base point or select physical constants.

Epsilon-order propagation through maps. A transformation or matching map with epsilon poles can require coefficients beyond the requested final order. Any format-independent order-bound calculation should remain active; an implementation inseparable from legacy word maps can be archived, but its capability should not be reported as retained merely because the general order planner remains.

These are capability checks, not reasons to retain the old path. If an adapter is the sole implementation of one of these operations, record that operation as archived/unavailable in the current finite-solution interface. General singular matching and continuation are already outside the claimed production coverage, so this can be an intentional and correctly scoped retirement.

Two inexpensive acceptance checks

Check stored-artifact dependencies as well as source dependencies. An explicit finite WXF result can reference a helper through a stored kernel or reconstruction expression even when the current builder has no direct source-level dependency on that helper. Verify the reachable definitions needed to load, reconstruct, and numerically evaluate current finite artifacts in a fresh session with the backup inaccessible. This is a dependency check, not a new mathematical validation campaign.

Separate mathematical tests from obsolete-format tests. Archive tests whose purpose is the retired operator representation. Retain tests of the still-active Frobenius, residue, exact mode-matching, epsilon-order, and kernel-conversion algorithms. A useful mathematical identity should not disappear solely because its test previously entered through a legacy adapter.

The dated manifest should distinguish retired representation machinery from archived mathematical capabilities not currently connected to the finite solver. No replacement boundary implementation is required during this cleanup.

Proceed with retirement. The only misleading outcome would be to claim that keeping local Frobenius/residue routines automatically preserves the former end-to-end boundary-composition capability. Explicitly acknowledging that interface gap is preferable to maintaining an incompatible second path that nominally promises more than the current framework supports.
## Application

Retired representation-specific interfaces are removed. The backup manifest
records archived connection-map, regularization and epsilon-map capabilities
separately from retained local Frobenius/residue algorithms. Current tests
retain mathematical coverage. A fresh standalone stored-artifact dependency
audit blocks Get/Import from Private_Backup and checks reachable expression data.
