%  script to turn a channel on or off
   ic=get(gco,'UserData');
   chplt(ic)=1-chplt(ic);
   set(gco,'ForeGroundColor',fgc(1+chplt(ic),:));
   if chplt(ic)
     set(mCH(ic),'String',num2str(minch(ic)));  
     set(MCH(ic),'String',num2str(maxch(ic)));
   else
     set(MCH(ic),'String',blanks(1));
     set(mCH(ic),'String',blanks(1));
   end
   rpltpage
