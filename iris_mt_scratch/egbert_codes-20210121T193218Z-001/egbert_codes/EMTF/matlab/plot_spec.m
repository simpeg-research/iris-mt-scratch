n1 = 4
n2 =32
load S_avg1_90-119
pwr = 10.^S_1_1_log(n1:64)/18;
freq = freq(n1:64)
loglog(freq,pwr,'r')
set(gca,'box','on')
hold on
pwr = 10.^S_2_2_log(n1:64)/18;
loglog(freq,pwr,'g')
pwr = 10.^S_6_6_log(n1:64)/18;
loglog(freq,pwr,'r--')
pwr = 10.^S_7_7_log(n1:64)/18;
loglog(freq,pwr,'g--')

load S_avg2_90-119
freq = freq(n1:n2)
pwr = 10.^S_1_1_log(n1:n2)/6;
loglog(freq,pwr,'r')
pwr = 10.^S_2_2_log(n1:n2)/6;
loglog(freq,pwr,'g')
pwr = 10.^S_6_6_log(n1:n2)/6;
loglog(freq,pwr,'r--')
pwr = 10.^S_7_7_log(n1:n2)/6;
loglog(freq,pwr,'g--')

n1 = 1
load S_avg3_90-119
freq = freq(n1:n2)
pwr = 10.^S_1_1_log(n1:n2)/3;
loglog(freq,pwr,'r')
pwr = 10.^S_2_2_log(n1:n2)/3;
loglog(freq,pwr,'g')
pwr = 10.^S_6_6_log(n1:n2)/3;
loglog(freq,pwr,'r--')
pwr = 10.^S_7_7_log(n1:n2)/3;
loglog(freq,pwr,'g--')
title('Average Power Spectrum :  H at PKD & SAO  : Days 90-119')
text('Position',[.0002,1e-7],'string','Red = E-W','color','r')
text('Position',[.0002,1e-6],'string','Green = N-S','color','g')
text('Position',[.01,1e-7],'string','PKD Solid')
text('Position',[.01,1e-6],'string','SAO Dashed ')
 hold off
