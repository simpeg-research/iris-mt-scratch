import matplotlib.pyplot as plt
import numpy as np
import scipy.signal as signal

from plot_helpers import plot_complex_response

j = np.complex(0.0, 1.0)

class RCCircuit(object):
    """
    This is a generic class but I am seeding it with the R, C values from the worked example
    in Scherbaum Chapter 2.
    """
    def __init__(self, **kwargs):
        self.R = kwargs.get('R', 4.0)
        self.C = kwargs.get('C', 1.25/(2*np.pi)) #0.199 F

    @property
    def tau(self):
        return self.R * self.C

    @property
    def poles(self):
        """
        the pole is located at s=-1/tau
        Note the pole is real-valued and there
    	is no solution if s=jw (Fourier transform),
    	since if there were it would imply
        jw = -1/tau making tau complex (and it isn't)
        Returns
        -------

        """
        return [-1. / self.tau, ]

    @property
    def zeros(self):
        return []

    @property
    def pz_scale_factor(self):
        """
        This is needed to reconcile the pole-zero evaluation which is cast in terms
        of monic monomials and the frequency response function.
        Returns
        -------

        """
        return 1. / self.tau

    def frequency_response_from_zpk(self, f):
        """
        ToDo: confirm w is same in each step here:
        Parameters
        ----------
        f: frequencies in Hz

        Returns
        -------

        """
        w = 2 * np.pi * f #angular_frequencies
        w, h = signal.freqs_zpk(self.zeros, self.poles, self.pz_scale_factor, worN=w)
        return h

    def amplitude_response(self, f):
        """
        amplitude portion of Scherbaum 2.21
        :param f:
        :return:
        """
        w = 2 * np.pi * f
        denominator = np.sqrt(1.0 + (self.tau * w)**2)
        return 1./denominator

    def phase_response(self, f):
        """
        phase portion of Scherbaum 2.21 (shown as 2.22)
        :param f:
        :return:
        """
        w = 2 * np.pi * f
        return -np.arctan(w*self.tau)

    def complex_response(self, f):
        """
        Here we use Equation 2.19 (rather than the product of amplitude and phase.  This to
        confirm there is no atan / atan2 issues
        :param f:
        :return:
        """
        w = 2 * np.pi * f
        j = np.complex(0, 1.0)
        denominator = self.tau * j * w + 1
        #<alternative factorization, yields same result>
        #     denominator = (1./self.tau) + j * w
        #     scale_factor = 1./self.tau
        #</alternative factorization, yields same result>
        return 1./denominator


    def two_sided_complex_response_function(self):
        pass

    def evaluate_transfer_function(self, s):
        """
        s: point(s) in the complex plane
        T(s) = Y(s)/X(s) = 1/(1+sRC) = 1/(1+s*tau)
        In s-polyland this 1/(1+as) or 1/(1+ax) ...
        There aren't any zeros and there is a pole at s=-1/a
        Parameters
        ----------
        s

        Returns
        -------

        """
        #can we give a value to tau here as a variable? its being used in two different ways
        #s = jw
        tau = self.tau
        #s = s*np.complex(0, 1)
        #function = lambda s,tau: 1/(1+tau*s)
        #return function(s, tau)
        tf = 1./ (1 + s*self.tau)
        return tf





def test_rc_circuit():
    rc_circut = RCCircuit()
    frequencies = np.logspace(-3, 1, 200)
    frequencies = np.hstack(([0], frequencies))
    s = j * 2 * np.pi * frequencies  # laplace variable from frequency axis s--> jw

    cr_zpk = rc_circut.frequency_response_from_zpk(frequencies)
    cr_standard = rc_circut.complex_response(frequencies)
    tf = rc_circut.evaluate_transfer_function(s)
    plot_complex_response(frequencies, cr_zpk)
    plot_complex_response(frequencies, cr_standard)
    plot_complex_response(frequencies, tf)
    #OK, so the complex response looks as expected
    print('ok')

def test_rc_circuit_two_sided():
    rc_circut = RCCircuit()
    sampling_rate = 20; dt = 1./sampling_rate
    frequencies = np.fft.fftfreq(1000, d=dt)
    frequencies = np.fft.fftshift(frequencies)
    s = j * 2 * np.pi * frequencies  # laplace variable from frequency axis s--> jw

    cr_zpk = rc_circut.frequency_response_from_zpk(frequencies)
    cr_standard = rc_circut.complex_response(frequencies)
    tf = rc_circut.evaluate_transfer_function(s)
    plt.plot(frequencies, np.abs(cr_zpk)); plt.show()
    print('ok')

def main():
    #test_rc_circuit()
    test_rc_circuit_two_sided()

if __name__ == "__main__":
    main()
