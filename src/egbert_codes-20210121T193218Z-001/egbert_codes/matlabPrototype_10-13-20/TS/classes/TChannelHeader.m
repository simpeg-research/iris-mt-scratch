classdef TChannelHeader < matlab.mixin.Heterogeneous
    % class for storing metadata for a single channel
    %    reorganizing TDataHeader -- channel specific info in this object,
    %    which is bottom of a heirearchy of three classes:
    %       channel, site, array
    %   array will contain an array of sites (+ info about array as a
    %   whole), sites will contain an array of channels (+ general site
    %   info)
    
    properties
        azimuth % Channel azimuth
        tilt    %  Channel tilt
        coordinateSystem  %  'geographic" or "geomagnetic" -- coordinate system for orientation
        declination
        ChannelID  % Channel ID :  character array
        ChannelResponse
        UserData   %   any additional description or information
    end   % properties
    
    methods
        function obj = TChannelHeader()
        end
    end
end  % classdef