cfile = 'TEST/MMT/Pw_071'
[fid,recl,nbt,nt,nsta,nsig,nch,ih,stcor,decl,chid,csta,sta,orient,periods] = ...
     Pw_hd(cfile);
ind = [1:nt];
if(sta(:,1)' == 'SAO')
  ind = [ ih(2):ih(3)-1 ih(1):ih(2)-1 ];
end

U1 = zeros(nbt,nt)+i*zeros(nbt,nt);
U2 = zeros(nbt,nt)+i*zeros(nbt,nt);
periods = zeros(nbt,1);
for ib = 1:nbt
   [period,nf,tf,xxinv,cov] = Pw_in(fid,recl,ib);
   temp = tf(:,ind);
   temp = temp(:,1:2)\temp;
   U1(ib,:)  =  temp(1,:); U2(ib,:) = temp(2,:);
   periods(ib) = period;
end
