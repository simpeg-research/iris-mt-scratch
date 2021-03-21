import numpy as np

def add_regularization_term(zeros, poles, k, misfit, aa=0.1, verbose=False):
    """
    We could probably do a better job on the conjugate condition by grouping the individual
    poles in pairs and forcing them to have balanced imaginary parts AND balanced real parts.

    Not clear how well that would work ...
    -you would definitely need to keep the groupings the same for the duration
    of the inversion
    -need to identify if number is odd or even.
    -If odd, pop off the first one and force it to be real by penalizing
    its imaginary component
    -keep the remaining 2N poles as the conjugates.
    -divide the number by two, and for each
    """
    if verbose:
        print('misfit in', misfit)
    # punish unbalanced imaginary components
    misfit += aa * np.abs(np.mean(np.sum(np.imag(zeros))))
    misfit += np.abs(np.mean(np.sum(np.imag(poles))))
    misfit += aa * np.abs(np.imag(k))
    # punish poles on rhs of plane
    for pole in poles:
        if np.real(pole) > 0:
            misfit += aa * np.abs(np.real(pole))  # + aa / np.abs(np.real(pole) )
            # misfit += aa * np.abs(np.real(pole) )
    if verbose:
        print('misfit out', misfit)
    return misfit


def get_pz_regularization(pz, aa=0.1):
    """
    """
    penalty = 0.0
    if np.mod(len(pz), 2) == 1:
        real_pz = pz[0]
        conjugate_pzs = pz[1:]
    else:
        real_pz = 0.0
        conjugate_pzs = pz
    penalty = aa * np.imag(real_pz)
    # print('penalty', penalty)
    n_conjugate_pairs = int(len(conjugate_pzs) / 2)
    # print('n_conjugate_pairs',n_conjugate_pairs)
    for i_conjugate_pair in range(n_conjugate_pairs):
        p1 = conjugate_pzs[0 + i_conjugate_pair * 2]
        p2 = conjugate_pzs[1 + i_conjugate_pair * 2]
        penalty += aa * np.abs(np.real(p1) - np.real(p2))  # reals should be close
        penalty += aa * np.abs(np.imag(p1) + np.imag(p2))  # imags should be opposite
    return penalty


def add_regularization_term2(zeros, poles, k, misfit, aa=0.1, verbose=False):
    """
    We could probably do a better job on the conjugate condition by grouping the individual
    poles in pairs and forcing them to have balanced imaginary parts AND balanced real parts.

    """
    # print('zeros', zeros)
    # print('poles', poles)
    if verbose:
        print('misfit in', misfit)
    if len(zeros) > 0:
        print(zeros)
        misfit += get_pz_regularization(zeros, aa=aa)
    if len(poles) > 0:
        misfit += get_pz_regularization(poles, aa=aa)

    misfit += aa * np.abs(np.imag(k))
    # punish poles on rhs of plane
    #     for pole in poles:
    #         if np.real(pole)>0:
    #             misfit += aa * np.abs(np.real(pole) ) #+ aa / np.abs(np.real(pole) )
    if verbose:
        print('misfit out', misfit)
    return misfit