function clr_bar(rec,lims,ndiv)
%clr_bar :  puts a color bar at the specified location
% Usage: clr_bar(rec,lims,ndiv) 
%  rec = rectangle for clor bar to fill (x,y of lower corner, width,length)
% lims =  lower, upper limits on scale
% ndiv = number of color divisions
c = 1:ndiv ;
c = c+1;
c = lims(1) + (c/ndiv)*(lims(2)-lims(1)) ;
%c = c(2:end);
cb(1,:) = c;
cb(2,:) = c;
y = [1;2];
if(lims(1) < lims(2) )
  x = c;
else
  x = fliplr(c);
end
axes('position',rec);
imagesc(x,y,cb)
%lims(1) = lims(1) - 2*ndiv
caxis(lims)
set(gca,'YTickLabelMode','manual','YTickLabels','',...
   'FontWeight','bold')
