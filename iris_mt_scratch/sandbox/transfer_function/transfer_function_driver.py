"""
Continuation of aurora driver.  I'm too impatient to wait the 6.5 seconds it
takes to load and do tests everytime I want to check TRME

So I saved a band of data and I load that here


        #Z: array([[ 0.43571599-0.06491527j, -0.18934942-0.05807046j],
        #         [-0.21657737+0.07116618j,  0.05219818+0.06366403j]])

        #Z: array([[0.41464914 - 0.09269744j, -0.14563335 - 0.07932368j],
        #       [-0.18650074 + 0.07459541j, 0.03722138 + 0.06684994j]])

        #Z: array([[0.43571599 - 0.06491527j, -0.18934942 - 0.05807046j],
        #       [-0.21657737 + 0.07116618j, 0.05219818 + 0.06366403j]])
"""
from iris_mt_scratch.general_helper_functions import TEST_BAND_FILE
from iris_mt_scratch.general_helper_functions import read_complex, save_complex

from iris_mt_scratch.sandbox.transfer_function.TRegression import RegressionEstimator
from iris_mt_scratch.sandbox.transfer_function.TRME import TRME

MAKE_OVERDETERMINED = False

def test_regression(band_da=None):
    if band_da is None:
        band_da = read_complex(TEST_BAND_FILE)
    band_dataset = band_da.to_dataset("channel")
    X = band_dataset[["hx", "hy"]]
    Y = band_dataset[["ex", "ey"]]
    if MAKE_OVERDETERMINED:
        X = X.isel(time=0)
        Y = Y.isel(time=0)
    regression_estimator = RegressionEstimator(X=X, Y=Y)
    Z = regression_estimator.estimate()
    print(Z)
    regression_estimator = TRME(X=X, Y=Y)
    Z = regression_estimator.estimate()
    print(Z)
    return Z


# def test_regression(band_da=None):
#     if band_da is None:
#         band_da = read_complex(TEST_BAND_FILE)
#     band_dataset = band_da.to_dataset("channel")
#     X = band_dataset[["hx", "hy"]]
#     Y = band_dataset[["ex", "ey"]]
#     if MAKE_OVERDETERMINED:
#         X = X.isel(time=0)
#         Y = Y.isel(time=0)
#     regression_estimator = RegressionEstimator(X=X, Y=Y)
#     Z = regression_estimator.estimate()
#     print(Z)
#     regression_estimator = TRME(X=X, Y=Y)
#     Z = regression_estimator.estimate()
#     return Z

def main():
    test_regression()

if __name__ == '__main__':
    main()






