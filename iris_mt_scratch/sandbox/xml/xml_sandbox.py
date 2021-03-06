# -*- coding: utf-8 -*-
"""
Created on Fri Jan  8 15:24:33 2021

@author: kkappler
This is a xml reader prototype for the filter.xml

Filter application info: they always have either "value" or "poles_zeros"


#import xml.etree.ElementTree as ET
#tree = ET.parse(xml_path)
# mt_root_element = tree.getroot()
# mt_experiment = Experiment()
# mt_experiment.from_xml(mt_root_element)
"""


import datetime
import lxml
import matplotlib.pyplot as plt
import numpy as np
import obspy
import os
import pandas as pd
import pdb
import xmltodict as xd

from lxml import etree, objectify
from pathlib import Path

from iris_mt_scratch.general_helper_functions import FIGURES_BUCKET
from mth5.utils.pathing import DATA_DIR
from mth5_test_data.util import MTH5_TEST_DATA_DIR

from mt_metadata.base.helpers import element_to_dict
from mt_metadata.timeseries import Station
import xml.etree.cElementTree as ET

#<FROM TIM>
from obspy.clients.fdsn import Client
from obspy import UTCDateTime
from obspy import read_inventory


def test_instantiate_and_export_mth5_metadata_example():
    print("test_instantiate_and_export_mth5_metadata_example")
    mt_station = Station()
    json_string = mt_station.to_json(required=False, nested=True)
    f = open('meta.json', 'w')
    f.write(json_string)
    f.close()
    return


def get_response_inventory_from_iris(network=None, station=None, channel=None,
                            starttime=None, endtime=None, level="response"):
    """

    Parameters
    ----------
    network     network = "BK"
    station
    channel     channel = "LQ2,LQ3,LT1,LT2".  If you leave it as None it will get all channels
    starttime
    endtime
    station_id

    Returns
    -------

    """
    client = Client(base_url="IRIS", force_redirect=True)
    inventory = client.get_stations(network=network,
                                    station=station,
                                    channel=channel,
                                    starttime=starttime,
                                    endtime=endtime,
                                    level=level)
    return inventory


def test_get_example_em_xml_from_iris_via_web():
    print("test_get_example_em_xml_from_iris_via_web")
    client = Client(base_url="IRIS", force_redirect=True)
    starttime = UTCDateTime("2015-01-09")
    endtime = UTCDateTime("2015-01-20")
    inventory = client.get_stations(network="XX", station="EMXXX",
    starttime=starttime,
    endtime=endtime)
    network  = inventory[0] #obspy.core.inventory.network.Network
    print('ok')


def test_get_example_xml_inventory():
    print("test_get_example_xml_inventory")
    test_file_name = MTH5_TEST_DATA_DIR.joinpath("iris", "fdsn-station_2021-03-09T04_44_51.xml")
    inventory = read_inventory(test_file_name.__str__())
    iterate_through_mtml(inventory)
    print('ok')

def describe_inventory_stages(inventory, assign_names=False):
    """
    Scans iinventory looking for stages.  Has option to assign names to stages, these are used as keys in MTH5
    Modifies inventory in place.

    ToDo: Best practice to return inventory or no?
    Parameters
    ----------
    inventory
    assign_names

    Returns
    -------

    """
    new_names_were_assigned = False
    networks = inventory.networks
    for network in networks:
        for station in network:
            for channel in station:
                response =  channel.response
                stages = response.response_stages
                info = f"{network.code}-{station.code}-{channel.code}" \
                    f" {len(stages)}-stage response"
                print(info)
                for i,stage in enumerate(stages):
                    print(f"stagename {stage.name}")
                    if stage.name is None:
                        if assign_names:
                            new_names_were_assigned = True
                            new_name = f"{channel.code}_{i}"
                            stage.name = new_name
                            print(f"ASSIGNING stage {stage}, name {stage.name}")
                    if hasattr(stage, "symmetry"):
                        pass
                        # import matplotlib.pyplot as plt
                        # print(f"symmetry: {stage.symmetry}")
                        # plt.figure()
                        # plt.clf()
                        # plt.plot(stage.coefficients)
                        # plt.ylabel("Filter Amplitude")
                        # plt.xlabel("Filter 'Tap'")
                        # plt.title(f"{stage.name}; symmetry: {stage.symmetry}")
                        # plt.savefig(FIGURES_BUCKET.joinpath(f
                        # "{stage.name}.png"))
                        #plt.show()
    if new_names_were_assigned:
        inventory.networks = networks
        print("NETWORKS REASSIGNED")
    return #inventory




def iterate_through_mtml(networks):
    """
    Starting from pseudocode recommended by Tim
    20210203: So far all obspy XML encountered have had only a single network.
    
    Returns
    -------
    type networks: obspy.core.inventory.inventory.Inventory
    """
    for network in networks:
        for station in network:
            for channel in station:
                response =  channel.response
                stages = response.response_stages
                info = '{}-{}-{} {}-stage response'.format(network.code, station.code, channel.code, len(stages))
                print(info)

                for stage in stages:
                    #pass
                    print('stage {}'.format(stage))





def main():
    """
    """
    test_instantiate_and_export_mth5_metadata_example()
    test_get_example_xml_inventory()
    test_get_example_em_xml_from_iris_via_web()
    print("finito {}".format(datetime.datetime.now()))

if __name__ == "__main__":
    main()
