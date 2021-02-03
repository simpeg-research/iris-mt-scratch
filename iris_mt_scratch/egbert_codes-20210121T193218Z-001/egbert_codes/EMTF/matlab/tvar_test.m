nsta = 2;
nfreq = 64;
cfile = [ 'f5PKD080'; 'f5SAO080']

fids = [];start_decs = []; chid = []; nch = [];orient = [];

for ista = 1:nsta
  [nd,nf,nch1,chid1,orient1,drs,stdec,decs,fid,start_dec] ...
                    = fc_open(cfile(ista,:));
  fids = [ fids fid ];
  start_decs = [start_decs ; start_dec ] ;
  chid = [ chid  chid1 ];
  nch = [nch  nch1 ];
  orient = [orient orient1(1,:) ];
end
  
id = 1

%   set up array of pointers to start of each frequency in each FC file
[start_freqs] = mk_start_freqs(id,fids,nf,nch,start_decs);

%   find set numbers available for all sites
[isets,isets_pt] =  mk_isets(fids,start_decs,nch,nf,id);

%  set up bands for one decimation level ... (here just one frequency/band)
iband = ones(2,1)*[1:nfreq];
nbands = nfreq;

%   as an example extract H signal power at PKD (averaged over
%   10 minute (approx) window
   navg = 6;
   comp = [1 2 ]; nc = 2;
   nsets = length(isets);
   nt = fix(nsets/navg);
   H_power = zeros(nbands,nt);
%   time expressed in days (1 Jan = 0 )
   time = (isets(1:navg:navg*nt)+navg/2)*96/86400;

% loop over bands ...
for kb = 1:nbands
   [fc] = fc_get(fids,start_freqs,nch,isets_pt,id,iband(:,kb));
   temp = reshape(fc(comp,1:navg*nt),nc*navg,nt);
   H_power(kb,:) = sum(temp .* conj(temp) );
end    
