
   page = page - 1;

   if (page <= 0)
     page = page + 1;
     disp('This is already the first page');
     beep('splat');
   else
     xp = xp - PointPerWindow;
     npts = min(PointPerWindow,Nopoints-xp+1);
     plotpage(npts,0);
     ss = sprintf('pg# %d/%d',page,nopage); 
     set(PAGE,'String',ss); 
   end
