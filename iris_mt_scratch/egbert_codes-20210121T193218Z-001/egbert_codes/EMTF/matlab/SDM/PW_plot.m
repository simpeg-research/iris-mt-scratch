
%  plot MT power vs time of day/year for PKD/SAO array
load PW_2H_96
PWHD_96 = PWHD;
[dum,nt,nb,nh,nday] = size(PW.tf);

HH96 = zeros(3,2,nb,nh,nday)+i*zeros(3,2,nb,nh,nday);
for day = 1:nday
  for hr = 1:nh
     for band = 1:nb
        HH96(:,:,band,hr,day) = PW.tf(:,6:8,band,hr,day)'/PW.tf(:,1:2,band,hr,day)';
     end
   end
end
nday96 = nday;

load PW_2H_97
HH97 = zeros(3,2,nb,nh,nday)+i*zeros(3,2,nb,nh,nday);
for day = 1:nday
  for hr = 1:nh
     for band = 1:nb
        HH97(:,:,band,hr,day) = PW.tf(:,6:8,band,hr,day)'/PW.tf(:,1:2,band,hr,day)';
     end
   end
end

load UVP_SNR96-97
TFsmth = zeros(3,2,nb);
for ib = 1:nb
   U = U_snr(:,:,ib);
   sig = sqrt(var_AVG(:,ib));
   U = diag(sig)*U;
   TFsmth(:,:,ib) = U(6:8,:)/U(1:2,:);
end
nday = nday+nday96;

nband = 6;
band1 = 6;
bandstep = 1;
HyHy = zeros(nband,nh,nday)+i*zeros(nband,nh,nday);
HxHx = zeros(nband,nh,nday)+i*zeros(nband,nh,nday);
HyHx = zeros(nband,nh,nday)+i*zeros(nband,nh,nday);
HzHx = zeros(nband,nh,nday)+i*zeros(nband,nh,nday);
tind = [5:12,1:4];
%wt1 = .25; wt0 = .5;
wt1 = .0; wt0 = 1;
for k=1:nband
  bm = band1 + bandstep*k -2;
  b0 = band1 + bandstep*k-1 ;
  bp = band1 + bandstep*k ;
%  here x is geographic north ...
  HxHx(k,:,1:nday96) =  wt1*HH96(2,2,bm,tind,:) + ...
                       wt0*HH96(2,2,b0,tind,:) + ...
                       wt1*HH96(2,2,bp,tind,:);
  HyHy(k,:,1:nday96) =  wt1*HH96(1,1,bm,tind,:) + ...
                       wt0*HH96(1,1,b0,tind,:) + ...
                       wt1*HH96(1,1,bp,tind,:);
  HxHx(k,:,nday96+1:nday) =  wt1*HH97(2,2,bm,tind,:) + ...
                       wt0*HH97(2,2,b0,tind,:) + ...
                       wt1*HH97(2,2,bp,tind,:);
  HyHy(k,:,nday96+1:nday) =  wt1*HH97(1,1,bm,tind,:) + ...
                       wt0*HH97(1,1,b0,tind,:) + ...
                       wt1*HH97(1,1,bp,tind,:);

  HyHx(k,:,1:nday96) =  wt1*HH96(1,2,bm,tind,:) + ...
                       wt0*HH96(1,2,b0,tind,:) + ...
                       wt1*HH96(1,2,bp,tind,:);
  HyHx(k,:,nday96+1:nday) =  wt1*HH97(1,2,bm,tind,:) + ...
                       wt0*HH97(1,2,b0,tind,:) + ...
                       wt1*HH97(1,2,bp,tind,:);

  HzHx(k,:,1:nday96) =  wt1*HH96(3,2,bm,tind,:) + ...
                       wt0*HH96(3,2,b0,tind,:) + ...
                       wt1*HH96(3,2,bp,tind,:);
  HzHx(k,:,nday96+1:nday) =  wt1*HH97(3,2,bm,tind,:) + ...
                       wt0*HH97(3,2,b0,tind,:) + ...
                       wt1*HH97(3,2,bp,tind,:);

  HxHx(k,:,:) = conj(HxHx(k,:,:)) - TFsmth(2,2,b0);
  HyHy(k,:,:) = conj(HyHy(k,:,:)) - TFsmth(1,1,b0);
  HyHx(k,:,:) = conj(HyHx(k,:,:)) - TFsmth(1,2,b0);
  HzHx(k,:,:) = conj(HzHx(k,:,:)) - TFsmth(3,2,b0);
  PER(k) = PW.T(b0);
end

   
%clim = [.7,1.5];
clim = [-.4,.4];
ctitle = 'Hx/Hx TF (Imag) Deviations From Smooth TF : 1996-1997'
   mask = zeros(nh,nday) ;
   mask(:,31:42) = 1;
   mask(6:8,20:22) = 1;
   mask(:,4) = 1;
   mask(:,17) = 1;
   mask(:,58) = 1;
   mask(:,71:74) = 1;
   mask(:,6) = 1;

hfig = Pplot1(imag(HxHx),PER,clim,ctitle,mask)

%clim = [.7,1.5];
clim = [-.4,.4];
ctitle = 'Hx/Hx TF (Real) Deviations From Smooth TF : 1996-1997'

hfig = Pplot1(real(HxHx),PER,clim,ctitle,mask)

%clim = [.7,1.5];
clim = [-.2,.2];
ctitle = 'Hy/Hx TF (Real) Deviations From Smooth TF : 1996-1997'

hfig = Pplot1(real(HyHx),PER,clim,ctitle,mask)

%clim = [.7,1.5];
clim = [-.2,.2];
ctitle = 'Hz/Hx TF (Real) Deviations From Smooth TF : 1996-1997'

hfig = Pplot1(real(HzHx),PER,clim,ctitle,mask)

%clim = [.7,1.5];
clim = [-.2,.2];
ctitle = 'Hy/Hx TF (Imag) Deviations From Smooth TF : 1996-1997'

hfig = Pplot1(imag(HyHx),PER,clim,ctitle,mask)

%clim = [.7,1.5];
clim = [-.2,.2];
ctitle = 'Hz/Hx TF (IMag) Deviations From Smooth TF : 1996-1997'

hfig = Pplot1(imag(HzHx),PER,clim,ctitle,mask)
