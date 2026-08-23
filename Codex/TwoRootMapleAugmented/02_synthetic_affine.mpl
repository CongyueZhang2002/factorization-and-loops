restart:
interface(prettyprint=0):

packageDirectory := "/home/maxzhang/factorization-and-loops/Addon/Other_Addon/Maple/IntegrableConnections":
libname := packageDirectory, libname:
with(IntegrableConnections):
with(linalg):

zeroMatrixQ := proc(M)
    evalb(convert(map(normal, evalm(M)), set) = {0})
end proc:

printf("BEGIN_NATIVE_RHS_TEST\n"):
A := [matrix(1, 1, [1/x]), matrix(1, 1, [1/y])]:
particularExpected := x + y + eps*x^2:
b := [
    vector(1, [normal(diff(particularExpected, x) - A[1][1,1]*particularExpected)]),
    vector(1, [normal(diff(particularExpected, y) - A[2][1,1]*particularExpected)])
]:
printf("A=%a\n", A):
printf("b=%a\n", b):
printf("integrability=%a\n", TestIntegrabilityConditions(A, [x,y], b)):

rhsStart := time[real]():
try
    rhsResult := RationalSolutions(A, [x,y], ['param', [eps], 'rhs', b]):
    rhsSeconds := time[real]() - rhsStart:
    printf("rhs_call_status=OK\n"):
    printf("rhs_seconds=%.6f\n", rhsSeconds):
    printf("rhs_result=%a\n", rhsResult):
catch:
    rhsSeconds := time[real]() - rhsStart:
    printf("rhs_call_status=ERROR\n"):
    printf("rhs_seconds=%.6f\n", rhsSeconds):
    printf("rhs_exception=%a\n", lastexception):
    quit:
end try:

rhsHomogeneous := op(1, rhsResult):
rhsParticular := op(2, rhsResult):
rhsHomogeneousResidual := [seq(
    map(normal, evalm(map(diff, rhsHomogeneous, [x,y][mu]) -
        A[mu] &* rhsHomogeneous)), mu=1..2)]:
rhsParticularResidual := [seq(
    map(normal, evalm(map(diff, rhsParticular, [x,y][mu]) -
        A[mu] &* rhsParticular - convert(b[mu], matrix))), mu=1..2)]:
printf("rhs_homogeneous_residual=%a\n", rhsHomogeneousResidual):
printf("rhs_particular_residual=%a\n", rhsParticularResidual):
printf("rhs_homogeneous_zero=%a\n",
    evalb({seq(zeroMatrixQ(rhsHomogeneousResidual[mu]), mu=1..2)} = {true})):
printf("rhs_particular_zero=%a\n",
    evalb({seq(zeroMatrixQ(rhsParticularResidual[mu]), mu=1..2)} = {true})):
printf("END_NATIVE_RHS_TEST\n"):

printf("BEGIN_AUGMENTED_TEST\n"):
particularZero := x + y:
particularResidue := eps*x^2:
f0 := [
    normal(diff(particularZero, x) - particularZero/x),
    normal(diff(particularZero, y) - particularZero/y)
]:
f1 := [
    normal(diff(particularResidue, x) - particularResidue/x),
    normal(diff(particularResidue, y) - particularResidue/y)
]:
augmentedA := [seq(matrix(3, 3, [
    A[mu][1,1], f0[mu], f1[mu],
    0, 0, 0,
    0, 0, 0
]), mu=1..2)]:
printf("augmented_A=%a\n", augmentedA):
printf("augmented_integrability=%a\n", TestIntegrabilityConditions(augmentedA, [x,y])):

augmentedStart := time[real]():
try
    augmentedResult := RationalSolutions(augmentedA, [x,y], ['param', [eps]]):
    augmentedSeconds := time[real]() - augmentedStart:
    printf("augmented_call_status=OK\n"):
    printf("augmented_seconds=%.6f\n", augmentedSeconds):
    printf("augmented_result=%a\n", eval(augmentedResult)):
catch:
    augmentedSeconds := time[real]() - augmentedStart:
    printf("augmented_call_status=ERROR\n"):
    printf("augmented_seconds=%.6f\n", augmentedSeconds):
    printf("augmented_exception=%a\n", lastexception):
    quit:
end try:

augmentedResidual := [seq(
    map(normal, evalm(map(diff, augmentedResult, [x,y][mu]) -
        augmentedA[mu] &* augmentedResult)), mu=1..2)]:
printf("augmented_residual=%a\n", augmentedResidual):
printf("augmented_residual_zero=%a\n",
    evalb({seq(zeroMatrixQ(augmentedResidual[mu]), mu=1..2)} = {true})):

expectedBasis := matrix(3, 3, [
    x*y, particularZero, particularResidue,
    0,   1,              0,
    0,   0,              1
]):
printf("expected_basis=%a\n", eval(expectedBasis)):
if rowdim(convert(augmentedResult, matrix)) = 3 and
        coldim(convert(augmentedResult, matrix)) = 3 then
    basisChange := map(normal, evalm(inverse(expectedBasis) &* augmentedResult)):
    basisChangeDerivative := [
        map(normal, map(diff, basisChange, x)),
        map(normal, map(diff, basisChange, y))
    ]:
    printf("basis_change=%a\n", eval(basisChange)):
    printf("basis_change_derivative=%a\n", basisChangeDerivative):
    printf("basis_change_kinematic_constant=%a\n",
        evalb({seq(zeroMatrixQ(basisChangeDerivative[mu]), mu=1..2)} = {true})):
    printf("basis_change_determinant=%a\n", normal(det(basisChange))):
else
    printf("basis_change=NOT_COMPUTED_WRONG_DIMENSIONS\n"):
end if:
printf("affine_semantics=coordinate_2_equals_1; coordinate_3_is_free_residue_parameter; coordinate_1_has_independent_homogeneous_freedom\n"):
printf("END_AUGMENTED_TEST\n"):

quit:
