

   if (length(str2num(get(gco,'String'))) == 0) 
      set(gco,'String',num2str(page));
   else
      newpage = str2num(get(gco,'String'))
      if (newpage > nopage) | (newpage < 1)
        disp('page number cannot be less than 1 or');
        disp('over total number of pages ');
        beep('laughter');
        set(gco,'String',num2str(page));
      else
        page = newpage;
        xp = PointPerWindow*(page-1) + 1;
        npts = min(PointPerWindow,Nopoints-xp+1);
        xend = xp+npts-1;
        aa = xp:stride:xend;
        plotpage(npts,0);
        ss = sprintf('pg# %d/%d',page,nopage); 
        set(PAGE,'String',ss); 
     end
   end
