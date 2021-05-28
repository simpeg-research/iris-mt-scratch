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
    driver_parameters["BULK SPECTRA"] = 1#False
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
        print("RUN OBJ is picking up an ez term (presumably from BQ3")
        experiment, run_obj, runts_obj = test_runts_from_xml(dataset_id, runts_obj=False)
    #</TEST RunTS FROM XML>

    #<INITIALIZE DATA AND METADATA>
    if driver_parameters["initialize_data"]:
        pkd_mvts = get_example_data(station_id="PKD", component_station_label=False)
    #</INITIALIZE DATA>

    #<PROCESS DATA>
        #<BULK SPECTRA>
    if driver_parameters["BULK SPECTRA"]:
        windowing_scheme = WindowingScheme(taper_family="hamming",
                                           num_samples_window=288000,
                                           num_samples_overlap=0,
                                           sampling_rate=40.0)
        windowed_obj = windowing_scheme.apply_sliding_window(pkd_mvts.dataset)
        tapered_obj = windowing_scheme.apply_taper(windowed_obj)
        fft_obj = windowing_scheme.apply_fft(tapered_obj)
        frequencies = fft_obj.frequency.data[1:]

        #LOOP OVER CHANNELS
        #add default flag for dropping DC
        SHOW_RESPONSE_FUNCTIONS = True
        PNG_PATH = Path("~/").expanduser().joinpath(".cache", "iris_mt", "png")
        PNG_PATH.mkdir(parents=True, exist_ok=True)

        channel_keys = list(fft_obj.data_vars.keys())
        print(f"channel_keys: {channel_keys}")
        print("TODO: THIS IS CHOKING ON EZ presumably from LQ3 -- probably happening "
              "in translator from inventory to experiment")
        for key in channel_keys[0:1]:
            print(f"{key}")
            channel = run_obj.get_channel(key)
            # <PZRSP>
            pz_calibration_response = channel.channel_response_filter.complex_response(frequencies)
            pz_calibration_response *= 1e-9
            abs_pz_calibration_response = np.abs(pz_calibration_response)
            max_pz_calibration_response = np.max(abs_pz_calibration_response)
            norm_pz_calibration_response = abs_pz_calibration_response / max_pz_calibration_response
            # </PZRSP>

            # <FAP RSP>
            from qf.instrument import DeployedInstrument
            from qf.instrument import Instrument
            bf4 = Instrument(make="emi", model="bf4", serial_number=9819, channel=0, epoch=0)
            hx_instrument = DeployedInstrument(sensor=bf4)
            hx_instrument.get_response_function()
            bf4_resp = hx_instrument.response_function(frequencies)
            bf4_resp *= 421721.0
            abs_bf4_resp = np.abs(bf4_resp)
            max_bf4_resp = np.max(abs_bf4_resp)
            norm_bf4_resp = abs_bf4_resp / max_bf4_resp
            # </FAP RSP>


            # <CF RESPONSES>
            if SHOW_RESPONSE_FUNCTIONS:
                plt.figure(1)
                plt.clf()
                plt.loglog(frequencies, abs_pz_calibration_response, label='pole-zero')
                plt.loglog(frequencies, abs_bf4_resp, label='fap EMI')
                plt.legend()
                plt.title(f"Calibration Response Functions {key}")
                plt.xlabel("Frequency (Hz)")
                plt.ylabel("Response nT/sqrt(Hz)")
                png_name = f"{key}_response_function_comparison_emifap_vs_pz.png"
                plt.savefig(PNG_PATH.joinpath(png_name))
                #plt.show()
            # </CF RESPONSES>

            # <CF NORMALIZED RESPONSES>
            # plt.loglog(frequencies, norm_pz_calibration_response, label=f"pole-zero {max_pz_calibration_response:.2f}")
            # plt.loglog(frequencies, norm_bf4_resp, label=f"fap EMI {max_bf4_resp:.2f}")
            # plt.legend()
            # plt.title(f"Normalized Calibration Response Functions {key}")
            # plt.xlabel("Frequency (Hz)")
            # plt.ylabel("Normalized Response (Hz)")
            # png_name = f"{key}_normalized_response_function_comparison_emifap_vs_pz.png"
            # plt.savefig(PNG_PATH.joinpath(png_name))
            # plt.show()
            # </CF NORMALIZED RESPONSES>

            n_smooth = 131
            show_raw = 0
            raw_spectral_density = fft_obj[key].data[:,1:]
            #raw_spectral_density = np.abs(fft_obj[key].data[:, 1:])
            raw_spectral_density = raw_spectral_density.squeeze()#only for full window - need to recognize this or workaround
            calibrated_data_pz = raw_spectral_density / pz_calibration_response
            #calibrated_data_pz = raw_spectral_density / abs_pz_calibration_response
            calibrated_data_fap = raw_spectral_density / abs_bf4_resp

            plt.figure(2)
            plt.clf()
            if n_smooth:
                import scipy.signal as ssig
                smooth_calibrated_data_pz = ssig.medfilt(np.abs(calibrated_data_pz), n_smooth)
                smooth_calibrated_data_fap = ssig.medfilt(np.abs(calibrated_data_fap), n_smooth)
            if show_raw:
                plt.loglog(frequencies, calibrated_data_pz, color='b', label='pole-zero')
                plt.loglog(frequencies, calibrated_data_fap, color='r', label='fap EMI')
            if n_smooth:
                plt.loglog(frequencies, smooth_calibrated_data_pz, color='b', label='smooth pole-zero')
                plt.loglog(frequencies, smooth_calibrated_data_fap, color='r', label='fap EMI')

            plt.legend()
            plt.grid(True, which="both", ls="-")
            plt.title(f"Calibrated Spectra {key}")
            plt.xlabel("Frequency (Hz)")
            plt.ylabel("nT/sqrt(Hz)")
            png_name = f"{key}_calibrated_spectra_comparison_emifap_vs_pz.png"
            plt.savefig(PNG_PATH.joinpath(png_name))
            #plt.show()




        #<CALIBRATION>
    filters_dict = experiment.surveys[0].filters
    #run_obj.get_channel('hx').channel_response_filter.filters_list


    # plt.loglog(frequencies, raw_hx_spectra)
    # plt.show()
    #
    # calibrated_data = spectral_calibration *np.abs(hx_spectral_density) / calibration_response[1:]
    # #calibrated_data = spectral_calibration * np.abs(fft_obj.hx_pkd.data[:, 1]).squeeze() / calibration_response[1:]
    # plt.loglog(frequencies[1:], calibrated_data)
    # plt.ylabel("nT/sqrt(Hz)")
    # plt.title("Calibrated spectra")
    # plt.show()
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

    fft_obj = windowing_scheme.apply_fft(tapered_obj, pkd_mvts.sample_rate)
    print("fft_obj", fft_obj)
    frequencies = fft_obj.frequency.data[2:]
    key = "hy"
    channel = run_obj.get_channel(key)
    pz_calibration_response = channel.channel_response_filter.complex_response(frequencies)
    pz_calibration_response *= 1e-9
    calibrated_spectra = fft_obj[key].data[:, 2:] / pz_calibration_response
#    raw_spectral_density = np.abs(fft_obj[key].data[:, 1:])
#    calibrated_data_pz =

#    abs_spectrum = np.abs(fft_obj.hx_pkd.data)
    mean_spectrum = np.mean(np.abs(calibrated_spectra), axis=0)
#    mean_spectrum = fft_obj.hx_pkd.data.mean(axis=0)
    #log_spectrum = np.log10(mean_spectrum)
    import scipy.signal as ssig
    plt.figure(2)
    #plt.clf()
    plt.loglog(frequencies, np.abs(mean_spectrum), 'b*' )
    plt.grid(True, which="both", ls="-")
    plt.show()
    #</DEFINE WINDOWING/TAPER PARAMETERS>
    print("try to combine these runs")


if __name__ == "__main__":
    main()
    print("Fin")
