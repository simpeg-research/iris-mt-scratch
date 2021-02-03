

   if (length(str2num(get(gco,'String'))) == 0) 
      set(gco,'String',num2str(PointPerWindow));
   else
      PointPerWindow = str2num(get(gco,'String'));

%     stride = fix(PointPerWindow/WinMax);
%     stride = max(1,stride);

      page = 1;
      xp = 1;
      nopage = ceil(Nopoints/PointPerWindow);

      xend = xp+PointPerWindow-1;
      if (xend > Nopoints)  
         xend = Nopoints; 
      end 
      aa = xp:stride:xend;
      for ic = Nochn:-1:1
        if chplt(ic)
           set(ACh(ic),'xlim',[xp xp+PointPerWindow-1]);
           if centered
              data0 = centered*mean(data(ic,aa));
              set(PCh(ic),'Xdata',aa,'Ydata',data(ic,aa)-data0);
           else 
              set(PCh(ic),'Xdata',aa,'Ydata',data(ic,aa));
           end 

        end
      end
      ss = sprintf('pg# %d/%d',page,nopage); 
      set(PAGE,'String',ss); 
   end
