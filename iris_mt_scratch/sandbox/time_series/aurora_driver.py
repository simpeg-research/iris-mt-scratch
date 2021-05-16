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
from mth5.mth5 import MTH5
from mth5.timeseries.channel_ts import ChannelTS
from mth5.timeseries.run_ts import RunTS
from mth5.utils.pathing import DATA_DIR

TEST_DATA_HELPER = TestDataHelper(dataset_id="PKD_SAO_2004_272_00-2004_272_02")

xml_path = Path("/home/kkappler/software/irismt/mt_metadata/data/xml")
magnetic_xml_template = xml_path.joinpath("mtml_magnetometer_example.xml")
electric_xml_template = xml_path.joinpath("mtml_electrode_example.xml")
single_station_xml_template = xml_path.joinpath("mtml_single_station.xml")

#<LOAD SOME DATA FROM A SINGLE STATION>
N = 288000#86400
SAMPLING_RATE = 40.0#1.0

def test_can_read_inventory_from_its_file_representation():
    pass

def get_mth5_experiment_from_iris(station_id, save_experiment_xml=False):
    from obspy import UTCDateTime
    network = "BK"
    starttime = UTCDateTime("2004-09-28T00:00:00")
    endtime = UTCDateTime("2004-09-28T23:59:59")
    channel_codes = "LQ2,LQ3,LT1,LT2"
    # Read inventory from IRIS Client
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
    #We should in theory be able to push this inventory down to file
    #and then reload it but that is not working right now;
    #import obspy #obspy.core.inventory.inventory.Inventory
    #tmp_inventory_path = "tmp_inventory.xml"
    #inventory.write(tmp_inventory_path)
    #experiment = Experiment()
    #experiment.from_xml(fn=tmp_inventory_path)
    translator = XMLInventoryMTExperiment()
    experiment = translator.xml_to_mt(inventory_object=inventory)
    if save_experiment_xml:
        output_xml_path = get_station_xml_filename(station_id)
        experiment.to_xml(output_xml_path)
        print(f"saved experiement to {output_xml_path}")
    return experiment

def get_experiment_from_xml(xml):
    xml_path = Path(xml)
    experiment = Experiment()
    experiment.from_xml(fn=xml_path)
    print(experiment, type(experiment))
    return experiment

def get_filters_dict_from_experiment(experiment):
    print(experiment, type(experiment))
    surveys = experiment.surveys
    survey = surveys[0]
    print("Survey Filters", survey.filters)
    survey_filters = survey.filters
    filter_keys = list(survey_filters.keys())
    print("FIlter keys", filter_keys)
    for filter_key in filter_keys:
        print(filter_key, survey_filters[filter_key])
    return survey_filters

def embed_metadata_into_run_ts(station_id, xml_path=None):
    """
    2021-05-12: Trying to initialize RunTS class from xml metadata.

    This will give us a single station run for now

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
        # #this method not working -
        # from mt_metadata.timeseries.stationxml import XMLInventoryMTExperiment
        # from mt_metadata.utils import STATIONXML_02
        # translator = XMLInventoryMTExperiment()
        # mt_experiment = translator.xml_to_mt(stationxml_fn=STATIONXML_02)

    mth5_obj = MTH5()
    mth5_obj.open_mth5(r"test.h5", "w")
    mth5_obj.from_experiment(experiment)

    if "REW09" in mth5_obj.station_list:
        run_01 = mth5_obj.get_run("REW09", "a")
    elif "PKD" in mth5_obj.station_list:
        print("NEED TO ADD A RUN")
        mth5_obj.add_run("PKD", "a")
        run_01 = mth5_obj.get_run("PKD", "a")
        # run_01
        # Out[3]:
        # / Survey / Stations / PKD / a:
        # == == == == == == == == == ==

    runts_object = run_01.to_runts()
    return runts_object

def get_channel(component, station_label=""):
    if component[0]=='h':
        ch = ChannelTS('magnetic')
    elif component[0]=='e':
        ch = ChannelTS('electric')
    ch.sample_rate = SAMPLING_RATE
    ch.start = datetime.datetime(2004, 9, 28, 0, 0, 0)#
    print("insert ROVER call here to access PKD, date, interval")
    print("USE this to load the data to MTH5")
    #https: // github.com / kujaku11 / mth5 / blob / master / examples / make_mth5_from_z3d.py
    time_series = np.random.randn(N)
    time_series = TEST_DATA_HELPER.load_channel(station_label, component)

    ch.ts = time_series  # get this from iris                    # .data, .timestamo
    ch.station_metadata.id = station_label
    ch.run_metadata.id = 'MT001a'
    component_string = "_".join([component,station_label,])
    #component_string = component
    ch.component = component_string
    return ch


def get_example_data(component=None, load_actual=False, station_label=None):
    components_list = ['hx', 'hy', 'ex', 'ey', ]
    array_list = []
    for component in components_list:
        channel = get_channel(component, station_label=station_label)
        array_list.append(channel)
    mvts = RunTS(array_list=array_list)
    return mvts

#</LOAD SOME DATA FROM A SINGLE STATION>

def filter_control_example(xml_path=None):
    if xml_path is None:
        #make this load from mt_metadata the versioned file
        xml_path = Path("single_station_mt.xml")
    experiment = get_experiment_from_xml(xml_path)
    filter_dict = get_filters_dict_from_experiment(experiment)
    my_filter = filter_dict[list(filter_dict.keys())[0]]
    frq = np.arange(5)+1.2
    response = my_filter.complex_response(frq)
    print("response", response)

    for key in filter_dict.keys():
        print(f"key = {key}")
    print("OK")

def main():
    #experiment = get_mth5_experiment_from_iris("PKD", save_experiment_xml=True)
    #experiment = get_mth5_experiment_from_iris("SAO", save_experiment_xml=True)
    filter_control_example()
    filter_control_example(xml_path=get_station_xml_filename("PKD"))
    #runts_object = embed_metadata_into_run_ts("REW09", xml_path=Path("single_station_mt.xml"))

    #<FAILS no SURVEY>
    pkd_xml = get_station_xml_filename("PKD")
    runts_object = embed_metadata_into_run_ts("PKD", xml_path=pkd_xml)
    #runts_object = embed_metadata_into_run_ts("PKD", xml_path="tmp.xml")
    #</FAILS no SURVEY>

    runts_object = embed_metadata_into_run_ts("PKD")
    runts_object = embed_metadata_into_run_ts(xml_path=Path("single_station_mt.xml"))
    pkd_mvts = get_example_data(station_label="PKD")
    sao_mvts = get_example_data(station_label="SAO")
    pkd = pkd_mvts.dataset
    sao = sao_mvts.dataset
    pkd.update(sao)
    print("try to combine these runs")


if __name__ == "__main__":
    main()
