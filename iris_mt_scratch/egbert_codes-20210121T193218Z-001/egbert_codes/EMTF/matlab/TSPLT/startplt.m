delete(hfig);
decimate = 1;
[ch_id,su_id,data,ierr,ts_strt,ts_end] = ...
            plt_set(Nfiles,filenames, dirnames,decimate);
data = data/1000;
plotTS