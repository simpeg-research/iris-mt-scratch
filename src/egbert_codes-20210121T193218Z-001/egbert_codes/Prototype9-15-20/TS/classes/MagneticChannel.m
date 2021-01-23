classdef MagneticChannel < TChannelHeader
    % class for storing metadata for a single magnetic channel
    %
    %    reorganizing TDataHeader -- channel specific info in this object,
    %    which is bottom of a heirearchy of three classes:
    %       channel, site, array
    %   array will contain an array of sites (+ info about array as a
    %   whole), sites will contain an array of channels (+ general site
    %   info)
    
    properties
        %   hmmm -- not quite sure how to deal with vertical H channels and
        %   tilts
        vertical = 0
    end   % properties
    
    methods
        function obj = MagneticChannel()
            obj = obj@TChannelHeader();
        end
        %******************************************************************
        function obj = set(obj,varargin)
            narg = nargin;
            if ~mod(nargin,2)
                error('arguments to set must occur in pairs')
            end
            for k = 1:2:narg-1
                switch lower(varargin{k})
                    case 'vertical'
                        obj.vertical = varargin{k+1};
                    case 'azimuth'
                        obj.azimuth = varargin{k+1};
                    case 'tilt'
                        obj.tilt = varargin{k+1};
                    case 'declination'
                        obj.declination = varargin{k+1};
                    case 'coordinatesystem'
                        if any(strcmpi(varargin{k+1},{'geographic','geomagnetic'}))
                            obj.coordinateSystem = varargin{k+1};
                        else
                            error('not a valide coordinate system')
                        end
                    case 'channelid'
                        obj.ChannelID = varargin{k+1};
                    case 'channelresponse'
                        obj.ChannelResponse = varargin{k+1};
                    case 'userdata'
                        obj.UserData = varargin{k+1};
                    otherwise
                        error('not a valid property for TChannelHeader object')
                end
            end
        end
    end
end  % classdef