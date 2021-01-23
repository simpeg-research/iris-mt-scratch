%	sdm_year		MATLAB script
%	
%	special script for EQARRAY to make a SDM array from all 
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
    YEAR = 96;
    d_YEAR = ['D',num2str(YEAR)];
    f_day = 1;
    l_day = 366;
    d_good = zeros(2,l_day);
%   set the day from which al header information shall be used as 
%   standard header. This is copied into SDMHD structure and saved in file
    i_f_std = 100;

%  make a structure SDMS of the standard dimensions:
	NT = 10;
	NBT = 28;

	T = zeros(NBT,1);
	nf = zeros(NBT,1);
	var = zeros(NT,NBT);
	S = zeros(NT,NT,NBT);
	U = zeros(NT,NT,NBT);
	lambda = zeros(NT,NBT);

	SDMS = struct('T',T,'nf',nf,'var',var,'S',S,'U',U, ...
		'lambda',lambda);

    
    for jd = f_day:l_day

%  make the file names

	if (jd < 10) 
	    cfile = [d_YEAR,'/D000',num2str(YEAR),'/MMT/00', ...
		num2str(jd),'.S0'];
	elseif (jd >= 10 & jd < 100 ) 
	    dd = num2str(floor(jd/10)*10);
	    cfile = [d_YEAR,'/D0',dd,num2str(YEAR),'/MMT/0', ...
		num2str(jd),'.S0'];
	else
	    dd = num2str(floor(jd/10)*10);
	    cfile = [d_YEAR,'/D',dd,num2str(YEAR),'/MMT/', ...
		num2str(jd),'.S0'];
	end
   
% 	see if the file exists
    fid = fopen (cfile,'r');
% 	if not, continue with next file
    if fid < 0 
      cfile
      ' doesn''t exist'
% 	if it exists, close file, call pwstruct
    else
	fclose(fid);
	[fid_sdm,irecl,nbt,nt,nsta,nsig,nch,ih,stcor,decl,sta,chid,csta, ...
		orient,periods] = sdm_init(cfile);
	[Sdms] = loadsdms(fid_sdm,irecl,nbt,nt); 
	fclose(fid_sdm);
    % 	check through the header
%  	if # of bands in file is smaller than the default # fill up with 0 
	if (NBT > nbt)
	    ' adding 0s in NBT ',cfile
	    e = length(Sdms.T);
	    Sdms.NBT(e+1:NBT,:) = 0;
	    Sdms.var(:,e+1:NBT) = 0;
	    Sdms.S(:,:,e+1:NBT) = 0;
	    Sdms.U(:,:,e+1:NBT) = 0;
	    Sdms.lambda(:,e+1:NBT) = 0;

	end
% 		if # of bands in file is larger than the default #, truncate
        if (NBT < nbt)
	    ' truncating in NBT ',cfile
	    Sdms.NBT = Sdms.NBT(1:NBT,:);
	    Sdms.var = Sdms.var(:,e+1:NBT);
	    Sdms.S = Sdms.S(:,:,1:NBT);
	    Sdms.U = Sdms.U(:,:,1:NBT);
	    Sdms.lambda = Sdms.lambda(:,1:NBT);
	end
%  		if the # of channels disagrees
        if (nt ~= NT)
	    'filling channels', cfile
	    l = zeros(1,NT);
	    l(1:nch(1)) = 1;
	    l(6:nch(2)+5) = 1;

	    temp = zeros(NT,NBT);
	    temp(find(l),:) = Sdms.var;
	    Sdms.var = temp;

	    temp = zeros(NT,NBT);
	    temp(find(l),:) = Sdms.lambda;
	    Sdms.lambda = temp;

	    temp = zeros(10,10,28);
	    temp(find(l),find(l),:) = Sdms.S;
	    Sdms.S = temp;

	    temp = zeros(10,10,28);
	    temp(find(l),1:sum(nch),:) = Sdms.U;
	    Sdms.U = temp;
         end		%  if # of chan less than 10
         
%  		append the arrays of day-structures (pw) to 
%		the year structure (PW)
%  		into the next higher dimension
	SDMS.T = Sdms.T;
	SDMS.nf = cat(3,SDMS.nf,Sdms.nf);
	SDMS.var = cat(3,SDMS.var,Sdms.var);
	SDMS.S = cat(4,SDMS.S,Sdms.S);
	SDMS.U = cat(4,SDMS.U,Sdms.U);
   Sdms.lambda = flipud(sort(Sdms.lambda));
   SDMS.lambda = cat(3,SDMS.lambda,Sdms.lambda);
%	   set d_good to nch if the file existed
jd
	d_good(:,jd) = nch';

%	    fill the SDMHD header structure if jd is the selected standard
%	    day
	if (jd == i_f_std)
	    col = ':' * ones(10,1);
	    ch_name = [char(chid(1:2,:)'),char(col),char(csta'), ...
		    char(col),num2str(orient(1,:)')];
	    SDMHD = struct('nbt',nbt,'nt',nt,'nsta',nsta,'nch',nch, ...
		'ih',ih,'stcor',stcor,'decl',decl,'chid',chid, ...
		'sta',sta,'orient',orient,'ch_name',ch_name);
	end		
    end    % if (fid)
end       	%  for jf = f_day:l_day

%	finally strip off the first entries of all PW struct members
    [m,n] = size(SDMS.nf);
    SDMS.nf = SDMS.nf(:,:,2:n);
    SDMS.var = SDMS.var(:,:,2:n);
    SDMS.S = SDMS.S(:,:,:,2:n);
    SDMS.U = SDMS.U(:,:,:,2:n);
    SDMS.lambda = SDMS.lambda(:,:,2:n);

    SDMHD.nch = d_good;
	SDMHD = setfield(SDMHD,'Year',YEAR);

    README = [
    'This MAT file contains two structures: SDMS and SDMHD. SDMS';
    'are the concatenated Sdms structures from each day of the  ';
    'year indicated by the filename, as returned by LOADSDMS.   ';
    'SDMHD holds header information like chid, station names,   ';
    'sensor orientation, etc. as well as the array nch which    ';
    'gives the number of channels for each station for each day.';
    'If nch (k,:) = [0 0] means there was no data for this day. ';
    ];

    outfile = ['SDMS_',num2str(YEAR)];
    save_str = ['save 'outfile ' SDMS SDMHD README'];
    eval(save_str);