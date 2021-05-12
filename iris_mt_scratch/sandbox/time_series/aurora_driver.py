"""
20210511: This script is intended to run an example version of end-to-end processing.
"""

import datetime
import numpy as np
from pathlib import Path
import xarray as xr

from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
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




def main():
    pkd_mvts = get_example_data(station_label="PKD")
    sao_mvts = get_example_data(station_label="SAO")

    print("try to combine these runs")


if __name__ == "__main__":
    main()
