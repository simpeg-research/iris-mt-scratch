"""
20210511: This script is intended to run an example version of end-to-end processing.
        #import xml.etree.ElementTree as ET
        #tree = ET.parse(xml_path)
        # mt_root_element = tree.getroot()
        # mt_experiment = Experiment()
        # mt_experiment.from_xml(mt_root_element)


TODO: MTH5 updated so that channel now returns a channel response
The question is how to propagate the response information to Attributes RunTS

20210520: This is a copy of aurora_driver.py which is going to be overwritten.  Most of the tests and tools
are associated with MTH5 helper stuffs so moved to mth5_helpers.py for now.  Needs a clean up.
"""

import datetime
import numpy as np
import pandas as pd
from pathlib import Path
import xarray as xr

#from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_data
from iris_mt_scratch.sandbox.io_helpers.generate_pkdsao_test_data import get_station_xml_filename
from iris_mt_scratch.sandbox.xml.xml_sandbox import describe_inventory_stages
from iris_mt_scratch.sandbox.xml.xml_sandbox import get_response_inventory_from_iris
from mt_metadata.timeseries import Experiment
from mt_metadata.timeseries.stationxml import XMLInventoryMTExperiment
from mt_metadata.utils import STATIONXML_02
from mth5.mth5 import MTH5
from mth5.timeseries.channel_ts import ChannelTS
from mth5.timeseries.run_ts import RunTS
from mth5.utils.pathing import DATA_DIR

#TEST_DATA_HELPER = TestDataHelper(dataset_id="PKD_SAO_2004_272_00-2004_272_02")
HEXY = ['hx','hy','ex','ey'] #default components list
xml_path = Path("/home/kkappler/software/irismt/mt_metadata/data/xml")
magnetic_xml_template = xml_path.joinpath("mtml_magnetometer_example.xml")
electric_xml_template = xml_path.joinpath("mtml_electrode_example.xml")
#single_station_xml_template = STATIONXML_02 # Fails for "no survey key"
#single_station_xml_template = Path("single_station_mt.xml")


#<LOAD SOME DATA FROM A SINGLE STATION>
N = 288000#86400
#DEFAULT_SAMPLING_RATE = 40.0#1.0


def get_filters_dict_from_experiment(experiment, verbose=False):
    """
    MTH5 HELPER
    Only takes the zero'th survey, we will need to index surveys eventually
    Parameters
    ----------
    experiment
    verbose

    Returns
    -------

    """
    surveys = experiment.surveys
    survey = surveys[0]
    survey_filters = survey.filters
    if verbose:
        print(experiment, type(experiment))
        print("Survey Filters", survey.filters)
        filter_keys = list(survey_filters.keys())
        print("FIlter keys", filter_keys)
        for filter_key in filter_keys:
            print(filter_key, survey_filters[filter_key])
    return survey_filters

def get_experiment_from_xml(xml):
    xml_path = Path(xml)
    experiment = Experiment()
    experiment.from_xml(fn=xml_path)
    print(experiment, type(experiment))
    return experiment

def cast_obspy_inventory_to_mth5_experiment(inventory):
    translator = XMLInventoryMTExperiment()
    experiment = translator.xml_to_mt(inventory_object=inventory)
    return experiment


def get_mth5_experiment_from_iris(station_id, save_experiment_xml=False):
    """
    his function needs to be factored to remove duplication.
    Note it is composed of 3 parts
    1. It gets an iris inventory (this is also a fcn in xml_sandbox --get_response_inventory_from_iris())
    2. It cycles through the SNCL and blubs some info, adding stage names if needed
    describe_inventory_stages() does this
    3. It casts the inventory to an Experiement()
    Returns experiment

    gets metadata from IRIS as station_xml and then uses obspy to cast this
    as an "Inventory()" obspy.core.inventory.inventory.Inventory
    The inventory is then cast to an "Experiment()" and the experiment is returned.

    One might think that the inventory could be saved using inventory.write("tmp.xml")
    and then we could create the experiment using
    experiment = Experiment()
    experiment.from_xml(fn="tmp.xml")
    but this did not work.  What does work is to create the experiment and save
    that to xml, and read back in.

    Parameters
    ----------
    station_id
    save_experiment_xml

    Returns
    -------

    """
    from obspy import UTCDateTime
    network = "BK"
    starttime = UTCDateTime("2004-09-28T00:00:00")
    endtime = UTCDateTime("2004-09-28T23:59:59")
    channel_codes = "LQ2,LQ3,LT1,LT2"
    channel_codes = "BQ2,BQ3,BT1,BT2"

    inventory = get_response_inventory_from_iris(network=network,
                                        station=station_id,
                                        channel=channel_codes,
                                        starttime=starttime,
                                        endtime = endtime,
                                        )
    inventory
    print("Add sensor name here")
    describe_inventory_stages(inventory, assign_names=True)
    print("NETWORKS REASSIGNED")
    describe_inventory_stages(inventory, assign_names=False)
    experiment = cast_obspy_inventory_to_mth5_experiment(inventory)

    if save_experiment_xml:
        output_xml_path = get_station_xml_filename(station_id)
        experiment.to_xml(output_xml_path)
        print(f"saved experiement to {output_xml_path}")
    return experiment


def check_run_channels_have_expected_properties(run):
    """
    Just some sanity check that we can access filters
    Parameters
    ----------
    run

    Returns
    -------

    """
    print(run.channel_summary)
    hx = run.get_channel('hx')
    print(hx.channel_response_filter)
    print(hx.channel_response_filter.filters_list)
    print(hx.channel_response_filter.complex_response(np.arange(3) + 1))
    return

def test_experiment_from_station_xml():
    """
    This test passes but when we use the hack of setting magnetic to "T" instead of "F" in
    fdsn_tools.py it fails for no code "F"
    Returns
    -------

    """
    from mt_metadata.utils import STATIONXML_02
    single_station_xml_template = STATIONXML_02  # Fails for "no survey key"
    #single_station_xml_template = Path("single_station_mt.xml")
    translator = XMLInventoryMTExperiment()
    mt_experiment = translator.xml_to_mt(stationxml_fn=STATIONXML_02)
    return

def embed_metadata_into_run(station_id, xml_path=None):
    """
    2021-05-12: Trying to initialize RunTS class from xml metadata.

    This will give us a single station run for now


    Tried several ways to manually assign run properties
    Here are some sample commands I may need this week.
    #ch = get_channel("hx", station_id="PKD", load_actual=True)
    #hx.from_channel_ts(ch,how="data")
    # run_01.metadata.sample_rate = 40.0
    # run_01.metadata.time_period.start = datetime.datetime(2004,9,28,0,0,0)
    # run_01.metadata.time_period.end = datetime.datetime(2004, 9, 28, 2, 0, 0)
    #run_01.station_metadata = "PKD"
    #run_01.write_metadata()
    #?run_01.from_channel_ts()


    Parameters
    ----------
    direct_from_xml

    Returns
    -------

    """
    test_file = Path("test.h5")
    if test_file.exists():
        test_file.unlink()

    if xml_path:
        experiment = get_experiment_from_xml(xml_path)
    else:
        experiment = get_mth5_experiment_from_iris(station_id)

    mth5_obj = MTH5()
    mth5_obj.open_mth5(r"test.h5", "w")
    mth5_obj.from_experiment(experiment)

    if "REW09" in mth5_obj.station_list:
        run_01 = mth5_obj.get_run("REW09", "a")
    elif "PKD" in mth5_obj.station_list:
        run_01 = mth5_obj.get_run("PKD", "001") #this run is created here
        print(experiment.surveys[0].stations[0].runs[0])
        check_run_channels_have_expected_properties(run_01)

    return run_01



def cast_run_to_run_ts(run, array_list=None, station_id=None):
    """
    add to mth5 helpers?
    basically embed data into a run_ts object.
    array_list = get_example_array_list(components_list=HEXY,
                                        load_actual=True,
                                        station_id="PKD")
    Parameters
    ----------
    run
    array_list
    station_id

    Returns
    -------

    """
    runts_object = run.to_runts()
    if array_list:
        runts_object.set_dataset(array_list)
    if station_id:
        runts_object.station_metadata.id = station_id
    return runts_object




def filter_control_example(xml_path=None):
    """
    This has two stages:
    1. reads an xml
    2. casts to experiement
    3. does filter tests.
    The filter tests all belong in MTH5 Helpers.
    Loads an xml file and casts it to experiment.  Iterates over the filter objects to
    confirm that these all registered properly and are accessible.  Evaluates
    each filter at a few frequencies to confirm response function works

    ToDo: Access "single_station_mt.xml" from metadata repository
    Parameters
    ----------
    xml_path

    Returns
    -------

    """
    if xml_path is None:
        print("WHY is this not working when I reference the STATIONXML_02?")
        xml_path = Path("single_station_mt.xml")
        #xml_path = STATIONXML_02
    experiment = get_experiment_from_xml(xml_path)
    filter_dict = get_filters_dict_from_experiment(experiment)
    frq = np.arange(5) + 1.2
    filter_keys = list(filter_dict.keys())
    for key in filter_keys:
        my_filter = filter_dict[key]
        response = my_filter.complex_response(frq)
        print(f"{key} response", response)

    for key in filter_dict.keys():
        print(f"key = {key}")
    print("OK")



def test_filter_stages():
    """
    Sanity check to look at each stage of the filters.  Just want to look at their spectra for now,
    input/output units should be added also, but the belongs in MTH5 or mt_metadata
    Returns
    -------

    """
    pass


def test_filter_control():
    print("move this from driver")
    pass

#</LOAD SOME DATA FROM A SINGLE STATION>

def set_driver_parameters():
    driver_parameters = {}
    driver_parameters["create_xml"] = True
    driver_parameters["test_filter_control"] = True
    driver_parameters["run_ts_from_xml_01"] = True
    driver_parameters["run_ts_from_xml_02"] = True
    driver_parameters["run_ts_from_xml_03"] = True
    driver_parameters["initialize_data"] = True
    return driver_parameters


def main():
    #test_experiment_from_station_xml()

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
    #method 1 is in aurora driver
        # <METHOD2>
    if driver_parameters["run_ts_from_xml_02"]:
        pkd_xml = get_station_xml_filename("PKD")
        run_obj = embed_metadata_into_run("PKD", xml_path=pkd_xml)
        runts_obj = cast_run_to_run_ts(run_obj, station_id="PKD")
        # </METHOD2>

        # <METHOD3>
    if driver_parameters["run_ts_from_xml_03"]:
        run_obj = embed_metadata_into_run("REW09", xml_path=single_station_xml_template)
        runts_obj = cast_run_to_run_ts(run_obj)
        # </METHOD3>
    #</TEST RunTS FROM XML>

    #<INITIALIZE DATA>
    if driver_parameters["initialize_data"]:
        pkd_mvts = get_example_data(station_id="PKD", component_station_label=True)
        sao_mvts = get_example_data(station_id="SAO", component_station_label=True)
        pkd = pkd_mvts.dataset
        sao = sao_mvts.dataset
        pkd.update(sao)
    #</INITIALIZE DATA>
    print("try to combine these runs")


if __name__ == "__main__":
    main()
    print("Fin")
