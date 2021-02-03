classdef TMarkedData
    % store time intervals, channels, and possibly site ID for marked
    % sections of time series; allows multiple intervals, but just one list
    % of channels, and one siteID
    
    properties
        StartTime    %   datetime objects giving start of marked intervals
        EndTime    %   datetime object giving end of marked interval
        Channels   %  list of channel numbers  -- could add channel names/IDs
        SiteID     %   site ID
    end
    
    methods
        function obj = TMarkedData(time1,time2,Ch,site)
            % Usage: obj = TMarkedData(time1,time2,Ch,site)
            %   time1, time 2 can be arrays (of same size); 
            %   Ch is list of channls marked (integer array)
            %   site is opotional
            obj.StartTime = time1;
            obj.EndTime = time2;
            obj.Channels = Ch;
            if nargin==4
                obj.SiteID = site;
            end
        end
        %   might add methods to create new object from one or more other
        %   other objects (e.g., merge -- with some rule about channels)
    end
end

