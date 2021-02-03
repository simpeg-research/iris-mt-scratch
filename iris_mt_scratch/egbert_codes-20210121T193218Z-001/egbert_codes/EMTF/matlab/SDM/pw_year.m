%	pw_year		MATLAB script
%	
%	special script for EQARRAY to make a PW array from all 
%	daily files of one year.
%	Change the variable YEAR to access the different year
%	subdirectories.
%	Output is a structure of the same form as the pw structure
%
%	Hardwired are the dimensions for nbt, nch. If a certain file
%	does not match these defaults, the script tries to fix this.
%	Missing channels are filled with 0s in the arrays tf and cov
%	If nbt is less than the default all arrays 
%	these
    YEAR = 98;
    d_YEAR = ['D',num2str(YEAR)];
    f_day = 1;
    l_day = 180;
    d_good = zeros(2,l_day);

%   set the day from which al header information shall be used as 
%   standard header. This is copied into SDMHD structure and saved in file
    i_f_std = 100;

%  make a structure PW of the standard dimensions:
%	nch = 10;
%	nf = 28;
% so that
%	PW.tf = 2x10x28
%	PW.cov = 10x10x28
%	PW.xxinv = 2x2x28
%	

	T = zeros(28,1);
	nf = zeros(28,1);
	tf = zeros(2,10,28);
	cov = zeros(10,10,28);
	xxinv = zeros(2,2,28);

	PW = struct('T',T,'nf',nf,'tf',tf,'xxinv',xxinv,'cov',cov);

%  make the relevant arrays for the PWHD structure. These include
	nbt = 28;
	nt = 10;
	nsta  = 2;
	nch = [ 5 5];
	ih = [1 6];
	stcor = zeros(2,2);
	decl = [0 0];
	chid = zeros(6,10);
	sta = zeros(3,2);
	orient = zeros(2,10);
	ch_name = [
	    'Hx:PKD: 270';
	    'Hy:PKD:   0';
	    'Hz:PKD:   0';
	    'Ex:PKD: 270';
	    'Ey:PKD:   0';
	    'Hx:SAO: 270';
	    'Hy:SAO:   0';
	    'Hz:SAO:   0';
	    'Ex:SAO: 270';
	    'Ey:SAO:   0'];

	PWHD = struct('nbt',nbt,'nt',nt,'nsta',nsta,'nch',nch, ...
		'ih',ih,'stcor',stcor,'decl',decl,'chid',chid, ...
		'sta',sta,'orient',orient,'ch_name',ch_name);


    
    for jd = f_day:l_day

%  make the file names

	if (jd < 10) 
	    cfile = [d_YEAR,'/D000',num2str(YEAR),'/MMT/00', ...
		num2str(jd),'.Pw'];
	elseif (jd >= 10 & jd < 100 ) 
	    dd = num2str(floor(jd/10)*10);
	    cfile = [d_YEAR,'/D0',dd,num2str(YEAR),'/MMT/0', ...
		num2str(jd),'.Pw'];
	else
	    dd = num2str(floor(jd/10)*10);
	    cfile = [d_YEAR,'/D',dd,num2str(YEAR),'/MMT/', ...
		num2str(jd),'.Pw'];
	end
   
% see if the file exists
   fid = fopen (cfile,'r');
% if not, continue with next file
   if fid < 0 
      cfile
      ' doesn''t exist'
% if it exists, close file, call pwstruct
    else
      fclose(fid);
%      cfile
      [pw,pwhd] = pwstruct(cfile);
% 	check through the header
%  	if # of bands in file is smaller than the default # fill up with 0 
	if (PWHD.nbt > pwhd.nbt)
	    ' adding 0s in NBT ',cfile
	    [c,d,e] = size(pw.tf);
	    pw.tf(:,:,e+1:PWHD.nbt) = 0;
	    pw.cov(:,:,e+1:PWHD.nbt) = 0;
	    pw.xxinv(:,:,e+1:PWHD.nbt) = 0;
	    pw.nf(e+1:PWHD.nbt,:) = 0;
	end
% 		if # of bands in file is larger than the default #, truncate
        if (PWHD.nbt < pwhd.nbt)
	    ' truncating in NBT ',cfile
	    [c,d,e] = size(pw.tf);
	    pw.tf= pw.tf(:,:,1:PWHD.nbt);
	    pw.cov = pw.cov(:,:,1:PWHD.nbt);
	    pw.xxinv = pw.xxinv(:,:,1:PWHD.nbt);
	    pw.nf = pw.nf(1:PWHD.nbt,:);
	end
%  		if the # of channels disagrees
        if (pwhd.nt ~= PWHD.nt)
	    'filling channels', cfile
	    l = zeros(1,10);
	    l(1:pwhd.nch(1)) = 1;
	    l(6:pwhd.nch(2)+5) = 1;

	    temp = zeros(2,10,28);
	    temp(:,find(l),:) = pw.tf;
	    pw.tf = temp;

	    temp = zeros(10,10,28);
	    temp(find(l),find(l),:) = pw.cov;
	    pw.cov = temp;
         end		%  if # of chan less than 10
         
%  		append the arrays of day-structures (pw) to 
%		the year structure (PW)
%  		into the next higher dimension
	PW.T = pw.T;
	PW.nf = cat(3,PW.nf,pw.nf);
	PW.tf = cat(4,PW.tf,pw.tf);
        PW.xxinv = cat(4,PW.xxinv,pw.xxinv);
        PW.cov = cat(4,PW.cov,pw.cov);
%	   set d_good to nch if the file existed
	d_good(:,jd) = pwhd.nch';

	if (jd == i_f_std)
		PWHD.ch_name = pwhd.ch_name;
		PWHD.orient = pwhd.orient;
		PWHD.chid = pwhd.chid;
		PWHD.sta = pwhd.sta;
	end

   end    % if (fid)
end       	%  for jf = f_day:l_day

%	finally strip off the first entries of all PW struct members
    n = length(PW.nf);
    PW.nf = PW.nf(:,:,2:n);
    PW.tf = PW.tf(:,:,:,2:n);
    PW.xxinv = PW.xxinv(:,:,:,2:n);
    PW.cov = PW.cov(:,:,:,2:n);

    PWHD.nch = d_good;
	PWHD = setfield(PWHD,'Year',YEAR);
    README = [
    'This MAT file contains two structures: PW and PWHD. Both   ';
    'are the concatenated structures from each day of the       ';
    'year indicated by the filename, as returned by pwstruct.   ';
    'PWHD  holds header information like chid, station names,   ';
    'sensor orientation, etc. as well as the array nch which    ';
    'gives the number of channels for each station for each day.';
    'If nch (k,:) = [0 0] means there was no data for this day. ';
    ];

    outfile = ['PW_',num2str(YEAR)];
    save_str = ['save 'outfile ' PW PWHD README'];
    eval(save_str);