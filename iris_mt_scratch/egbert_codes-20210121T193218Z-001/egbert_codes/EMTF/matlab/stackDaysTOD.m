%%%   NEW VERSION ....
%%%   change folowing code to run for different data files ...
%   # of stations, frequencies
nsta = 2;
nfreq = 64;

%  set clean = 0 to turn off FC cleaning
clean = 1 ;

%  set compXp = 0 to turn off cross-product computation
%   E.g., might want to compute residuals with different
%   prediction components.  No reason to keep redoing the cross-prod 
%   computation
compXp = 1 ;

% set finalPlot = 0 to turn off plotting at end of run
finalPlot = 0;


%  set up bands for one decimation level ... (here just one frequency/band)
%iband = ones(2,1)*[1:29 31:64];
%nbands = 63;
iband = ones(2,1)*[1:nfreq];
nbands = nfreq;

%   decimation level
%   Time average ... number of sets to average
%   doesn't now work with navg = 1
ID = [ 1 ; 2 ; 3 ];
NAVG = [ 18 ; 6 ; 3 ];
ndays = 9;
day2 = day1+ndays;

%   set starting day ...
for id=ID'
navg = NAVG(id);
year = 97
% currently assumes you want to use all days in the 10 day directory

rootDir = ['/home/server/project/egbert/EQAR/D' num2str(year) '/'];
dirOut = '/home/server/homes/pi/egbert/pEQAR/RES/'
%   for 5 channels at both sites ...
if(day1 < 100 )
  sta =  [ 'PKD10' ;'SAO0 '] ;
  dir = [ rootDir 'D0' num2str(day1) num2str(year) '/FC/'];
end
if ( day1 >= 100 )
  sta =  [ 'PKD1' ;'SAO '] ;
  dir = [ rootDir 'D' num2str(day1) num2str(year) '/FC/'];
  fprintf(1,'Directory =  %s \n ',dir);
end

%  for 5 channels at both sites:
fc = [ 'f5' ; 'f5' ];
%  for 3 channels at SAO  (i.e., for day1 < ???)
%fc = [ 'f5' ; 'f3' ];
sta = [ fc sta ];
nchar_sta = length(sta(2,:))-1;

% output file name
XP_out_file = [ dirOut 'XP_' num2str(id) '_' num2str(day1) '-' num2str(day2) '.mat'];

%   read in sampling rates .... needed for frequency calculation ...
cfile = [dir sta(1,:) num2str(day1) ; dir sta(2,1:nchar_sta) num2str(day1)  ' ' ]
nchar = [ length(cfile(1,:)) length(cfile(2,:))-1 ];
[nd,nf,nch1,chid1,orient1,drs,stdec,decs,fid,start_dec] ...
                    = fc_open(cfile(1,1:nchar(1)));
fclose(fid);
freq = mean(iband)/(2*nfreq*drs(id));

%   declare here component numbers of cross-products to save
%  currently : save all  H/H  (horizontal only, including between
%    sites) + H/E at both site
xind = [ 1  1 ;  2 2 ; 6 6 ; 7 7];

%         1 6 ; 1 7 ; 2 6 ; 2 7 ; ...
%         1 4 ; 1 5 ; 2 4 ; 2 5 ; ...
%         6 9 ; 6 10 ; 7 9 ; 7 10 ];

[nxind, dum] = size(xind);
for k=1:nxind
   cS = [ 'S_' num2str(xind(k,1)) '_' num2str(xind(k,2)) ];
   eval( [ cS ' = [];' ] ); 
end

%*****************NEW  ************************************
%  now residuals ... loadPw loads in TFs and variances from averaged Pw file
%   replaces call to resid_setup
loadPwTOD
%*****************NEW  ************************************

%  res_ind ... for now just compute residuals for every channel,
%  using all other channels as predictors
%  in each row: 1st # = channel to compute residuals for
%     2nd # = # of channels to use in prediction
%     numbers 3-12 = channels to use for prediction.
%       (if 2nd no is less than 10, fill out array with zeros)
res_ind = [  ...
  1 8 3 4 5 6 7 8 9 10 0 0; ...
  2 8 3 4 5 6 7 8 9 10 0 0; ...
  6 8 1 2 3 4 5 8 9 10 0 0; ...
  7 8 1 2 3 4 5 8 9 10 0 0 ; ...
  1 5 6 7 8 9 10 0 0 0 0 0; ...
  2 5 6 7 8 9 10 0 0 0 0 0; ...
  6 5 1 2 3 4 5 0 0 0 0 0; ...
  7 5 1 2 3 4 5 0 0 0 0 0; ...
  1 2 4 5 0 0 0 0 0 0 0 0; ...
  2 2 4 5 0 0 0 0 0 0 0 0; ...
  6 2 9 10 0 0 0 0 0 0 0 0; ...
  7 2 9 10 0 0 0 0 0 0 0 0];

Res_names = [ ...
  'R_01_all' ; ...
  'R_02_all' ; ...
  'R_06_all' ; ...
  'R_07_all' ; ...
  'R_01_rem' ; ...
  'R_02_rem' ; ...
  'R_06_rem' ; ...
  'R_07_rem' ; ...
  'R_01_loc' ; ...
  'R_02_loc' ; ...
  'R_06_loc' ; ...
  'R_07_loc' ];
RES_out_file =  ...
  [ dirOut 'RES_' num2str(id) '_' num2str(day1) '-' num2str(day2) 'TOD.mat'];
[nres,dum]  = size(Res_names);
res_names = Res_names;
for k=1:nres
   eval( [ Res_names(k,:) ' = [];' ] ); 
   res_names(k,1) = 'r';
end

ndays = 0;
t_all = [];
for day = day1:day2
%   NOTE :::  add  space to end of SAO to acount for different file name
%    lengths (when PKD1 is used ...)
   cfile = [dir sta(1,:) num2str(day) ; dir sta(2,1:nchar_sta) num2str(day)  ' ' ];
%    this BS ... and ' ' above ... to deal with PKD1 vs SAO  +
%           matlab 4 limitations on characters and matrices
   nchar = [ length(cfile(1,:)) length(cfile(2,:))-1 ];
%  change tvarNew to change which auto/cross/residual powers are computed
%   presently computes/saves Hxx Hyy Hxy at station # 1 ... PKD
%   NOTE ::::   ALL OF THE FILE READING AND COMPUTATION HAPPENS IN TVAR ...
   fprintf(' Day # %d \n',day);
%*****************NEW  ************************************
%  first set up channel noise variances for this day
%   so far only works for years 96 and 97
   dayInd = day;
   if year == 97
      dayInd = dayInd+366
   end
   sigma_N = squeeze(Var(:,:,dayInd))' ;
   [SIGMA_N] = VarInterp(sigma_N,periods,freq);
   scFac = scaleFac(:,dayInd);

%   tvarTOD replaces tvarNew
   tvarTOD
%*****************NEW  ************************************
   if(fid > 0 )
     if compXp
        for k=1:nxind
           cS = [ 'S_' num2str(xind(k,1)) '_' num2str(xind(k,2)) ];
           cs = [ ' s' num2str(xind(k,1)) num2str(xind(k,2)) ];
           eval( [ cS ' = [' cS cs ' ];' ] ); 
        end
     end
     for k = 1:nres
        eval( [ Res_names(k,:) ' = [ ' Res_names(k,:) ' ' res_names(k,:) '];' ] ); 
     end
     t_all = [t_all time' ];
     ndays = ndays + 1;
   end
end

if compXp
   xp_str = [ 'save ' XP_out_file ' navg ndays t_all freq ' ];
   for k=1:nxind
     cS = [ ' S_' num2str(xind(k,1)) '_' num2str(xind(k,2)) ];
     xp_str = [ xp_str cS ];
   end
   eval(xp_str);
end

res_str = [ 'save ' RES_out_file ' navg ndays t_all freq ' ];
for k=1:nres
  res_str = [ res_str ' ' Res_names(k,:) ];
end
eval(res_str);
end

if finalPlot
%   just makes a picture at the end of the run ... can be commented out
svbl = 'S_2_2';
rvbl = 'R_01_all';
figure('Name',[ 'Signal Power: '  svbl ])
[nnn,mmm ] = size(S_1_1);
eval(['z1 = log10(' svbl ');']);
zav = mean(z1') ; zav = zav' ;
z1 = z1 - (zav * ones(1,mmm));
z1 = z1*10;

pcolor(t_all,freq,z1);
caxis([-25,25]);
shading flat
colorbar
hsvmat = hsv(64);
hsvmat = hsvmat(56:-1:1,:);
colormap(hsvmat)
[nnn,mmm ] = size(R_01_all);

figure
eval(['z1 = log10(' rvbl ');']);
z1 = z1 - (zav * ones(1,mmm));
z1 = z1*10;

pcolor(t_all,freq,z1);
caxis([-45,5]);
shading flat
colorbar
hsvmat = hsv(64);
hsvmat = hsvmat(56:-1:1,:);
colormap(hsvmat)

figure
eval(['z1 = ' svbl './' rvbl ';']);
z1 = 10*log10(z1);

pcolor(t_all,freq,z1);
caxis([-5,35]);
shading flat
colorbar
hsvmat = hsv(64);
hsvmat = hsvmat(56:-1:1,:);
colormap(hsvmat)
end
