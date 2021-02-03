%  browse
eval(['cd ' current_dir]);

[cfile,current_dir] = uigetfile('*');
if(current_dir(end) == '\')
   current_dir = current_dir(1:end-1);
end
if(cfile ~= 0 )
  l = min(nchar,length(cfile));
  ll = 0;
  for k = 1:Nfiles
    if( cfile == filenames(k,1:l)) break; end
    ll = ll+1;
  end
  if ll == Nfiles
%     file k is not already in list
    Nfiles = Nfiles + 1;
    filenames(Nfiles,1:l) = cfile(1:l);
    cdl = length(current_dir);
    dirnames(Nfiles,1:cdl) = current_dir;
    chngdir;
  end
  updlist;
  set(h_dir,'String',current_dir);
  browse;
end
