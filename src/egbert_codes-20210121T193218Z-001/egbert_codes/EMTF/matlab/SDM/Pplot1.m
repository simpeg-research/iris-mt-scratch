function [hfig] = Pplot(grad_pwr,PER,clim,ctitle,mask)

[nband,nh,nd] = size(grad_pwr);

ncol = 64;
cmap = jet(ncol);
cmap(1,:) = [1,1,1];
hfig = figure('Position',[50,50,600,800],'PaperPosition',[1,1,6,9]);
delete(gca)
x = [5:10:730];
y = [1:2:23];
dx0 = .8;
space = .005;
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
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   z1 = z1 .*(1-mask);

   image(x,y,z1);
   text(300,5,[ 'T = ' num2str(fix(PER(ib))) ' s'],'Color','k','FontWeight','bold',...
      'FontSize',11)
   if(ib ==1)
      title(ctitle)
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
%colormap(cmap);
%   alternative colormap
cmap = colmap;
cmap1 = interp1([1:17],cmap,[1:.25:16.75]);
cmap1(1,:) = [1 1 1];
colormap(cmap1);
clr_bar(cb_rect,clim,ncol);
