function [Sdms] = loadSdms(fid_sdm,irecl,nbt,nt)
% loads nt x nt Spectral density matrices from *.S0
%  file connected to unit fid_sdm 
%  using record length info info in irecl, for all nbt
% frequency bands.  Call sdm_init first
%  USAGE:  [Sdms] = loadSdms(fid_sdm,irecl,nbt,nt)

T = zeros(nbt);
nf = T;
var = zeros(nt,nbt);
S = zeros(nt,nt,nbt)+i*zeros(nt,nt,nbt);
lambda = zeros(nt,nbt);
U = zeros(nt,nt,nbt)+i*zxeros(nt,nt,nbt);

for ib = 1:nbt
   [T(ib),nf(ib),var(:,ib),S(:,:,ib)] = ...
      sdm_in(fid_uev,nt,ib,irecl);
   %  solve generalized eigenvalue problem
   [u1,eval1] = eig(S(:,:,ib),diag(var(:,ib))); 
   u1 = diag(var(:,ib))*u1;
   % eigenvectors of scaled sdm ...
   %   u = sqrt(diag(var))*u;
   %  make sure eigenvalues are in correct order ...
   [temp,ind] = sort(diag(eval));
   ind = ind([nt:-1:1]);
   U(:,:,ib) = u1(:,ind);
   lambda(:,ib) = eval(ind);
end

Sdms = struct('T',T,''nf',nf,'var',var,'S',S,'U',U,...
   'lambda',lambda);
