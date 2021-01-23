function [day] = julday(mo_da_yr);

mday = [ 31 28 31 30 31 30 31 31 30 31 30 31 ];
if mo_da_yr(3)-4*floor(mo_da_yr(3)/4) == 0
  mday(2) = 29;
end

day = 0;
for k=1:mo_da_yr(1)
  day = day + mday(k);
end
day = day + mo_da_yr(2);
end