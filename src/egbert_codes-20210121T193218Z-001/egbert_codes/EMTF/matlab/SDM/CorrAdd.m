i1 = find(CorrInd(:,1));
i2 = find(CorrInd(:,2));
i3 = find(CorrInd(:,3));
n1 = length(i1); n2 = length(i2); n3 = length(i3);
[c1] = mvcorr(Sdms.S,i1,i2,i3);
c = [ c ;c1 ];
hCorFig = findobj('Name','Correlations');
figure(hCorFig(1));
%figure('Name','Correlations')
ch_names = [ setstr(csta') setstr(chid')];
ctitle = 'Multiple/Partial Correlation'
CurveLabels1 = [];
for k1 = 1:n1
   cl = [ ch_names(i1(k1),:) '/'];
   for k = 1:min(n2,2)
      cl = [ cl ch_names(i2(k),:) '; ' ]; 
   end
   if n3 ~= 0
      cl = [ cl ' | '];
      for k = 1:min(n3,2)
         cl = [ cl ch_names(i3(k),:) '; '];
      end
   end
   CurveLabels1 = [ CurveLabels1 ; cl ];
end
[nc1,mc1] = size(CurveLabels)
[nc2,mc2] = size(CurveLabels1)

nc = nc1+nc2; mc = max(mc1,mc2);
clear CurveLabelsA;
CurveLabelsA(1:nc1,1:mc1) = CurveLabels;
CurveLabelsA(nc1+1:nc,1:mc2) = CurveLabels1;
size(CurveLabelsA);
CurveLabels  = CurveLabelsA;
semilogx(Sdms.T,c');
legendstr = ['legend('];
for k = 1:nc
   legendstr = [ legendstr 'CurveLabels(' num2str(k) ',:),' ];
end
legendstr = [ legendstr '0)' ];
eval(legendstr);
hleg = findobj('Tag','legend');
if ~isempty(hleg)
   fatleg(hleg(1),line_thick);
   leg_pos = get(hleg(1),'Position');
   leg_pos(3:4) = leg_pos(3:4)*leg_scale*l_scale(nc);
   set(hleg(1),'Position',leg_pos);
end

title(ctitle);
fatlines(gca,line_thick);
set(gca,'Ylim',[0,1],'FontSize',12,'FontWeight','bold');
xlabel('Period (sec)');
ylabel('Squared Correlation');
set(get(gca,'Title'),'FontSize',12,'FontWeight','bold')
set(findobj('Tag','ADD'),'enable','on');
   
