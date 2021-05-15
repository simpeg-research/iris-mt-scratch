import matplotlib.pyplot as plt
import pandas as pd
from mth5.utils.pathing import DATA_DIR

ASCII_COLUMNS = ["hx", "hy", "ex", "ey"]
def sort_out_which_channels_are_which():
    print("Not yet Implemented")
    print("You can use the mat-files un ULFEM if you really need to")

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
    cast_data_to_archive()


if __name__ == "__main__":
    main()
    print("Fin")
