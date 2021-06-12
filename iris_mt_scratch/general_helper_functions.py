import inspect
import subprocess
import xarray as xr

from pathlib import Path

import iris_mt_scratch

init_file = inspect.getfile(iris_mt_scratch)
DATA_DIR = Path(init_file).parent.joinpath("sandbox", "data")


FIGURES_BUCKET = Path.home().joinpath("Documents/IRIS_MT/figures")

def execute_subprocess(cmd, **kwargs):
    """
    A wrapper for subprocess.call
    """
    exit_status = subprocess.call([cmd], shell=True, **kwargs)
    if exit_status != 0:
        raise Exception("Failed to execute \n {}".format(cmd))
    return


# <NETCDF DOESN'T HANDLE COMPLEX>
#https://stackoverflow.com/questions/47162983/how-to-save-xarray-dataarray
# -with-complex128-data-to-netcdf

def save_complex(data_array, *args, **kwargs):
    ds = xr.Dataset({'real': data_array.real, 'imag': data_array.imag})
    return ds.to_netcdf(*args, **kwargs)

def read_complex(*args, **kwargs):
    ds = xr.open_dataset(*args, **kwargs)
    return ds['real'] + ds['imag'] * 1j
# </NETCDF DOESN'T HANDLE COMPLEX>