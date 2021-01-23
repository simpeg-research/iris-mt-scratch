upper = 10;
lower = -10;
%  some additional bad days ...
%   first PKD
extraOmit_97 = [105,284];
%  then SAO
extraOmit_97 = [ extraOmit_97  ...
 93    98   100   141   159   167   177   189   204   210   212   243 ...
245   259   263   266   270   305   309   310   324   325];

test1 = squeeze(10*log10(SDMS.var(1,:,:)));
test2 = squeeze(10*log10(SDMS.var(2,:,:)));
test3 = squeeze(10*log10(SDMS.var(3,:,:)));
test6 = squeeze(10*log10(SDMS.var(6,:,:)));
test7 = squeeze(10*log10(SDMS.var(7,:,:)));
test8 = squeeze(10*log10(SDMS.var(8,:,:)));
test4 = squeeze(10*log10(SDMS.var(4,:,:)));
test5 = squeeze(10*log10(SDMS.var(5,:,:)));
test9 = squeeze(10*log10(SDMS.var(9,:,:)));
test10 = squeeze(10*log10(SDMS.var(10,:,:)));

[dum,ndays] = size(test1);
temp = median(test6(5:25,:),2);
temp = test6(5:25,:)-temp*ones(1,ndays);
HN_SAOx = median(temp,1);
temp = median(test7(5:25,:),2);
temp = test7(5:25,:)-temp*ones(1,ndays);
HN_SAOy = median(temp,1);
temp = median(test8(5:25,:),2);
temp = test8(5:25,:)-temp*ones(1,ndays);
HN_SAOz = median(temp,1);
temp = median(test9(5:25,:),2);
temp = test9(5:25,:)-temp*ones(1,ndays);
EN_SAOx = median(temp,1);
temp = median(test10(5:25,:),2);
temp = test10(5:25,:)-temp*ones(1,ndays);
EN_SAOy = median(temp,1);

temp = median(test1(5:25,:),2);
temp = test1(5:25,:)-temp*ones(1,ndays);
HN_PKDx = median(temp,1);
temp = median(test2(5:25,:),2);
temp = test2(5:25,:)-temp*ones(1,ndays);
HN_PKDy = median(temp,1);
temp = median(test3(5:25,:),2);
temp = test3(5:25,:)-temp*ones(1,ndays);
HN_PKDz = median(temp,1);
temp = median(test4(5:25,:),2);
temp = test4(5:25,:)-temp*ones(1,ndays);
EN_PKDx = median(temp,1);
temp = median(test5(5:25,:),2);
temp = test5(5:25,:)-temp*ones(1,ndays);
EN_PKDy = median(temp,1);


PKD_E_BAD = EN_PKDx > upper | EN_PKDy > upper | ...
            EN_PKDx < lower | EN_PKDy < lower;

PKD_H_BAD = HN_PKDx > upper | HN_PKDy > upper | ...
            HN_PKDx < lower | HN_PKDy < lower | ...
            HN_PKDz < lower | HN_PKDz > upper;

PKD_BAD = PKD_E_BAD | PKD_H_BAD;

SAO_E_BAD = EN_SAOx > upper | EN_SAOy > upper | ...
            EN_SAOx < lower | EN_SAOy < lower;

SAO_H_BAD = HN_SAOx > upper | HN_SAOy > upper | ...
            HN_SAOx < lower | HN_SAOy < lower | ...
            HN_SAOz < lower | HN_SAOz > upper;

SAO_BAD = SAO_E_BAD | SAO_H_BAD;

%  Plot PKD
plot(EN_PKDx,'m')
hold on
plot(EN_PKDy,'r')
plot(HN_PKDx,'g')
plot(HN_PKDy,'c')
plot(HN_PKDz,'b')
legend('E_x','E_y','H_x','Hy','Hz')
plot(PKD_BAD*10,'k--','LineWidth',3)
set(gca,'Xlabel',text('string','Julian Day : 1997','FontWeight','bold'))
set(gca,'Ylabel',text('string','dB above Typical','FontWeight','bold'))
title('Parkfield : Bad Data Channels')
set(gca,'FontWeight','bold')
%cprint


%  Plot SAO
figure
plot(EN_SAOx,'m')
hold on
plot(EN_SAOy,'r')
plot(HN_SAOx,'g')
plot(HN_SAOy,'c')
plot(HN_SAOz,'b')
legend('E_x','E_y','H_x','Hy','Hz')
plot(SAO_BAD*10,'k--','LineWidth',3)
set(gca,'Xlabel',text('string','Julian Day : 1997','FontWeight','bold'))
set(gca,'Ylabel',text('string','dB above Typical','FontWeight','bold'))
title('Hollister : Bad Data Channels')
set(gca,'FontWeight','bold')

iuse = 1 - ( SAO_BAD | PKD_BAD); 
iuse(extraOmit_97) = 0;
save GOOD_97 iuse
