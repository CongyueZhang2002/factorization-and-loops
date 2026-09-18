# Readable Wolfram records

Generated mathematical text is stored as a pair:

- `Results.wl` is ordinary, readable Wolfram Language. Partonic results put
  `Coefficients` first, then epsilon coverage and physical conventions.
- `Results.wl.meta.wxf` contains exact symbol identities and the execution,
  definition and validation metadata omitted from the displayed result.

`Get["Results.wl"]` directly exposes the mathematics using ordinary Wolfram
symbol resolution. For further framework computation, use
``FeynFacet`ReadPartonicResult["Results.wl"]`` or
``FeynFacet`FamilyArtifactRead["Results.wl"]``. These restore the complete
common schema and original symbol contexts. Numerical zero is displayed as zero;
for example, incoming TT and transverse spin transfer are distinct calculations.

The codec lives in [Core/RecordFormat.wl](../FeynFacet/Core/RecordFormat.wl).
It has no FeynCalc dependency and is loaded by both package entry points.
Intermediate records use the same codec; native solver/FORM files retain their
required native syntax, and explicit `.wxf` products remain binary.

## Exact identities without context prefixes

Every non-System symbol receives a readable local spelling. If two distinct
symbols share a name, or a name conflicts with System, an indexed spelling is
used, such as `x` and `x2`. The companion maps each spelling back to its original
held symbol. Context prefixes are not stripped with textual replacement.
Strings retain their literal contents. Association keys receive the same
treatment as values. UTF-8 and multiline expressions are tested explicitly.
Wolfram abbreviations are not structurally exact inside held expressions
(for example I versus Complex[0,1]); the companion therefore retains those
held subexpressions at their original positions. It does not duplicate the
complete coefficient payload.

A write identifier in the header and companion detects accidentally mixed
pairs. There are **no new content hashes**. This identifier is not a checksum:
editing coefficient text does not automatically update scientific validation.
Recompute and revalidate an intentionally changed result.

## Reading and moving files

Use `FamilyArtifactWrite[value,file]` for generated records, and
`FamilyArtifactMove`, `FamilyArtifactCopy`, `FamilyArtifactDelete` for file
operations. The standalone equivalents live in the `FeynFacetRecords` context.
Missing or mismatched companions cause exact machine reading to fail. A brief
bounded retry covers replacement of the two files. Existing plain input cards
and external reference formulas can still be read normally.

Text and metadata are written to temporary files before replacement.
No second complete coefficient payload is stored in the companion. Reported
result size includes both files. The accepted `Compression` option does not
turn readable `.wl` text into an opaque compressed expression; binary companions
are compact by default.

[Core tests](../Tests/Core/t_readable_records.wls) cover shadowed symbols,
Unicode, multiline records, held expressions, common result restoration and
paired file operations. End-to-end regeneration verifies the physical schema.

## Exact held syntax and cache inputs

The reader rejects context-qualified symbols outside strings and aliases absent
from the companion. It checks association keys as well as values. The text
check walks backtick positions against non-overlapping quoted-string spans;
escaped quotes remain inside their strings. It does not copy the complete
expression merely to remove strings. Associations
whose held keys can acquire identical InputForm spellings retain their exact
original container in metadata; ordinary coefficient maps do not need this
extra payload. Atomic complex numbers in that held metadata are encoded
explicitly to distinguish them from deliberately unevaluated Complex syntax.

The `.wl` and `.meta.wxf` form one logical input. Coefficient reuse compares
companion bytes exactly in addition to its existing text-file identity.
Companion snapshots are kept in binary metadata, not displayed in the
mathematical record.


Sparse matrices are written using explicit SparseArray rules and dimensions,
without dense expansion. Symbol aliases include stored entries and symbolic
defaults. Reading delays sparse-array construction until exact symbol identities
have been restored. Deliberately inactive constructors and literal strings retain
their original meaning. The writer rejects qualified symbols before committing
either file; large quoted strings are scanned without recursive regex expansion.
