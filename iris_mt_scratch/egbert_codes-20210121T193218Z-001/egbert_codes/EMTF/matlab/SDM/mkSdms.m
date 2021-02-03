%  change grouping here
grouping = 'all';
S = Sdms.S;
[var,sig] = sdm_var(S,grouping,ih,chid);

nb = nbt
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
