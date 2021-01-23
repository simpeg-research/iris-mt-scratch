function find_ch(h_check,h_omit);

% makes lists ind1 and ind2 of channels in each of the two
% groups: ind1 = those channels checked, ind2 = the rest

global ind1 ind2
kk = get(gco,'Value');
obj_tag = get(gco,'Tag');
k = str2num(obj_tag(2:end));
if(obj_tag(1) == 'C')
   jj = get(h_check(k),'Value');
   ll = get(h_omit(k),'Value');
   set(h_omit(k),'Value',(1-jj)*ll);
else
   jj = get(h_check(k),'Value');
   ll = get(h_omit(k),'Value');
   set(h_check(k),'Value',(1-ll)*jj);
end  
nt = length(h_check);
n1 = 0 ; n2 = 0;
ind1 = []; ind2 = [];
for k=1:nt
   if(get(h_omit(k),'value') == 0 )
     if( get(h_check(k),'value') == 1)
       n1 = n1 + 1;
       ind1(n1) = k;
     else
       n2 = n2 + 1;
       ind2(n2) = k;
    end
  end
end
