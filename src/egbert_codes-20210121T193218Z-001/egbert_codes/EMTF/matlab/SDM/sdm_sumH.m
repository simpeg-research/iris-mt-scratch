load SDMS_2H_140-199
T = SDMS.T;

[nt,nb,nh] = size(SDMS.var);
nf = sum(squeeze(SDMS.nf(:,:)),2);
S = sum(SDMS.S(:,:,:,:),4)/nh;

grouping = 'all';
[var,sig] = sdm_var(S,grouping,SDMHD.ih,SDMHD.chid);

lambda = zeros(nt,nb);
U = zeros(nt,nt,nb)+i*zeros(nt,nt,nb);

for ib = 1:nb
   %  solve generalized eigenvalue problem
   [u1,eval1] = eig(S(:,:,ib),diag(var(:,ib)));
   %  scale into eigenvectors of scaled sdm
   u1 = diag(sqrt(var(:,ib)))*u1;
   %  now normalize so that eigenvectors are orthonormal
   normU = sum(conj(u1).*u1,1); normU = 1./sqrt(normU);
   u1 = u1*diag(normU);
   % eigenvectors of scaled sdm ...
   %   u = sqrt(diag(var))*u;
   %  make sure eigenvalues are in correct order ...
   [temp,ind] = sort(diag(eval1));
   ind = ind([nt:-1:1]);
   U(:,:,ib) = u1(:,ind);
   lambda(:,ib) = real(temp([nt:-1:1]));
end

Sdms = struct('T',T,'nf',nf,'var',var,'S',S,'U',U,...
   'lambda',lambda);
nsta = SDMHD.nsta;
nch = [ 5 5];
ih = SDMHD.ih;
stcor = SDMHD.stcor;
decl = SDMHD.decl;
chid = SDMHD.chid;
sta = SDMHD.sta;
orient = SDMHD.orient;
ch_name = SDMHD.ch_name;
Sdmhd = struct('nbt',nb,'nt',nt,'nsta',nsta,'nch',nch,'ih',ih,...
   'stcor',stcor,'decl',decl,'chid',chid,'sta',sta,'orient',orient,...
   'ch_name',ch_name)

