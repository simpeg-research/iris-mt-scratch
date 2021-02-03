ccc_____________________________________________________________________
ccc
      subroutine wrt_time(time)
      include 'seed.inc'
      record /INT_TIME/time
      write(0,*) time.second, time.ticks
      return
      end
