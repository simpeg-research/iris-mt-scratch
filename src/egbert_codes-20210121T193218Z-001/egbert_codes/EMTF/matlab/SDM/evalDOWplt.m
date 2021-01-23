ne = 1;
clim = [0,40];
ctit = 'First Eigenvalue of Scaled SDM for Each Day of Week';
periods = SDMS.T;
T = log10(periods);
ctitle = {'Sunday','Monday','Tuesday','Wednesday','Thursday',...
    'Friday','Saturday'};
figure('Position',[100,100,900,600],'PaperPosition',[1,1,9,6],...
     'PaperOrientation','Landscape');
width = .210;
height = .35;
space = .025;

rects = [2*space,.55,width,height; ...
	3*space+width,.55,width,height;...
	4*space+2*width,.55,width,height;...
	5*space+3*width,.55,width,height;...
	2*space,.15,width,height; ...
	3*space+width,.15,width,height;...
	4*space+2*width,.15,width*1.18,height];
for k = 0:6
   inds = find(iuse & mod(day,7) == k );
   n = length(inds);
   x = [1:n];
   temp = SDMS.lambda(ne,:,inds);
   temp = 10*log10(squeeze(temp));
   axes('Position',rects(k+1,:));
   imagesc(x,T,temp);
   colormap(jet);
   caxis(clim);
   if(k ==6)
      colorbar;
   end
   set(gca,'FontWeight','demi',...
        'FontSize',10);
   if(k==0 | k == 4)
      ylabel('log_{10} Period (s)');
   end
   title(ctitle(k+1));
   if( k== 6) 
      cb_ax = findobj('Tag','Colorbar');
      cb_ax = cb_ax(1);
      set(cb_ax,'FontWeight','demi','FontSize',12);
      axes(cb_ax);
      xlabel('dB');
     set(cb_ax,'FontSize',10);
   end
%   eval(['print -depsc DOWevals' num2str(k) '.eps']);
end
title_pos = [-15,-.2]; 
text('Position',title_pos,'Units','normalized',...
	'String',ctit,'FontWeight','demi','FontSize',14,...
'HorizontalAlignment','Center')
