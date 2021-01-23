for k=1:NfilesMax
  filenames(k,:) = blanks;
end
Nfiles = 0;
updlist;
current_dir = blanks;
set(h_dir,'String',current_dir);
