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

nband = 8;
band1 = 8;
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

clim = [0,20];
ncol = 32;
cmap = jet(ncol);
cmap(1,:) = [1,1,1];
figure('Position',[50,50,600,800],'PaperPosition',[1,1,6,9]);
delete(gca)
x = [5:10:730];
y = [1:2:23];
dx0 = .8;
space = .0025;
dy = .85/nband;
dy0 = dy - space;
Jday = [0,50,100,150,200,250,300,366,50,100,150,200,250,300,365];
Jtics = [0,50,100,150,200,250,300,366,50,100,150,200,250,300,365];
Jtics(9:end) = Jtics(9:end)+365;
Mtics = [1,31,28,31,30,31,30,31,31,30,31,30,...
             31,31,28,31,30,31,30,31,31,30,31,30];
Mtics = cumsum(Mtics);
months = {'Ja','Fb','Mr','Ap','My','Jn','Jl','Au','Sp','Oc','Nv','Dc'};
for ib = 1:nband
   rect = [.1,.95-ib*dy,dx0,dy0];
   hax =   axes('Position',rect);
   z = squeeze(grad_pwr(ib,:,:));
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/clim(2)))+1;
   mask = z==0 ;
   temp = median(z,1);
   temp = ones(12,1)*(temp > clim(2));
   mask = mask  | temp;
   mask(:,31:42) = 1;
   z1 = z1 .*(1-mask);

   image(x,y,z1);
   text(320,5,[ 'T = ' num2str(fix(PER(ib))) ' s'],'Color','k','FontWeight','bold',...
      'FontSize',11)
   if(ib ==1)
      title('Power In Gradients  vs. Time of Day and Julian Day : 1996-1997')
      set(get(gca,'Title'),'FontWeight','bold','FontSize',12)
      set(gca,'XaxisLocation','top','XtickLabel',months,'Xtick',Mtics,...
     'FontWeight','bold','FontSize',9)
   end
   if(ib < nband & ib > 1)
      set(gca,'XtickLabelMode','manual','XtickLabel','',...
      'FontWeight','bold')
      if(2*(floor(ib/2)) == ib)
         set(gca,'TickDir','in','Xtick',Jtics)
      else
         set(gca,'TickDir','in','Xtick',Mtics)
      end
   end
   if(ib == nband)
      set(hax,'Xtick',Jtics,'XtickLabel',Jday,'FontWeight',...
         'bold','Xlabel',text('string','Julian Day','FontWeight','bold','FontSize',12))
      text(100,32,'1996','FontWeight','bold','FontSize',12)
      text(625,32,'1997','FontWeight','bold','FontSize',12,...
       'HorizontalAlignment','right')
   end
   if(ib==6) 
      text(-45,-10,'Local Time (PST)','rotation',90,'FontWeight','bold',...
       'FontSize',12)
   end
end
cb_rect = [.3,.95-nband*dy-.07,.4,.015];
colormap(cmap);
clr_bar(cb_rect,clim,ncol);
