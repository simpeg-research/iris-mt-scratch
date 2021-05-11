"""
20210511: This script is intended to run an example version of end-to-end processing.
"""
import datetime
import numpy as np
import xarray as xr

from iris_mt_scratch.sandbox.time_series.multivariate_time_series import MultiVariateTimeSeries
from mth5.timeseries.channel_ts import ChannelTS
from mth5.timeseries.run_ts import RunTS

#<LOAD SOME DATA FROM A SINGLE STATION>
N = 86400
SAMPLING_RATE = 1.0
def get_dummy_channel(component):
    if component[0]=='h':
        ch = ChannelTS('magnetic')
    elif component[0]=='e':
        ch = ChannelTS('electric')
    ch.sample_rate = SAMPLING_RATE
    ch.start = datetime.datetime(1977, 3, 2, 0, 0, 0)#'2020-01-01T12:00:00+00:00'  # datetime.datetime(1977,3,2,0,0,0)#why not an object of type datetime()
    # Might need Tim:
    ch.ts = np.random.randn(N)  # get this from iris                    # .data, .timestamo
    ch.station_metadata.id = 'PKD'  # get from for loop
    ch.run_metadata.id = 'MT001a'
    ch.component = component
    return ch

def get_example_data(component=None, load_actual=False):
    components_list = ['hx', 'hy', 'ex', 'ey', ]
    array_list = []
    for component in components_list:
        dummy_channel = get_dummy_channel(component)
        array_list.append(dummy_channel)
    mvts = RunTS(array_list=array_list)
    print("OKEE")
        #xrd = xr.



#</LOAD SOME DATA FROM A SINGLE STATION>




def main():
    get_example_data()


if __name__ == "__main__":
    main()
