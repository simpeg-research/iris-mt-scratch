function [S] = terrFix(dt,sgn,ih,S,T)

%  time shift dt is error in phase at each site
%  sgn is sign shift at each site (-1 to flip)
%   (or could be more general time shift)
nsta = length(ih);
nbt = length(T);
ii = size(S);
ncht = ii(1);
ih1 = [ ih ncht+1];
for ista = 1:nsta
   ph = sgn(ista)*exp(-i*dt(ista)*2*pi./T);
   for j = ih1(ista):ih1(ista+1)-1
      for k = 1:ncht
         S(j,k,:) = squeeze(S(j,k,:)).*ph;
         S(k,j,:) = squeeze(S(k,j,:)).*conj(ph);
      end
   end
end




