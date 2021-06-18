#TODO: replace "fence_posts" with "band_edges"

import numpy as np
from pathlib import Path

from interval import Interval
from interval import IntervalSet

from emtf_band_setup import EMTFBandSetupFile

class FrequencyBand(Interval):
    """
    Extends the interval class.

    has a lower bound, an upper bound and a central frequency

    These are intervals
    an method for Fourier coefficient indices

    Some thoughts 20210617:

    TLDR:
    For simplicity, I'm going with Half open, df/2 intervals when they are
    perscribed by FC indexes, and half_open gates_and_fenceposts when they
    are not.  The gates and fenceposts can be converted to the percribed form by
    mapping to emtf_band_setup_form and then mapping to FCIndex form.
    A 3dB point correction etc maybe done in a later version.

    <ON DEFAULT FREQUENCY BAND CONFIGURATIONS>
    Because these are Interval()s there is a little complication:
    If we use closed intervals we can have an issue with the same Fourier 
    coefficient being in more than one band [a,b],[b,c] if b corresponds to a harmonic.
    Honestly this is not a really big deal, but it feels sloppy. The default
    behaviour should partition the frequency axis, not break it into sets with
    non-zero overlap, even though the overlapping sets are of measure zero.

    On the other hand, it is common enough (at low frequency) to have bands
    which are only 1 Harmonic wide, and if we dont use closed intervals we
    can wind up with intervals like [a,a), which is the empty set.

    The best solution I can think of for now incorporates the fact that the
    harmonic frequencies we are going to interact with in digital processing
    will be a discrete collection, basically fftfreqs, which are separated by df.

    If we are given the context of df (= 1/(N*dt)) wher N is number of
    samples in the original time series and dt is the sample interval,
    then we can use half-open intervals with width df centered at the
    frequencies under consideration.
    
    I.e since the actual picking of Fourier coefficients and indexes will
    always occur in the context of a sampling rate and a frequency axis and 
    we will know df and therefore we can pad the frequency bounds by +/-
    df/2.

    In that case we can use open, half open, or closed intervals, it really
    doesn't matter, so we will choose half open
    [f_i-df/2, f_i+df/2) to get the satisfying property of covering the
    frequency axis completely but ensure no accidental double coverage.

    Notes that this is just a default convention.  There is no rule against
    using closed intervals, nor having overlapping bands.

    The df/2 trick also protects us from numeric roundoff errors resulting in
    edge frequencies landing in a bin other than that which is intended.

    There is one little oddity which accompanies this scheme.  Consider the
    case where you have a 1-harmonic wide band, say at 10Hz.  And df for
    arguments sake is 0.05 Hz.  The center frequency harmonically will not
    evaluate to 10Hz exactly, rather it will evaluate to sqrt((
    9.95*10.05))=9.9999874, and not 10.  This is a little bit unsatisfying
    but I take solace in two things:
    1. The user is welcome to use their own convention, [10.0, 10.0], or even
    [10.0-epsilon , 10.0+epsilon] if worried about numeric ghosts which
    asymptotes to 10.0
    2.  I'm not actually 100% sure that the geometric center frequency of the
    harmonic at 10Hz is truly 10.0.  Afterall a band has finite width even if
    the harmonic is a Dirac spike.

    At the end of the day we need to choose something, so its half-open,
    lower-closed intervals by default.

    Here's a good webpage with formulas if we want to get really fancy with
    3dB band edges.
    http://www.sengpielaudio.com/calculator-cutoffFrequencies.htm

    </ON DEFAULT FREQUENCY BAND CONFIGURATIONS>


    """
    def __init__(self, **kwargs):
        Interval.__init__(self,**kwargs)


    def fourier_coefficient_indices(self, frequencies):
        """

        Parameters
        ----------
        frequencies: numpy array
            Intended to represent the one-sided frequency axis of the data
            that has been FFT-ed

        Returns
        -------

        """
        cond1 = frequencies >= self.lower_bound
        cond2 = frequencies >= self.upper_bound
        indices = np.where(cond1 & cond2)[0]
        return indices


    def in_band_harmonics(self, frequencies):
        indices = self.fourier_coefficient_indices(frequencies)
        harmonics = frequencies[indices]
        return harmonics


    def center_frequency(self, frequencies=None):
        """
        if frequencies are provided, return the true
        Parameters
        ----------
        frequencies

        Returns
        -------

        """
        return np.sqrt(self.lower_bound*self.upper_bound)        






def spectral_gates_and_fenceposts(f_lower_bound, f_upper_bound,
                                  num_bands_per_decade=None, num_bands=None):
    """
    Provides logarithmically spaced fenceposts acoss lowest and highest
    frequencies.
    Parameters
    ----------
    lower_bound: float, lowest frequency under consideration
    upper_bound: float, highest frequency under consideration
    num_bands_per_decade

    Returns: logarithmically spaced fenceposts acoss lowest and highest
    frequencies
    -------

    """
    """
    @type nBandsPerDecade: int
    @param nBandsPerDecade: number of bands per decade; May want to handle 
    bands per octave and some other cases, but log10 is fine for now (Oct 2012)

    @type fencePosts: numpy array
    @rparam fencePosts: the posts for a partitioning of a range of the 
    frequency domain

    Returns array of frequencies being the fenceposts for the averaging gates.  
    This is a lot like calling logspace.  The resultant gates have constant 
    Q, i.e. deltaF/f_center=Q=constant.  
    where f_center is defined geometircally, i.e. sqrt(f2*f1) is the center freq 
    between f1 and f2.
    """
    if (num_bands is None) and (num_bands_per_decade is None):
        print("Specify number_of_bands of bands_per_decade")
        raise Exception

    if num_bands is None:
        number_of_decades = np.log10(f_upper_bound/ f_lower_bound);
        # The number of decades spanned (use log8 for octaves)
        num_bands = round(number_of_decades * num_bands_per_decade)  # this is the number of bands
        # I want; or should i be ceiling or flooring depending on desired resolution??

    a = np.exp((1.0 / num_bands) * np.log(f_upper_bound / f_lower_bound))
    # log - NOT log10!

    print("a = {}".format(a))
    bases = a * np.ones(num_bands + 1);
    print("bases = {}".format(bases))
    exponents = np.linspace(0, num_bands, num_bands + 1)
    print(f"exponents = {exponents}")
    fence_posts = f_lower_bound * (bases ** exponents)
    print(f"fence posts = {fence_posts}")
    return fence_posts


class FrequencyBands(object):
    """
    Use this as the core element for BandAveragingScheme
    """
    def __init__(self, **kwargs):
        self.gates = None
        self.fence_posts = kwargs.get("fence_posts", None)
        #frequencies ... can repeat (log spacing)

    def from_emtf_cfg(self, filepath, decimation_level):
        w



class BandAveragingScheme(object):
    """
    Context: A band is an Interval(). 
    A band_averaging_scheme can be represented as an IntervalSet()

    This should support multiple decimation levels.
    For now, let's make it for a single decimation level.  There can be a
    collection of band_avergaing_schemes keyed by decimation_level_id

    May want to rename this as a BandDefinition and a BandAveragingScheme can be
    a  decimation level aggregated collection of BandDefinations


    
    What do we want from this class?
    1. We want to be able to generate a sequence of indices that correspond to
    the indices of an array that we will average together.  I.e. [5,6,7] will
    for example grab the 5th, 6th and 7th Fourier coefficient from an array
    and return the band with the average value.



    2. We want to be able to access bands by some label (often this will just be an integer)
    band1, band2, or "low-frequency" or "dead band" etc.

    3.a) A given band should be able to express its lower and upper bounds in
    terms of frequency in Hz.
    3b) It should be specified if the bounds are open, closed, or half open (
    lower or upper)

    4. It would be nice to have a generator for logarithmic or linear bands

    Note that a band is just an Interval() with an upper bound and a lower bound

    In general we do not allow bands to overlap, but this might not be something
    to enforce.  But it would be a good thing to be able to check.


    Recall that when band averaging you lose phase information unless you have
    performed some cross spectral operation first, such as ratio or product
    between fourier series.

    Gates and fenceposts is an issue here, there are N bands and N+1 band edges.

    At the core of Gary's band strucutre is a
    TSTFTarray.m:11:        EstimationBands    %   array of dimension (nBands,3) giving decimation
    band = obj.EstimationBands(ib,:);
    AllRuns(k) = obj.Array{j}(k).FC(band(1)).extractBand(band(2:3));

    time to start killing chickens - DC
    """
    def __init__(self, **kwargs):
        self.gates = None
        self.fence_posts = kwargs.get("fence_posts", None)
        #frequencies ... can repeat (log spacing)

    @property
    def number_of_bands(self):
        return len(self.fence_posts)-1
        
    
    

    def band(self, i_band):
        """
        Decide to index bands from zero or one, i.e.  Choosing 0 for now.
        Parameters
        ----------
        i_band: integer key for band

        Returns
        -------

        """
        ivl = Interval(lower_bound=self.fence_posts[i_band],
                       upper_bound=self.fence_posts[i_band+1])

        return ivl

    def center_frequency(self, band):
        pass

    def plot(self):
        #placeholder: show a plot of the band edges (dots) with x's in
        # between indicating the Fourier coefficient bins within each band
        pass




def test_instantiate_band_averaging_scheme():
    epsilon = 1e-7
    lower_bound = 0.078125
    upper_bound = 19.921875
    fenceposts = spectral_gates_and_fenceposts(lower_bound, upper_bound,
                                               num_bands=8)
    band_averaging_scheme = BandAveragingScheme(fence_posts=fenceposts)
    i_band = 3
    band = band_averaging_scheme.band(i_band)
    print(f"band {i_band} = {band}")
    print("OK")
    pass

def test_emtf_band_setup():
    #filepath = Path("bs_test.cfg")
    filepath = Path("bs_256.cfg")
    emtf_band_setup = EMTFBandSetupFile(filepath=filepath)
    emtf_band_setup.load()
    dec_1 = emtf_band_setup.get_decimation_level(1)
    print(dec_1)
    print("ok")
    return


def main():
    test_emtf_band_setup()
    test_instantiate_band_averaging_scheme()
    pass

if __name__ == "__main__":
    main()
# def bandAveragingScheme(fence_posts):
#     """
#     returns list of bands for spectral (usually MT TF) averaging
#
#     @type fenceposts: numpy array
#     @param fencePosts: list of band egdes
#     @rtype bands: dictionary
#     @rparam bands: List of returned bands; index key is 'band Number', entry
#     is lower and upper bound
#
#     @note: BAND AVERAGING SEEMS TO DESERVE A CLASS:
#         -FENCEPOSTS
#         -F_center
#         -F_Low
#         -F_hi
#         no?
#
#     """
#
#     bands = {}
#     nB = len(fencePosts) - 1;
#     for iB in range(0, nB):
#         logger.debug("Band {} of {}".format(iB + 1, nB))
#         band = np.array([fencePosts[iB], fencePosts[iB + 1]])
#         bands[iB] = band
#
#     return bands