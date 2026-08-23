#!/usr/bin/env python3
"""No-kernel positive and adversarial tests for the V6e post-run verifier."""

from __future__ import annotations

import argparse
import copy
import hashlib
import tempfile
import unittest
from dataclasses import replace
from fractions import Fraction
from pathlib import Path

import verify_cf300_v6e_full_mission_xh as verifier


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def digest_label(label: str) -> str:
    return digest_bytes(label.encode())


def wl(value) -> str:
    if isinstance(value, bool):
        return "True" if value else "False"
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(value, Fraction):
        return f"{value.numerator}/{value.denominator}"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, list) or isinstance(value, tuple):
        return "{" + ", ".join(wl(item) for item in value) + "}"
    if isinstance(value, dict):
        return "<|" + ", ".join(f"{wl(key)} -> {wl(item)}" for key, item in value.items()) + "|>"
    raise TypeError(type(value))


def rank_certificate(augmented: bool) -> dict:
    if augmented:
        columns, rank = 913, 889
        pivots = list(range(1, 889)) + [913]
        pivot_fp, row_fp = verifier.AUG_PIVOT_FP, verifier.AUG_ROWS_FP
    else:
        columns, rank = 912, 888
        pivots = list(range(1, 889))
        pivot_fp, row_fp = verifier.COEFF_PIVOT_FP, verifier.COEFF_ROWS_FP
    free = list(range(889, 913))
    rows = list(range(1, rank + 1))
    return {
        "Status": "VerifiedNativeRankWithStablePlanV1",
        "MatrixDimensions": [960, columns], "Rank": rank, "Nullity": 24,
        "Seconds": 0.1, "PivotColumns": pivots, "FreeColumns": free,
        "IndependentEquationRows": rows, "PivotFingerprint": pivot_fp,
        "FreeColumnFingerprint": verifier.FREE_FP,
        "RowWitnessFingerprint": row_fp,
    }


def image(image_id: str, prime: int, epsilon: Fraction, offset: int) -> dict:
    points = [[(offset + i) % prime, (offset + 37 * i + 1) % prime] for i in range(30)]
    coefficient = rank_certificate(False)
    augmented = rank_certificate(True)
    return {
        "ImageID": image_id, "Prime": prime, "EpsilonValue": epsilon,
        "PointCount": 30, "AttemptCount": 30, "AcceptedPoints": points,
        "AcceptedPointsFingerprint": verifier.POINTS_FP if image_id == "I00" else digest_label(image_id + "-points"),
        "SampleSeconds": 0.2, "MatrixFingerprint": digest_label(image_id + "-matrix"),
        "RightHandSideFingerprint": digest_label(image_id + "-rhs"),
        "BaseColumnPrefixContainedExactly": True,
        "FullRank": {
            "Status": "CertifiedAffineConsistencyByTwoStableRanksV1",
            "Consistent": False, "CoefficientRank": 888, "AugmentedRank": 889,
            "CoefficientNullity": 24, "CoefficientCertificate": coefficient,
            "AugmentedCertificate": augmented,
        },
        "FrozenRankCertificateExact": True,
    }


def trial(label: str, seconds: float, nonce: str) -> dict:
    gates = {key: True for key in {
        "StatusExact", "InputIdentityStable", "ExactOracleIdentity",
        "MaximalAssemblyFingerprintExact", "RawLeafCountExact",
        "RawUniqueReuseConservationExact", "CompileCountExact", "CollisionFree",
        "LegacyOracleCountExact", "LegacyOraclePassed", "SpecializedSealPassed",
        "SpecializedSealValidBeforeConsume", "SealStatusExact",
        "SealNonceUUIDShaped", "SealFingerprintSHA256Shaped",
        "FreshThenReplayConsumeExact", "NoAlgebraicFallback",
        "NoFailureOrMissing", "SourcesStable",
    }}
    return {
        "Status": "CF300V6eSameInputTrialPassed", "Label": label, "Seconds": seconds,
        "Gates": gates, "AssemblyFingerprint": verifier.ASSEMBLY_FP,
        "ExactFormsFingerprint": verifier.EXACT_FORMS_FP,
        "CompiledFormsFingerprint": verifier.COMPILED_FORMS_FP,
        "CompiledShapeFingerprint": digest_label("shape"),
        "RawLeafCount": 576, "UniqueCompiledLeafCount": 500,
        "CompileCacheReuseCount": 76, "PhaseSeconds": {"compile": seconds / 2},
        "SealStatus": "ExactOneFormRebindSpecializedSealV6e",
        "SealNonce": nonce, "SealFingerprint": digest_label(nonce),
        "SealValidBeforeConsume": True, "FreshConsumePassed": True,
        "ReplayConsumeRejected": True,
    }


class Fixture:
    def __init__(self, root: Path):
        self.root = root
        self.driver = root / "run_cf300_sector12_v6e_correctness_same_input_benchmark_xh.wls"
        self.driver.write_text("frozen synthetic driver\n", encoding="utf-8")
        self.preparation = root / "preparation.wl"
        self.cache = root / "cache.wl"
        self.v6d = root / "v6d.wl"
        for path, data in ((self.preparation, b"prep"), (self.cache, b"cache"), (self.v6d, b"v6d")):
            path.write_bytes(data)
        self.source_paths = {}
        source_hashes = {}
        source_dir = root / "sources"
        source_dir.mkdir()
        for name in verifier.EXPECTED_SOURCE_HASHES:
            path = source_dir / (name + ".source")
            path.write_bytes((name + "\n").encode())
            self.source_paths[name] = path
            source_hashes[name] = verifier.sha256_file(path)
        self.project_root = root
        self.prerequisite = root / "prerequisite.wl"
        self.output = root / "output.wl"
        done = root / "done"
        done.mkdir()
        self.mission_wrapper = done / "synthetic.wl"
        self.status = done / "synthetic.status"
        self.log = root / "mission.log"
        self.manifest = root / "SHA256SUMS"
        self.wrapper_argv = [
            str(self.driver.resolve()), str(self.project_root.resolve()),
            str(self.preparation.resolve()), str(self.cache.resolve()),
            str(self.v6d.resolve()), str(self.output.resolve()),
            str(self.prerequisite.resolve()), "4",
        ]
        self.write_mission_wrapper()
        self.policy = verifier.Policy(
            source_hashes=source_hashes,
            preparation_sha=verifier.sha256_file(self.preparation),
            cache_sha=verifier.sha256_file(self.cache),
            v6d_sha=verifier.sha256_file(self.v6d),
            mission_wrapper_sha=verifier.sha256_file(self.mission_wrapper),
            project_root=str(self.project_root),
        )
        self.images = [
            image("I00", 10007, Fraction(1, 21), 1),
            image("I01", 10007, Fraction(1, 11), 101),
            image("I10", 10039, Fraction(1, 21), 201),
            image("I11", 10039, Fraction(1, 11), 301),
        ]
        self.trials = [
            trial("same-input-1", 10.0, "11111111-1111-4111-8111-111111111111"),
            trial("same-input-2", 12.0, "22222222-2222-4222-8222-222222222222"),
        ]
        coeff = self.images[0]["FullRank"]["CoefficientCertificate"]
        aug = self.images[0]["FullRank"]["AugmentedCertificate"]
        stable = {
            "MatrixDimensions": [960, 912], "CoefficientRank": 888, "AugmentedRank": 889,
            "CoefficientPivotColumns": coeff["PivotColumns"],
            "CoefficientFreeColumns": coeff["FreeColumns"],
            "CoefficientIndependentEquationRows": coeff["IndependentEquationRows"],
            "AugmentedPivotColumns": aug["PivotColumns"],
            "AugmentedFreeColumns": aug["FreeColumns"],
            "AugmentedIndependentEquationRows": aug["IndependentEquationRows"],
            "CoefficientPivotFingerprint": verifier.COEFF_PIVOT_FP,
            "CoefficientFreeFingerprint": verifier.FREE_FP,
            "CoefficientIndependentRowFingerprint": verifier.COEFF_ROWS_FP,
            "AugmentedPivotFingerprint": verifier.AUG_PIVOT_FP,
            "AugmentedFreeFingerprint": verifier.FREE_FP,
            "AugmentedIndependentRowFingerprint": verifier.AUG_ROWS_FP,
        }
        residues = copy.deepcopy(self.images[0]["AcceptedPoints"])
        lifts = [[Fraction(x, 1), Fraction(y, 1)] for x, y in residues]
        self.prerequisite_object = {
            "Status": "CF300V6dExactLiftPrerequisiteV1",
            "SourceV6dArtifactFile": str(self.v6d),
            "SourceV6dArtifactSHA256": self.policy.v6d_sha,
            "OrbitCoreV6dSHA256": source_hashes["OrbitCoreV6d"],
            "MaximalAssemblyFingerprint": verifier.ASSEMBLY_FP,
            "MaximalAssembly": {"AssemblyFingerprint": verifier.ASSEMBLY_FP},
            "AnchorImageID": "I00", "AnchorPrime": 10007,
            "AnchorEpsilonValue": Fraction(1, 21),
            "AnchorAcceptedPointResidues": residues, "AnchorAcceptedPoints": residues,
            "AnchorAcceptedPointsFingerprint": verifier.POINTS_FP,
            "ExactRationalPointLifts": lifts,
            "PointLiftCertificate": {
                "Status": "CertifiedBalancedRationalPointLiftV1", "Prime": 10007,
                "SearchDenominatorBound": 100, "ResidueFingerprint": verifier.POINTS_FP,
                "LiftFingerprint": digest_label("lifts"),
                "AllDenominatorsInvertible": True, "AllReductionsExact": True,
                "ExactPointsDistinctOverQ": True,
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
        self.status_object = {"Mission": self.mission_wrapper.name, "Status": "OK", "HadMessages": False,
                              "Wall": 1.0, "Kernel": 24, "Result": 0}
        self.log_text = "MISSION synthetic.wl kernel 24 start 2026-08-23T00:00:00\nMISSION end 2026-08-23T00:00:01 wall 1.0 s status OK\n"
        self.output_object = {}
        self.rebuild()

    def write_mission_wrapper(self, argv=None, helper_ceiling: int = 0,
                              duplicate_assignment: bool = False,
                              import_target: str | None = None,
                              get_target: str | None = None) -> None:
        argv = list(self.wrapper_argv if argv is None else argv)
        assignment = "$ScriptCommandLine = {" + ", ".join(wl(item) for item in argv) + "};"
        duplicate = "\n    " + assignment if duplicate_assignment else ""
        import_target = argv[0] if import_target is None else import_target
        get_target = argv[0] if get_target is None else get_target
        text = (
            "(* synthetic KernelPool mission wrapper *)\n"
            f"Block[{{KernelPoolMission`$TaskBrokerMaxHelpers = {helper_ceiling}}},\n"
            "  Module[{},\n"
            f"    Unprotect[$ScriptCommandLine]; {assignment}{duplicate}\n"
            f"    SetDirectory[{wl(argv[1])}];\n"
            f"    Import[{wl(import_target)}, \"Text\"];\n"
            f"    Get[{wl(get_target)}]]]\n"
        )
        self.mission_wrapper.write_text(text, encoding="utf-8")

    def repin_mission_wrapper(self) -> None:
        self.policy = replace(
            self.policy, mission_wrapper_sha=verifier.sha256_file(self.mission_wrapper)
        )

    def rebuild(self) -> None:
        self.prerequisite.write_text(wl(self.prerequisite_object) + "\n", encoding="utf-8")
        prerequisite_sha = verifier.sha256_file(self.prerequisite)
        prerequisite_size = self.prerequisite.stat().st_size
        times = [entry["Seconds"] for entry in self.trials]
        median = sum(times) / 2
        self.output_object = {
            "Status": "CF300Sector12V6eCorrectnessSameInputBenchmarkPassedXH",
            "PreparationSHA256": self.policy.preparation_sha,
            "CacheSHA256": self.policy.cache_sha,
            "FrozenV6dArtifactSHA256": self.policy.v6d_sha,
            "SourceHashes": dict(self.policy.source_hashes),
            "DriverSHA256": verifier.sha256_file(self.driver),
            "ExpectedDispatchKernelID": 24, "DispatchKernelID": 24,
            "TaskBrokerMaxHelpers": 0, "OuterPoolKernelCount": 8,
            "NestedKernelCount": 0, "NestedKernelsAtEntry": [],
            "FrozenV6CorrectnessOracle": {"Seconds": 20.0, "AssemblyFingerprint": verifier.ASSEMBLY_FP},
            "Trial1": self.trials[0], "Trial2": self.trials[1],
            "RepeatFingerprintsExact": True, "TrialSealEvidenceValid": True,
            "TrialSealNoncesDistinct": True, "TrialSealFingerprintsDistinct": True,
            "V6eTrialSeconds": times, "V6eMedianSeconds": median,
            "FrozenV6dRebindSeconds": verifier.V6D_SECONDS,
            "ObservedSpeedupFactor": verifier.V6D_SECONDS / median,
            "PerformanceAcceptancePassed": True,
            "FiniteFieldImages": [{key: entry[key] for key in ("ImageID", "Prime", "EpsilonValue")} for entry in self.images],
            "FiniteFieldImageResults": self.images,
            "AllFourFrozenImageCertificatesExact": True,
            "CrossImageStablePlanExact": True,
            "PrerequisiteCaptureRequested": True,
            "LiftPrerequisiteOutputFile": str(self.prerequisite.resolve()),
            "LiftPrerequisiteOutputSHA256": prerequisite_sha,
            "LiftPrerequisiteStatus": "CF300V6dExactLiftPrerequisiteV1",
            "LiftPrerequisiteByteCount": prerequisite_size + 512,
            "LiftPrerequisiteFileByteCount": prerequisite_size,
            "MaximumAtomicOutputBytes": verifier.MAX_BYTES,
            "LiftPrerequisiteConsumerValidation": {"Passed": True, "Seconds": 0.01},
            "AtomicOutputSizePolicy": {"MaximumBytes": verifier.MAX_BYTES,
                                       "PreTelemetryByteCount": 1,
                                       "TemporaryCleanupRequired": True,
                                       "OverwriteTarget": False},
        }
        self.persist()

    def persist(self) -> None:
        self.prerequisite.write_text(wl(self.prerequisite_object) + "\n", encoding="utf-8")
        prerequisite_sha = verifier.sha256_file(self.prerequisite)
        prerequisite_size = self.prerequisite.stat().st_size
        self.output_object["LiftPrerequisiteOutputSHA256"] = prerequisite_sha
        self.output_object["LiftPrerequisiteFileByteCount"] = prerequisite_size
        self.output_object["LiftPrerequisiteByteCount"] = prerequisite_size + 512
        self.output.write_text(wl(self.output_object) + "\n", encoding="utf-8")
        self.status.write_text(wl(self.status_object) + "\n", encoding="utf-8")
        self.log.write_text(self.log_text, encoding="utf-8")
        self.manifest.write_text(f"{verifier.sha256_file(self.driver)}  {self.driver.name}\n", encoding="utf-8")

    def args(self) -> argparse.Namespace:
        return argparse.Namespace(driver=str(self.driver), output=str(self.output),
                                  prerequisite=str(self.prerequisite), preparation=str(self.preparation),
                                  cache=str(self.cache), v6d=str(self.v6d),
                                  mission_wrapper=str(self.mission_wrapper),
                                  mission_status=str(self.status), mission_log=str(self.log),
                                  manifest=str(self.manifest))


class VerifierTests(unittest.TestCase):
    def run_fixture(self, mutate=None, expected_error=None, post_mutate=None):
        with tempfile.TemporaryDirectory(prefix="cf300-v6e-verifier-test-") as directory:
            fixture = Fixture(Path(directory))
            if mutate:
                mutate(fixture)
                fixture.persist()
            if post_mutate:
                post_mutate(fixture)
            old_driver_sha = verifier.DRIVER_SHA
            verifier.DRIVER_SHA = verifier.sha256_file(fixture.driver)
            try:
                if expected_error is None:
                    report = verifier.verify(fixture.args(), fixture.policy, fixture.source_paths)
                    self.assertEqual(report["status"], "CF300V6eFullMissionPostRunVerifiedXH")
                else:
                    with self.assertRaisesRegex(verifier.VerificationError, expected_error):
                        verifier.verify(fixture.args(), fixture.policy, fixture.source_paths)
            finally:
                verifier.DRIVER_SHA = old_driver_sha

    def test_valid_full_fixture(self):
        self.run_fixture()

    def test_mission_wrapper_native_threads_mutation(self):
        def mutate(f):
            argv = list(f.wrapper_argv)
            argv[-1] = "3"
            f.write_mission_wrapper(argv)
            f.repin_mission_wrapper()
        self.run_fixture(mutate, "native thread count")

    def test_mission_wrapper_argument_order_mutation(self):
        def mutate(f):
            argv = list(f.wrapper_argv)
            argv[2], argv[3] = argv[3], argv[2]
            f.write_mission_wrapper(argv)
            f.repin_mission_wrapper()
        self.run_fixture(mutate, "ordered argument/path linkage")

    def test_mission_wrapper_argument_path_mutation(self):
        def mutate(f):
            argv = list(f.wrapper_argv)
            argv[4] = str((f.root / "wrong-v6d.wl").resolve())
            f.write_mission_wrapper(argv)
            f.repin_mission_wrapper()
        self.run_fixture(mutate, "ordered argument/path linkage")

    def test_mission_wrapper_duplicate_assignment_mutation(self):
        def mutate(f):
            f.write_mission_wrapper(duplicate_assignment=True)
            f.repin_mission_wrapper()
        self.run_fixture(mutate, "literal \\$ScriptCommandLine assignments")

    def test_mission_wrapper_helper_ceiling_mutation(self):
        def mutate(f):
            f.write_mission_wrapper(helper_ceiling=1)
            f.repin_mission_wrapper()
        self.run_fixture(mutate, "helper ceiling")

    def test_mission_wrapper_target_mismatch_mutation(self):
        def mutate(f):
            argv = list(f.wrapper_argv)
            argv[0] = str((f.root / "wrong-target.wls").resolve())
            f.write_mission_wrapper(argv)
            f.repin_mission_wrapper()
        self.run_fixture(mutate, "target mismatch")

    def test_mission_wrapper_target_import_linkage_mutation(self):
        def mutate(f):
            f.write_mission_wrapper(import_target=str((f.root / "wrong-target.wls").resolve()))
            f.repin_mission_wrapper()
        self.run_fixture(mutate, "exact target/path linkage")

    def test_mission_wrapper_hash_mutation(self):
        self.run_fixture(expected_error="mission wrapper hash mismatch",
                         post_mutate=lambda f: f.mission_wrapper.write_text(
                             f.mission_wrapper.read_text(encoding="utf-8") + "(* changed *)\n",
                             encoding="utf-8"))

    def test_parser_line_continuation_comments_and_duplicate_rejection(self):
        with tempfile.TemporaryDirectory() as directory:
            valid = Path(directory) / "valid.wl"
            valid.write_bytes(b'<|(* nested (* comment *) *) "Path" -> "abc\\\ndef", "A" -> <|"B" -> {1, 2}|>|>')
            with verifier.WLDocument(valid) as document:
                self.assertEqual(document.as_string(document.path("Path")), "abcdef")
                self.assertEqual(document.as_int_list(document.path("A", "B")), [1, 2])
            duplicate = Path(directory) / "duplicate.wl"
            duplicate.write_text('<|"A" -> 1, "A" -> 2|>', encoding="utf-8")
            with verifier.WLDocument(duplicate) as document:
                with self.assertRaisesRegex(verifier.VerificationError, "duplicate"):
                    document.assoc()

    def test_wrong_kernel(self):
        self.run_fixture(lambda f: f.output_object.update({"DispatchKernelID": 25}), "K24 identity")

    def test_helper_ceiling(self):
        self.run_fixture(lambda f: f.output_object.update({"TaskBrokerMaxHelpers": 1}), "helper ceiling")

    def test_nested_kernel_inventory(self):
        def mutate(f):
            f.output_object["NestedKernelCount"] = 1
            f.output_object["NestedKernelsAtEntry"] = [99]
        self.run_fixture(mutate, "nested kernels")

    def test_semantic_oracle_gate(self):
        self.run_fixture(lambda f: f.trials[0]["Gates"].update({"ExactOracleIdentity": False}), "gates invalid")

    def test_duplicate_seal_nonce(self):
        def mutate(f):
            f.trials[1]["SealNonce"] = f.trials[0]["SealNonce"]
            f.trials[1]["SealFingerprint"] = f.trials[0]["SealFingerprint"]
        self.run_fixture(mutate, "reused a seal")

    def test_rank_mutation(self):
        self.run_fixture(lambda f: f.images[2]["FullRank"].update({"AugmentedRank": 888}), "rank tuple")

    def test_cross_image_plan_mutation(self):
        def mutate(f):
            cert = f.images[3]["FullRank"]["CoefficientCertificate"]
            cert["IndependentEquationRows"] = list(range(2, 890))
        self.run_fixture(mutate, "cross-image plan")

    def test_performance_regression(self):
        def mutate(f):
            f.trials[0]["Seconds"] = 600.0
            f.trials[1]["Seconds"] = 700.0
            f.output_object["V6eTrialSeconds"] = [600.0, 700.0]
            f.output_object["V6eMedianSeconds"] = 650.0
            f.output_object["ObservedSpeedupFactor"] = verifier.V6D_SECONDS / 650.0
        self.run_fixture(mutate, "performance acceptance")

    def test_consumer_metadata_mutation(self):
        def mutate(f):
            f.output_object["LiftPrerequisiteConsumerValidation"]["Passed"] = False
        self.run_fixture(mutate, "consumer validation")

    def test_prerequisite_policy_mutation(self):
        def mutate(f):
            f.prerequisite_object["CapturePolicy"]["AllowPlanRediscoveryInExactDriver"] = True
        self.run_fixture(mutate, "capture policy mismatch")

    def test_pool_messages(self):
        def mutate(f):
            f.status_object["HadMessages"] = True
        self.run_fixture(mutate, "recorded messages")

    def test_log_message_marker(self):
        self.run_fixture(expected_error="forbidden marker",
                         post_mutate=lambda f: f.log.write_text(f.log_text + "During evaluation of In[1]:= bad\n", encoding="utf-8"))

    def test_live_source_hash_mutation(self):
        def mutate(f):
            next(iter(f.source_paths.values())).write_bytes(b"mutated")
        self.run_fixture(mutate, "live source hash mismatch")

    def test_live_input_hash_mutation(self):
        self.run_fixture(expected_error="live input hash mismatch",
                         post_mutate=lambda f: f.cache.write_bytes(b"changed cache"))

    def test_prerequisite_hash_linkage_mutation(self):
        self.run_fixture(expected_error="prerequisite output SHA linkage",
                         post_mutate=lambda f: f.prerequisite.write_bytes(f.prerequisite.read_bytes() + b" "))

    def test_stale_atomic_temporary_inventory(self):
        def post(f):
            (f.output.parent / (f.output.name + ".tmp-adversary")).write_text("stale", encoding="utf-8")
        self.run_fixture(expected_error="stale atomic temporary", post_mutate=post)

    def test_malformed_manifest(self):
        self.run_fixture(expected_error="malformed manifest",
                         post_mutate=lambda f: f.manifest.write_text("not-a-hash driver\n", encoding="utf-8"))

    def test_prerequisite_residue_link_mutation(self):
        def mutate(f):
            f.prerequisite_object["AnchorAcceptedPointResidues"][0][0] += 1
        self.run_fixture(mutate, "anchor residue linkage")

    def test_correct_but_performance_not_accepted_status(self):
        def mutate(f):
            f.output_object["Status"] = "CF300Sector12V6eCorrectButPerformanceAcceptanceNotMetXH"
        self.run_fixture(mutate, "did not meet correctness and performance")


if __name__ == "__main__":
    unittest.main(verbosity=2)
