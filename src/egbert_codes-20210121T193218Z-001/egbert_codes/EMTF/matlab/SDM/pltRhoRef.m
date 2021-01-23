figure('Position',[100,100,150,800],'PaperPosition',[1,1,1.5,8])
Escl = rhoRef*5; 
for ib = 1:nbt
   Escl(:,ib) = sqrt(Escl(:,ib)/T(ib));
end
loglog(Escl(1,:),T,'b');
hold on 
loglog(Escl(2,:),T,'g');
loglog(Escl(3,:),T,'r');
fatlines(gca,2);
y1 = 10^lT1; y2 = 10^lT2;
set(gca,'Ytick',[],'FontWeight','demi',...
  'FontSize',14,'box','on','Xlim',[.3,30],'Xtick',[1,10],'Ylim',[y1,y2]);
