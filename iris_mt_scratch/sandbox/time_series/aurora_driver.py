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
"""

import datetime
from pathlib import Path

import numpy as np
import pandas as pd
import xarray as xr
from iris_metadata_ingest_helpers import filter_control_example
from iris_metadata_ingest_helpers import get_experiment_from_xml
from iris_mt_scratch.sandbox.io_helpers.generate_pkdsao_test_data import get_station_xml_filename
# from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_array_list
from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_data
from iris_mt_scratch.sandbox.time_series.mth5_helpers import HEXY
from iris_mt_scratch.sandbox.time_series.mth5_helpers import cast_run_to_run_ts
from iris_mt_scratch.sandbox.time_series.mth5_helpers import embed_metadata_into_run
from iris_mt_scratch.sandbox.time_series.mth5_helpers import get_mth5_experiment_from_iris
from iris_mt_scratch.sandbox.time_series.windowing_scheme import WindowingScheme


def set_driver_parameters():
    driver_parameters = {}
    driver_parameters["create_xml"] = True
    driver_parameters["test_filter_control"] = True
    driver_parameters["run_ts_from_xml_01"] = True
    driver_parameters["run_ts_from_xml_02"] = False
    driver_parameters["run_ts_from_xml_03"] = False
    driver_parameters["initialize_data"] = True
    return driver_parameters


def main():
    driver_parameters = set_driver_parameters()
    #<CREATE METADATA XML>
    if driver_parameters["create_xml"]:
        experiment = get_mth5_experiment_from_iris("PKD", save_experiment_xml=True)
        experiment = get_mth5_experiment_from_iris("SAO", save_experiment_xml=True)
    #</CREATE METADATA XML>

    #<TEST FILTER CONTROL>
    if driver_parameters["test_filter_control"]:
        filter_control_example()
        filter_control_example(xml_path=get_station_xml_filename("PKD"))
    #</TEST FILTER CONTROL>


    #<TEST RunTS FROM XML>
    if driver_parameters["run_ts_from_xml_01"]:
        run = embed_metadata_into_run("PKD")
        array_list = get_example_array_list(components_list=HEXY,
                                            load_actual=True,
                                            station_id="PKD")
        runts_object = cast_run_to_run_ts(run, array_list=array_list)
    #</TEST RunTS FROM XML>

    #<INITIALIZE DATA>
    if driver_parameters["initialize_data"]:
        pkd_mvts = get_example_data(station_id="PKD")
        sao_mvts = get_example_data(station_id="SAO")
        pkd = pkd_mvts.dataset
        sao = sao_mvts.dataset
        sao.update(pkd)

    #</INITIALIZE DATA>

    #<DEFINE WINDOWING/TAPER PARAMETERS>
    windowing_scheme = WindowingScheme()
    #</DEFINE WINDOWING/TAPER PARAMETERS>
    print("try to combine these runs")


if __name__ == "__main__":
    main()
    print("Fin")
