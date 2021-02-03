%   driver for single site and remote reference TF estmation ... intial testing
%   First set up some things to define the run ...  so far this is simple,
%   use first site for local, second for remote, estimate VTF as well as
%   impedance with RR approach.  
RRorSS = 'RR';
switch RRorSS
    case 'RR'
        TranMTcfgFile = 'tranmtRR.cfg';  %
        FCdir = './';
        SITES = struct('RR',true,'LocalSite',1,'RemoteSite',2,'VTF',true);
        SaveFileSuffix = '_zrr.mat';
    case 'SS'
        TranMTcfgFile = 'tranmtSS2.cfg';  %
        FCdir = './';
        SITES = struct('RR',false,'LocalSite',1,'VTF',true);
        SaveFileSuffix = '_zss.mat';
end
%   initialize loading of data for one or two sites: local/remote
%    create TSTFTarray object -- load list of FC files for all runs/sites
FCAobj = TSTFTarray(TranMTcfgFile,FCdir);
%   load all files -- this also loads estimation band file
FCAobj.loadFCarray
%   using SITES and Header from array objec, create Header for output TF object
TFHD = TFHeader().ArrayHeader2TFHeader(FCAobj.Header, SITES);
%  create object to collect TF estimates for all bands
TFobj = TTFZ(FCAobj.NBands,TFHD);
%%  create iteration control object for RME, set some convergence parameters
iter = IterControl;
iter.iterMax = 50;
iter.rdscnd = true;
iter.r0 = 1.1;
%%  loop over bands
for ib = 1:FCAobj.NBands
    T = FCAobj.extractFCband(ib);
    %   extract data in format compatible with regression object
    if SITES.RR
        [H,E,R] = getMTTFdata(FCAobj,TFHD);
        %   to start we require that all channels be available
        Use = ~any(isnan([H E R]),2);
        RMEobj = TRME_RR(H(Use,:),E(Use,:),R(Use,:),iter);
    else
        [H,E] = getMTTFdata(FCAobj,TFHD);
        Use = ~any(isnan([H E]),2);
        RMEobj = TRME(H(Use,:),E(Use,:),iter);
    end
    RMEobj.Estimate;
    TFobj.setTF(ib,RMEobj,T)
end
saveFile = [ FCAobj.ArrayInfo.ArrayName SaveFileSuffix];
save(saveFile,'TFobj');

TFobj.ap_res

PLOTobj = RhoPlot(TFobj);
PLOTobj.rhoPhiPlot