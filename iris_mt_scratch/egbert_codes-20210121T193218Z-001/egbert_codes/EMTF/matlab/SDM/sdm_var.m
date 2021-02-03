function [var,sig] = sdm_var(S,grouping,ih,chid)
% Usage: [var,sig] = sdm_var(S,grouping,ih,chid);

nsta = length(ih);
[dum,nt] = size(chid);
[dum,dum,nb] = size(S);
%   find indices where components in list change from E to H or H to E
switch grouping
  case 'standard'
    Hnum = 72; Enum = 69;
    temp = fix(chid(1,:));
    ind = (temp == Hnum) - (temp == Enum);
    ind = ind(1:nt-1).*ind(2:nt);
    ind = 1+find(ind == -1);
    for ista = 1:nsta
      if(sum(ind == ih(ista) ) == 0)
         ind = [ind ih(ista)]
      end
    end
    ind = sort(ind);
  case 'all'
    ind = [1:nt]
  otherwise
       fprintf(1,'%s \n','Case Not Coded in evecCbk')
end
  
ngrp = length(ind)
ind = [ind nt+1];
var = zeros(nt,nb);
sig = zeros(nt,nb);
dmu = .9;
o = ones(nt,1);
pmax = 1.0001; pmin = .2;
for ib = 1:nb
   TF = zeros(nt,nt);
   v = zeros(nt,1);
   for igrp = 1:ngrp
      i1 = ind(igrp);
      i2 = ind(igrp+1)-1;
   
      II = [i1:i2];
      JJ = [1:i1-1 i2+1:nt];
      S11 = S(II,II,ib);
      S22 = S(JJ,JJ,ib);
      S12 = S(II,JJ,ib);

      TF(II,JJ) = S12/S22;
      S1g2 = S11 - (S12/S22)*S12';
      v(II) = real(diag(S1g2));
      sig(II,ib) = real(diag(S11));
   end
   mu = 1;
   done = 0;
   while 1-done
      X = mu*abs(TF).*abs(TF);
      X = diag(1./v)*X*diag(v) + eye(nt);
      vhat = X\o; 
      if(max(vhat) > pmax | min(vhat) < pmin )
         mu = mu*dmu ;
      else
         done = 1;
      end
      var(:,ib) = vhat.*v;
    end
end
