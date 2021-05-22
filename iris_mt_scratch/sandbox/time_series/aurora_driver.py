"""
20210511: This script is intended to run an example version of end-to-end processing.
        #import xml.etree.ElementTree as ET
        #tree = ET.parse(xml_path)
        # mt_root_element = tree.getroot()
        # mt_experiment = Experiment()
        # mt_experiment.from_xml(mt_root_element)


TODO: MTH5 updated so that channel now returns a channel response
The question is how to propagate the response information to
Attributes RunTS

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

from iris_mt_scratch.sandbox.io_helpers.generate_pkdsao_test_data import get_station_xml_filename
# from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_array_list
from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_data
from iris_mt_scratch.sandbox.time_series.mth5_helpers import cast_run_to_run_ts
from iris_mt_scratch.sandbox.time_series.mth5_helpers import get_experiment_from_xml
from iris_mt_scratch.sandbox.time_series.mth5_helpers import HEXY
from iris_mt_scratch.sandbox.time_series.mth5_helpers import cast_run_to_run_ts
from iris_mt_scratch.sandbox.time_series.mth5_helpers import check_run_channels_have_expected_properties
from iris_mt_scratch.sandbox.time_series.mth5_helpers import embed_metadata_into_run
from iris_mt_scratch.sandbox.time_series.mth5_helpers import get_mth5_experiment_from_iris
from iris_mt_scratch.sandbox.time_series.windowing_scheme import WindowingScheme


def set_driver_parameters():
    driver_parameters = {}
    driver_parameters["create_xml"] = 0#False
    driver_parameters["run_ts_from_xml_01"] = False #True
    driver_parameters["run_ts_from_xml_02"] = False
    driver_parameters["run_ts_from_xml_03"] = False
    driver_parameters["initialize_data"] = True
    return driver_parameters

def test_runts_from_xml():
    run_obj = embed_metadata_into_run("PKD")
    array_list = get_example_array_list(components_list=HEXY,
                                        load_actual=True,
                                        station_id="PKD")
    runts_obj = cast_run_to_run_ts(run_obj, array_list=array_list)
    return run_obj, runts_obj


def main():
    """
    XML with FAP is here:
    https://service.iris.edu/fdsnwsbeta/station/1/query?net=EM&sta=FL001&cha=MFN&level=response&format=xml&includecomments=true&nodata=404



    Returns
    -------

    """
    driver_parameters = set_driver_parameters()
    #<CREATE METADATA XML>
    if driver_parameters["create_xml"]:
        #experiment = get_mth5_experiment_from_iris("SAO", save_experiment_xml=True)
        experiment = get_mth5_experiment_from_iris("PKD", save_experiment_xml=True)
    #</CREATE METADATA XML>


    #<TEST RunTS FROM XML>
    if driver_parameters["run_ts_from_xml_01"]:
        run_obj, runts_obj = test_runts_from_xml()
    #</TEST RunTS FROM XML>

    #<INITIALIZE DATA AND METADATA>
    if driver_parameters["initialize_data"]:
        #experiment = get_mth5_experiment_from_iris("PKD", save_experiment_xml=True)
        run_obj = embed_metadata_into_run("PKD")
        pkd_mvts = get_example_data(station_id="PKD", component_station_label=False)
#        sao_mvts = get_example_data(station_id="SAO")
#        pkd = pkd_mvts.dataset
#        sao = sao_mvts.dataset
#        sao.update(pkd)
    #</INITIALIZE DATA>

    #<PROCESS DATA>

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
    for key in fft_obj.data_vars.keys():
        print(f"{key}")
        channel = run_obj.get_channel(key)
        # <PZRSP>
        pz_calibration_response = channel.channel_response_filter.complex_response(frequencies)
        abs_pz_calibration_response = np.abs(pz_calibration_response)
        max_pz_calibration_response = np.max(abs_pz_calibration_response)
        norm_pz_calibration_response = abs_pz_calibration_response / max_pz_calibration_response
        # </PZRSP>

        # <FAP RSP>
        from instrument import DeployedInstrument
        from instrument import Instrument
        bf4 = Instrument(make="emi", model="bf4", serial_number=9819, channel=0, epoch=0)
        hx_instrument = DeployedInstrument(sensor=bf4)
        hx_instrument.get_response_function()
        bf4_resp = hx_instrument.response_function(frequencies)
        bf4_resp *= 421721.0
        abs_bf4_resp = np.abs(bf4_resp)
        norm_bf4_resp = bf4_resp / np.max(abs_bf4_resp)
        # </FAP RSP>


        # <CF RESPONSES>
        if SHOW_RESPONSE_FUNCTIONS:
            plt.loglog(frequencies, abs_pz_calibration_response, label='pole-zero')
            plt.loglog(frequencies, abs_bf4_resp, label='fap EMI')
            plt.legend()
            plt.title(f"Calibration Response Functions {key}")
            plt.xlabel("Frequency (Hz)")
            plt.ylabel("Response nT/sqrt(Hz)")
            plt.savefig(f"{key}_response_function_comparison_emifap_vs_pz.png")
            plt.show()
        # </CF RESPONSES>

        # <CF NORMALIZED RESPONSES>
        plt.loglog(frequencies, norm_pz_calibration_response, label='pole-zero')
        plt.loglog(frequencies, norm_bf4_resp, label='fap EMI')
        plt.legend()
        plt.title(f"Normalized Calibration Response Functions {key}")
        plt.xlabel("Frequency (Hz)")
        plt.ylabel("Normalized Response (Hz)")
        plt.savefig(f"{key}_normalized_response_function_comparison_emifap_vs_pz.png")
        plt.show()
        # </CF NORMALIZED RESPONSES>

        n_smooth = 131
        show_raw = 0
        raw_spectral_density = np.abs(fft_obj[key].data[:,1:])
        raw_spectral_density = raw_spectral_density.squeeze()#only for full window - need to recognize this or workaround
        calibrated_data_pz = raw_spectral_density / abs_pz_calibration_response
        calibrated_data_fap = raw_spectral_density / abs_bf4_resp

        if n_smooth:
            import scipy.signal as ssig
            smooth_calibrated_data_pz = ssig.medfilt(calibrated_data_pz, n_smooth)
            smooth_calibrated_data_fap = ssig.medfilt(calibrated_data_fap, n_smooth)
        if show_raw:
            plt.loglog(frequencies, calibrated_data_pz, color='b', label='pole-zero')
            plt.loglog(frequencies, calibrated_data_fap, color='r', label='fap EMI')
        if n_smooth:
#            plt.loglog(frequencies, smooth_calibrated_data_pz, color='b', label='smooth pole-zero')
            plt.loglog(frequencies, smooth_calibrated_data_fap, color='r', label='fap EMI')

        plt.legend()
        plt.grid(True, which="both", ls="-")
        plt.title(f"Calibrated Spectra {key}")
        plt.xlabel("Frequency (Hz)")
        plt.ylabel("nT/sqrt(Hz)")
        plt.savefig("calibrated_spectra_comparison_emifap_vs_pz.png")
        plt.show()




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
    windowing_scheme = WindowingScheme(taper_family="hamming", num_samples_window=256, num_samples_overlap=64)
    windowed_obj = windowing_scheme.apply_sliding_window(pkd_mvts.dataset)
    print("windowed_obj", windowed_obj)

    tapered_obj = windowing_scheme.apply_taper(windowed_obj)
    print("tapered_obj", tapered_obj)
    print("ADD A FLAG TO THESE SO YOU KNOW IF TAPER IS APPLIED OR NOT")

    fft_obj = windowing_scheme.apply_fft(tapered_obj, pkd_mvts.sample_rate)
    print("fft_obj", fft_obj)

    abs_spectrum = np.abs(fft_obj.hx_pkd.data)
    mean_spectrum = np.mean(abs_spectrum, axis=0)
#    mean_spectrum = fft_obj.hx_pkd.data.mean(axis=0)
    #log_spectrum = np.log10(mean_spectrum)
    import scipy.signal as ssig

    plt.loglog(fft_obj.hx_pkd.frequency.data[1:], np.abs(mean_spectrum[1:]), )
    plt.grid(True, which="both", ls="-")
    plt.show()
    #</DEFINE WINDOWING/TAPER PARAMETERS>
    print("try to combine these runs")


if __name__ == "__main__":
    main()
    print("Fin")
