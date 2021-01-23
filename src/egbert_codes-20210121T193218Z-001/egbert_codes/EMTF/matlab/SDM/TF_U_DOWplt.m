%  this script makes plots of TFs computed from evecs for
%  Day of Week variations
%  channel to compute TFs for
chDep = [7];
%  channels to use as independent or reference variables
chInd = [1,2];
%  plotting limits
clim = [-.5,.5];
%   title
ctit1 = 'Deviation of Real(Hx/Hy) TF from reference for Each Day of Week';
ctit2 = 'Deviation of Real(Hx/Hx) TF from reference for Each Day of Week';
ctit3 = 'Deviation of Imag(Hx/Hy) TF from reference for Each Day of Week';
ctit4 = 'Deviation of Imag(Hx/Hx) TF from reference for Each Day of Week';
%   END OF EDIT FIELDS

% reference TF: use smoothed TFS from full array
load UVP_SNR96-97
TFsmth = zeros(2,nb);
for ib = 1:nb
   U = U_snr(:,:,ib);
   sig = sqrt(var_AVG(:,ib));
   U = diag(sig)*U;
   TFsmth(:,ib) = squeeze(U(chDep,:)/U(chInd,:)).';
end

periods = SDMS.T;
T = log10(periods);
ctitle = {'Sunday','Monday','Tuesday','Wednesday','Thursday',...
    'Friday','Saturday'};
width = .210;
height = .35;
space = .025;

rects = [2*space,.60,width,height; ...
	3*space+width,.60,width,height;...
	4*space+2*width,.60,width,height;...
	5*space+3*width,.60,width,height;...
	2*space,.15,width,height; ...
	3*space+width,.15,width,height;...
	4*space+2*width,.15,width*1.18,height];
nmax = 50;
TF_DOW = zeros(2,nb,nmax,7)+i*zeros(2,nb,nmax,7);
for k = 0:6
   inds = find(iuse & mod(day,7) == k );
   n = length(inds);
   [TF] = U_TF(SDMS,inds,chInd,chDep);
   TF_DOW(1,:,1:n,k+1) = squeeze(TF(1,:,:)) - TFsmth(1,:).'*ones(1,n);
   TF_DOW(2,:,1:n,k+1) = squeeze(TF(2,:,:)) - TFsmth(2,:).'*ones(1,n);
end
hfig1 = figure('Position',[100,100,900,600],'PaperPosition',[1,1,9,6],...
     'PaperOrientation','Landscape');
for k = 0:6
   inds = find(iuse & mod(day,7) == k );
   n = length(inds);
   x = [1:n];
   temp = squeeze(real(TF_DOW(1,:,1:n,k+1)));
   axes('Position',rects(k+1,:));
   imagesc(x,T,temp);
%  use yellow centered colormap ...
   cmap = colmap;
   cmap1 = interp1([1:17],cmap,[1:.25:16.75]);
   cmap1 = cmap1(end:-1:1,:);
   colormap(cmap1);

   if(length(clim) == 2) caxis(clim); end
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
      xlabel('');
     set(cb_ax,'FontSize',10);
   end
%   eval(['print -depsc DOWevals' num2str(k) '.eps']);
end
title_pos = [-15,-.2]; 
text('Position',title_pos,'Units','normalized',...
	'String',ctit1,'FontWeight','demi','FontSize',14,...
'HorizontalAlignment','Center')

figure('Position',[100,100,900,600],'PaperPosition',[1,1,9,6],...
     'PaperOrientation','Landscape');
for k = 0:6
   inds = find(iuse & mod(day,7) == k );
   n = length(inds);
   x = [1:n];
   temp = squeeze(real(TF_DOW(2,:,1:n,k+1)));
   axes('Position',rects(k+1,:));
   imagesc(x,T,temp);
%  use yellow centered colormap ...
   cmap = colmap;
   cmap1 = interp1([1:17],cmap,[1:.25:16.75]);
   cmap1 = cmap1(end:-1:1,:);
   colormap(cmap1);

   if(length(clim) == 2) caxis(clim); end
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
      xlabel('');
     set(cb_ax,'FontSize',10);
   end
%   eval(['print -depsc DOWevals' num2str(k) '.eps']);
end
title_pos = [-15,-.2]; 
text('Position',title_pos,'Units','normalized',...
	'String',ctit2,'FontWeight','demi','FontSize',14,...
'HorizontalAlignment','Center')

figure('Position',[100,100,900,600],'PaperPosition',[1,1,9,6],...
     'PaperOrientation','Landscape');
for k = 0:6
   inds = find(iuse & mod(day,7) == k );
   n = length(inds);
   x = [1:n];
   temp = squeeze(imag(TF_DOW(1,:,1:n,k+1)));
   axes('Position',rects(k+1,:));
   imagesc(x,T,temp);
%  use yellow centered colormap ...
   cmap = colmap;
   cmap1 = interp1([1:17],cmap,[1:.25:16.75]);
   cmap1 = cmap1(end:-1:1,:);
   colormap(cmap1);

   if(length(clim) == 2) caxis(clim); end
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
      xlabel('');
     set(cb_ax,'FontSize',10);
   end
%   eval(['print -depsc DOWevals' num2str(k) '.eps']);
end
title_pos = [-15,-.2]; 
text('Position',title_pos,'Units','normalized',...
	'String',ctit3,'FontWeight','demi','FontSize',14,...
'HorizontalAlignment','Center')

figure('Position',[100,100,900,600],'PaperPosition',[1,1,9,6],...
     'PaperOrientation','Landscape');
for k = 0:6
   inds = find(iuse & mod(day,7) == k );
   n = length(inds);
   x = [1:n];
   temp = squeeze(imag(TF_DOW(2,:,1:n,k+1)));
   axes('Position',rects(k+1,:));
   imagesc(x,T,temp);
%  use yellow centered colormap ...
   cmap = colmap;
   cmap1 = interp1([1:17],cmap,[1:.25:16.75]);
   cmap1 = cmap1(end:-1:1,:);
   colormap(cmap1);

   if(length(clim) == 2) caxis(clim); end
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
      xlabel('');
     set(cb_ax,'FontSize',10);
   end
%   eval(['print -depsc DOWevals' num2str(k) '.eps']);
end
title_pos = [-15,-.2]; 
text('Position',title_pos,'Units','normalized',...
	'String',ctit4,'FontWeight','demi','FontSize',14,...
'HorizontalAlignment','Center')
