function [filenames,Nfiles] = chngnm(filenames)

% edits the file name list ... note: if you change
% the name of a file in the list, it will be assigned
%  the path name at the top of the menu
%    ... the original directory path name will be lost

global blanks NfilesMax nchar h_dir current_dir ...
   blanks_dir ed dirnames

size(dirnames)
s_str = 'String';
k = get(gco,'UserData')
s = get(gco,'String');
l = sum(s ~= ' ');
l = min(l,length(s));
lcd = length(current_dir);
if(l > 0 )
   temp = s(s ~= ' ');
   l = min(nchar,length(temp));
   filenames(k,:) = blanks;
   filenames(k,1:l) = temp(1:l);
   dirnames(k,:) = blanks_dir;
   dirnames(k,1:l) = current_dir;
else
   filenames(k,:) = blanks;
   dirnames(k,:) = blanks_dir;
end
ind = filenames ~= ' ';
ind = (max(ind')');
Nfiles = sum(ind);
ind = find(ind);
size(dirnames)
filenames(1:Nfiles,:) = filenames(ind,:);
dirnames(1:Nfiles,:) = dirnames(ind,:);
for k=Nfiles+1:NfilesMax
  filenames(k,:) = blanks;
  dirnames(k,:) = blanks_dir;
end
updlist
end

