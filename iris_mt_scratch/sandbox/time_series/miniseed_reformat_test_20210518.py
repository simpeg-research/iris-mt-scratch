"""
Examples of dumping a miniseed file from MTH5
"""

from iris_mt_scratch.sandbox.io_helpers.test_data import get_example_data




def test_cast_pkd_to_mseed():
    channel_map = {"hx_pkd":"BT1", "hy_pkd":"BT2",
                   "ex_pkd":"BQ2","ey_pkd":"BQ3",}
    import obspy
    #from obspy import UTCDateTime, read, Trace, Stream
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
        #data = hx_data.astype(np.int32)
        st = obspy.Stream([obspy.Trace(data=data, header=stats)])
    # write as ASCII file (encoding=0)
        st.write(f"{ch_label}.mseed", format='MSEED', reclen=512)
    print("OK")


def main():
    test_cast_pkd_to_mseed()

if __name__ == "__main__":
    main()
    print("Fin")
