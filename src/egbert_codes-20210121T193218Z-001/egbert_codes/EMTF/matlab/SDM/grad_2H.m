[nt,nb,nh,nday] = size(SDMS.var);

Neig = 2*ones(nb,1);
grad_pwr = zeros(nb,nh,nday);
T = SDMS.T;
for id = 1:nday
  for hr = 1:nh
     if(1-bad(hr,id))
        S = SDMS.S(:,:,:,hr,id);
        [S_UV] = UVpwr(S,var_AVG,U_snr,Up_snr,Neig);
        grad_pwr(:,hr,id) = 10*log10(squeeze(S_UV(3,:) + S_UV(4,:))+1);
     end
   end
end

x = [5:10:365];
y = [1:2:23];
nrows = 7;
ib0 = 6;
ib = ib0;
for r = 1:nrows
  for c = 1:2
     ib = ib+1;
     subplot(nrows,2,ib-ib0)
     imagesc(x,y,squeeze(grad_pwr(ib,:,:)));
     caxis([0,20])
     text(25,5,[ 'T = ' num2str(T(ib))],'Color','c','FontWeight','bold')
  end
end
colormap(jet)
colorbar
