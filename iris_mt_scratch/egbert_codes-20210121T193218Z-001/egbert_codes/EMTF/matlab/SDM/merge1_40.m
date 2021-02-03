nb40_use = 


load SDMS_2H_96
SDMS1 = SDMS;
SDMHD1 = SDMHD;
load SDMS_96_40HZ;
[nt,nb1,nd1] = size(SDMS96.var);
[nt,nb40,nd40] = size(SDMS.var);
ind1 = [1:2:nd40];
ind2 = [2:2:nd40];
nd = nd1;
nb = nb1+nb40_use;
S = zeros(nt,nt,nb,nd)+i*zeros(nt,nt,nb,nd);
S(:,:,nb40_use+1:nb,1:nd) = SDMS1.S;
S(:,:,1:nb40_use,:) = (SDMS.S(:,:,1:nb40_use,ind1)+...
   SDMS.S(:,:,1:nb40_use,ind2))/2;
U = zeros(nt,nt,nb,nd)+i*zeros(nt,nt,nb,nd);
U(:,:,nb40_use+1:nb,:) = SDMS1.U;
U(:,:,1:nb40_use,:) = SDMS1.U(:,:,1:nb40_use,:);
var = zeros(nt,nb,nd);
var(:,nb40_use+1:nb,:) = SDMS1.var;
var(:,1:nb40_use,:) = (SDMS.var(:,1:nb40_use,ind1)+...
   SDMS.var(:,1:nb40_use,ind2))/2;
lambda = zeros(nt,nb,nd);
lambda(:,nb40_use+1:nb,:) = SDMS1.lambda;
lambda(:,1:nb40_use,:) = (SDMS.lambda(:,1:nb40_use,ind1)+...
   SDMS.lambda(:,1:nb40_use,ind2))/2;
nf = zeros(nb,1,nd);
nf(:,nb40_use+1:nb,:) = SDMS1.nf;
nf(:,1:nb40_use,:) = (SDMS.nf(:,1:nb40_use,ind1)+...
   SDMS.nf(:,1:nb40_use,ind2));
nch = SDM1.nch;
T = SDMS1.T;
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
