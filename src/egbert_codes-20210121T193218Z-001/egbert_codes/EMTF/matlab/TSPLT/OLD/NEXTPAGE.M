   page = page + 1;

   if (page > nopage) 
     page = page -1 ;
     disp('Not that many pages');
     beep('splat');
   else
     xp = xp + PointPerWindow;
     npts = min(PointPerWindow,Nopoints-xp+1);
     plotpage(npts,0);
     ss = sprintf('pg# %d/%d',page,nopage);
     set(PAGE,'String',ss);
   end
