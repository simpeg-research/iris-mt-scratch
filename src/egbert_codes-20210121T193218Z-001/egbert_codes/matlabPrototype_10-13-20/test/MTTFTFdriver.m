%   driver for single site and remote reference TF estmation ... intial testing
%   First set up some things to define the run ...  so far this is simple,
%   use first site for local, second for remote, estimate VTF as well as
%   impedance with RR approach.  
RRorSS = 'RR';
switch RRorSS
    case 'RR'
        TranMTcfgFile = 'CFG/tranmtRR.cfg';  %
        FCdir = './';
        SITES = struct('RR',true,'LocalSite',1,'RemoteSite',2,'VTF',true);
        SaveFileSuffix = '_zrr.mat';
    case 'SS'
        TranMTcfgFile = 'CFG/tranmtSS.cfg';  %
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
        H = H(Use,:);
        R = R(Use,:);
        E = E(Use,:);
        %   next dwnweight segment with vry high power -- leverage control,
        %   plus some protection agains wild outliers in H
        
        %    get a second set of weights for remote site -- test of QD
        %    scheme to protect against outliers in remote channels
        w = Edfwts(H,R);
        n = length(w);
        %wRef  = Edfwts(spdiags(w,0,n,n)*R);
        %W = spdiags(w.*wRef,0,n,n);
        W = spdiags(w,0,n,n);
        RMEobj = TRME_RR(W*H,W*E,W*R,iter);
    else
        [H,E] = getMTTFdata(FCAobj,TFHD);
        Use = ~any(isnan([H E]),2);
        H = H(Use,:);
        E = E(Use,:);
        w = Edfwts(H);
        n = length(w);
        W = spdiags(w,0,n,n);
        RMEobj = TRME(W*H,W*E,iter);
    end
    RMEobj.Estimate;
    TFobj.setTF(ib,RMEobj,T)
end
saveFile = [ FCAobj.ArrayInfo.ArrayName SaveFileSuffix];
save(saveFile,'TFobj');

TFobj.ap_res

PLOTobj = RhoPlot(TFobj);
PLOTobj.rhoPhiPlot