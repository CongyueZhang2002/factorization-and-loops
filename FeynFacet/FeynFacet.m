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

ClassifyBlocks::usage =
  "ClassifyBlocks[blocks] quotients a block set by connection equivalence: basis permutation composed with an optional v<->w relabelling. Blocks are bucketed by permutation-invariant multisets and then matched exactly, so every class member carries an explicit permutation and swap that reproduce its connection matrices from the representative entry by entry. Classes are keyed by the content address of their exact orbit key; integer ClassID labels are a convenience only.";

CanonicalizeClasses::usage =
  "CanonicalizeClasses is RETIRED (overhaul 2026-09-02): the CANONICA class ladder is retired; DiagonalBlockClassCampaign (finite-field route) canonicalizes classes; implementation in Private_Backup/CanonicalBlocks.wl; the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

ValidateCanonicalForm::usage =
  "ValidateCanonicalForm[form] certifies an epsilon-form by exact dlog reconstruction: it extracts the alphabet, requires every residue matrix to be constant, and requires the stored matrices to be reproduced exactly as eps times the sum of residues against dlog of the letters. form may be a canonical-form record, a form file, or matrices with their variables. Any stored \"Validated\" flag is ignored, because CANONICA reports a failed sector as {False,{partial,partial}}, which has the same shape as a success.";

CanonicalBlocksStatus::usage =
  "CanonicalBlocksStatus[formDirectory] prints one greppable line per stored canonical-form file giving class, content address, dimension, ansatz degree and frame, and a closing summary. With \"Classes\" it also lists the classes that have no form yet, and with \"Validate\"->True it re-runs ValidateCanonicalForm on every stored form. It is meant to be called from a second kernel while a campaign runs.";

TransportFamily::usage =
  "TransportFamily is RETIRED (overhaul 2026-09-02): the observable transport (BuildObservableTransport) is the production route; the Libra path-ordered engines live in Private_Backup; the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks::usage =
  "AssembleFamilyDifferentialSystemWithEpsilonFormDiagonalBlocks[system,coefficientPresentation] re-expresses a two-variable family differential system using either a RationalizingParametrization or SquareRootGeneratorsAndQuadraticRelations, composes the certified diagonal-block basis transformations, and re-derives every transformed diagonal connection block. The result has epsilon-form diagonal blocks and general lower off-diagonal blocks; it does not claim that the whole family is in epsilon form. The assembly verifies the block transformations, their inverses, the transformed connection equation, block lower-triangularity, and flatness according to the selected check level.";

TransportPathArtifactRun::usage =
  "TransportPathArtifactRun is RETIRED (overhaul 2026-09-02): the path-transport exception seam is retired with the Libra engines; use BuildObservableTransport; the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

LibraFamilyEpsForm::usage =
  "LibraFamilyEpsForm is RETIRED (overhaul 2026-09-02): the whole-family Libra construction is kept, unloaded, in FeynFacet/Private_Backup/LibraEpsForm.wl. Calls return <|\"Status\" -> \"RouteRetired\", ...|>. The family completion runs through the per-sector epsilon-form driver, FactorFamilyRegulatorDependence, and ValidateFamilyDLogEpsilonForm.";

TransportStatus::usage =
  "TransportStatus is RETIRED (overhaul 2026-09-02): status printer of the retired TransportFamily route (Private_Backup/MasterTransport.wl); the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

TransportWord::usage =
  "TransportWord is RETIRED (overhaul 2026-09-02): path-ordered transport word structure of the retired TransportFamily route (Private_Backup/MasterTransport.wl); the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

TransportQuadrature::usage =
  "TransportQuadrature is RETIRED (overhaul 2026-09-02): quadrature structure of the retired TransportFamily route (Private_Backup/MasterTransport.wl); the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

TransportConstant::usage =
  "TransportConstant[block,order,index] is a symbolic integration constant of TransportFamily: component index of the constant vector of the given block at the given epsilon order. The valuation constraints are linear equations on these, and the boundary-fixing stage substitutes them.";

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

SolveEpsFormStripInFrame::usage =
  "SolveEpsFormStripInFrame[{E,C,B},{v,w},eps,frame] identifies the square roots occurring in one off-diagonal strip, chooses the least complicated exact catalog chart containing those roots, solves the rational strip with SolveEpsFormStrip, and pulls the dlog gauge back to the original algebraic frame. It returns a gauge only after exact chart composition, branch-consistent round-trip, and transformed-one-form identities are satisfied. Epsilon factorization remains the subsequent whole-sector step. When the root set has no joint rational chart, the strip is dispatched to the direct multiquadratic engine (\"MultiquadraticDispatch\" -> True, the default; \"MultiquadraticOptions\" are passed to it). That engine returns \"Solved\" only after one rational-in-regulator gauge is reconstructed, its active dlog potentials are certified, and independent fresh provider residuals pass; otherwise it returns a typed incomplete or \"ModularConsistent\" result which the caller must not install. \"NoRationalStripChart\" is returned only when the engine itself refuses the input as outside its scope, and then carries \"MultiquadraticDispatch\" -> \"OutOfScope\" with the engine's typed refusal under \"MultiquadraticRefusal\". \"Deadline\" (an absolute AbsoluteTime[] value; Infinity, the default, is unbounded) bounds strip construction cooperatively and is handed on to the selected solver unless its option bundle already carries an explicit \"Deadline\". On expiry it returns a typed resumable \"BudgetExhausted\" record rather than $Aborted, $Failed, or an exception. \"GaugePullBackMode\" is \"Exact\" (default) or \"FiniteFieldReconstruct\"; any other name, including the retired \"MapleCanonical\" (Maple canonical gauge, overhaul 2026-09-02), is refused typed as \"InvalidGaugePullBackMode\".";

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

SolveResidueRationalGauge::usage =
  "SolveResidueRationalGauge is RETIRED (overhaul 2026-09-02): the Maple residue-gauge route; the finite-field strip route (SolveEpsFormStripFiniteField, SolveEpsFormStripInFrame) replaces it; the symbol answers <|\"Status\" -> \"RouteRetired\", ...|>.";

SolveEpsFormStrip::usage =
  "SolveEpsFormStrip is RETIRED (overhaul 2026-09-02): the CANONICA degree ladder and Maple residue solver it implemented are kept, unloaded, in FeynFacet/Private_Backup/EpsFormStrip.wl. Calls return <|\"Status\" -> \"RouteRetired\", ...|>. Use SolveEpsFormStripInFrame (finite-field route). Options[SolveEpsFormStrip] remains the option set the in-frame solver filters.";

NormalizeEpsFormAffineSample::usage =
  "NormalizeEpsFormAffineSample[sample,columns,p] fixes an affine finite-field solution so that its selected nullspace-coordinate block is the identity and its particular solution vanishes in those coordinates. It returns the normalized particular vector and nullspace basis modulo the prime p.";

ReconstructEpsFormStrip::usage =
  "ReconstructEpsFormStrip[record,modularData] combines modular epsilon interpolations by Chinese remaindering, performs bounded rational reconstruction, rebuilds the rational gauge and dlog residues, and returns them only when the letters are regulator-free, the residues are free of the kinematic variables, and both exact Pfaffian equations vanish (DLogFormCertified); CanonicalEpsFormCertified additionally reports whether the residues are regulator-free (the sector driver factorizes the regulator afterwards). record contains Strip, Variables, and Regulator.";

VerifyEpsFormStrip::usage =
  "VerifyEpsFormStrip[record,solution] checks the structural conditions first (LettersEpsFree: the alphabet is regulator-free; ResiduesKinematicsFree: the residue matrices are free of both variables; ResiduesEpsFree: and of the regulator), then substitutes the gauge and residues into both unspecialized Pfaffian equations. ExactPfaffianResidualsZero reports the literal identities; DLogFormCertified (identities, regulator-free letters, kinematics-free residues) is the strip acceptance; CanonicalEpsFormCertified adds regulator-free residues.";

PrepareEpsFormStripSampling::usage =
  "PrepareEpsFormStripSampling[record] computes once the regulator- and prime-independent setup of one off-diagonal block for finite-field sampling: the letter alphabet, the dlog derivative table, the residue-unknown layout and forcing coefficients, the denominator factor census and the gauge denominator. The result carries a fingerprint of the strip; SampleEpsFormStripAffine accepts it through the \"Preparation\" option and verifies the fingerprint before reuse, recomputing otherwise. SolveEpsFormStripFiniteField prepares once per solve and shares the preparation across the degree probe and every sample of every prime.";

SampleEpsFormStripAffine::usage =
  "SampleEpsFormStripAffine[record,epsilonValue,prime] constructs the rational-gauge and constant-dlog-residue equations for one two-variable off-diagonal block, samples them at exact finite-field kinematic points, and returns the affine solution space at the chosen regulator value. With \"DiscoverPlan\" -> True the full four-elimination solve also returns an \"EliminationPlan\" (normalization columns, a row basis, the verified square constrained core); with \"EliminationPlan\" -> plan the sample is solved by ONE factorization of the constrained core with nullity+1 right-hand sides, every original row is checked, and a failing sample is returned with a typed Discard status instead of a solution. \"Preparation\" accepts the once-per-block setup from PrepareEpsFormStripSampling.";

InterpolateEpsFormStripAffine::usage =
  "InterpolateEpsFormStripAffine[samples,prime] fixes one common affine normalization and reconstructs every gauge and residue coordinate as a rational function of the regulator over the prime field, using independent regulator points for exact validation.";

FactorFamilyRegulatorDependence::usage =
  "FactorFamilyRegulatorDependence[{Ax, Ay}, {x, y}, eps] finds one constant (chart-independent) transformation T(eps) that makes the dlog-form family connection eps-factored, T^-1 A T = eps (eps-free), with Libra FactorDependence on exact rational samples of A/eps; the unsampled symbolic identity is the acceptance test. Returns Status \"OK\" with Transformation, Inverse and the new Connection, \"AlreadyEpsFactored\" (identity), \"NotFactored\" with the attempts, or \"RegulatorFactorizationDeadlineExpired\" with the Stage it stopped at. Replaces the per-sector CANONICA TransformDlogToEpsForm step (2026-08-22). Options: \"TimeLimit\" (900, one subcall), \"Deadline\" (Infinity; an ABSOLUTE AbsoluteTime[] budget for the whole stage, checked at every stage boundary and capping every bounded subcall), \"UseFermat\", \"Verbose\".";
FactorFamilyRegulatorDependenceInFrame::usage =
  "FactorFamilyRegulatorDependenceInFrame[{Ax, Ay}, {x, y}, eps, frame] is FactorFamilyRegulatorDependence for a connection in a multiquadratic identity frame: the roots present in the connection are classified against the frame's root list, the connection is pulled back to the smallest catalogued rational chart for that root set (TransportRootSetChart), the constant T(eps) is found there and applied in the source frame, where the eps-factorization and the inverse identity are verified exactly. Status \"NoRationalChart\" means the root set has no joint rational chart AND FactorFamilyRegulatorDependenceMultiquadratic, which is attempted next, also refused (its diagnostics travel in \"MultiquadraticFactorization\"): the caller must stop (typed) rather than continue with regulator-dependent residues. Rational connections go straight to FactorFamilyRegulatorDependence.";
FactorFamilyRegulatorDependenceMultiquadratic::usage =
  "FactorFamilyRegulatorDependenceMultiquadratic[{Ax, Ay}, {x, y}, eps, roots] finds the constant T(eps) IN THE GRADED ALGEBRA Q(x,y)[r_1,...,r_k]/(r_i^2-q_i), for a root set that has no joint rational chart (for three independent quadratic roots the triple cover is a K3 surface, which carries no global rational parameterization). T lies in grade 0, so conjugation acts grade by grade: the connection is decomposed into its 2^k grade components -- ordinary rational matrices -- and Libra FactorDependence is run on exact rational samples of every component, the same ExactRationalSamples strategy as the rational route, per grade. Acceptance is exact and made in the algebra: every grade of T^-1 A T is eps-factored identically in (x, y), T T^-1 = 1 exactly, and the composed algebraic connection is spot-checked against the direct product with the r-symbol zero test; a sign-sheet corroboration at fresh primes evaluates the conjugated object on all 2^k embeddings of a split point. Numeric square classes introduced by radical denesting (Sqrt[2]) are carried as extra graded generators, so no Together decides an equality on a non-canonical form. COMPLETENESS BOUNDARY: the linear solve is run on the ordinary rational grade matrices and therefore admits only a T with entries in Q(eps). The grade-zero argument is exact for the non-isotrivial roots, whose squares depend on the chart variables, but a valid constant transformation may carry a numeric square class (Sqrt[2] eps is constant in {x,y} and has nonzero numeric-root grade), so over a constant field with numeric classes this is a SUFFICIENT solver, not a complete one; a failure with numeric classes present returns the narrowed typed refusal \"ConstantFieldRestriction\" (with the generators responsible and Complete -> False) rather than the unqualified \"NotFactored\". Returns Status \"OK\", \"AlreadyEpsFactored\", or a typed refusal (\"GradeDecompositionFailed\", \"NotFactored\", \"ConstantFieldRestriction\", \"GradeNotEpsFactored\", \"ExactGradeCheckTimedOut\", \"GradedRankTooLarge\", \"RegulatorFactorizationDeadlineExpired\", ...). Options: \"TimeLimit\", \"Deadline\" (Infinity; an ABSOLUTE stage budget checked before and after the grade decomposition, at every point-ladder rung, at the exact check, and before the spot checks and the corroboration, which are evidence stages and are skipped -- recorded in \"DeadlineSkippedStages\" -- rather than discarding an accepted exact factorization), \"UseFermat\", \"PointLadder\", \"GatePoints\", \"ExactCheckTimeLimit\", \"CorroborationPrimes\", \"RoundTripSpotChecks\", \"SpotCheckTimeLimit\", \"Verbose\".";
EpsFormStripObstruction::usage =
  "EpsFormStripObstruction[record] is the order-by-order (in the regulator) obstruction certificate for the eps-form completion of one off-diagonal block record {e, c, bbar}: at each order the closed rational form w_k = e D_{k-1} - D_{k-1} c + B_k must have constant residues along its polar curves. Returns Status \"NoObstructionToOrder\" (with the gauge series D_k and their numerator degrees; a rational solver's failure is then an ansatz or budget limitation), \"MissingLetters\" (polar curves outside the block alphabet with nonzero constant residue: extend the alphabet with them and re-solve), \"NonConstantResidue\" (proof that no rational gauge exists with the present diagonal eps-forms and letters; the pair needs a basis change such as the blockwise Libra balances), \"PrimitiveNotRational\" or \"NotClosed\". Options: \"MaximumOrder\" (4), \"ExtraLetters\", \"TransverseLines\" (3), \"Verbose\".";
SolveEpsFormStripFiniteField::usage =
  "SolveEpsFormStripFiniteField[record] searches a rational-gauge degree ladder, samples and interpolates over successive prime fields, lifts by Chinese remaindering and rational reconstruction, and returns a gauge only after both unspecialized Pfaffian equations vanish exactly. The block setup is prepared once per solve; a pilot sample discovers the constrained elimination plan that every later sample reuses (\"Elimination\" -> \"Constrained\" default, \"Full\" forces the four-elimination path). Since 2026-08-21 three optimizations are default: an a-priori sparse gauge-numerator support from the preparation valuation census (\"Support\", the shell-growth ladder falls back to the full bidegree rectangle), held-out incremental regulator sampling with an unseen-prime residual before the exact check (\"RegulatorSampling\" -> \"HeldOut\", or \"Deterministic\" for the fixed schedule), and an optional FLINT modular-solve backend for the constrained core (\"Backend\" -> Automatic; every FLINT solution is re-verified in Wolfram). Every prime artifact carries per-sample stage timers. Modular data can be retained in an artifact directory and resumed.";

InstallEpsFormStripSolution::usage =
  "InstallEpsFormStripSolution[checkpoint,record,solution,sector,lowerSector] appends one exactly verified strip gauge to a descending sector checkpoint after checking dimensions and strip order; the regulator-free alphabet and kinematics-free residues are recomputed from the solution, so a lift that is not a dlog form cannot be installed.";

ExactlyValidatedFamilyDLogEpsilonFormQ::usage =
  "ExactlyValidatedFamilyDLogEpsilonFormQ[record] returns True only when a FamilyDLogEpsilonForm with Status \"FamilyDLogEpsilonFormValidated\" carries characteristic-zero symbolic validation of its basis-transformation inverse, connection-transformation equation, epsilon factorization, constant-residue dlog representation, coefficient-presentation relations, and flatness. Validation strength is read from Validation, not from Status.";

ValidatedFamilyDLogEpsilonFormQ::usage =
  "ValidatedFamilyDLogEpsilonFormQ[record] returns True when a FamilyDLogEpsilonForm with Status \"FamilyDLogEpsilonFormValidated\" carries internally consistent exact or probabilistic evidence for its defining equations. Validation strength is read from Validation; probabilistic evidence is never reported as exact, regardless of the number of square-root generators.";

ValidateFamilyDLogEpsilonForm::usage =
  "ValidateFamilyDLogEpsilonForm[record,system] re-derives the defining equations of a candidate family dlog epsilon form from the differential system, coefficient presentation, ordered diagonal blocks, basis transformation, letters, and constant residue matrices. Every accepted result has Status \"FamilyDLogEpsilonFormValidated\". IdentityMethod -> \"Symbolic\" records characteristic-zero validation; \"RandomPoints\" records random-rational-point evidence; and \"Modular\" records Method \"ProbabilisticFiniteFieldSampling\" for both rational and square-root coefficient presentations. The result contains no content digests or settings-dependent acceptance conditions.";

FamilyArtifactRead::usage =
  "FamilyArtifactRead[file] reads one Wolfram Language artifact with the context path restricted to System` and Global`, so that symbols in the file never resolve into a package context loaded earlier in the session (in particular CANONICA`). Every campaign or worker read of a stored record or differential system must use this function. Returns $Failed when the file is missing or unreadable. FamilyArtifactRead[file, context] reads with the guard context explicit (default \"Global`\"); evaluation-time messages no longer discard a valid artifact, parser failures stay typed, and the collected messages are in FeynFacet`Private`$familyArtifactReadMessages (2026-08-23).";

FamilyArtifactWrite::usage =
  "FamilyArtifactWrite[value,file] writes one artifact atomically: Put to a temporary name in the target directory followed by RenameFile. Returns the file path.";

DiagonalBlockEpsForm::usage =
  "DiagonalBlockEpsForm[{Ax,Ay},{x,y},eps] constructs and certifies the epsilon form of one irreducible diagonal block in a rational two-variable chart: one spectator slice is normalized by Lee balances and factored (Libra), which fixes the constant residues of every letter depending on x; the x-equation d_x T = Ax T - T Bx is then a homogeneous linear system for a rational T with letter denominators and is solved by finite-field sampling, regulator interpolation, Chinese remaindering and rational reconstruction; the pure-y residues and the rational scalar gauge are read off exactly from the y-direction; the only acceptance is the exact two-variable gate. Returns an Association with Status \"Certified\", Transformation, Letters, Residues, EpsForm and stage timings. The block's variables and regulator are the symbols given, whatever they are named. \"ChartRetry\" (default True) retries a block with exactly one regulator-free irreducible quadratic denominator in a chart: the conic parametrization of CanonicalBlocks and the catalog chart of TransportCharts whose root square is that quadratic, matched positionally by TransportRootSetChart and rekeyed to the block's own variables, so the retry never depends on the variables being named v and w. \"ChartParameter\" is Automatic, which is Global`t unless t is one of the block's own symbols and a fresh package-private symbol otherwise; a parameter equal to one of the block's variables is refused with Status \"ChartParameterCollides\".";

DiagonalBlockSliceEpsForm::usage =
  "DiagonalBlockSliceEpsForm[{Ax,Ay},{x,y},eps] computes the constant residues of the block's epsilon form on a generic rational slice y = y0 by Lee balances and maps every slice locus to a letter of the block. The default engine \"NumericalEps\" specializes the regulator to a fixed rational number (1/101) before the balance chain -- exact arithmetic over Q(x); the residue tuple is then M_a(e)/e, a constant conjugate of the true one, and is brought to a canonical small-height frame. \"Engine\" -> \"Symbolic\" keeps eps symbolic and finishes with Lee's linear factor-out step. Returns SliceLetters with SliceResidues (constant matrices), the balance path and timings.";

SolveDiagonalBlockGaugeFiniteField::usage =
  "SolveDiagonalBlockGaugeFiniteField[{Ax,Ay},{x,y},eps,sliceData] solves the x-equation d_x T = Ax T - T Bx, Bx = eps Sum_a R_a d_x log phi_a with the slice residues R_a, for a rational T over a letter-denominator ansatz by finite-field sampling (pilot full nullspace, then one constrained LinearSolve per sample with an all-row check), per-prime regulator interpolation, Chinese remaindering and rational reconstruction; the result is accepted only after the exact x-equation holds.";

CompleteDiagonalBlockEpsForm::usage =
  "CompleteDiagonalBlockEpsForm[{Ax,Ay},{x,y},eps,solve] takes a transformation solving the x-equation and determines exactly, from T^-1 Ay T - T^-1 d_y T, the constant residues of the pure-y letters and the rational scalar gauge with integer exponents that removes the remaining scalar dlog terms.";

CertifyDiagonalBlockEpsForm::usage =
  "CertifyDiagonalBlockEpsForm[{Ax,Ay},{x,y},eps,T,letters,residues] is the exact gate: the source connection pushed through T equals eps Sum_a R_a dlog phi_a entrywise in both variables, the residues are constant, the letters are regulator-free, the form is flat, and T is invertible.";

DiagonalBlockClassCampaign::usage =
  "DiagonalBlockClassCampaign[classes,directory] runs DiagonalBlockEpsForm over class representatives (a list of class records or the path of classes.wl) and writes one ledger record per class in the CanonicalizeClasses schema (Transformation, EpsForm, Variables, Chart, Frame, Method, Seconds, Validated). Options: \"Kernels\" (subkernel pool under one main kernel), \"Overwrite\", \"TimeConstraint\" per class, \"Fallback\" -> \"CANONICA\" to try the CANONICA ladder when the finite-field route does not certify, \"CanonicaValidation\" to re-check every record with ValidateCanonicalForm. \"Variables\" and \"Regulator\" are Automatic: each class record's own \"Variables\"/\"Regulator\" is preferred, then the regulator is detected from the representative matrices by name (eps, Eps, epsilon, Epsilon, ep), then Global`v, Global`w and Global`eps; an explicit option overrides the record. A record that declares other than two variables gets a failure record with Status \"ClassVariablesNotTwoSymbols\" instead of being solved as a pair.";

DiagonalBlockLetters::usage =
  "DiagonalBlockLetters[{Ax,Ay},{x,y},eps] returns the regulator-free irreducible denominator factors of the block (the candidate letters) and the regulator-dependent ones (apparent singularities).";

FamilyEpsilonFormRecord::usage =
  "FamilyEpsilonFormRecord[record] normalizes one family epsilon-form record to the standard schema: the diagonal-block list is converted to plain index lists (the annotated {indices, classId} layout is accepted), verified to flatten to a basis permutation, and the required analytic fields are checked for presence. Returns the normalized record, or an Association whose \"Status\" names the defect.";

BuildObservableTransportManifest::usage =
  "BuildObservableTransportManifest[epsilonFormDirectories,differentialSystemDirectory,valuationsFile,manifestFile] discovers every differential-equation family, selects the first exactly certified whole-family epsilon form from the ordered directories, and writes the transport manifest atomically. The returned Association names the selected, missing, rejected, and multiply represented families; a directory in which no file yields a family name returns \"NoDifferentialFamiliesFound\" rather than an empty complete inventory. Option \"Card\" appends one common transport card to every manifest row; \"ReportFile\" writes the complete inventory as Wolfram Language data. The artifact naming is the campaign's: \"DifferentialFilePattern\" and \"EpsFormFilePattern\" select the files, \"FamilyFromFileName\" maps a file name to its family (Automatic takes the one canonical-family token in the base name), and \"FamilySortKey\" (default Identity) orders the manifest rows.";

BuildObservableTransportDemand::usage =
  "BuildObservableTransportDemand[familyEpsForm,familySystem,valuations] maps the exact coefficient valuations of the family's canonical masters into the epsilon-order/master-row pairs required from that family. Options specify the hard-function orders, safety orders, master valuation and transport path. The map is derived from familySystem[\"BlockBasis\"] and the permutation stored in familyEpsForm[\"Blocks\"].";

FindObservableTransportPath::usage =
  "FindObservableTransportPath[familyEpsForm] selects a deterministic rational base and target sample. For a multiquadratic record it first seeks a regular base at which every declared root is a nonzero rational number, then falls back to the first regular rational path; rational-family selection is unchanged. It fixes no physical branch; the polynomial dlog map remains the primary analytic record.";

BuildObservableTransport::usage =
  "BuildObservableTransport[familyEpsForm,demand] constructs only the iterated-integral maps that can contribute to the requested epsilon-order/master-row pairs. familyEpsForm is an exactly certified whole-family epsilon-form record. demand declares PhysicalDemandPairs (or the older Cartesian PhysicalRows and PhysicalOrders form), PhysicalValuation and Path. The routine first imposes the vanishing Laurent coefficients of the physical masters, derives the exact allowed boundary subspace, keeps its constants factored, and then propagates only nonzero projected dlog words. Every returned kernel, residue decomposition and differential invariant is checked symbolically.";

ComputeTruncatedLocalFrobeniusExpansion::usage =
  "ComputeTruncatedLocalFrobeniusExpansion[connection,spec] computes a finite local Frobenius prefactor H(rho,eps) and connection residue R for an epsilon-form connection, so that the retained local solution is H(rho,eps) rho^(eps R) c. spec gives Variable, Regulator, LocalExpansionPoint, and optionally LocalVariable, LocalDirection (+1 or -1), and FixedRules; options set the retained local and epsilon orders. The result records PointType as OrdinaryPoint or RegularSingularPoint. LocalDirection defines variable=LocalExpansionPoint+LocalDirection rho and includes the differential Jacobian. Non-epsilon-form or non-Fuchsian local connections are refused with typed statuses.";

TransformTangentialConnectionToNormalResidueEigenbasis::usage =
  "TransformTangentialConnectionToNormalResidueEigenbasis[normalResidue,tangentialConnection,spec] transforms a normal connection residue and the tangential connection to a supplied moving eigenbasis of the normal residue, including the derivative of that basis. spec gives TangentialVariable, Regulator, NormalResidueEigenbasis, and LocalExponents. The eigenbasis may be rational in the tangential variable and regulator; its columns must diagonalize the normal residue. The result contains TangentialConnectionInEigenbasis, EqualExponentSectors, and the integer/regulator split of every local exponent. Coupling between unequal exponent sectors is refused.";

MatchBoundaryAsymptoticsToFrobeniusModes::usage =
  "MatchBoundaryAsymptoticsToFrobeniusModes[frobenius,basisTransformation,spec,realizations] matches declared physical-limit asymptotics to local Frobenius modes after applying the basis transformation and truncated local prefactor. spec must declare BoundaryDomain as either a PhysicalBoundaryPoint or a PhysicalBoundaryStratum with its TangentialVariables; the result therefore distinguishes boundary constants from boundary functions. A relation between a physical limiting variable and the local expansion coordinate is recorded explicitly, including any required logarithm branch.";

DegenerateResidueEigenspaceBasis::usage =
  "DegenerateResidueEigenspaceBasis[mode,modes] returns the echelon basis and dimension of the degenerate normal-residue eigenspace containing mode. Degeneracy alone does not imply a relation among boundary constants or functions; such a relation must be supplied separately.";
ConstructMasterIntegralSolution::usage =
  "ConstructMasterIntegralSolution[family,\"InputFiles\"->files] constructs every requested epsilon coefficient of every requested physical master integral as an explicit sum of formal Chen iterated integrals multiplied by typed boundary constants or boundary functions. files explicitly names the family differential equation, requested-output coefficient operator, boundary-asymptotic matching, and regularized boundary-to-base-point evolution records. DemandCoverage and BoundaryDataStatus report independent properties of the result.";
MasterIntegralSolutionQ::usage =
  "MasterIntegralSolutionQ[result] revalidates a V2 MasterIntegralSolution, including coverage of every requested epsilon coefficient, allowed symbolic heads, the differential equation, and boundary-asymptotic matching.";
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
  "BoundaryFunctionEpsilonCoefficient[id,order] is an inert exact placeholder for the coefficient of epsilon^order in the boundary function identified by id on a physical boundary stratum.";

FormalChenIteratedIntegral::usage =
  "FormalChenIteratedIntegral[letterSequence,{variable,lowerLimit,upperLimit},curve,curvePointValues] is an inert Chen iterated integral. The letter sequence is ordered outermost first; curve is None for multiple polylogarithms and a square-free quartic for elliptic multiple polylogarithms. An optional fifth argument records a tangential-base-point prescription.";
AlgebraicMarkedPoint::usage =
  "AlgebraicMarkedPoint[coefficients,index] denotes an indexed marked point defined as a root of a polynomial whose ascending coefficient list may contain spectator kinematic variables.";
IteratedIntegralKernel::usage =
  "IteratedIntegralKernel[label,variable,curve] returns the coefficient of the integration one-form represented by a GPLPole, GPLFactor, E4Pole, E4Factor, E4Omega0, E4OmegaInf or E4Eta2 label.";
ExpandIteratedIntegralLetterSequence::usage =
  "ExpandIteratedIntegralLetterSequence[letterSequence,variable,curve,definitions] expands one requested sequence of factor or composite letters into marked-point letters for multiple or elliptic multiple polylogarithms.";
BuildCompactEndpointResidue::usage =
  "BuildCompactEndpointResidue[letters,residueMatrices,variable,endpoint] computes the exact simple-pole residue directly from aligned sparse square or rectangular matrices in the inert GPL/eMPL alphabet, without constructing a symbolic connection. Options declare a quartic Curve and CompositeDefinitions.";
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
ComposeTangentialJunctionWordMaps::usage =
  "ComposeTangentialJunctionWordMaps[binding,upstreamTerms,downstreamTerms,outputOrder] contracts demanded sparse maps across a regularized tangential junction. It preserves each ordered {upstream word,downstream word} pair, epsilon-order routing and the original Stage-3 boundary coordinates without shuffle expansion or dense transport materialization.";
AttachBoundarySelectorsToRationalEpsilonDependentBlock::usage =
  "AttachBoundarySelectorsToRationalEpsilonDependentBlock[source,block,boundarySelectorData,sourceRows,targetRows] splits full-system boundary selector matrices into source and rational-epsilon-dependent-block rows while preserving their shared boundary-constant or boundary-function epsilon-coefficient labels.";
ConstructMasterIntegralEpsilonExpansionCoefficient::usage =
  "ConstructMasterIntegralEpsilonExpansionCoefficient[operator,boundaryValueData,{epsilonOrder,masterIntegralRow},path] constructs one requested master-integral epsilon-expansion coefficient from its iterated-integral coefficient operator, the off-diagonal basis-transformation block at the path endpoint, an optional CanonicalToPhysicalMasterIntegralMapByEpsilonOrder, and the boundary-value vector. A tangential-base-point prescription is retained in every nonempty formal iterated integral.";
AcceptedObservableTransportQ::usage =
  "AcceptedObservableTransportQ[result] checks the required named exact certificates and, according to the representation and boundary method, every fresh modular closure, ambient-invariance and quotient-coordinate certificate. It keeps probabilistic structural acceptance distinct from an exact symbolic identity.";

CertifyTransportEpsilonValuations::usage =
  "CertifyTransportEpsilonValuations[record] certifies the TransportEpsilonValuations (TMin, BlockLower) of a transport-ready family epsilon-form record by three independent p-adic trials at fresh primes and random rational kinematic points, and returns <|\"Status\" -> \"TransportEpsilonValuationsCertified\", \"Record\" -> the record with the certificate attached, \"Tight\" -> ..., \"Certificate\" -> ...|>; a record without valuations gets them derived from the trials; a claim above the observed orders or an ill-formed record is refused typed (\"TransportEpsilonValuationsTooHigh\", \"TransportEpsilonValuationsInvalid\", \"IncompleteFamilyEpsilonFormRecord\", ...). CertifyTransportEpsilonValuations[file] certifies the record stored in file in place (atomic replace; options \"Write\" -> False for a dry run, \"OutputFile\" for a copy) and returns the certificate status without the record; an already certified file reports \"AlreadyCertified\" -> True. BuildObservableTransport uses a record's valuations only when this certificate is present and bound to the record.";

ObservableTransportWordMap::usage =
  "ObservableTransportWordMap[result,firstWord,secondWord] returns one demanded matrix-valued word from a materialized record, the exact lazy operator chain, or the optional compact quotient automaton. Lazy evaluation preserves the ordered product D R_word B K_word N_base and performs no global rational canonicalization.";

ReconstructObservableTransportWordMaps::usage =
  "ReconstructObservableTransportWordMaps[result,{{firstWord,secondWord},...}] materializes only the requested rational word maps, reconstructs all their final entries as one traced multi-right-hand-side Ratracer problem, and accepts the result at fresh modular points with the independent FLINT solver. Intermediate gauges and nullspaces are not reconstructed.";

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
SyntaxInformation[SolveResidueRationalGauge] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[SolveEpsFormStrip] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[NormalizeEpsFormAffineSample] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ReconstructEpsFormStrip] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[VerifyEpsFormStrip] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[SampleEpsFormStripAffine] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[InterpolateEpsFormStripAffine] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[SolveEpsFormStripFiniteField] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
SyntaxInformation[InstallEpsFormStripSolution] =
  {"ArgumentsPattern" -> {_, _, _, _, _}};
SyntaxInformation[ExactlyValidatedFamilyDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ValidatedFamilyDLogEpsilonFormQ] =
  {"ArgumentsPattern" -> {_}};
SyntaxInformation[ValidateFamilyDLogEpsilonForm] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[BuildObservableTransportManifest] =
  {"ArgumentsPattern" -> {_, _, _, _, OptionsPattern[]}};
SyntaxInformation[BuildObservableTransportDemand] =
  {"ArgumentsPattern" -> {_, _, _, OptionsPattern[]}};
SyntaxInformation[FindObservableTransportPath] =
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
SyntaxInformation[BuildObservableTransport] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[ComputeTruncatedLocalFrobeniusExpansion] =
  {"ArgumentsPattern" -> {_, _, OptionsPattern[]}};
SyntaxInformation[TransformTangentialConnectionToNormalResidueEigenbasis] =
  {"ArgumentsPattern" -> {_, _, _}};
SyntaxInformation[ConstructMasterIntegralSolution] =
  {"ArgumentsPattern" -> {_, OptionsPattern[]}};
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
SyntaxInformation[BuildCompactEndpointResidue] =
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
SyntaxInformation[ComposeTangentialJunctionWordMaps] =
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
SyntaxInformation[SolveEpsFormStripInFrame] =
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
$feynFacetSourceHash = Hash[
  FileHash[#, "SHA256"] & /@ $feynFacetSourceFiles,
  "SHA256",
  "HexString"
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
