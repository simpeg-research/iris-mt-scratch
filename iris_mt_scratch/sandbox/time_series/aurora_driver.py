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
import numpy as np
import pandas as pd
from pathlib import Path
import xarray as xr

from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
from iris_mt_scratch.sandbox.io_helpers.test_data import TestDataHelper
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

from iris_data_metadata_ingest_helpers import filter_control_example
from iris_data_metadata_ingest_helpers import get_experiment_from_xml
TEST_DATA_HELPER = TestDataHelper(dataset_id="PKD_SAO_2004_272_00-2004_272_02")
HEXY = ['hx','hy','ex','ey'] #default components list
xml_path = Path("/home/kkappler/software/irismt/mt_metadata/data/xml")
magnetic_xml_template = xml_path.joinpath("mtml_magnetometer_example.xml")
electric_xml_template = xml_path.joinpath("mtml_electrode_example.xml")
single_station_xml_template = STATIONXML_02 # Fails for "no survey key"
single_station_xml_template = Path("single_station_mt.xml")


#<LOAD SOME DATA FROM A SINGLE STATION>
N = 288000#86400
SAMPLING_RATE = 40.0#1.0

def test_can_read_inventory_from_its_file_representation():
    pass

def get_mth5_experiment_from_iris(station_id, save_experiment_xml=False):
    """
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

    print("Add sensor name here")
    describe_inventory_stages(inventory, assign_names=True)
    print("NETWORKS REASSIGNED")
    describe_inventory_stages(inventory, assign_names=False)

    translator = XMLInventoryMTExperiment()
    experiment = translator.xml_to_mt(inventory_object=inventory)
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
    print(hx.channel_response_filter.complex_response(np.arange(3) + 1))
    return


def embed_metadata_into_run(station_id, xml_path=None):
    """
    2021-05-12: Trying to initialize RunTS class from xml metadata.

    This will give us a single station run for now

    Notes:
    1. The following did not work:
    # from mt_metadata.timeseries.stationxml import XMLInventoryMTExperiment
    #from mt_metadata.utils import STATIONXML_02
    # translator = XMLInventoryMTExperiment()
    # mt_experiment = translator.xml_to_mt(stationxml_fn=STATIONXML_02)
    # @jared -- look into this

    2.
    tried several ways to manually assign run properties
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



def get_channel(component, station_id="", load_actual=False):
    if component[0]=='h':
        ch = ChannelTS('magnetic')
    elif component[0]=='e':
        ch = ChannelTS('electric')
    ch.sample_rate = SAMPLING_RATE
    ch.start = datetime.datetime(2004, 9, 28, 0, 0, 0)#
    print("insert ROVER call here to access PKD, date, interval")
    print("USE this to load the data to MTH5")
    #https: // github.com / kujaku11 / mth5 / blob / master / examples / make_mth5_from_z3d.py
    if load_actual:
        time_series = TEST_DATA_HELPER.load_channel(station_id, component)
    else:
        time_series = np.random.randn(N)

    ch.ts = time_series  # get this from iris                    # .data, .timestamo
    ch.station_metadata.id = station_id
    ch.run_metadata.id = 'MT001a'
    component_string = "_".join([component,station_id,])
    #component_string = component
    ch.component = component_string
    return ch


def get_example_array_list(components_list=None, load_actual=False, station_id=None):
    array_list = []
    for component in components_list:
        channel = get_channel(component,
                              station_id=station_id,
                              load_actual=load_actual)
        array_list.append(channel)
    return array_list

def get_example_data(components_list=HEXY,
                     load_actual=False,
                     station_id=None):
    array_list = get_example_array_list(components_list=components_list,
                                        load_actual=load_actual,
                                        station_id=station_id)
    mvts = RunTS(array_list=array_list)
    return mvts

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
        # <METHOD1>
    if driver_parameters["run_ts_from_xml_01"]:
        run = embed_metadata_into_run("PKD")
        array_list = get_example_array_list(components_list=HEXY,
                                            load_actual=True,
                                            station_id="PKD")
        runts_object = cast_run_to_run_ts(run, array_list=array_list)
                                          #station_id="PKD")
        # </METHOD1>

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
        pkd_mvts = get_example_data(station_id="PKD")
        sao_mvts = get_example_data(station_id="SAO")
        pkd = pkd_mvts.dataset
        sao = sao_mvts.dataset
        pkd.update(sao)
    #</INITIALIZE DATA>
    print("try to combine these runs")


if __name__ == "__main__":
    main()
    print("Fin")
