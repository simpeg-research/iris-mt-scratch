%  rdtshd reads in header of EMI MT-24 data file,
% returns start time (integer array istart :
%   elements are mo,day,yr,hr,min,sec)
%  + # of pts in file, sampling frequency,
%   and channel id
% Usage: [ ch,su,sampfreq,istart,npt] = rdtshd(pathname)

function [ ch,su,sampfreq,istart,npt] = rdtshd(pathname)

fid = fopen(pathname,'r','l');
nlines = 26;
for k=1:nlines
   line = fgets(fid);
   ll = length(line);
   if(ll >= 12) 
     if line(1:9) == 'AcqNumSmp'
        npt = sscanf(line,'AcqNumSmp: %d',1);
    
     elseif line(1:10) == 'AcqSmpFreq'
        sampfreq = sscanf(line,'AcqSmpFreq: %f',1);
     elseif line(1:12) == 'AcqStartTime'
        istart = sscanf(line,...
           'AcqStartTime: %d.%d.%d-%d:%d:%d',6);
     elseif line(1:11) == 'ChannelType'
        ch = line(line ~= ' '); 
        ch = [ch(13),lower(ch(15))];
     elseif line(1:9) == 'SetupName'
        su = line(line ~= ' ');
        su = su(11:length(su));
        su = [ su blanks(10-length(su))];

     end

   end
end
fclose(fid);
end
