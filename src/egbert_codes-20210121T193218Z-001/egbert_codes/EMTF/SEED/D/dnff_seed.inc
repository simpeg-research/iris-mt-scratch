ccc     maximum block length for input files
        integer nblkmx,nixmx,nxxmx
ccc     set nblkmx = 4096 for seed files?
        parameter (nblkmx = 4096)
ccc     set nixmx to 10*nblkmx for seed files ...
        parameter (nixmx = 10*nblkmx,nxxmx = 3*nblkmx)
