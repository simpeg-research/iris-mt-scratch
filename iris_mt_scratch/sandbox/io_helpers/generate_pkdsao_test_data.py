
import matplotlib.pyplot as plt
import pathlib
import pandas as pd

from iris_mt_scratch.sandbox.xml.xml_sandbox import describe_inventory_stages
from iris_mt_scratch.sandbox.xml.xml_sandbox import get_response_inventory_from_iris
from iris_mt_scratch.general_helper_functions import execute_subprocess
from mth5.utils.pathing import DATA_DIR

ASCII_COLUMNS = ["hx", "hy", "ex", "ey"]

def get_test_dataset(station_id):
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
    return inventory

def test_can_read_rover():
    import obspy
    home = pathlib.Path("~/").expanduser()
    cache_path = home.joinpath(".cache")
    iris_cache = cache_path.joinpath("iris_mt")
    rover_cache = iris_cache.joinpath("datarepo", "data")
    data_file = rover_cache.joinpath("BK/2004/272/PKD.BK.2004.272")
    st1 = obspy.read(str(data_file))
    print("?")


def sort_out_which_channels_are_which():
    print("Not yet Implemented")
    print("You can use the mat-files in ULFEM if you really need to")


def get_webpage_name_from_metadata(station_id, pz_or_fap='pz'):
    """
    Place holder for a function to form the IRIS metadata query
    Returns
    -------
    # webpage = "https://service.iris.edu/fdsnws/station/1/query?net=BK&sta=PKD&loc=--&cha=LQ2,LQ3,LT1,LT2&starttime=2007-03-14T14:20:00&endtime=2008-08-26T00:00:00&level=response&format=xml&includecomments=true&nodata=404"
    """
    if pz_or_fap == "pz":
        if station_id == "PKD":
            webpage = "https://service.iris.edu/fdsnws/station/1/query?net=BK&sta=PKD&loc=--&cha=LQ2,LQ3,LT1,LT2&starttime=2004-09-28T00:00:00&endtime=2004-09-28T23:59:59&level=response&format=xml&includecomments=true&nodata=404"
        elif station_id == "SAO":
            webpage = "https://service.iris.edu/fdsnws/station/1/query?net=BK&sta=SAO&loc=--&cha=LQ2,LQ3,LT1,LT2&starttime=2004-09-28T00:00:00&endtime=2004-09-28T23:59:59&level=response&format=xml&includecomments=true&nodata=404"
    elif pz_or_fap == "fap":
        if station_id == "PKD":
            webpage = "https://service.iris.edu/fdsnwsbeta/station/1/query?net=EM&sta=FL001&cha=MFN&level=response&format=xml&includecomments=true&nodata=404"
        elif station_id == "SAO":
            print("Ask Tim For a SAO FAP response")
            raise(Exception)
    else:
        print(f"pz_or_fap must be one of 'pz' or 'fap', not {pz_or_fap}")
        raise Exception

    return webpage



def iris_metadata_access_via_wget():
    for station_id in ["PKD", "SAO",]:
        print(station_id)
        webpage = get_webpage_name_from_metadata(station_id)
        output_filepath = f"{station_id}.xml"
        cmd = 'wget "'
        cmd += webpage
        cmd += '" --output-document='
        cmd += str(output_filepath)
        execute_subprocess(cmd)
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
    # test_can_read_rover()
    iris_metadata_access_via_wget()
    # cast_data_to_archive()


if __name__ == "__main__":
    main()
    print("Fin")
