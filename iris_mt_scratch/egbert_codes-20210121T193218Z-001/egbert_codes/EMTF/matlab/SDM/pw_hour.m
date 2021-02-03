%	pw_hour		MATLAB script
%	
%	special script for EQARRAY to make a PW array from all 
%	2 hour files averaged over days 140-199
%	Output is a structure of the same form as the pw structure
%
%	Hardwired are the dimensions for nbt, nch. If a certain file
%	does not match these defaults, the script tries to fix this.
%	Missing channels are filled with 0s in the arrays tf and cov
%	If nbt is less than the default all arrays 
%	these

%  make a structure PW of the standard dimensions:
	nt = 10;
	nbt = 123;
% so that
%	PW.tf = 2x10x28
%	PW.cov = 10x10x28
%	PW.xxinv = 2x2x28
%	

	T = zeros(nbt,1);
	nf = zeros(nbt,1);
	tf = zeros(2,nt,nbt);
	cov = zeros(nt,nt,nbt);
	xxinv = zeros(2,2,nbt);

	PW = struct('T',T,'nf',nf,'tf',tf,'xxinv',xxinv,'cov',cov);

%  make the relevant arrays for the PWHD structure. These include
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


%%%   2 hour  :       n = 13;
    n = 25;
    
    for hr = 0:1:23

%  make the file names
       cfile = ['BART_h',num2str(hr),'.Pw'];
      [pw,pwhd] = pwstruct(cfile);
%  		append the arrays of day-structures (pw) to 
%		the year structure (PW)
%  		into the next higher dimension
	PW.T = pw.T;
	PW.nf = cat(3,PW.nf,pw.nf);
	PW.tf = cat(4,PW.tf,pw.tf);
        PW.xxinv = cat(4,PW.xxinv,pw.xxinv);
        PW.cov = cat(4,PW.cov,pw.cov);
%	   set d_good to nch if the file existed

	if (hr == 0)
		PWHD.ch_name = pwhd.ch_name;
		PWHD.orient = pwhd.orient;
		PWHD.chid = pwhd.chid;
		PWHD.sta = pwhd.sta;
                PWHD.nch = pwhd.nch;
	end

end       	%  for hr = 0:2:22

%	finally strip off the first entries of all PW struct members
    PW.nf = PW.nf(:,:,2:n);
    PW.tf = PW.tf(:,:,:,2:n);
    PW.xxinv = PW.xxinv(:,:,:,2:n);
    PW.cov = PW.cov(:,:,:,2:n);

    PWHD = setfield(PWHD,'Year',1997);
    README = [
    'This MAT file contains two structures: PW and PWHD. Both   ';
    'are the concatenated structures for 2 hour segments from   ';
    'days 140-199 , 1997                                        ';
    'PWHD  holds header information like chid, station names,   ';
    'sensor orientation, etc. as well as the array nch which    ';
    'gives the number of channels for each station for each day.';
    'If nch (k,:) = [0 0] means there was no data for this day. ';
    ];

    outfile = ['/home/ohm/data/EQAR/MAT_ARR/PW_1H_140-199'];
    save_str = ['save 'outfile ' PW PWHD README'];
    eval(save_str);
