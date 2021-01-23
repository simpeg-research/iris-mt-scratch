%  setrange changes range used for plotting data channels
%  mm = 0 <= MIN  and mm = 1 <= MAX
%  chno <= Channel number
%  h_ob <= Object handle for gain control

function setrange(h_ob,mmc)
 
%   include declarations of global variables
    glob_inc

mm = mmc(1); chno = mmc(2);
if mm < 2 
   mm = mmc(1);chno = mmc(2);
   if (length(str2num(get(h_ob,'String'))) == 0) 
      if (mm == 0)
        set(h_ob,'String',num2str(minch(chno)));
      else
        set(h_ob,'String',num2str(maxch(chno)));
      end
   else
      gain = str2num(get(h_ob,'String'));

      if (mm == 0) 
        minch(chno) = gain;
        if centered  
          maxch(chno) = -gain;
          set(MCH(chno),'String',num2str(-gain));
        end
      else
        maxch(chno) = gain;
        if centered
          minch(chno) = -gain; 
          set(mCH(chno),'String',num2str(-gain));
        end
      end 

      ic = chno;
      if chplt_old(ic) set(ACh(ic),'ylim',[minch(ic) maxch(ic)]); end
%      set(Ch(ic),'Xdata',aa,'Ydata',data(ic,aa));
   end
%  Reset ranges to default settings
elseif mm == 2
   for ic = 1:Nochn
      minch(ic) = minch0(ic);
      maxch(ic) = maxch0(ic);
      if chplt(ic)
        set(mCH(ic),'String',num2str(minch(ic)));
        set(MCH(ic),'String',num2str(maxch(ic)));
      end
      if chplt_old(ic) set(ACh(ic),'ylim',[minch(ic) maxch(ic)]); end
   end
elseif mm == 3
%  Increase range by factor sfac
   for ic = 1:Nochn
      minch(ic) = sfac*minch(ic);
      maxch(ic) = sfac*maxch(ic);
      if chplt(ic)
        set(mCH(ic),'String',num2str(minch(ic)));
        set(MCH(ic),'String',num2str(maxch(ic)));
      end
      if chplt_old(ic) set(ACh(ic),'ylim',[minch(ic) maxch(ic)]); end
   end
elseif mm == 4
%  Decrease range by factor sfac
   for ic = 1:Nochn
      minch(ic) = minch(ic)/sfac;
      maxch(ic) = maxch(ic)/sfac;
      if chplt(ic)
        set(mCH(ic),'String',num2str(minch(ic)));
        set(MCH(ic),'String',num2str(maxch(ic)));
      end
      if chplt_old(ic) set(ACh(ic),'ylim',[minch(ic) maxch(ic)]); end
   end
else
%  Center or uncenter range
   data0 = (2*centered - 1) *midch;
   minch = minch - data0;
   maxch = maxch - data0;
   minch0 = minch0 - data0;
   maxch0 = maxch0 - data0;
   for ic = 1:Nochn
      if chplt(ic)
         set(mCH(ic),'String',num2str(minch(ic)));
         set(MCH(ic),'String',num2str(maxch(ic)));
      end
      if chplt_old(ic) 
         set(ACh(ic),'ylim',[minch(ic) maxch(ic)]);
         if centered
            data0 = centered*mean(data(ic,aa));
            set(PCh(ic),'Xdata',aa,'Ydata',data(ic,aa)-data0);
         else
            set(PCh(ic),'Xdata',aa,'Ydata',data(ic,aa));
         end
      end
   end
end
end
