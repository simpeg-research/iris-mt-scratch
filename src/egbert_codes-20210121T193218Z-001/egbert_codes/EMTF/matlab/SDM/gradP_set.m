%load UVP_SNR96-97b
load UVP_SNR96-97
load SDMS_2H_96
bad_2H;
bad_96 = bad;
bad_ch_96 = bad_ch;

[nt,nb,nh,nday] = size(SDMS.var);

Neig = squeeze(sum(abs(Up_snr(1,:,:)) > 0 , 2))
g = 2*ones(nb,1);
grad_pwr96 = zeros(nb,nh,nday);
T = SDMS.T;
for id = 1:nday
  for hr = 1:nh
     good_ch = 1 - squeeze(bad_ch_96(:,1,hr,id));
     if(sum(good_ch) >= 8)
        S = SDMS.S(:,:,:,hr,id);
        ind = find(good_ch);
        [S_UV] = UVpwrM(S,var_AVG,U_snr,Up_snr,Neig,ind);
        [S_UV] = [S_UV];
        grad_pwr96(:,hr,id) = 10*log10(squeeze(S_UV(3,:) + S_UV(4,:))+1);
     end
   end
end

load SDMS_2H_97
bad_2H
bad_97 = bad
bad_ch_97 = bad_ch;

[nt,nb,nh,nday] = size(SDMS.var);

Neig = squeeze(sum(abs(Up_snr(1,:,:)) > 0 , 2))
grad_pwr97 = zeros(nb,nh,nday);
T = SDMS.T;
for id = 1:nday
  for hr = 1:nh
     good_ch = 1 - squeeze(bad_ch_97(:,1,hr,id));
     if(sum(good_ch) >= 8)
        S = SDMS.S(:,:,:,hr,id);
        ind = find(good_ch);
        [S_UV] = UVpwrM(S,var_AVG,U_snr,Up_snr,Neig,ind);
        grad_pwr97(:,hr,id) = 10*log10(squeeze(S_UV(3,:) + S_UV(4,:))+1);
     end
   end
end

nband = 7;
band1 = 6;
bandstep = 2;
grad_pwr = zeros(nband,12,74);
tind = [5:12,1:4];
wt1 = .25;wt0 = .5;
%wt1 = 0;wt0 = 1;
for k=1:nband
  bm = band1 + bandstep*k -2;
  b0 = band1 + bandstep*k-1 ;
  bp = band1 + bandstep*k ;
  grad_pwr(k,:,1:37) = wt1*grad_pwr96(bm,tind,:) + ...
                       wt0*grad_pwr96(b0,tind,:) + ...
                       wt1*grad_pwr96(bp,tind,:);
  
  grad_pwr(k,:,38:74)= wt1*grad_pwr97(bm,tind,:) + ...
                       wt0*grad_pwr97(b0,tind,:) + ...
                       wt1*grad_pwr97(bp,tind,:) ;
  PER(k) = T(b0);
end

grad_pwr = grad_pwr(1:6,:,:);
PER = PER(1:6)

ctitle='Power In Gradients  vs. Time of Day and Julian Day : 1996-1997'
clim = [0,18];
hfig = Pplot6(grad_pwr,PER,clim,ctitle)
