function hfig = pltARR(x,y,z,clim,cmap)

[nc,dum] = size(cmap);
cmap(1,:) = [1,1,1];
z1 = z.*(z >= clim(1) & z <= clim(2))  +
     clim(1)*(z < clim(1)) + clim(2)*(z > clim(2));
z1 = ceil((z1 - clim(1))*(nc-1)/clim(2))+1;
mask = isnan(z);
z1 = z1 *(1-mask) + mask;
