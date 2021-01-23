%  call this routine after setting up frequencies ...

%  path to Pw file to use to load TF ...
%cfile = '/home/server/scratch/sierra/DATA/D15096/MMT/Pw_150_159'
%cfile = '/home/server/scratch/eisel/EQAR/D26096/MMT/Pw_STD';
cfile = '/home/server/scratch/sierra/DATA/D26096/MMT/Pw_260-283.ST';
[fid,recl,nbt,nt,nsta,nsig,nch,ih,stcor,decl,chid,csta,sta1,orient] = ...
     Pw_hd(cfile);
ind = [1:nt];

% make sure that PKD is first station (just a convention, assumed other places)
if(sta1(:,1)' == 'SAO')
  ind = [ ih(2):ih(3)-1 ih(1):ih(2)-1 ];
end

u1 = zeros(nbt,nt)+i*zeros(nbt,nt);
u2 = zeros(nbt,nt)+i*zeros(nbt,nt);
sigma_N = zeros(nbt,nt);
periods = zeros(nbt,1);
for ib = 1:nbt
   [period,nf,tf,xxinv,cov] = Pw_in(fid,recl,ib);
   sigma_N(ib,:) = diag(real(cov))';
   temp = tf(:,ind);
   temp = temp(:,1:2)\temp;
   u1(ib,:)  =  temp(1,:); u2(ib,:) = temp(2,:);
   periods(ib) = period;
end

%  interpolate onto frequencies used ...
[U1,U2,SIGMA_N] = U_interp(u1,u2,sigma_N,periods,freq);
