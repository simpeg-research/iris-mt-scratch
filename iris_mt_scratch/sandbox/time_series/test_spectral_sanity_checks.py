"""
Objective: To get away from programming my own frequency axes etc and start using the
built-in tools in np.fft

The numpy.fft.fft() function returns an N-vector where the frequency axis is organized as follows:
Let Fx = np.fft.fft(x) for some function x(t), which is defined at t=0..(N-1)*dt,

Fx[0] corresponds to the DC component or the mean value of the time series.  It is actually
N * E[x], which is a bit surprising but there are always factors of N, and dt floating around.
Fx[n] = n*df where df is 1/(N*dt).

The zero terms everpresence means that the FFT exhibits a sort of parity.  You either took
the transform of an even or an odd number of points.
In either case we split the frequency axis evenly on a beaded pattern of N,
If the leftovers from the DC have an even number or samples the distnace between beads is te
circumference over N, if N was odd we split the frequency axis in equal disntance to either
side of zero



Frequency axis for a one sided spectrum

When we apply the
"""
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd

from sinusoid import Sinusoid
from iris_mt_scratch.sandbox.poles_and_zeros.test_pole_zero_estimation_arma import test_load_and_plot_response_function
#import scipy.signal as ssig
#from scipy.interpolate import interp1d
#make this an xarray creature


    


def generate_two_sine_waves(f1=1.0, f2=10.0, sps=1000.0, T=100.0, A1=10, A2=2):
    sinusoid_1 = Sinusoid(amplitude=A1, frequency=f1, sps=sps, duration=T)
    sinusoid_2 = Sinusoid(amplitude=A2, frequency=f2, sps=sps, duration=T)
    return sinusoid_1, sinusoid_2

def plot_two_sine_waves(sin1, sin2):
    plt.figure(1)
    plt.plot(sin1.time_vector, sin1.data, color='red', label=sin1.__str__())
    plt.plot(sin2.time_vector, sin2.data, color='orange', label=sin2.__str__())
    plt.legend()
    plt.show()

def main():
    sps = 500.0
    dc_offset = 0#33
    sin1, sin2 = generate_two_sine_waves(sps=sps, T=10)
    #plot_two_sine_waves(sin1, sin2) #sanity check

    sin1_series = sin1.data + dc_offset
    F1 = np.fft.fft(sin1_series)
    F2 = np.fft.fft(sin2.data)

    #<CRUDE FREQUENCY AXIS WORKS FOR ONE SIDED>
    df = sin1.df
    frequencies = df * np.arange(sin1.n_samples)
    plt.figure(2)
    plt.plot(frequencies, np.abs(F1), color='red', label=sin1.__str__())
    plt.plot(frequencies, np.abs(F2), color='orange', label=sin2.__str__())
    plt.legend()
    plt.show()
    #</CRUDE FREQUENCY AXIS WORKS FOR ONE SIDED>

    #<FFT FREQS --  NO SHIFTS>
    """
    The weird thing here is that we have not performed any reordering of F1, F2
    We only reordered the x-axis.  
    """
    frequencies = np.fft.fftfreq(sin1.n_samples, d=sin1.dt)
    plt.figure(3)
    plt.plot(frequencies, np.abs(F1), color='red', label=sin1.__str__())
    plt.plot(frequencies, np.abs(F2), color='orange', label=sin2.__str__())
    plt.title('FFT Freqs, No Shifting Nada')
    plt.figure(4)
    plt.plot(np.abs(F1), color='red', label=sin1.__str__())
    plt.plot(np.abs(F2), color='orange', label=sin2.__str__())
    plt.legend()
    plt.figure(5)
    plt.plot(frequencies, 'b*')
    plt.show()
    #</FFT FREQS --  NO SHIFTS>


    #<>
    """
    """
    frequencies = np.fft.fftfreq(sin1.n_samples, d=sin1.dt)
    frequencies = np.fft.fftshift(frequencies)
    F1 = np.fft.fftshift(F1)
    #F2 = np.fft.fftshift(F2)
    plt.figure(5)
    plt.plot(frequencies, np.abs(F1), color='red', label=sin1.__str__())
    plt.plot(frequencies, np.abs(F2), color='orange', label=sin2.__str__())
    plt.legend()
    plt.show()
    # </>


    print('oi!')


    test_load_and_plot_response_function()
    print('ok')

if __name__ == "__main__":
    main()