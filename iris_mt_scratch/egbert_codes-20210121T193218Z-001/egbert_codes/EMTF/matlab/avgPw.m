path(path,'/home/ohm/data/EQAR/matlab/EQAR')
load PW_96;
ref = [1 2 ];
%   DON'T ROTATE TFs
nRot = 1;
[V_96, sig_V_96] = pws2TFeg(PW,PWHD,ref,nRot);                 
[nT,dum,nDay96] = size(PW.nf);
Var_96 = zeros(10,nT,nDay96);
for k = 1:10
  Var_96(k,:,:) = PW.cov(k,k,:,:);
end

load PW_97;
[V_97, sig_V_97] = pws2TFeg(PW,PWHD,ref,nRot);                 
[nT,dum,nDay97] = size(PW.nf); 
Var_97 = zeros(10,nT,nDay97); 
for k = 1:10 
  Var_97(k,:,:) = PW.cov(k,k,:,:); 
end 

%  some days have nch = 0 (and are not included in PW structure)
inds = 366 + find(sum(PWHD.nch,1) > 0);
nDays96 = nDay96;
nDays = 366+365;
V = zeros(2,10,nT,nDays);;
V(:,:,:,1:nDays96) = V_96;
V(:,:,:,inds) = V_97;
Var = zeros(10,nT,nDays);
Var(:,:,1:nDays96) = squeeze(Var_96);
Var(:,:,inds) = squeeze(Var_97);

temp = V==0;
temp = squeeze(sum(temp(1,3:10,:,:),2));
ind = temp(1,:) ==0;
Vall = V(:,:,:,ind);
Vmed = median(real(Vall),4)+i*median(imag(Vall),4);

temp = Var==0;
temp = squeeze(sum(temp(:,:,:),1));
ind = temp(1,:) ==0;
Vall = Var(:,:,ind);
VarMed = median(Vall,3);
VarVar = zeros(size(Var));
for k = 1:10
temp = (VarMed(k,:)'*ones(1,731));
VarVar(k,:,:) = temp;
end
VarVar = Var./VarVar;

periods = PW.T

scaleFac = ones(10,731);
scaleFac(2,78:167) = .9952;
scaleFac(1,78:167) = 1.0048;
scaleFac(10,54:299) = .92;
scaleFac(9,54:299) = .908;
scaleFac(8,54:299) = .948;
scaleFac(7,54:299) = .936;
scaleFac(6,54:299) = .92;

save avgPW_96-97 Vmed Var VarMed periods scaleFac

