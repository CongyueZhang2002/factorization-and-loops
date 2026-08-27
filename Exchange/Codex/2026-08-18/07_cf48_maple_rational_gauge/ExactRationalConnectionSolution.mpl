# Exact rational particular solutions of flat inhomogeneous connections.
#
# A = [A_1,...,A_m], x = [x_1,...,x_m], b = [b_1,...,b_m]
# define d_i V = A_i V + b_i.  params lists every symbolic parameter in
# the coefficient field other than the differential variables.
#
# This routine handles the important fast path in which one univariate
# equation determines a unique rational particular solution.  It tries every
# differential variable and accepts a candidate only after exact substitution
# into all m equations.  FAIL means that this fast path did not decide the
# problem; it is not a proof that no rational solution exists.

ExactRationalConnectionSolution := proc(A::list, x::list, b::list,
    params::list)
local m, i, j, V, VL, constants, residuals, zeroResidual;

    m := nops(x);
    if nops(A) <> m or nops(b) <> m then
        error "A, x, and b must have the same length"
    end if;

    for i to m do
        try
            V := IntegrableConnections:-Mratsolde(
                convert(A[i], matrix), x[i], b[i]);

            if V = {} then
                next
            end if;

            VL := convert(V, list);
            constants := indets(VL, name) minus
                {op(x), op(params)};

            if nops(constants) <> 0 then
                next
            end if;

            residuals := [seq(
                map(normal,
                    diff(VL, x[j]) -
                    convert(evalm(A[j] &* V), list) -
                    convert(b[j], list)),
                j = 1 .. m)];
            zeroResidual := true;
            for j to m do
                if convert(residuals[j], set) <> {0} then
                    zeroResidual := false;
                    break
                end if
            end do;

            if zeroResidual then
                return table([
                    "SolutionList" = VL,
                    "FirstVariableIndex" = i,
                    "FirstVariable" = x[i],
                    "Residuals" = residuals,
                    "HomogeneousConstants" = constants
                ])
            end if
        catch:
            # A failure for one variable ordering does not invalidate another.
        end try
    end do;

    return FAIL
end proc:
