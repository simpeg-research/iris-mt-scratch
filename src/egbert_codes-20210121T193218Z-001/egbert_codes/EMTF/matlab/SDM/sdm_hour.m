%	sdm_hour		MATLAB script
%	
%	special script for EQARRAY to make a SDM array from all 
%	two hour files for a 60 day period, days 140-199 1997 
%	Output is a structure of the same form as the sdm structure in the S0 file
%
%	Hardwired are the dimensions for nbt, nch. If a certain file
%	does not match these defaults, the script tries to fix this.
%	Missing channels are filled with 0s in the arrays tf and cov
%	If nbt is less than the default all arrays 
%	these

%  make a structure SDMS of the standard dimensions:
	NT = 10;
	NBT = 123;

	T = zeros(NBT,1);
	nf = zeros(NBT,1);
	var = zeros(NT,NBT);
	S = zeros(NT,NT,NBT);
	U = zeros(NT,NT,NBT);
	lambda = zeros(NT,NBT);

	SDMS = struct('T',T,'nf',nf,'var',var,'S',S,'U',U, ...
		'lambda',lambda);

    
    for hr = 0:1:23
%  make the file names
       cfile = ['BART_h',num2str(hr),'.S0'];
       [fid_sdm,irecl,nbt,nt,nsta,nsig,nch,ih,stcor,decl,sta,chid,csta, ...
		orient,periods] = sdm_init(cfile);
	[Sdms] = loadsdms(fid_sdm,irecl,nbt,nt); 
	fclose(fid_sdm);
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

	if (hr == 0)
	    col = ':' * ones(10,1);
	    ch_name = [char(chid(1:2,:)'),char(col),char(csta'), ...
		    char(col),num2str(orient(1,:)')];
	    SDMHD = struct('nbt',nbt,'nt',nt,'nsta',nsta,'nch',nch, ...
		'ih',ih,'stcor',stcor,'decl',decl,'chid',chid, ...
		'sta',sta,'orient',orient,'ch_name',ch_name);
	end		
end       	%  for jf = f_day:l_day

%	finally strip off the first entries of all PW struct members
    [m,n] = size(SDMS.nf);
    SDMS.nf = SDMS.nf(:,:,2:n);
    SDMS.var = SDMS.var(:,:,2:n);
    SDMS.S = SDMS.S(:,:,:,2:n);
    SDMS.U = SDMS.U(:,:,:,2:n);
    SDMS.lambda = SDMS.lambda(:,:,2:n);

    SDMHD = setfield(SDMHD,'Year',1997);

    README = [
    'This MAT file contains two structures: SDMS and SDMHD. SDMS';
    'are the concatenated Sdms structures from each two hour    ';
    'segment of the averaged over days 140-199 .                ';
    'SDMHD holds header information like chid, station names,   ';
    'sensor orientation, etc. as well as the array nch which    ';
    'gives the number of channels for each station for each day.';
    'If nch (k,:) = [0 0] means there was no data for this day. ';
    ];

    outfile = ['/home/ohm/data/EQAR/MAT_ARR/SDMS_1H_140-199'];
    save_str = ['save 'outfile ' SDMS SDMHD README'];
    eval(save_str);
