



def extract_band(frequency_band, fft_obj, epsilon=1e-7):
    """
    TODO: THis may want to be a method of fft_obj, or it may want to be a
    method of frequency band.  For now leave as stand alone.
    Parameters
    ----------
    interval
    fft_obj: xr.DataArray
    epsilon: use this when you are worried about missing a frequency due to
    round off error.  THis is in general not needed if we use a df/2 pad
    around true harmonics.

    Returns xr.DataArray
    -------

    """
    cond1 = fft_obj.frequency >= frequency_band.lower_bound - epsilon
    cond2 = fft_obj.frequency <= frequency_band.upper_bound + epsilon

    band = fft_obj.where(cond1 & cond2, drop=True)
    return band

