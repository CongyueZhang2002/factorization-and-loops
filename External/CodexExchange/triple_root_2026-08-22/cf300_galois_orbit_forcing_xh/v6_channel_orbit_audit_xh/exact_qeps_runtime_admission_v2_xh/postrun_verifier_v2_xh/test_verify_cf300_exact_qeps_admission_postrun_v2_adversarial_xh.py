#!/usr/bin/env python3
"""Synthetic positive and adversarial tests for the exact-Q(eps) post-run verifier."""

from __future__ import annotations

import argparse
import copy
import hashlib
import tempfile
import unittest
from dataclasses import replace
from fractions import Fraction
from pathlib import Path

import verify_cf300_exact_qeps_admission_postrun_v2_xh as verifier


def wl(value) -> str:
    if value is None:
        return "None"
    if isinstance(value, bool):
        return "True" if value else "False"
    if isinstance(value, str):
        return json_quote(value)
    if isinstance(value, Fraction):
        return f"{value.numerator}/{value.denominator}"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, (list, tuple)):
        return "{" + ", ".join(wl(item) for item in value) + "}"
    if isinstance(value, dict):
        return "<|" + ", ".join(f"{wl(key)} -> {wl(item)}" for key, item in value.items()) + "|>"
    raise TypeError(type(value))


def json_quote(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def digest(path: Path) -> str:
    return verifier.sha256_file(path)


class Fixture:
    def __init__(self, root: Path):
        self.root = root
        self.project_root = root
        self.admission_driver = root / "run_cf300_sector12_exact_qeps_admitted_v2_xh.wls"
        self.held_gate = root / "held_parse_cf300_exact_qeps_runtime_admission_v2_xh.wls"
        self.frozen_driver = root / "run_cf300_sector12_exact_qeps_left_obstruction_v1.wls"
        self.helper = root / "CF300ExactQepsLeftObstruction.wl"
        self.modular = root / "CF300ModularQepsWitnessReconstruction.wl"
        self.schema = root / "CF300_V6D_EXACT_LIFT_PREREQUISITE_SCHEMA.wl"
        self.kpsubmit = root / "kpsubmit.sh"
        self.v6d = root / "v6d.wl"
        self.exact_manifest = root / "SHA256SUMS_EXACT"
        self.admission_manifest = root / "SHA256SUMS_ADMISSION"
        self.admission_driver.write_text("synthetic admission driver\n", encoding="utf-8")
        self.held_gate.write_text("synthetic held gate\n", encoding="utf-8")
        self.frozen_driver.write_text('synthetic exact driver; "NativeThreads" -> 4\n', encoding="utf-8")
        self.helper.write_text("synthetic exact helper\n", encoding="utf-8")
        self.modular.write_text('synthetic modular source; "NativeThreads" -> 4\n', encoding="utf-8")
        self.schema.write_text("synthetic prerequisite schema\n", encoding="utf-8")
        self.kpsubmit.write_text("synthetic kpsubmit\n", encoding="utf-8")
        self.v6d.write_text("synthetic v6d\n", encoding="utf-8")

        self.exact_sources = {}
        for name in verifier.EXACT_SOURCE_HASHES:
            if name == "ExactWitnessHelper":
                path = self.helper
            elif name == "ModularReconstruction":
                path = self.modular
            elif name == "OrbitCoreV6d":
                path = root / "orbit_core.wl"
                path.write_text("synthetic orbit core\n", encoding="utf-8")
            else:
                path = root / (name + ".source")
                path.write_text(f"synthetic {name}\n", encoding="utf-8")
            self.exact_sources[name] = path
        self.held_sources = {
            "AdmissionDriver": self.admission_driver,
            "FrozenDriver": self.frozen_driver,
            "ExactHelper": self.helper,
            "ModularReconstruction": self.modular,
            "PrerequisiteSchema": self.schema,
        }
        self.runtime_sources = {
            "FrozenDriver": self.frozen_driver,
            "ExactHelper": self.helper,
            "ModularReconstruction": self.modular,
            "PrerequisiteSchema": self.schema,
            "FrozenManifest": self.exact_manifest,
            "KpSubmit": self.kpsubmit,
            "V6dArtifact": self.v6d,
        }
        stable_manifest_file = root / "manifest_stable.source"
        stable_manifest_file.write_text("stable manifest source\n", encoding="utf-8")
        line = f"{digest(stable_manifest_file)}  {stable_manifest_file.name}\n"
        self.exact_manifest.write_text(line, encoding="utf-8")
        self.admission_manifest.write_text(line, encoding="utf-8")

        self.policy = verifier.Policy(
            project_root=str(root),
            exact_source_hashes={key: digest(path) for key, path in self.exact_sources.items()},
            held_source_hashes={key: digest(path) for key, path in self.held_sources.items()},
            admission_runtime_hashes={key: digest(path) for key, path in self.runtime_sources.items()},
            exact_manifest_sha=digest(self.exact_manifest),
            admission_manifest_sha=digest(self.admission_manifest),
            transformed_driver_sha=hashlib.sha256(b"transformed").hexdigest(),
            orbit_core_sha=digest(self.exact_sources["OrbitCoreV6d"]),
            v6d_sha=digest(self.v6d),
        )
        self.inventory = verifier.Inventory(
            exact_sources=self.exact_sources,
            held_sources=self.held_sources,
            admission_runtime_sources=self.runtime_sources,
            held_gate=self.held_gate,
            exact_manifest=self.exact_manifest,
            admission_manifest=self.admission_manifest,
        )

        self.held = root / "held.wl"
        self.prerequisite = root / "prerequisite.wl"
        self.certificate = root / "certificate.wl"
        self.receipt = root / "receipt.wl"
        done = root / "done"
        done.mkdir()
        self.wrapper = done / "exact_admission.wl"
        self.status = done / "exact_admission.status"
        self.log = root / "exact_admission.log"
        self.wrapper_argv = [
            str(self.admission_driver.resolve()), str(root.resolve()),
            str(self.v6d.resolve()), str(self.prerequisite.resolve()),
            str(self.held.resolve()), str(self.certificate.resolve()),
            str(self.receipt.resolve()),
        ]
        self.write_wrapper()
        self.wrapper_pin = digest(self.wrapper)

        points = [[index + 1, 2 * index + 3] for index in range(30)]
        coeff_pivots = list(range(1, 889))
        free = list(range(889, 913))
        aug_pivots = list(range(1, 889)) + [913]
        stable = {
            "MatrixDimensions": [960, 912], "CoefficientRank": 888,
            "AugmentedRank": 889,
            "CoefficientPivotColumns": coeff_pivots,
            "CoefficientFreeColumns": free,
            "CoefficientIndependentEquationRows": list(range(1, 889)),
            "AugmentedPivotColumns": aug_pivots,
            "AugmentedFreeColumns": free,
            "AugmentedIndependentEquationRows": list(range(1, 890)),
            "CoefficientPivotFingerprint": verifier.COEFF_PIVOT_FP,
            "CoefficientFreeFingerprint": verifier.FREE_FP,
            "CoefficientIndependentRowFingerprint": verifier.COEFF_ROWS_FP,
            "AugmentedPivotFingerprint": verifier.AUG_PIVOT_FP,
            "AugmentedFreeFingerprint": verifier.FREE_FP,
            "AugmentedIndependentRowFingerprint": verifier.AUG_ROWS_FP,
        }
        self.prerequisite_object = {
            "Status": "CF300V6dExactLiftPrerequisiteV1",
            "SourceV6dArtifactFile": str(self.v6d.resolve()),
            "SourceV6dArtifactSHA256": self.policy.v6d_sha,
            "OrbitCoreV6dSHA256": self.policy.orbit_core_sha,
            "MaximalAssemblyFingerprint": verifier.ASSEMBLY_FP,
            "MaximalAssembly": {"AssemblyFingerprint": verifier.ASSEMBLY_FP},
            "AnchorImageID": "I00", "AnchorPrime": 10007,
            "AnchorEpsilonValue": Fraction(1, 21),
            "AnchorAcceptedPointResidues": points,
            "ExactRationalPointLifts": points,
            "AnchorAcceptedPointsFingerprint": verifier.POINTS_FP,
            "PointLiftCertificate": {
                "Status": "CertifiedBalancedRationalPointLiftV1", "Prime": 10007,
                "SearchDenominatorBound": 100, "AllDenominatorsInvertible": True,
                "AllReductionsExact": True, "ExactPointsDistinctOverQ": True,
                "AnchorLiftedPointsNonsingularModuloPrimeAtEpsilon": True,
                "CapturedPlanRevalidatedAtLiftedResidues": True,
            },
            "StablePlan": stable,
            "AnchorPlanRevalidation": {
                "Status": "CF300V6dI00StablePlanRevalidatedV1",
                "PlanArraysRevalidated": True, "FullResidualRevalidated": True,
                "AllFrozenFingerprintsExact": True,
                "CrossImagePlanFingerprintStable": True,
            },
            "CapturePolicy": {
                "ReproduceOriginalV6dSeedAndCandidateOrder": True,
                "CompareRecoveredPointFingerprintBeforeLift": True,
                "CompareAllPlanArrayFingerprintsBeforeLift": True,
                "RequireCrossImageFingerprintStability": True,
                "AllowPlanRediscoveryInExactDriver": False,
                "ConsumeV6dScoreColumnIndices": False,
                "ExactRationalPointsNonsingularOverQepsClaimed": False,
            },
        }
        self.held_object = self.make_held_object()
        self.certificate_object = self.make_certificate_object()
        self.receipt_object = {}
        self.status_object = {
            "Mission": self.wrapper.name, "Status": "OK", "HadMessages": False,
            "Wall": 1.0, "Kernel": 24, "Result": 0,
        }
        self.persist()

    def write_wrapper(self, argv=None, helper: int = 0,
                      duplicate: bool = False, import_target: str | None = None) -> None:
        argv = list(self.wrapper_argv if argv is None else argv)
        assignment = "$ScriptCommandLine = {" + ", ".join(wl(item) for item in argv) + "};"
        duplicate_text = "\n    " + assignment if duplicate else ""
        target = argv[0] if import_target is None else import_target
        text = (
            f"Block[{{KernelPoolMission`$TaskBrokerMaxHelpers = {helper}}},\n"
            f"  Unprotect[$ScriptCommandLine]; {assignment}{duplicate_text}\n"
            f"  SetDirectory[{wl(str(Path(argv[0]).parent))}];\n"
            f"  Import[{wl(target)}, \"Text\"]; Get[{wl(argv[0])}]]\n"
        )
        self.wrapper.write_text(text, encoding="utf-8")

    def repin_wrapper(self) -> None:
        self.wrapper_pin = digest(self.wrapper)

    def make_held_object(self) -> dict:
        records = {}
        for key, path in self.held_sources.items():
            records[key] = {
                "Status": "CF300ExactQepsHeldParseRecordV2XH", "Label": key,
                "File": str(path.resolve()), "SHA256": self.policy.held_source_hashes[key],
                "CharacterCount": 100, "SyntaxLength": 100,
                "TerminalLFPresent": True,
                "SourceReadMode": "PinnedASCIIBytesPreserveTerminalLF",
                "HoldCompleteExact": True, "SyntaxLengthExact": True,
                "ParserMessages": [], "SplitContextMarkerLines": [],
                "ParseNamespaceCleanupPassed": True, "Passed": True,
            }
        return {
            "Status": "CF300ExactQepsRuntimeAdmissionHeldParsePassedV2XH",
            "AllPassed": True, "ExpectedDispatchKernelID": 24,
            "DispatchKernelID": 24, "TaskBrokerMaxHelpers": 0,
            "OuterPoolKernelCount": 8, "NestedKernelCountAtEntry": 0,
            "NestedKernelsAtEntry": [],
            "MaximumOutputBytes": verifier.MAX_SMALL_OUTPUT_BYTES,
            "SourceReadMode": "PinnedASCIIBytesPreserveTerminalLF",
            "SourceHashesBefore": dict(self.policy.held_source_hashes),
            "SourceHashesAfter": dict(self.policy.held_source_hashes),
            "ParseRecords": records, "GateSHA256": digest(self.held_gate),
        }

    def modular_summary(self) -> dict:
        return {
            "Status": "ReconstructedCF300ExactQepsWitnessSupportV1",
            "Field": "Q(eps)", "SupportFunctionCount": 889,
            "DegreeProfileStableAcrossTrainingPrimes": True,
            "RationalReconstructionBoundSatisfied": True,
            "PrefixReconstructionStable": True, "HeldOutPrimeImagesExact": True,
            "Backend": "SourcePinnedCFFA4FLINTFixedSquare",
            "NativeBinarySHA256": self.policy.exact_source_hashes["NativeFixedSquareBinary"],
            "FiniteFieldStripSolveSHA256": self.policy.exact_source_hashes["FiniteFieldStripSolve"],
            "NativeThreads": 4, "TrainingPrimeCount": 4,
            "HeldOutPrimeCertificates": [{"Status": "passed"}, {"Status": "passed"}],
            "ActualNativeSolveAttempts": {"Training": 100, "HeldOut": 10, "Total": 110},
        }

    def make_certificate_object(self) -> dict:
        modular = self.modular_summary()
        nested_reconstruction = copy.deepcopy(modular)
        certificate = {
            "Status": "CertifiedCF300ExactQepsLeftObstructionV1",
            "Field": "Q(eps)", "MatrixDimensions": [960, 912],
            "CoefficientRankFromPinnedPlan": 888,
            "AugmentedRankFromPinnedPlan": 889,
            "WitnessSupportCount": 10, "LeftResidualCoordinateCount": 912,
            "LeftClearedNumeratorsAllZero": True,
            "RightClearedNumeratorZero": True, "RightPairing": 1,
            "ReconstructionCertificate": nested_reconstruction,
            "RightClearedIdentityCertificate": {
                "Status": "ExactClearedDenominatorIdentityV1",
                "NumeratorZero": True, "DenominatorNonzero": True,
            },
            "WitnessScoreIndexPolicy":
                "Pick[Range[Length[values]],mask]; no Position head traversal",
        }
        return {
            "Status": "CF300Sector12ExactQepsLeftObstructionCertifiedV1",
            "Field": "Q(eps)", "V6dArtifactFile": str(self.v6d.resolve()),
            "V6dArtifactSHA256": self.policy.v6d_sha,
            "OrbitCoreV6dSHA256": self.policy.orbit_core_sha,
            "PrerequisiteFile": str(self.prerequisite.resolve()),
            "PrerequisiteSHA256": "pending",
            "Requirements": {
                "Status": "CF300V6dExactLiftRequirementsV1",
                "MatrixDimensions": [960, 912], "CoefficientRank": 888,
                "AugmentedRank": 889, "PointCount": 30,
            },
            "ModularReconstructionSummary": modular,
            "ExactSampleSummary": {
                "Status": "AssembledCF300ExactQepsSampleV1",
                "MatrixDimensions": [960, 912], "PointCount": 30,
                "ExactRationalPointsNonsingularOverQeps": True,
            },
            "Certificate": certificate, "PlanDiscoveryPerformed": False,
            "DriverSHA256": self.policy.held_source_hashes["FrozenDriver"],
            "SourceHashes": dict(self.policy.exact_source_hashes),
        }

    def sync_source_pins(self) -> None:
        exact = {key: digest(path) for key, path in self.exact_sources.items()}
        held = {key: digest(path) for key, path in self.held_sources.items()}
        runtime = {key: digest(path) for key, path in self.runtime_sources.items()}
        self.policy = replace(self.policy, exact_source_hashes=exact,
                              held_source_hashes=held,
                              admission_runtime_hashes=runtime)
        self.held_object = self.make_held_object()
        self.certificate_object["DriverSHA256"] = held["FrozenDriver"]
        self.certificate_object["SourceHashes"] = dict(exact)
        for summary in (self.certificate_object["ModularReconstructionSummary"],
                        self.certificate_object["Certificate"]["ReconstructionCertificate"]):
            summary["NativeBinarySHA256"] = exact["NativeFixedSquareBinary"]
            summary["FiniteFieldStripSolveSHA256"] = exact["FiniteFieldStripSolve"]

    def persist(self) -> None:
        self.held.write_text(wl(self.held_object) + "\n", encoding="utf-8")
        self.prerequisite.write_text(wl(self.prerequisite_object) + "\n", encoding="utf-8")
        prerequisite_sha = digest(self.prerequisite)
        self.certificate_object["PrerequisiteSHA256"] = prerequisite_sha
        self.certificate.write_text(wl(self.certificate_object) + "\n", encoding="utf-8")
        certificate_sha = digest(self.certificate)
        certificate_size = self.certificate.stat().st_size
        if not self.receipt_object:
            self.receipt_object = {
                "Status": "CF300ExactQepsRuntimeAdmissionPassedV2XH",
                "AdmissionPassed": True, "FailureReason": None,
                "ExpectedDispatchKernelID": 24, "DispatchKernelID": 24,
                "TaskBrokerMaxHelpers": 0, "OuterPoolKernelCount": 8,
                "NestedKernelCountAtEntry": 0, "NestedKernelsAtEntry": [],
                "AdmissionStateStable": True,
                "FrozenDriverSHA256": self.policy.held_source_hashes["FrozenDriver"],
                "TransformedDriverSHA256": self.policy.transformed_driver_sha,
                "TypedDriverExitTag": "CF300ExactQepsFrozenDriverExitV2",
                "SourceReadMode": "PinnedASCIIBytesPreserveTerminalLF",
                "FrozenDriverTerminalLFPresent": True,
                "TransformedDriverHeldParse": {
                    "HoldCompleteExact": True, "SyntaxLengthExact": True,
                    "ParserMessages": [], "SplitContextMarkerLines": [],
                },
                "TransformedParseCleanupPassed": True,
                "ContextBacktickSplitGuardPassed": True,
                "HeldParseArtifactFile": str(self.held.resolve()),
                "HeldParseArtifactSHA256": digest(self.held),
                "HeldParseGateSHA256": digest(self.held_gate),
                "HeldParseEvidenceValid": True, "DriverCode": 0,
                "DriverOutputFile": str(self.certificate.resolve()),
                "DriverOutputStatus": "CF300Sector12ExactQepsLeftObstructionCertifiedV1",
                "DriverOutputSHA256": certificate_sha,
                "DriverOutputFileByteCount": certificate_size,
                "MaximumCertificateBytes": verifier.MAX_CERTIFICATE_BYTES,
                "MaximumReceiptBytes": verifier.MAX_SMALL_OUTPUT_BYTES,
                "OutputRollbackPerformed": False,
                "PrerequisiteFile": str(self.prerequisite.resolve()),
                "PrerequisiteSHA256": prerequisite_sha,
                "PrerequisiteStable": True,
                "SourceHashesBefore": dict(self.policy.admission_runtime_hashes),
                "SourceHashesAfter": dict(self.policy.admission_runtime_hashes),
                "ImmutableSourcePinsStable": True,
                "AdmissionWrapperSHA256": self.policy.held_source_hashes["AdmissionDriver"],
            }
        else:
            self.receipt_object["HeldParseArtifactSHA256"] = digest(self.held)
            self.receipt_object["DriverOutputSHA256"] = certificate_sha
            self.receipt_object["DriverOutputFileByteCount"] = certificate_size
            self.receipt_object["PrerequisiteSHA256"] = prerequisite_sha
            self.receipt_object["FrozenDriverSHA256"] = self.policy.held_source_hashes["FrozenDriver"]
            self.receipt_object["AdmissionWrapperSHA256"] = self.policy.held_source_hashes["AdmissionDriver"]
            self.receipt_object["SourceHashesBefore"] = dict(self.policy.admission_runtime_hashes)
            self.receipt_object["SourceHashesAfter"] = dict(self.policy.admission_runtime_hashes)
        self.receipt.write_text(wl(self.receipt_object) + "\n", encoding="utf-8")
        self.status.write_text(wl(self.status_object) + "\n", encoding="utf-8")
        self.log.write_text(
            f"MISSION {self.wrapper.name} kernel 24 start 2026-08-23T00:00:00\n"
            f"CF300_EXACT_QEPS_ADMISSION PASS output={self.certificate.resolve()} receipt={self.receipt.resolve()}\n"
            "MISSION end 2026-08-23T00:00:01 wall 1.0 s status OK\n",
            encoding="utf-8",
        )

    def args(self) -> argparse.Namespace:
        return argparse.Namespace(
            project_root=str(self.project_root),
            admission_driver=str(self.admission_driver), v6d=str(self.v6d),
            prerequisite=str(self.prerequisite), held_parse=str(self.held),
            certificate=str(self.certificate), receipt=str(self.receipt),
            mission_wrapper=str(self.wrapper), mission_status=str(self.status),
            mission_log=str(self.log), expected_wrapper_sha256=self.wrapper_pin,
        )


class VerifierTests(unittest.TestCase):
    def run_fixture(self, mutate=None, expected_error=None, post_mutate=None):
        with tempfile.TemporaryDirectory(prefix="cf300-exact-postrun-") as directory:
            fixture = Fixture(Path(directory))
            if mutate:
                mutate(fixture)
                fixture.persist()
            if post_mutate:
                post_mutate(fixture)
            if expected_error is None:
                report = verifier.verify(fixture.args(), fixture.policy, fixture.inventory)
                self.assertEqual(report["status"], "CF300ExactQepsAdmissionPostRunVerifiedV2XH")
                self.assertEqual(report["native_flint_threads"], 4)
            else:
                with self.assertRaisesRegex(verifier.VerificationError, expected_error):
                    verifier.verify(fixture.args(), fixture.policy, fixture.inventory)

    def test_valid_fixture(self):
        self.run_fixture()

    def test_wrapper_argument_order(self):
        def mutate(f):
            argv = list(f.wrapper_argv)
            argv[2], argv[3] = argv[3], argv[2]
            f.write_wrapper(argv)
            f.repin_wrapper()
        self.run_fixture(mutate, "ordered target/argument linkage")

    def test_wrapper_duplicate_assignment(self):
        def mutate(f):
            f.write_wrapper(duplicate=True)
            f.repin_wrapper()
        self.run_fixture(mutate, "literal \\$ScriptCommandLine assignments")

    def test_wrapper_helper_ceiling(self):
        def mutate(f):
            f.write_wrapper(helper=1)
            f.repin_wrapper()
        self.run_fixture(mutate, "helper ceiling")

    def test_wrapper_target_linkage(self):
        def mutate(f):
            f.write_wrapper(import_target=str(f.root / "wrong.wls"))
            f.repin_wrapper()
        self.run_fixture(mutate, "target linkage")

    def test_wrapper_hash_pin(self):
        self.run_fixture(expected_error="wrapper hash mismatch",
                         post_mutate=lambda f: f.wrapper.write_text(
                             f.wrapper.read_text(encoding="utf-8") + "(* mutation *)\n",
                             encoding="utf-8"))

    def test_pool_wrong_kernel(self):
        self.run_fixture(lambda f: f.status_object.update({"Kernel": 25}), "K24")

    def test_pool_nonzero_result(self):
        self.run_fixture(lambda f: f.status_object.update({"Result": 1}), "result is not zero")

    def test_receipt_nested_kernel(self):
        def mutate(f):
            f.receipt_object["NestedKernelCountAtEntry"] = 1
            f.receipt_object["NestedKernelsAtEntry"] = [99]
        self.run_fixture(mutate, "K24/helper/nested")

    def test_held_parse_failed_status(self):
        self.run_fixture(lambda f: f.held_object.update(
            {"Status": "CF300ExactQepsRuntimeAdmissionHeldParseFailedXH"}),
            "failed or typed diagnostic")

    def test_held_parse_record_context_split(self):
        def mutate(f):
            f.held_object["ParseRecords"]["AdmissionDriver"]["SplitContextMarkerLines"] = [17]
        self.run_fixture(mutate, "split context markers")

    def test_held_parse_source_read_mode(self):
        def mutate(f):
            f.held_object["SourceReadMode"] = "ImportTextCanonicalized"
        self.run_fixture(mutate, "held-parse source read mode mismatch")

    def test_held_parse_record_terminal_lf(self):
        def mutate(f):
            first = next(iter(f.held_object["ParseRecords"].values()))
            first["TerminalLFPresent"] = False
        self.run_fixture(mutate, "TerminalLFPresent")

    def test_held_parse_record_source_read_mode(self):
        def mutate(f):
            first = next(iter(f.held_object["ParseRecords"].values()))
            first["SourceReadMode"] = "ImportTextCanonicalized"
        self.run_fixture(mutate, "record read mode mismatch")

    def test_held_parse_receipt_hash_linkage(self):
        def post(f):
            f.receipt_object["HeldParseArtifactSHA256"] = "0" * 64
            f.receipt.write_text(wl(f.receipt_object) + "\n", encoding="utf-8")
        self.run_fixture(expected_error="held-parse path/SHA/gate linkage", post_mutate=post)

    def test_prerequisite_hash_linkage(self):
        self.run_fixture(expected_error="prerequisite path/SHA linkage|prerequisite path/SHA",
                         post_mutate=lambda f: f.prerequisite.write_bytes(
                             f.prerequisite.read_bytes() + b" "))

    def test_certificate_typed_diagnostic_status(self):
        self.run_fixture(lambda f: f.certificate_object.update(
            {"Status": "CF300ExactQepsWitnessConstructionFailedV1"}),
            "failed or typed diagnostic")

    def test_nested_certificate_failed_status(self):
        def mutate(f):
            f.certificate_object["Certificate"]["Status"] = \
                "CF300ExactQepsLeftObstructionFailure"
        self.run_fixture(mutate, "nested obstruction certificate")

    def test_modular_typed_diagnostic_status(self):
        def mutate(f):
            f.certificate_object["ModularReconstructionSummary"]["Status"] = \
                "CF300ModularQepsReconstructionFailure"
        self.run_fixture(mutate, "failed/diagnostic status")

    def test_receipt_failed_status(self):
        self.run_fixture(lambda f: f.receipt_object.update(
            {"Status": "CF300ExactQepsRuntimeAdmissionFailedV2XH",
             "AdmissionPassed": False}), "failed or typed diagnostic")

    def test_receipt_typed_exit_tag(self):
        self.run_fixture(lambda f: f.receipt_object.update(
            {"TypedDriverExitTag": "UnrelatedTag"}),
            "byte-exact read/typed-exit contract")

    def test_receipt_terminal_lf(self):
        self.run_fixture(lambda f: f.receipt_object.update(
            {"FrozenDriverTerminalLFPresent": False}),
            "byte-exact read/typed-exit contract")

    def test_receipt_source_read_mode(self):
        self.run_fixture(lambda f: f.receipt_object.update(
            {"SourceReadMode": "ImportTextCanonicalized"}),
            "byte-exact read/typed-exit contract")

    def test_receipt_transformed_driver_pin(self):
        self.run_fixture(lambda f: f.receipt_object.update(
            {"TransformedDriverSHA256": "0" * 64}),
            "driver/wrapper SHA linkage")

    def test_receipt_output_hash_linkage(self):
        def post(f):
            f.receipt_object["DriverOutputSHA256"] = "0" * 64
            f.receipt.write_text(wl(f.receipt_object) + "\n", encoding="utf-8")
        self.run_fixture(expected_error="driver-output status/path/SHA/size", post_mutate=post)

    def test_native_thread_artifact_mutation(self):
        def mutate(f):
            f.certificate_object["ModularReconstructionSummary"]["NativeThreads"] = 3
        self.run_fixture(mutate, "native thread count")

    def test_native_thread_source_literal_mutation(self):
        def mutate(f):
            f.frozen_driver.write_text('synthetic exact driver; "NativeThreads" -> 3\n',
                                       encoding="utf-8")
            f.sync_source_pins()
        self.run_fixture(mutate, "native-thread literal four")

    def test_modular_source_thread_literal_mutation(self):
        def mutate(f):
            f.modular.write_text('synthetic modular source; "NativeThreads" -> 3\n',
                                 encoding="utf-8")
            f.sync_source_pins()
        self.run_fixture(mutate, "native-thread literal four")

    def test_source_hash_mutation(self):
        self.run_fixture(expected_error="exact source hash mismatch",
                         post_mutate=lambda f: next(iter(f.exact_sources.values())).write_text(
                             "changed\n", encoding="utf-8"))

    def test_admission_manifest_source_pin_mutation(self):
        self.run_fixture(expected_error="source manifest hash mismatch",
                         post_mutate=lambda f: f.admission_manifest.write_text(
                             f.admission_manifest.read_text(encoding="utf-8") +
                             "# mutation\n", encoding="utf-8"))

    def test_certificate_size_ceiling(self):
        def post(f):
            with f.certificate.open("r+b") as stream:
                stream.truncate(verifier.MAX_CERTIFICATE_BYTES + 1)
        self.run_fixture(expected_error="1 GiB ceiling", post_mutate=post)

    def test_receipt_size_ceiling(self):
        def post(f):
            with f.receipt.open("r+b") as stream:
                stream.truncate(verifier.MAX_SMALL_OUTPUT_BYTES + 1)
        self.run_fixture(expected_error="16 MiB ceiling", post_mutate=post)

    def test_stale_atomic_temporary(self):
        def post(f):
            (f.receipt.parent / (f.receipt.name + ".tmp-adversary")).write_text(
                "stale", encoding="utf-8")
        self.run_fixture(expected_error="stale atomic temporary", post_mutate=post)

    def test_log_failure_marker(self):
        self.run_fixture(expected_error="forbidden marker",
                         post_mutate=lambda f: f.log.write_text(
                             f.log.read_text(encoding="utf-8") + "During evaluation of In[1]:= bad\n",
                             encoding="utf-8"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
