#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
aggregate="$script_dir/run_cf300_sector12_rank2_extension_aggregate.wls"

passes=0
failures=0

pass() {
  passes=$((passes + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  failures=$((failures + 1))
  printf 'FAIL %s\n' "$1" >&2
}

contains() {
  local text=$1
  local literal=$2
  grep -Fq -- "$literal" <<<"$text"
}

source_has_complete_native_gate() {
  local source=$1
  local gate completion output
  gate=$(sed -n '/CFFR1_NATIVE_PROVENANCE_GATE_BEGIN/,/CFFR1_NATIVE_PROVENANCE_GATE_END/p' "$source")
  completion=$(sed -n '/CFFR1_NATIVE_PROVENANCE_COMPLETION_BEGIN/,/CFFR1_NATIVE_PROVENANCE_COMPLETION_END/p' "$source")
  output=$(sed -n '/CFFR1_NATIVE_PROVENANCE_OUTPUT_BEGIN/,/CFFR1_NATIVE_PROVENANCE_OUTPUT_END/p' "$source")

  contains "$gate" 'AllTrue[primeArtifacts,' &&
    contains "$gate" '"NativeDependencyHashes", None' &&
    contains "$gate" 'nativeDependencyHashesBefore &' &&
    contains "$gate" '"NativeBinaryFile", None' &&
    contains "$gate" 'nativeBinaryFile &&' &&
    contains "$gate" '"NativeBinarySHA256", None' &&
    contains "$gate" 'nativeBinaryHashBefore &&' &&
    contains "$gate" '"FixedPlanFLINTBinaryFile", None' &&
    contains "$gate" 'fixedPlanFLINTBinaryFile &&' &&
    contains "$gate" '"FixedPlanFLINTBinarySHA256", None' &&
    contains "$gate" 'fixedPlanFLINTBinaryHashBefore &' &&
    contains "$gate" '"NativePrimeArtifactProvenanceMismatch"' &&
    contains "$completion" 'nativeDependencyHashesAtCompletion = Map[' &&
    contains "$completion" 'nativeBinaryHashAtCompletion = FileHash[' &&
    contains "$completion" 'fixedPlanFLINTBinaryHashAtCompletion = FileHash[' &&
    contains "$completion" 'nativePrimeDriverHashAtCompletion = FileHash[' &&
    contains "$output" '"NativeDependencyHashes" -> nativeDependencyHashesBefore' &&
    contains "$output" '"NativeAdapterSHA256" -> nativeDependencyHashesBefore[' &&
    contains "$output" '"NativeModuleSHA256" -> nativeDependencyHashesBefore[' &&
    contains "$output" '"NativeBinarySHA256" -> nativeBinaryHashBefore' &&
    contains "$output" '"FixedPlanFLINTBinarySHA256" -> fixedPlanFLINTBinaryHashBefore' &&
    contains "$output" '"NativePrimeDriverSHA256" -> nativePrimeDriverHashBefore' &&
    grep -Fq -- 'First[primeDriverFiles] =!= nativePrimeDriverFile' "$source" &&
    grep -Fq -- 'nativeDependencyHashesAtCompletion =!=' "$source" &&
    grep -Fq -- 'nativeBinaryHashAtCompletion =!= nativeBinaryHashBefore' "$source" &&
    grep -Fq -- 'fixedPlanFLINTBinaryHashAtCompletion =!=' "$source" &&
    grep -Fq -- 'nativePrimeDriverHashAtCompletion =!=' "$source" &&
    grep -Fq -- '"NativePrimeArtifactRoleMismatch"' "$source"
}

if source_has_complete_native_gate "$aggregate"; then
  pass baseline_native_provenance_gate
else
  fail baseline_native_provenance_gate
fi

temporary_directory=$(mktemp -d)
trap 'rm -rf -- "$temporary_directory"' EXIT

expect_mutant_rejected() {
  local label=$1
  local mutant=$2
  if source_has_complete_native_gate "$mutant"; then
    fail "$label"
  else
    pass "$label"
  fi
}

altered="$temporary_directory/altered-native-hash-key.wls"
sed 's/"NativeBinarySHA256"/"NativeBinarySHA25X"/g' \
  "$aggregate" >"$altered"
expect_mutant_rejected altered_native_hash_key_rejected "$altered"

missing="$temporary_directory/missing-native-completion-hash.wls"
sed '/nativeDependencyHashesAtCompletion = Map\[/d' \
  "$aggregate" >"$missing"
expect_mutant_rejected missing_native_hash_recheck_rejected "$missing"

mixed="$temporary_directory/mixed-native-hashes-accepted.wls"
sed 's/AllTrue\[primeArtifacts,/AnyTrue[primeArtifacts,/g' \
  "$aggregate" >"$mixed"
expect_mutant_rejected mixed_native_hash_acceptance_rejected "$mixed"

legacy="$temporary_directory/legacy-prime-driver-accepted.wls"
sed 's/First\[primeDriverFiles\] =!= nativePrimeDriverFile/False/' \
  "$aggregate" >"$legacy"
expect_mutant_rejected legacy_prime_driver_acceptance_rejected "$legacy"

unsurfaced="$temporary_directory/native-adapter-hash-unsurfaced.wls"
sed '/"NativeAdapterSHA256" -> nativeDependencyHashesBefore\[/d' \
  "$aggregate" >"$unsurfaced"
expect_mutant_rejected missing_native_hash_surface_rejected "$unsurfaced"

printf 'CF300_RANK2_NATIVE_AGGREGATE_PROVENANCE_STATIC passes=%d failures=%d\n' \
  "$passes" "$failures"
((failures == 0))
