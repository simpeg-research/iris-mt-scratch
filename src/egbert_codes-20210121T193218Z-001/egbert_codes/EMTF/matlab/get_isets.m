%   reads in set numbers for one station, decimation level id
%      ... gets set numbers from first frequency in decimation level
%
function [isets] = get_isets(fid,start_dec,nch)

iskip = nch*4;
fseek(fid,start_dec,'bof');
head = fread(fid,3,'long');
nskip = (2*nch-1)*4;
fseek(fid,nskip,'cof');
for l=1:head(3)
  isets(l) = fread(fid,1,'long');
  fseek(fid,iskip,'cof');
end
