var = SDMS.var;
[nt,nb,nday] = size(var);

medvar = median(var,3);
temp = 10*log10(var);
medvar = 10*log10(squeeze(medvar));
for id = 1:nday
  temp(:,:,id) = temp(:,:,id) - medvar;
end
rc = 0;
x = [1:nday]; y = [1:nb];
bad_ch = abs(temp) > 15;
bad_per = squeeze(any(bad_ch,1)) ;
bad = any(bad_per,1);

for r = 1:5
  for c = 1:2
     rc = rc+1;
     subplot(6,2,rc)
     imagesc(x,y,squeeze(temp(rc,:,:)));
%     imagesc(x,y,squeeze(bad_ch(rc,1,:,:)));
     caxis([-20,20])
     text(25,5,SDMHD.ch_name(rc,:),'Color',[1,1,1],'FontWeight','bold',...
            'fontsize',12)
  end
end
subplot(6,2,11)
imagesc(20*bad_per);
caxis([-20,20]);
subplot(6,2,12)
temp = ones(nb,1)*bad;
imagesc(20*bad);
caxis([-20,20]);
colorbar
colormap(jet)
