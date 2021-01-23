ctitle = 'Hx Residuals :: dB Above Average Signal :: 30 Min. Averages :: SAO'
%  directories to use
dirs = [ 'D26096' ; 'D27096' ; 'D28096'  ];
day1 = [  260 ; 270 ; 280 ];
day2 = day1 + 9;;
plot_vbl = 'R_06';
sig_vbl = 'S_6_6_log'
%  caxis limits in dB
lims_vbl = [-35 15 ];

rect = [100,100,900,650];
rect_paper = [1.,1.,9.,6.5];
ids = [1:3];nd = length(ids);
yspace = .01; y0 = .15; 
dy = (.95-yspace - y0)/nd; 
x1 = .10;xl = .85;yl = dy-yspace;
rect_ax = [];
for id=ids
  y1 = y0 + (id-1)*dy;
  rect_ax = [rect_ax ; x1 y1 xl yl ];
end 
rect_cb = [.3,y0-.05-4*yspace,.4,.025];
hfig = figure('Position',rect,'PaperPosition',rect_paper,'PaperOrientation', ...
    'Landscape');
 
%%% color map 
hsv_mat = hsv(64);
hsv_mat = hsv_mat(56:-1:1,:);

%   decimation level loop
for id = ids 
%  nwin is number of points in a data window ...
% drs gives sampling rate in seconds
nwin = 128 ; drs = [1,4,16,64];
%%%   The following variables are read in ...
%%%   ndays t_all freq R_1_1to10 ... R_10_1to10
[ndirs, temp ] = size(dirs);
eval ( [ 'load S_avg' num2str(id) '_90-119.mat' ] );
z = [];
time = [];
%  Loop over data directories, accumulating data for plotting variable
%  in array z
for idir = 1:ndirs
% data directory ...
  dir = ['/home/server/scratch/sierra/DATA/' dirs(idir,:) '/FC/']
% matlab save file path 
  in_file=[ dir 'RES_' num2str(id) '_' num2str(day1(idir)) '-' num2str(day2(idir)) '.mat'];
  eval(['load ' in_file]);
  eval( [ 'z = [ z ' plot_vbl ' ];' ] );
  time = [ time t_all ];
end

% convert to "full array" with NaNs for missing time segments ...
%   dt is the time step between data sets ...  (in days)
%    uses navg (# of time windows used in average for estimates)
dt = .75*navg*nwin*drs(id)/(3600*24);
itime = ceil((time - time(1))/dt + .5);
[ nfreq , ntime ]  = size(z);
z1 = zeros(nfreq,itime(ntime));
z1 = z1 ./z1;
z = log10(z);
z1(:,itime) = z;
%  normalize using average signal power spectrum (loaded from S_avg)
eval(['z_norm = ' sig_vbl ]);
z1 = z1 - (z_norm * ones(1,itime(ntime)));
z1 = z1 * 10;

t1 = time(1) + dt*[0:itime(ntime)-1];

%pcolor(t1,freq,z1);shading flat;
%hax = gca;
%delete(hax);
axes('position',rect_ax(nd-id+1,:));
pcolor(t1,freq,z1);
shading flat;
if(size(lims_vbl) > 0 ) 
   caxis(lims_vbl)
end
if(id == nd ) 
   set(gca,'xlabel',text(0,0,'Day of Year'))
end
set(gca,'ylabel',text(0,0,'frequency :: hz'))
if( id < nd ) 
   set(gca,'XTickLabelMode','manual','XTickLabels','')
end
colormap(hsv_mat)
if(id == 1 )
   title(ctitle)
end

%  White lines to mark days ...
%   here I use 0:00 UT ; change hour_mark to mark a different hour each day
hold on
hour_mark = 0;
hoyr_mark = hour_mark/24;
y = [ freq(1) freq(nfreq) ];
day_start = ceil(time(1)); day_end = floor(time(ntime));
for day = day_start:day_end
   x = [day+hour_mark,day+hour_mark];
   h = line(x,y);
   set(h,'LineWidth',1.5,'Color','k')
end

end

if(size(lims_vbl) > 0 ) 
   clr_bar(rect_cb,lims_vbl,56)
else
   colorbar('horiz');
end
xtxt = 1.05
ytxt = -.5
text('position',[xtxt ytxt],'units','normalized','string','dB')
