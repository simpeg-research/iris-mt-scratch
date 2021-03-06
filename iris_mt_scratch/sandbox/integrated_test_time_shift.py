#Script to confirm that the implementation of the frequency domain time shift is correct.
#This can be modified to import the spectral time shift method from mt_metadata delay filter
#to validate that method.

import matplotlib.pyplot as plt
import numpy as np
np.random.seed(1)

plt.ion()

def is_odd(integer):
    if np.mod(integer,2)==1:
        return True
    elif np.mod(integer,2)==0:
        return False
    else:
        print('maybe you didnt provide an integer?')
        raise Exception

def is_even(integer):
    return ~is_odd(integer)


def spectral_time_shift(data_series, shift, sampling_rate):
    """
    Parameters
    ----------
    data_series
    shift  : how much to shift the time series [seconds]
    sampling_rate

    Returns
    -------

    """
    n_samples = len(data_series)
    spectrum = np.fft.fft(data_series)
    frequencies = np.fft.fftfreq(n_samples, d=1./sampling_rate)
    shift_multiplier = np.exp(-1.j * 2 * np.pi * frequencies * shift)
    shifted_spectrum = shift_multiplier * spectrum
    shifted_data = np.real(np.fft.ifft(shifted_spectrum))
    return shifted_data



def test_time_shift():
    n_samples = 1001
    data = np.zeros(n_samples)
    sampling_rate = 50.0 #sps
    dt = 1./sampling_rate
    if is_odd(n_samples):
        small_half = int((n_samples-1)/2)
        large_half = small_half + 1
        time_axis = dt*(np.arange(n_samples)-small_half)
        signal = np.random.random(large_half)
        data[small_half:] = signal
        tau = 2.0
        envelope = np.exp(-time_axis/tau)
        data = data*envelope
        shift = 0.2#s
        shifted_data = spectral_time_shift(data, shift, sampling_rate)
        plt.plot(time_axis, data, 'b', label='original')
        plt.plot(time_axis, shifted_data, 'r', label='shifted')
        plt.legend()
        plt.show()



if __name__ == '__main__':
    test_time_shift()
    print('ok')
