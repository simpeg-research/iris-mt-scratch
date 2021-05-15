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
from pathlib import Path
import subprocess
import xarray as xr

from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
from mt_metadata.timeseries import Experiment
from mth5.timeseries.channel_ts import ChannelTS
from mth5.timeseries.run_ts import RunTS

#from mt_metadata

xml_path = Path("/home/kkappler/software/irismt/mt_metadata/data/xml")
magnetic_xml_template = xml_path.joinpath("mtml_magnetometer_example.xml")
electric_xml_template = xml_path.joinpath("mtml_electrode_example.xml")
single_station_xml_template = xml_path.joinpath("mtml_single_station.xml")

#<LOAD SOME DATA FROM A SINGLE STATION>
N = 86400
SAMPLING_RATE = 1.0

def execute_subprocess(cmd, **kwargs):
    """
    A wrapper for subprocess.call
    """
    exit_status = subprocess.call([cmd], shell=True, **kwargs)
    if exit_status != 0:
        raise Exception("Failed to execute \n {}".format(cmd))
    return

def iris_data_access_via_wget():
    webpage = "https://service.iris.edu/fdsnws/station/1/query?net=BK&sta=PKD&loc=--&cha=LQ2,LQ3,LT1,LT2&starttime=2007-03-14T14:20:00&endtime=2008-08-26T00:00:00&level=response&format=xml&includecomments=true&nodata=404"
    output_folder = Path.expanduser("/home/kkappler/.cache/iris_mt/20210514")
    output_filepath = output_folder.joinpath("pkd_test.xml")

    cmd = f"wget {webpage} -- output - document {output_filepath}"
#    wget
# - -output - document / Path / TO / PKD.xml
def IRISDataAccessExample():
    from obspy.clients.fdsn import Client
    from obspy import UTCDateTime
    from obspy import read_inventory

    # Read inventory foerm IRIS Client
    client = Client(base_url="IRIS", force_redirect=True)
    starttime = UTCDateTime("2004-03-14T14:20:00")
    endtime = UTCDateTime("2004-03-17T00:00:00")
    inventory = client.get_stations(network="BK", station="PKD", channel="LQ2,LQ3,LT1,LT2",
                                    starttime=starttime,
                                    endtime=endtime,
                                    level="response")
    print("ADD sensor_type here")
    networks = inventory.networks
    for network in networks:
        for station in network:
            for channel in station:
                response =  channel.response
                stages = response.response_stages
                info = '{}-{}-{} {}-stage response'.format(network.code, station.code, channel.code, len(stages))
                print(info)

                for i,stage in enumerate(stages):
                    new_name = f"{channel.code}_{i}"
                    stage.name = new_name
                    print(f"stage {stage}, name {stage.name}")
                    if stage.name is None:
                        print("Give it a name")
    inventory.networks = networks
    print("NETWORKS REASSIGNED")
    # for network in networks:
    #     for station in network:
    #         for channel in station:
    #             response =  channel.response
    #             stages = response.response_stages
    #             #info = '{}-{}-{} {}-stage response'.format(network.code, station.code, channel.code, len(stages))
    #             #print(info)
    #             for i,stage in enumerate(stages):
    #                 #new_name = f"{channel.code}_{i}"
    #                 #stage.name = new_name
    #                 #print(f"stage {stage}, name {stage.name}")
    #                 print(f"stagename {stage.name}")
    #                 if stage.name is None:
    #                     print(f"stage {stage}, name {stage.name}")
    #                     print("Give it a name")
    #                 print("OK")
    from mt_metadata.timeseries.stationxml import XMLInventoryMTExperiment

    translator = XMLInventoryMTExperiment()
    experiment = translator.xml_to_mt(inventory_object=inventory)
    print("supposedly we have an inventory now ... check it")
    # networks = inventory.networks
    # for network in networks:
    #     for station in network:
    #         for channel in station:
    #             response =  channel.response
    #             stages = response.response_stages
    #             info = '{}-{}-{} {}-stage response'.format(network.code, station.code, channel.code, len(stages))
    #             print(info)
    #
    #             for stage in stages:
    #                 #pass
    #                 print('stage {}'.format(stage))

    return

def get_filters_dict_from_experiment_xml(xml):
    xml_path = Path(xml)
    mt_experiment = Experiment()
    mt_experiment.from_xml(fn=xml_path)
    print(mt_experiment, type(mt_experiment))
    surveys = mt_experiment.surveys
    survey = surveys[0]
    print("Survey Filters", survey.filters)
    survey_filters = survey.filters
    filter_keys = list(survey_filters.keys())
    print("FIlter keys", filter_keys)
    for filter_key in filter_keys:
        print(filter_key, survey_filters[filter_key])
    return survey_filters

def embed_metadata_into_run_ts(direct_from_xml=False):
    """
    2021-05-12: Trying to initialize RunTS class from xml metadata.
    Some issue on Karl's system with cloning -- probably related to
    logger.  workaround is to take the populated xml and parse
    with element tree.
    Parameters
    ----------
    direct_from_xml

    Returns
    -------

    """
    test_file = Path("test.h5")
    if test_file.exists():
        test_file.unlink()

    if direct_from_xml:
        from mt_metadata.timeseries import Experiment
        xml_path = Path("single_station_mt.xml")
        mt_experiment = Experiment()
        mt_experiment.from_xml(fn=xml_path)

    else:
        #this method not working -
        from mt_metadata.timeseries.stationxml import XMLInventoryMTExperiment
        from mt_metadata.utils import STATIONXML_02
        translator = XMLInventoryMTExperiment()
        mt_experiment = translator.xml_to_mt(stationxml_fn=STATIONXML_02)

    from mth5.mth5 import MTH5
    mth5_obj = MTH5()
    mth5_obj.open_mth5(r"test.h5", "w")

    mth5_obj.from_experiment(mt_experiment)

    run_01 = mth5_obj.get_run("REW09", "a")

    runts_object = run_01.to_runts()
    return runts_object


def get_dummy_channel(component, station_label=""):
    if component[0]=='h':
        ch = ChannelTS('magnetic')
    elif component[0]=='e':
        ch = ChannelTS('electric')
    ch.sample_rate = SAMPLING_RATE
    ch.start = datetime.datetime(1977, 3, 2, 0, 0, 0)#'2020-01-01T12:00:00+00:00'  # datetime.datetime(1977,3,2,0,0,0)#why not an object of type datetime()
    # Might need Tim:
    print("insert ROVER call here to access PKD, date, interval")
    print("USE this to load the data to MTH5")
    #https: // github.com / kujaku11 / mth5 / blob / master / examples / make_mth5_from_z3d.py

    ch.ts = np.random.randn(N)  # get this from iris                    # .data, .timestamo
    ch.station_metadata.id = 'PKD'  # get from for loop
    ch.run_metadata.id = 'MT001a'
    component_string = "_".join([component,station_label,])
    #component_string = component
    ch.component = component_string
    return ch

def get_example_data(component=None, load_actual=False, station_label=None):
    components_list = ['hx', 'hy', 'ex', 'ey', ]
    array_list = []
    for component in components_list:
        dummy_channel = get_dummy_channel(component,
                                          station_label=station_label)
        array_list.append(dummy_channel)
    mvts = RunTS(array_list=array_list)
    print("OKEE")
    return mvts
#</LOAD SOME DATA FROM A SINGLE STATION>

def filter_control_example():
    test_xml = Path("single_station_mt.xml")
    filter_dict = get_filters_dict_from_experiment_xml(test_xml)
    my_filter = filter_dict[list(filter_dict.keys())[0]]
    frq = np.arange(5)+1.2
    response = my_filter.complex_response(frq)
    print("response", response)

    for key in filter_dict.keys():
        print(f"key = {key}")
    print("OK")

def main():
    #iris_data_access_via_wget()
    IRISDataAccessExample()
    # filter_control_example()
    # runts_object = embed_metadata_into_run_ts()
    # runts_object = embed_metadata_into_run_ts(direct_from_xml=True)
    pkd_mvts = get_example_data(station_label="PKD")
    sao_mvts = get_example_data(station_label="SAO")
    pkd = pkd_mvts.dataset
    sao = sao_mvts.dataset
    pkd.update(sao)
    print("try to combine these runs")


if __name__ == "__main__":
    main()
