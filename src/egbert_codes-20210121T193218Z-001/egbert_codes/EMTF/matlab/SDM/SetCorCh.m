function SetCorCh

global CorrInd
kk = get(gco,'Value');
obj_tag = get(gco,'Tag');
k = str2num(obj_tag(2:end));
l = str2num(obj_tag(1:1));
if kk==1
   for j=1:3
      CorrInd(k,j) = 0;
      obj_tag = [ num2str(j) num2str(k) ];
      set(findobj('Tag',obj_tag),'Value',0);
   end
   CorrInd(k,l) = 1;
   obj_tag = [ num2str(l) num2str(k) ];
   set(findobj('Tag',obj_tag),'Value',1);
else
   obj_tag = [ num2str(l) num2str(k) ];
   set(findobj('Tag',obj_tag),'Value',0);
   CorrInd(k,l) = 0;
end
