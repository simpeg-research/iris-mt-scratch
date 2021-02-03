%  call this routine after setting up frequencies ...
%  Modified version loads an averaged TF + noise variance
%   THIS VERSION: also sets up "Time of Day" TF
%     estimates for each day (NOTE: these are zero if channel is missing ...
load /home/ohm/data/EQAR/MAT_ARR/avgPW_96-97

%  interpolate averaged TF onto frequencies used ...
u1 = squeeze(Vmed(1,:,:)).';
u2 = squeeze(Vmed(2,:,:)).';
[U1,U2,SIGMA_N] = U_interp(u1,u2,VarMed',periods,freq);
nF = length(freq);

load /home/ohm/data/EQAR/MAT_ARR/PW_2H_140-199.mat

ref = [1 2]; nRot = 1;
[V,sig_V] = pws2TFeg(PW,PWHD,ref,nRot);
[dum,ncht,nbt,ntod] = size(V);
Utod = zeros(2,ncht,nF,ntod)+i*zeros(2,ncht,nF,ntod);
VarTOD=zeros(nbt,ncht);
for k = 1:ntod
   u1 = squeeze(V(1,:,:,k)).';
   u2 = squeeze(V(2,:,:,k)).';
   for l = 1:ncht
     VarTOD(:,l) = squeeze(PW.cov(l,l,:,k));
   end
   [U1tod,U2tod,temp] = U_interp(u1,u2,VarTOD,PW.T,freq);
   Utod(1,:,:,k) = U1tod.';
   Utod(2,:,:,k) = U2tod.';
end
