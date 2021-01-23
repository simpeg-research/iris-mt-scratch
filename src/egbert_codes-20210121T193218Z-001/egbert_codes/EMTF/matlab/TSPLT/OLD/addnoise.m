function addnoise(cfile,nchng)

fid = fopen(cfile,'r');
chd = fread(fid,4096,'char');
[data] = fread(fid,inf,'long');
n = size(data)
data = data + randn(size(data))*std(data)/100.;
fclose(fid)
cfile(nchng) = num2str(1)
fid = fopen(cfile,'w')
fwrite(fid,chd,'char')
fwrite(fid,data,'long')
end
