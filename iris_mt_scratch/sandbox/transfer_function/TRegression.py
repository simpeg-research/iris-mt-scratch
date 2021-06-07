"""
follows Gary's TRegression.m in
iris_mt_scratch/egbert_codes-20210121T193218Z-001/egbert_codes/matlabPrototype_10-13-20/TF/classes

2009 Maxim Smirnov, Gary Egbert
Oregon State University

Abstract class to handle regression esimators
Y = Xb + epsilon

Usage: b = obj.Estimate;

(Complex) regression-M estimate for the model  Y = X*b

Allows multiple columns of Y, but estimates b for each column separately

Iter is a structure which controls the robust scheme
Fields: r0, RG.nITmax, tol (rdcndwt ... not coded yet)
On return also contains number of iterations

Cov_SS and Cov_NN are estimated signal and noise covariance matrices, which
together can be used to compute error covariance for the matrix of regression
coefficients b
R2 is squared coherence (top row is using raw data, bottom cleaned, with crude
correction for amount of downweighted data)

properties
  X; % predictors
  Y; % predicted variables
  b; % parameters to be estimated
  Cov_SS; % inverse signal covariance
  Cov_NN; % noise covariance
  R2;
  Yc; % array of cleaned data
  ITER;
end

 methods (Abstract)

    result = Estimate(obj)

 end %methods


%methods

% function   result = SetParameters(Parameters);
% end;
%
% function RG = TRegression(X,Y);
%   RG.X = X;
%   RG.Y = Y;
%   RG.Regression;
% end;
%
%end;%methods

end %class


"""

from iter_control import IterControl

class RegressionEstimator(object):

    def __init__(self, **kwargs):
        self.X = kwargs.get("X", None)
        self.Y = None # predicted variables
        self.b = None # parameters to be estimated
        self.inverse_signal_covariance = None #Cov_SS
        self.noise_covariance = None  #Cov_NN
        self.squared_coherence = None # R2
        self.Yc = None # cleaned data
        self.iter_control = kwargs.get("iter_control", IterControl())


    def estimate(self):
        print("this method is not defined for the abstract base class")
        return None


