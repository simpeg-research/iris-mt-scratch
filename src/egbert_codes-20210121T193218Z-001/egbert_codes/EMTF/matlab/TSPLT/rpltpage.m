    xp = PointPerWindow*(page-1) + 1;
    npts = min(PointPerWindow,Nopoints-xp+1);
    xend = xp+npts-1;
    aa = xp:stride:xend;
    plotpage(npts,0);
