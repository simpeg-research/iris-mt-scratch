"""
w_rad_per_sample, hh = signal.freqz_zpk(z, p, k)
Returns 512 samples which span frequencies from 0 to pi-dw where dw = pi/512

w_rad_per_sample, hh = signal.freqz_zpk(z, p, k, worN=1024)
Returns 1024 samples which span frequencies from 0 to pi-dw where dw = pi/1024

In these cases we make the frequency axis Hz by multiplying by f_nyquist / pi

w_rad_per_sample, hh = signal.freqz_zpk(z, p, k, whole=True)
Returns 512 samples.  which span frequencies from 0 to 2*pi-dw where dw = pi/256
The first 256 samples are the same output as if you had set worN to 256
The next 256 samples correspond to the frequencies starting at nyquist and counting
down to dc (not including DC) for negative frequencies.
[0, df, 2*df ... 255*df, 256*df 257*df , ... 510*df, 511*df]
Here 511*df ~ -df, 510*df ~-2*df, ... etc
So you would want to split the RHS off, fliplr and append it to the LHS.
This is probably equivalent to fftshift

"""
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal

from rc_circuit import RCCircuit
from obspy.signal.invsim import paz_to_freq_resp
# sampling_rate = 1000.0 #sps in Hz
# f_nyquist = sampling_rate / 2
# z, p, k = signal.butter(4, 100, output='zpk', fs=sampling_rate)
# w, h = signal.freqz_zpk(z, p, k, fs=1000)
#
# w_rad_per_sample, hh = signal.freqz_zpk(z, p, k)
# w_hz = w_rad_per_sample * f_nyquist / np.pi
# w, h = signal.freqz_zpk(z, p, k, whole=True)
# #w = np.fft.fftshift(w)
# h = np.fft.fftshift(h)

rc_ckt = RCCircuit()
zeros = rc_ckt.zeros
poles = rc_ckt.poles
pz_scale_factor = rc_ckt.pz_scale_factor

#What is going wrong here?  In the scipy example, the poles and zeros of the Butterworth
#filter take a sampling rate as an input, and that sampling rate is fed into the freqz_zpk
#this is some sort of a z-transform thing that depends on the sampling rate ...
#but in my case we do not depend on the sampling rate, the solution is analytic
#
#The thing is that I get the same values for h, no matter what the w is, which is incorrect
#So I think it is because this is a z-transform method and not a Laplace transform method
#w, h = signal.freqz_zpk(zeros, poles, 1.0, fs=1000.0)

#<ZPK>
frequencies = np.logspace(-3, 1, 200)
frequencies = np.hstack(([0], frequencies))
angular_frequencies = 2*np.pi*frequencies
w, h = signal.freqs_zpk(zeros, poles, 1./rc_ckt.tau, worN=angular_frequencies)
#</ZPK>

#<RC>
cr = rc_ckt.complex_response(frequencies)
cr_scale_factor = 1.0#rc_ckt.tau
#</RC>

#<OBSPY>
scale_fac = 1./rc_ckt.tau
h_obspy, f_obspy = paz_to_freq_resp(poles, zeros, scale_fac, 0.005, 16384, freq=True)
#</OBSPY>

plt.plot(frequencies, np.abs(h), '*', label='zpk')
plt.plot(frequencies, cr_scale_factor*np.abs(cr), 'r', label='freqresp')
plt.plot(f_obspy, np.abs(h_obspy), 'k', label='obspy')
plt.legend()
plt.grid()
plt.show()
import matplotlib.pyplot as plt
fig = plt.figure()
ax1 = fig.add_subplot(1, 1, 1)
ax1.set_title('Digital filter frequency response')

ax1.plot(w, 20 * np.log10(abs(h)), 'b')
#ax1.plot(w_hz, 20 * np.log10(abs(hh)), 'b*')
ax1.set_ylabel('Amplitude [dB]', color='b')
ax1.set_xlabel('Frequency [Hz]')
ax1.grid()

ax2 = ax1.twinx()
angles = np.unwrap(np.angle(h))
ax2.plot(w, angles, 'g')
ax2.set_ylabel('Angle [radians]', color='g')

plt.axis('tight')
plt.show()