figure
ctitle = ['PKD Hz';'PKD Ex';'PKD Ey';'SAO Hx';'SAO Hy'; ...
        'SAO Hz';'SAO Ex';'SAO Ey'];

for k = 3:nt
  if ReIm == 'real'
    subplot(4,2,k-2); plot(t,squeeze(real(TF(k,l,:))),'r*');
    hold on ; plot(t,squeeze(real(TF_smth(k,l,:))),'b-');
  else
    subplot(4,2,k-2); plot(t,squeeze(imag(TF(k,l,:))),'r*');
    hold on ; plot(t,squeeze(imag(TF_smth(k,l,:))),'b-');
  end
  xtxt = .8; ytxt = .8;
  h = text(xtxt,ytxt,ctitle(k-2,:),'Units','normal')
end
