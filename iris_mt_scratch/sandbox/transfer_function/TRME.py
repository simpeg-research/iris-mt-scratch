"""
follows Gary's TRME.m in
iris_mt_scratch/egbert_codes-20210121T193218Z-001/egbert_codes/matlabPrototype_10-13-20/TF/classes

% 2009 Gary Egbert , Maxim Smirnov
% Oregon State University

%
%  (Complex) regression-M estimate for the model  Y = X*b
%
%  Allows multiple columns of Y, but estimates b for each column separately
%
%   S and N are estimated signal and noise covariance
%    matrices, which together can be used to compute
%    error covariance for the matrix of regression coefficients b
%  R2 is squared coherence (top row is using raw data, bottom
%    cleaned, with crude correction for amount of downweighted data)

%  Parameters that control regression M-estimates are defined in ITER

initialization:
obj = TRME(X=X, Y=Y, iter_control=iter)

THe QR-decomposition is employed on the matrix of independent variables.
X = Q R where Q is unitary/orthogonal and R upper triangular.
Since X is [n_data x n_channels_in] Q is [n_data x n_data].  Wikipedia has a
nice description of the QR factorization:
https://en.wikipedia.org/wiki/QR_decomposition
On a high level, the point of the QR decomposition is to transform the data
into a domain where the inversion is done with a triangular matrix.



< MATLAB Documentation >
[Q,R] = qr(A) performs a QR decomposition on m-by-n matrix A such that A = Q*R.
The factor R is an m-by-n upper-triangular matrix, and the factor Q is an
m-by-m orthogonal matrix.
[___] = qr(A,0) produces an economy-size decomposition using any of the
previous output argument combinations. The size of the outputs depends on the
size of m-by-n matrix A:

If m > n, then qr computes only the first n columns of Q and the first n rows of R.

If m <= n, then the economy-size decomposition is the same as the regular decomposition.

If you specify a third output with the economy-size decomposition, then it is
returned as a permutation vector such that A(:,P) = Q*R.
< /MATLAB Documentation >

Matlab's reference to the "economy" rerpresentation is what Trefethen and Bau
call the "reduced QR factorization".  Golub & Van Loan (1996, §5.2) call Q1R1
the thin QR factorization of A;

There are sevearl discussions online about the differences in
numpy, scipy, sklearn, skcuda etc.
https://mail.python.org/pipermail/numpy-discussion/2012-November/064485.html
We will default to using numpy for now.
Note that numpy's default is to use the "reduced" form of Q, R.  R is
upper-right triangular.

This is cute:
https://stackoverflow.com/questions/26932461/conjugate-transpose-operator-h-in-numpy

THe Matlab mldivide flowchart can be found here:
https://stackoverflow.com/questions/18553210/how-to-implement-matlabs-mldivide-a-k-a-the-backslash-operator
And the matlab documentation here
http://matlab.izmiran.ru/help/techdoc/ref/mldivide.html
"""
import numpy as np
from scipy.linalg import solve_triangular

from iris_mt_scratch.sandbox.transfer_function.TRegression import \
    RegressionEstimator

class TRME(RegressionEstimator):

    def __init__(self, **kwargs):
        super(TRME, self).__init__(**kwargs)


    @property
    def r0(self):
        return self.iter_control.r0

    @property
    def u0(self):
        return self.iter_control.u0

    @property
    def n_data(self):
        return self.Y.shape[0]

    @property
    def correction_factor(self):
        return self.iter_control.correction_factor


    def sigma(self, QHY, Y_or_Yc, cfac=1):
        """
        QHY[i,j] = Q.H * Y[i,j] = <Q[:,i], Y[:,j]>
        So when we sum columns of norm(QHY) we are get in the zeroth position
        <Q[:,0], Y[:,0]> +  <Q[:,1], Y[:,0]>, that is the 0th channel of Y
        projected onto each of the Q-basis vectors


        Computes the difference in the norm of the output channels
        and the output channels inner-product with Q
        Parameters
        ----------
        QHY
        Y_or_Yc
        cfac

        Returns
        -------

        """
        Y2 = np.linalg.norm(Y_or_Yc, axis=0)**2
        QHY2 = np.linalg.norm(QHY, axis=0)**2
        sigma = cfac * (Y2 - QHY2) / self.n_data;
        return sigma

    def solve_overdetermined(self):
        """
        Overdetermined problem...use svd to invert, return
        NOTE: the solution IS non - unique... and by itself RME is not setup
        to do anything sensible to resolve the non - uniqueness(no prior info
        is passed!).  This is stop-gap, to prevent errors when using RME as
        part of some other estimation scheme!

        We basically never get here and when we do we dont trust the results
        https://docs.scipy.org/doc/numpy-1.9.2/reference/generated/numpy.linalg.svd.html
        https://www.mathworks.com/help/matlab/ref/double.svd.html
        Returns
        -------

        """
        print("STILL NEEDS TO BE TRANSLATED")
        U, s, V = np.linalg.svd(self.X, full_matrices=False)
        #[u, s, v] = svd(self.X, 'econ');
        sInv = 1. / diag(s);
        self.b = v * diag(sInv) * u.T * self.Y;
        if self.iter_control.return_covariance:
            self.noise_covariance = np.zeros(self.n_channels_out,
                                             self.n_channels_out);
            self.inverse_signal_covariance = np.zeros(self.n_param,
                                                      self.n_param);

        return self.b

    def huber_weights(self, sigma, YP):
        """
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [YC,E_psiPrime] = HuberWt(Y,YP,sig,r0)

        inputs are data (Y) and predicted (YP), estiamted
        error variances (for each column) and Huber parameter r0
        allows for multiple columns of data
        """
        K = self.n_channels_out
        YC = self.Y.copy() #may need copy here to leave Y as it is ... maybe not
        E_psiPrime = np.zeros((self.n_channels_out,1))
        for k in range(self.n_channels_out):
            r0s = self.r0 * np.sqrt(sigma[k])
            residuals = np.abs(self.Y[:, k] - YP[:, k])
            w = np.minimum(r0s/residuals, 1.0)
            YC[:, k] = w * self.Y[:, k] + (1 - w) * YP[:, k]
            E_psiPrime[k] = 1.0 * np.sum(w == 1) / self.n_data;
        self.Yc = YC
        return E_psiPrime

    def estimate(self):
        """
        function that does the actual regression - M estimate

        Usage: [b] = Estimate(obj);
        (Object has all outputs; estimate of coefficients is also returned
        as function output)

        # note that ITER is a handle object, so mods to ITER properties are
        # already made also to obj.ITER!
        Returns
        -------

        """
        #<CHECK IF SYSTEM OVERDETERMINED>
        if self.is_overdetermined:
            b0 = self.solve_overdetermined()
            return b0

        # < QR decomposition of design matix>
        [Q, R] = np.linalg.qr(self.X)
        if np.isclose(np.matmul(Q, R) - self.X, 0).all():
            pass
        else:
            print("Failed QR decompostion sanity check")
            raise Exception
        # initial LS estimate b0, error variances sigma
        QHY = np.matmul(np.conj(Q.T), self.Y)
        print("MLDIVIDE")
        print("MLDIVIDE")
        b0 = solve_triangular(R, QHY)

        sigma = self.sigma(QHY, self.Y)
        #array([2049740.38627989, 228567.81051429])
        if self.iter_control.max_number_of_iterations > 0:
            converged = False;
            #cfac = self.iter_control.correction_factor
        else:
            converged = True
            E_psiPrime = 1;
            YP = np.matmul(Q, QHY);#not sure we need this?
            self.b = b0;
            self.Yc = self.Y;

        self.iter_control.number_of_iterations = 0;

        while not converged:
            self.iter_control.number_of_iterations += 1
            YP = np.matmul(Q, QHY) # predicted data
            E_psiPrime = self.huber_weights(sigma, YP)
            #HuberWt(Y, YP, sig, r0)
            # cleaned data
            #updated error variance estimates, computed using cleaned data
            QHYc = np.matmul(Q.T, self.Yc)
            self.b = solve_triangular(R, QHYc) #self.b = R\QTY;
            sigma = self.sigma(QHYc, self.Yc, cfac=self.correction_factor)
            converged = self.iter_control.converged(self.b, b0);
            b0 = self.b;

        if self.iter_control.redescend:
            self.iter_control.number_of_redescending_iterations = 0;
            while self.iter_control.number_of_redescending_iterations <= \
                    self.iter_control.maximum_number_of_redescending_iterations:
                self.iter_control.number_of_redescending_iterations += 1
                # one obj with redescending influence curve
                YP = np.matmul(Q, QTY)
                # cleaned data
                [self.Yc, E_psiPrime] = RedescendWt(self.Y, YP, sigma, ITER.u0);
                # updated error variance estimates, computed using cleaned data
                QTY = np.matmul(Q.T, self.Yc)
                print("MLDIVIDE")
                print("MLDIVIDE")
                #self.b = R\QTY;
                sigma = self.sigma(QTY, self.Yc)
                #sigma = (sum(obj.Yc. * conj(obj.Yc), 1) - sum(QTY. * conj(QTY),
                #                                      1)) / nData;
            # crude estimate of expectation of psi ... accounting for
            # redescending influence curve
            E_psiPrime = 2 * E_psiPrime - 1;

        result = self.b;
        if self.iter_control.return_covariance:
            # compute error covariance matrices
            print("INVINV")
            print("INVINV")
            self.Cov_SS = np.linalg.inv(np.matmul(R.T,R));
            #self.Cov_SS = inv(R'*R);
            res = obj.Yc - YP;
            # need to look at how we should compute adjusted residual cov to
            # make consistent with tranmt
            print("MATMUL")
            print("MATMUL")
            SSRC = np.conj(np.matmul(res.T, res));
            #SSRC = conj(res'*res);
            res = obj.Y-YP;
            print("MATMUL")
            print("MATMUL")
            SSR = np.conj(np.matmul(res.T, res));
            #SSR = conj(res'*res);

            # SSY = real(sum(obj.Y.* conj(obj.Y), 1));
            #SSYC = real(sum(obj.Yc. * conj(obj.Yc), 1)); #ORIGINAL
            print("UGH")
            print("UGH")
            SSYC = real(sum(obj.Yc * np.conj(obj.Yc), 1));
            #obj.Cov_NN = diag(1. / (E_psiPrime. ^ 2)) * SSRC / (nData - nParam);#original
            obj.Cov_NN = diag(1. / (E_psiPrime**2)) * SSRC / (nData-nParam);
            print("UGH")
            print("UGH")
            #obj.R2 = 1-diag(real(SSR))'./SSYC;
            print("UGH")
            print("UGH")
            #obj.R2(obj.R2 < 0) = 0;
            
            
