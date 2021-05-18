import datetime
import numpy as np
import pandas as pd

from mth5.timeseries.channel_ts import ChannelTS
from mth5.utils.pathing import DATA_DIR



class TestDataHelper(object):
    def __init__(self, **kwargs):
        self.dataset_id = kwargs.get("dataset_id")

    def load_df(self, dataset_id=None):
        if dataset_id is None:
            dataset_id = self.dataset_id

        if dataset_id == "pkd_test_00":
            source_data_path = DATA_DIR.joinpath("iris/BK/2004/ATS")
            merged_h5 = source_data_path.joinpath("pkd_sao_272_00.h5")
            df = pd.read_hdf(merged_h5, "pkd")
            return df
        if dataset_id == "sao_test_00":
            source_data_path = DATA_DIR.joinpath("iris/BK/2004/ATS")
            merged_h5 = source_data_path.joinpath("pkd_sao_272_00.h5")
            df = pd.read_hdf(merged_h5, "sao")
            return df

        if dataset_id == "PKD_SAO_2004_272_00-2004_272_02":
            source_data_path = DATA_DIR.joinpath("iris/BK/2004/ATS")
            merged_h5 = source_data_path.joinpath("pkd_sao_272_00.h5")
            pkd_df = pd.read_hdf(merged_h5, "pkd")
            sao_df = pd.read_hdf(merged_h5, "sao")
            return sao_df

    def load_channel(self, station, component):
        if self.dataset_id == "PKD_SAO_2004_272_00-2004_272_02":
            source_data_path = DATA_DIR.joinpath("iris/BK/2004/ATS")
            merged_h5 = source_data_path.joinpath("pkd_sao_272_00.h5")
            df = pd.read_hdf(merged_h5, key=f"{component}_{station.lower()}")
            return df.values




DEFAULT_SAMPLING_RATE = 40.0

def get_channel(component, station_id="", sampling_rate=DEFAULT_SAMPLING_RATE, load_actual=True ):
    """
    One off - specifically for loading PKD and SAO data for May 24th spectral tests.
    Move this into either io_helpers or into
    Parameters
    ----------
    component
    station_id
    load_actual

    Returns
    -------

    """
    test_data_helper = TestDataHelper(dataset_id="PKD_SAO_2004_272_00-2004_272_02")

    if component[0]=='h':
        ch = ChannelTS('magnetic')
    elif component[0]=='e':
        ch = ChannelTS('electric')

    ch.sample_rate = sampling_rate
    ch.start = datetime.datetime(2004, 9, 28, 0, 0, 0)
    print("insert ROVER call here to access PKD, date, interval")
    print("USE this to load the data to MTH5")
    #https: // github.com / kujaku11 / mth5 / blob / master / examples / make_mth5_from_z3d.py
    if load_actual:
        time_series = test_data_helper.load_channel(station_id, component)
    else:
        N = 288000
        time_series = np.random.randn(N)

    ch.ts = time_series  # get this from iris                    # .data, .timestamo
    ch.station_metadata.id = station_id
    ch.run_metadata.id = 'MT001a'
    component_string = "_".join([component,station_id,])
    ch.component = component_string


    return ch
