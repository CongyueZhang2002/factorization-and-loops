# Final coefficient results

Completed coefficient values belong under <process>/Results/<run>. Traces,
normalized target records, reconstruction probes and completed coefficient Kira
databases are disposable working data. Failed or unfinished runs keep their
restart data.

The current main NNLO UU result is:
Projects/ppHX_UU/NNLO/qqp-qqp/Results/DoubleReal/UU_08_10_canonical/MasterIntegralCoefficients.wxf.

It contains all 347 master coefficients: 345 exact expressions and two Laurent
expansions, both through epsilon^5. The latter start at epsilon^-4 and epsilon^-2.
Their omitted terms begin at epsilon^6 inside the stored analytic prefactor.
This is a limitation of the completed reconstruction, not a claim that those
two coefficients are exact in epsilon.

## Reading the result

After loading FACET, use Import[file, "WXF"]. The file contains expressions,
not file references or reconstruction generators.

The value multiplying a master is the global "PreFactor" times the sum of
that master's "Terms". Each term has an analytic "PreFactor" and a
"Coefficient". "Representation" is either "Exact" or "LaurentSeries".

For an exact term the coefficient is an expression. For a Laurent term it is
an association with "SeriesVariable", integer-keyed "Orders", and
"SeriesTruncation". Evaluate the finite Laurent sum as:

    Total[KeyValueMap[#2 variable^#1 &, coefficient["Orders"]]]

and multiply by the term prefactor. The prefactor can depend on epsilon;
it is deliberately kept outside the rational Laurent coefficients. Expand that
prefactor too when extracting coefficients of the complete epsilon expansion.
Do not interpret a stored truncated sum as an all-orders expression.

"RemainderTerms" uses the same convention; an empty list means zero.
"Definitions" includes the process setup, dimension rule, physical kinematics,
topology and cut definitions, reverse rules and topology equivalences.
No file in a deleted reconstruction directory is needed to interpret the values.
The Format is FeynFacet-MasterIntegralCoefficients, version 1.

Existing NLO and ghost CoefficientResult.wl files remain final FormatVersion-8
FeynFacet-IBP records and can be read with Get. Their mathematical values are
unchanged.

## Consolidating completed split reconstructions

Scripts/finalize_coefficients.wls accepts one Wolfram request file:

    <|
      "TraceDirectory" -> "/absolute/path/to/FiniteField",
      "DefinitionFile" -> "/absolute/path/to/KiraStore/Metadata.bin",
      "RationalResults" -> {"/absolute/path/to/rec_exact.txt"},
      "SeriesResults" -> {
        <|"Variable" -> Global`Epsilon, "Order" -> 5,
          "Files" -> {"/absolute/path/to/series_completed.txt"}|>
      },
      "OutputFile" -> "/process/Results/run/MasterIntegralCoefficients.wxf"
    |>

Use only completed reconstruction files. The exporter rejects duplicate or
missing outputs, incomplete target sets, malformed/gapped Laurent sequences,
and series that do not reach the requested order. It restores physical
symbols and analytic prefactors, writes compressed WXF and requires an exact
serialization read-back. It refuses to overwrite an existing final file.
It does not rerun root/cut certification and records that fact explicitly.
The request and reconstruction inputs are not dependencies of the final file.

## Production retention

The project form of CoefficientSimplification and ReconstructCoefficients
default to "KeepWorkingFiles" -> False. After a complete result has been
saved and read back, they remove that run's guarded CoefficientSimplification
workspace. ReconstructCoefficients now defaults its result path to the actual
process Results/<run>/CoefficientResult.wl.

"KeepWorkingFiles" -> True retains temporary files for an explicit diagnostic
or additional reconstruction. "ResultFile" -> None returns the result in memory
and retains the working data; so does an explicit output inside the work
directory. The low-level CoefficientSimplification[inputs, kiraFile] form also
returns in memory, so its caller owns saving and cleanup. Incomplete runs retain
working data even if a partial result is written. Kira workspaces are removed
separately once their coefficient jobs are complete; the general IBP reduction
tables required by DE construction remain inputs.

Parser tests create tiny synthetic traces. NLO and ghost reconstruction
integration tests generate traces from retained amplitude/reduction inputs,
then remove them. They no longer require permanent production intermediates.
