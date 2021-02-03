%   create a TS object with two blocks from two old TS object files
Dir = '/Users/garyegbert/Desktop/MTprocessing/NEW/test/SyntheticTests/';
files = {'test1'};saveFile='test1';fileType = 'ASC';sta='ts1';
files = {'test2'};saveFile='test2';fileType = 'ASC';sta = 'ts2';
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
        case 'ASC'
            tsObj = asc_clk_TS([Dir  files{k} '.asc'],sta);
            tsObj.latitude = 45; tsObj.longitude =200;
    end
    Blocks(k).data = tsObj.data;
    Blocks(k).startTime = datetime(tsObj.startTime);
    %   really should not have dt defined in blocks and in parent object!
    %  also need to make sure blocks are consistent--same dt, Nch
    Blocks(k).dt = tsObj.dt;
end

TSobj.clock_zero = datetime(tsObj.zeroTime);
TSobj.Blocks = Blocks;

%%   now make header --   first headers for 5 channels'
ChResp = ChannelResponse();
MagChannelResponse = ChResp.LoadTableFile([Dir 'SYNmagResponse.mat']);
ElecChannelResponse = ChResp.LoadTableFile([Dir 'SYNelecResponse.mat']);
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

TSobj.save([Dir saveFile])