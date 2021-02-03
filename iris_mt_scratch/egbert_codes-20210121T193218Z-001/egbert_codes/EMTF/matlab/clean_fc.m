%  cleans up spikes in Fourier domain by using each 
%  group of two channels specified in ch_groups
%  to predict data in each channel;  with two full 5-channel
%  stations call with one group for each horizontal e or h pair
%   (for a total of 4 groups).  This will result in 4 estiamtes
%  for each channel (including the actual data).  If the data differs
%  significantly from the other three predictions, replace
%   data with l1 norm minimizing fit to other three predictions.
%  works on a single frequncy band, with U already defined for this
%   band (ncht rows by 2 columns)
% 
%usage :   function [fcc] = clean_fc(fc,Pall,ch_groups,niter)
function [fcc,temp,wttemp] = clean_fc(fc,U,ch_groups,niter)
[ngroups,dum] = size(ch_groups);
%  wt0 is the cut off for replacing a FC by prediction 
%  unless there is one odd point wt should be near 1/ngroups ...

itst = 7;
%replace points by prediction if abs deviation from l1 estimate
%   exceeds average deviation of individual predictions by a factor
%   of devmx
devmx = 3.;
fac = devmx/(ngroups-1);

wt = ngroups*ones(size(fc));
fc_l1 = zeros(size(fc));
for ig = 1:ngroups
   grp = ch_groups(ig,:);
   ug_inv = inv(U(grp,:));
   
%   eval( [ 'tf' num2str(ig) ' = U*ug_inv ' ] );
%   eval( [ 'fc' num2str(ig) ' = tf' num2str(ig) 'fc(grp,:)' ] );
   tf = U*ug_inv;
   eval( [ 'fc' num2str(ig) ' = tf * fc(grp,:);' ] )
   eval( [ 'w' num2str(ig) ' = ones(size(fc)); ' ] )
   eval( [ 'fc_l1 = fc_l1 + fc' num2str(ig) ';' ] )
end
%  average of all predictions ...
fc_l1 = fc_l1/ngroups ;

%   now iteratively compute weights ...
for iter = 1:niter
   for ig = 1:ngroups
      eval( [ 'w' num2str(ig) ' = 1./abs(fc_l1 - fc' num2str(ig) ');' ] )
   end
   wt = zeros(size(fc));
   fc_l1 = wt;
   for ig = 1:ngroups
      eval( [ 'wt = wt + w' num2str(ig) ';' ] )
      eval( [ 'fc_l1 = fc_l1 + fc' num2str(ig) '.*w' num2str(ig) ';' ] )
   end
   fc_l1 = fc_l1 ./ wt;
end
%  turn weights back into distance
wsum = zeros(size(fc));
for ig=1:ngroups
   eval( [ 'w' num2str(ig) ' = 1./ w' num2str(ig) ';' ] )
   eval( [ 'wsum = wsum + w' num2str(ig) ';' ] )
end
wt = ones(size(fc));
for ig = 1:ngroups
   grp = ch_groups(ig,:);
%  now zero out those elements of the final weighting array for
%  which the actual data was "odd man out"
   eval( [ 'wt(grp,:) = w' num2str(ig) ...
       '(grp,:) < (wsum(grp,:) - w' num2str(ig) '(grp,:))*fac;']  )
end
temp = [ fc1(itst,:);fc2(itst,:);fc3(itst,:);fc4(itst,:);fc_l1(itst,:)];
wttemp = [w1(itst,:);w2(itst,:);w3(itst,:);w4(itst,:);wt(itst,:)];

% make cleaned data array
fcc = fc.*wt + fc_l1.*(1-wt);
end
