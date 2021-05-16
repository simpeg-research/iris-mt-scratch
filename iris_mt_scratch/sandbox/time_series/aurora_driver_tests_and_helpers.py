
import numpy as np

from pathlib import Path

from mt_metadata.timeseries import Experiment
from mt_metadata.utils import STATIONXML_02


def get_experiment_from_xml(xml):
    xml_path = Path(xml)
    experiment = Experiment()
    experiment.from_xml(fn=xml_path)
    print(experiment, type(experiment))
    return experiment


def get_filters_dict_from_experiment(experiment):
    print(experiment, type(experiment))
    surveys = experiment.surveys
    survey = surveys[0]
    print("Survey Filters", survey.filters)
    survey_filters = survey.filters
    filter_keys = list(survey_filters.keys())
    print("FIlter keys", filter_keys)
    for filter_key in filter_keys:
        print(filter_key, survey_filters[filter_key])
    return survey_filters

def filter_control_example(xml_path=None):
    """
    Loads an xml file and casts it to experiment.  Iterates over the filter objects to
    confirm that these all registered properly and are accessible.  Evaluates
    each filter at a few frequencies to confirm response function works

    ToDo: Access "single_station_mt.xml" from metadata repository
    Parameters
    ----------
    xml_path

    Returns
    -------

    """
    if xml_path is None:
        print("WHY is this not working when I reference the STATIONXML_02?")
        xml_path = Path("single_station_mt.xml")
        #xml_path = STATIONXML_02
    experiment = get_experiment_from_xml(xml_path)
    filter_dict = get_filters_dict_from_experiment(experiment)
    my_filter = filter_dict[list(filter_dict.keys())[0]]
    frq = np.arange(5)+1.2
    response = my_filter.complex_response(frq)
    print("response", response)

    for key in filter_dict.keys():
        print(f"key = {key}")
    print("OK")