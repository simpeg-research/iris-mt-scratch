"""
The underlying idea of this script is to try to generate a pole-zero fitting algorithm
for a given instrument response.  The general idea is as follows:

Say you are given (or can calculate) a frequency response function such as from
a Frequency-Amplitude-Phase table.  Then you can generate a noise process that behaves
like the instrument response by convolving white noise with the instrument response.

If the instrument response is not available you should be able to calculate it as the
FFT of the frequency response function, but here is another way:

1. Make a white noise process (using random.rand, random.randn)
Note that you need to associate a sampling rate with this noise and you should probably
apply an AAF to it.
2. FFT your noise and multiply it against the two-sided response function
(Mirror the amplitude response about the Y-axis, and rotate your phase
response about y=x so that PHI(-f) = -PHI(f)
3. Take the spectral product
4. Inverse FFT the "coloured noise".
5. Apply an ARMA model to fit the noise.

It would seem important to make sure that the frequency content of the the white noise time series has
good coverage in the frequency band where the poles and zeros are "active".  In the case of Scherbaum 1997
RC circuit example from chapeter 2 the interesting region is between DC and 10Hz.
See Also, lets make a time series that has, say 10000 frequencies in the region 0, 25Hz.
Let the Nyquist frequency be 25Hz, so that the sampling frequency is 50Hz.


"""
import matplotlib.pyplot as plt
import numpy as np
import os
import pandas as pd

import scipy.signal as ssig
from scipy.interpolate import interp1d

import statsmodels.api as sm
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.arima_model import ARMA

from iris_mt_scratch.sandbox.plot_helpers import plot_complex_response
from iris_mt_scratch.sandbox.poles_and_zeros.rc_circuit import RCCircuit
from time_series import TimeSeries
xcomplex = ssig.iirfilter
class WhiteNoise(TimeSeries):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.amplitude = kwargs.get('amplitude', 1.0)
        self.generate_time_series()


    def generate_time_series(self):
        data = np.random.randn(self.n_samples)
        #data = np.random.rand(self.n_samples)
        data = data - np.mean(data)
        self.data = data
        return data

    def __str__(self):
        description = 'white noise '.format(self.frequency)
        return description

def interpolate_function(x, y, log_scale, interp_kind):

    if log_scale:
        interp_function = interp1d(np.log(x), np.log(y), kind=interp_kind,
                                 bounds_error=False, fill_value='extrapolate')
        interpolator = lambda f: np.exp(interp_function(np.log(np.abs(f))))
    else:
        interp_function = interp1d(x, y, kind=interp_kind,
                                 bounds_error=False, fill_value='extrapolate')
        interpolator = lambda f: interp_function(np.abs(f))
    return interpolator



def test_load_and_plot_response_function():
    resources_path = '/home/kkappler/software/quakefinder/analysis_super/analysis/resources/calibration/emi/bf4'
    bf4_file = os.path.join(resources_path, '9819_0_0.csv')
    df = pd.read_csv(bf4_file)
    j = np.complex(0, 1.0)

    frequencies = df['Frequency [Hz]'].to_numpy()
    ampl = df['Amplitude [V/nT]']
    phase_degrees = df['Phase [degrees]'].to_numpy()
    phase_radians = np.pi * phase_degrees / 180.

    ampl = ampl.to_numpy()

    complex_response = ampl * np.exp(j*phase_radians)
    plot_complex_response(frequencies, complex_response)
    #plt.show()

def create_RC_circuit_response(frequencies, show=False):#R=None, C=None):
    """
    Following Scherbaum chapter 2 model the response of a simple RC voltage divider, with the
    output being the voltage measured across the capacitor.  The frequency response is thought of
    as T(jw) in order to make a simple substitution for s=jw in Laplace domain.
    :param R:
    :param C:
    :return:
    """
    rc_circuit = RCCircuit()
    complex_response = rc_circuit.complex_response(frequencies)
    if show:
        plot_complex_response(frequencies, complex_response)
    return complex_response

def generate_white_noise_process_from_response_function(sampling_rate, n_points):
    dt = 1./sampling_rate
    noise = np.random.randn(n_points)
    #noise = ssig.decimate()
    fft_noise = np.fft.fft(noise)

    pass

def fit_arma_to_white_noise(time_series, ar_order, ma_order):
    pass



def main():


    sampling_rate = 500.0; dt = 1./sampling_rate;
    n_samples = 100001
    duration = n_samples / sampling_rate
    wn = WhiteNoise(sps=sampling_rate, duration=duration)
    frequencies = wn.frequency_axis()
    rc_circut = RCCircuit()
    complex_response = rc_circut.complex_response(frequencies)
    #complex_response = complex_response * rc_circut.pz_scale_factor
    F_wn = wn.fft()
    coloured_spectrum = F_wn * complex_response
    plt.plot(np.fft.fftshift(frequencies), np.fft.fftshift(np.abs(coloured_spectrum)))

    arma_process_series = np.real(np.fft.ifft(coloured_spectrum))
    # plt.plot(frequencies, np.abs(np.fft.fft(arma_process_series)))
    # plt.show()
    # plt.plot(wn.data, 'k', label='white noise')
    # plt.plot(arma_process_series, 'r', label='arma')
    # plt.legend()
    # plt.show()
    rho, sigma = sm.regression.yule_walker(arma_process_series, order=1)#, method = "mle")
    print('rho', rho)
    print('sigma', rho)

    #rho is the pole
    a = np.array([1,  rho]) #denominator coefficients
    b = np.array([1])# numerator coefficients (zeros)
    wn2 = ssig.lfilter(b, a, arma_process_series)

    plt.plot(np.fft.fftshift(frequencies), np.fft.fftshift(np.abs(np.fft.fft(wn2))))
    plt.show()

    # model = ARIMA(arma_process_series, order=(1,0,0))
    # model_fit = model.fit()
    # print(model_fit.summary())
    #
    # model = ARMA(arma_process_series, (1, 0))
    # model_fit = model.fit()
    # print(model_fit.summary())
    # #at this point we are going to need an interpolation function that returns the complex
    # #response.
    # #we could presumably interpolate the complex valued function if we use linear interpolation
    # #but if we want to interpolate in log space we probably need to work the amplitude and phase
    # #separately
    # #generate_white_noise_process_from_response_function(sampling_rate, n_samples, )
    # df = 1./(n_samples * dt)
    # non_negative_frequencies = df * np.arange((n_samples+1)/2)
    # negative_frequencies = -np.flipud(non_negative_frequencies[1:])
    # frequencies = np.hstack((negative_frequencies, non_negative_frequencies))
    # noise = np.random.randn(n_samples)
    # fft_noise = np.fft.fft(noise)
    # frequencies_2 = np.fft.fftfreq(n_samples, d=1./sampling_rate)
    #
    #
    # tt, sine = generate_two_sine_waves(sps=sampling_rate, T=n_samples*dt)
    # fft_sig = np.fft.fft(sine)
    # ff = np.fft.fftfreq(len(tt), d=1./sampling_rate)
    # #plt.plot(np.abs(fft_sig))
    # plt.plot(frequencies, np.abs(fft_sig))
    # #plt.plot(ff, np.abs(fft_sig))
    # plt.xlabel('Frequency (Hz)')
    # print('oi!')
    #
    #
    # test_load_and_plot_response_function()
    print('ok')

if __name__ == "__main__":
    main()
