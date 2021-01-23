%   plotpg  plots a page of data

    function plotpage(npts,newplt)

%   include declarations of global variables
    glob_inc

    E_clr = [.9 0 0 ];
    H_clr = [0 .9 0 ];

    aa = xp:stride:xp+npts-1;
    nchplt = sum(chplt)
    lxi = 0.55;
    lyi = (0.8-.01*nchplt)/nchplt;
    xi  = 0.4;
    yi = 0.1;

    if newplt
%      create new plotting axes
       for ic = Nochn:-1:1
         if chplt(ic)
            ACh(ic) = axes('Position',[xi yi lxi lyi]);
            yi = yi + lyi + .01;
         end
       end
    elseif max(chplt ~= chplt_old)
       for ic = Nochn:-1:1
         if chplt_old(ic)
            delete(ACh(ic));
         end  
         if chplt(ic)
            ACh(ic) = axes('Position',[xi yi lxi lyi]);
            yi = yi + lyi + .01;
         end
       end 
    end

    if newplt | max( chplt ~= chplt_old )
       for ic = Nochn:-1:1
          if chplt(ic)
             axes(ACh(ic));
             if centered
                PCh(ic) = plot(aa,data(ic,aa)-mean(data(ic,aa)));
             else
                PCh(ic) = plot(aa,data(ic,aa));
             end
             if upper(ch_id(ic,1)) == 'E'
                clr = E_clr;
             else
                clr = H_clr;
             end
             set(PCh(ic),'Color',clr); 
             set(ACh(ic),'xlim',[xp xp+PointPerWindow-1]);
             set(ACh(ic),'ylim',[minch(ic) maxch(ic)]);
             set(ACh(ic),'ylabel',text(0,0,ch_id(ic,:)));
             if (ic ~= nchplt)
               set(gca,'XtickLabelMode','manual','XtickLabels',' ');
             end
          end
       end
    else
       for ic = Nochn:-1:1
          if chplt(ic)
             if centered
                set(PCh(ic),'Xdata',aa,...
                            'Ydata',data(ic,aa)-mean(data(ic,aa)));
             else
                set(PCh(ic),'Xdata',aa,'Ydata',data(ic,aa));
             end
             set(ACh(ic),'ylim',[minch(ic) maxch(ic)]);
             set(ACh(ic),'xlim',[xp xp+PointPerWindow-1]);
             if upper(ch_id(ic,1)) == 'E'
                clr = E_clr;
             else
                clr = H_clr;
             end
             set(PCh(ic),'Color',clr); 
          end
       end
     end 
     chplt_old = chplt;
