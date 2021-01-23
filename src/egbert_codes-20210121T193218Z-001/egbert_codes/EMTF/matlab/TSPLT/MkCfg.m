%  Make emi-dnff.inp
fid = fopen('emi-dnff.inp','w');
fprintf(fid,'%s','EMI ACQMT-24');
fprintf(fid,'\n');
%  Run directory
runDirectory = deblank(dirnames(1,:));
if(runDirectory(end) == '\')
   runDirectory = runDirectory(1:end-1);
end
%  Assume that the run directory starts c:\ ...
lEnd = length(runDirectory);
lSurv = 3;
while (runDirectory(lSurv+1) ~= '\')
   lSurv = lSurv + 1;
end
survey = runDirectory(4:lSurv);
surveyFile = [ runDirectory(1:lSurv) '\' survey '.srv' ];
lSetup = lSurv + 1;
while (runDirectory(lSetup+1) ~= '\')
   lSetup = lSetup + 1;
end

temp = deblank(filenames(1,:));
run = runDirectory(lSetup+2:end);
Band = temp(end);
runFile = [ runDirectory '\' run '.b0' Band ];
fprintf(fid,'%s',surveyFile);
fprintf(fid,'\n');
fprintf(fid,'%s',runFile);
fprintf(fid,'\n');
fprintf(fid,'%d \n',Nfiles);
for k = 1:Nfiles
   fprintf(fid,'%s',deblank(filenames(k,:)));
   fprintf(fid,'\n');
end
fprintf(fid,'%s','C:\Bin_Mt24\decset.cfg');
fprintf(fid,'\n');
fprintf(fid,'%s','C:\Bin_Mt24\pwset.cfg');
fclose(fid);

%  Make tranmt.cfg
fid = fopen('tranmt.cfg','w');
fprintf(fid,'%s',run);
fprintf(fid,'\n');
fprintf(fid,'%s','C:\Bin_Mt24\ss_opts.cfg');
fprintf(fid,'\n');
fprintf(fid,'%d \n',1);
fprintf(fid,'%d %d \n',1,Nfiles);
fprintf(fid,'%s',['.\' run '.f' num2str(Nfiles)]);
fprintf(fid,'\n');
fprintf(fid,'%s','n');
fclose(fid)

%  Make mt24.bat
%  For some reason I can't get new line correct for DOS
%fid = fopen('mt24.bat','w');
%fprintf(fid,'%s \n','C:\bin_mt24\dnff');
%fprintf(fid,'%s','C:\bin_mt24\tranmt');
%fprintf(fid,'\n');
%fprintf(fid,'%s','del *.f*');
%fclose(fid)
