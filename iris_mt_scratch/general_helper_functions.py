import subprocess

from pathlib import Path

FIGURES_BUCKET = Path.home().joinpath("Documents/IRIS_MT/figures")

def execute_subprocess(cmd, **kwargs):
    """
    A wrapper for subprocess.call
    """
    exit_status = subprocess.call([cmd], shell=True, **kwargs)
    if exit_status != 0:
        raise Exception("Failed to execute \n {}".format(cmd))
    return
