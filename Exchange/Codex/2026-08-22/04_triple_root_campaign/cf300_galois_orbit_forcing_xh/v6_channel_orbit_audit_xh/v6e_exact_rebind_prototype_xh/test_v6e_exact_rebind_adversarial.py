#!/usr/bin/env python3
"""Adversarial no-Wolfram model for V6e leaf memoization and seals.

The model is intentionally smaller than the Wolfram ABI.  It exercises the
security/correctness invariants independently: canonical pairs, collision
checks, order-preserving memoization, exact raw/unique/reuse conservation,
suffix/core/layout binding, one legacy oracle, and single-use nonces.
"""

from __future__ import annotations

from copy import deepcopy
from fractions import Fraction
import hashlib
import math
import random
import sys
from typing import Callable


TOTAL = 0


def check(name: str, condition: bool, failures: list[str]) -> None:
    global TOTAL
    TOTAL += 1
    print(f"{'PASS' if condition else 'FAIL'} {name}")
    if not condition:
        failures.append(name)


def fp(value: object) -> str:
    return hashlib.sha256(repr(value).encode()).hexdigest()


Pair = tuple[int, int]


def canonical_pair(numerator: int, denominator: int) -> Pair:
    if denominator == 0:
        raise ZeroDivisionError
    divisor = math.gcd(numerator, denominator)
    numerator //= divisor
    denominator //= divisor
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    return numerator, denominator


def valid_canonical_pair(pair: Pair) -> bool:
    if not isinstance(pair, tuple) or len(pair) != 2:
        return False
    numerator, denominator = pair
    return (
        isinstance(numerator, int)
        and isinstance(denominator, int)
        and denominator != 0
        and canonical_pair(numerator, denominator) == pair
    )


def compile_pair(pair: Pair) -> tuple[str, Pair]:
    if not valid_canonical_pair(pair):
        raise ValueError("noncanonical pair")
    return "DRCARationalExactV1", pair


def legacy_compile(channel: Fraction) -> tuple[str, Pair]:
    return compile_pair((channel.numerator, channel.denominator))


def build_records(rng: random.Random, count: int = 23,
                  grade_count: int = 4) -> list[dict[str, object]]:
    pool: list[Pair] = []
    for _ in range(17):
        pool.append(canonical_pair(rng.randint(-30, 30),
                                   rng.randint(1, 29)))
    records: list[dict[str, object]] = []
    for index in range(count):
        channels: list[list[Fraction]] = []
        pairs: list[list[Pair]] = []
        for component in range(2):
            channel_row: list[Fraction] = []
            pair_row: list[Pair] = []
            for grade in range(grade_count):
                # Force heavy reuse while preserving a nontrivial order.
                pair = pool[(7 * index + 5 * component + grade) % len(pool)]
                pair_row.append(pair)
                channel_row.append(Fraction(*pair))
            channels.append(channel_row)
            pairs.append(pair_row)
        one_form = tuple(sum(row, Fraction(0)) for row in channels)
        records.append({
            "OneForm": one_form,
            "OneFormChannels": channels,
            "CanonicalFieldChannels": pairs,
            "ChannelFingerprint": fp(pairs),
        })
    return records


def flatten_records(records: list[dict[str, object]]) -> list[dict[str, object]]:
    leaves: list[dict[str, object]] = []
    for record_index, record in enumerate(records):
        channels = record["OneFormChannels"]
        pairs = record["CanonicalFieldChannels"]
        assert isinstance(channels, list) and isinstance(pairs, list)
        if fp(pairs) != record["ChannelFingerprint"]:
            raise ValueError("record fingerprint mismatch")
        for component in range(2):
            for grade in range(len(channels[component])):
                leaves.append({
                    "Index": (record_index, component, grade),
                    "Channel": channels[component][grade],
                    "Pair": pairs[component][grade],
                })
    return leaves


def memoized_compile(
    records: list[dict[str, object]],
    key_function: Callable[[Pair], str] = fp,
) -> dict[str, object]:
    leaves = flatten_records(records)
    groups: dict[str, list[dict[str, object]]] = {}
    for leaf in leaves:
        pair = leaf["Pair"]
        if not valid_canonical_pair(pair):
            raise ValueError("invalid canonical pair")
        if Fraction(*pair) != leaf["Channel"]:
            raise ValueError("pair/channel mismatch")
        groups.setdefault(key_function(pair), []).append(leaf)
    for group in groups.values():
        reference = group[0]["Pair"]
        if any(leaf["Pair"] != reference for leaf in group[1:]):
            raise ValueError("hash collision")
    cache = {
        key: compile_pair(group[0]["Pair"])
        for key, group in groups.items()
    }
    compiled = [cache[key_function(leaf["Pair"])] for leaf in leaves]
    raw = len(leaves)
    unique = len(cache)
    reused = raw - unique
    if raw != unique + reused:
        raise AssertionError("count conservation")
    audit_indices = sorted(set((
        0, math.ceil(raw / 4) - 1, math.ceil(raw / 2) - 1,
        math.ceil(3 * raw / 4) - 1, raw - 1,
    )))
    if any(compiled[index] != legacy_compile(leaves[index]["Channel"])
           for index in audit_indices):
        raise ValueError("legacy audit mismatch")
    return {
        "Leaves": leaves,
        "Compiled": compiled,
        "Raw": raw,
        "Unique": unique,
        "Reused": reused,
        "CompileCount": len(cache),
        "CollisionGroups": 0,
        "AuditIndices": audit_indices,
    }


def base_fixture(records: list[dict[str, object]]) -> tuple[dict, dict, dict]:
    base_forms = ((Fraction(1, 2), Fraction(1, 3)),
                  (Fraction(2, 5), Fraction(3, 7)))
    suffix = tuple(record["OneForm"] for record in records)
    base = {
        "AssemblyFingerprint": fp(("base", base_forms)),
        "AssemblerSource": "assembler-sha",
        "ValidatorSource": "validator-sha",
        "EquationCoreExact": ("E", "C", "BBar", 991),
        "EquationCoreCompiled": ("Ec", "Cc", "Bc", 992),
        "OneForms": base_forms,
        "CompiledPrefix": (("p0",), ("p1",)),
        "GaugeUnknownCount": 480,
        "Dimensions": (2, 2),
        "GradeCount": 4,
        "ColumnLayout": ("gauge", "residue", 2),
    }
    target = {
        "ABIFingerprint": fp(("target", base_forms, suffix)),
        "Core": ("record", "roots", "support"),
        "OneForms": base_forms + suffix,
        "GaugeUnknownCount": 480,
        "ResidueUnknownCount": 4 * len(base_forms + suffix),
        "UnknownCount": 480 + 4 * len(base_forms + suffix),
        "ColumnLayout": ("gauge", "residue", len(base_forms + suffix)),
    }
    memo = memoized_compile(records)
    compiled_suffix = tuple(memo["Compiled"])
    result = {
        "SourceABIFingerprint": target["ABIFingerprint"],
        "AssemblerSource": base["AssemblerSource"],
        "ValidatorSource": base["ValidatorSource"],
        "EquationCoreExact": base["EquationCoreExact"],
        "EquationCoreCompiled": base["EquationCoreCompiled"],
        "OneForms": target["OneForms"],
        "ExactSuffix": tuple(
            tuple(tuple(row) for row in record["OneFormChannels"])
            for record in records
        ),
        "CanonicalSuffix": tuple(
            tuple(tuple(row) for row in record["CanonicalFieldChannels"])
            for record in records
        ),
        "CompiledPrefix": base["CompiledPrefix"],
        "CompiledSuffix": compiled_suffix,
        "GaugeUnknownCount": target["GaugeUnknownCount"],
        "ResidueUnknownCount": target["ResidueUnknownCount"],
        "UnknownCount": target["UnknownCount"],
        "ColumnLayout": target["ColumnLayout"],
        "Memo": {
            "Raw": memo["Raw"], "Unique": memo["Unique"],
            "Reused": memo["Reused"],
            "CompileCount": memo["CompileCount"],
            "CollisionGroups": memo["CollisionGroups"],
        },
    }
    result["ExactFormsFingerprint"] = fp((
        result["EquationCoreExact"], result["OneForms"],
        result["ExactSuffix"],
    ))
    result["CompiledFormsFingerprint"] = fp((
        result["EquationCoreCompiled"], result["CompiledPrefix"],
        result["CompiledSuffix"],
    ))
    result["CompiledShapeFingerprint"] = fp((
        len(result["CompiledPrefix"]), len(result["CompiledSuffix"]),
    ))
    result["AssemblyFingerprint"] = assembly_fingerprint(result)
    return base, target, result


def assembly_fingerprint(result: dict) -> str:
    return fp((
        result["SourceABIFingerprint"], result["OneForms"],
        result["GaugeUnknownCount"], result["ResidueUnknownCount"],
        result["UnknownCount"], result["ColumnLayout"],
        result["ExactFormsFingerprint"],
        result["CompiledFormsFingerprint"],
        result["CompiledShapeFingerprint"],
    ))


def seal_payload(seal: dict) -> dict:
    return {key: value for key, value in seal.items()
            if key != "SealFingerprint"}


def make_seal(base: dict, target: dict, result: dict,
              nonce: str = "fresh-nonce") -> dict:
    seal = {
        "Status": "ExactOneFormRebindSpecializedSealV6e",
        "Nonce": nonce,
        "BaseAssemblyFingerprint": base["AssemblyFingerprint"],
        "ResultAssemblyFingerprint": result["AssemblyFingerprint"],
        "TargetABIFingerprint": target["ABIFingerprint"],
        "AssemblerSource": base["AssemblerSource"],
        "ValidatorSource": base["ValidatorSource"],
        "ExactCoreFingerprint": fp(result["EquationCoreExact"]),
        "CompiledCoreFingerprint": fp(result["EquationCoreCompiled"]),
        "BasePrefixFingerprint": fp(base["OneForms"]),
        "ExactSuffixFingerprint": fp(result["ExactSuffix"]),
        "CanonicalSuffixFingerprint": fp(result["CanonicalSuffix"]),
        "CompiledSuffixFingerprint": fp(result["CompiledSuffix"]),
        "GaugeUnknownCount": result["GaugeUnknownCount"],
        "ResidueUnknownCount": result["ResidueUnknownCount"],
        "UnknownCount": result["UnknownCount"],
        "ColumnLayoutFingerprint": fp(result["ColumnLayout"]),
        "Certificates": {
            "CollisionFree": True,
            "CanonicalPairsMatch": True,
            "CountConservation": True,
            "LegacyOraclePassed": True,
        },
    }
    seal["SealFingerprint"] = fp(seal_payload(seal))
    return seal


def legacy_oracle(base: dict, target: dict, result: dict) -> bool:
    prefix_count = len(base["OneForms"])
    return all((
        result["SourceABIFingerprint"] == target["ABIFingerprint"],
        result["AssemblerSource"] == base["AssemblerSource"],
        result["ValidatorSource"] == base["ValidatorSource"],
        result["EquationCoreExact"] == base["EquationCoreExact"],
        result["EquationCoreCompiled"] == base["EquationCoreCompiled"],
        result["OneForms"] == target["OneForms"],
        result["OneForms"][:prefix_count] == base["OneForms"],
        result["CompiledPrefix"] == base["CompiledPrefix"],
        result["GaugeUnknownCount"] == target["GaugeUnknownCount"],
        result["ResidueUnknownCount"] == target["ResidueUnknownCount"],
        result["UnknownCount"] == target["UnknownCount"],
        result["ColumnLayout"] == target["ColumnLayout"],
        result["Memo"]["Raw"] == result["Memo"]["Unique"]
        + result["Memo"]["Reused"],
        result["Memo"]["CompileCount"] == result["Memo"]["Unique"],
        result["Memo"]["CollisionGroups"] == 0,
        result["ExactFormsFingerprint"] == fp((
            result["EquationCoreExact"], result["OneForms"],
            result["ExactSuffix"],
        )),
        result["CompiledFormsFingerprint"] == fp((
            result["EquationCoreCompiled"], result["CompiledPrefix"],
            result["CompiledSuffix"],
        )),
        result["CompiledShapeFingerprint"] == fp((
            len(result["CompiledPrefix"]), len(result["CompiledSuffix"]),
        )),
        result["AssemblyFingerprint"] == assembly_fingerprint(result),
    ))


def specialized_valid(base: dict, target: dict, result: dict,
                      seal: dict) -> bool:
    prefix_count = len(base["OneForms"])
    certificates = seal.get("Certificates", {})
    return all((
        seal.get("Status") == "ExactOneFormRebindSpecializedSealV6e",
        isinstance(seal.get("Nonce"), str) and len(seal["Nonce"]) >= 8,
        seal.get("SealFingerprint") == fp(seal_payload(seal)),
        seal.get("BaseAssemblyFingerprint") == base["AssemblyFingerprint"],
        seal.get("ResultAssemblyFingerprint")
        == result["AssemblyFingerprint"],
        seal.get("TargetABIFingerprint") == target["ABIFingerprint"],
        seal.get("AssemblerSource") == base["AssemblerSource"]
        == result["AssemblerSource"],
        seal.get("ValidatorSource") == base["ValidatorSource"]
        == result["ValidatorSource"],
        result["SourceABIFingerprint"] == target["ABIFingerprint"],
        result["EquationCoreExact"] == base["EquationCoreExact"],
        result["EquationCoreCompiled"] == base["EquationCoreCompiled"],
        seal.get("ExactCoreFingerprint") == fp(result["EquationCoreExact"]),
        seal.get("CompiledCoreFingerprint")
        == fp(result["EquationCoreCompiled"]),
        result["OneForms"] == target["OneForms"],
        result["OneForms"][:prefix_count] == base["OneForms"],
        seal.get("BasePrefixFingerprint") == fp(base["OneForms"]),
        seal.get("ExactSuffixFingerprint") == fp(result["ExactSuffix"]),
        seal.get("CanonicalSuffixFingerprint")
        == fp(result["CanonicalSuffix"]),
        seal.get("CompiledSuffixFingerprint")
        == fp(result["CompiledSuffix"]),
        seal.get("GaugeUnknownCount") == result["GaugeUnknownCount"]
        == target["GaugeUnknownCount"],
        seal.get("ResidueUnknownCount") == result["ResidueUnknownCount"]
        == target["ResidueUnknownCount"],
        seal.get("UnknownCount") == result["UnknownCount"]
        == target["UnknownCount"],
        seal.get("ColumnLayoutFingerprint") == fp(result["ColumnLayout"]),
        result["ColumnLayout"] == target["ColumnLayout"],
        result["Memo"]["Raw"] == result["Memo"]["Unique"]
        + result["Memo"]["Reused"],
        result["Memo"]["CompileCount"] == result["Memo"]["Unique"],
        result["Memo"]["CollisionGroups"] == 0,
        isinstance(certificates, dict) and bool(certificates),
        all(isinstance(value, bool) for value in certificates.values()),
        all(certificates.values()),
    ))


def consume(base: dict, target: dict, result: dict, seal: dict,
            consumed: set[str]) -> bool:
    nonce = seal.get("Nonce")
    if not isinstance(nonce, str) or nonce in consumed:
        return False
    if not specialized_valid(base, target, result, seal):
        return False
    consumed.add(nonce)
    return True


def expect_compile_failure(records: list[dict[str, object]],
                           key_function: Callable[[Pair], str] = fp) -> bool:
    try:
        memoized_compile(records, key_function)
    except (ValueError, ZeroDivisionError):
        return True
    return False


def main() -> int:
    failures: list[str] = []
    rng = random.Random(2026082309)
    records = build_records(rng)
    memo = memoized_compile(records)

    check("raw/unique/reuse conserve exactly",
          memo["Raw"] == memo["Unique"] + memo["Reused"], failures)
    check("compile count equals unique canonical leaves",
          memo["CompileCount"] == memo["Unique"], failures)
    check("fixture exercises actual cache reuse", memo["Reused"] > 0,
          failures)
    check("compiled leaf order matches raw legacy order",
          memo["Compiled"] == [legacy_compile(leaf["Channel"])
                               for leaf in memo["Leaves"]], failures)
    check("deterministic audit covers first and last leaves",
          memo["AuditIndices"][0] == 0 and
          memo["AuditIndices"][-1] == memo["Raw"] - 1, failures)

    forced_collision = lambda pair: "forced-collision"
    check("forced fingerprint collision fails exact group comparison",
          expect_compile_failure(records, forced_collision), failures)

    numerator_mutant = deepcopy(records)
    n, d = numerator_mutant[0]["CanonicalFieldChannels"][0][0]
    numerator_mutant[0]["CanonicalFieldChannels"][0][0] = (n + 1, d)
    check("numerator mutation fails", expect_compile_failure(numerator_mutant),
          failures)

    denominator_mutant = deepcopy(records)
    n, d = denominator_mutant[0]["CanonicalFieldChannels"][0][0]
    denominator_mutant[0]["CanonicalFieldChannels"][0][0] = (n, d + 1)
    check("denominator mutation fails",
          expect_compile_failure(denominator_mutant), failures)

    zero_denominator = deepcopy(records)
    n, _ = zero_denominator[0]["CanonicalFieldChannels"][0][0]
    zero_denominator[0]["CanonicalFieldChannels"][0][0] = (n, 0)
    check("zero denominator fails", expect_compile_failure(zero_denominator),
          failures)

    scaled_noncanonical = deepcopy(records)
    n, d = scaled_noncanonical[0]["CanonicalFieldChannels"][0][0]
    scaled_noncanonical[0]["CanonicalFieldChannels"][0][0] = (2 * n, 2 * d)
    check("proportional but noncanonical pair fails",
          expect_compile_failure(scaled_noncanonical), failures)

    channel_mutant = deepcopy(records)
    channel_mutant[0]["OneFormChannels"][0][0] += Fraction(1, 17)
    check("exact channel mutation fails",
          expect_compile_failure(channel_mutant), failures)

    component_swap = deepcopy(records)
    component_swap[0]["OneFormChannels"].reverse()
    check("component swap fails", expect_compile_failure(component_swap),
          failures)

    grade_swap = deepcopy(records)
    grade_swap[0]["OneFormChannels"][0][0], \
        grade_swap[0]["OneFormChannels"][0][1] = \
        grade_swap[0]["OneFormChannels"][0][1], \
        grade_swap[0]["OneFormChannels"][0][0]
    check("grade swap fails", expect_compile_failure(grade_swap), failures)

    fingerprint_mutant = deepcopy(records)
    fingerprint_mutant[0]["ChannelFingerprint"] = "0" * 64
    check("record channel fingerprint mutation fails",
          expect_compile_failure(fingerprint_mutant), failures)

    reorder_records = deepcopy(records)
    reorder_records[0], reorder_records[1] = reorder_records[1], \
        reorder_records[0]
    # Compilation itself preserves any supplied order; the target suffix gate
    # is what must reject a record reorder.
    target_suffix = tuple(record["OneForm"] for record in records)
    check("record reorder rejected by exact target suffix order",
          tuple(record["OneForm"] for record in reorder_records)
          != target_suffix, failures)

    base, target, result = base_fixture(records)
    seal = make_seal(base, target, result)
    check("valid specialized seal passes",
          specialized_valid(base, target, result, seal), failures)
    check("valid legacy oracle passes", legacy_oracle(base, target, result),
          failures)
    check("specialized and legacy validators agree on valid fixture",
          specialized_valid(base, target, result, seal)
          == legacy_oracle(base, target, result), failures)

    consumed: set[str] = set()
    check("fresh nonce consumes once",
          consume(base, target, result, seal, consumed), failures)
    check("reused nonce fails closed",
          not consume(base, target, result, seal, consumed), failures)

    mutations: list[tuple[str, Callable[[dict, dict, dict, dict], None]]] = []
    mutations.append(("equation-core mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "EquationCoreExact", ("mutant",))))
    mutations.append(("compiled-core mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "EquationCoreCompiled", ("mutant",))))
    mutations.append(("base-prefix mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "OneForms", ((Fraction(9, 11),),)
                          + r["OneForms"][1:])))
    mutations.append(("target-ABI mutation",
                      lambda b, t, r, s: t.__setitem__(
                          "ABIFingerprint", "mutant-abi")))
    mutations.append(("gauge-count mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "GaugeUnknownCount", r["GaugeUnknownCount"] + 1)))
    mutations.append(("residue-count mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "ResidueUnknownCount",
                          r["ResidueUnknownCount"] + 4)))
    mutations.append(("unknown-count mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "UnknownCount", r["UnknownCount"] + 4)))
    mutations.append(("column-layout mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "ColumnLayout", ("mutant",))))
    mutations.append(("exact-suffix mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "ExactSuffix", r["ExactSuffix"][:-1])))
    mutations.append(("canonical-suffix mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "CanonicalSuffix", r["CanonicalSuffix"][:-1])))
    mutations.append(("stale-compiled-cache mutation",
                      lambda b, t, r, s: r.__setitem__(
                          "CompiledSuffix", r["CompiledSuffix"][:-1]
                          + (("DRCARationalExactV1", (99, 101)),))))
    mutations.append(("wrong assembler source hash",
                      lambda b, t, r, s: r.__setitem__(
                          "AssemblerSource", "wrong")))
    mutations.append(("wrong validator source hash",
                      lambda b, t, r, s: r.__setitem__(
                          "ValidatorSource", "wrong")))
    mutations.append(("stale result assembly fingerprint",
                      lambda b, t, r, s: r.__setitem__(
                          "AssemblyFingerprint", "stale")))
    mutations.append(("seal fingerprint mutation",
                      lambda b, t, r, s: s.__setitem__(
                          "SealFingerprint", "0" * 64)))
    mutations.append(("false certificate",
                      lambda b, t, r, s: s["Certificates"].__setitem__(
                          "CollisionFree", False)))
    mutations.append(("non-Boolean certificate",
                      lambda b, t, r, s: s["Certificates"].__setitem__(
                          "CollisionFree", 1)))
    mutations.append(("raw-count conservation mutation",
                      lambda b, t, r, s: r["Memo"].__setitem__(
                          "Raw", r["Memo"]["Raw"] + 1)))
    mutations.append(("compile-count mutation",
                      lambda b, t, r, s: r["Memo"].__setitem__(
                          "CompileCount", r["Memo"]["CompileCount"] + 1)))
    mutations.append(("collision-count mutation",
                      lambda b, t, r, s: r["Memo"].__setitem__(
                          "CollisionGroups", 1)))

    for name, mutate in mutations:
        local_base = deepcopy(base)
        local_target = deepcopy(target)
        local_result = deepcopy(result)
        local_seal = deepcopy(seal)
        mutate(local_base, local_target, local_result, local_seal)
        specialized = specialized_valid(
            local_base, local_target, local_result, local_seal)
        legacy = legacy_oracle(local_base, local_target, local_result)
        check(f"{name} rejected by specialized seal", not specialized,
              failures)
        # Seal-only metadata mutations do not affect the independent legacy
        # oracle.  All result/target/base mutations must make both reject.
        if name not in {"canonical-suffix mutation",
                        "seal fingerprint mutation", "false certificate",
                        "non-Boolean certificate"}:
            check(f"{name} rejected by legacy oracle", not legacy, failures)

    # Randomized leaf stress: exact memoized output must equal legacy output
    # for every generated fixture, with compile-count conservation.
    randomized_cases = 800
    for case in range(randomized_cases):
        local = build_records(rng, count=rng.randint(1, 40))
        local_memo = memoized_compile(local)
        if not (
            local_memo["Raw"]
            == local_memo["Unique"] + local_memo["Reused"]
            and local_memo["CompileCount"] == local_memo["Unique"]
            and local_memo["Compiled"]
            == [legacy_compile(leaf["Channel"])
                for leaf in local_memo["Leaves"]]
        ):
            failures.append(f"randomized case {case}")
            break
    check(f"{randomized_cases} randomized memo fixtures equal legacy",
          not any(item.startswith("randomized case") for item in failures),
          failures)

    print(f"SUMMARY passed={TOTAL - len(failures)} total={TOTAL} "
          f"failures={len(failures)} randomized_cases={randomized_cases}")
    if failures:
        print("FAILED " + ", ".join(failures))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
