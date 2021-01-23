function [TF] = U_TF(SDMS,inds,chInd,chDep);
%  computes TF from evecs in standard SDM structure

%  extract First two columns of evec matrix U, independent
%  and dependent variable rows, multiply by error scale (to convert
%  vrom SNR to physical units)
%   inds gives indices of SDMS to use
[nt,nb,N] = size(SDMS.var);
n = length(inds);
TF = zeros(2,nb,n)+i*zeros(2,nb,n);
for ib = 1:nb
   for k = 1:n
      U = SDMS.U(:,1:2,ib,inds(k));
      sig = sqrt(SDMS.var(:,ib,inds(k)));
      U = diag(sig)*U;
      TF(:,ib,k) = squeeze(U(chDep,:)/U(chInd,:)).';
   end
end

%  following might be more efficient, but is not currently debugged
%Ind = SDMS.U(chInd,1:2,:,inds);
%Ind = reshape(Ind,[2,2,nb*n]);
%IndVar = sqrt(SDMS.var(chInd,:,inds));
%IndVar = reshape(IndVar,[2,nb*n]);
%Dep = SDMS.U(chDep,1:2,:,inds);
%Dep = reshape(Dep,[2,nb*n]);
%DepVar = sqrt(SDMS.var(chDep,:,inds));
%DepVar = reshape(DepVar,[1,nb*n]);
%for l = 1:2
%   Dep(l,:) = squeeze(Dep(l,:)).*DepVar;
%   for k = 1:2
%     Ind(k,l,:) = squeeze(Ind(k,l,:)).'.*IndVar(k,:);
%   end
%end
%det = 1./squeeze(Ind(1,1,:).*Ind(2,2,:)-Ind(1,2,:).*Ind(2,1,:));
%IndInv = zeros(4,nb*n)+i*zeros(4,nb*n);
%IndInv(1,:) = det.*squeeze(Ind(2,2,:));
%IndInv(4,:) = det.*squeeze(Ind(1,1,:));
%IndInv(2,:) = -det.*squeeze(Ind(2,1,:));
%IndInv(3,:) = -det.*squeeze(Ind(1,2,:));
%IndInv = reshape(IndInv,2,2,nb*n);
%TF = zeros(2,nb*n)+i*zeros(2,nb*n);
%TF(1,:) = Dep(1,:).*squeeze(IndInv(1,1,:))+...
%                Dep(2,:).*squeeze(IndInv(2,1,:));
%TF(2,:) = Dep(1,:).*squeeze(IndInv(1,2,:))+...
%                Dep(2,:).*squeeze(IndInv(2,2,:));
%TF = reshape(TF,[2,nb,n]);
