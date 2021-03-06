      subroutine resptbl1(cfrsp,j,imode,igain,freq,resp,ijob)

CME	31/8/96
C	System response files for PAB (j=17) and MFS05 (j=18) included
C	Account for different headers of the calibration data files
C	and for inverse sequence of frequencies

cnew	added reading from generic table files. j =98 is a table of amplitudes
cnew	and phases, j=99 is one of real and imaginary part. Both modes asume
cnew	that any header information has non-numeric characters in
cnew	the first non-white-space position of a line.

      integer nfreq(3),j,imode,igain
      complex resp
      real tbl(3,9,0:150), temptbl(3)
      integer rsp_unit
      character*80 chead
      character*80 cfrsp
      save tbl,nfreq

      rsp_unit = 37
      if(ijob.eq.0) then
c        open the response table file
         open(unit=rsp_unit,file=cfrsp,status='old',err = 222)
         if (j.eq.7 .or. j.eq.8) then
c     read in table of system reponses
c     emi mt-1 response tables
            read(rsp_unit,'(a80)')
            read(rsp_unit,'(a80)')
            read(rsp_unit,'(a80)')
            read(rsp_unit,'(a80)')
            read(rsp_unit,'(a80)')
            if(j.eq.7) then
               do 20 k = 1,3
                  read(rsp_unit,*) nfreq(k)
                  do l = 1,nfreq(k)
                     read(rsp_unit,*) (tbl(k,i,l),i=1,9)
ccc             Change sign of response read from EMI ef sensors file
ccc             to account for minus sign in E = -dV/dx (and to make
ccc             system response correction consistent with P/Z response
ccc             in SEED volumes
                     do i = 2,9
                        tbl(k,i,l) = -tbl(k,i,l)
                     enddo
                  enddo
                  tbl(k,1,0) = 0.
                  do i = 2,9
                     tbl(k,i,0) = tbl(k,i,1)
                  enddo
 20            continue
            else		! j = 8
               read(rsp_unit,*) nfreq(1)
               do k = 1,nfreq(1)
                  read(rsp_unit,*) (tbl(1,i,k),i=1,3)
               enddo
               tbl(1,1,0) = 0.
               do i = 2,3
                  tbl(1,i,0) = tbl(1,i,1)
               enddo
               imode = 1
               igain = 1
            end if

C	this is PDAS/SPAM format of table files
         else if (j.ge.17 .and. j.lt.98) then
            chead = ' '
            do while (chead(1:5).ne.'-----')
               read(rsp_unit,'(a80)') chead
            end do
            read(rsp_unit,'(a80)') chead
            do k=1,150
               read (rsp_unit,*,end=500,err=500) (tbl(1,i,k),i=1,3)
            end do
 500        nfreq(1) = k-1
            nnfreq = nfreq(1)/2 + mod(nfreq(1),2)
C-PDAS invert sequence of frequencies
            do k=1,nnfreq
               do i = 1,3
                  temptbl(i) = tbl(1,i,k)
                  tbl(1,i,k) = tbl(1,i,nfreq(1)+1-k)
                  tbl(1,i,nfreq(1)+1-k) = temptbl(i)
               end do
            end do
            tbl(1,1,0) = 0.
            do i = 2,3
               tbl(1,i,0) = tbl(1,i,1)
            end do
            imode = 1 
            igain = 1
c     end of pdas/mms05 table reading
 
cnew	this is the generic amplitude/phase or real/imaginary table
         elseif (j.eq.98 .or. j.eq.99) then
            read (rsp_unit,'(a80)') chead
cnew	skip all lines whic have non-numeric characters as first 
cnew	non-white-space character (icfirst is integer function in inpu_bin.f)
            do while (
     &           ichar(chead(icfirst(chead,80):icfirst(chead,80)+1))
     &           .lt.48 .or.
     &           ichar(chead(icfirst(chead,80):icfirst(chead,80)+1))
     &           .gt.57 )
               read (rsp_unit,'(a80)') chead
            enddo
            backspace(rsp_unit)
            do k=1,150
               read (rsp_unit,*,end=501,err=501) (tbl(1,i,k),i=1,3)
            end do
 501        nfreq(1) = k-1
cnew 	check if frequencies increase, if not invert
            if (tbl(1,1,1) .gt. tbl(1,1,nfreq(1))) then
               nnfreq = nfreq(1)/2 + mod(nfreq(1),2)
               do k=1,nnfreq
                  do i = 1,3
                     temptbl(i) = tbl(1,i,k)
                     tbl(1,i,k) = tbl(1,i,nfreq(1)+1-k)
                     tbl(1,i,nfreq(1)+1-k) = temptbl(i)
                  end do
               end do
               tbl(1,1,0) = 0.
               do i = 2,3
                  tbl(1,i,0) = tbl(1,i,1)
               end do
            endif
            imode = 1 
            igain = 1
         end if
         
               

         close (rsp_unit)
         return
         
      else		!  (ijob .eq. 1)

c      interpolate frequency
         ip = 2*igain+1
         ig = ip-1
         do 40 i=0,nfreq(imode)-1
            if((tbl(imode,1,i).lt.freq).and.
     &           (freq.le.tbl(imode,1,i+1)))then
               w=(tbl(imode,1,i+1)-freq)/(tbl(imode,1,i+1)-
     &              tbl(imode,1,i))
               g = tbl(imode,ig,i)*w+tbl(imode,ig,i+1)*(1.-w)
               p = tbl(imode,ip,i)*w+tbl(imode,ip,i+1)*(1.-w)
cnew	if j = 99 the table is alredy in real/imaginary style
               if (j.eq.99) then
                  resp = cmplx(g,p)
               else
                  resp = cmplx(0.,3.14159*p/180.)
                  resp = g*cexp(resp)
               endif
               return
            end if
 40      continue
         print*,'resptbl failed'
         stop
      end if
 222  print*,' ERROR OPENING RSP-FILE ! looked up in SENSORS'
      write(*,*)cfrsp
      end
