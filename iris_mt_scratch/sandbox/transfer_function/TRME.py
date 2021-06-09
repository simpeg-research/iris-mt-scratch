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
"""
import numpy as np

from TRegression import RegressionEstimator

class TRME(RegressionEstimator):

    def __init__(self, **kwargs):
        super(TRME, self).__init__(**kwargs)

    #def TRME(self, X, Y, iter):

    @property
    def r0(self):
        return self.iter_control.r0

    @property
    def u0(self):
        return self.iter_control.u0

    @property
    def n_data(self):
        return self.Y.shape[0]

    def sigma(self, QTY, Y_or_Yc, cfac=1):
        YY = np.abs(Y_or_Yc)**2
        QTYQTY = np.abs(QTY)**2
        sigma = cfac * np.real(sum(YY, 1) - sum(QTYQTY, 1)) / self.n_data;
        return sigma

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
        #ITER = self.ITER;

        # Q - R decomposition of design matix
        n_data, K = self.Y.shape
        n_X, n_param = self.X.shape

        if n_X != n_data:
            print('data (Y) and design matrix (X) must have same number of '
                  'rows')

        if n_param > n_data:
            # overdetermined problem...use svd to invert, return
            # NOTE: the solution IS non - unique... and by itself RME is not set
            # up to do anything sensible to resolve the non - uniqueness(no
            # prior info is passed!).  This is stop - gap, to prevent errors
            # when using RME as part of some other estimation scheme!
            [u, s, v] = svd(self.X, 'econ');
            sInv = 1. / diag(s);
            self.b = v * diag(sInv) * u.T *self.Y;
            if self.iter_control.return_covariance:
                self.Cov_NN = zeros(K, K);
                self.Cov_SS = zeros(nParam, nParam);

            return self.b

        [Q, R] = qr(self.X, 0);
        # initial LS estimate b0, error variances sigma
        QTY = np.matmul(Q.T, self.Y)
        b0 = R\QTY;

        sigma = self.sigma(QTY, self.Y)

        if self.iter_control.max_number_of_iterations > 0:
            converged = False;
            #the problem is in the regression esimtate you downwaeight
            #things with large errors, but you need to define what's large
            #you estimate the standard devation of the errors from the residuals
            #BUT with this cleaned data approach (Yc) sigma is smaller than it
            #should be, you need to compensate for this by using a
            #correction_factor
            #its basically the expectation, if the data really were
            #gaussian, and you you estimated from the corrected data
            #this is how much too small the estiamte would be.
            cfac = 1. / (2 * (1. - (1. + self.r0) * exp(-self.r0)));
            #if you change the penalty functional you may need the pencil and
            #some calculus.
            #the relationship between the corrected-data-residuals and the
            # gaussin residauls could change if you change the penalty
            #
        else:
            converged = True
            E_psiPrime = 1;
            YP = np.matmul(Q, QTY);
            self.b = b0;
            self.Yc = obj.Y;

        self.iter_control.number_of_iterations = 0;

        while not converged:
            self.iter_control.number_of_iterations += 1
            # predicted data
            YP = Q * QTY;
            # cleaned data
            [self.Yc, E_psiPrime] = HuberWt(self.Y, YP, sigma, self.r0);
            #updated error variance estimates, computed using cleaned data
            QTY = np.matmul(Q.T, self.Yc)
            self.b = R\QTY;

            sigma = self.sigma(QTY,self.Yc, cfac=cfac)
            # YcYc = np.abs(self.Yc)**2
            # QTYQTY = np.abs(QTY) ** 2
            # sigma = cfac * (sum(YcYc, 1) - sum(QTYQTY, 1)) / nData
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
                self.b = R\QTY;
                sigma = self.sigma(QTY, self.Yc)
                #sigma = (sum(obj.Yc. * conj(obj.Yc), 1) - sum(QTY. * conj(QTY),
                #                                      1)) / nData;
            # crude estimate of expectation of psi ... accounting for
            # redescending influence curve
            E_psiPrime = 2 * E_psiPrime - 1;

        result = obj.b;
        if self.iter_control.return_covariance:
            # compute error covariance matrices
            self.Cov_SS = inv(R'*R);
            res = obj.Yc - YP;
            # need to look at how we should compute adjusted residual cov to
            # make consistent with tranmt
            SSRC = conj(res'*res);
            res = obj.Y-YP;
            SSR = conj(res'*res);
            # SSY = real(sum(obj.Y.* conj(obj.Y), 1));
            SSYC = real(sum(obj.Yc.* conj(obj.Yc), 1));
            obj.Cov_NN = diag(1. / (E_psiPrime.^ 2)) * SSRC / (nData-nParam);

            obj.R2 = 1-diag(real(SSR))'./SSYC;
            obj.R2(obj.R2 < 0) = 0;