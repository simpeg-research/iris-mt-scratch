function plotfcamp(fc)

figure
[ nfreq , ntime ]  = size(fc);
z = log10(abs(fc));
 zav = mean(z') ; zav = zav' ;
 z = z - (zav * ones(1,ntime));
 z = 10*z;
 lims_vbl = [-25,25];
pcolor(z);
shading flat
caxis(lims_vbl)
