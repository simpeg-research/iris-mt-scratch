      subroutine rec_num(itime,doy0,samp_rate,irec)
      include 'data_hdr.inc'
      record /INT_TIME/ itime
      record /EXT_TIME/ etime
      integer isec,irec(2),doy0,samp_rate,ndays
      real*8 rec

ccc   compute irec  ... relative to 0:00:00 of input day of year doy0
ccc   NOTE:   NO LEAPSECONDS HERE !!!!!!!
ccc   Convert internal time structure to external structure
ccc   JUne, 1997 : irec has dimension 2 ... fraction of dt is
ccc   now saved in irec(2)
      call int_to_ext(itime,etime)
      ndays = etime.doy-doy0
      if(ndays .lt. 0 ) then
         write(0,*) 'ERROR: time for zero record must preceed',
     &      ' start time for files :   STOPPING'
            write(0,*) 'ETIME.DOY',etime.doy,' doy0',doy0
         stop
      endif
      isec = ndays*(3600*24)+ 3600*etime.hour+60*etime.minute
     &           +etime.second
      if(samp_rate .lt. 0) then
         rec = ( dfloat(isec+dfloat(etime.ticks)/TICKS_PER_SEC)
     &                          /abs(samp_rate))
         irec(1) = nint(rec)
         irec(2) = nint( (rec - irec(1))*TICKS_PER_SEC)
      else
         rec = isec * samp_rate + 
     &            dfloat(samp_rate*dfloat(etime.ticks)/TICKS_PER_SEC)
         irec(1) = nint(rec)
         irec(2) = nint( (rec - irec(1))*TICKS_PER_SEC)
         write(0,*) etime.doy,etime.hour,etime.minute,etime.second,
     &        etime.ticks
      endif
      return
      end
