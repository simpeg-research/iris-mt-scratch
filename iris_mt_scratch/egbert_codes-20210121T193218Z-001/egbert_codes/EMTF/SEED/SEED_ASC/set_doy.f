      subroutine set_doy(doy_start)
      include 'seed.inc'
ccc   KLUGE to make seed_merge_asc work without (a) thinking to hard)
ccc     (b) breaking dnff_seed

      integer doy_start
      doy0 = doy_start
      return
      end
