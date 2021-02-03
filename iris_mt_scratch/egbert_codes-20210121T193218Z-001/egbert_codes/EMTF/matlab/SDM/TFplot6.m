function [hfig] = TFplot6(grad_pwr,PER,clim,ctitle,mask0)
% Usage:  [hfig] = TFplot6(grad_pwr,PER,clim,ctitle)

[nband,nh,nd] = size(grad_pwr);

ncol = 38;
ind = [1:2:20],
ind = [ ind ; [1:2:20] ];
ind = reshape(ind,1,20);
ind = [ind 21:64];
cmap = jet(64);
cmap = cmap(ind,:);
cmap = cmap(end:-1:1,:);
cmap(1,:) = [1,1,1];
%  switch order ... in some cases
hfig = figure('Position',[50,50,600,300],'PaperPosition',[1,1,6,3.0]);
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
dx = .395;
dy = .24;
rects =[.1,.70,dx,dy;...
	.1,.45,dx,dy;...
	.1,.20,dx,dy;...
	.5,.70,dx,dy;...
	.5,.45,dx,dy;...
	.5,.20,dx,dy]
for ib = 1:nband
   rect =  rects(ib,:);
   hax =   axes('Position',rect);
   z = squeeze(grad_pwr(ib,:,:));
   z1 = z.*(z >= clim(1) & z <= clim(2))  + ...
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
   z1 = ceil((z1 - clim(1))*((ncol-1)/(clim(2)-clim(1))))+1;
   mask = z< mask0 ;
%   temp = median(z,1);
%   temp = ones(12,1)*(temp > clim(2));
%   mask = mask  | temp;
   mask(:,31:42) = 1;
   mask(6:8,20:22) = 1;
   mask(:,4:6) = 1;
   mask(:,17) = 1;
   mask(:,52) = 1;
   mask(:,58) = 1;
   mask(:,71:74) = 1;

   z1 = z1 .*(1-mask);

   imagesc(x,y,z1);
%   text(300,5,[ 'T = ' num2str(fix(PER(ib))) ' s'],'Color','k','FontWeight','bold',...
%      'FontSize',10)
   text(315,5,[ num2str(fix(PER(ib))) ' s'],'Color','k','FontWeight','bold',...
      'FontSize',10)
   if(ib ==1 | ib == 4)
%      title(ctitle)
      set(get(gca,'Title'),'FontWeight','bold','FontSize',12)
      set(gca,'XaxisLocation','top','XtickLabel',months(1:3:end),...
	'Xtick',Mtics(1:3:end),...
        'FontWeight','bold','FontSize',10,'TickLength',[.02,.05])
   elseif(ib ==3 | ib ==6)
      set(hax,'Xtick',Jtics(2:2:end),'XtickLabel',Jday(2:2:end),...
	'FontWeight','bold','TickLength',[.02,.05])
      text(100,32.,'1996','FontWeight','bold','FontSize',10)
      text(625,32.,'1997','FontWeight','bold','FontSize',10,...
       'HorizontalAlignment','right')
   else
      set(gca,'XtickLabelMode','manual','XtickLabel','',...
      'FontWeight','bold','TickLength',[.02,.05])
         set(gca,'TickDir','in')
   end
   if(ib > 3) 
      set(gca,'YaxisLocation','right')
   end
end
cb_rect = [.3,.08,.4,.015];
colormap(cmap);
%   OLD inverted colormap
%%%%cmap = colmap;
%%%%cmap1 = interp1([1:17],cmap,[1:.25:16.75]);
%%%%cmap1(1,:) = [1 1 1];
%%%%  Colormap used for amp/ph variations plot
   cmap = colmap;
   cmap1 = interp1([1:17],cmap,[2:.25:16.75]);
   cmap1 = [ cmap1; 1 1 1];
   cmap1 = flipud(cmap1);
   iuse = [1:3:31,32:61-2];
   cmap1 = cmap1(iuse,:);
   colormap(cmap1);

colormap(cmap1);
%clr_bar(cb_rect,clim,ncol);
