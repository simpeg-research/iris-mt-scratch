function VECplot(U,stcor,pol,ri)

[nt,npol,nb] = size(U);
nsta = 2;
hcomp = [1,2;6,7];
ecomp = [4,5;9,10];
zcomp = [3;8];
H = zeros(2,nsta,nb);
E = zeros(2,nsta,nb);
HZ = zeros(nsta,nb);

for ista = 1:nsta 
  if(ri == 'real')
     H(:,ista,:) = real(U(hcomp(ista,:),pol,:)); 
     E(:,ista,:) = real(U(ecomp(ista,:),pol,:)); 
     HZ(ista,:)   = real(U(zcomp(ista),pol,:));
  else
     H(:,ista,:) = imag(U(hcomp(ista,:),pol,:)); 
     E(:,ista,:) = imag(U(ecomp(ista,:),pol,:)); 
     HZ(ista,:)   = imag(U(zcomp(ista),pol,:));
  end
end
c = ['b','r','g','m']; c = [c c c c ];
U = squeeze(H(2,:,:))/3;
V = squeeze(H(1,:,:))/3;
X = stcor(1,:)'*ones(1,nb);
Y = stcor(2,:)'*ones(1,nb);
Z = ones(nsta,1)*[1:nb];
for ista = 1:2
  lspec = [ c(ista) '-'];
  quiver3(X(ista,:),Y(ista,:),Z(ista,:),U(ista,:),V(ista,:),HZ(ista,:),0,lspec); 
  set(gca,'Nextplot','add');
  LX = stcor(1,ista)*ones(2,1);
  LY = stcor(2,ista)*ones(2,1);
  LZ = [1 nb];
  line(LX,LY,LZ,'LineWidth',3,'Color',c(ista))
end
