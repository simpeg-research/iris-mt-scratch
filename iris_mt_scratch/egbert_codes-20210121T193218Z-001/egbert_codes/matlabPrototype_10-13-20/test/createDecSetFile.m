%%
%   for this version we do no decimation ... just make the stop band on the
%   HP filter lower and lower frequency   -- this is not necessarily good
%   for TS reconstruction -- might need to modify
Npts = 256;
filterlengths  = [7,6,5,4];
overlapFraction = .25;
NDec = 4;

%   
trunc = (Npts/4)*ones(NDec,1);
dec = cell(NDec,1);
win = dec;
LPcoeff = [0.2154 0.1911 0.1307 0.0705];
for k = 1:NDec
   w = tukeywin(Npts,.5);
   win{k} = struct('Npts',Npts,...
       'overLap',Npts*overlapFraction,...
       'w',w',...
       'FCsave',[1,trunc(k)],...
       'MissMax',2);
   [B,A] = butter(filterlengths(k),.025*.25^(k-1),'high');
   dec{k} = struct('HPcoeffA',A,'HPcoeffB',B,...
       'decFac',1,'decT',1,'f',.5,'LPcoeff',LPcoeff);
   Npts = Npts*4;
end

%save decsetCfg.mat dec win

%%  Use this to check filter response
for idec = 1:NDec
    fvtool(dec{idec}.HPcoeffB,dec{idec}.HPcoeffA); %xlim([0,.1])
    pause(5)
end