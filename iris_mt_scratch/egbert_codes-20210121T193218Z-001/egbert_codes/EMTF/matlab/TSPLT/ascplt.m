%  opens ascii file CFILE ( output from bin2asc)
%  with NCH channels of data (so there are NCH+1 columns in the file)
%  reads data in, and starts PLOTTS
%  THIS IS A SCRIPT: BEFORE CALLING SET VARIABLES 
%   CFILE  = file name to plot
%   NCH  = number of DATA channels in file
chid = ['#1';'#2';'#3';'#4';'#5';'#6';'#7';'#8';'#9';'10'];
fid = fopen(CFILE,'r');
data = fscanf(fid,'%d',[NCH+1,inf]);
data = data(2:NCH+1,:);
ch_id = ch_id(1:NCH,:);
plotts

