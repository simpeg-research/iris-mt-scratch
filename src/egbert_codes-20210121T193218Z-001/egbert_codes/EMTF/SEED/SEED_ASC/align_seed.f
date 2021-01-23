ccc_____________________________________________________________________
ccc
      subroutine align_SEED(npts,nch,ix,ierr)

ccc   starting from a set of data blocks in array next_block,
ccc   find first possible common start time, initialize
ccc   array ix and starting record number irec  ...

      include 'seed.inc'
      integer ix(0:nch,*),nch,npts,ich,i,ierr,read_ms,k,
     &   irec_1(2,nchmx),irec_l(2,nchmx),start_rec,i0
      logical check_again
      double precision tdiff
      record /INT_TIME/exptime

ccc   find start, end sample numbers of (already input) next data block
ccc   (stored in next_blk)
      write(0,*) 'doy0 ==',doy0
      start_rec = 0
      do ich = 1,nch
         call rec_num(hdr(ich).begtime,doy0,samp_rate,irec_1(1,ich))
         start_rec = max(start_rec,irec_1(1,ich))
         call rec_num(hdr(ich).endtime,doy0,samp_rate,irec_l(1,ich))
      end do

      write(0,*) 'In align_seed : irec_1',(irec_1(1,k),k=1,5)
      write(0,*) 'In align_seed : irec_l',(irec_l(1,k),k=1,5)
      
ccc   make sure data blocks all contain a common starting record 
ccc   read additional blocks for "early" channels until this is
ccc   achieved
      check_again = .true.
      do while(check_again)
         check_again = .false.
         do ich = 1,nch
            do while(start_rec .gt. irec_l(1,ich)) 
               check_again = .true.
               ngot(ich) = read_ms(hdr(ich),next_blk(1,ich),nblkmx,
     &         inunits(ich))
               if(ngot(ich).le.0) then
ccc               end of file hit while searching for alignement
                  ierr = -1
                  return
               end if
               call rec_num(hdr(ich).begtime,doy0,samp_rate,
     &               irec_1(1,ich))
               start_rec = max(start_rec,irec_1(1,ich))
               call rec_num(hdr(ich).endtime,doy0,samp_rate,
     &                   irec_l(1,ich))
            end do
         end do
      end do

ccc   JUne 1997  add code to allow for offsets in sampling ...
      do ich = 1,nch
        dt(ich,1) = float(irec_1(2,ich))/TICKS_PER_SEC
        if(samp_rate.lt.0) then
           dt(ich,1) = dt(ich,1)*abs(samp_rate)
        else
           dt(ich,1) = dt(ich,1)/samp_rate
        endif
        dt_chng_rec(ich,1) = maxint
        dt_chng_n(ich) = 1
        dt_chng_i(ich) = 1
      enddo
      write(0,*) 'dt', (dt(ich,1),ich=1,nch)

c      irec = start_rec - 1
       write(0,*) 'start_rec = ',start_rec
      irec = start_rec
ccc   initialize ix, nix
      do ich = 1,nch
         i0 = start_rec - irec_1(1,ich)
         do i = i0+1,ngot(ich)
            ix(ich,i) = next_blk(i-i0,ich)
         end do
         nix(ich) = ngot(ich) - i0
      end do
      write(0,*) 'In align_seed : nix',(nix(k),k=1,5)

ccc   load next data block for each channel
      do ich = 1,nch
ccc      first save last header block
         call time_interval(ngot(ich),hdr(ich).sample_rate,second,
     &         ticks)
         call add_time(hdr(ich).begtime,second,ticks,exptime)
         ngot(ich) = read_ms(hdr(ich),next_blk(1,ich),nblkmx,
     &                      inunits(ich))
c         write(0,*) 'ngot(ich),ich',ngot(ich),ich
         if(ngot(ich) .le. 0 ) then
            iend(ich) = -1
            ngot(ich) = 0
         else
ccc         compute gap between blocks (if any) for channel ich
            iend(ich) = 0
            ngap(ich) = nint(tdiff(hdr(ich).begtime,exptime)/
     &              (TICKS_PER_SEC*ddr))
            if(ngap(ich) .gt. 0 ) then
               call rec_num(hdr(ich).begtime,doy0,samp_rate,
     &                     irec_1(1,ich))
               dt_chng_rec(ich,dt_chng_n(ich)) = irec_1(1,ich)
               dt_chng_n(ich) = dt_chng_n(ich) + 1
               dt(ich,dt_chng_n(ich)) = 
     &                  float(irec_1(2,ich))/TICKS_PER_SEC
               dt_chng_rec(ich,dt_chng_n(ich)) = maxint
            endif
         endif
      end do
c      write(0,*) 'in align seeed : ngot',(ngot(k),k=1,nch)
c      write(0,*) 'in align seeed : ngap',(ngap(k),k=1,nch)
      npts = 0
c      write(0,*) 'IEND',(iend(k),k=1,nch)
      return
      end
