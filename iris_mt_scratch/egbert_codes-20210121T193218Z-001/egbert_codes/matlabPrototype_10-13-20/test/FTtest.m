% testing FT 
Dir = '/Users/garyegbert/Desktop/MTprocessing/NEW/test/';
SubDir = './';
cfgfile = [Dir 'CFG/decsetCfgLP.mat'];
%dataFile = 'PAL59bc.mat'; stftFile = 'PAL59bc.stf';
%dataFile = 'PAM57bc.mat'; stftFile = 'PAM57bc.stf';
%dataFile = 'PAM57b.mat'; stftFile = 'PAM57b.stf';
%dataFile = 'PAM57c.mat'; stftFile = 'PAM57c.stf';
%dataFile = 'PAL59b.mat'; stftFile = 'PAL59b.stf';
%dataFile = 'PAL59c.mat'; stftFile = 'PAL59c.stf';
dataFile = 'TS/IAK34bc.mat'; stftFile = 'STF/IAK34bc.stf';
%dataFile = 'TS/NEN34bcd.mat'; stftFile = 'STF/NEN34bcd.stf';
%dataFile = 'test2.mat'; stftFile = 'test2.stf';
load([Dir SubDir dataFile])
clock_zero = tsObj.clock_zero;
FTobj = TSTFT();

FTobj.initWin(cfgfile,clock_zero,tsObj.dt)

FTobj.initTS(tsObj);

FTobj.TS2FC_LP(tsObj);
%FTobj.TS2FC(tsObj);
%   for now get rid of residual  ...
FTobj.res = [];
save([Dir SubDir stftFile],'FTobj');