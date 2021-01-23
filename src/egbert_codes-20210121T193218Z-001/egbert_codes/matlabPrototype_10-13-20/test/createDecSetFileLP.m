%%
%   for this version we do use LP filter and decimation by a factor of 4
Npts = 256;
filterlength  = 7;  %  all HP filters are the same 
overlapFraction = .25;
NDec = 4;
LPcoeff = [0.2154 0.1911 0.1307 0.0705];
trunc = Npts/4;
dec = cell(NDec,1);
win = dec;
LPcoeff = [0.2154 0.1911 0.1307 0.0705];
[B,A] = butter(filterlength,.0125,'high');
decT = 1;
decFac = 4;
for k = 1:NDec
   w = tukeywin(Npts,.5);
   win{k} = struct('Npts',Npts,...
       'overLap',Npts*overlapFraction,...
       'w',w',...
       'FCsave',[1,trunc],...
       'MissMax',2);
   dec{k} = struct('HPcoeffA',A,'HPcoeffB',B,...
       'decFac',decFac,'decT',decT,'f',.5,'LPcoeff',LPcoeff);
   decT = decT*decFac;
end

save CFG/decsetCfgLP.mat dec win

%%  Use this to check filter response
for idec = 1:NDec
    fvtool(dec{idec}.HPcoeffB,dec{idec}.HPcoeffA); xlim([0,.1])
    pause(5)
end

