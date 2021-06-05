#TODO: replace "fence_posts" with "band_edges"
import numpy as np

from interval import Interval
from interval import IntervalSet

def compute_quantile(data):
    """
    receive a 3D array
    Parameters
    ----------
    data

    Returns
    -------

    """

def extract_band(interval, fft_obj):
    """
    will likely be a method of windowing_scheme or FrequencyDomainRun()

    Make the core, underlying numeric (numpy based method) take lower and upper
    bounds explicitly, i.e. remove dependance on Interval()

    ToDo: Make this method check for the "channel" dimension of fft_obj
    ToDo: Make this accept indices as well as interval as argument
    Parameters
    ----------
    interval
    fft_obj

    Returns
    -------

    """
    epsilon = 1e-7
    frequencies = fft_obj.frequency.data

    cond1 = frequencies >= interval.lower_bound - epsilon
    cond2 = frequencies <= interval.upper_bound + epsilon
    indices = cond1 & cond2

    data = fft_obj.data[:, :, indices]

    return data


def extract_band2(interval, fft_obj, epsilon=1e-7):
    cond1 = fft_obj.frequency >= interval.lower_bound - epsilon
    cond2 = fft_obj.frequency <= interval.upper_bound + epsilon

    band = fft_obj.where(cond1 & cond2, drop=True)
    return band


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

class BandAveragingScheme(object):
    """
    Context: A band is an Interval(). Use Interval() or IntervalSet()?

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

def main():
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