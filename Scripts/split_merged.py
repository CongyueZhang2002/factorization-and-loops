#!/usr/bin/env python3
"""Split a MERGED canonical column '(w1)*(body1)+(w2)*(body2)+...'
into one 'weight<TAB>contribution' line per contribution, where each
body is itself a depth-0 '+'-joined list of '(t)*(r)' contributions."""
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    text = f.read().strip()


def depth_split(s):
    parts, depth, start = [], 0, 0
    for i, c in enumerate(s):
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        elif c == "+" and depth == 0:
            parts.append(s[start:i])
            start = i + 1
    parts.append(s[start:])
    return parts


out = open(dst, "w")
count = 0
for piece in depth_split(text):
    m = re.match(r"^\(([^()]*)\)\*\((.*)\)$", piece, re.S)
    if not m:
        sys.exit(f"UNRECOGNIZED PIECE: {piece[:120]}")
    weight, body = m.group(1), m.group(2)
    for contribution in depth_split(body):
        out.write(weight + "\t" + contribution + "\n")
        count += 1
out.close()
print(f"CONTRIBUTIONS: {count}")
