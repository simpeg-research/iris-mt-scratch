% listall  ... adds all new files in TSlist.mat
%  to list of files

%check to see if list of time series files
%  is in directory
  fid = fopen('TSlist.mat','r');
  if( fid < 0 )
    %   Time series list does not exist; make it
    eval(['!ls *.t0* > TSlist.mat']);
  else
    fclose(fid); 
  end
  clear fid
  fid = fopen('TSlist.mat','r');
  [sss,nfall] = fscanf(fid,'%s',inf); 
  fclose(fid);
%  !del TSlist.mat;
  if(nfall > 0 )
    nfall = length(sss)/nchar;
    sss = reshape(sss,nchar,nfall);
    sss = sss';
    cdl = length(current_dir);
    for k = 1:nfall
      ll = 0;
      for l = 1:Nfiles
        if( sss(k,:) == filenames(l,:)) break; end
        ll = ll+1;
      end
      if ll == Nfiles
%      file k is not already in list
        Nfiles = Nfiles + 1;
        filenames(Nfiles,:) = sss(k,:);
        dirnames(Nfiles,1:cdl) = current_dir;
      end 
    end
%   update list
    updlist
  else
    beep('splat');
    disp('No time series files in this directory')
  end


