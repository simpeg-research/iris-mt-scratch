import numpy as np

class RCCircuit(object):
    def __init__(self, **kwargs):
        self.R = kwargs.get('R', 4.0)
        self.C = kwargs.get('C', 1.25/(2*np.pi)) #0.199 F

    @property
    def tau(self):
        return self.R * self.C

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
        phasee portion of Scherbaum 2.21 (shown as 2.22)
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
        return 1./denominator


    def two_sided_complex_response_function(self):

        pass
