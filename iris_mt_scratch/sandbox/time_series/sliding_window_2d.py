"""
Notes in google doc:
https://docs.google.com/document/d/1CsRhSLXsRG8HQxM4lKNqVj-V9KA9iUQAvCOtouVzFs0/edit?usp=sharing
"""
# Purpose of this function is to execute sliding window on a 2D array.
#note that we may actually wish to support sliding window on multiple 1D arrays instead
#and use parallelization to speed this up ...

#the best answer is not obvious
#import numba
import numpy as np
from numpy.lib.stride_tricks import as_strided
import time
from numba import jit

from windowing_scheme_aurora import WindowingScheme




def sliding_window_crude(data, num_samples_window, num_samples_advance, num_windows=None):
    """

    Parameters
    ----------
    data
    num_samples_window
    num_samples_advance
    num_windows

    Returns
    -------

    """
    if num_windows is None:
        #Take this from windowing_scheme
        num_windows = int(np.floor((len(data)-num_samples_window)/num_samples_advance))+1
        print("num_windows", num_windows)
    output_array = np.full((num_windows, num_samples_window), np.nan)
    for i in range(num_windows):
        output_array[i, :] = data[i*num_samples_advance:i*num_samples_advance+num_samples_window]

    return output_array

# x = np.arange(100).reshape(10, 10)
#
# @jit(nopython=True) # Set "nopython" mode for best performance, equivalent to @njit
# def go_fast(a): # Function is compiled to machine code when called the first time
#     trace = 0.0
#     for i in range(a.shape[0]):   # Numba likes loops
#         trace += np.tanh(a[i, i]) # Numba likes NumPy functions
#     return a + trace              # Numba likes NumPy broadcasting
#
# print(go_fast(x))

@jit
def sliding_window_numba(data, num_samples_window, num_samples_advance, num_windows):
    """

    Parameters
    ----------
    data
    num_samples_window
    num_samples_advance
    num_windows

    Returns
    -------

    """
    output_array = np.full((num_windows, num_samples_window), np.nan)
    for i in range(num_windows):
        output_array[i, :] = data[i*num_samples_advance:i*num_samples_advance+num_samples_window]

    return output_array

def striding_window(data, num_samples_window, num_samples_advance, num_windows=None):
    """ applies a striding window to an array.  We use 1D arrays here.
    Note that this method is extendable to N-dimensional arrays as was once shown
    at  http://www.johnvinyard.com/blog/?p=268

    Karl has an implementation of this code but chose to restict to 1D here. This is becuase of several
    Warnings encountered, on the notes of stride_tricks.py, as well as for example here:
    https://stackoverflow.com/questions/4936620/using-strides-for-an-efficient-moving-average-filter

    While we can possible setup Aurora so that no copies of the strided windoe are made downstream,
    we cannot guarantee that another user may not add methods that do require copies.  For robustness
    we will use 1d implementation only for now.  Adding 2d is experimental.

    result is 2d: result[i] is the i-th window

    >>> sliding_window(np.arange(15), 4, 3, 2)
    array([[0, 1, 2],
           [2, 3, 4],
           [4, 5, 6],
           [6, 7, 8]])

    """
    print("num_samples_advance", num_samples_advance)
    if num_windows is None:
        #Take this from windowing_scheme
        num_windows = int(np.floor((len(data)-num_samples_window)/num_samples_advance))+1
        print("num_windows", num_windows)
    min_ = (num_windows - 1) * num_samples_advance + num_samples_window
    assert len(data) >= min_, "array is too small (min=%d)" % min_
    bytes_per_element = data.itemsize
    output_shape = (num_windows, num_samples_window)
    print("output_shape", output_shape)
    strides_shape = (num_samples_advance*bytes_per_element, bytes_per_element)
    #strides_shape = None
    print("strides_shape", strides_shape)
    strided_window = as_strided(data, shape=output_shape,
                                strides=strides_shape)#, writeable=False)
    return strided_window


N = 10000000
n_samples_window = 128; n_overlap = 96; n_advance = n_samples_window-n_overlap;
#qq = np.random.random(N)
qq = np.arange(N)
windowing_scheme = WindowingScheme(num_samples_window=n_samples_window, num_samples_overlap=n_overlap)
print(windowing_scheme.num_samples_advance)
print(windowing_scheme.available_number_of_windows(N))
# print(qq.shape)
# qq = np.atleast_2d(qq)
# print(qq.shape)
sw = striding_window(np.arange(15), 3, 2, num_windows=4)
print(sw)

t0 = time.time()
strided_window = striding_window(1.*np.arange(N), n_samples_window, n_advance)#, num_windows=4)
strided_window+=1
print("stride {}".format(time.time()-t0))

print(strided_window)

t0 = time.time()
slid_window = sliding_window_crude(1.*np.arange(N),n_samples_window, n_advance)#, num_windows=4)
slid_window+=1
print("crude  {}".format(time.time()-t0))

print(slid_window)

num_windows = windowing_scheme.available_number_of_windows(N)
print(num_windows)
t0 = time.time()
numba_slid_window = sliding_window_numba(1.*np.arange(N),n_samples_window, n_advance,
                           num_windows)#, num_windows=4)
numba_slid_window+=1
print("numba  {}".format(time.time()-t0))

t0 = time.time()
numba_slid_window = sliding_window_numba(1.*np.arange(N),n_samples_window, n_advance,
                           num_windows)#, num_windows=4)
print("numba  {}".format(time.time()-t0))
#sw0 = sliding_window(qq, n_samples_window, n_overlap, num_windows=windowing_scheme.available_number_of_windows(len(qq)))
sw = sliding_window(qq, n_samples_window, n_overlap)


print("dogs")

