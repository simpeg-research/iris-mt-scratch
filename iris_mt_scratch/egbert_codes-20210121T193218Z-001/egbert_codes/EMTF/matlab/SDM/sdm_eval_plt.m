subtract_mean = 1;
x = [1:365];
y = log10(SDMS.T);
ncht = sum(SDMHD.nch,1);
omit = ncht(find(ncht)) < 10;
use = 1-omit;
induse = find(sum(SDMHD.nch,1) ==10);
ctitle = 'Eigenvalues of SDM : PKD+SAO Array : 1997';
l1 = squeeze(10*log10(SDMS.lambda(1,:,:)));
l2 = squeeze(10*log10(SDMS.lambda(2,:,:)));
l3 = squeeze(10*log10(SDMS.lambda(3,:,:)));
l4 = squeeze(10*log10(SDMS.lambda(4,:,:)));
clim1 = [0,40];
clim2 = [0,40];
clim3 = [0,20];
clim4 = [0,10];
[n,m] = size(l1);
if(subtract_mean)
  l1 = l1 - median(l1,2)*ones(1,m);
  l2 = l2 - median(l2,2)*ones(1,m);
  l3 = l3 - median(l3,2)*ones(1,m);
  l4 = l4 - median(l4,2)*ones(1,m);
  clim1 = [-10,10];
  clim2 = [-10,10];
  clim3 = [-7.5,7.5];
  clim4 = [-5,5];
  ctitle = 'Eigenvalues of SDM : Difference from Median : 1997';
end
l1 = l1.*(l1 >= clim1(1)) + clim1(1)*(l1 < clim1(1));
temp = zeros(28,365);
temp(:,induse) = l1(:,find(use)); l1 = temp./(temp~=0);
temp = zeros(28,365);
temp(:,induse) = l2(:,find(use)); l2 = temp./(temp~=0);
temp = zeros(28,365);
temp(:,induse) = l3(:,find(use)); l3 = temp./(temp~=0);
temp = zeros(28,365);
temp(:,induse) = l4(:,find(use)); l4 = temp./(temp~=0);

figure('Position',[100,100,900,600],...
        'PaperPosition',[1,1,9,6],...
        'PaperOrientation','Landscape');
rect = [.1,.74,.8,.20];
axes('Position',rect);
imagesc(x,y,l1);
caxis(clim1);
set(gca,'FontWeight','bold')
title(ctitle)
text(10,1,'#1','FontSize',14,'FontWeight','bold','Color',[1,0,0])
set(get(gca,'title'),'FontSize',14);
set(gca, 'Ylabel',text('String','log_{10}(T)','FontWeight','bold','FontSize',11));
colorbar;
rect = [.1,.51,.8,.20];
axes('Position',rect);
imagesc(x,y,l2);
caxis(clim2);
set(gca,'FontWeight','bold');
text(10,1,'#2','FontSize',14,'FontWeight','bold','Color',[1,0,0])
set(gca, 'Ylabel',text('String','log_{10}(T)','FontWeight','bold','FontSize',11));
colorbar;
rect = [.1,.28,.8,.20];
axes('Position',rect);
imagesc(x,y,l3);
caxis(clim3);
text(10,1,'#3','FontSize',14,'FontWeight','bold','Color',[1,0,0])
set(gca,'FontWeight','bold');
set(gca, 'Ylabel',text('String','log_{10}(T)','FontWeight','bold','FontSize',11));
rect = [.1,.05,.8,.20];
colorbar;
h = axes('Position',rect);
imagesc(x,y,l4);
caxis(clim4);
set(gca,'FontWeight','bold');
text(10,1,'#4','FontSize',14,'FontWeight','bold','Color',[1,0,0])
set(gca,'Xlabel',text('String','Day of Year','FontWeight','bold','FontSize',11),...
'Ylabel',text('String','log_{10}(T)','FontWeight','bold','FontSize',11));
colorbar;
cmap = jet(64);
cmap(1,:) = [1,1,1];
colormap(cmap);
