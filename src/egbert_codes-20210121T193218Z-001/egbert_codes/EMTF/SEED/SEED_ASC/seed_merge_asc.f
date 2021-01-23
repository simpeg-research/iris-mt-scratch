      program seed_merge_asc

ccc   reads a series of mini-seed files, one for each channel
ccc   and outputs as an ASCII file with all channels merged and
ccc   alligned ... a good place to start to work on more complicated
ccc   read routines, e.g., allowing for data gaps ...
  
      integer nchmx,nblkmx,ich
      real dr,samp_freq
      parameter (nchmx = 10,nblkmx = 4096*10)
      character*80 cf_station,cfin(nchmx),cfsp,cout,arg
      integer nch,ix(0:nchmx,nblkmx),npts,ierr,doy_start,iargc,
     &    narg,k,doy_0,irec
      logical lbin

      lbin = .true.
      cf_station = 'cf_station'
      narg = iargc()
      do k = 1,narg
         call getarg(k,arg)
         if(arg(1:1) .eq. '-') then 
            call usage()
         else
            cf_station = arg
         endif
       enddo
      
ccc   open "station" file ... list of components, order, # of channels etc.
ccc   name of station file is input to routine as cf_station
      open(unit = 99,file = cf_station,status='old')
ccc   first line is number of data channels
      read(99,*) nch,doy_start
      do ich = 1,nch
ccc      then one line for file name of each data channel
         read(99,'(a80)') cfin(ich)
      enddo
ccc   next system parameter file (NOT NEEDED FOR THIS PROGRAM ...
ccc     can just leave blank ...)
      read(99,'(a80)') cfsp
ccc   last output station name
      read(99,'(a80)') cout
 
      call init_seed(cfin,nch,dr,samp_freq,doy_0)
      write(0,*) 'Done with init_seed'
      write(0,*) 'samp_freq',samp_freq
      write(0,*) 'doy_0',doy_0
      call set_doy(doy_start)
      if(lbin) then
         open(unit=1,file=cout,status='unknown',form='unformatted',
     &              access='direct',recl=4)
         irec = 1
         write(1,rec=irec) nch
         irec = 2
         write(1,rec=irec) samp_freq
         irec = 3
         write(1,rec=irec) doy_start
      else
         open(unit=1,file=cout,status='unknown')
      endif
10    continue
      call align_SEED(npts,nch,ix,ierr)
      ierr = 0
      do while (ierr .ge. 0)
         call rdblk_SEED(npts,nch,ix,ierr)
         call write_block(ix,nch,npts,1,lbin,irec)
      enddo
      if(ierr.eq.-3) go to 10
ccc   otherwise, end of file; just stop
      close(1)
      end
ccc_____________________________________________________________________
ccc
      subroutine write_block(ix,nch,npts,iounit,lbin,irec)
      logical lbin
      integer ix(0:nch,npts),iounit,nch,npts,i,k,irec

      if(lbin) then
         do i = 1,npts
            do k = 0,nch
               irec = irec + 1
               write(iounit,rec=irec) ix(k,i)
            enddo
         enddo
      else
         do i = 1,npts
           write(iounit,'(i10,5i9)') (ix(k,i),k=0,nch)
         end do
      endif
      return
      end 
ccc_____________________________________________________________________
ccc
      subroutine usage()
      
      write(0,*) 'Usage: seed_merge_asc <control file>'
      write(0,*) '        control file defaults to cf_station'
      stop
      end       
