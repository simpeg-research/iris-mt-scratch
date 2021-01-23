%  DEFINE REFERENCE POLARIZATION 
refPolarization = 90;

fs = 11;
ncol = 64;
refP = (90 + refPolarization)*pi/180;
C = [ cos(refP) sin(refP) ; ...
     -sin(refP) cos(refP) ];

%  plot interstation TF vs. time of day and frequency for PKD/SAO array
%%%  2 hour  :  load PW_2H_140-199
load PW_1H_140-199
[dum,nt,nb,nh] = size(PW.tf);

%   load smoothed TFs 
load UVP_SNR96-97
[dum1,dum2,nbSmth] = size(U_snr);
TFtemp = zeros(4,2,nbSmth);
%  and reference to PKD  H
for ib = 1:nbSmth
   U = U_snr(:,:,ib);
   sig = sqrt(var_AVG(:,ib));
   U = diag(sig)*U;
   TFtemp(:,:,ib) = U(5:8,:)/U(1:2,:);
end

%   compute unsmoothed 2 hour average TFs referenced to  PKD H
Tmax = max(T_smth);
Tmin = min(T_smth);
ind_use = PW.T >= Tmin & PW.T <= Tmax;
U_use = PW.tf(:,:,find(ind_use),:);
[dum,nt,nb,nh] = size(U_use);
T = PW.T(find(ind_use));
%  interploate smoothed TFs
TFsmth = zeros(4,2,nb)+i*zeros(4,2,nb);
for k = 1:4
   for l = 1:2
      TFsmth(k,l,:) = interp1(T_smth,squeeze(TFtemp(k,l,:)),T);
   end 
end 

%  compute TFs, subtract reference
TF = zeros(4,nb,nh)+i*zeros(4,nb,nh);
for ih = 1:nh
for ib = 1:nb
   U = U_use(:,:,ib,ih).';
   temp = U(5:8,:)/U(1:2,:);
   temp1 = temp - squeeze(TFsmth(:,:,ib));
%  Rotate Hx/Hy components ...
   temp(2:3,:) = C*temp(2:3,:);
   temp = temp*C(1,:)';
   temp1(2:3,:) = C*temp1(2:3,:);
   temp1 = temp1*C(1,:)';
   TF(:,ib,ih) = temp;
   TFdev(:,ib,ih) = temp1;
end
end
amp = abs(TF);
ph = atan2(imag(TF),real(TF)); 

%%%   2 hour :   tind = [5:12,1:4];
tind = [8:24,1:7];

clim = [-.5,.5];

nband = 4;
hfig = figure('Position',[50,50,600,800],'PaperPosition',[1,1,6,9]);
delete(gca)
x = log10(T);
%%%   2 hour :  y = [1:2:23];
y = [.5:1:23.5];
dx0 = .8;
space = .06;
dy = .85/nband;
dy0 = dy - space;

ib = 1;
   ctitle = ['Hx/Hx TF Real :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(real(TFdev(2,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);
   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');
ib = 2;
   ctitle = ['Hx/Hx TF Imag :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(imag(TFdev(2,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);

   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');
ib = 3;
   ctitle = ['Hy/Hx TF Real :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(real(TFdev(3,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);
   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');
ib = 4;
   ctitle = ['Hy/Hx TF IMag :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(imag(TFdev(3,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);
   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');
   xlabel('log_{10} Period')


%  alternative colormap
   cmap = colmap;
   cmap1 = interp1([1:17],cmap,[1:.25:16.75]);
   cmap1 = flipud(cmap1);
%   cmap1(1,:) = [1 1 1];
   colormap(cmap1);

    cb_rect = [.3,.95-nband*dy-.07,.4,.015];
   clr_bar(cb_rect,clim,ncol);
print -depsc TFdev_90.cps

% Next figure 
clim = [-.20,.20];

hfig = figure('Position',[50,50,600,800],'PaperPosition',[1,1,6,9]);

ib = 1;
   ctitle = ['Hz/Hx TF Real :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(real(TFdev(4,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);
   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');
ib = 2;
   ctitle = ['Hz/Hx TF Imag :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(imag(TFdev(4,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);
   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');

ib = 3;
   ctitle = ['Hz/Hx PKD TF Real :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(real(TFdev(1,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);
   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');
ib = 4;
   ctitle = ['Hz/Hx PKD TF Real :: Deviation :: Days 140-199 :: \theta_{ref} = ',...
             num2str(refPolarization)]; 
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(imag(TFdev(1,:,tind)))';
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   image(x,y,z1);
   title(ctitle)
   set(get(gca,'Title'),'FontWeight','bold','FontSize',fs)
   set(gca,'FontWeight','bold','FontSize',fs)
   ylabel('Local Time');
   xlabel('log_{10} Period')


%  alternative colormap
   colormap(cmap1);

    cb_rect = [.3,.95-nband*dy-.07,.4,.015];
   clr_bar(cb_rect,clim,ncol);
print -depsc TFdevZ_90.cps
