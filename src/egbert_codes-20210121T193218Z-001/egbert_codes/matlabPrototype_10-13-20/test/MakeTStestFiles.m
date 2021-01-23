%   create a TS object with two blocks from two old TS object files
Dir = '/Users/garyegbert/Desktop/MTprocessing/NEW/test/';

%files = {'PAL59b','PAL59c'};  saveFile = 'PAL59bc.mat';
%    these are to save each run in a separate file (with one block each)
%files = {'PAL59b'};   saveFile = 'PAL59b';
%files = {'PAL59c'};   saveFile = 'PAL59c';
%files = {'PAM57b','PAM57c'};  saveFile = 'PAM57bc.mat';
%files = {'PAM57b'};   saveFile = 'PAM57b';
%files = {'PAM57c'};   saveFile = 'PAM57c';
%files = {'IAK34b','IAK34c'};saveFile='IAK34bc';fileType = 'BIN';
files = {'NEN34b','NEN34c','NEN34d'};saveFile='NEN34bcd';fileType = 'BIN';
TSobj = TTS();
nFiles = length(files);
Blocks(nFiles) = TSblock();
for k = 1:length(files)
    switch fileType
        case 'MAT'
            load([Dir 'Original/' files{k}])
        case 'BIN'
            SCALE = false;
            tsObj = nimsbin_TS([Dir 'Original/' files{k} '.bin'],SCALE);
    end
    tsObj.deSpike
    Blocks(k).data = tsObj.data;
    Blocks(k).startTime = datetime(tsObj.startTime);
    %   really should not have dt defined in blocks and in parent object!
    %  also need to make sure blocks are consistent--same dt, Nch
    Blocks(k).dt = tsObj.dt;
end

TSobj.clock_zero = datetime(tsObj.zeroTime);
TSobj.Blocks = Blocks;
clear Blocks
%%   now make header --   first headers for 5 channels'
ChResp = ChannelResponse();
MagChannelResponse = ChResp.LoadTableFile([Dir 'SYS/NIMSmagResponse.mat']);
ElecChannelResponse = ChResp.LoadTableFile([Dir 'SYS/NIMSelecResponse.mat']);
ChHd(5) = TChannelHeader;
magCh = MagneticChannel;
ChHd(1) = magCh.set('azimuth',0,'tilt',0,'coordinateSystem','geomagnetic',...
     'declination',10,'ChannelID','Hx','ChannelResponse',MagChannelResponse);
ChHd(2) = magCh.set('azimuth',90,'tilt',0,'coordinateSystem','geomagnetic',...
    'declination',10,'ChannelID','Hy','ChannelResponse',MagChannelResponse);
ChHd(3) = magCh.set('azimuth',0,'tilt',0,'coordinateSystem','geomagnetic',...
    'declination',10,'ChannelID','Hz','ChannelResponse',MagChannelResponse,'vertical',true);
elecCh = ElectricChannel;
ChHd(4) = elecCh.set('azimuth',0,'tilt',0,'coordinateSystem','geomagnetic',...
    'declination',10,'ChannelID','Ex','ChannelResponse',ElecChannelResponse,'DipoleLength',0.1);
ChHd(5) = elecCh.set('azimuth',90,'tilt',0,'coordinateSystem','geomagnetic',...
    'declination',10,'ChannelID','Ey','ChannelResponse',ElecChannelResponse,'DipoleLength',0.1);
siteName = tsObj.name(1:3);
TSobj.Header = TSiteHeader(siteName,ChHd); 
TSobj.Header = TSobj.Header.set('latlong',[tsObj.latitude tsObj.longitude]);

TSobj.save([Dir 'TS/' saveFile])