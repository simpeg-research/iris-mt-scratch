c______________________________________________________________________
c
      subroutine init_seed(cfin,nch,dr,samp_freq,doy_0)

      include 'seed.inc'
      integer nget,nch,ich,read_ms,ifopen,doy_0
      character*80 cfin(*)
      real dr,samp_freq
      record /EXT_TIME/ etime

ccc   NOTE about samp_rate, samp_freq, dr, etc.  :::
ccc  samp_rate is the sampling rate following the convention in the mini-SEED
ccc  file headers: + means hz, - means seconds;
ccc  samp_freq is real, and always frequency
ccc  dr (used in main and several other routines is real and always sample
ccc    interval in seconds.


ccc   msval (here set equal to maxint) is missing value code
      msval = 2147483647
      nmsmx = 1000

      nget = nblkmx
      do ich = 1,nch
         inunits(ich) = ifopen(cfin(ich),"r")
         if(inunits(ich).eq.0) then
            write(0,*) 'unable to open file ',cfin(ich),' STOPPING'
            stop
         end if
ccc      read in first block for each channel
         ngot(ich)=read_ms(hdr(ich),next_blk(1,ich),nget,inunits(ich))
c           write(0,*) 'ngot(ich) = ',ngot(ich)
         if(ngot(ich) .eq. 0 ) then
ccc         no data for one channel
            write(0,*) 'No data found for ',cfin(ich),'   STOPPING'
            stop
         endif
      end do

ccc   Find sampling rate 
      samp_freq = hdr(1).sample_rate
      samp_rate = samp_freq
      if(samp_freq .lt. 1) then
         samp_freq = 1./samp_freq
      endif
     
      call time_interval(1,hdr(1).sample_rate,second,ticks)
      ddr = second+float(ticks)/float(TICKS_PER_SEC)
      dr = float(ddr)
      same_time = TICKS_PER_SEC*ddr/100.
      write(0,*) 'dr = ',dr
ccc   Find starting day from first channel
      call int_to_ext(hdr(1).begtime,etime)
      write(6,*) 'First data in file is at time : '
      write(6,*) 'YEAR   :', etime.year
      write(6,*) 'DOY    :', etime.doy
      write(6,*) 'MONTH  :', etime.month
      write(6,*) 'DAY    :', etime.day
      write(6,*) 'HOUR   :', etime.hour
      write(6,*) 'HOUR   :', etime.hour
      write(6,*) 'SECOND :', etime.second
      write(6,*) 'TICKS  :', etime.ticks

      doy0 = etime.doy
      doy_0 = doy0

      return
      end
