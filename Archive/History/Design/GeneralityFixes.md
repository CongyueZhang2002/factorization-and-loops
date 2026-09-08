# Package generality: consolidated fix plan (2026-08-23)

Sources: user directive (the package must be general; project data lives in
the project; accepted scope: two variables (v,w)/(s,t,u)); my pass plus
three independent audits (project-data, hidden-assumptions,
paths/defaults).  Ranked findings live in the three audit reports; this
file fixes the work split and the contracts.

## Group A - project data out of the package (agent I)
A1 TransportCharts.wl: delete TransportFamilyChartTable's literal table.
   New: package-private registry (starts empty);
   TransportFamilyChartRegister[assoc] (validated: values are catalog
   chart names or <|"RootSquares" -> {polys in the caller's source
   variables}|>); TransportFamilyChartLoad[file] :=
   Register[FamilyArtifactRead[file]].  TransportFamilyChart[family]
   unknown -> Missing["FamilyChartNotRegistered", family] (NEVER None:
   None means root-free and silently mistransports a rooted family).
   Callers updated: Scripts/family_epsform_sector.wls registers
   <ftData>/TransportFamilyCharts.wl when present (file already written
   under Results/UU_08_10_canonical/); the frame lookup treats the new
   Missing as "no frame declared" -> existing RationalIdentity fallback
   ONLY when the assembled connection is verified root-free (grep for
   radicals), else typed stop.  Other script/test callers updated
   mechanically.  TransportFamilyChart also stops hardwiring
   Global`v/w/x/y into BuildAlgebraicTransportFrame: source/chart
   variables become arguments with the current defaults.
A2 ObservableTransport.wl: "DifferentialFilePattern",
   "EpsFormFilePattern", "FamilyFromFileName" (function),
   "FamilySortKey" (default Identity) options; no nnlo_de_/CF literals
   (use $canonicalFamilyPrefix where a default is wanted); zero
   differential files -> "NoDifferentialFamiliesFound", never
   CompleteExactInventory.  Scripts/build_observable_transport_manifest.wls
   passes the project's patterns.
A3 FamilyEpsForm.wl legacy chart-alias string table -> merged into the
   registry (aliases registered from project data), deleted from package.

## Group B - roots, paths, provenance (agent I)
B1 BlockwiseTransport "Root" default Automatic -> $feynFacetRoot;
   MasterTransport fallback literal -> typed MasterTransport::root.
B2 FamilyRowGaugeResume: implementation provenance hashes ONLY package
   Private files; the driver passes its own identity via a new
   "DriverProvenance" -> <|name -> path|> option threaded from
   family_epsform_sector.wls.  Schema version bump (3); old checkpoints
   recompute (documented).
B3 $feynFacetAddonRoot (default $feynFacetRoot) and $feynFacetLoader
   (default Addon/Load/LoadFACET.wl under it), both overridable via
   Global`$FACETAddonRoot/$FACETLoader before load; the 22 Addon/ sites
   and 4 subkernel-bootstrap sites go through them.  EpsFormStrip CPU
   runner -> $feynFacetDirectory/Tools/RunWithCPUList.sh.
B4 Reduction/CoefficientStore: workspace root = option/variable
   ($FeynFacetWorkspaceRoot, default $feynFacetRoot); containment
   refusal ("outside FACET") dropped in favour of an explicit workspace
   argument; the delete guard checks the workspace root it was given.
   Reduction fingerprint payload drops absolute executable paths (hash
   fields stay); ResultDirectory equality tests -> fingerprint
   comparison (Simplification.wl:4397, Reconstruction.wl:1207).

## Group C - hardwired symbol names (agent II)
C1 DiagonalBlockClassCampaign: "Variables"/"Regulator" options through
   canonicalBlocksResolve*; class-record values preferred.
C2 canonicalBlocksBuildChart: refuse MemberQ[variables, parameter]
   (typed "ChartParameterCollides"); "ChartParameter" option on the
   diagonal retry, default a fresh private symbol.
C3 DiagonalBlockEpsForm catalog gate SymbolName v/w deleted: match via
   TransportRootSetChart + transportChartRekey (positional identify).
C4 TransportCharts extension "OutputVariables" default -> fresh private
   symbols; refuse intersection with base chart variables.  [file owned
   by agent I -- agent II specifies, agent I implements]
C5 EpsFormStrip Maple unknown heads Global`c / Global`cc<n> ->
   Unique-tagged, plus a typed refusal on collision with
   variables/regulator.
C6 familyCertificateModular signature: variables : {_Symbol, _Symbol}.

## Group D - interface hardening (agent II)
D1 Distributions/Simplification: "DistributionHeads" card key, default
   $twist2DistributionHeads.
D2 analyticContextQ: dimension rule validated by SHAPE
   (D -> a - 2 regulator, integer a, regulator _Symbol carried in the
   context) instead of identity with the package global; Gamma5Scheme
   stays required = "BMHV" for now (documented as the front-end's
   declared scope).
D3 Usage-string notes: v/w Automatic defaults, regulator name list,
   transportChartRekey as the rename path, BuildBasis normalization.
   [FeynFacet.m owned by agent I: agent II reports exact strings]
D4 Core.wl kernel/CPU fallbacks derived from $ProcessorCount with the
   present numbers as documented caps; CanonicalBlocks Directory[]
   default -> $TemporaryDirectory/FeynFacet; MasterTransport BasePoint:
   typed refusal when a letter vanishes at the chosen base.

## Out of scope now
Comments citing families/measurements (provenance, keep); the chart
catalog (general mathematics, keep; Notes strings cleaned by agent I);
quark-only hadron front-end scope (declared, documented).

## Adversarial generality tests (both agents + coordinator)
T1 t_package_generality.wls (agent I): static string-stripped scan of
   FeynFacet sources: no "CF"~digits literals outside comments, no
   /home/ or project-tree names; runtime: empty registry -> Missing
   (not None); register synthetic family "ZZ7" (chart name and
   root-square forms) -> lookups work; invalid registrations refused.
T2 t_generality_renamed_variables.wls (agent II): a synthetic class
   record and small block system written in variables {a, b} with
   regulator ep: DiagonalBlockClassCampaign options route them; the
   catalog retry matches lambda-type quadratics under the renamed
   variables (C3); chart-parameter collision refused (C2); Maple head
   collision refused (C5).
T3 Existing suites rerun by each agent for its files; coordinator runs
   the full battery before commit.
