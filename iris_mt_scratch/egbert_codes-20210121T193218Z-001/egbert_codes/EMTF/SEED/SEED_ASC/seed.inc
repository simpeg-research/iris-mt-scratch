      include 'data_hdr.inc'
      include '../../include/nchmx.inc'

      integer nblkmx,ngap_max,nix_enuf,ndmax,maxint
      parameter (nblkmx = 10000)
      parameter (ngap_max = 2000)
      parameter (nix_enuf = 1000)
      parameter (maxint = 2*(2**30 -1 ) +1)

      record /DATA_HDR/ hdr(nchmx)
      integer inunits(nchmx),next_blk(nblkmx,nchmx),
     &    second,ticks,irec,iend(nchmx),samp_rate,nmsmx,
     &    ngot(nchmx),nix(nchmx),ngap(nchmx),msval,doy0
     &    ,dt_chng_rec(nchmx,20),dt_chng_n(nchmx),
     &     dt_chng_i(nchmx)
      real dr,dt(nchmx,20),dt0
      double precision same_time,ddr

      common /INBLK_SEED/same_time,ddr,inunits,nmsmx,msval,doy0,
     &   samp_rate
      common /DATABLK_SEED/next_blk,hdr,ngot,iend,nix,ngap,irec
      common /PHASE_BLK_SEED/dt0,dt,dt_chng_rec,dt_chng_n,dt_chng_i
