#TODO: replace "fence_posts" with "band_edges"

import numpy as np
from pathlib import Path

# from interval import Interval
# from interval import IntervalSet

from emtf_band_setup import EMTFBandSetupFile
from iris_mt_scratch.sandbox.time_series.frequency_band_helpers import frequency_band_edges
from iris_mt_scratch.sandbox.time_series.frequency_band import FrequencyBand



class BandAveragingScheme(object):
    """
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

    """
    def __init__(self, **kwargs):
        self.something = None


    def from_emtf_cfg(self, filepath, decimation_level):
        pass

    

    def plot(self):
        #placeholder: show a plot of the band edges (dots) with x's in
        # between indicating the Fourier coefficient bins within each band
        pass




def test_instantiate_band_averaging_scheme():
    epsilon = 1e-7
    lower_bound = 0.078125
    upper_bound = 19.921875
    fenceposts = frequency_band_edges(lower_bound, upper_bound, num_bands=8)
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