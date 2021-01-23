itst_grp = 3;
figure
plot(real(temp(1:4,:))');
hold on
plot(real(temp(5,:))','w--');
plot(real(temp(itst_grp,:))','w');
zoom
figure
plot(real(temp(itst_grp,:))','y');
hold on
plot(real(temp(5,:))','y--');
plot(imag(temp(itst_grp,:))','c');
plot(imag(temp(5,:))','c--');
ww = (wttemp(5,:)-.5)*.1;
plot(ww,'r-.')
zoom
