StaOrder = [3,1,2];
evalSig = 2;
PltBand = ones(nbt,1);
%PltBand(([1:nbt]-2*(fix([1:nbt]/2))) == 1) = 0;
PltBand(Sdms.lambda(Ivec,:) < evalSig) = 0;
Clrs = ['r','g','b'];
phRefCh = 1;
nn = size(Hp);
if length(Hp) > 0
   Hind = reshape(Hp(:,1:2),nn(1)*2,1);
end
nE = size(Ep);
for ib = 1:nbt
   S1 = squeeze(Sdms.S(:,:,ib));
   Hpwr = 0;
   for k = 1:length(Hind)
     Hpwr = Hpwr + S1(Hind(k),Hind(k));
   end 
   Hpwr = real(Hpwr)/nn(1);
   for k = 1:nE(1)
      rhoRef(k,ib) = (S1(Ep(k,1),Ep(k,1))+S1(Ep(k,2),Ep(k,2)))/Hpwr;
      rhoRef(k,ib) = real(rhoRef(k,ib))*T(ib)/5;
   end
end
%  Need Hp, Ep, etc set up already
scale = .05;
ArrSc = .05;
rho_ref = 1000;
%line_thick = 1.5;
figRect = [100,100,400,800];
papRect = figRect/100;
axRect = [.15,.1,.5,.80];
axRectZ = [.65,.1,.25,.80];
figure('Position',figRect,'PaperPosition',papRect);
axes('Position',axRect);
ctit = ['Eigenvector #', num2str(Ivec)];
u = squeeze(Uplt(:,Ivec,:));
if(snr_units)
   u = 1./(sqrt(Sdms.var)).*u;
end
for ib = 1:nbt
   u(:,ib) = u(:,ib) / norm(u(Hind,ib));
   Hnrm = norm(u(Hind,ib))/sqrt(2*nsta);
   u(:,ib) = u(:,ib)/ Hnrm;
end


if(length(Hp) > 0 )
%   ph = zeros(2,nbt);
%   for ib=1:nbt
%      [u(:,ib),ph(:,ib)] = chngph(u(:,ib),[1,2]);
%   end
%   phU = unwrap(ph,pi/2);
   for ib = 1:nbt
      v = u(phRefCh,ib); v= conj(v)/abs(v);
      u(:,ib) = u(:,ib)*v;
   end
end

lT = log10(T);
lT1 = floor(min(lT)*2)/2;
lT2 = ceil(max(lT*2))/2;
x1 = 0;
x2 = 2*nsta+2;
xsc = figRect(3)*axRect(3)*(lT2-lT1)/((x2-x1)*figRect(4)*axRect(4));
x1 = x1*xsc;
x2 = x2*xsc;
STC = [StaOrder;0,0,0];

Z = zeros(nbt,nsta);
for ib = 1:nbt
 STC(2,:) = lT(ib);
 [uH,uE,uZ,H_sta,E_sta] = u_pair(u(:,ib),Hp,Ep,Hz,orient,...
    decl,STC,csta,T(ib),rho_ref,snr_units);
 Z(ib,:) = uZ(3,:);
 temp = size(uH);
 nH = temp(2);
 temp = size(uE);
 nE = temp(2);
 for kE = 1:nE
   escl = sqrt(rho_ref/rhoRef(kE,ib));
   uE(3,kE) = uE(3,kE)*escl; 
   uE(4,kE) = uE(4,kE)*escl; 
 end

 if(PltBand(ib))
   if nH > 0
     % plot complex H vectors
     y = real(uH(2,:));x = real(uH(1,:));
     x = x*xsc;
     dxr = real(uH(4,:));dyr = real(uH(3,:));
     dxr = dxr*scale;dyr = dyr*scale;
     dxi = imag(uH(4,:));dyi = imag(uH(3,:));
     dxi = dxi*scale;dyi = dyi*scale;
     for kH = 1:nH
        if(l_ellipse)
          polEllTst(x(kH),y(kH),dxr(kH),dyr(kH),dxi(kH),dyi(kH),Clrs(kH),ArrSc)
        else
          H = quiver(x(kH),y(kH),dxr(kH),dyr(kH),0,Clrs(kH));
          set(H,'LineWidth',2);
          hold on
%          cstr = [Clrs(kH) '--'];
          cstr = ['k-'];
          quiver(x(kH),y(kH),dxi(kH),dyi(kH),0,cstr);
        end
     end
   end
   % plot complex E vectors
   if nE > 0
     uE(1,:) = uE(1,:)+nsta+1;
     y = real(uE(2,:));x = real(uE(1,:));
     x = x*xsc;
     dxr = real(uE(4,:));dyr = real(uE(3,:));
     dxr = dxr*scale;dyr = dyr*scale;
     dxi = imag(uE(4,:));dyi = imag(uE(3,:));
     dxi = dxi*scale;dyi = dyi*scale;
     for kH = 1:nE
        if(l_ellipse)
          polEllTst(x(kH),y(kH),dxr(kH),dyr(kH),dxi(kH),dyi(kH),Clrs(kH),ArrSc)
        else
          H = quiver(x(kH),y(kH),dxr(kH),dyr(kH),0,Clrs(kH));
          set(H,'LineWidth',2);
          hold on
%          cstr = [Clrs(kH) '--'];
          cstr = ['k-'];
          quiver(x(kH),y(kH),dxi(kH),dyi(kH),0,cstr);
        end
     end
   end
 end
end
set(gca,'Xlim',[x1,x2],'Ylim',[lT1,lT2],'XtickLabel',[],'Xtick',[],...
   'FontWeight','demi','FontSize',14);
axes('Position',axRectZ);
ZmaxR = max(max(abs(real(Z))));
ZmaxI = max(max(abs(imag(Z))));
Zmax = max(ZmaxR,ZmaxI);
Zmax = ceil(Zmax*10)/10;
for ista = 1:nsta
   hold on
   csty = [Clrs(ista) '-'];
   plot(real(Z(:,ista)),lT,csty)
   csty = [Clrs(ista) '--'];
   plot(imag(Z(:,ista)),lT,csty)
end
fatlines(gca,2)
plot([0,0],[lT1,lT2],'k--');
set(gca,'Xlim',[-Zmax,Zmax],'Ylim',[lT1,lT2],'YtickLabel',[],...
   'FontWeight','demi','FontSize',14,'box','on');
eval(['print -depsc Evec' num2str(Ivec) '.eps']);
