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
  "IdentifySafePropagator[setup,propagator] certifies a strict sign in the nonsoft, noncollinear interior of physical massless 2-to-n phase space, allowing boundary zeros. Supported forms are exact rational multiples of a real momentum square or a null bilinear. It does not certify endpoint convergence, removal of i0, or auxiliary-mass deformations; unsupported forms and uncertified signs return $Failed.";

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
  "KiraReduction[inputs,file] identifies equivalent cut topologies, runs one exact-target Kira reduction, closes its exported rules against the solved database, writes and verifies the compact artifact, then removes the temporary Kira workspace. The temporary workspace is <project>/<order>/<channel>/Kira/<contribution>/<run>. The full owner path is preserved relative to FeynFacet`Private`$feynFacetWorkspaceRoot; results outside that workspace are rejected. The reduction-input fingerprint covers the Kira and Fermat executable hashes and not their absolute paths, so a solved workspace stays valid when the add-on tree moves.";

KiraImportReduction::usage =
  "KiraImportReduction[inputs,file] validates and imports the matching solved Kira workspace, closes its exact reduction rules, writes and verifies the compact artifact, then removes the workspace. It never reruns Kira.";

CoefficientSimplification::usage =
  "CoefficientSimplification[inputs,kiraFile] reconstructs exact master coefficients from one saved diagram-pair set and the KiraResult.wl artifact path by finite-field reconstruction. CoefficientSimplification[projectDirectory,cardName,resultFolder] automatically loads one saved diagram-pair set and KiraResult.wl, reconstructs the coefficients and writes CoefficientResult.wl. resultFolder may be Automatic. The option \"NormalizationKernels\" controls the Mathematica workers; \"Threads\" controls FireFly. The Setup key \"DistributionHeads\" declares the collinear-distribution heads of the channel (default the twist-2 quark set of FeynFacet/Physics/Distributions.wl) and exactly those heads are treated as distributions. A saved artifact is matched to its inputs by the analytic-context fingerprint rather than by the absolute result directory.";

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
  "BuildFamilyDifferentialSystemBlockDecomposition[system,systemReference] derives diagonal blocks in the current master-integral basis as strongly connected components of the connection dependency graph, ordered so the connection is block lower triangular. This establishes indecomposability under basis permutations only; it does not establish irreducibility under general basis transformations. The default validation uses bounded probabilistic finite-field sampling; ValidationMethod -> CharacteristicZeroSymbolicIdentity uses exact symbolic zero tests.";

FamilyDifferentialSystemBlockDecompositionQ::usage =
  "FamilyDifferentialSystemBlockDecompositionQ[record,system] re-evaluates the recorded exact or finite-field nonzero-pattern evidence and checks that the V2 record contains precisely the strongly connected components, partitions the original master-integral basis rows, and is ordered block lower triangular.";

ConstructDiagonalBlockDLogEpsilonForm::usage =
  "ConstructDiagonalBlockDLogEpsilonForm[system,coefficientPresentation,blockRows] constructs one schema-V2 DiagonalBlockDLogEpsilonForm. It extracts blockRows in their declared order and revalidates the family coefficient presentation. Automatic construction runs DiagonalBlockEpsForm on the original source-variable block, including its block-local rationalizing-chart search, but asks only for a reconstruction-stabilized candidate; that candidate is composed into the selected family presentation before the family-block equation is derived. CandidateDiagonalBlockDLogEpsilonForm may instead supply either the V2 mathematical fields or a current certified DiagonalBlockEpsForm result; externally supplied legacy results must carry their exact gate. The default ProbabilisticFiniteFieldSampling validation evaluates invertibility and both basis-transformation equations at stored points modulo primes disjoint from finite-field reconstruction; every declared square-root sign sheet is checked. CharacteristicZeroSymbolicIdentity is an explicit development option. DiagonalBlockEpsFormOptions passes bounded construction options, while the candidate-return and chart-routing options are controlled by this constructor.";

DiagonalBlockDLogEpsilonFormQ::usage =
  "DiagonalBlockDLogEpsilonFormQ[record,system,coefficientPresentation] re-pulls the selected rows of the V2 FamilyDifferentialSystem through the validated coefficient presentation and replays the record's stored finite-field points and every declared square-root sign sheet (or redoes an explicitly requested symbolic development check). It validates the basis-transformation equation, invertibility, constant residues, and regulator-free letters rather than accepting a stored flag as evidence.";

ClassifyBlocks::usage =
  "ClassifyBlocks[blocks] quotients a block set by connection equivalence: basis permutation composed with an optional v<->w relabelling. Blocks are bucketed by permutation-invariant multisets and then matched exactly, so every class member carries an explicit permutation and swap that reproduce its connection matrices from the representative entry by entry. Classes are keyed by the content address of their exact orbit key; integer ClassID labels are a convenience only.";


ValidateCanonicalForm::usage =
  "ValidateCanonicalForm[form] certifies an epsilon-form by exact dlog reconstruction: it extracts the alphabet, requires every residue matrix to be constant, and requires the stored matrices to be reproduced exactly as eps times the sum of residues against dlog of the letters. form may be a canonical-form record, a form file, or matrices with their variables. Any stored \"Validated\" flag is ignored, because CANONICA reports a failed sector as {False,{partial,partial}}, which has the same shape as a success.";

CanonicalBlocksStatus::usage =
  "CanonicalBlocksStatus[formDirectory] prints one greppable line per stored canonical-form file giving class, content address, dimension, ansatz degree and stored coordinate representation, and a closing summary. With \"Classes\" it also lists the classes that have no form yet, and with \"Validate\"->True it re-runs ValidateCanonicalForm on every stored form. It is meant to be called from a second kernel while a campaign runs.";

AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks::usage =
  "AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[system,coefficientPresentation] re-expresses a two-variable family differential system and composes its diagonal-block basis transformations. The result has epsilon-form diagonal blocks and general lower off-diagonal blocks. Production uses validated supplied diagonal forms and defers repeated transformation identities to the final family certificate; Development re-derives them. \"OffDiagonalSimplification\" defaults to \"PreserveProducts\" in Production and \"Together\" in Development. \"Blocks\" must give explicit {rows,provider} specifications.";


PullBackMasterIntegralDifferentialSystem::usage =
  "PullBackMasterIntegralDifferentialSystem[system,parametrization,baseLift] changes coordinates of a complete DE and its supplied basis matrices, fixing rationalized root branches at the specified ordinary-point lift.";

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
FactorFamilyRegulatorDependenceInCoefficientPresentation::usage =
  "FactorFamilyRegulatorDependenceInCoefficientPresentation[{Ax,Ay},{x,y},eps,presentation] finds a kinematics-independent basis transformation T(eps) that factors epsilon from a connection in the declared coefficient presentation. It tries a catalogued rationalizing parametrization for the roots actually present, then the square-root parity decomposition if none is catalogued. RegulatorFactorizationUnsuccessful reports unsuccessful construction with separate RationalizingParametrizationSearch and MultiquadraticFactorization diagnostics; it is not a nonexistence result. A deadline expiry is reported separately.";
FactorFamilyRegulatorDependenceMultiquadratic::usage =
  "FactorFamilyRegulatorDependenceMultiquadratic[{Ax,Ay},{x,y},eps,roots] seeks T(eps) over Q(eps) by decomposing the connection in square-root monomials and solving the rational coefficient equations. Each parity component is indexed by the exponents of the declared generators modulo two; RootCount counts generators, not matrix rank. Generator independence and validation strength are reported separately. Numeric square roots may require a larger constant field, so ConstantFieldRestriction denotes an incomplete search over Q(eps). The number of roots does not classify the associated variety or establish non-rationalizability. Options control sampling, time limits, and exact or deferred family validation.";
AnalyzeOffDiagonalBlockEpsilonFormObstructions::usage =
  "AnalyzeOffDiagonalBlockEpsilonFormObstructions[record] diagnoses a finite Taylor expansion of a rational off-diagonal block equation, with the lower transformation order fixed at zero and primitive integration constants fixed to zero. It tests closedness and constructs rational primitives when possible. Unequal sampled residues are reported as unresolved geometric components; primitive-construction failure is inconclusive. NoObstructionToOrder refers only to the computed coefficients. No outcome certifies nonexistence under arbitrary Laurent normalizations, alphabets or bases.";

SolveOffDiagonalBasisTransformationBlockFiniteField::usage =
  "SolveOffDiagonalBasisTransformationBlockFiniteField[record] solves one rational two-variable off-diagonal basis-transformation block by finite-field sampling, regulator interpolation, Chinese remaindering, and rational reconstruction. It returns a solution only after both unspecialized Pfaffian equations vanish exactly.";

ExactlyValidatedFamilyDLogEpsilonFormQ::usage =
  "ExactlyValidatedFamilyDLogEpsilonFormQ[record] returns True only when a FamilyDLogEpsilonForm with Status \"FamilyDLogEpsilonFormValidated\" carries characteristic-zero symbolic validation of its basis-transformation inverse, connection-transformation equation, epsilon factorization, constant-residue dlog representation, coefficient-presentation relations, and flatness. Validation strength is read from Validation, not from Status.";

ValidatedFamilyDLogEpsilonFormQ::usage =
  "ValidatedFamilyDLogEpsilonFormQ[record] returns True when a FamilyDLogEpsilonForm with Status \"FamilyDLogEpsilonFormValidated\" carries internally consistent exact or probabilistic evidence for its defining equations. Validation strength is read from Validation; probabilistic evidence is never reported as exact, regardless of the number of square-root generators.";

ValidateFamilyDLogEpsilonForm::usage =
  "ValidateFamilyDLogEpsilonForm[record,system] re-derives the defining equations of a candidate family dlog epsilon form from the differential system, coefficient presentation, ordered diagonal blocks, basis transformation, letters, and constant residue matrices. It returns a non-persisted FamilyDLogEpsilonFormValidationResult; every accepted result has Status \"FamilyDLogEpsilonFormValidationPassed\". The script-side BuildValidatedFamilyDLogEpsilonFormV2 constructor is the sole boundary that turns this result into a complete persisted FamilyDLogEpsilonForm. IdentityMethod -> \"Symbolic\" records characteristic-zero validation; \"RandomPoints\" records random-rational-point evidence; and \"Modular\" records Method \"ProbabilisticFiniteFieldSampling\" for both rational and square-root coefficient presentations. The result contains no content digests or settings-dependent acceptance conditions.";

FamilyArtifactRead::usage =
  "FamilyArtifactRead[file,context] reads a Wolfram record with guarded resolution of unqualified symbols (default Global`). Explicit symbol contexts are preserved. Missing, malformed or aborted reads return $Failed; benign messages remain available in $familyArtifactReadMessages.";

FamilyArtifactWrite::usage =
  "FamilyArtifactWrite[value,file] writes a complete record atomically, qualifying stored symbols, including shadowed System names so Get and FamilyArtifactRead preserve its meaning. Compression -> True stores a lossless compressed expression; Automatic compresses records above 8 MiB, and False (default) writes plain Wolfram text.";

DiagonalBlockEpsForm::usage =
  "DiagonalBlockEpsForm[{Ax,Ay},{x,y},eps] constructs and certifies the epsilon form of one irreducible diagonal block in a rational two-variable chart: one spectator slice is normalized by Lee balances and factored (Libra), which fixes the constant residues of every letter depending on x; the x-equation d_x T = Ax T - T Bx is then a homogeneous linear system for a rational T with letter denominators and is solved by finite-field sampling, regulator interpolation, Chinese remaindering and rational reconstruction; the pure-y residues and the rational scalar basis rescaling are read off exactly from the y-direction; the default and only legacy acceptance is the exact two-variable gate. Returns an Association with Status \"Certified\", Transformation, Letters, Residues, EpsForm and stage timings. \"ReturnCandidateBeforeCertification\" -> True is the V2 constructor's internal route: it returns Status \"CandidateConstructed\" without the exact acceptance gate after finite-field reconstruction has stabilized across successive primes. The block's variables and regulator are the symbols given, whatever they are named. \"ChartRetry\" (default True) retries a block with exactly one regulator-free irreducible quadratic denominator in a chart: the conic parametrization of CanonicalBlocks and the catalog chart of TransportCharts whose root square is that quadratic, matched positionally by TransportRootSetChart and rekeyed to the block's own variables, so the retry never depends on the variables being named v and w. \"ChartParameter\" is Automatic, which is Global`t unless t is one of the block's own symbols and a fresh package-private symbol otherwise; a parameter equal to one of the block's variables is refused with Status \"ChartParameterCollides\".";

DiagonalBlockSliceEpsForm::usage =
  "DiagonalBlockSliceEpsForm[{Ax,Ay},{x,y},eps] computes the constant residues of the block's epsilon form on a generic rational slice y = y0 by Lee balances and maps every slice locus to a letter of the block. The default engine \"NumericalEps\" specializes the regulator to a fixed rational number (1/101) before the balance chain -- exact arithmetic over Q(x); the residue tuple is then M_a(e)/e, a constant conjugate of the true one, and is brought to a basis with small rational coefficients obtained by constant conjugation. \"Engine\" -> \"Symbolic\" keeps eps symbolic and finishes with Lee's linear factor-out step. Returns SliceLetters with SliceResidues (constant matrices), the balance path and timings.";

SolveDiagonalBlockBasisTransformationFiniteField::usage =
  "SolveDiagonalBlockBasisTransformationFiniteField[{Ax,Ay},{x,y},eps,sliceData] solves the diagonal-block basis-transformation equation d_x T = Ax T - T Bx by finite-field sampling, regulator interpolation, Chinese remaindering, and rational reconstruction; by default the result is accepted only after the exact equation holds. \"ReturnCandidateBeforeExactEquationCheck\" -> True is the V2 constructor's internal route and returns an unaccepted CandidateConstructed only after two successive prime-extended lifts give the same canonical rational matrix.";

CompleteDiagonalBlockEpsForm::usage =
  "CompleteDiagonalBlockEpsForm[{Ax,Ay},{x,y},eps,solve] takes a transformation solving the x-equation and determines exactly, from T^-1 Ay T - T^-1 d_y T, the constant residues of the pure-y letters and the rational scalar basis rescaling with integer exponents that removes the remaining scalar dlog terms.";

CertifyDiagonalBlockEpsForm::usage =
  "CertifyDiagonalBlockEpsForm[{Ax,Ay},{x,y},eps,T,letters,residues] is the exact gate: the source connection pushed through T equals eps Sum_a R_a dlog phi_a entrywise in both variables, the residues are constant, the letters are regulator-free, the form is flat, and T is invertible.";

DiagonalBlockClassCampaign::usage =
  "DiagonalBlockClassCampaign[classes,directory] runs DiagonalBlockEpsForm over class representatives (a list of class records or the path of classes.wl) and writes one ledger record per class with Transformation, EpsForm, Variables, Chart, Frame, Method, Seconds and Validated fields (Transformation, EpsForm, Variables, Chart, Frame, Method, Seconds, Validated). Options: \"Kernels\" (subkernel pool under one main kernel), \"Overwrite\", \"TimeConstraint\" per class, \"ValidateCanonicalForm\" to re-check every record with ValidateCanonicalForm. \"Variables\" and \"Regulator\" are Automatic: each class record's own \"Variables\"/\"Regulator\" is preferred, then the regulator is detected from the representative matrices by name (eps, Eps, epsilon, Epsilon, ep), then Global`v, Global`w and Global`eps; an explicit option overrides the record. A record that declares other than two variables gets a failure record with Status \"ClassVariablesNotTwoSymbols\" instead of being solved as a pair.";

DiagonalBlockLetters::usage =
  "DiagonalBlockLetters[{Ax,Ay},{x,y},eps] returns the regulator-free irreducible denominator factors of the block (the candidate letters) and the regulator-dependent ones (apparent singularities).";

FamilyEpsilonFormRecord::usage =
  "FamilyEpsilonFormRecord[record] normalizes one family epsilon-form record to the standard schema: the diagonal-block list is converted to plain index lists (the annotated {indices, classId} layout is accepted), verified to flatten to a basis permutation, and the required analytic fields are checked for presence. Returns the normalized record, or an Association whose \"Status\" names the defect.";


ComputeTruncatedLocalFrobeniusExpansion::usage =
  "ComputeTruncatedLocalFrobeniusExpansion[connection,spec] computes a truncated prefactor H(rho,eps) for an epsilon-form connection. EpsilonNormalizedConnectionResidue is R = Res(connection/eps), so the full connection residue is eps R and the local solution is H(rho,eps) rho^(eps R) c. The record states this convention explicitly. spec gives Variable, Regulator, LocalExpansionPoint and optionally LocalVariable, LocalDirection and FixedRules. LocalDirection includes the coordinate Jacobian; options set retained local and epsilon orders. Non-epsilon-form and non-Fuchsian inputs are rejected.";

TransformTangentialConnectionToNormalResidueEigenbasis::usage =
  "TransformTangentialConnectionToNormalResidueEigenbasis[normalResidue,tangentialConnection,spec] transforms a normal connection residue and the tangential connection to a supplied moving eigenbasis of the normal residue, including the derivative of that basis. spec gives TangentialVariable, Regulator, NormalResidueEigenbasis, and LocalExponents. The eigenbasis may be rational in the tangential variable and regulator; its columns must diagonalize the normal residue. The result contains TangentialConnectionInEigenbasis, EqualExponentSectors, and the integer/regulator split of every local exponent. Coupling between unequal exponent sectors is refused.";

ConstructBoundaryFunctionDifferentialSystem::usage =
  "ConstructBoundaryFunctionDifferentialSystem[modeMatching,inducedConnection] constructs the differential system obeyed by the free Frobenius coefficients along a positive-dimensional physical boundary stratum. It includes the moving normal-basis term, retains mixing inside degenerate or Jordan sectors, and validates normal-residue horizontality, invariance of the boundary-mode subspace, and tangential flatness. A supplied BoundaryFunctionConnectionMatrices option avoids characteristic-zero derivation when the connection was reconstructed from finite-field images.";

BoundaryFunctionDifferentialSystemQ::usage =
  "BoundaryFunctionDifferentialSystemQ[result] checks the structural and mathematical-validation contract of a V2 BoundaryFunctionDifferentialSystem.";


ConstructBoundaryFunctionEpsilonCoefficientEquations::usage =
  "ConstructBoundaryFunctionEpsilonCoefficientEquations[system,{emin,emax}] expands a validated boundary-function differential system in the dimensional regulator and returns the coupled differential equations and the precise boundary-function epsilon orders they require.";

MatchBoundaryAsymptoticsToFrobeniusModes::usage =
  "MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,basisTransformation,spec,realizations] matches declared physical-limit asymptotics to local Frobenius modes after applying the basis transformation and truncated local prefactor. spec must declare BoundaryDomain as either a PhysicalBoundaryPoint or a PhysicalBoundaryStratum with its TangentialVariables; the result therefore distinguishes boundary constants from boundary functions. A relation between a physical limiting variable and the local expansion coordinate is recorded explicitly, including any required logarithm branch.";

DegenerateResidueEigenspaceBasis::usage =
  "DegenerateResidueEigenspaceBasis[mode,modes] returns the echelon basis and dimension of the degenerate normal-residue eigenspace containing mode. Degeneracy alone does not imply a relation among boundary constants or functions; such a relation must be supplied separately.";


VerifyMasterIntegralSolution::usage =
  "VerifyMasterIntegralSolution[result] checks the generic coefficient identities of the stored integrals, their kernel pullbacks, the exact gauge equations in every coordinate and flatness. It uses the finite coefficient ordering to establish the multivariate equations, without relying on derivatives at a single point.";
ApplyFiniteIntegrationPreparation::usage =
  "ApplyFiniteIntegrationPreparation[system,preparation] applies the stored complete basis transformation and preserves the original differential equations for independent exact verification. Use AutomaticPreparation->False when constructing finite coefficients from this already prepared system.";
FindEpsilonRescaling::usage =
  "FindEpsilonRescaling[connectionMatrices,eps] finds exact integer epsilon shifts making every nonzero entry have nonnegative valuation, and orders rows when the epsilon-zero dependency graph is acyclic. Failure establishes only insufficiency of diagonal epsilon rescaling.";
PrepareDifferentialSystemForFiniteIntegration::usage =
  "PrepareDifferentialSystemForFiniteIntegration[system] applies epsilon rescaling and constructs explicit homogeneous solutions for epsilon-zero diagonal blocks, verifying every kinematic equation. It returns a complete change of basis and transformed connection or identifies the unsolved block.";
ConstructMasterIntegralDimensionalRecurrence::usage =
  "ConstructMasterIntegralDimensionalRecurrence[representations] constructs a cut-aware rational dimensional recurrence by Gram insertions and Kira reduction at fixed rational kinematics, after certifying eventual high-dimensional convergence.";
DetermineLaurentBoundsFromDimensionalRecurrence::usage =
  "DetermineLaurentBoundsFromDimensionalRecurrence[recurrence] derives sufficient master Laurent bounds from eventual high-dimensional holomorphy and the finite set of dimension poles of the inverse recurrence, without evaluating master integrals.";
ConstructMasterIntegralRepresentations::usage =
  "ConstructMasterIntegralRepresentations[data,request] constructs master integral definitions and Feynman-parameter or cut Baikov representations from GLI identifiers and topology data, preserving the AMFlow momentum-space convention. It does not choose a new master basis or boundary normalization.";
DetermineMasterIntegralExpansionOrders::usage =
  "DetermineMasterIntegralExpansionOrders[system,request] fixes ordinary-point or Frobenius boundary normalization, derives pole bounds from normalized integral representations, and determines sufficient orders for global evolution, local matching and boundary coefficients without computing the global solution. RequestedMasterIntegralUpperOrders derives full output intervals using the valuations of the complete boundary-to-master transformation; it is exclusive with RequestedMasterIntegralOrderRanges.";
DetermineLaurentValuation::usage =
  "DetermineLaurentValuation[expression,epsilon] determines an exact integer Laurent valuation for rational expressions and supported meromorphic prefactors, including Gamma products. Unsupported or essential dependence is reported.";
DetermineIntegralLaurentBound::usage =
  "DetermineIntegralLaurentBound[representation] derives a lower epsilon bound for a supplied normalized sum of resolved parameter integrals. It checks regular rational factors on the parameter cube and counts resonant Taylor moments, or combines polynomial moments exactly.";
DetermineEpsilonOrders::usage =
  "DetermineEpsilonOrders[calculation] propagates sufficient Laurent orders through declared linear combinations, products and convolutions. It records remainder inequalities and distinguishes derived, assumed and missing input bounds.";
DetermineFundamentalMatrixEpsilonOrders::usage =
  "DetermineFundamentalMatrixEpsilonOrders[preparedSystem,request] determines entrywise coefficient orders for L V R, including all DE dependencies, from a regular connection with triangular epsilon-zero part.";
DetermineEndpointEpsilonOrders::usage =
  "DetermineEndpointEpsilonOrders[expansion,request] derives separate epsilon requirements for resolved endpoint projections, or exact matrix-power moments. It retains boundary derivatives, logarithmic powers and explicit prefactors.";
DetermineFrobeniusLaurentBounds::usage =
  "DetermineFrobeniusLaurentBounds[normalSystem] derives local fundamental-matrix and inverse Laurent bounds from the finite resonant Frobenius range of a jointly regular rational Fuchsian frame. Global matching and uncontrolled corners are not inferred.";
ConstructMasterIntegralSolution::usage =
  "ConstructMasterIntegralSolution[system,request] constructs explicit finite nested-integral coefficients at an ordinary base point. RequestedMasterIntegralOrderRanges derives sufficient evolution and initial-constant orders from integral definitions and stores the requested master coefficients in kinematics-independent C[j,n]. RequestedMasterIntegralUpperOrders also derives each output lower cutoff from transport of the declared boundary Laurent class. A Rows/EpsilonOrderRange request instead specifies fundamental-matrix coefficients. No boundary values or final observable demands are inferred.";
MasterIntegralSolutionQ::usage =
  "MasterIntegralSolutionQ[result] checks explicit finite integral and arithmetic definitions and the presence of every requested coefficient. It rejects operator-only records and does not certify physical boundary data.";
MasterIntegralSolutionCoefficient::usage =
  "MasterIntegralSolutionCoefficient[result,row,order] returns the stored finite row multiplying the original-master initial constants at the declared ordinary base point.";
ExpandMasterIntegralSolutionInInitialConstants::usage =
  "ExpandMasterIntegralSolutionInInitialConstants[result,lowerBounds,orders] explicitly performs the epsilon convolution with initial constants C[j,m]. Each supplied integer lower bound is an assumption for that constant series. Missing fundamental-matrix coefficients cause failure.";
WriteMasterIntegralSolution::usage =
  "WriteMasterIntegralSolution[result,directory,opts] writes complete finite expressions as Wolfram text files or, with FileFormat->WXF, one compressed solution.wxf file. Both formats include explicit integral definitions and requested coefficients.";

DeriveMasterIntegralEpsilonOrderRequirements::usage =
  "DeriveMasterIntegralEpsilonOrderRequirements[request,valuations] derives epsilon-order upper demands from explicit V2 hard-function order and coefficient-valuation records. The two-input result is explicitly upper bounds only. DeriveMasterIntegralEpsilonOrderRequirements[request,valuations,lowerBounds] stores every required integer order from supplied master Laurent lower bounds, indexed by global master index; identically zero coefficients require no orders.";
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
  "ComputeConnectionResidueAtLocalExpansionPoint[letters,kernelCoefficientMatrices,variable,point] computes Res(Sum_i kernelCoefficientMatrices[[i]] omega_i) from the declared integration kernels, including elliptic kernels. No implicit epsilon factor is inserted or removed: callers must supply coefficients of the actual one-form whose residue is requested. Square and rectangular matrices are supported; options give Curve and CompositeDefinitions.";
ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint::usage =
  "ComputeRationalEpsilonDependentBlockConnectionResidueAtLocalExpansionPoint[source,diagonal,incomingByOrder,variable,localExpansionPoint] computes the block-triangular Laurent coefficients of the connection residue at a local expansion point when the source and target diagonal blocks are in epsilon form and the incoming block is rational in epsilon. Each channel contains Letters and KernelCoefficientMatrices; no full symbolic connection is assembled.";


AssembleCutContributions::usage =
  "AssembleCutContributions[{result1, ...}, opts] reads retained coefficient formats, applies supplied exact master identities, and combines terms without losing Laurent truncations. Automatic weights are the identical-particle symmetry factor times (-1) per outgoing ghost-antighost pair.";

IdenticalParticleSymmetryFactor::usage =
  "IdenticalParticleSymmetryFactor[setup] is the exact phase-space symmetry factor 1/n! per species of identical, hadron-untagged outgoing partons declared by the process card. The measured fragmenting leg is excluded; a ghost-antighost pair is distinct and gives 1.";

AMFlowPrescription::usage =
  "AMFlowPrescription[setup] derives AMFlow loop prescriptions from Setup: 0 for phase-space integrations, +1 for forward virtual loops and -1 for conjugate virtual loops. AMFlowPrescription[setup,topology] additionally derives the cut mask and rejects active denominators that mix forward and conjugate virtual loops; it does not persist denominator-sign metadata.";

MasterIntegralAmFlow::usage =
  "MasterIntegralAmFlow[data,numericalKinematics] evaluates one master integral numerically with AMFlow. data contains Master, Topology, CutIndices and either Prescription or Setup; numericalKinematics is a rule list or Association. MasterIntegralAmFlow[result,master,numericalKinematics] obtains the topology data from a FeynFacet coefficient result. Set \"Verbose\" -> True to print AMFlow progress. The return value is numerical verification data, not an analytic master integral.";

\[Alpha]s::usage = "\[Alpha]s is the strong coupling used by FeynFacet.";


RegisterRationalizingParametrizations::usage =
 "RegisterRationalizingParametrizations[entries] adds named rationalizing parametrizations after verifying every map. Invalid entries or conflicting names register nothing. This extends supported rational maps, not the set of implemented geometries.";

FindCutIntegralEquivalences::usage =
  "FindCutIntegralEquivalences[integrals, topologyRecords, \"Normalization\" -> definition] finds exact equivalences under unit-Jacobian affine changes to independent positive-energy cut momenta. It preserves cut powers and ordinary propagator prescriptions and records both changes of variables. This is a sufficient equivalence test, not an IBP reduction.";

ConstructGlobalMasterDifferentialSystem::usage =
  "ConstructGlobalMasterDifferentialSystem[familySystems, cutEquivalences] assembles the shared differential system and eliminates algebraic identities implied by overlapping family equations. It stores exact integral substitutions and checks their differential compatibility at rational points. It reports a spanning bound, not a proof of minimality.";

ReduceMasterIntegralSolutionConstants::usage =
  "ReduceMasterIntegralSolutionConstants[solutions, globalSystem] substitutes shared integral values into explicit finite master solutions, propagates Laurent orders and imports existing finite lower-sector solutions when reference points differ. It never equates values at different points.";

ConstructHomogeneousBlockLimits::usage =
  "ConstructHomogeneousBlockLimits[globalSystem, chart] computes general-epsilon homogeneous block residues after valid diagonal integer-power gauges. It retains algebraic multiplicities and reports blocks requiring a nondiagonal local gauge.";
BoundBoundaryDataByScaling::usage =
  "BoundBoundaryDataByScaling[limits, condition, rationalPoint] bounds homogeneous boundary freedom using an independently justified scaling condition on specified master rows. Differential row-span tests establish which complete blocks those rows observe. It does not compute boundary matching.";

DetermineThreeParticlePhaseSpaceScaling::usage =
  "DetermineThreeParticlePhaseSpaceScaling[globalSystem, topologyRecords, boundaryKinematics, normalization] checks a sufficient uniform recoil-mass scaling theorem on unit-cut masters. It verifies tree-denominator forms and positive external projections. Raised-cut rows remain unqualified unless observed through other rows by the DE.";

ConstructRequestedMasterDifferentialSystem::usage =
  "ConstructRequestedMasterDifferentialSystem[globalSystem, requestedMasters] keeps the exact derivative closure of the requested integrals and their embeddings. Unrequested directions are dropped only when no retained differential equation depends on them.";

NormalizeRegularSingularSystem::usage = "NormalizeRegularSingularSystem[system] constructs a rational Fuchsian gauge whose residue exponents have zero integer part at epsilon=0, preserving Jordan multiplicities and lower-sector source terms.";

DecomposeResidueEigenspaces::usage = "DecomposeResidueEigenspaces[normalizedSystem] computes exact generalized eigenspaces of its block-triangular residue, including the full nilpotent parts.";

ConstructFrobeniusBoundaryExpansion::usage = "ConstructFrobeniusBoundaryExpansion[system, exactSeedMatrix, request] computes a finite epsilon-expanded Frobenius counterterm after generic-epsilon mode selection; the result is not a finite-kinematics solution.";

SaturateLaurentColumnBasis::usage = "SaturateLaurentColumnBasis[matrix, epsilon] constructs a basis of the same rational column space that is regular and has full column rank at epsilon=0, with the exact amplitude change of basis.";

RegularSingularGaugeMatrix::usage = "RegularSingularGaugeMatrix[record] multiplies the explicit local gauge factors into their exact rational matrix.";
RemoveCoalescingApparentSingularities::usage = "RemoveCoalescingApparentSingularities[system] removes rational apparent singularities whose positions tend to the normal boundary as epsilon tends to zero, and verifies that their residues vanish.";

ConstructBoundaryConnection::usage = "ConstructBoundaryConnection[data, request] constructs explicit finite epsilon coefficients of the singular-to-ordinary connection by proper integration of a Frobenius counterterm residual.";

DetermineBoundaryCountertermOrder::usage = "DetermineBoundaryCountertermOrder[preparedConnection, gauge, {normalVariable, epsilon}, epsilonRange] determines a sufficient Frobenius counterterm depth from coefficientwise normal-power bounds.";

ConstructSharedBoundaryCoefficientDefinitions::usage = "ConstructSharedBoundaryCoefficientDefinitions[connection, specification] materializes the original-master boundary coefficients at their declared points in a shared finite expression graph.";

ExtendMasterIntegralSolutionForBoundaryBounds::usage = "ExtendMasterIntegralSolutionForBoundaryBounds[solution, ordinaryPointLowerBounds] reuses the prepared DE and extends only epsilon coefficients needed by the changed boundary normalization.";

ExpressFamilyBoundaryConstantsInGlobalBasis::usage = "ExpressFamilyBoundaryConstantsInGlobalBasis[solutions, globalSystem, requestedClosure, bounds, normalCoordinates] replaces local ordinary-point constants by global original-master coefficients evaluated at the same points.";

ApplySharedBoundaryCoefficientDefinitions::usage = "ApplySharedBoundaryCoefficientDefinitions[familySolution, sharedData, sharedFile] returns a compact stored solution and its validated explicit form in the reduced boundary amplitudes.";


PrepareSingularBoundarySystem::usage="PrepareSingularBoundarySystem[system] removes coalescing apparent poles, normalizes the regular singular point, retains generalized residue eigenspaces, and prepares a finite residual-integral connection. It does not select physical modes.";
DetermineBoundaryAmplitudeOrders::usage="DetermineBoundaryAmplitudeOrders[preparation,saturatedSeed,originalBounds] derives conservative Laurent bounds for amplitudes and original-master connection entries from exact gauges and connection paths.";
ConstructSingularBoundaryConnection::usage="ConstructSingularBoundaryConnection[preparation,seed,request] determines the sufficient subtraction order and stores an explicit finite singular-boundary connection through the requested epsilon orders.";

PrepareProcessDiagrams::usage = "PrepareProcessDiagrams[setup] generates all diagrams once for reuse within a run with fixed FeynArts model data. Pass the returned record as the PreparedDiagrams option to CollinearFactorizePreIBP; process and loop-order changes are rejected, and each diagram selection is validated.";
