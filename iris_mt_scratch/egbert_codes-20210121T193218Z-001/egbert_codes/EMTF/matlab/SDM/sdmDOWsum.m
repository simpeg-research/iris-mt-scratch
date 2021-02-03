%%%   sums over sdms for fixed day of the week
ncht = sum(SDMHD.nch,1);
%   define day numbers for which there is any data
day = [1:length(ncht)];
day = day(find(ncht));
%   omit all days with any missing channels
omit = ncht(find(ncht)) < 10;
%   also exclude very noisy days
load GOOD_96_97
%  Finally some more bad points
load MORE_BAD96-97

%   iuse is 1 if the day is "good", 0 otherwise
iuse = iuse .* (1-omit);
iuse(IndsBad) = 0;

%  Day 1 of 1996 is a Monday
%   Day 0 == sunday
npd = [];
evals_all = zeros(nt,nb,7);
for k = 0:6
   inds = find(iuse & mod(day,7) == k );
   npd = [ npd length(inds)];
   T = SDMS.T;
   nf = sum(SDMS.nf(:,:,inds),3);
   S = sum(SDMS.S(:,:,:,inds),4);
   S = S / npd(k+1);
   nb = length(T);

%   grouping = 'standard';
   grouping = 'all';
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
   evals_all(:,:,k+1) = lambda;

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
   'ch_name',ch_name);

   str = ['save SDMavgDOW_' num2str(k) ' Sdmhd Sdms;'];
   eval(str);
end
