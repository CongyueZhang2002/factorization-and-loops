"""Independent finite-dimensional Clifford check, never a production coefficient.

Embeds physical external vectors in D=4,6,8 and realizes BMHV gamma5 as
its four-dimensional definition. Normalized traces keep tr(1)=4. The two
ordinary Compton diagrams are contracted directly with numerical matrices.
"""
import numpy as np


def clifford(dimension):
    identity = np.eye(2, dtype=complex)
    zero = np.zeros((2, 2), dtype=complex)
    pauli = [np.array([[0, 1], [1, 0]]),
             np.array([[0, -1j], [1j, 0]]), np.diag([1, -1])]
    physical = [np.diag([1, 1, -1, -1]).astype(complex)]
    physical += [np.block([[zero, matrix], [-matrix, zero]]) for matrix in pauli]
    gamma5 = 1j * physical[0] @ physical[1] @ physical[2] @ physical[3]
    if dimension == 4:
        return physical, gamma5
    extra = pauli[:2] if dimension == 6 else [physical[0], *[1j * g for g in physical[1:]]]
    identity = np.eye(len(extra[0]))
    gamma = [np.kron(g, identity) for g in physical]
    gamma += [1j * np.kron(gamma5, g) for g in extra]
    return gamma, np.kron(gamma5, identity)


def born_moment(x, z, dimension):
    gamma, gamma5 = clifford(dimension)
    metric = np.diag([1, -1, -1, -1])
    qscale, r = 2.0, 1.0 / x - 1.0
    p = qscale / 2 * np.array([1 + r, 0, 0, 1 + r])
    q = np.array([0.0, 0, 0, -qscale])
    # Published Breit-frame Born coordinates, independent of package Gram rules.
    k = qscale / 2 * np.array([r + (1 - r) * z,
                               2 * np.sqrt(r * z * (1 - z)), 0, r - (1 + r) * z])
    sx, sy = np.array([0.0, 1, 0, 0]), np.array([0.0, 0, 1, 0])
    sout = np.array([0.0, k[3] / k[0], 0, -k[1] / k[0]])
    slash = lambda v: sum(v[i] * metric[i, i] * gamma[i] for i in range(4))
    s = (p + q) @ metric @ (p + q)
    t = (k - q) @ metric @ (k - q)
    result = []
    for polarizations in [[sx, sy], [np.array([1.0, 0, 0, 0])], [q]]:
        value = 0j
        for incoming, outgoing in [(sx, sout), (sy, sy)]:
            rhoi = gamma5 @ slash(incoming) @ slash(p) / 2
            rhof = gamma5 @ slash(outgoing) @ slash(k)
            for photon in polarizations:
                for a in range(dimension):
                    amplitude = (gamma[a] @ slash(p + q) @ slash(photon) / s
                                 + slash(photon) @ slash(k - q) @ gamma[a] / t)
                    conjugate = gamma[0] @ amplitude.conj().T @ gamma[0]
                    value += (-1 if a == 0 else 1) * np.trace(rhof @ amplitude @ rhoi @ conjugate)
        value /= (len(gamma[0]) / 4) * 2 * len(polarizations)
        result.append(value)
    return np.array(result)


if __name__ == "__main__":
    for x, z in [(1 / 2, 1 / 3), (2 / 5, 3 / 7), (3 / 4, 2 / 5)]:
        for dimension in [4, 6, 8]:
            value = born_moment(x, z, dimension)
            assert np.max(np.abs(value - [4, 0, 0])) < 1e-11, (x, z, dimension, value)
            print(f"PASS D={dimension}, x={x:.5g}, z={z:.5g}: T=4, L=0, Ward=0")
