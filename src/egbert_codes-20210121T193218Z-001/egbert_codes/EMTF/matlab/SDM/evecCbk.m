cbk = get(gcbo,'Tag')

switch cbk
   case 'GETIB'
     % finds band which is closest to frequncy where slider is released,
     %  then displays in small box above plot button

     per = get(gcbo,'Value');
     per = 10^per;
     ib = find_ib(nbt,periods,per);
     if(exist('h_ib'))
        delete(h_ib);
        clear h_ib;
     end
     h_ib = axes('Position',[.05,.34,.05,.04],...
        'XTickLabelMode','manual', ...
        'YtickLabelMode','manual',...
        'box','on',...
        'Xlim',[0,1],...
        'Ylim',[0,1]); 
     text('Parent',h_ib,'Position',[.18,.32],'String',num2str(ib),...
        'FontWeight','bold');
  case 'PLOT'
     per = get(findobj('Tag','GETIB'),'Value');
     per = 10^per
     ib = find_ib(nbt,periods,per);
     hev1 = evec_plt(ib,Uplt,Sdms.var,Sdms.nf,Sdms.T,...
        ivec,rho_ref,snr_units,l_ellipse)
     hfig_evec=[hfig_evec hev1];
  case 'eigSM'
     eigSM; 
     
     if(exist('hfig_evec_menu')) 
        chk_clr(hfig_evec_menu);
        clear hfig_evec_menu;
     end
  case 'PLTSM'
     l_smthsep=1-l_smthsep; set(gcbo,'Value',l_smthsep);
     if(l_smthsep)
        Uplt = zeros(size(Uplt));
        Uplt(:,1:2,:) = Usm;
        for ib = 1:nb
           if(Neig(ib) > 0 )
              Uplt(:,3:2+Neig(ib),:) = Vsm(:,1:Neig(ib),:);
           end
        end
     else
        Uplt = Sdms.U;
        for ib = 1:nbt
          N = sqrt(Sdms.var(:,ib));
          Uplt(:,:,ib) = diag(N)*Uplt(:,:,ib);
        end
     end
  case 'PERP'
     l_perp=l_smthsep*(1-l_perp); set(gcbo,'Value',l_perp);
     if(l_perp)
        for ib = 1:nb
           if(Neig(ib) > 0 )
              Uplt(:,3:2+Neig(ib),:) = Uperp(:,1:Neig(ib),:);
           end
        end
     else
        for ib = 1:nb
           if(Neig(ib) > 0 )
              Uplt(:,3:2+Neig(ib),:) = Vsm(:,1:Neig(ib),:);
           end
        end
     end        
     
  case 'MTTFs'
     l_MTTF=l_smthsep*(1-l_MTTF); set(gcbo,'Value',l_MTTF);
     if(l_MTTF)
        Uplt(:,1:2,:) = TFsm;
     else
        Uplt(:,1:2,:) = Usm;
     end        
  case 'Cancel'
    close(gcf);
    rho_ref=rho_ref_old;
    snr_units=snr_units_old;
    n_evec=n_evec_old;
    l_ellipse=l_ellipse_old;
    l_perp = l_perp_old;
    l_MTTF = l_MTTF_old;
    if(l_smthsep)
       if(l_MTTF)
         Uplt(:,1:2,:) = TFsm;
       else
         Uplt(:,1:2,:) = Usm;
       end        
       if(l_perp)
         for ib = 1:nb
           if(Neig(ib) > 0 )
              Uplt(:,3:2+Neig(ib),:) = Uperp(:,1:Neig(ib),:);
           end
         end
       else
         for ib = 1:nb
           if(Neig(ib) > 0 )
              Uplt(:,3:2+Neig(ib),:) = Vsm(:,1:Neig(ib),:);
           end
         end
       end
    end 
  case 'Clr Evec Figs'
    delete(findobj('Tag','evec'));
  otherwise
     fprintf(1,'%s \n','Case Not Coded in evecCbk')
end
