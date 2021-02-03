load SDMS_96
SDMS96 = SDMS;
SDMHD96 = SDMHD;
load SDMS_97
SDMS97 = SDMS;
SDMHD97 = SDMHD;
[nt,nb,nd96] = size(SDMS96.var);
[nt,nb,nd97] = size(SDMS97.var);
nd = nd96+nd97;
S = zeros(nt,nt,nb,nd)+i*zeros(nt,nt,nb,nd);
S(:,:,:,1:nd96) = SDMS96.S;
S(:,:,:,nd96+1:nd) = SDMS97.S;
U = zeros(nt,nt,nb,nd)+i*zeros(nt,nt,nb,nd);
U(:,:,:,1:nd96) = SDMS96.U;
U(:,:,:,nd96+1:nd) = SDMS97.U;
var = zeros(nt,nb,nd);
var(:,:,1:nd96) = SDMS96.var;
var(:,:,nd96+1:nd) = SDMS97.var;
lambda = zeros(nt,nb,nd);
lambda(:,:,1:nd96) = SDMS96.lambda;
lambda(:,:,nd96+1:nd) = SDMS97.lambda;
nf = zeros(nb,1,nd);
nf(:,:,1:nd96) = SDMS96.nf;
nf(:,:,nd96+1:nd) = SDMS97.nf;
nch = zeros(2,nd+3);
nch(:,1:nd96) = SDMHD96.nch;
nch(:,nd96+1:nd+3) = SDMHD97.nch;
T = SDMS96.T;
SDMS = struct('T',T,'nf',nf,'var',var,'S',S,'U',U,...
   'lambda',lambda);
nsta = SDMHD.nsta;
ih = SDMHD.ih;
stcor = SDMHD.stcor;
decl = SDMHD.decl;
chid = SDMHD.chid;
sta = SDMHD.sta;
orient = SDMHD.orient;
ch_name = SDMHD.ch_name;
SDMHD = struct('nbt',nb,'nt',nt,'nsta',nsta,'nch',nch,'ih',ih,...
   'stcor',stcor,'decl',decl,'chid',chid,'sta',sta,'orient',orient,...
   'ch_name',ch_name)
