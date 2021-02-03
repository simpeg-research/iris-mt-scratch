%  plot H and E components of one eigenvector on a single plot

function hfig = evplt_HE(rect,ll_lim,sfac,uH,uE,H_sta,E_sta,...
   axlab,ctit,l_ellipse,l_label)

stmonitr
if(axlab(2))
   ym = 'auto';
else
   ym = 'manual';
end
if(axlab(1))
   xm = 'auto';
else
   xm = 'manual';
end
temp = size(uH);
nH = temp(2);
temp = size(uE);
nE = temp(2);
ss = 0;
if nH > 0
   ss = ss + real(   sum(sum (uH(3:4,:).*conj(uH(3:4,:)) )));
end
if nE > 0
    ss = ss + real(sum(sum(uE(3:4,:).*conj(uE(3:4,:)))));
end
lat_range = ll_lim(2)-ll_lim(1);
lon_range = ll_lim(4) - ll_lim(3);
if( ~ l_ellipse) sfac = .8*sfac ; end;
scale = sfac*sqrt(lat_range*lon_range/ss);
%temp = size(uZ);
%nZ = temp(2);
hfig = axes('Position',rect);
bgr = [.8,.8,.90];
ll_pX = [ ll_lim(3) ll_lim(4) ll_lim(4) ll_lim(3) ll_lim(3) ];
ll_pY = [ ll_lim(1) ll_lim(1) ll_lim(2) ll_lim(2) ll_lim(1) ];
patch(ll_pX,ll_pY,bgr)
hold on

%  plot station locations
y = real(uE(1,:));x = real(uE(2,:));
plot(x,y,'ko')

if nH > 0
% plot complex H vectors
y = real(uH(1,:));x = real(uH(2,:));
dxr = real(uH(4,:));dyr = real(uH(3,:));
dxr = dxr*scale;dyr = dyr*scale;
dxi = imag(uH(4,:));dyi = imag(uH(3,:));
dxi = dxi*scale;dyi = dyi*scale;
if(l_ellipse)
  pol_ell(x,y,dxr,dyr,dxi,dyi,'g')
else
  quiver(x,y,dxr,dyr,0,'g');
  hold on
  quiver(x,y,dxi,dyi,0,'g--');
end
end
if(l_label)
  xx = x+lat_range/10;
  if (nH > 0 ) text(xx,y,char(H_sta'),'Color',[0,0,0],'FontSize',12); end
else
  set(gca,'YTickLabelMode','manual','YTickLabels','');
end

% plot complex E vectors
if nE > 0
y = real(uE(1,:));x = real(uE(2,:));
dxr = real(uE(4,:));dyr = real(uE(3,:));
dxr = dxr*scale;dyr = dyr*scale;
dxi = imag(uE(4,:));dyi = imag(uE(3,:));
dxi = dxi*scale;dyi = dyi*scale;
if(l_ellipse)
  pol_ell(x,y,dxr,dyr,dxi,dyi,'r')
else
  quiver(x,y,dxr,dyr,0,'r');
  hold on
  quiver(x,y,dxi,dyi,0,'r--');
end
end
set(gca,'Color',[.85,.85,.9])
fatlines(gca,line_thick)
set(gca,'Ylim',ll_lim(1:2),'Xlim',ll_lim(3:4),'XTickLabelMode',xm, ...
   'YTickLabelMode',ym,'FontWeight','bold','FontSize',11);
title(ctit);
set(get(gca,'title'),'FontWeight','Bold','FontSize',12);
hold off
return
