"""Exact eps-Laurent valuation of the reconstructed NNLO UU coefficient columns.

Input format (ratracer output): "Expressions/Output_%06d_%06d.expr =\n  <expr>;"
with variables FACETff449fcadcv1..v5 = CA, CF, Epsilon, x, y (SymbolRules in
FiniteFieldCanonical/TraceManifest.wxf).  eps = v3.

Method: two RIGOROUS bounds that are computed in one parse and must meet.
  * structural lower bound  L  on ord_eps: ord(number)=0, ord(eps)=1,
    ord(other var)=0, ord(a^k)=k ord(a), ord(prod)=sum, ord(sum)>=min,
    ord(a/b) >= L(a) - U(b).   (>= throughout, so L <= ord.)
  * evaluation upper bound  U:  substitute exact values for CA,CF,x,y in a
    large prime field, keep eps SYMBOLIC as a polynomial; the resulting
    one-variable valuation is >= the generic one, so U >= ord.
If L == U the valuation is pinned EXACTLY, with no probabilistic step.
Several independent points are used; L is the max over points, U the min.
"""
import re, sys, random
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]

P = (1 << 61) - 1            # Mersenne prime, exact modular arithmetic
VARS = ["FACETff449fcadcv%d" % k for k in range(1, 6)]
EPSVAR = "FACETff449fcadcv3"

TOKEN = re.compile(r"\s*(?:(\d+)|(FACETff449fcadcv\d+)|([()+\-*/^,;]))")

# ---------------------------------------------------------------- polynomials
def ptrim(a):
    while len(a) > 1 and a[-1] == 0:
        a.pop()
    return a

def padd(a, b):
    if len(a) < len(b):
        a, b = b, a
    r = a[:]
    for i, c in enumerate(b):
        r[i] = (r[i] + c) % P
    return ptrim(r)

def pneg(a):
    return [(-c) % P for c in a]

def pmul(a, b):
    if a == [0] or b == [0]:
        return [0]
    if len(a) == 1:
        c = a[0]
        return ptrim([(c * x) % P for x in b])
    if len(b) == 1:
        c = b[0]
        return ptrim([(c * x) % P for x in a])
    r = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        if x:
            for j, y in enumerate(b):
                if y:
                    r[i + j] = (r[i + j] + x * y) % P
    return ptrim(r)

def ppow(a, k):
    r = [1]
    base = a
    while k:
        if k & 1:
            r = pmul(r, base)
        base = pmul(base, base)
        k >>= 1
    return r

def plowdeg(a):
    for i, c in enumerate(a):
        if c:
            return i
    return None                      # identically zero mod p

INF = float("inf")

class Val:
    """(structural lower bound, numerator poly, denominator poly) at one point."""
    __slots__ = ("lo", "n", "d")
    def __init__(self, lo, n, d):
        self.lo, self.n, self.d = lo, n, d

def vord(v):
    ln, ld = plowdeg(v.n), plowdeg(v.d)
    if ln is None:
        return INF
    if ld is None:
        raise ZeroDivisionError("denominator vanishes at the sample point")
    return ln - ld

def vmul(a, b):
    lo = INF if (a.lo is INF or b.lo is INF) else a.lo + b.lo
    return Val(lo, pmul(a.n, b.n), pmul(a.d, b.d))

def vdiv(a, b):
    ob = vord(b)
    lo = INF if a.lo is INF else (a.lo - ob if ob is not INF else INF)
    return Val(lo, pmul(a.n, b.d), pmul(a.d, b.n))

def vadd(a, b):
    lo = min(a.lo, b.lo)
    if a.d == b.d:
        return Val(lo, padd(a.n, b.n), a.d)
    return Val(lo, padd(pmul(a.n, b.d), pmul(b.n, a.d)), pmul(a.d, b.d))

def vneg(a):
    return Val(a.lo, pneg(a.n), a.d)

def vpow(a, k):
    if k >= 0:
        lo = INF if a.lo is INF else a.lo * k
        return Val(lo, ppow(a.n, k), ppow(a.d, k))
    k = -k
    oa = vord(a)
    lo = INF if oa is INF else -oa * k
    return Val(lo, ppow(a.d, k), ppow(a.n, k))

# ---------------------------------------------------------------- evaluation
PREC = {"+": 1, "-": 1, "*": 2, "/": 2, "^": 3}

def evaluate(text, point):
    """Shunting-yard over the token stream; `point` maps var name -> field elt
    (eps is the polynomial [0,1])."""
    out, ops = [], []
    def apply(op):
        if op == "u-":
            out.append(vneg(out.pop()))
            return
        b = out.pop(); a = out.pop()
        if op == "+": out.append(vadd(a, b))
        elif op == "-": out.append(vadd(a, vneg(b)))
        elif op == "*": out.append(vmul(a, b))
        elif op == "/": out.append(vdiv(a, b))
        elif op == "^":
            k = b.n
            if len(k) != 1 or b.d != [1]:
                raise ValueError("non-integer exponent")
            e = k[0]
            if e > P // 2:
                e -= P
            out.append(vpow(a, int(e)))
    prev = None                       # for unary minus detection
    pos, n = 0, len(text)
    while pos < n:
        m = TOKEN.match(text, pos)
        if not m:
            if text[pos].isspace():
                pos += 1
                continue
            raise ValueError("bad token at %r" % text[pos:pos+40])
        pos = m.end()
        num, var, sym = m.group(1), m.group(2), m.group(3)
        if num is not None:
            out.append(Val(0 if int(num) % P else INF, [int(num) % P], [1]))
            prev = "val"
        elif var is not None:
            if var == EPSVAR:
                out.append(Val(1, [0, 1], [1]))
            else:
                out.append(Val(0, [point[var] % P], [1]))
            prev = "val"
        elif sym == "(":
            ops.append("("); prev = "("
        elif sym == ")":
            while ops and ops[-1] != "(":
                apply(ops.pop())
            if not ops:
                raise ValueError("unbalanced )")
            ops.pop()
            prev = "val"
        elif sym in (";", ","):
            break
        else:
            if sym == "-" and prev in (None, "(", "op"):
                ops.append("u-"); prev = "op"
            elif sym == "+" and prev in (None, "(", "op"):
                prev = "op"
            else:
                while ops and ops[-1] != "(" and (
                        ops[-1] == "u-" or PREC[ops[-1]] >= PREC[sym]):
                    if sym == "^" and ops[-1] == "^":
                        break
                    apply(ops.pop())
                ops.append(sym); prev = "op"
    while ops:
        op = ops.pop()
        if op == "(":
            raise ValueError("unbalanced (")
        apply(op)
    if len(out) != 1:
        raise ValueError("parse left %d values" % len(out))
    return out[0]

def valuation(text, points):
    los, ups = [], []
    for pt in points:
        v = evaluate(text, pt)
        if plowdeg(v.n) is None:               # identically zero at this point
            los.append(v.lo); ups.append(INF); continue
        los.append(v.lo); ups.append(vord(v))
    L = max(los); U = min(ups)
    return L, U

# ---------------------------------------------------------------- driver
def main():
    src = (REPOSITORY_ROOT / "Codex/ppHX_NNLO_DoubleReal/"
           "CoefficientSimplification/UU_08_10_canonical/Reconstruction_2026_08_13/"
           "rec_rest.txt")
    rng = random.Random(20260816)
    points = []
    for _ in range(3):
        points.append({v: rng.randrange(2, P - 2) for v in VARS if v != EPSVAR})
    entries = []
    cur, buf = None, []
    with open(src) as f:
        for line in f:
            m = re.match(r"^Expressions/Output_(\d+)_(\d+)\.expr\s*=\s*$", line)
            if m:
                if cur is not None:
                    entries.append((cur, "".join(buf)))
                cur = int(m.group(1)); buf = []
            else:
                buf.append(line)
    if cur is not None:
        entries.append((cur, "".join(buf)))
    sys.stderr.write("entries: %d\n" % len(entries))
    out = open("valuations_rest.txt", "w")
    import time
    t0 = time.time()
    for k, (idx, body) in enumerate(sorted(entries)):
        try:
            L, U = valuation(body, points)
            status = "EXACT" if L == U else ("ZERO" if U is INF and L is INF else "BRACKET")
            if U is INF and L is INF:
                out.write("%d ZERO - - %d\n" % (idx, len(body)))
            else:
                out.write("%d %s %s %s %d\n" % (idx, status,
                    "inf" if L is INF else L, "inf" if U is INF else U, len(body)))
        except Exception as e:
            out.write("%d ERROR %s - %d\n" % (idx, type(e).__name__ + ":" + str(e)[:60], len(body)))
        out.flush()
        if (k + 1) % 25 == 0:
            sys.stderr.write("  %d/%d  %.1fs\n" % (k + 1, len(entries), time.time() - t0))
            sys.stderr.flush()
    out.close()
    sys.stderr.write("done %.1fs\n" % (time.time() - t0))

if __name__ == "__main__":
    main()
