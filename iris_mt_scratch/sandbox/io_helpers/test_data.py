import pandas as pd

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


