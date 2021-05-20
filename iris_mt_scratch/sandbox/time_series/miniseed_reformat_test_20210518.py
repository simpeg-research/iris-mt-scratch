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
from iris_mt_scratch.sandbox.io_helpers.test_data import get_channel
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

HEXY = ['hx','hy','ex','ey'] #default components list
xml_path = Path("/home/kkappler/software/irismt/mt_metadata/data/xml")
magnetic_xml_template = xml_path.joinpath("mtml_magnetometer_example.xml")
electric_xml_template = xml_path.joinpath("mtml_electrode_example.xml")
single_station_xml_template = STATIONXML_02 # Fails for "no survey key"
single_station_xml_template = Path("single_station_mt.xml")






def test_cast_pkd_to_mseed():
    channel_map = {"hx_pkd":"BT1", "hy_pkd":"BT2",
                   "ex_pkd":"BQ2","ey_pkd":"BQ3",}
    import obspy
    from obspy import UTCDateTime, read, Trace, Stream
    pkd_mvts = get_example_data(station_id="PKD")
    time_axis = pkd_mvts.dataset.time
    t0 = time_axis[0]
    for ch_label in pkd_mvts.channels:
        data = pkd_mvts.dataset[ch_label].data
        stats = {'network': 'BK', 'station': 'PKD', 'location': '',
             'channel': channel_map[ch_label],
                 'npts': len(data),
             'sampling_rate': 40.0,
             'mseed': {'dataquality': 'D'}}
        stats['starttime'] = obspy.UTCDateTime(t0.astype(int) * 1e-9)#ns
    #hx_data = hx_data.astype(np.int32)
        st = obspy.Stream([obspy.Trace(data=data, header=stats)])
    # write as ASCII file (encoding=0)
        st.write(f"{ch_label}.mseed", format='MSEED', reclen=512)
    print("OK")


def main():
    test_cast_pkd_to_mseed()

if __name__ == "__main__":
    main()
    print("Fin")
