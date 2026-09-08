# Authorized sequence: master validation, then double-real distributions

The user authorized this sequence on 2026-09-07:
first watch the current complete-master validation and fix problems;
afterward start steps 1-4 of the proposed assembly work. No further approval
is required for that implementation.

## Prerequisite and current computation

Finish the 91-family/345-master/2,220-coefficient comparison at v=1/4,w=1/5.
Read the live files in
ppHX_NNLO_DoubleReal/Results/Validation/FullValidation_2026-09-07.
Use the existing dynamic pool and resume unfinished families after fixing
general failures. Preserve accepted AMFlow references. Do not repeat AMFlow
when only the physical DE evaluation needs repair.

The separate stage-3 reference inventory is still incomplete. Report its
missing references accurately; do not create a new requirement to complete
that separate inventory before the user-authorized assembly phase.

The master comparison is now complete and passing. Initial assembly identity
and format findings are in
ppHX_NNLO_DoubleReal/Results/Assembly/InitialInputs_2026-09-07/README.md.
The identity audit is complete: the two main dotted-master entries are literal
exact zeros, and all ghost entries have exact maps into the validated basis.
The retained proofs and maps are in Results/Assembly/MasterMaps_2026-09-07.
The weighted and physically normalized 345-master tables are in
Results/Assembly/Stage4_2026-09-07. Generic interior epsilon coverage does not
by itself establish the distribution-specific demands below.

## Step 1: physical double-real assembly

Implement a general input interface for the retained coefficient formats,
explicit finite master solutions and process contribution weights. The
current main coefficient file is
ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/MasterIntegralCoefficients.wxf.
Locate the corresponding final ghost coefficient result. Audit the union of
master identities and required epsilon orders, scalar prefactors, phase-space
normalization, flux, spin/color factors and the observable differential measure.

Combine coefficients of identical physical masters before expensive endpoint
operations. Preserve exact coefficients and the declared truncation of the two
Laurent-reconstructed entries. Record exactly which partonic channels and cuts
are included. Current cards provide the ud -> udgg contribution and its ghost
completion; this is not all NNLO partonic contributions.

## Step 2: endpoint functions with variable scattering kinematics

The physical recoil-mass coordinate is z=Q_X^2/s=1-v-w, with endpoint z=0.
Keep the tangential scattering variable v symbolic. Present physical boundary
normalization was obtained on v=1/4,w=3/4-z; those data fix constants but are not
the full variable-v endpoint functions required for distribution coefficients.

Use the local form of the existing two-variable DE and its tangential
equations, matched to the established physical normalization. Keep epsilon
dependent powers and logarithmic modes until distribution extraction. Discuss
the nontrivial local/tangential DE construction and intersecting endpoints
with Pro before implementing the mathematical choice.

## Step 3: distribution-specific epsilon requirements

Connect endpoint projections and all actual prefactors to the existing order
planner, working backward from the requested final epsilon order. Delta terms
can demand extra endpoint coefficients even when the regular remainder does
not require deeper global solutions. Do not assume the current generic-point
2,220-coefficient demand proves sufficient orders for distributions.

Construct any newly demanded finite coefficients explicitly and obtain the
corresponding physical boundary data. Never hide missing orders in a generator
or interpret them as zero.

## Step 4: delta, plus distributions and regular remainder

Return explicit distribution coefficients by partonic channel, color structure
and perturbative order, together with a finite representation of the locally
integrable remainder. Define the integration interval, coordinate Jacobian,
scales and plus prescription as part of the input/output convention.

For the usual single-threshold finite NNLO coefficient the basis is delta(z),
[log^k(z)/z]_+ for k=0..3, and a locally integrable remainder. The general code
must derive actual intermediate requirements from the regulated expressions,
handle or explicitly resolve higher endpoint powers, and allow multiple
endpoint variables for other observables. Regular may include integrable
endpoint logarithms.

Retain explicit finite shared expressions rather than expanding every special
function repeatedly. Demonstrate the general path on the current double-real
contribution, retaining its epsilon poles and recording missing NNLO sectors.
Use proportionate checks: consistency with the assembled interior expression,
endpoint limits and a few smooth test-function integrals. Do not turn checking
into the dominant calculation.

## Scope of completion

The deliverable is general production code plus the assembled current
double-real distribution result. No family-specific production branches and
no backward-compatibility requirement. Consult Pro on nontrivial mathematical
decisions and retain the exchange. Keep ~/FACET read-only and all computed
artifacts under the process Results folder.

Adding real-virtual, double-virtual, the other real channels and full coupling,
PDF and fragmentation-function counterterms is step 5, outside this explicit
1-4 instruction. Do not call the current double-real result a complete finite
NNLO hard coefficient.
