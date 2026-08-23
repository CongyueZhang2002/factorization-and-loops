#!/usr/bin/env python3
"""Static-only V6f gate.  It never launches Wolfram or the FLINT binary."""

from pathlib import Path

HERE = Path(__file__).resolve().parent
HELPER = (HERE / "DirectRootChannelExactOneFormBridgeV6f.staged.wl").read_text()
DRIVER = (HERE / "V6F_DRIVER_INTEGRATION_STAGED.wl").read_text()

required_helper = [
    '"ExactLegacyOracleBridgePassed" -> True',
    'appendedChannels =!= oracleExactSuffix',
    'compiledSuffix =!= oracleCompiledSuffix',
    'SameQ[legacyAuditCompiled, memoAuditCompiled]',
    'drbfSourceHashes[entry["SourceFiles"]] =!= handle["SourceHashes"]',
    '"RecordMerkleRoot" -> recordMerkleRoot',
    '"Assembly" -> semanticAssembly',
]
for needle in required_helper:
    assert needle in HELPER, needle

for forbidden in ["TimeConstrained", "TimeOut", "Timeout", "Parallel", "LaunchKernels"]:
    assert forbidden not in HELPER

# Warm resolution must not invoke full validators or serialize the assembly.
resolve = HELPER.split("DRCAResolveExactOneFormBridgeV6f[handle_Association]", 1)[1]
resolve = resolve.split("DRCAResolveExactOneFormBridgeV6f[___]", 1)[0]
for forbidden in [
    "DRCAAssemblyPreparationValidQ", "TRPreparationABIValidQ",
    "InputForm", "ExactChannelForms", "CompiledForms",
]:
    assert forbidden not in resolve, forbidden

# The integration must build from the immediate frozen-V6 call, clear the
# legacy variable, avoid V6e, and retain cold/warm timings separately.
assert "DRCARebindExactOneFormChannels" in DRIVER
assert "DRCARebindExactOneFormRecordsV6e" not in DRIVER
assert "Clear[v6fLegacyResult]" in DRIVER
assert '"OneTimeLegacyOracleSeconds"' in DRIVER
assert '"WarmResolveSeconds"' in DRIVER

print("V6F_STATIC_GATE_OK")
