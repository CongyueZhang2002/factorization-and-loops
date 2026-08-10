# Size and counting conventions

The word "size" is meaningless unless its metric and object are stated.  This
record uses the following quantities.

## Mathematica `ByteCount`

`ByteCount[expr]` estimates the memory occupied by one Mathematica expression
in the running kernel.  It is used for pair, target, master, fraction-list, and
tensor-expression comparisons performed with one Mathematica version.  It is
not an on-disk file size and should not be compared directly with a serialized
file byte count.

## Serialized bytes

`FileByteCount[file]` is the exact number of bytes in a saved `.wl` or binary
artifact.  It depends on the serialization grammar.  It is useful for storage
and I/O planning, but two different serialization formats may have different
sizes for mathematically identical expressions.

## Additive terms

An additive-term count is the number of terms after splitting only the
top-level `Plus`.  It depends on whether common factors remain outside the
sum.  It is therefore reported as a structural diagnostic, not as an
invariant measure of analytic complexity.

## Objects simplified

An object is one independently scheduled coefficient.  Depending on the
route, it is an amplitude-pair coefficient, a complete Kira-target
coefficient, or a final master coefficient.  Counts from different routes are
not interchangeable.

## Target leaves and denominator entries

A target leaf is one contribution generated when a Kira target rule is
inserted into a selected master column.  Several leaves can share one source
entry.  A denominator entry is an exact numerator-denominator pair stored
after branch-safe hadronic cleanup.  Therefore a column can have more leaves
than denominator entries.

## Fraction and denominator-class counts

A fraction is one stored exact pair `{numerator, denominator}`.  A denominator
class consists of fractions whose denominators are structurally identical.
A hash is used only to find candidates; structural equality determines class
membership.

## Reduction factors

Every reduction factor in this record is `input bytes/output bytes` using one
and the same metric.  A value larger than one means that representation became
smaller.  An expansion factor is `output bytes/input bytes`.

