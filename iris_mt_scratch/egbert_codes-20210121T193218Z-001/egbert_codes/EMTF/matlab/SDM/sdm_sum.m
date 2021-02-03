ncht = sum(SDMHD.nch,1);
omit = ncht(find(ncht)) < 10;
load GOOD_96_97
iuse = iuse .* (1-omit);
inds = find(iuse);
T = SDMS.T;
nf = sum(SDMS.nf(:,:,inds),3);
S = sum(SDMS.S(:,:,:,inds),4);
S = S / sum(iuse);
nb = length(T);

grouping = 'standard';
[var,sig] = sdm_var(S,grouping,SDMHD.ih,SDMHD.chid);

nt = max(ncht);
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

