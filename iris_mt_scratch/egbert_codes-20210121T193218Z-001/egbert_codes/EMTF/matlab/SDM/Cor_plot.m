stmonitr;
i1 = find(CorrInd(:,1));
i2 = find(CorrInd(:,2));
i3 = find(CorrInd(:,3));
n1 = length(i1); n2 = length(i2); n3 = length(i3);
[c] = mvcorr(Sdms.S,i1,i2,i3);
figure('Name','Correlations')
ch_names = [ setstr(csta') setstr(chid')];
ctitle = 'Multiple/Partial Correlation'
CurveLabels = [];
for k1 = 1:n1
   cl = [ ch_names(i1(k1),:) '/'];
%   for k = 1:min(n2,2)
   for k = 1:n2
      cl = [ cl ch_names(i2(k),:) '; ' ]; 
   end
   if n3 ~= 0
      cl = [ cl ' | '];
      for k = 1:min(n3,2)
         cl = [ cl ch_names(i3(k),:) '; '];
      end
   end
   CurveLabels = [ CurveLabels ; cl ];
end
semilogx(Sdms.T,c');
legendstr = ['legend('];
for k = 1:n1
   legendstr = [ legendstr 'CurveLabels(' num2str(k) ',:),' ];
end
legendstr = [ legendstr '0)' ];
eval(legendstr);
hleg = findobj('Tag','legend');
if ~isempty(hleg)
   fatleg(hleg(1),line_thick);
   leg_pos = get(hleg(1),'Position');
   leg_pos(3:4) = leg_pos(3:4)*leg_scale,l_scale(n1);
   set(hleg(1),'Position',leg_pos);
end

title(ctitle);
fatlines(gca,line_thick);
set(gca,'Ylim',[0,1],'FontSize',12,'FontWeight','bold');
xlabel('Period (sec)');
ylabel('Squared Correlation');
set(get(gca,'Title'),'FontSize',12,'FontWeight','bold')
set(findobj('Tag','ADD'),'enable','on');


