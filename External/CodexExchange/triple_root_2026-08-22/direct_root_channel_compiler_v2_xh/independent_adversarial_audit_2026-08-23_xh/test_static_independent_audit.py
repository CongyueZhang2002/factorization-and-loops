#!/usr/bin/env python3
"""Static, non-Wolfram audit probes for the External-only V2 prototype."""

from pathlib import Path


HERE = Path(__file__).resolve().parent
PROTOTYPE = HERE.parent
EXCHANGE = PROTOTYPE.parent
V2 = (PROTOTYPE / "DirectRootChannelCompilerV2.wl").read_text(encoding="utf-8")
V1 = (
    EXCHANGE / "direct_root_channel_assembler_xh" / "DirectRootChannelAssembler.wl"
).read_text(encoding="utf-8")
ADVERSARIAL = (
    PROTOTYPE / "run_direct_root_channel_compiler_v2_adversarial.wls"
).read_text(encoding="utf-8")
PHYSICAL = (
    PROTOTYPE / "run_cf300_sector12_compiler_v2_benchmark.wls"
).read_text(encoding="utf-8")


def require(condition, message):
    if not condition:
        raise AssertionError(message)
    print(f"PASS {message}")


def main():
    require("LinearSolve[" not in V2, "recursive compiler has no dense fallback")
    require("TRFieldDecompose[" not in V2, "compiler owns its decomposition path")
    require(
        all(token not in V2 + ADVERSARIAL + PHYSICAL for token in (
            "LaunchKernels[", "CloseKernels[", "ParallelSubmit[", "ParallelMap[",
            "KillProcess[", "RunProcess[", "StartProcess[",
        )),
        "compiler and drivers do not acquire nested kernels or signal processes",
    )
    require(
        V2.count("SameQ[pool[\"Values\"][[#1]],") == 2,
        "both scalar and polynomial hash buckets require structural equality",
    )
    require(
        "half = Quotient[dimension, 2];" in V2
        and "delta = Last[deltas];" in V2
        and "lowerDeltas = Most[deltas];" in V2,
        "recursive split treats the last root as the high bit",
    )
    require(
        "check - UnitVector[dimension, 1]" in V2
        and "reconstructed - expression" in V2,
        "inverse and field round trips fail closed",
    )
    require(
        'drcaStableFingerprint[{record, roots, oneForms, gaugeDenominator,' in V1
        and 'drcav2StableFingerprint[{record, roots, gaugeCanonical}]' in V2,
        "observed: default V1 and V2 SourceABIFingerprint payloads differ",
    )
    for driver_name, driver in (("adversarial", ADVERSARIAL), ("physical", PHYSICAL)):
        comparison_start = driver.index('comparisonKeys = {')
        comparison_end = driver.index('};', comparison_start)
        comparison_block = driver[comparison_start:comparison_end]
        require(
            '"Record"' not in comparison_block
            and '"Roots"' not in comparison_block
            and '"PrototypeSourceFile"' not in comparison_block
            and '"PrototypeSourceSHA256"' not in comparison_block,
            f"observed: {driver_name} exact-equality gate omits four V1 fields",
        )
    require(
        "V2CompilerSourceSHA256" not in V2,
        "observed: detached V1 compatibility view has no explicit V2 provenance field",
    )


if __name__ == "__main__":
    main()
