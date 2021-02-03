[nt,nb,nh,nday] = size(SDMS.var);

medvar = median(SDMS.var,4);
temp = 10*log10(SDMS.var);
medvar = 10*log10(squeeze(medvar));
for id = 1:nday
  temp(:,:,:,id) = temp(:,:,:,id) - medvar;
end
medvar = median(temp,2);
rc = 0;
x = [5:10:365]; y = [1:2:23];
bad_ch = abs(medvar) > 15;
bad = squeeze(any(bad_ch,1)) ;
for r = 1:5
  for c = 1:2
     rc = rc+1;
     subplot(6,2,rc)
     imagesc(x,y,squeeze(medvar(rc,1,:,:)));
%     imagesc(x,y,squeeze(bad_ch(rc,1,:,:)));
     caxis([-15,15])
     text(25,5,SDMHD.ch_name(rc,:),'Color',[1,0,0],'FontWeight','bold')
  end
end
subplot(6,2,11)
imagesc(bad);
colormap(jet)
