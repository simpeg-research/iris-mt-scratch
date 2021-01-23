classdef TFHeader
    % class for storing metadata for a TF estimate
    
    properties
        LocalSite  %  TSiteHeader object -- info about local site (location,
                   %  channel azimuths, etc.
        ChOut      %  output (predicted) channels -- numbers within LocalSite
                   %      channel list -- usually E and Hz
        ChIn       %  input (predicting) channels -- numbers within LocalSite
                   %      channel list  -- usually Hx, Hy
        Processing     %   single site or remote ref -- could generalize, e.g.,
                   %   multivariate array, multiple remote, etc.
        RemoteSite %   TSiteHeader objecg -- info about remote site (as for local)
        ChRef      %   reference channels -- numbers within RemoteSite channel list
        UserMetaData; %  user metadata no specific format, just anything
    end   % properties
    properties (Dependent)
        NChIn
        NChOut
    end
    methods
        function obj = TFHeader()
        end
        %******************************************************************
        function result = get.NChIn(obj)
            result = length(obj.ChIn);
        end
        %******************************************************************
        function result = get.NChOut(obj)
            result = length(obj.ChOut);
        end        
        %******************************************************************
        function obj = ArrayHeader2TFHeader(obj,ArrayHD, SITES)
            %   Usage: obj = ArrayHeader2TFHeader(obj,ArrayHD, OPTIONS)
            %        given an input TArrayHeader, 
            %   and SITES, a structure defining:
            %          RR    -- true for RR processing, otherwise SS
            %          LocalSite   -- site ID or number for local site
            %          RemoteSite  -- site ID or number for Reference site
            %          VTF     --  true if Vertical Field TF should also be estimated
            %
            %          Could add more if we want to generalize to other
            %          estimation schemes
            %    this always uses horizontal magnetics for ChIn and ChRef, 
            %          electrics and Hz for ChOut -- could generalize
         
            %  find local site number if a character string is provide
            if ischar(SITES.LocalSite)
                LocalInd = find(strcmp(SITES.LocalSite,ArrayHD.SiteIDs));
            else
                LocalInd = SITES.LocalSite;
            end
            %  find local magnetic and electric field channel numbers
            obj.LocalSite = ArrayHD.Sites(LocalInd);
            obj.ChIn = [];
            obj.ChOut = [];
            HZind = [];
            for ich = 1:obj.LocalSite.Nch
                if isa(obj.LocalSite.Channels(ich),'MagneticChannel')
                    if obj.LocalSite.Channels(ich).vertical
                        HZind = [HZind ; ich];
                    else
                        obj.ChIn = [obj.ChIn ; ich];
                    end
                elseif isa(obj.LocalSite.Channels(ich),'ElectricChannel')
                    obj.ChOut = [obj.ChOut ; ich];
                end
            end
            if length(obj.ChIn) ~=2
                error('did not find exactly 2 horizontal magnetic channels for local site')
            end
            if SITES.VTF
                if isempty(HZind)
                    error('no vertical magnetic channel found for local site')
                elseif length(HZind) > 1
                    error('more than one vertical magnetic channel found for local site')
                else
                    obj.ChOut = [HZind;obj.ChOut];
                end
            end
            if SITES.RR
                obj.Processing = 'RR';
                %  find refertence site number if a character string is provide
                if ischar(SITES.RemoteSite)
                    ReferenceInd = find(strcmp(SITES.RemoteSite,obj.Header.SiteIDs));
                else
                    ReferenceInd = SITES.RemoteSite;
                end
                %   extract reference channels --  here we assume these are
                %   always magnetic (the normal approach), but this code
                %   could easily be modified to allow more general
                %   reference channels
                obj.RemoteSite = ArrayHD.Sites(ReferenceInd);
                obj.ChRef = [];
                for ich = 1:obj.RemoteSite.Nch
                    if isa(obj.RemoteSite.Channels(ich),'MagneticChannel') && ...
                            ~obj.RemoteSite.Channels(ich).vertical
                        obj.ChRef = [obj.ChRef ; ich];
                    end
                end
                if length(obj.ChRef) ~=2
                    error('did not find exactly 2 horizontal magnetic channels for reference site')
                end
            else
                obj.Processing = 'SS';
            end
        end
    end
end
