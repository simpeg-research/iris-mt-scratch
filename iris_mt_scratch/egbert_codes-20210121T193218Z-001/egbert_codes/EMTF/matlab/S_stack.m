%  stack a series of XP files to form time averaged spectra
ID = [1,2,3];

%   decimation level loop
for id = ID 
%  directories to use
dirs = [ 'D09096' ; 'D10096' ; 'D11096'  ];
day1 = [  90 ; 100 ; 110 ];
day2 = day1 + 9;;
[ndirs,dum] = size(dirs);
% output file name
dir =  '/home/server/scratch/sierra/DATA/S_AVG/';

S_avg_file = [ dir 'S_avg' num2str(id) '_' ...
             num2str(day1(1)) '-' num2str(day2(ndirs)) '.mat' ];
%

%   declare here component numbers of cross-products to save
%  currently : save all  H/H  (horizontal only, including between
%    sites) + H/E at both site
xind = [ 1  1 ;  1 2 ; 2 2 ; 6 6 ; 6 7 ; 7 7 ; ...
         1 6 ; 1 7 ; 2 6 ; 2 7 ; ...
         1 4 ; 1 5 ; 2 4 ; 2 5 ; ...
         6 9 ; 6 10 ; 7 9 ; 7 10 ];
 
[nxind, dum] = size(xind);

% load first directory
dir = ['/home/server/scratch/sierra/DATA/' dirs(1,:) '/FC/']
% matlab save file path 
in_file=[ dir 'XP_' num2str(id) '_' num2str(day1(1)) '-' num2str(day2(1)) '.mat'];
eval(['load ' in_file]);
[nf,ntime] = size(S_1_1);

nsum = ntime
o = ones(ntime,1);
for k=1:nxind
   cS = [ 'S_' num2str(xind(k,1)) '_' num2str(xind(k,2)) ];
   eval( [ cS '_avg = ' cS '*o ;'] ) ;
   if(xind(k,1) == xind(k,2))
      eval( [ cS '_log = log10(' cS ')*o ;' ] );
   end
end

%  Loop over data directories, accumulating sums for averaging SDM entries
%   plus averages of logs of diagonal elements

for idir = 2:ndirs
% data directory ...
  dir = ['/home/server/scratch/sierra/DATA/' dirs(idir,:) '/FC/']
% matlab save file path 
  in_file=[ dir 'XP_' num2str(id) '_' num2str(day1(idir)) '-' num2str(day2(idir)) '.mat'];
  eval(['load ' in_file]);
  [nf,ntime] = size(S_1_1);
  o = ones(ntime,1);
  nsum = nsum + ntime
  for k=1:nxind
     cS = [ 'S_' num2str(xind(k,1)) '_' num2str(xind(k,2)) ];
     eval( [ cS '_avg = ' cS '_avg +'  cS '*o ;'] ) ;
     if(xind(k,1) == xind(k,2))
        eval( [ cS '_log = ' cS '_log + log10(' cS ')*o ;' ] );
     end
   end
end

%  save to .mat file
svstr = [ ' freq nsum ' ];
for k=1:nxind
   cS = [ 'S_' num2str(xind(k,1)) '_' num2str(xind(k,2)) ];
   svstr = [ svstr cS '_avg '];
   eval( [ cS '_avg = ' cS '_avg / nsum ;' ] );
   if(xind(k,1) == xind(k,2))
      eval( [ cS '_log = ' cS '_log / nsum;' ] );
      svstr = [ svstr cS '_log '];
   end
end

eval( [ 'save ' S_avg_file svstr ] );
end
