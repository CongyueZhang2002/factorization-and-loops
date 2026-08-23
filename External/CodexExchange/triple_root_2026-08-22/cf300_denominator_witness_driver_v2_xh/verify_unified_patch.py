#!/usr/bin/env python3
"""Apply the staged unified diff in memory and require byte-equivalent lines."""

import re
from pathlib import Path


HERE = Path(__file__).resolve().parent
V1 = HERE.parent / "cf300_sector12_next_ansatz_xh/run_cf300_sector12_denominator_witness_screen.wls"
V2 = HERE / "run_cf300_sector12_denominator_witness_screen_v2.wls"
PATCH = HERE / "0001-v2-select-before-build-and-product-masks.patch"


def apply_unified(old_lines, patch_lines):
    output = []
    cursor = 0
    index = 2
    while index < len(patch_lines):
        header = re.fullmatch(
            r"@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@", patch_lines[index]
        )
        if header is None:
            raise AssertionError(f"invalid hunk header: {patch_lines[index]!r}")
        old_start = int(header.group(1)) - 1
        old_count = int(header.group(2) or "1")
        output.extend(old_lines[cursor:old_start])
        cursor = old_start
        consumed = 0
        index += 1
        while index < len(patch_lines) and not patch_lines[index].startswith("@@ "):
            line = patch_lines[index]
            if line.startswith(" "):
                assert old_lines[cursor] == line[1:]
                output.append(line[1:])
                cursor += 1
                consumed += 1
            elif line.startswith("-"):
                assert old_lines[cursor] == line[1:]
                cursor += 1
                consumed += 1
            elif line.startswith("+"):
                output.append(line[1:])
            elif line == r"\ No newline at end of file":
                pass
            else:
                raise AssertionError(f"invalid hunk line: {line!r}")
            index += 1
        assert consumed == old_count, (consumed, old_count)
    output.extend(old_lines[cursor:])
    return output


def main():
    old = V1.read_text().splitlines()
    expected = V2.read_text().splitlines()
    patch = PATCH.read_text().splitlines()
    assert patch[0] == (
        "--- a/cf300_sector12_next_ansatz_xh/"
        "run_cf300_sector12_denominator_witness_screen.wls"
    )
    assert patch[1] == (
        "+++ b/cf300_denominator_witness_driver_v2_xh/"
        "run_cf300_sector12_denominator_witness_screen_v2.wls"
    )
    observed = apply_unified(old, patch)
    assert observed == expected
    print(f"PASS staged patch reconstructs V2 exactly ({len(patch)} lines)")


if __name__ == "__main__":
    main()
