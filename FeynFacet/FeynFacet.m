(* ::Package:: *)

If[Names["FeynCalc`$FeynCalcVersion"] === {}, Needs["FeynCalc`"]];

BeginPackage["FeynFacet`"];

ClearAll["FeynFacet`*"];
ClearAll["FeynFacet`Private`*"];

Get[FileNameJoin[{DirectoryName[$InputFileName], "Distributions.wl"}]];

DeclareScalar::usage =
  "DeclareScalar[expr] declares the scalar pieces of expr as FeynCalc variables.";

BuildBasis::usage =
  "BuildBasis[{nb,n,xhat,yhat}, assumptions] validates a light-cone basis against the package's fixed normalization GlobalBasisGram: nb.n = 1, nb.nb = n.n = 0, xhat.xhat = yhat.yhat = -1 and every other product zero, in SP and SPD alike, with SPE zero throughout. The normalization is a convention of the package and not an option: a basis in another normalization is refused by BuildBasis::relation. assumptions enters the FullSimplify of the check only.";

Build4Vec::usage =
  "Build4Vec[coordinates, basis] constructs a vector from basis coordinates.";

BuildGlobalBasis::usage =
  "BuildGlobalBasis[{nb,n,xhat,yhat}] installs and validates the global basis.";

GlobalBasisGram::usage =
  "GlobalBasisGram is the Gram matrix of {nb,n,xhat,yhat}.";

NA::usage =
  "NA marks a parton with no associated hadron quantity.";

SimplifyAssum::usage =
  "SimplifyAssum[expr, assumptions] applies Simplify with assumptions. A process card may be supplied to infer its momentum-fraction domain.";

FullSimplifyAssum::usage =
  "FullSimplifyAssum[expr, assumptions] applies FullSimplify with assumptions. A process card may be supplied to infer its momentum-fraction domain.";

BuildSimplificationContext::usage =
  "BuildSimplificationContext[setup] validates the required CoefficientKinematics block. It certifies the source and dimensionless physical chambers, mass dimensions, invertible coordinate map, positive fractions and scale, twist-2 factor, Laurent valuation, forbidden variables, and branch grammar.";

SimplifyHardCoefficients::usage =
  "SimplifyHardCoefficients[data,setup] applies one card-defined exact normalization to NLO or NNLO coefficients. Both assembled coefficients and contribution groups use the same twist-2, fraction-root, branch-preserving, forbidden-variable, and dimensionless-coordinate kernel. data may be {c1,...} with Method->\"Assembled\" or {{c11,c12,...},...} with Method->\"ContributionWise\"; Automatic infers the input form.";

ToFeynFacetForm::usage =
  "ToFeynFacetForm[expr] converts FeynCalc internal expressions to compact external FeynCalc syntax such as SP, SPD, SPE, FAD and SFAD. It preserves the dimensional meaning of scalar products and returns $Failed if an internal scalar-product object remains.";

FeynFacet`dD::usage =
  "dD[k] is the remaining D-dimensional integration measure for k.";

dFraction::usage =
  "dFraction[x] is the differential measure for a momentum fraction x.";

Cut::usage =
  "Cut[SPD[q],direction] is an oriented on-shell cut propagator. direction=1 denotes theta(q^0) delta(q^2), direction=-1 denotes theta(-q^0) delta(q^2), and Cut[SPD[q]] is shorthand for direction=1.";

PartialFraction::usage =
  "PartialFraction[expr,{k1,...}] applies ApartFF while retaining every Cut propagator and its positive-energy orientation in each returned term. With no loop momenta, PartialFraction[expr,{}] returns expr unchanged.";

BuildTopologies::usage =
  "BuildTopologies[fractions,{k1,...},setup] constructs a complete cut-aware FCTopology for every denominator family in a partial-fraction result, names it TopologyF<forward SelectedIndex>C<conjugate SelectedIndex>N<n>, prints a topology summary including cut directions, and returns the family data with CutMomenta, CutIndices and CutDirections. External momenta and on-shell rules are inferred from the denominators and setup. With no loop momenta and fractions equal to 1, it returns an empty family list.";

IdentifySafePropagator::usage =
  "IdentifySafePropagator[setup,propagator] returns True when a massless phase-space propagator Q^2 has one fixed sign, allowing zeros on the phase-space boundary, and returns $Failed otherwise.";

TopologyEquivalence::usage =
  "TopologyEquivalence[topologies,setup] finds conservative multiloop equivalence classes. Accepted mappings have exact rational unit Jacobian and preserve every propagator, cut slot, cut energy direction and the phase-space/forward/conjugate loop partition inferred from setup.";

GenerateDiagram::usage =
  "GenerateDiagram[setup] generates and returns the complete FeynArts diagram lists for Setup[\"ForwardAmplitudes\"] and Setup[\"ConjugateAmplitudes\"].";

DimensionalShift::usage =
  "DimensionalShift[integrand,families,{k1,...}] applies the topology-dependent dimensional shift to every integral family, collects the GLI coefficients without expensive simplification, prints a result summary, and returns the collected expression. With no families and no loop momenta, it returns integrand unchanged. Coefficients should be simplified after IBP and master aggregation. DimensionalShift[integrand,propagators,{k1,...},topology] applies the shift to one family.";

CommonFactorSafe::usage =
  "CommonFactorSafe[expr,{k1,...}] extracts a common prefactor while retaining scalar products that depend on loop momenta, propagators, cuts, measures and GLI master integrals in the remainder.";

CollinearFactorize::usage =
  "CollinearFactorize[config] returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Propagators,LoopMomentum}. LoopMomentum contains the remaining phase-space momenta followed by the forward and conjugate virtual-loop momenta.";

CollinearFactorizePreIBP::usage =
  "CollinearFactorizePreIBP[config] runs diagram generation, collinear factorization, partial fractioning, topology construction and dimensional shifting from one configuration Association. It returns {FractionMeasure,PreFactor,PhaseSpace,Integrand,Topologies}, where Integrand is the GLI expression and topology records contain algebraic and cut metadata. Causal prescriptions are inferred from config when needed.";

GenerateCollinearFactorizePreIBPResult::usage =
  "GenerateCollinearFactorizePreIBPResult[setup,fractionMeasure,preFactor,phaseSpace,integrand,topologies,resultDirectory] validates and packages one selected diagram-pair result. resultDirectory is optional for saved-file compatibility but required for an in-memory IBP input.";

KiraReduction::usage =
  "KiraReduction[inputs,file] identifies equivalent cut topologies, runs one exact-target Kira reduction, closes its exported rules against the solved database, writes and verifies the compact artifact, then removes the temporary Kira workspace. The temporary workspace is <workspace root>/Codex/<process>/Kira/<run>, where the workspace root is FeynFacet`Private`$feynFacetWorkspaceRoot (default the package root; set Global`$FACETWorkspaceRoot before loading to move it); a result directory outside the workspace root takes its process and run names from the last components of its own path instead of being refused. The reduction-input fingerprint covers the Kira and Fermat executable hashes and not their absolute paths, so a solved workspace stays valid when the add-on tree moves.";

KiraImportReduction::usage =
  "KiraImportReduction[inputs,file] validates and imports the matching solved Kira workspace, closes its exact reduction rules, writes and verifies the compact artifact, then removes the workspace. It never reruns Kira.";

CoefficientSimplification::usage =
  "CoefficientSimplification[inputs,kiraFile] reconstructs exact master coefficients from one saved diagram-pair set and the KiraResult.wl artifact path by finite-field reconstruction. CoefficientSimplification[projectDirectory,cardName,resultFolder] automatically loads one saved diagram-pair set and KiraResult.wl, reconstructs the coefficients and writes CoefficientResult.wl. resultFolder may be Automatic. The option \"NormalizationKernels\" controls the Mathematica workers; \"Threads\" controls FireFly. The Setup key \"DistributionHeads\" declares the collinear-distribution heads of the channel (default the twist-2 quark set of FeynFacet/Distributions.wl) and exactly those heads are treated as distributions. A saved artifact is matched to its inputs by the analytic-context fingerprint rather than by the absolute result directory.";

ReconstructCoefficients::usage =
  "ReconstructCoefficients[traceDirectory] reconstructs the master coefficients of one emitted finite-field trace and returns the production CoefficientResult. Columns whose expression file is below \"BundleBelowBytes\" share one trace; larger columns run solo, ascending by size. \"SeriesVariable\" -> Automatic truncates the reconstruction to a Laurent series in the context regulator through \"SeriesOrder\", None reconstructs the full rational form. A completed result file carrying its DONE marker is never redone. \"VerifySlices\" and \"VerifySeriesOrders\" add exact boundary checks, and every job appends its probe count to <traceDirectory>/progress. The stored Kira artifact is matched to the pair inputs by card name and analytic-context fingerprint, not by the absolute result directory.";

ReconstructionStatus::usage =
  "ReconstructionStatus[traceDirectory] reports the phase, probe count, measured probe rate and estimated remaining time of every reconstruction job in traceDirectory, reading the progress files a running job appends to. It is meant to be called from a second kernel while the reconstruction runs.";

CoefficientProgressPanel::usage =
  "CoefficientProgressPanel[] displays the current coefficient-reconstruction stage, target progress, elapsed time and estimated remaining time.";

$CoefficientSimplificationProgress::usage =
  "$CoefficientSimplificationProgress stores the current coefficient-reconstruction progress data.";

DecomposeFamilyBlocks::usage =
  "DecomposeFamilyBlocks[deDirectory] decomposes every family differential-equation artifact in deDirectory into the strongly connected components of its dependency graph. It returns the block list, the per-family block-lower-triangularity certificate that licenses solving a family block by block, and the block-dimension histogram. \"FilePattern\" selects the artifacts, \"ZeroTest\" chooses structural or algebraic vanishing of a connection entry, and \"OutputDirectory\" writes blocks.wl and decomposition.wl atomically. \"Variables\" -> Automatic means Global`v and Global`w, and \"Regulator\" -> Automatic detects the regulator by name among eps, Eps, epsilon, Epsilon and ep, failing with DecomposeFamilyBlocks::regulator when the artifact names none of them.";

BuildFamilyDifferentialSystemBlockDecomposition::usage =
  "BuildFamilyDifferentialSystemBlockDecomposition[system,systemReference] derives the irreducible diagonal blocks of a V2 FamilyDifferentialSystem as strongly connected components of the directed connection-dependency graph and orders them so the connection is block lower triangular. The default validation classifies zero entries by bounded probabilistic finite-field sampling; \"ValidationMethod\" -> \"CharacteristicZeroSymbolicIdentity\" performs exact symbolic zero tests.";

FamilyDifferentialSystemBlockDecompositionQ::usage =
  "FamilyDifferentialSystemBlockDecompositionQ[record,system] re-evaluates the recorded exact or finite-field nonzero-pattern evidence and checks that the V2 record contains precisely the strongly connected components, partitions the original master-integral basis rows, and is ordered block lower triangular.";

ConstructDiagonalBlockDLogEpsilonForm::usage =
  "ConstructDiagonalBlockDLogEpsilonForm[system,coefficientPresentation,blockRows] constructs one schema-V2 DiagonalBlockDLogEpsilonForm. It extracts blockRows in their declared order and revalidates the family coefficient presentation. Automatic construction runs DiagonalBlockEpsForm on the original source-variable block, including its block-local rationalizing-chart search, but asks only for a reconstruction-stabilized candidate; that candidate is composed into the selected family presentation before the family-block equation is derived. CandidateDiagonalBlockDLogEpsilonForm may instead supply either the V2 mathematical fields or a current certified DiagonalBlockEpsForm result; externally supplied legacy results must carry their exact gate. The default ProbabilisticFiniteFieldSampling validation evaluates invertibility and both basis-transformation equations at stored points modulo primes disjoint from finite-field reconstruction; every declared square-root sign sheet is checked. CharacteristicZeroSymbolicIdentity is an explicit development option. DiagonalBlockEpsFormOptions passes bounded construction options, while the candidate-return and chart-routing options are controlled by this constructor.";

DiagonalBlockDLogEpsilonFormQ::usage =
  "DiagonalBlockDLogEpsilonFormQ[record,system,coefficientPresentation] re-pulls the selected rows of the V2 FamilyDifferentialSystem through the validated coefficient presentation and replays the record's stored finite-field points and every declared square-root sign sheet (or redoes an explicitly requested symbolic development check). It validates the basis-transformation equation, invertibility, constant residues, and regulator-free letters rather than accepting a stored flag as evidence.";

ClassifyBlocks::usage =
  "ClassifyBlocks[blocks] quotients a block set by connection equivalence: basis permutation composed with an optional v<->w relabelling. Blocks are bucketed by permutation-invariant multisets and then matched exactly, so every class member carries an explicit permutation and swap that reproduce its connection matrices from the representative entry by entry. Classes are keyed by the content address of their exact orbit key; integer ClassID labels are a convenience only.";

CanonicalizeClasses::usage =
  "CanonicalizeClasses is RETIRED (overhaul 2026-09-02): the CANONICA class ladder is retired; DiagonalBlockClassCampaign (finite-field route) canonicalizes classes; implementation in Private_Backup/CanonicalBlocks.wl; the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

ValidateCanonicalForm::usage =
  "ValidateCanonicalForm[form] certifies an epsilon-form by exact dlog reconstruction: it extracts the alphabet, requires every residue matrix to be constant, and requires the stored matrices to be reproduced exactly as eps times the sum of residues against dlog of the letters. form may be a canonical-form record, a form file, or matrices with their variables. Any stored \"Validated\" flag is ignored, because CANONICA reports a failed sector as {False,{partial,partial}}, which has the same shape as a success.";

CanonicalBlocksStatus::usage =
  "CanonicalBlocksStatus[formDirectory] prints one greppable line per stored canonical-form file giving class, content address, dimension, ansatz degree and frame, and a closing summary. With \"Classes\" it also lists the classes that have no form yet, and with \"Validate\"->True it re-runs ValidateCanonicalForm on every stored form. It is meant to be called from a second kernel while a campaign runs.";

AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks::usage =
  "AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[system,coefficientPresentation] re-expresses a two-variable family differential system using either a RationalizingParametrization or SquareRootGeneratorsAndQuadraticRelations, composes the certified diagonal-block basis transformations, and re-derives every transformed diagonal connection block. The result has epsilon-form diagonal blocks and general lower off-diagonal blocks; it does not claim that the whole family is in epsilon form. The assembly verifies the block transformations, their inverses, the transformed connection equation, block lower-triangularity, and flatness according to the selected check level. The \"Blocks\" option must give explicit {rows,provider} diagonal-block specifications.";

LibraFamilyEpsForm::usage =
  "LibraFamilyEpsForm is RETIRED (overhaul 2026-09-02): the whole-family Libra construction is kept, unloaded, in FeynFacet/Private_Backup/LibraEpsForm.wl. Calls return <|\"Status\" -> \"RouteRetired\", ...|>. The family completion runs through the per-sector epsilon-form driver, FactorFamilyRegulatorDependence, and ValidateFamilyDLogEpsilonForm.";

RationalizingParametrizationCatalog::usage =
  "RationalizingParametrizationCatalog[] returns the catalogued forward rational parametrizations and their displayed rationalized square roots. Catalog membership does not assert a rational inverse or birationality.";

VerifyRationalizingParametrization::usage =
  "VerifyRationalizingParametrization[parametrization] verifies rationality of the forward substitution and displayed roots, their square-root identities, a nonzero Jacobian, and declared parent compositions. It does not certify a rational inverse or birationality.";

BuildSquareRootGeneratorsAndQuadraticRelations::usage =
  "BuildSquareRootGeneratorsAndQuadraticRelations[rootSquares,{v,w},{x,y}] records square-root generators after the identity substitution v=x,w=y and verifies their quadratic relations. It does not assert square-class independence, a degree-2^r function field, or Galois conjugacy.";

FamilySquareRootGeneratorCensus::usage =
  "FamilySquareRootGeneratorCensus[familySystem,rootData] classifies the square-root generators occurring in every nonzero off-diagonal connection block. It reports generator-count statistics and any radical bases not generated by the declared quadratic relations.";

LookupCataloguedRationalizingParametrizationForRoots::usage =
  "LookupCataloguedRationalizingParametrizationForRoots[rootSquares] returns the least complicated catalogued rationalizing parametrization containing the requested radicands, None for an empty list, or Missing[\"NoCataloguedRationalizingParametrization\",...] for a catalog miss. A miss is not a nonexistence theorem.";

SolveOffDiagonalBasisTransformationBlock::usage =
  "SolveOffDiagonalBasisTransformationBlock[{E,C,B},{v,w},eps,coefficientPresentation] solves the off-diagonal basis-transformation block D in dD = eps E D - eps D C + B. It uses a catalogued rationalizing parametrization when available and otherwise dispatches to the declared square-root-generator solver. A result is accepted only after the defining equations and any coordinate reexpression are verified. \"BasisTransformationReexpressionMode\" is \"Exact\" (default) or \"FiniteFieldReconstruct\"; unsupported modes are refused with status \"InvalidBasisTransformationReexpressionMode\".";

ComposeRationalizingParametrizations::usage =
  "ComposeRationalizingParametrizations[base,rootSquare,rules,newVariables] composes a verified forward rationalizing parametrization with a rational parametrization of one additional square root and verifies the composed forward map.";

ExtendRationalizingParametrization::usage =
  "ExtendRationalizingParametrization[base,rootSquare] asks RationalizeRoots for candidate forward parametrizations of the pulled-back square root and returns the least complicated verified candidate. Failure to find one is not a nonexistence theorem.";

RegisterFamilyRootData::usage =
  "RegisterFamilyRootData[association] registers project-supplied per-family root data in an initially empty package registry. Each family is associated with either a catalogued rationalizing parametrization name or a list of source radicands for explicit square-root generators and quadratic relations.";

LoadFamilyRootData::usage =
  "LoadFamilyRootData[file] reads and registers a family-to-root-data association from a Wolfram Language artifact.";

FamilyRootData::usage =
  "FamilyRootData[family] returns the registered rationalizing parametrization or square-root-generator record for a family, or Missing[\"FamilyRootDataNotRegistered\",family]. Optional source and parametrizing variables re-express the same data without changing its mathematical content.";

NormalizeEpsFormAffineSample::usage =
  "NormalizeEpsFormAffineSample[sample,columns,p] fixes an affine finite-field solution so that its selected nullspace-coordinate block is the identity and its particular solution vanishes in those coordinates. It returns the normalized particular vector and nullspace basis modulo the prime p.";

ReconstructOffDiagonalBasisTransformationBlock::usage =
  "ReconstructOffDiagonalBasisTransformationBlock[record,modularData] combines modular regulator interpolations by Chinese remaindering and rational reconstruction, reconstructs the off-diagonal basis-transformation block and constant dlog residue matrices, and accepts them only after the exact Pfaffian equations and structural dlog conditions hold.";

VerifyOffDiagonalBasisTransformationBlock::usage =
  "VerifyOffDiagonalBasisTransformationBlock[record,solution] checks the dlog structural conditions and substitutes the proposed off-diagonal basis-transformation block and residue matrices into both unspecialized Pfaffian equations.";

FactorFamilyRegulatorDependence::usage =
  "FactorFamilyRegulatorDependence[{Ax, Ay}, {x, y}, eps] finds one constant (chart-independent) transformation T(eps) that makes the dlog-form family connection eps-factored, T^-1 A T = eps (eps-free), with Libra FactorDependence on exact rational samples of A/eps; the unsampled symbolic identity is the acceptance test. Returns Status \"OK\" with Transformation, Inverse and the new Connection, \"AlreadyEpsFactored\" (identity), \"NotFactored\" with the attempts, or \"RegulatorFactorizationDeadlineExpired\" with the Stage it stopped at. Replaces the per-sector CANONICA TransformDlogToEpsForm step (2026-08-22). Options: \"TimeLimit\" (900, one subcall), \"Deadline\" (Infinity; an ABSOLUTE AbsoluteTime[] budget for the whole stage, checked at every stage boundary and capping every bounded subcall), \"UseFermat\", \"Verbose\".";
FactorFamilyRegulatorDependenceInFrame::usage =
  "FactorFamilyRegulatorDependenceInFrame[{Ax, Ay}, {x, y}, eps, frame] is FactorFamilyRegulatorDependence for a connection in a multiquadratic identity frame: the roots present in the connection are classified against the frame's root list, the connection is pulled back to the smallest catalogued rational chart for that root set (TransportRootSetChart), the constant T(eps) is found there and applied in the source frame, where the eps-factorization and the inverse identity are verified exactly. Status \"NoRationalChart\" means the root set has no joint rational chart AND FactorFamilyRegulatorDependenceMultiquadratic, which is attempted next, also refused (its diagnostics travel in \"MultiquadraticFactorization\"): the caller must stop (typed) rather than continue with regulator-dependent residues. Rational connections go straight to FactorFamilyRegulatorDependence.";
FactorFamilyRegulatorDependenceMultiquadratic::usage =
  "FactorFamilyRegulatorDependenceMultiquadratic[{Ax, Ay}, {x, y}, eps, roots] finds the constant T(eps) IN THE GRADED ALGEBRA Q(x,y)[r_1,...,r_k]/(r_i^2-q_i), for a root set that has no joint rational chart (for three independent quadratic roots the triple cover is a K3 surface, which carries no global rational parameterization). T lies in grade 0, so conjugation acts grade by grade: the connection is decomposed into its 2^k grade components -- ordinary rational matrices -- and Libra FactorDependence is run on exact rational samples of every component, the same ExactRationalSamples strategy as the rational route, per grade. Acceptance is exact and made in the algebra: every grade of T^-1 A T is eps-factored identically in (x, y), T T^-1 = 1 exactly, and the composed algebraic connection is spot-checked against the direct product with the r-symbol zero test; a sign-sheet corroboration at fresh primes evaluates the conjugated object on all 2^k embeddings of a split point. Numeric square classes introduced by radical denesting (Sqrt[2]) are carried as extra graded generators, so no Together decides an equality on a non-canonical form. COMPLETENESS BOUNDARY: the linear solve is run on the ordinary rational grade matrices and therefore admits only a T with entries in Q(eps). The grade-zero argument is exact for the non-isotrivial roots, whose squares depend on the chart variables, but a valid constant transformation may carry a numeric square class (Sqrt[2] eps is constant in {x,y} and has nonzero numeric-root grade), so over a constant field with numeric classes this is a SUFFICIENT solver, not a complete one; a failure with numeric classes present returns the narrowed typed refusal \"ConstantFieldRestriction\" (with the generators responsible and Complete -> False) rather than the unqualified \"NotFactored\". Returns Status \"OK\", \"AlreadyEpsFactored\", or a typed refusal (\"GradeDecompositionFailed\", \"NotFactored\", \"ConstantFieldRestriction\", \"GradeNotEpsFactored\", \"ExactGradeCheckTimedOut\", \"GradedRankTooLarge\", \"RegulatorFactorizationDeadlineExpired\", ...). Options: \"TimeLimit\", \"Deadline\" (Infinity; an ABSOLUTE stage budget checked before and after the grade decomposition, at every point-ladder rung, at the exact check, and before the spot checks and the corroboration, which are evidence stages and are skipped -- recorded in \"DeadlineSkippedStages\" -- rather than discarding an accepted exact factorization), \"UseFermat\", \"PointLadder\", \"GatePoints\", \"ExactCheckTimeLimit\", \"CorroborationPrimes\", \"RoundTripSpotChecks\", \"SpotCheckTimeLimit\", \"Verbose\".";
AnalyzeOffDiagonalBlockEpsilonFormObstructions::usage =
  "AnalyzeOffDiagonalBlockEpsilonFormObstructions[record] analyzes the regulator expansion of one off-diagonal block equation. At each order it tests closedness, rational primitives, and constancy of residues along polar curves, returning the first typed obstruction found or \"NoObstructionToOrder\". The result is relative to the tested truncation and ansatz; it is not a general nonexistence theorem.";

SolveOffDiagonalBasisTransformationBlockFiniteField::usage =
  "SolveOffDiagonalBasisTransformationBlockFiniteField[record] solves one rational two-variable off-diagonal basis-transformation block by finite-field sampling, regulator interpolation, Chinese remaindering, and rational reconstruction. It returns a solution only after both unspecialized Pfaffian equations vanish exactly.";

ExactlyValidatedFamilyDLogEpsilonFormQ::usage =
  "ExactlyValidatedFamilyDLogEpsilonFormQ[record] returns True only when a FamilyDLogEpsilonForm with Status \"FamilyDLogEpsilonFormValidated\" carries characteristic-zero symbolic validation of its basis-transformation inverse, connection-transformation equation, epsilon factorization, constant-residue dlog representation, coefficient-presentation relations, and flatness. Validation strength is read from Validation, not from Status.";

ValidatedFamilyDLogEpsilonFormQ::usage =
  "ValidatedFamilyDLogEpsilonFormQ[record] returns True when a FamilyDLogEpsilonForm with Status \"FamilyDLogEpsilonFormValidated\" carries internally consistent exact or probabilistic evidence for its defining equations. Validation strength is read from Validation; probabilistic evidence is never reported as exact, regardless of the number of square-root generators.";

ValidateFamilyDLogEpsilonForm::usage =
  "ValidateFamilyDLogEpsilonForm[record,system] re-derives the defining equations of a candidate family dlog epsilon form from the differential system, coefficient presentation, ordered diagonal blocks, basis transformation, letters, and constant residue matrices. It returns a non-persisted FamilyDLogEpsilonFormValidationResult; every accepted result has Status \"FamilyDLogEpsilonFormValidationPassed\". The script-side BuildValidatedFamilyDLogEpsilonFormV2 constructor is the sole boundary that turns this result into a complete persisted FamilyDLogEpsilonForm. IdentityMethod -> \"Symbolic\" records characteristic-zero validation; \"RandomPoints\" records random-rational-point evidence; and \"Modular\" records Method \"ProbabilisticFiniteFieldSampling\" for both rational and square-root coefficient presentations. The result contains no content digests or settings-dependent acceptance conditions.";

FamilyArtifactRead::usage =
  "FamilyArtifactRead[file] reads one Wolfram Language artifact with the context path restricted to System` and Global`, so that symbols in the file never resolve into a package context loaded earlier in the session (in particular CANONICA`). Every campaign or worker read of a stored record or differential system must use this function. Returns $Failed when the file is missing or unreadable. FamilyArtifactRead[file, context] reads with the guard context explicit (default \"Global`\"); evaluation-time messages no longer discard a valid artifact, parser failures stay typed, and the collected messages are in FeynFacet`Private`$familyArtifactReadMessages (2026-08-23).";

FamilyArtifactWrite::usage =
  "FamilyArtifactWrite[value,file] writes one artifact atomically: Put to a temporary name in the target directory followed by RenameFile. Returns the file path.";

DiagonalBlockEpsForm::usage =
  "DiagonalBlockEpsForm[{Ax,Ay},{x,y},eps] constructs and certifies the epsilon form of one irreducible diagonal block in a rational two-variable chart: one spectator slice is normalized by Lee balances and factored (Libra), which fixes the constant residues of every letter depending on x; the x-equation d_x T = Ax T - T Bx is then a homogeneous linear system for a rational T with letter denominators and is solved by finite-field sampling, regulator interpolation, Chinese remaindering and rational reconstruction; the pure-y residues and the rational scalar basis rescaling are read off exactly from the y-direction; the default and only legacy acceptance is the exact two-variable gate. Returns an Association with Status \"Certified\", Transformation, Letters, Residues, EpsForm and stage timings. \"ReturnCandidateBeforeCertification\" -> True is the V2 constructor's internal route: it returns Status \"CandidateConstructed\" without the exact acceptance gate after finite-field reconstruction has stabilized across successive primes. The block's variables and regulator are the symbols given, whatever they are named. \"ChartRetry\" (default True) retries a block with exactly one regulator-free irreducible quadratic denominator in a chart: the conic parametrization of CanonicalBlocks and the catalog chart of TransportCharts whose root square is that quadratic, matched positionally by TransportRootSetChart and rekeyed to the block's own variables, so the retry never depends on the variables being named v and w. \"ChartParameter\" is Automatic, which is Global`t unless t is one of the block's own symbols and a fresh package-private symbol otherwise; a parameter equal to one of the block's variables is refused with Status \"ChartParameterCollides\".";

DiagonalBlockSliceEpsForm::usage =
  "DiagonalBlockSliceEpsForm[{Ax,Ay},{x,y},eps] computes the constant residues of the block's epsilon form on a generic rational slice y = y0 by Lee balances and maps every slice locus to a letter of the block. The default engine \"NumericalEps\" specializes the regulator to a fixed rational number (1/101) before the balance chain -- exact arithmetic over Q(x); the residue tuple is then M_a(e)/e, a constant conjugate of the true one, and is brought to a canonical small-height frame. \"Engine\" -> \"Symbolic\" keeps eps symbolic and finishes with Lee's linear factor-out step. Returns SliceLetters with SliceResidues (constant matrices), the balance path and timings.";

SolveDiagonalBlockBasisTransformationFiniteField::usage =
  "SolveDiagonalBlockBasisTransformationFiniteField[{Ax,Ay},{x,y},eps,sliceData] solves the diagonal-block basis-transformation equation d_x T = Ax T - T Bx by finite-field sampling, regulator interpolation, Chinese remaindering, and rational reconstruction; by default the result is accepted only after the exact equation holds. \"ReturnCandidateBeforeExactEquationCheck\" -> True is the V2 constructor's internal route and returns an unaccepted CandidateConstructed only after two successive prime-extended lifts give the same canonical rational matrix.";

CompleteDiagonalBlockEpsForm::usage =
  "CompleteDiagonalBlockEpsForm[{Ax,Ay},{x,y},eps,solve] takes a transformation solving the x-equation and determines exactly, from T^-1 Ay T - T^-1 d_y T, the constant residues of the pure-y letters and the rational scalar basis rescaling with integer exponents that removes the remaining scalar dlog terms.";

CertifyDiagonalBlockEpsForm::usage =
  "CertifyDiagonalBlockEpsForm[{Ax,Ay},{x,y},eps,T,letters,residues] is the exact gate: the source connection pushed through T equals eps Sum_a R_a dlog phi_a entrywise in both variables, the residues are constant, the letters are regulator-free, the form is flat, and T is invertible.";

DiagonalBlockClassCampaign::usage =
  "DiagonalBlockClassCampaign[classes,directory] runs DiagonalBlockEpsForm over class representatives (a list of class records or the path of classes.wl) and writes one ledger record per class in the CanonicalizeClasses schema (Transformation, EpsForm, Variables, Chart, Frame, Method, Seconds, Validated). Options: \"Kernels\" (subkernel pool under one main kernel), \"Overwrite\", \"TimeConstraint\" per class, \"Fallback\" -> \"CANONICA\" to try the CANONICA ladder when the finite-field route does not certify, \"CanonicaValidation\" to re-check every record with ValidateCanonicalForm. \"Variables\" and \"Regulator\" are Automatic: each class record's own \"Variables\"/\"Regulator\" is preferred, then the regulator is detected from the representative matrices by name (eps, Eps, epsilon, Epsilon, ep), then Global`v, Global`w and Global`eps; an explicit option overrides the record. A record that declares other than two variables gets a failure record with Status \"ClassVariablesNotTwoSymbols\" instead of being solved as a pair.";

DiagonalBlockLetters::usage =
  "DiagonalBlockLetters[{Ax,Ay},{x,y},eps] returns the regulator-free irreducible denominator factors of the block (the candidate letters) and the regulator-dependent ones (apparent singularities).";

FamilyEpsilonFormRecord::usage =
  "FamilyEpsilonFormRecord[record] normalizes one family epsilon-form record to the standard schema: the diagonal-block list is converted to plain index lists (the annotated {indices, classId} layout is accepted), verified to flatten to a basis permutation, and the required analytic fields are checked for presence. Returns the normalized record, or an Association whose \"Status\" names the defect.";

FindRequestedOutputIteratedIntegralCoefficientInputFiles::usage =
  "FindRequestedOutputIteratedIntegralCoefficientInputFiles[epsilonFormDirectories,differentialSystemDirectory] finds family differential-system files and candidate family dlog-epsilon-form files for a requested-output iterated-integral coefficient-operator campaign. File patterns and the file-name-to-family function are explicit options.";

ClassifyRequestedOutputIteratedIntegralCoefficientInputs::usage =
  "ClassifyRequestedOutputIteratedIntegralCoefficientInputs[inputFiles] reads the candidate family dlog-epsilon-form files and records whether each is validated and whether its validation is exact. It does not claim to validate the associated family differential-system file.";

SelectValidatedFamilyDLogEpsilonFormInputs::usage =
  "SelectValidatedFamilyDLogEpsilonFormInputs[classifiedInputs,valuationsFile] selects the first validated family dlog-epsilon form per family in directory-priority order and associates its differential-system, master-integral coefficient-valuation, and optional card files. The result explicitly reports missing, rejected, and additional validated candidates.";

WriteRequestedOutputIteratedIntegralCoefficientInputSummary::usage =
  "WriteRequestedOutputIteratedIntegralCoefficientInputSummary[selection,inputTableFile] writes the selected requested-output coefficient-operator inputs as a TSV file and optionally writes the complete selection summary as Wolfram Language data.";

ChooseRegularBasePointAndFirstPathParameterScale::usage =
  "ChooseRegularBasePointAndFirstPathParameterScale[familyDLogEpsilonForm] selects a deterministic regular rational base point and a nonzero affine scale for the first path parameter. For a square-root presentation it first seeks a base point at which every declared square root is a nonzero rational number. It fixes no physical analytic-continuation branch.";

ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs::usage =
  "ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs[familyDLogEpsilonForm,requirements] constructs a lazy iterated-integral coefficient operator for a validated V2 MasterIntegralEpsilonOrderRequirements record. Required masters are resolved against OriginalMasterIntegralBasis, and requested rows retain that original physical-basis ordering. MasterIntegralEpsilonOrderRequirementsReference must locate the persisted requirements artifact and carry matching MathematicalInputReferences. It imposes the required vanishing Laurent coefficients, derives the allowed boundary-constraint subspace, and retains either the exact operator chain or a modularly validated compressed representation. RegularBasePointAndFirstPathParameterScale is a constructor option rather than part of the mathematical epsilon-order requirements. Exact and probabilistic validation strength is recorded in Validation rather than in the result status.";

ComputeTruncatedLocalFrobeniusExpansion::usage =
  "ComputeTruncatedLocalFrobeniusExpansion[connection,spec] computes a finite local Frobenius prefactor H(rho,eps) and connection residue R for an epsilon-form connection, so that the retained local solution is H(rho,eps) rho^(eps R) c. spec gives Variable, Regulator, LocalExpansionPoint, and optionally LocalVariable, LocalDirection (+1 or -1), and FixedRules; options set the retained local and epsilon orders. The result records PointType as OrdinaryPoint or RegularSingularPoint. LocalDirection defines variable=LocalExpansionPoint+LocalDirection rho and includes the differential Jacobian. Non-epsilon-form or non-Fuchsian local connections are refused with typed statuses.";

TransformTangentialConnectionToNormalResidueEigenbasis::usage =
  "TransformTangentialConnectionToNormalResidueEigenbasis[normalResidue,tangentialConnection,spec] transforms a normal connection residue and the tangential connection to a supplied moving eigenbasis of the normal residue, including the derivative of that basis. spec gives TangentialVariable, Regulator, NormalResidueEigenbasis, and LocalExponents. The eigenbasis may be rational in the tangential variable and regulator; its columns must diagonalize the normal residue. The result contains TangentialConnectionInEigenbasis, EqualExponentSectors, and the integer/regulator split of every local exponent. Coupling between unequal exponent sectors is refused.";

ConstructBoundaryFunctionDifferentialSystem::usage =
  "ConstructBoundaryFunctionDifferentialSystem[modeMatching,inducedConnection] constructs the differential system obeyed by the free Frobenius coefficients along a positive-dimensional physical boundary stratum. It includes the moving normal-basis term, retains mixing inside degenerate or Jordan sectors, and validates normal-residue horizontality, invariance of the boundary-mode subspace, and tangential flatness. A supplied BoundaryFunctionConnectionMatrices option avoids characteristic-zero derivation when the connection was reconstructed from finite-field images.";

BoundaryFunctionDifferentialSystemQ::usage =
  "BoundaryFunctionDifferentialSystemQ[result] checks the structural and mathematical-validation contract of a V2 BoundaryFunctionDifferentialSystem.";

TangentialBoundaryEvolutionOperatorQ::usage =
  "TangentialBoundaryEvolutionOperatorQ[result] checks the V2 square evolution operator for the boundary-function equation c(t,eps)=U(t,t0;eps).c(t0,eps), represented as iterated-integral coefficient maps indexed by epsilon order.";

ComposeBoundaryFunctionSolutionMapWithTangentialEvolution::usage =
  "ComposeBoundaryFunctionSolutionMapWithTangentialEvolution[boundaryFunctionSolutionMap,evolution] composes a requested-output solution map whose columns are boundary-function epsilon coefficients with their tangential evolution from a declared base point. It returns a map whose columns are boundary-constant epsilon coefficients and retains the tangential iterated-integral letter sequence as a separate path segment.";

ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution::usage =
  "ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution[finiteFieldBoundaryFunctionMap,tangentialEvolution] composes sparse support while retaining the finite-field and tangential coefficient operators as ordered, unmultiplied factors.";

FactorizedFiniteFieldBoundarySolutionCompositionQ::usage =
  "FactorizedFiniteFieldBoundarySolutionCompositionQ[result] re-derives and validates a factorized finite-field boundary-solution support composition without performing a characteristic-zero lift or Cartesian path expansion.";

ConstructBoundaryFunctionEpsilonCoefficientEquations::usage =
  "ConstructBoundaryFunctionEpsilonCoefficientEquations[system,{emin,emax}] expands a validated boundary-function differential system in the dimensional regulator and returns the coupled differential equations and the precise boundary-function epsilon orders they require.";

MatchBoundaryAsymptoticsToFrobeniusModes::usage =
  "MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,basisTransformation,spec,realizations] matches declared physical-limit asymptotics to local Frobenius modes after applying the basis transformation and truncated local prefactor. spec must declare BoundaryDomain as either a PhysicalBoundaryPoint or a PhysicalBoundaryStratum with its TangentialVariables; the result therefore distinguishes boundary constants from boundary functions. A relation between a physical limiting variable and the local expansion coordinate is recorded explicitly, including any required logarithm branch.";

DegenerateResidueEigenspaceBasis::usage =
  "DegenerateResidueEigenspaceBasis[mode,modes] returns the echelon basis and dimension of the degenerate normal-residue eigenspace containing mode. Degeneracy alone does not imply a relation among boundary constants or functions; such a relation must be supplied separately.";
ConstructMasterIntegralSolution::usage =
  "ConstructMasterIntegralSolution[boundaryFunctionMap,tangentialEvolution] constructs a V2 master-integral solution in terms of boundary constants as an exact ordered sparse coefficient-operator product, without expanding the Cartesian product of the two path segments. ConstructMasterIntegralSolution[family,\"InputFiles\"->files] constructs the point-boundary form as L_T(target).C_canonical(path).b from a validated family dlog epsilon form, requested-output iterated-integral coefficient operator, and boundary-asymptotic mode matching. DemandCoverage and BoundaryDataStatus report independent properties of either result.";
MasterIntegralSolutionQ::usage =
  "MasterIntegralSolutionQ[result] validates the stored factors, exact coordinate interfaces, demand coverage, and sparse dependency data of a V2 MasterIntegralSolution without reloading files or expanding a Cartesian product of letter sequences. For a point-boundary solution it also checks the stored family-differential-system and master-integral epsilon-order-requirements references against the factorization interface.";
DeriveMasterIntegralEpsilonOrderRequirements::usage =
  "DeriveMasterIntegralEpsilonOrderRequirements[request,valuations] derives the required epsilon orders of every master integral from explicit V2 hard-function epsilon-order and master-coefficient valuation records.";
MasterIntegralEpsilonOrderRequirementsQ::usage =
  "MasterIntegralEpsilonOrderRequirementsQ[result] re-derives and validates a V2 MasterIntegralEpsilonOrderRequirements record from its stored mathematical inputs.";
ConstructBoundarySelectorMatrices::usage =
  "ConstructBoundarySelectorMatrices[modeMatching,boundaryData,{emin,emax}] constructs the rational matrices that select the required Frobenius-mode coefficients at each epsilon order. The result preserves the explicitly declared boundary domain and reports whether its columns label boundary-constant or boundary-function coefficients.";

ConstructBoundaryValueVectorFromConstants::usage =
  "ConstructBoundaryValueVectorFromConstants[modeMatching,boundaryConstantData,{emin,emax}] constructs the boundary-value vector at a physical boundary point. It refuses boundary-stratum input rather than treating tangential functions as constants.";

ConstructBoundaryValueVectorFromFunctions::usage =
  "ConstructBoundaryValueVectorFromFunctions[modeMatching,boundaryFunctionData,{emin,emax}] constructs the boundary-value vector on a positive-dimensional physical boundary stratum and records its tangential function space. It refuses point-boundary input.";

BoundaryConstantEpsilonCoefficient::usage =
  "BoundaryConstantEpsilonCoefficient[id,order] is an inert exact placeholder for the coefficient of epsilon^order in the boundary constant identified by id.";

BoundaryFunctionEpsilonCoefficient::usage =
  "BoundaryFunctionEpsilonCoefficient[id,order][t1,...] is the coefficient of epsilon^order in the boundary function identified by id, evaluated at the tangential coordinates t1,... of a physical boundary stratum. Its coordinate dependence is retained so that the induced tangential differential equation acts on it.";

FormalChenIteratedIntegral::usage =
  "FormalChenIteratedIntegral[letterSequence,{variable,lowerLimit,upperLimit},curve,curvePointValues] is an inert Chen iterated integral. The letter sequence is ordered outermost first; curve is None for multiple polylogarithms and a square-free quartic for elliptic multiple polylogarithms. An optional fifth argument records a tangential-base-point prescription.";
AlgebraicMarkedPoint::usage =
  "AlgebraicMarkedPoint[coefficients,index] denotes an indexed marked point defined as a root of a polynomial whose ascending coefficient list may contain spectator kinematic variables.";
IteratedIntegralKernel::usage =
  "IteratedIntegralKernel[label,variable,curve] returns the coefficient of the integration one-form represented by a GPLPole, GPLFactor, E4Pole, E4Factor, E4Omega0, E4OmegaInf or E4Eta2 label.";
ExpandIteratedIntegralLetterSequence::usage =
  "ExpandIteratedIntegralLetterSequence[letterSequence,variable,curve,definitions] expands one requested sequence of factor or composite letters into marked-point letters for multiple or elliptic multiple polylogarithms.";
ComputeConnectionResidueAtLocalExpansionPoint::usage =
  "ComputeConnectionResidueAtLocalExpansionPoint[letters,residueMatrices,variable,localExpansionPoint] computes the exact simple-pole connection residue directly from aligned sparse square or rectangular coefficient matrices in the declared iterated-integral alphabet. It does not construct the full symbolic connection. Options declare a quartic Curve and CompositeDefinitions.";
ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint::usage =
  "ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint[source,diagonal,incomingByOrder,variable,localExpansionPoint] computes the block-triangular Laurent coefficients of the connection residue at a local expansion point when the source and target diagonal blocks are in epsilon form and the incoming block is rational in epsilon. Each channel contains Letters and Residues; no full symbolic connection is assembled.";

SolveRationalEpsilonDependentBlockByVariationOfConstants::usage =
  "SolveRationalEpsilonDependentBlockByVariationOfConstants[source,block,requestedOutputs] solves a lower-triangular rational-epsilon-dependent block by variation of constants. In FTarget=G+H FSource, the off-diagonal basis-transformation block H is normalized by H(base)=0 and removes the non-dlog part order by order through modular Hermite reduction. A declared square-free quartic Y^2=P4 uses the pair algebra h0+h1 Y and f0 du+f1 du/Y. VariationOfConstantsMethod is recorded as ExactDLogDecomposition for path-independent dlog input or FiniteFieldHermiteReductionAndReconstruction for the finite-field recurrence, which is validated at a fresh finite-field point.";
RationalEpsilonDependentBlockSolutionQ::usage =
  "RationalEpsilonDependentBlockSolutionQ[result] checks the schema and internal consistency of a rational-epsilon-dependent-block solution record. Use VerifyRationalEpsilonDependentBlockSolution to re-evaluate its defining equations against source and block inputs.";
VerifyRationalEpsilonDependentBlockSolution::usage =
  "VerifyRationalEpsilonDependentBlockSolution[result,source,block,requestedOutputs] re-derives the problem and verifies the direct solution exactly or the modular solution at a new finite-field point, including the off-diagonal basis-transformation block at the path endpoint.";
ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator::usage =
  "ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator[source,block,solution] constructs a sparse iterated-integral coefficient operator from a verified rational-epsilon-dependent-block solution whose source and block payloads match the supplied inputs. It supports independent or shared boundary coordinates and keeps multiple- and elliptic-polylogarithm letters opaque until a requested coefficient is constructed.";
RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ::usage =
  "RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ[operator] checks the structural contract of a rational-epsilon-dependent-block iterated-integral coefficient operator.";
ChangeRationalEpsilonDependentBlockSolutionBasePoint::usage =
  "ChangeRationalEpsilonDependentBlockSolutionBasePoint[operator,newBasePoint,sourceSelectors,targetSelectors] changes the lower integration limit and initial-data selectors of the same differential system. For FTarget=G+H FSource it replaces each target selector by T_q-Sum_r H_r(newBasePoint) S_(q-r), without changing residues or constructing a dense inverse. Option OffDiagonalTransformationBlockAtNewBase supplies H_r(newBasePoint) when it cannot be obtained by substitution.";
ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix::usage =
  "ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix[operator,operatorTokenSequence,boundaryOrder,outputOrder,rows] computes the sparse coefficient matrix represented by one D...D or D...D K S...S operator-token sequence and returns its corresponding iterated-integral letter sequence explicitly.";
ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap::usage =
  "ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap[operator,{outputOrder,rows}] constructs the nonzero iterated-integral coefficient map for requested master-integral rows and one epsilon order, including the H S...S contribution from the off-diagonal basis-transformation block at the path endpoint. MaximumTerms and MaximumStates are fail-closed resource caps.";
BuildTangentialJunctionBinding::usage =
  "BuildTangentialJunctionBinding[spec] builds a family-neutral singular-junction record from epsilon-order decks for the source-mode map, the complete target-G-mode map and the regularized downstream inverse selectors. It refuses until the target G representation and the rho^0/rho^1 intertwining-jet evidence are complete.";
AcceptedTangentialJunctionBindingQ::usage =
  "AcceptedTangentialJunctionBindingQ[binding] checks the structural contract of a TangentialJunctionBindingV1 record.";
ComposeTangentialJunctionIteratedIntegralCoefficientMaps::usage =
  "ComposeTangentialJunctionIteratedIntegralCoefficientMaps[binding,upstreamTerms,downstreamTerms,outputOrder] contracts requested sparse iterated-integral coefficient maps across a regularized tangential junction. It preserves each ordered pair of upstream- and downstream-path iterated-integral letter sequences, epsilon-order routing and the original boundary-data coordinates without applying a shuffle expansion or constructing a dense evolution operator.";
AttachBoundarySelectorsToRationalEpsilonDependentBlock::usage =
  "AttachBoundarySelectorsToRationalEpsilonDependentBlock[source,block,boundarySelectorData,sourceRows,targetRows] splits full-system boundary selector matrices into source and rational-epsilon-dependent-block rows while preserving their shared boundary-constant or boundary-function epsilon-coefficient labels.";
ConstructMasterIntegralEpsilonExpansionCoefficient::usage =
  "ConstructMasterIntegralEpsilonExpansionCoefficient[operator,boundaryValueData,{epsilonOrder,masterIntegralRow},path] constructs one requested master-integral epsilon-expansion coefficient from its iterated-integral coefficient operator, the off-diagonal basis-transformation block at the path endpoint, an optional CanonicalToPhysicalMasterIntegralMapByEpsilonOrder, and the boundary-value vector. A tangential-base-point prescription is retained in every nonempty formal iterated integral.";
IteratedIntegralCoefficientOperatorForRequestedOutputsQ::usage =
  "IteratedIntegralCoefficientOperatorForRequestedOutputsQ[result] checks the V2 requested-output coefficient-operator schema, the exact structural certificates, and every finite-field closure, subspace-invariance, residue, and quotient-coordinate certificate required by the selected representation. Validation.Method distinguishes deterministic symbolic validation from probabilistic finite-field sampling.";

CertifyTransportEpsilonValuations::usage =
  "CertifyTransportEpsilonValuations[record] certifies the TransportEpsilonValuations (TMin, BlockLower) of a transport-ready family epsilon-form record by three independent p-adic trials at fresh primes and random rational kinematic points, and returns <|\"Status\" -> \"TransportEpsilonValuationsCertified\", \"Record\" -> the record with the certificate attached, \"Tight\" -> ..., \"Certificate\" -> ...|>; a record without valuations gets them derived from the trials; a claim above the observed orders or an ill-formed record is refused typed (\"TransportEpsilonValuationsTooHigh\", \"TransportEpsilonValuationsInvalid\", \"IncompleteFamilyEpsilonFormRecord\", ...). CertifyTransportEpsilonValuations[file] certifies the record stored in file in place (atomic replace; options \"Write\" -> False for a dry run, \"OutputFile\" for a copy) and returns the certificate status without the record; an already certified file reports \"AlreadyCertified\" -> True. ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs uses a record's valuations only when this certificate is present and bound to the record.";

ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs::usage =
  "ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs[operator,firstPathSegmentLetterIndices,secondPathSegmentLetterIndices] computes the coefficient matrix multiplying the formal iterated integrals indexed by the two explicit path-segment letter-index sequences. It evaluates the stored exact or compressed lazy operator without conflating the two sequences into one word on a concatenated path.";

ReconstructIteratedIntegralCoefficientMatricesForRequestedOutputs::usage =
  "ReconstructIteratedIntegralCoefficientMatricesForRequestedOutputs[operator,{{firstPathSegmentLetterIndices,secondPathSegmentLetterIndices},...}] reconstructs only the requested rational coefficient matrices as one multi-right-hand-side finite-field problem and validates them at fresh points. Each output record preserves the two path-segment letter-index sequences explicitly.";

AssembleCutContributions::usage =
  "AssembleCutContributions[{result1, ...}] combines coefficient results of one process on a shared canonical family namespace. Each contribution enters with the exact weight IdenticalParticleSymmetryFactor[setup] times (-1) per outgoing ghost-antighost pair, realizing the Slavnov-Taylor completion of -g gluon polarization sums.";

IdenticalParticleSymmetryFactor::usage =
  "IdenticalParticleSymmetryFactor[setup] is the exact phase-space symmetry factor 1/n! per species of identical, hadron-untagged outgoing partons declared by the process card. The measured fragmenting leg is excluded; a ghost-antighost pair is distinct and gives 1.";

AMFlowPrescription::usage =
  "AMFlowPrescription[setup] derives AMFlow loop prescriptions from Setup: 0 for phase-space integrations, +1 for forward virtual loops and -1 for conjugate virtual loops. AMFlowPrescription[setup,topology] additionally derives the cut mask and rejects active denominators that mix forward and conjugate virtual loops; it does not persist denominator-sign metadata.";

MasterIntegralAmFlow::usage =
  "MasterIntegralAmFlow[data,numericalKinematics] evaluates one master integral numerically with AMFlow. data contains Master, Topology, CutIndices and either Prescription or Setup; numericalKinematics is a rule list or Association. MasterIntegralAmFlow[result,master,numericalKinematics] obtains the topology data from a FeynFacet coefficient result. Set \"Verbose\" -> True to print AMFlow progress. The return value is numerical verification data, not an analytic master integral.";

\[Alpha]s::usage = "\[Alpha]s is the strong coupling used by FeynFacet.";

SyntaxInformation[DeclareScalar] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[BuildBasis] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[Build4Vec] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BuildGlobalBasis] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[FullSimplifyAssum] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[BuildSimplificationContext] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[SimplifyHardCoefficients] = {
  "ArgumentsPattern" -> {_, _, OptionsPattern[]}
};
SyntaxInformation[ToFeynFacetForm] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CommonFactorSafe] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[CollinearFactorize] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CollinearFactorizePreIBP] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[GenerateCollinearFactorizePreIBPResult] =
  {"ArgumentsPattern" -> {_, _, _, _, _, _, _.}};
SyntaxInformation[KiraReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[KiraImportReduction] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[CoefficientSimplification] =
  {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};
SyntaxInformation[ReconstructCoefficients] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[ReconstructionStatus] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[CoefficientProgressPanel] = {"ArgumentsPattern" -> {}};
SyntaxInformation[DecomposeFamilyBlocks] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[BuildFamilyDifferentialSystemBlockDecomposition] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[FamilyDifferentialSystemBlockDecompositionQ] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[ConstructDiagonalBlockDLogEpsilonForm] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[DiagonalBlockDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ClassifyBlocks] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[CanonicalizeClasses] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[ValidateCanonicalForm] =
  {"ArgumentsPattern" -> {_, _., OptionsPattern[]}};
SyntaxInformation[CanonicalBlocksStatus] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[RationalizingParametrizationCatalog] = {"ArgumentsPattern" -> {}};
SyntaxInformation[VerifyRationalizingParametrization] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[RegisterFamilyRootData] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[LoadFamilyRootData] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[FamilyRootData] = {"ArgumentsPattern" -> {_, _., _.}};
SyntaxInformation[
  AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[LibraFamilyEpsForm] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[NormalizeEpsFormAffineSample] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ReconstructOffDiagonalBasisTransformationBlock] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[VerifyOffDiagonalBasisTransformationBlock] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[SolveOffDiagonalBasisTransformationBlockFiniteField] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[AnalyzeOffDiagonalBlockEpsilonFormObstructions] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[SolveDiagonalBlockBasisTransformationFiniteField] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ExactlyValidatedFamilyDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ValidatedFamilyDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ValidateFamilyDLogEpsilonForm] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[FindRequestedOutputIteratedIntegralCoefficientInputFiles] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[ClassifyRequestedOutputIteratedIntegralCoefficientInputs] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[SelectValidatedFamilyDLogEpsilonFormInputs] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[WriteRequestedOutputIteratedIntegralCoefficientInputSummary] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[ChooseRegularBasePointAndFirstPathParameterScale] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[AssembleCutContributions] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[IdenticalParticleSymmetryFactor] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[AMFlowPrescription] = {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[MasterIntegralAmFlow] =
  {"ArgumentsPattern" -> {_, _, _., OptionsPattern[]}};
SyntaxInformation[PartialFraction] = {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildTopologies] = {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[IdentifySafePropagator] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[TopologyEquivalence] = {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[GenerateDiagram] = {"ArgumentsPattern" -> {_}};
SyntaxInformation[DimensionalShift] = {"ArgumentsPattern" -> {_, _, _, _.}};
SyntaxInformation[ConstructIteratedIntegralCoefficientOperatorForRequestedOutputs] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[IteratedIntegralCoefficientOperatorForRequestedOutputsQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ComputeIteratedIntegralCoefficientMatrixForRequestedOutputs] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ReconstructIteratedIntegralCoefficientMatricesForRequestedOutputs] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[ComputeTruncatedLocalFrobeniusExpansion] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[TransformTangentialConnectionToNormalResidueEigenbasis] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ConstructBoundaryFunctionDifferentialSystem] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BoundaryFunctionDifferentialSystemQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[TangentialBoundaryEvolutionOperatorQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ComposeBoundaryFunctionSolutionMapWithTangentialEvolution] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[ComposeFactorizedFiniteFieldBoundaryFunctionSolutionMapWithTangentialEvolution] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[FactorizedFiniteFieldBoundarySolutionCompositionQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ConstructBoundaryFunctionEpsilonCoefficientEquations] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[ConstructMasterIntegralSolution] =
  {"ArgumentsPattern" -> {_, ___}};
SyntaxInformation[MasterIntegralSolutionQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[DeriveMasterIntegralEpsilonOrderRequirements] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[MasterIntegralEpsilonOrderRequirementsQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[MatchBoundaryAsymptoticsToFrobeniusModes] =
  {"ArgumentsPattern" -> {_, _, _, _}};
SyntaxInformation[DegenerateResidueEigenspaceBasis] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[ConstructBoundarySelectorMatrices] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[ConstructBoundaryValueVectorFromConstants] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[ConstructBoundaryValueVectorFromFunctions] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[BoundaryConstantEpsilonCoefficient] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[BoundaryFunctionEpsilonCoefficient] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[IteratedIntegralKernel] =
  {"ArgumentsPattern" -> {_, _, _.}};
SyntaxInformation[ExpandIteratedIntegralLetterSequence] =
  {"ArgumentsPattern" -> {_, _, _., _.}};
SyntaxInformation[ComputeConnectionResidueAtLocalExpansionPoint] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint] =
  {"ArgumentsPattern" -> {_, _, _, _, _, OptionsPattern[]}};
SyntaxInformation[SolveRationalEpsilonDependentBlockByVariationOfConstants] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[RationalEpsilonDependentBlockSolutionQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[VerifyRationalEpsilonDependentBlockSolution] =
  {"ArgumentsPattern" -> {_, _, _, _}};
SyntaxInformation[ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientOperator] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[RationalEpsilonDependentBlockIteratedIntegralCoefficientOperatorQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ChangeRationalEpsilonDependentBlockSolutionBasePoint] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ComputeRationalEpsilonDependentBlockIteratedIntegralCoefficientMatrix] =
  {"ArgumentsPattern" -> {_, _, _, _, _.}};
SyntaxInformation[ConstructRationalEpsilonDependentBlockIteratedIntegralCoefficientMap] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildTangentialJunctionBinding] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ComposeTangentialJunctionIteratedIntegralCoefficientMaps] =
  {"ArgumentsPattern" -> {_, _, _, _}};
SyntaxInformation[AttachBoundarySelectorsToRationalEpsilonDependentBlock] =
  {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[ConstructMasterIntegralEpsilonExpansionCoefficient] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ComposeRationalizingParametrizations] =
  {"ArgumentsPattern" -> {_, _, _, _}};
SyntaxInformation[BuildSquareRootGeneratorsAndQuadraticRelations] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[FamilySquareRootGeneratorCensus] =
  {"ArgumentsPattern" -> {_, _}};
SyntaxInformation[LookupCataloguedRationalizingParametrizationForRoots] =
  {"ArgumentsPattern" -> {_, _.}};
SyntaxInformation[SolveOffDiagonalBasisTransformationBlock] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[ExtendRationalizingParametrization] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};

Options[PartialFraction] = {
  FeynCalc`DropScaleless -> False,
  FeynCalc`FDS -> False
};


Begin["`Private`"];

$feynFacetDirectory = DirectoryName[ExpandFileName[$InputFileName]];
$feynFacetRoot = DirectoryName[$feynFacetDirectory];
(* Installation roots (generality pass 2026-08-23): the ADD-ON tree and
   the subkernel loader are properties of the installation, not of the
   package's parent directory.  Both may be overridden by setting the
   Global variables BEFORE the package loads; the defaults preserve the
   repository layout. *)
$feynFacetAddonRoot = If[StringQ[Global`$FACETAddonRoot], Global`$FACETAddonRoot, $feynFacetRoot];
$feynFacetLoader = If[StringQ[Global`$FACETLoader], Global`$FACETLoader,
  FileNameJoin[{$feynFacetAddonRoot, "Addon", "Load", "LoadFACET.wl"}]];
$feynFacetPrivateDirectory = FileNameJoin[{$feynFacetDirectory, "Private"}];
(* Load order and layer structure (overhaul 2026-09-02): the manifest
   Private/LoadOrder.wl lists the layers in load order and the files of
   each layer; a layer may reference only itself and lower layers.  The
   package refuses to load if the manifest is missing or malformed, or
   if a listed file is absent.  Files under Private_Backup/ are never
   loaded (superseded code kept with its evidence). *)
$feynFacetLoadOrderFile = FileNameJoin[{$feynFacetPrivateDirectory, "LoadOrder.wl"}];
$feynFacetLoadOrder = If[FileExistsQ[$feynFacetLoadOrderFile],
  Get[$feynFacetLoadOrderFile], $Failed];
If[! MatchQ[$feynFacetLoadOrder, {(_String -> {___String}) ..}],
  Print["FeynFacet: load-order manifest missing or malformed: ", $feynFacetLoadOrderFile];
  Abort[]
];
(* A manifest entry is a path relative to its layer directory: "TaskBroker.wl"
   (a file directly in the layer) or "Modular/ModularArithmetic.wl" (a file
   in a sub-folder of the layer; round 5 of the overhaul, 2026-09-02).  The
   bare file name must be unique across the whole manifest, so that a
   module can be addressed by its name alone; a duplicate is a typed
   refusal to load. *)
$feynFacetPrivateFiles = Flatten[Function[{layer, files},
    FileNameJoin[{$feynFacetPrivateDirectory, layer, #}] & /@ files] @@@
  $feynFacetLoadOrder];
$feynFacetPrivateModuleNames = Flatten[FileNameTake /@ Last[#] & /@ $feynFacetLoadOrder];
If[! DuplicateFreeQ[$feynFacetPrivateModuleNames],
  Print["FeynFacet: duplicate module names in the load-order manifest: ",
    Select[Tally[$feynFacetPrivateModuleNames], Last[#] > 1 &][[All, 1]]];
  Abort[]
];
(* Module files are addressed by their manifest spelling OR by their bare
   name, never by a path that assumes a particular folder layout:
   feynFacetPrivateFile["ModularArithmetic.wl"] and
   feynFacetPrivateFile["Modular/ModularArithmetic.wl"] both return the full
   path of that module ($Failed if the manifest does not list it). *)
$feynFacetPrivateFileIndex = Association[Flatten[
  Function[{layer, files},
    With[{path = FileNameJoin[{$feynFacetPrivateDirectory, layer, #}]},
      {# -> path, FileNameTake[#] -> path}] & /@ files] @@@ $feynFacetLoadOrder]];
FeynFacet`Private`feynFacetPrivateFile[name_String] := Lookup[$feynFacetPrivateFileIndex, name, $Failed];
$feynFacetSourceFiles = Join[
  {ExpandFileName[$InputFileName], FileNameJoin[{$feynFacetDirectory, "Distributions.wl"}]},
  $feynFacetPrivateFiles
];
If[! AllTrue[$feynFacetSourceFiles, FileExistsQ],
  Print["FeynFacet: missing source files: ",
    Select[$feynFacetSourceFiles, ! FileExistsQ[#] &]];
  Abort[]
];
$feynFacetEpsilon = Symbol["Global`Epsilon"];
$dimensionRule = System`D -> 4 - 2 $feynFacetEpsilon;

SetAttributes[Cut, HoldAll];

FeynFacet`dD /: MakeBoxes[
    FeynFacet`dD[k_, dim_: D],
    form : StandardForm | TraditionalForm
  ] := RowBox[{
  SuperscriptBox["d", ToBoxes[dim, form]],
  ToBoxes[k, form]
}];

dFraction /: MakeBoxes[
    dFraction[x_],
    form : StandardForm | TraditionalForm
  ] := With[
  {xBoxes = ToBoxes[x, form]},
  InterpretationBox[
    RowBox[{"\[DifferentialD]", xBoxes}],
    dFraction[x]
  ]
];

Cut /: MakeBoxes[
    cut : Cut[argument_, direction_: 1],
    form : StandardForm | TraditionalForm
  ] := Module[{shown, boxes, sign},
  shown = argument /. FeynCalc`SPD[q_] :> HoldForm[q^2];
  boxes = MakeBoxes[shown, form];
  sign = Switch[direction, 1, "+", -1, "-", _, ToBoxes[direction, form]];
  InterpretationBox[
    RowBox[{SubscriptBox["\[Delta]", sign], "(", boxes, ")"}],
    cut
  ]
];

Scan[If[Get[#] === $Failed, Abort[]] &, $feynFacetPrivateFiles];

End[];

Quiet[EndPackage[], General::shdw];

If[Length[DownValues[FeynCalc`Calc]] === 0,
  Quiet[
    Block[{FeynCalc`$FeynCalcStartupMessages = False},
      FeynCalc`FCReloadAddOns[{"FeynCalcLegacy"}]
    ],
    General::shdw
  ]
];

If[Length[DownValues[FeynCalc`Calc]] === 0,
  Print["FeynFacet: the FeynCalcLegacy add-on is required but could not be loaded."];
  Abort[]
];

Print[
  Style["FeynFacet ", "Text", Bold],
  Style["0.1", "Text"]
];
