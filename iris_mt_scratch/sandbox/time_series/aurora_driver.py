"""
20210511: This script is intended to run an example version of end-to-end processing.

TODO: MTH5 updated so that run provides a channel which returns a channel response.
It seems like we need both a Run and a RunTS object to be able to access calibration
info and data in the same environment

TO ACCESS CHANNEL-SPECIFIC FILTERS LOOK HERE:
#check_run_channels_have_expected_properties()
"""

import datetime
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.signal as ssig
import xarray as xr

from aurora.signal.windowing_scheme import WindowingScheme
# from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_array_list
from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_data
from iris_mt_scratch.sandbox.io_helpers.test_data import TEST_DATA_SET_CONFIGS
from iris_mt_scratch.sandbox.time_series.mth5_helpers import cast_run_to_run_ts
from iris_mt_scratch.sandbox.time_series.mth5_helpers import get_experiment_from_obspy_inventory
from iris_mt_scratch.sandbox.time_series.mth5_helpers import get_experiment_from_xml_path
from iris_mt_scratch.sandbox.time_series.mth5_helpers import HEXY
from iris_mt_scratch.sandbox.time_series.mth5_helpers import check_run_channels_have_expected_properties
from iris_mt_scratch.sandbox.time_series.mth5_helpers import embed_experiment_into_run


def set_driver_parameters():
    driver_parameters = {}
    driver_parameters["run_ts_from_xml_01"] = 1#False #True
    driver_parameters["initialize_data"] = True
    driver_parameters["dataset_id"] = "pkd_test_00"
    driver_parameters["BULK SPECTRA"] = 0#True
    return driver_parameters

def test_runts_from_xml(dataset_id, runts_obj=False):
    dataset_id = "pkd_test_00"
    test_dataset_config = TEST_DATA_SET_CONFIGS[dataset_id]
    inventory = test_dataset_config.get_inventory_from_iris(ensure_inventory_stages_are_named=True)
    experiment = get_experiment_from_obspy_inventory(inventory)
    test_dataset_config.save_xml(experiment)
    run_obj = embed_experiment_into_run("PKD", experiment, h5_path=Path("PKD.h5"))

    if runts_obj:
        array_list = get_example_array_list(components_list=HEXY,
                                            load_actual=True,
                                            station_id="PKD")
        runts_obj = cast_run_to_run_ts(run_obj, array_list=array_list)
    return experiment, run_obj, runts_obj



def main():
    """
    Returns
    -------

    """
    driver_parameters = set_driver_parameters()
    dataset_id = driver_parameters["dataset_id"]

    #<TEST RunTS FROM XML>
    if driver_parameters["run_ts_from_xml_01"]:
        experiment, run_obj, runts_obj = test_runts_from_xml(dataset_id,
                                                             runts_obj=True)
    #</TEST RunTS FROM XML>

    #<INITIALIZE DATA AND METADATA>
    if driver_parameters["initialize_data"]:
        #ADD from_miniseed
        pkd_mvts = get_example_data(station_id="PKD", component_station_label=False)
    #</INITIALIZE DATA>

    #<PROCESS DATA>
        #<BULK SPECTRA CALIBRATION>
    if driver_parameters["BULK SPECTRA"]:

        windowing_scheme = WindowingScheme(taper_family="hamming",
                                           num_samples_window=288000,
                                           num_samples_overlap=0,
                                           sampling_rate=40.0)
        windowed_obj = windowing_scheme.apply_sliding_window(pkd_mvts.dataset)
        tapered_obj = windowing_scheme.apply_taper(windowed_obj)
        
        
        fft_obj = windowing_scheme.apply_fft(tapered_obj)
        from test_calibration import parkfield_sanity_check
        figures_path = Path("~/").expanduser().joinpath(".cache", "iris_mt", "png")
        # Maybe better to make parkfield_sanity_check start from run_ts and
        # run_obj once we have run_ts behaving correct w.r.t. data channels?
        parkfield_sanity_check(fft_obj, run_obj, figures_path=figures_path,
                               show_response_curves=True)
        #</BULK SPECTRA CALIBRATION>


        #<FC SERIES>
    filters_dict = experiment.surveys[0].filters
    #<DEFINE WINDOWING/TAPER PARAMETERS>
    windowing_scheme = WindowingScheme(taper_family="hamming",
                                       num_samples_window=512,
                                       num_samples_overlap=192,
                                       sampling_rate=40.0)
    windowed_obj = windowing_scheme.apply_sliding_window(pkd_mvts.dataset)
    print("windowed_obj", windowed_obj)

    tapered_obj = windowing_scheme.apply_taper(windowed_obj)
    print("tapered_obj", tapered_obj)
    print("ADD A FLAG TO THESE SO YOU KNOW IF TAPER IS APPLIED OR NOT")

    stft_obj = windowing_scheme.apply_fft(tapered_obj)#, pkd_mvts.sample_rate)
    
    print("stft_obj", stft_obj)
    stft_obj_xrda = stft_obj.to_array("channel")

    frequencies = stft_obj.frequency.data[1:]
    print(f"Lower Bound:{frequencies[0]}, Upper bound:{frequencies[-1]}")
    from frequency_bands import spectral_gates_and_fenceposts
    from frequency_bands import BandAveragingScheme
    from frequency_bands import extract_band
    from frequency_bands import extract_band2
    fenceposts = spectral_gates_and_fenceposts(frequencies[0], frequencies[
        -1], num_bands=8)
    band_averaging_scheme = BandAveragingScheme(fence_posts=fenceposts)
    for i_band in range(band_averaging_scheme.number_of_bands):
        band = band_averaging_scheme.band(i_band)
        band_data = extract_band(band, fft_obj_xrda)
        band_data2 = extract_band2(band, fft_obj_xrda)

        print("ready for TF")
        qq=1
        #extract_band(fft_obj)
        #fft_obj.extract_band(band)
        
    key = "hy"
    channel = run_obj.get_channel(key)
    pz_calibration_response = channel.channel_response_filter.complex_response(frequencies)
    calibrated_spectra = fft_obj[key].data[:, 2:] / pz_calibration_response
#    raw_spectral_density = np.abs(fft_obj[key].data[:, 1:])

    mean_spectrum = np.mean(np.abs(calibrated_spectra), axis=0)

    plt.figure(2)
    plt.clf()
    plt.loglog(frequencies, np.abs(mean_spectrum), 'b*' )
    plt.grid(True, which="both", ls="-")
    plt.show()
    #</DEFINE WINDOWING/TAPER PARAMETERS>


if __name__ == "__main__":
    main()
    print("Fin")
