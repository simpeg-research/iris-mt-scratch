      program dnff

      character*10 cdate
      character*4 cvers
      parameter (cvers = '5.1', cdate = '02/13/1998')
  
      include '../../D/iounits.inc'
      include 'params1.inc'
      include '../../D/decimate.inc'
      include '../../D/input.inc'
      include 'dnff_seed.inc'

      parameter (nt=nwmx/2,ntot= nwmx*nchmx,nchmx1=nchmx+1,
     &  nmax = 3*nwmx,nwsvmx = nwmx*4+15,nfmax=nwmx/2,nwmx1=nwmx+10
     &       , nchmx2 = 2*nchmx,nchmx21 = nchmx*2+1)
          
      real x(nchmx,nwmx1),samprate(ndmx),w(nwmx,ndmx)
     &    ,sc(nchmx),wsave(nwsvmx,ndmx),stcor(2),orient(2,nchmx),
     &    xx(ndmx,nchmx1,0:nxxmx),pspecl1(nchmx,nwmx,ndmx),
     &    areg(nchmx,10),rr(nwmx),ar(nwmx),bwo(nwmx),br(nwmx,1)
      real	dt

      complex wrk(nwmx),rnrmt(nchmx,ndmx,nt),cwrk(nchmx,nsmax)
     &   ,cout(nchmx,nsmax)
        
      integer ix1(nchmx1,nixmx),
     &   next(ndmx),ifirstd(ndmx),nacc(ndmx),
     &    idp(0:ndmx,2,nbadmx),iwrk(nchmx,nsmax),
     &    ids(0:ndmx,2,nbadmx),ndp(0:ndmx),ifirst(ndmx),nspec(ndmx),
     &    nds(0:ndmx),iftype(nfilmax,nchmx),
     &    nfil(nchmx),iset(4,nsmax),ifdir(3,nsmax),
     &    idl(ndmx),ioffc,ixs(nsmax),doy_start,hr_start,min_start,
     &     sec_start,iset_offset(ndmx),time_int,doy_0

        logical lstart(ndmx),lstartd(ndmx),lgood,lg,lclkd
     &  ,lfd(nchmx,ndmx),lwinst(ndmx),lseed
        
      character*1 ans
      character*50 arg
      character*6 chid(nchmx)
      character*80 afparam(nfilmax,nchmx),cfin(nchmx),cf_station

C   SCRATCH FILE 02.01.98
        real x_scr(nsmax*nfmax,nchmx,2)
        integer iuse_scr(nsmax*nfmax)

       print*,'********************************************************'
       print*,'*                                                      *'
       print*,'*     DNFF_SEED     Version: ',cvers,'   Date: ',cdate,
     &'        *'
       print*,'*                                                      *'
       print*,'********************************************************'
       print*,' '
       bytes = NBYTES
      ioff = 0
      lseed = .false.

c     parse command line options
       nargs = iargc()
       do k = 1, nargs
          call getarg(k,arg)
          if (arg(1:2) .eq. '-b') then
             read (arg(3:3),*) bytes
          elseif(arg(1:2).eq.'-s') then
ccc          Read directly from mini-seed data files.  In this case only one 
ccc          run can be done at a time.  To run with seed files: 
ccc                    dnff -scf_station   
ccc          where "cf_station" is the name of a file containing # of
ccc          channels, and file names for each channel
             lseed = .true.
             cf_station = arg(3:50)
             if(iclong(cf_station,78).eq.0) cf_station = 'cf_station'
          endif

      enddo
      if( lseed) then
         write(6,'(/,''    Using binary mini-SEED files'',/)')
      else
      write(6,'(/,''    Using integer*'',i1,'' as binary input '',/)')
     &      bytes
      endif

c       return here to start processing another data file
1000  continue

c*********************************************************************
      
c    compute l1 power spectrum for pre-scaling output
c          blank array pspecl1
      do i = 1,ndmx
         nspec(i) = 0
         do k = 1,nchmx
            do j = 1,nwmx
               pspecl1(k,j,i) = 0.0
            enddo
         enddo
      enddo

c*****  get station name from standard input, input files paths from
c       local file paths; open input file, make sp br etc path/file names
      if(lseed) then
         call init_files(cf_station,cfin,nch,doy_start,hr_start,
     &                   min_start,sec_start)
         call init_seed(cfin,nch,dr,sampfreq,doy_0)
         time_int = - sec_start+
     &       60*(-min_start+60*(-hr_start + 24*(doy_0-doy_start)))
         write(0,*) 'Survey Start'
         write(0,*) doy_start,hr_start,min_start,sec_start
         write(0,*) 'doy_0',doy_0
         write(0,*) 'Time Interval',time_int

         msval = 2147483647
         rmsval =  float(msval) - 1000.
      else
         call cininit(msval,rmsval,nch)
      endif
      nchp1 = nch+1

      write(0,*) 'Opening output file',cfout
C     ME  REMOVE SCRATCH FILE
      call outinit(nch,lpack)

c  read system parameter file:  number of channels,
c  electrode line lengths, filter parameters, conversion
c  factors, etc. from file spsta###x
      call getsp(nch0,sampr,sc,nfil,iftype,afparam,
     &   decl,stcor,orient,chid,cda,cdb,lclkd)  !cfsp,

      if(nch0.ne.nch) then
         print*,'error: nch in sp file does not agree with nch in',
     &     ' data file'
         stop
      endif
      if(cfsp(4:11).eq.'standard') then
         print*,'enter declination, station coordinates'
         read(5,*) decl,stcor(1),stcor(2)
      endif

c  set up decimation; decset reads parameters which control decimation
c  from a file; see documentation in decset for further info; 
      call decset(nwmx,lfd,idoff,ierr)
      if(ierr.eq.1) then
         print*,'parameters read from cf_decset are inconsistent',
     &   ' with parameters declared in main program'
           stop
      endif

c  compute sampling rate for each decimation level     
        nfusemx = 0
        do 1 i = 1,nd
        idl(i) = i + idoff
        samprate(i) = sampr
        nfusemx = max(nfusemx,nfuse(i))
           do 1 j = 1,i                        
1          samprate(i) = samprate(i)*idec(j)
c  set up decimation filter corrections, conversion of counts
c  to physical units (this routine makes a table of transfer
c  functions to correct for all of these)
      call fcorsu(samprate,nfil,afparam,
     1  iftype,sc,rnrmt,cda,lfd)
c    read in bad records file (gives record ranges which should not 
c    be processed (idp) or stacked (ids); see routine for input format
c    file also gives offset to adjust record numbers with
      call bdrcsu(nd,nbadmx,ndp,idp,nds,ids,ioffc)  !cfbr,
ccccEGBERT
ccc    Change call to mk_offset, and replace mk_offst.f with new version
ccc     declare dt (output by mk_offset, and used by pshftsd) as real
           call mk_offset(time_int,iset_offset,sampfreq,dt)
ccccEGBERT
c      write(6,*) 'TIME_INTERVAL',time_int
c      write(6,*) 'ISET_OFFSET',iset_offset

c     set up fft tables
      do id = 1,nd
         call cffti(nwin(id),wsave(1,id))
      enddo

c     initialize various arrays
      do i = 1,nd
         lwinst(i) = .true.
      enddo
      nuse = 0
      nmsmx = nwmx

c    get first block of data and set up pointers at start of processing
c    also, if too large a data gap occurs return to stmt. 90
c    and reset pointers


      lfirst = .true.
85    continue
      if(lseed) then
         call align_SEED(npts,nch,ix1,ierr)
         call rdblk_seed(npts,nch,ix1,ierr)
         if(npts .le. 0 ) then
            write(0,*) 'Terminating after initial read'
            write(0,*) 'npts,ierr',npts,ierr
            stop
         endif
      else
         call rdblk(npts,ix1,ierr,nch)
      endif
      if(ierr.eq.-1) go to 300
      irec1 = ix1(1,1)
         write(6,*) 'Time interval since t0',time_int
         write(6,*) 'First sample number ',irec1

90    call pterst(irec1,ifirst,ifirstd,next,lstart,lstartd)
      write(0,*) 'Setup Complete'

c>>>>>>>>>>>>>>>main loop starts here >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        ifrec = 0
100     continue
        
c     call decimation routine
        call dcimte(ix1,npts,xx,nchp1,nxxmx,ifirst,ifirstd,next,lstart
     &    ,lstartd,nacc,rmsval)
                           
      do 200 id = 1,nd
      if(nfuse(id) .gt. 0) then
c     compute number of sets accumulated at decimation level id
c    (will ususally be 1 or 0)
      nsets = (nacc(id) - olap(id) - 2*npwmx(id) - missmx(1,id)/2)
     &                           / ( nwin(id) - olap(id) )
         do 190 i = 1,nsets                                  
c          make set i at decimation level id; return in array x
           call mkset(xx,nchp1,nxxmx,ifirst,x,nwmx,ist,id,irec,lrec,
     &                rmsval,lgood,roff)

            ist = ist + iset_offset(id)
c   need to decide if set contains data segmenta which should not be
c   processed (declared in bad record file brsta###x)
           call badrec(nd,ndp,idp,id,irec,lrec,lg)
           if (lgood.and.lg) then
c       set is "good" (i.e. not too many missing data points; not
c       among the bad record ranges); proceed with processing

c   first difference,demean, window, and fourier transform data 
             n = nwin(id)
             nmen=n+npwmx(id)-1
             call demean(x,nch,nmen)
             call frstdif(x,nch,n,lfd,id,areg,npw(1,id),rr,ar,br,bwo)
             call demean(x,nch,n)
             call ps1win(x,nch,n,lwinst(id),w(1,id))
             call fftnp2(n,nch,x,wrk,wsave(1,id))

c   correct for filters (decimation, first differencing) and normalize
c   fourier coefficients to have units of nt/(sqrt(hz))
c   [ uses table of transfer function coefficients stored in complex
c     array rnrmt ]
            nfmid = nfuse(id)
            call filtcor(x,nch,nfmid,id,rnrmt,nd,areg,npw(1,id),n,lfd)
            nfreq = nfmid

CCCCC   WHAT IS CORRECT HERE ??????
ccccEGBERT
ccc ADD THIS CALL ... and include new subroutine pshftsd.f
cc      correct for offsets in actual sampling times

ccc      for seed files need to correct for offsets in actual sampling
ccc       times relative to nominal sampling times
             if(lseed) then
ccc             use seed version
                call pshftsd(x,nfreq,nch,samprate(id),nwin(id),irec)
             else
               call phs_shft(dt,x,nfreq,nch,samprate(id),nwin(id))
             endif
 
ccccEGBERT

c        if necessary correct for clock drifts
              if(lclkd) then          
                 tset = ((irec+lrec)/2. - iclk0)*samprate(1)
                 call cldrft(x,nfreq,nch,samprate(id)
     &              ,nwin(id),cdb,tset)
              endif

c     if necessary correct for offset of begining of set (caused by
c        non-integer set overlap)
              if(abs(roff) .gt. 1.0e-5) then
                 roff = - roff * samprate(1)
                 call cldrft(x,nfreq,nch,samprate(id)
     &              ,nwin(id),1.0,roff)
              endif

c       check to see if set contains segments which should not be stacked
c       if so indicate by making set number negative
              call badrec(nd,nds,ids,id,irec,lrec,lg)
              if( .not. lg) ist = - abs(ist)

c         output fourier coefficients to scratch file f_sta###x
              call freqout(nch,nfreq,x,ifrec,nsmax,nfusemx,
     &            x_scr,iuse_scr)

c         add abs(FCs) to array to compute scalling factor for output
              call l1spec(nch,x,nfreq,pspecl1(1,1,id),nchmx)
              nspec(id) = nspec(id) + 1

c         update array ifdir (which will be used to sort out fourier coefficients
c         at end of program)
              nuse = nuse + 1
              ifdir(1,nuse) = id + idoff
              ifdir(2,nuse) = nfreq
              ifdir(3,nuse) = ist
c     check for overflow of nsmax (maximum # of sets
              if (nuse.eq.nsmax) then
                 write(*,232) nsmax
 232   format(/,'!!!  Number of processed sets reached',/,
     &          '     maximum number of allowed sets !!!',/,
     &          '     The program will finish processing now',/,
     &          '     To process all data change NSMAX =',i6,/,
     &          '     in file PARAMS1.INC !!!')
                 goto 300

               endif
c              print*,'good',irec,lrec,id,ist
c           else
c              print*,'bad',irec,lrec,id,ist
           endif
190     continue
        endif
200     continue
c    get more data and go back to top of main loop
      if(lseed) then
         call rdblk_seed(npts,nch,ix1,ierr)
      else
         call rdblk(npts,ix1,ierr,nch)
      endif
                    
c     ierr = 0 for normal read
        if(ierr.eq.0) then
           lfirst = .false.
           go to 100
        endif

c      ierr = -3 when there is a gap in the record numbers that is so
c large that it is most reasonable to start the decimation filtering over
        if(ierr.eq. -3) then
           if(lseed) then
              lfirst = .true.
              go to 85
           else
              go to 90
           endif
        endif

c     ierr = -2 means the record numbers jump backwards; the program doesn't
c    know what to do about this and stops
ccc     won't happen with seed files
        if(ierr.eq.-2) then
            print*,'error: excess records/ incorrect time mark'
            print*,'stopping here'
        endif
  
300     continue

c<<<<<<<<<<<<<<<<<<< end of main loop <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      print*,'number of sets = ',nuse
        
c***********************
c       reorder f_ file by frequency
c*************************

c       close connection to data file
      close(in_unit)
c       reorder and output file of fourier coefficients
c      l1 power spectrum
      do 490 i = 1,nd
      do 490 j = 1,nch
      do 490 k = 1,nfuse(i)
         if(lpack) then
            pspecl1(j,k,i) = pspecl1(j,k,i)/nspec(i)
         else
            pspecl1(j,k,i) = 1000.
         endif
490      continue

ccc    eliminate decimation levels with nfuse(id) = 0
      iid = 0
      do id = 1,nd
         if(nfuse(id) .gt. 0) then
            iid = iid + 1
            idl(iid) = idl(id)
            nwin(iid) = nwin(id)
            samprate(iid) = samprate(id)
         endif
      enddo

c      header for FC file
      irlo = 4*(nch+1)
      call wfhead(nch,iid,nfmax,nwin,samprate,idl
     1   ,chid,orient,decl,stcor,irlo)

c       read in scratch file, reorder pack if requested, output        
C     ME 	REMOVE SCRATCH FILE
c      call mkseq(ioscr,iouout,ifdir,iset,nuse,nch,nd,
c     1 cwrk,cout,nfusemx,idoff,pspecl1,nchmx,nwmx,lpack,iwrk,ixs)
      print*,'CALL MKSEQ, NFUSEMX ',nfusemx
      call mkseq(ifdir,iset,nuse,nch,nd,
     1 cwrk,cout,nfusemx,idoff,pspecl1,nchmx,nwmx,lpack,iwrk,ixs,
     2 nsmax, x_scr, iuse_scr)
C     ME 	REMOVE SCRATCH FILE        
c       close files; delete f_file on closing
      close(out_unit)
C ME 	REMOVE SCRATCH FILE
c      close(ioscr,status = 'delete')
C ME 	REMOVE SCRATCH FILE
500   continue


      if(.not.lseed) then
         print*,'FT another data file?'
         read(5,'(a1)') ans
         if(ans.eq.'y') go to 1000
      endif
      stop
      end
