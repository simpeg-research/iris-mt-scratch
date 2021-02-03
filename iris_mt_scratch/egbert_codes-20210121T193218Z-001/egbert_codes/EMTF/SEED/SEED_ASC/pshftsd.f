ccc_____________________________________________________________________
ccc
      subroutine pshftsd(x,nfreq,nch,dr,nwin,start_rec)
     
ccc   subroutine corrects for offsets in sampling times in seed files
ccc   almost the same as phs_shft; special version for seed files
ccc   allows for possible changes in time shifts during run.

      include 'seed.inc'

      complex tc,t
      real x(nch,2,nfreq),dr,t1,pi2
      integer nwin,start_rec
      parameter(pi2 = 6.28318)                      

      do j = 1,nch
ccc      check to see if starting record number is past next
ccc      sampling phase shift change
ccc      NOTE: assuming here that we won't ever have to jump
ccc         forward more than one segment (i.e., every shift
ccc         in the phase has at least one data set)
ccc      ALSO:  we shift to the next phase when the first set
ccc         with starting record past the limit is found ...
ccc         this will always be a level 1 set; some higher level
ccc         sets with earlier starts will still be accumulating
ccc        data ... but phase correction should be small for higher
ccc        level sets, these sets (if any) will stradle the change, etc.
         if(start_rec .ge. dt_chng_rec(j,dt_chng_i(j))) then
            dt_chng_i(j) = dt_chng_i(j) + 1
         endif 

ccc      now do the phase shift 
         t1 =   -pi2*(dt0 + dt(j,dt_chng_i(j)))/(dr*nwin)
         do i = 1,nfreq
            tc = cmplx(cos(i*t1),sin(i*t1))
            t = tc*cmplx(x(j,1,i),x(j,2,i))
            x(j,1,i) = real(t)
            x(j,2,i) = aimag(t)
         enddo
      enddo
      return
      end
