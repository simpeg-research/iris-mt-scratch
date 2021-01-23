c______________________________________________________________________
c
      subroutine init_files(cf_station,
     &   cfin,nch,doy_start,hr_start,min_start,sec_start)
      include 'seed.inc'
      include '../../D/iounits.inc'
c      character*80 cfsp,cfbr,cfdecset,cfpwset,cfout
      character*80 cfin(*),cf_station,cfile_TERR
      character*40 ctemp,croot
      character*2 cfn
      character*3 cfn2
      integer doy_start,hr_start,min_start,sec_start
      logical lpath
c       cfsp, cfbr,cfdecset,cfpwset are path/file names for
c       system params, bad recs,decset,pwset, and output file

ccc   open "station" file ... list of components, order, # of channels etc.
ccc   name of station file is input to routine as cf_station
      open(unit = 99,file = cf_station,status='old')
ccc   first line is number of data channels, starting reference time
ccc   (i.e., survey start time ... for combining with other EMI data
      read(99,*) nch,doy_start,hr_start,min_start,sec_start
      do ich = 1,nch
ccc      then one line for file name of each data channel
         read(99,'(a80)') cfin(ich)
      enddo
ccc   system parameter file
      read(99,'(a80)') cfsp
ccc   output station name root
      read(99,'(a40)') croot
      close(99)

ccc   mi is length of data file name with blanks stripped off
      mi = iclong(croot,40)
ccc   mr is length of "file root" -- data file name with suffix (beginging
ccc     with a dot (.) and any blanks stripped off
      mr = irlong(croot,40)
 
ccc   next see if there is a TERR_ file 
      cfile_TERR = 'MMT/TERR_'//croot(mi-2:mi)//'a'
      open(unit=99,file = cfile_TERR,status='old',err=10)
      read(99,*,err=10)
      read(99,*,err=10) idum,dt0
      write(0,*) 'dt0 = ',dt0
      close(99)
      go to 15
10    dt0 = 0.
15    continue

ccc   now look for paths.cfg file ... tells where to look for data,
ccc   where to put output FC files, where to find decimation control
ccc   files, etc.
      open(unit=pth_unit,file='paths.cfg',status='old',err=20)
      lpath = .true.
      go to 25
20    lpath = .false.
25    continue

ccc   make full names for data files using path from data directory + names
ccc   from cf_station file
      md = 0
      if(lpath) then
         read(pth_unit,'(a40)',err = 30) ctemp
         md = iclong(ctemp,40)
      end if
30    continue
      if(md.gt.0) then
ccc      prepend data directory path to file names in cfin(nch)
         do ich = 1,nch
            mi = iclong(cfin(ich),80)
            cfin(ich) = ctemp(1:md)//'/'//cfin(ich)(1:mi)
         enddo
      end if

ccc   system parameter directory (In all cases blank field => localdirectory)
ccc   NOTE:  SEED Version uses sp file name from SEED control file,
ccc     can't make the file name up from the data file ... 
      md = 0
      if(lpath) then
         read(pth_unit,'(a40)',err = 40) ctemp
         md = iclong(ctemp,40)
      endif
40    continue
      if(ctemp(1:8).eq.'standard') then
         cfsp='standard.sp'
      else
         if(md.gt.0) then
            msp = iclong(cfsp,80)
            cfsp = ctemp(1:md)//'/'//cfsp(1:msp)
         end if
      endif

ccc   bad record directory
      md = 0
      mi = iclong(croot,40)
      if(lpath) then
         read(pth_unit,'(a40)',err = 50) ctemp
         md = iclong(ctemp,40)
      end if
50    continue
      if(md.gt.0) then
         cfbr = ctemp(1:md)//'/'//croot(1:mr)//'.bad'
      else
         cfbr = croot(1:mr)//'.bad'
      end if
c      decset file (full path name)
      md = 0
      if(lpath) then
         read(pth_unit,'(a80)',err = 60) cfdecset
         md = iclong(cfdecset,80)
      end if
60    continue
      if(md.eq.0) then
         cfdecset = 'decset.cfg'
      end if

ccc   pwset file (full path name)
      md = 0
      if(lpath) then
         read(pth_unit,'(a80)',err = 70) cfpwset
         md = iclong(cfpwset,80)
      end if
70    continue
      if(md.eq.0) then
         cfpwset = 'pwset.cfg'
      end if

ccc   output FC file name
      md = 0
      if(lpath) then
         read(pth_unit,'(a40)',err = 80) ctemp
         md = iclong(ctemp,40)
      end if
80    continue
      if(nch.lt.10) then
         write(cfn,'(a1,i1)') 'f',nch
      else
         write(cfn2,'(a1,i2)') 'f',nch
      endif
      if(md.gt.0) then
         if(nch.lt.10) then
            cfout = ctemp(1:md)//'/'//croot(1:mr)//'.'//cfn
         else
            cfout = ctemp(1:md)//'/'//croot(1:mr)//'.'//cfn2
         endif
      else
         if(nch.lt.10) then
            cfout = croot(1:mr)//'.'//cfn
         else
            cfout = croot(1:mr)//'.'//cfn2
         endif
      end if
      close(pth_unit)
      return
      end
