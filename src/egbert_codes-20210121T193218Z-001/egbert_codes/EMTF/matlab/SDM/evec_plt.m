%   plots some eigenvectors for a single specified frequency band
%
%  Usage: 

function [hfig_evec] = evec_plt(ib,U,VAR,NF,T,...
    ivec,rho_ref,snr_units,l_ellipse)

global ll_lim fid_sdm irecl nbt nt nsta nch ...
                 stcor decl sta csta chid orient periods asp
global Hp Ep Hz

%  get this figure size info out of stmonitr.m now
%lower_left = [50,50];
%pix_x = 200;
%extra = 100;
%space = 25;
%sfac = .7;
stmonitr

%  read in sdm for band ib
%   NOW : Input vectors variances etc. once, call funtion
%[period,nf,var,S] = sdm_in(fid_sdm,nt,ib,irecl);
%  solve generalized eigenvalue problem
nvec = length(ivec);
period = T(ib);
var = VAR(:,ib);
nf = NF(ib);
u = U(:,:,ib);
%[u,eval] = eig(S,diag(var));
if(snr_units) 
   u = diag(1./(sqrt(var)))*u;
end

nn = size(Hp);
if length(Hp) > 0
   Hind = reshape(Hp(:,1:2),nn(1)*2,1);
end

% calculate window sizes, figure scalings
pix_y = pix_x/asp;
width = (pix_x+space)*nvec+extra;
height = pix_y + extra;
width_paper = 9;
height_paper = 9*height/width;

norm_width = pix_x/width;
x_step = (pix_x+space)/width;
x0 = extra/width;
y0 = .5*extra/height;
norm_height = pix_y/height;
rect_fig = [ lower_left [width height ]]; 
rect_paper = [ 1 1 width_paper height_paper ];
if(snr_units) 
  figname = [ 'Band =  ' num2str(ib) ...
             '     ::   Period =  ' num2str(period)  ' sec.      '...
                          'SNR Units'];
else
  figname = [ 'Band = ' num2str(ib) ...
             '     ::   Period =  ' num2str(period)  ' sec.      '...
             ' ::   Ref rho =  ' num2str(rho_ref) ];
end
hfig_evec=figure('Position',rect_fig,...
	'Name',figname,...
	'PaperPosition',rect_paper,...
	'PaperOrientation','landscape',...
	'NumberTitle','off',...
	'Tag','evec');
rect_plt = [ x0 , y0 , norm_width, norm_height ];

% loop over desired eigenvectors
axlab = [1,1];
l_label = 1;
for k=1:nvec
   ctit = ['Eigenvector #', num2str(ivec(k))];
   if(length(Hp) > 0 )
      u(:,k) = chngph(u(:,k),Hind);
   end
   [uH,uE,uZ,H_sta,E_sta] = u_pair(u(:,k),Hp,Ep,Hz,orient,...
      decl,stcor,csta,period,rho_ref,snr_units);
   if( k > 1 ) l_label = 0; end
   hfig = evplt_HE(rect_plt,ll_lim,sfac,uH,uE,H_sta,E_sta,...
       axlab,ctit,l_ellipse,l_label);
   if(k == 1 ) 
       xtxt = ll_lim(1) + .2*(ll_lim(2)-ll_lim(1));
       ytxt = ll_lim(3) - .15*(ll_lim(4)-ll_lim(3));
       text('Position',[xtxt,ytxt],'string','Green: Magnetics',...
           'Color',[0,.7,0],'FontSize',12,'FontWeight','bold');
   elseif (k == nvec)
       xtxt = ll_lim(1) + .2*(ll_lim(2)-ll_lim(1));
       ytxt = ll_lim(3) - .15*(ll_lim(4)-ll_lim(3));
       text('Position',[xtxt,ytxt],'string','Red: Electrics',...
            'Color','r','FontSize',12,'FontWeight','bold');
   end
   rect_plt(1)  = rect_plt(1) + x_step;
   axlab = [1,0];
end
