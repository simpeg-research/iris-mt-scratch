classdef TArrayHeader
    % class for storing array header object
    
    %    reorganizing TDataHeader -- channel specific info in this object,
    %    which is bottom of a heirearchy of three classes:
    %       channel, site, array
    %   array will contain an array of sites (+ info about array as a
    %   whole), sites will contain an array of channels (+ general site
    %   info)
    
    
    properties
        ArrayName;
        UserMetaData; %  user metadata no specific format, just anything
        Sites   %   array of TSiteHeader objects
    end   % properties
    
    properties (Dependent)
        NSites; %   Number of sites : integer
        NchSites %  Number of channels at each site : integer array (NSites)
        Nch      %  Nch = sum(NchSites)
        ih  %   indicies of first channel for each site :integer array (NSites)
        LatLong % site coordinates: integer array (2,NSites)
        SiteIDs   % station ID's :  character array
    end
    
    methods
         function obj = TArrayHeader(NameIn,SitesIn)
            if nargin >= 1
                obj.ArrayName = NameIn;
                if nargin == 2
                    obj = obj.SetSites(SitesIn);
                end
            end
        end
        %******************************************************************
        function obj = SetSites(obj,SitesIn)
            allAreSiteObjects = true;
            for k = 1:length(SitesIn)
                allAreSiteObjects = ...
                    allAreSiteObjects && isa(SitesIn(k),'TSiteHeader');
            end
            if allAreSiteObjects
                obj.Sites = SitesIn;
            end
        end
        %******************************************************************
        function value = get.NSites(obj)
            value = length(obj.Sites);
        end
        %******************************************************************
        function value = get.NchSites(obj)
            value = zeros(obj.NSites,1);
            for iSite = 1:obj.NSites
                value(iSite) = obj.Sites(iSite).Nch;
            end
        end    
        %******************************************************************
        function value = get.Nch(obj)
            value = sum(obj.NchSites);
        end      
        %******************************************************************
        function value = get.ih(obj)
            value = cumsum([1 (obj.NchSites)']);
        end 
        %******************************************************************
        function value = get.LatLong(obj)
            value = zeros(obj.NSites,2);
            for iSite = 1:obj.NSites
                value(iSite,:)= obj.Sites(iSite).LatLong;
            end
        end
        %******************************************************************
        function value = get.SiteIDs(obj)
            value = cell(obj.NSites);
            for iSite = 1:obj.NSites
                value{iSite}= obj.Sites(iSite).SiteID;
            end
        end
    end   % methods
    
end  % classdef