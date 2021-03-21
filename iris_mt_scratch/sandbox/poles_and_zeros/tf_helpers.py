import numpy as np

from scipy import signal


def evaluate_transfer_function_response(num, den, w):
    """
    num, array-like : numerator coefficients, in decreasing order
    den, array-like : denomenator coefficients, in decreasing order
    w, array-like   : angular frequencies at which to evalute 
                      the function
    """
    tf = signal.TransferFunction(num, den)
    w, resp = signal.freqresp(tf, w=w)
    return resp

def get_jacobian(num, den, w):
    """
    num, array-like : numerator coefficients, in decreasing order
    den, array-like : denomenator coefficients, in decreasing order
    w, array-like   : angular frequencies at which to evalute
                      the function
    """
    jac = np.zeros((w.size, num.size + den.size), dtype=np.complex128)
    s = 1.j * w
    n_s = np.polyval(num, s)
    d_s = np.polyval(den, s)
    for i in range(num.size):
        jac[:, i] = s**(num.size - 1 - i) / d_s
    for i in range(den.size):
        jac[:, i + num.size] = - s**(den.size - 1 - i) * n_s / d_s**2.
    return jac



def Fit_ZerosPolesGain_toFrequencyResponse_LM(w, resp, m, n):
    """
    w (array)    : (real) angular frequencies at which we
                      have the system response
    resp (array) : complex system response at angular frequencies w
    m (int)      : number of zeros to use in the fit; number of
                      numerator coefficients will be m + 1
    n (int)      : number of poles to use in the fit; number of
                      denominator coefficients will be n + 1
    """

    # set up initial guess.
    tf = np.zeros(m + 1 + n + 1, dtype=np.complex128)
    tf[:] = 1.   # for now, just set initial guess at all ones
    print("Initial Numerator Guess: ", tf[:m+1])
    print("Initial Denominator Guess: ", tf[m+1:])

    # evaluate initial misfit
    resp_pred = \
        evaluate_transfer_function_response(tf[:m+1], tf[m+1:], w)
    resid = resp - resp_pred
    misfit = np.mean(np.absolute(resid))
    print("Initial misfit: ", misfit)

    max_iter = 10
    l = 1
    for i in range(max_iter):

        misfit_previous = misfit

        # (1) get Jacobian matrix
        jac = get_jacobian(tf[:m+1], tf[m+1:], w)

        # (2) solve the least squares system, with L-M damping
        hes = np.matmul(jac.conj().T, jac)
        hes += l * np.eye(m + 1 + n + 1)
        d_tf = np.matmul(np.matmul(np.linalg.inv(hes), jac.conj().T),
                         resid)
        # PROBLEM the polynomial coefficients are becoming complex

        # (3) update model parameter
        tf += d_tf

        # (4) evaluate misfit
        resp_pred = \
            evaluate_transfer_function_response(tf[:m+1], tf[m+1:], w)
        resid = resp - resp_pred
        misfit = np.mean(np.absolute(resid))
        print("Misfit Step {:d}: ".format(i+1), misfit)

        # (5) adjust damping term l
        if misfit > misfit_previous: l *= 2
        else: l /= 2

    return signal.TransferFunction(tf[:m+1], tf[m+1:]).to_zpk()


def Fit_ZerosPolesGain_toFrequencyResponse_LLSQ(w, resp, m, n,
                                                useSKiter=False,
                                                regularize=False):
    """
    USING Levy Method ("Error-Equation" Method) TO MAKE THIS A LINEAR
    LEAST SQUARES PROBLEM. THEN OPTIONALLY USING Sanathanan-Koerner (SK)
    Iteration TO DEAL WITH THE BIAS INTRODUCED BY THE WAY THE PROBLEM
    IS SET UP. ALSO INCLUDES OPTIONAL REGULARIZATION.

    w (array)    : (real) angular frequencies at which we
                      have the system response
    resp (array) : complex system response at angular frequencies w

    m (int)      : number of zeros to use in the fit; number of
                      numerator coefficients will be m + 1
    n (int)      : number of poles to use in the fit; number of
                      denominator coefficients will be n + 1

    useSKiter (bool)   : flips on/off Sanathanan-Koerner (SK) iteration

    regularize (bool)  : flips on/off regularization

    """

    # CONVERT TO COMPLEX (LAPLACE) FREQUENCY, DEFINE USEFUL VALUES
    s = 1.j * w
    num = m + 1
    den = n + 1

    # SET UP ITERATION CONTROLS
    if useSKiter:
        iter_max = 100
    else:
        iter_max = 1
    tf = None
    iter_count = 0
    for it in range(iter_max):

        # (1) SET UP DESIGN MATRIX
        # Because of the way this problem is framed, the constant term
        # in the denominator is not included here. See notes above.
        # Basically, the constant term from the denominator is over
        # in the RHS vector.
        g = np.zeros((w.size, num + den - 1), dtype=np.complex128)
        for i in range(num):
            g[:, i] = s**(num - 1 - i)
        for i in range(den - 1):
            g[:, i + num] = - resp * s**(den - 1 - i)

        # (2) SET UP WEIGHTS
        # In S-K iteration, the system is weighted by the denominator
        # of theprevious iteration. During the first iteration,
        # set weights = 1.
        if tf is None:
            weights = np.eye(resp.size)
        else:
            weights = np.diag(np.polyval(tf[m+1:], w))

        # (3) COMPUTE THE SVD
        u, sing, vh = np.linalg.svd(np.matmul(weights, g),
                                    full_matrices=True)

        # (4) REGULARIZE, IF NECESSARY
        if regularize:
            alpha = np.logspace(-4, 4, num=100)
            sing_full = np.zeros(u.shape[0])
            sing_full[:sing.size] = sing
            filt = sing_full[np.newaxis, :]**2. / \
                   (sing_full[np.newaxis, :]**2. +
                    alpha[:, np.newaxis]**2.)
            d_bar = np.matmul(u.conj().T, np.matmul(weights, resp))
            err = np.matmul((1. - filt)**2., d_bar**2.) / \
                  (resp.size * np.sum(1. - filt, axis=1)**2.)
            alpha_optimal = alpha[np.argmin(err)]
            print("Regularization Parameter: ", alpha_optimal)
            filter_factors = sing**2. / (sing**2. + alpha_optimal**2.)
            print("Max/Min Filter Factors: ", np.amax(filter_factors),
                  " / ", np.amin(filter_factors))
        else:
            filter_factors = np.ones(sing.size)

        # (4) CALCULATE THE MODEL PARAMETER
        # Need to concatenate a value of [1] on the end of the model
        # parameter in order to get the full list of transfer function
        # coefficients. The [1] is the constant term in the
        # denominator polynomial.
        model = \
    np.matmul(vh.conj().T,
              np.matmul(np.diag(filter_factors),
                        np.matmul(np.diag(sing**-1.),
                                  np.matmul(u[:, :num+den-1].conj().T,
                                            np.matmul(weights, resp)))))
        tf_previous = tf
        tf = np.concatenate((model, np.array([1.])))

        # (5) EVALUATE THE CHANGE FROM THE LAST MODEL PARAMETER
        # Break iteration if the percent change in mean magnitude is <1%
        if tf_previous is not None:
            mean_value = np.mean(np.absolute(tf_previous))
            mean_change = np.mean(np.absolute(tf - tf_previous))
            if mean_change / mean_value < 0.01:
                break
        iter_count += 1

    if useSKiter:
        print("Number of S-K iterations: ", iter_count)

    # (6) RETURN THE RESULT IN POLES-ZEROS FORM
    return signal.TransferFunction(tf[:m+1], tf[m+1:]).to_zpk()


