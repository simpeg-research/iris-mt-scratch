Ep = [ 4 3 1 ; 6 5 2; 8 7 3];
Hp =  [ 2 1 2];
%Ep = [ 18 17 1; 20 19 2; 22 21 3 ];
%Hp = [];

nsta = 3
   stcor = [ 1:nsta; 1:nsta ];
   lat_max =max(max(stcor(1,:)));
   lat_min =min(min(stcor(1,:)));
   lon_max =max(max(stcor(2,:)));
   lon_min =min(min(stcor(2,:)));
   lat_av = (lat_max+lat_min)/2.;
   lat_range = (lat_max-lat_min);
   lon_range = cos(lat_av*pi/180)*(lon_max-lon_min);
   marg = .6*max([lat_range,lon_range]);
marg ==1 ;
 
asp = (2*marg+lon_range)/(2*marg+lat_range);
lat_max = lat_max+marg;
lon_max = lon_max+marg;
lat_min = lat_min-marg;
lon_min = lon_min-marg;
ll_lim = [ lat_min,lat_max,lon_min,lon_max];

