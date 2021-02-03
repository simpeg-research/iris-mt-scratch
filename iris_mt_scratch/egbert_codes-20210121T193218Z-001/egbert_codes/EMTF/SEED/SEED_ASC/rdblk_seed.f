ccc_____________________________________________________________________
ccc
      subroutine rdblk_SEED(npts,nch,ix,ierr)

ccc   returns "some" data points for nch channels of data,
ccc   each in a separate mini-seed file.   reads additional
ccc   blocks as needed, allows for gaps, adds sample numbers
ccc   to output multiplexed integer data array ix  ...

ccc  (tried to make interface/arguments similar to old versioni, but ...)
ccc   On entry it is assumed that the array ix contains npts+nix(nch)
ccc   data points, where nix varies with channel; all have at least
ccc   npts samples, which were used by the calling program on the
ccc   previous call.  Also in common block DATABLK_SEED the contents
ccc   of the next data block read from each file are stored in array
ccc   next_blk (along with info about numbers of pts read, gaps, etc.)
ccc   THe routine moves the unused portion of ix (i.e., the nix(.)
ccc   points for each channel after the first npts) to the top of
ccc   the array, and depending on various conditions (gap size if any,
ccc   how big nix(ich) is already, etc.) adds new points to the bottom
ccc   of the array (all of next_blk(ich)+ any missing values to fill
ccc   in small enough gaps).  If appropriate a new
ccc   block is read in (sometimes no points are moved from next_blk;
ccc   then no new block is read).  When ix has emptied for a channel
ccc   for which an EOF has been found, the routine returns ierr = -1
ccc   If a large gap (gt ngap_max) is found, and ix for
ccc   the channel with the gap has been emptied, the routine returns
ccc    ierr = - 3   ... in this case the calling program should next 
ccc   align the blocks (already in next_blk ... but some searching
ccc   through additional data will be required usually ... see
ccc   align_seed.f .)   Then this routine can be called again, and
ccc   reading can continue.

      include 'seed.inc'
      record /INT_TIME/exptime
      integer ix(0:nch,*),nch,npts,npts1,ich,i,ierr,read_ms,
     &   irec_1(2)
      double precision tdiff
      logical enuf_already(nchmx),big_gap(nchmx),lend

c      write(0,*) 'ngot',ngot
c      write(0,*) 'nix',nix
c      write(0,*) 'ngap',ngap

      ierr = 0
      npts1 = nix(1) + ngot(1) + ngap(1)
      do ich = 1,nch
         big_gap(ich) = (ngap(ich).gt.ngap_max)
         enuf_already(ich) = nix(ich).gt.nix_enuf
ccc      move "left over" points from previous read to top of buffer
         do i=npts+1,npts+nix(ich)
            ix(ich,i-npts) = ix(ich,i) 
         end do
         if(enuf_already(ich) .or. big_gap(ich)) then
ccc         don't add points to ix for this channel
            npts1 = min(npts1,nix(ich))
         else
ccc        first fill in missing value codes in gap (if needed)
            do i = 1,ngap(ich)
               ix(ich,nix(ich)+i) = msval
            enddo 
ccc         then move data from next block into output array,
            do i=1,ngot(ich)
               ix(ich,nix(ich)+ngap(ich)+i) = next_blk(i,ich) 
            end do
ccc         calculate number of points available for all channels
ccc         this is number of points returned (npts)
            npts1 = min(npts1,nix(ich)+ngap(ich)+ngot(ich))
         endif
      end do
      npts = npts1
c      write(0,*) 'npts',npts
ccc   recompute # of left over points
      do ich = 1,nch
         if(enuf_already(ich) .or. big_gap(ich))  then 
            nix(ich) = nix(ich) - npts
         else
            nix(ich) = nix(ich) + ngot(ich) + ngap(ich) - npts
         endif
      end do
ccc   add record numbers to the first npts points
      do i = 1,npts
         irec = irec + 1
         ix(0,i) = irec
      end do
c      write(0,*) 'New nix',nix

ccc   read in next block
      do ich = 1,nch
         if( (iend(ich).ge.0) .and. (.not.enuf_already(ich))
     &     .and. (.not.big_gap(ich)) ) then
ccc         continue reading file for channel ich
ccc         first save last header block
            call time_interval(ngot(ich),hdr(ich).sample_rate,second,
     &         ticks)
            call add_time(hdr(ich).begtime,second,ticks,exptime)
            ngot(ich) = read_ms(hdr(ich),next_blk(1,ich),nblkmx,
     &      inunits(ich))
c            call wrt_time(exptime)
c            call wrt_time(hdr(ich).begtime)
            if(ngot(ich) .le. 0 ) then
c               write(0,*) 'EOF: ngot(ich),ich',ngot(ich),ich
               iend(ich) = -1
               ngot(ich) = 0
            else
ccc            compute gap between blocks (if any) for channel ich
               ngap(ich) = nint(tdiff(hdr(ich).begtime,exptime)/
     &                     (TICKS_PER_SEC*ddr))
c               write(0,*) 'Reading for channel #',ich,' got ',ngot(ich),
c     &             'gap = ',ngap(ich)
                if(ngap(ich) .gt. 0 ) then
c                   write(0,*) 'NGAP ',(ngap(k),k=1,nch)
                   call rec_num(hdr(ich).begtime,doy0,samp_rate,irec_1)
                   dt_chng_rec(ich,dt_chng_n(ich)) = irec_1(1)
                   dt_chng_n(ich) = dt_chng_n(ich) + 1
                   dt(ich,dt_chng_n(ich)) = float(irec_1(2))/
     &                   TICKS_PER_SEC
                   dt_chng_rec(ich,dt_chng_n(ich)) = maxint
                endif
            endif
         endif
      end do
ccc   set ierr ...
      if(npts .gt. 0 ) then
ccc      all OK ... keep going
         ierr = 0
      else 
ccc      end of data stream???
         lend = .false.
         do ich = 1,nch
            lend = lend .or.iend(ich) .lt. 0 
         enddo
         if(lend) then
            ierr = -1
         else 
ccc         must be large data gap ...
            write(0,*) 'Large gap?'
c            write(0,*) 'IEND',(iend(k),k=1,nch)
            ierr = -3
         endif
ccc      (ierr = -2  can't occur for seed files ...)
      endif
      return
      end
