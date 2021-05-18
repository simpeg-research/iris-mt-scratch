import matplotlib.pyplot as plt
import pandas as pd

from iris_mt_scratch.general_helper_functions import execute_subprocess
from mth5.utils.pathing import DATA_DIR

ASCII_COLUMNS = ["hx", "hy", "ex", "ey"]
def sort_out_which_channels_are_which():
    print("Not yet Implemented")
    print("You can use the mat-files un ULFEM if you really need to")


def get_webpage_name_from_metadata(station_id):
    """
    Place holder for a function to form the IRIS metadata query
    Returns
    -------
    # webpage = "https://service.iris.edu/fdsnws/station/1/query?net=BK&sta=PKD&loc=--&cha=LQ2,LQ3,LT1,LT2&starttime=2007-03-14T14:20:00&endtime=2008-08-26T00:00:00&level=response&format=xml&includecomments=true&nodata=404"
    """
    if station_id == "PKD":
        webpage = "https://service.iris.edu/fdsnws/station/1/query?net=BK&sta=PKD&loc=--&cha=LQ2,LQ3,LT1,LT2&starttime=2004-09-28T00:00:00&endtime=2004-09-28T23:59:59&level=response&format=xml&includecomments=true&nodata=404"
    elif station_id == "SAO":
        webpage = "https://service.iris.edu/fdsnws/station/1/query?net=BK&sta=SAO&loc=--&cha=LQ2,LQ3,LT1,LT2&starttime=2004-09-28T00:00:00&endtime=2004-09-28T23:59:59&level=response&format=xml&includecomments=true&nodata=404"
    return webpage


def get_station_xml_filename(station_id, data_date=None):
    """Placeholder in case we need to make many of these"""
    target_folder = DATA_DIR.joinpath("iris/BK/2004/XML")
    target_folder.mkdir(exist_ok=True)
    xml_filepath = target_folder.joinpath(f"{station_id}.xml")
    return xml_filepath

def iris_metadata_access_via_wget():
    for station_id in ["PKD", "SAO",]:
        print(station_id)
        webpage = get_webpage_name_from_metadata(station_id)
        output_filepath = get_station_xml_filename(station_id)
        cmd = 'wget "'
        cmd += webpage
        cmd += '" --output-document='
        cmd += str(output_filepath)
        execute_subprocess(cmd)
    return


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

def cast_data_to_archive(case_id=None):
    """
    One off
    delimiter=r"\s+"
    Parameters
    ----------
    case_id

    Returns
    -------

    """
    if case_id is None:
        case_id = "PKD_SAO_2004_272_00-2004_272_02"
    if case_id == "PKD_SAO_2004_272_00-2004_272_02":
        source_data_path = DATA_DIR.joinpath("iris/BK/2004/ATS")
        pkd_source_path = source_data_path.joinpath("PKD_272_00.asc")
        sao_source_path = source_data_path.joinpath("SAO_272_00.asc")
        pkd_df = pd.read_csv(pkd_source_path,
                         header=None,
                         delim_whitespace=True,
                         names=ASCII_COLUMNS)
        sao_df = pd.read_csv(sao_source_path,
                             header=None,
                             delim_whitespace=True,
                             names=ASCII_COLUMNS)
#                         delimiter=r"\s+", names=)#delim_whitespace=True))#
        sort_out_which_channels_are_which()
        # plt.plot(pkd_df["hx"] - pkd_df["hx"].mean(), label='PKD');
        # plt.plot(sao_df["hx"] - sao_df["hx"].mean(), label='SAO');
        #plt.show()
        pkd_df.to_csv(pkd_source_path.with_suffix(".csv"))
        pkd_df.to_hdf(pkd_source_path.with_suffix(".h5"), "pkd")
        sao_df.to_csv(sao_source_path.with_suffix(".csv"))
        sao_df.to_hdf(sao_source_path.with_suffix(".h5"), "sao")

        #Test adding to an h5
        merged_h5 = source_data_path.joinpath("pkd_sao_272_00.h5")
        pkd_df.to_hdf(merged_h5, "pkd")
        sao_df.to_hdf(merged_h5, "sao", "a")
        for component in ASCII_COLUMNS:
            pkd_df[component].to_hdf(merged_h5, f"{component}_pkd", "a")
            sao_df[component].to_hdf(merged_h5, f"{component}_sao", "a")

        #test access
        pkd_df2 = pd.read_hdf(merged_h5, "pkd")
        sao_df2 = pd.read_hdf(merged_h5, "sao")
        print("PKD", (pkd_df==pkd_df2).all() )
        print("SAO", (sao_df == sao_df2).all())

        hx_pkd = pd.read_hdf(merged_h5, "hx_pkd")
        return




def main():
    iris_metadata_access_via_wget()
    cast_data_to_archive()


if __name__ == "__main__":
    main()
    print("Fin")
