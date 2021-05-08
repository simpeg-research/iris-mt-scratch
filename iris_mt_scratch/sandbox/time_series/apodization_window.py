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

2. user-defined: ["array"]
In this case length is defined by the array.
"array" = [1, 2, 3, 4, 5, 4, 3, 2, 1]

If "array" is non-empty then the assumption is that we are in the user defined case.

It is a little bit unsatisfying that the args need to be ordered for scipy.signal.get_window().
It is suggested that you use OrderedDict() for any windows that have more than one additional args.

For example
"family" = 'general_gaussian'
"additional_args" = OrderedDict("power":1.5, "sigma":7)

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
    See Also
    [2] Harris FJ. On the use of windows for harmonic analysis with the discrete
    Fourier transform. Proceedings of the IEEE. 1978 Jan;66(1):51-83.


    Instantiate an apodization window object.
    """
    def __init__(self, **kwargs):
        """

        Parameters
        ----------
        kwargs
        """
        self.family = kwargs.get('family', '')
        self._length = kwargs.get('length', 0)
        self.taper = kwargs.get('array', np.empty(0))
        self.additional_args = kwargs.get('additional_args', {})
        self.coherent_gain = None
        self.NENBW = None
        self.S1 = None
        self.S2 = None
        self._apodization_factor = None

        if self.taper.size==0:
            self.make()


    def __str__(self):
        """
        Returns a string comprised of the family, length, and True/False
        if self.taper is not None
        @rtype: str
        """
        return f"{self.family} {self.length} taper_exists={bool(self.taper.any())}"

    @property
    def length(self):
        if self._length==0:
            self._length = len(self.taper)
        return self._length

    def make(self):
        """
        this is just a wrapper call to scipy.signal
        @note: see scipy.signal.get_window for a description of what is
        expected in args[1:]. http://docs.scipy.org/doc/scipy/reference/
        generated/scipy.signal.get_window.html

        note: this is just repackaging the args so that scipy.signal.get_window() accepts all cases.
        """
        window_args = [v for k,v in self.additional_args.items()]
        window_args.insert(0, self.family)
        window_args = tuple(window_args)
        self.taper = ssig.get_window(window_args, self.length)

        return


    @property
    def calc_apodization_factor(self):
        S1 = sum(self.taper)
        S2 = sum(self.taper**2);
        self.coherent_gain = S1 / self.length
        self.nenbw = self.length*S2/(S1**2)
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
    print(apodization_window, "window factor=",apodization_window.apodization_factor)
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
