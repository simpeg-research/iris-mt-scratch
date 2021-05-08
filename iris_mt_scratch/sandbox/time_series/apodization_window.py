"""
Based loosely on TaperModule() concept developed by kkappler in 2012, this is
a leaner version intended to support most apodization windows available via
scipy.signal.get_window()


    Supported Window types = ['boxcar', 'triang', 'blackman', 'hamming', 'hann',
      'bartlett', 'flattop', 'parzen', 'bohman', 'blackmanharris',
      'nuttall', 'barthann', 'kaiser', 'gaussian', 'general_gaussian',
      'slepian', 'chebwin']

    have_additional_args = {
      'kaiser' : 'beta',
      'gaussian' : 'std',
      'general_gaussian' : ('power', 'width'),
      'slepian' : 'width',
      'chebwin' : 'attenuation'
    }



"""

import numpy as np
import scipy.signal as ssig



class ApodizationWindow():
    """
    usage: apod_window = ApodizationWindow()
    @type family: string
    @ivar family: Specify the taper type - boxcar, kaiser, hanning, etc
    @type length: Integer
    @ivar length: The length of taper
    @type taper: numpy array
    @ivar taper: The actual taper window itself
    @type coherentGain: float
    @ivar coherentGain:
    @type NENBW: float
    @ivar NENBW: normalized equivalent noise bandwidth
    @type S1: float
    @ivar S1: window sum
    @type S2: float
    @ivar S2: sum of squares of taper elements

    @author: kkappler
    @note: example usage:
        tpr=ApodizationWindow(family='hanning', length=55 )

    Window factors S1, S2, CG, ENBW are modelled after Heinzel et al. p12-14
    [1] Spectrum and spectral density estimation by the Discrete Fourier transform
    (DFT), including a comprehensive list of window functions and some new
    flat-top windows.  G. Heinzel, A. Roudiger and R. Schilling, Max-Planck
    Institut fur Gravitationsphysik (Albert-Einstein-Institut)
    Teilinstitut Hannover February 15, 2002

    Handles case of user-defined taper being assigned in cond
    Instantiate an apodization window object.
    """
    def __init__(self, **kwargs):
        """

        Parameters
        ----------
        kwargs
        """
        self.family = kwargs.get('family', '')
        self.length = kwargs.get('length', -1)
        self.taper = kwargs.get('array', None)
        self.additional_parameters = kwargs.get('additional_parameters', None)
        self.coherent_gain = None
        self.NENBW = None
        self.S1 = None
        self.S2 = None
        self._apodization_factor = None

        #here are some conditions for making taper
        condition_1 = len(self.family) != 0
        condition_2 = self.length != -1
        condition_3 = self.taper is None

        if (condition_1 and condition_2 and condition_3):
            self.make()
        elif (not condition_3):
            # user defined taper.
            logger.info("user defined taper being initiated")
            if (self.length == -1):
                self.length = len(self.taper)
            if (self.family == ''):
                self.family = 'user-defined'


    def __str__(self):
        """
        Returns a string comprised of the family, length, and True/False
        if self.taper is not None
        @rtype: str
        """
        return f"{self.family} {self.length} {bool(self.taper)}"


    def make(self):
        """

        @note: see scipy.signal.get_window for a description of what is
        expected in args[1:]. http://docs.scipy.org/doc/scipy/reference/
        generated/scipy.signal.get_window.html
        """
        if self.family == 'slepian':
            logger.error("This is not yet supported but exists in karl/unstable")
            raise Exception
            self.taper = slepian(self.length)
        else:
            self.taper = ssig.get_window(self.family, self.length)
        #self.calc_apodization_factor()

        return


    def custom_make(self, window_coefficients, **kwargs):
        self.family = kwargs.get('label', None)
        self.taper = window_coefficients
        self.length = len(window_coefficients)
        #self.calc_apodization_factor()
        return

    @property
    def calc_apodization_factor(self):
        self.S1 = sum(self.taper)
        self.S2 = sum(self.taper**2);
        self.nenbw = self.coherent_gain = 0.0
        if (self.length != 0):
            self.coherent_gain = self.S1/self.length
        if (self.S1 != 0):
            self.nenbw = self.length*self.S2/(self.S1**2)
        if (self.nenbw is not None) and (self.coherent_gain is not None):
            self._apodization_factor = np.sqrt(self.nenbw)*self.coherent_gain
        return

    @property
    def apodization_factor(self):
        if self._apodization_factor is None:
            self.calc_apodization_factor
        return self._apodization_factor

def test_can_inititalize_apodization_window():
    """
    """
    apodization_window = ApodizationWindow(family='hamming', length=128)
    print(apodization_window)
    pass

def main():
    """
    """
    test_can_inititalize_apodization_window()
    print("fin")

if __name__ == "__main__":
    main()
