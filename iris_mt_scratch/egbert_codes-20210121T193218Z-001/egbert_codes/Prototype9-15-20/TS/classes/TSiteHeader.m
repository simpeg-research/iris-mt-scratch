classdef TSiteHeader
    % class for storing metadata for a single site
    %
    %    reorganizing TDataHeader -- channel specific info in this object,
    %    which is bottom of a heirearchy of three classes:
    %       channel, site, array
    %   array will contain an array of sites (+ info about array as a
    %   whole), sites will contain an array of channels (+ general site
    %   info)
    
    properties
        Channels % array of Nch TChannel Header objects, one for each channel
        
        UserMetaData; %  user metadata no specific format, just anything
        LatLong % site coordinates: float array in decimal degrees(2,NSites)
        XY; % cartesian coordinates (UTM projection) integer array in m (2,NSites)
        SiteID   % Sitestion ID
    end   % properties
    properties (Dependent)
        Nch      %  Nch = sum(NchSites)
        coordinateSystem  %  coordinate system for orientation for all channels in site
    end
    
    methods
        function obj = TSiteHeader(site,ChannelsIn)
            if nargin >= 1
                obj.SiteID = site;
                if nargin == 2
                    obj = obj.SetChannels(ChannelsIn);
                end
            end
        end
        %******************************************************************
        function obj = SetChannels(obj,ChannelsIn)
            allAreChannelObjects = true;
            for k = 1:length(ChannelsIn)
                allAreChannelObjects = ...
                    allAreChannelObjects && isa(ChannelsIn(k),'TChannelHeader');
            end
            if allAreChannelObjects
                obj.Channels = ChannelsIn;
            end
        end
        %******************************************************************
        function obj = set(obj,varargin)
            narg = nargin;
            if ~mod(nargin,2) 
                error('arguments to set must occur in pairs')
            end
            for k = 1:2:narg-1
                switch lower(varargin{k})
                    case 'channels'
                        obj = obj.SetChannels(varargin{k+1});
                    case 'coordinatesystem'
                        %   need to do something for consistency
                        %   between site and channel properties ...
                        if any(strcmpi(varargin{k+1},{'geographic','geomagnetic'}))
                            %  not coded
                        else
                            error('not a valide coordinate system')
                        end
                    case 'latlong'
                        if isreal(varargin{k+1}) && length(varargin{k+1}) ==2
                            obj.LatLong = varargin{k+1};
                        else
                            error('invalid values for lat and long')
                        end
                    case 'channelresponse'
                        obj.ChannelResposne = varargin{k+1};
                    case 'siteid'
                        obj.SiteID = varargin{k+1};
                    otherwise
                        error('not a valid property for TSiteHeader object')
                end
            end
        end
        %******************************************************************
        function  consistent = ConsistentHeaders(obj1,obj2)
            %   check to see if two headers are consistent -- i.e., same
            %   site, same channel headers ... as for two distinct runs at
            %   the same site
            
            consistent = strcmp(obj1.SiteID,obj2.SiteID);
            %   should test consistency of lat and long, but these are not
            %   always exactly the same in different runs
            %consistent = consistent && isequal(obj1.LatLong,obj2.LatLong);
            consistent = consistent && obj1.Nch==obj2.Nch;
            if not(consistent)
                return
            end
            for ich = 1:obj1.Nch
                consistent = consistent && isequal(obj1.Channels(ich),obj2.Channels(ich));
            end
        end
        %******************************************************************
        function  value = get.Nch(obj)
            value = length(obj.Channels);
        end
        %******************************************************************
        function  value = get.coordinateSystem(obj)
            ChannelCoordinates = cell(obj.Nch,1);
            for ich = 1:obj.Nch
                ChannelCoordinates{ich} = obj.Channels(ich).coordinateSystem;
            end
            if all(strcmpi(ChannelCoordinates,'geographic'))
                value = 'geographic';
            elseif all(strcmpi(ChannelCoordinates,'geomagnetic'))
                value = 'geomagnetic';
            else
                value = 'inconsistent';
            end
        end
    end
end  % classdef