function [ch_id,su_id,data,ierr,ts_strt,ts_end] = ...
            plt_set(Nfiles,filenames, dirnames,decimate);

global blanks_dir blanks

%  form full pathnames
pathnames= [];
for ic = 1:Nfiles
   pathnames = [ pathnames ; [ blanks_dir ' ' blanks ]];
end
for ic = 1:Nfiles
   l_dir = length(deblank(dirnames(ic,:))) ;
   l_file = length(deblank(filenames(ic,:))) ;
   l_path = l_dir+l_file+1;
   if(l_dir > 0)
      pathnames(ic,1:l_path) = [ dirnames(ic,1:l_dir) '/' ...
                             filenames(ic,1:l_file)];
   else
      pathnames(ic,1:l_file) = filenames(ic,1:l_file);
   end
end

%  read in file headers
ch_id = []; istarts = []; npts = []; sampfreqs = [];
su_id = [];
for ic = 1:Nfiles
  [ ch,su,sampfreq,istart,npt] = rdtshd(deblank(pathnames(ic,:)));
  ch_id = [ch_id ; ch ]; 
  su_id = [su_id ; su ];
  istarts = [ istarts istart ];
  npts = [ npts npt ];
  sampfreqs = [ sampfreqs sampfreq ] ;
end
if ( min(sampfreqs(1) == sampfreqs(2:Nfiles) ) < 1 )
   ierr = -1;
   fprintf(1,'Error : not all sampling frequncies same');
   return
end

[ts_strt,ts_end] = strtend(istarts,npts,sampfreq);

if max(ts_strt) > min(ts_end)
   ierr = -2;
   fprintf(1,'Error : channels do not overlap in time');
   return
end

ts_strt = decimate*(ceil(ts_strt/decimate));
ts_end = decimate*(floor(ts_end/decimate));
ndata = max(ts_end)/decimate;
data = zeros(Nfiles,ndata);
if (max(ts_strt) ~= min(ts_strt)) | (max(ts_end) ~= min(ts_end))
   data = data./data;
end
for ic = 1:Nfiles
   fid = fopen(deblank(pathnames(ic,:)),'r','l');
   fseek(fid,4096,'bof');
   [temp,count] = fread(fid,inf,'long');
   ts_end(ic) = ts_strt(ic) + count-1;
   i1 = ts_strt(ic)/decimate; i2 = ts_end(ic)/decimate;
   data(ic,i1:i2) = temp(ts_strt(ic):decimate:ts_end(ic))';
end
