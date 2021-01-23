%  plot MT power vs time of day/year for PKD/SAO array
load UVP_SNR96-97
load SDMS_2H_96
bad_2H;
bad_96 = bad;
bad_ch_96 = bad_ch;

[nt,nb,nh,nday] = size(SDMS.var);

Neig = squeeze(sum(abs(Up_snr(1,:,:)) > 0 , 2));
g = 2*ones(nb,1);
mt_pwr96 = zeros(2,nb,nh,nday);
T = SDMS.T;
for id = 1:nday
  for hr = 1:nh
     good_ch = 1 - squeeze(bad_ch_96(:,1,hr,id));
     if(sum(good_ch) >= 8)
        S = SDMS.S(:,:,:,hr,id);
        ind = find(good_ch);
        [S_UV] = UVpwrM(S,var_AVG,U_snr,V_snr,Neig,ind);
        mt_pwr96(1,:,hr,id) = 10*log10(squeeze(S_UV(1,:)));
        mt_pwr96(2,:,hr,id) = 10*log10(squeeze(S_UV(2,:)));
     end
   end
end

load SDMS_2H_97
bad_2H
bad_97 = bad
bad_ch_97 = bad_ch;

[nt,nb,nh,nday] = size(SDMS.var);

Neig = squeeze(sum(abs(Up_snr(1,:,:)) > 0 , 2));
mt_pwr97 = zeros(2,nb,nh,nday);
T = SDMS.T;
for id = 1:nday
  for hr = 1:nh
     good_ch = 1 - squeeze(bad_ch_97(:,1,hr,id));
     if(sum(good_ch) >= 8)
        S = SDMS.S(:,:,:,hr,id);
        ind = find(good_ch);
        [S_UV] = UVpwrM(S,var_AVG,U_snr,V_snr,Neig,ind);
        mt_pwr97(1,:,hr,id) = 10*log10(squeeze(S_UV(1,:)));
        mt_pwr97(2,:,hr,id) = 10*log10(squeeze(S_UV(2,:)));
     end
   end
end

nband = 7;
band1 = 6;
bandstep = 2;
mt_pwr = zeros(2,nband,12,74);
tind = [5:12,1:4];
for k=1:nband
  bm = band1 + bandstep*k -2;
  b0 = band1 + bandstep*k-1 ;
  bp = band1 + bandstep*k ;
  for l = 1:2
    mt_pwr(l,k,:,1:37) = .25*mt_pwr96(l,bm,tind,:) + ...
                       .50*mt_pwr96(l,b0,tind,:) + ...
                       .25*mt_pwr96(l,bp,tind,:);
    mt_pwr(l,k,:,38:74)= .25*mt_pwr97(l,bm,tind,:) + ...
                       .50*mt_pwr97(l,b0,tind,:) + ...
                       .25*mt_pwr97(l,bp,tind,:) ;
  end
  mt_pwr(3,k,:,:) = 10.^(mt_pwr(1,k,:,:)/10) +10.^( mt_pwr(2,k,:,:)/10);
  mt_pwr(3,k,:,:) = 10*log10(mt_pwr(3,k,:,:));
  PER(k) = T(b0);
end

%   
%clim = [0,40];
%ctitle = 'Power in MT vec. #1 vs. Time of Day and Julian Day : 1996-1997'
%temp = squeeze(mt_pwr(1,:,:,:));
%msk = temp < 4;
%temp = (1-msk).* temp; 
%hfig = Pplot(temp,PER,clim,ctitle)
%
%clim = [0,40];
%ctitle = 'Power in MT vec. #2 vs. Time of Day and Julian Day : 1996-1997'
%temp = squeeze(mt_pwr(2,:,:,:));
%msk = temp < 4;
%temp = (1-msk).* temp; 
%hfig = Pplot(temp,PER,clim,ctitle)
%
clim = [0,45];
ctitle = 'Total Power in MT fields vs. Time of Day and Julian Day : 1996-1997'
temp = squeeze(mt_pwr(3,:,:,:));
msk = temp < 4;
temp = (1-msk).* temp; 
hfig = Pplot(temp,PER,clim,ctitle)

%temp1 = squeeze(mt_pwr(1,:,:,:));
%temp1 = 10.^(temp1/10);
%temp2 = squeeze(mt_pwr(2,:,:,:));
%temp2 = 10.^(temp2/10);
%temp = zeros(size(temp1));
%for k = 1:nband
%   b0 = band1 + bandstep*k-1 ;
%   u = U_snr(1:2,:,b0);
%   decl = 20+90;
%   c = cos(decl*pi/180); s = sin(decl*pi/180);
%   rot =  [ c s ; -s c ];
%   u_rot = rot*u;
%%   Hx (measurement coord geographic east) at PKD
%%   temp(k,:,:) = (abs(u(1,1)).^2)*temp1(k,:,:) + (abs(u(1,2)).^2)*temp2(k,:,:);
%%   Hx : geomag coord
%%   temp(k,:,:) = (abs(u_rot(1,1)).^2)*temp1(k,:,:) + (abs(u_rot(1,2)).^2)*temp2(k,:,:);
%%   Hy (measurement coord; geographic east) at PKD
%%   temp(k,:,:) = (abs(u(2,1)).^2)*temp1(k,:,:) + (abs(u(2,2)).^2)*temp2(k,:,:);
%%   Hy geomag
%   temp(k,:,:) = (abs(u_rot(2,1)).^2)*temp1(k,:,:) + (abs(u_rot(2,2)).^2)*temp2(k,:,:);
%end
%temp = 10*log10(temp);
%clim = [0,35];
%ctitle = 'MT H_y SNR (PKD; Geomag) vs. Time of Day and Julian Day : 1996-1997'
%%ctitle = 'MT H_x SNR (PKD; Geomag) vs. Time of Day and Julian Day : 1996-1997'
%%msk = temp < 4;
%%temp = (1-msk).* temp; 
hfig = Pplot(temp,PER,clim,ctitle)
