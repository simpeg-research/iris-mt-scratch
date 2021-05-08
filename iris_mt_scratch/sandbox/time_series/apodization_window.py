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

The Taper Config has 2 possible forms:
1. Standard form: ["family", "length", "additional_args"]

Example 1
"family" = "hamming"
"length" = 128
"additional_args" = {}

Example 2
"family" = "kaiser"
"length" = 64
"additional_args" = {"beta":8}
2. user-defined: ["family", "array"]
In this case length is defined by the array.
"family" = "user-defined"
"array" = [1, 2, 3, 4, 5, 4, 3, 2, 1]


"""
# import iris_mt_scratch.logging_util import init_logging
# logger = init_logging(__name__,module_name = 'aurora.time_series.taper')

import logging
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
        self.taper = kwargs.get('array', np.empty(0))
        self.additional_args = kwargs.get('additional_args', {})
        self.coherent_gain = None
        self.NENBW = None
        self.S1 = None
        self.S2 = None
        self._apodization_factor = None

        #here are some conditions for making taper
        condition_1 = len(self.family) != 0
        condition_2 = self.length != -1
        condition_3 = self.taper.size == 0

        if (condition_1 and condition_2 and condition_3):
            self.make()
        elif (not condition_3):
            # user defined taper.
            logging.info("user defined taper being initiated")
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
        return f"{self.family} {self.length} taper_exists={bool(self.taper.any())}"


    def make(self):
        """
        @note: see scipy.signal.get_window for a description of what is
        expected in args[1:]. http://docs.scipy.org/doc/scipy/reference/
        generated/scipy.signal.get_window.html

        note: this is just repackaging the args so
        """
        window_args = [v for k,v in self.additional_args.items()]
        window_args.insert(0, self.family)
        window_args = tuple(window_args)
        self.taper = ssig.get_window(window_args, self.length)

        return


    def custom_make(self, window_coefficients, **kwargs):
        self.family = kwargs.get('label', None)
        self.taper = window_coefficients
        self.length = len(window_coefficients)
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
    apodization_window = ApodizationWindow(family='blackmanharris', length=256)
    print(apodization_window)
    apodization_window = ApodizationWindow(family='kaiser', length=128, additional_args={"beta":8})
    print(apodization_window)
    apodization_window = ApodizationWindow(family='slepian', length=64, additional_args={"width":0.3})
    print(apodization_window)
    pass

def main():
    """
    """
    test_can_inititalize_apodization_window()
    print("fin")

if __name__ == "__main__":
    main()
