
function ArrayInfo = ReadTranMTCfg(arrayFile)
%  reads in standard array.cfg file--i.e., the configuration
%    file used for all EMTF processing, giving number of sites, list
%     of FC files (one for each run) for each site, output name, etc.
%     This is simplified -- no channel weights, and no extra inputs at end
%     of file.  Everything is returned in ArrayInfo structure
%   Usage:  ArrayInfo = readArrayCfg(arrayFile);
%       ArrayInfo.Files is cell array of length nsta (number of stations)
%            each cell contains cell array of file  names for this site
%            (could be more than one), site name, and channel weights
%            (array of length nch(ista))
%       ArrayInfo.bandFile is name for band-setup file
%       ArrayInfo.ArrayName is root for naming output  files

fid = fopen(arrayFile,'r');
nSites = fscanf(fid,'%d\n');
bandFile = fgetl(fid);
Files = cell(nSites,1);
for k = 1:nSites
    temp = fscanf(fid,'%d',2);
    nfiles  = temp(1);
    nch   = temp(2);
    % [wts,count] = fscanf(fid,'%f',nch);
    fgetl(fid);
    FCfiles = cell(nfiles,1);
    for l = 1:nfiles
        FCfiles{l} = deblank(fgetl(fid));
    end
    Files{k} = struct('FCfiles',{FCfiles},'nch',nch);%,'wts',wts);
    clear FCfiles;
end
ArrayName = deblank(fgetl(fid));
fclose(fid);
ArrayInfo = struct('Files',{Files},'bandFile',bandFile,'ArrayName',ArrayName);
end