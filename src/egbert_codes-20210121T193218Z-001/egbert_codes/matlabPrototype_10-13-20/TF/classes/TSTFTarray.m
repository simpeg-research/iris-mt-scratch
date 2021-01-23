classdef TSTFTarray < handle
    %   class to support creating FC arrays from STFT objects stored as mat files
    %      simplified -- not a subclass of TFC -- cannot be used for array
    %      processing without additional features/changes.  Just intended
    %      for SS and RR processing
    properties
        ArrayInfo   % cell array containing list of STFT file names (created 
                    % from tranmt.cfg + band setup file, array name
        Array   % cell array containing all STFT objects
        FCdir = './'    %  root path for STFT files
        EstimationBands    %   array of dimension (nBands,3) giving decimation
                        % levels and band limits, as returned by function
                        % ReadBScfg.
        Header     %    TArrayHeader object -- mostly just an array of site headers
        iBand      %   current band number
        OneBand    %   data for one band --  data for one band -- a TFC1Dec
                   %   object, containing all FCs for all sites/runs for band
                   %   iBand, merged and aligned
        T          %   period for center of  current band--could be dependent
    end
    properties (Dependent)
        NSites
        NBands
    end
    
    methods
        function obj = TSTFTarray(TranMTcfgFile,FCdir)
            % class constructor
            if nargin > 0
                obj.ArrayInfo = ReadTranMTcfg(TranMTcfgFile); 
                if nargin > 1
                    obj.FCdir = FCdir;
                end
            end      
        end
        %******************************************************************ch
        function loadFCarray(obj)
            %  initialize and load all STFT objects  -- for now no
            %  checks  on consistency
            obj.Array = cell(length(obj.ArrayInfo.Files),1);
            %   read in estimation bands
            obj.EstimationBands = ReadBScfg(obj.ArrayInfo.bandFile);
            %   load all STFT files for all sites/runs
            SiteHeaders(obj.NSites) = TSiteHeader();
            for j = 1:obj.NSites
                nFCfiles = length(obj.ArrayInfo.Files{j}.FCfiles);
                %    this just creates an array of empty TSTFT objects of
                %    length nFCfikles -- one for each run
                obj.Array{j}(nFCfiles) = TSTFT();
                for k = 1:nFCfiles
                    %  full path name of file to load
                    cfile = [obj.FCdir obj.ArrayInfo.Files{j}.FCfiles{k}];
                    load(cfile,'-mat','FTobj')
                    obj.Array{j}(k) = FTobj;
                    if k==1
                        SiteHeaders(j) = obj.Array{j}(k).Header;
                    else
                        if ~ConsistentHeaders(SiteHeaders(j),obj.Array{j}(k).Header)
                            error('Headers for two runs are not consistent')
                        end
                    end
                end
            end
            obj.Header = TArrayHeader(obj.ArrayInfo.ArrayName,SiteHeaders);
            %   probably should carry a Header for this object;  
            %   Also should compare headers to make sure that runs for a
            %   given site are consistent, and that sites are consistent
            %   (use same Windows, start times, and also overlap in time?)  
        end
        %******************************************************************
        function T = extractFCband(obj,ib)
            %  Usage: T = extractFCband(obj,ib);
            %   loads FCs for full array for frequency band ib into TSTFTarray
            %     object, storing in OneBand.
            %   Returns T - 1/f_center where f_center is center frequency
            %   of band
            obj.iBand = ib;  % could add some error checking
            band = obj.EstimationBands(ib,:);
            AllSites(obj.NSites) = TFC1Dec();
            for j = 1:obj.NSites
                %   first extract TFC1Dec objects defined by band for one
                %   site
                nFCfiles = length(obj.Array{j});
                AllRuns(nFCfiles) = TFC1Dec();
                for k = 1:nFCfiles
                    AllRuns(k) = obj.Array{j}(k).FC(band(1)).extractBand(band(2:3));
                    %   make sure all objects have orderd segments,
                    %   complete block
                    AllRuns(k).timeSort;
                    AllRuns(k).reblock;
                end
                %   merge all runs for site j
                AllSites(j) = AllRuns.mergeRuns;
                clear('AllRuns');
            end
            %  merge all sites into a single TFC1Dec object
            obj.OneBand = AllSites.mergeSites;
            %   nominal period for estimation band: 1/f_center
            T = 1./mean(obj.OneBand.freqs);
        end
        %******************************************************************
        function [H,E,R] = getMTTFdata(obj,TFHD)
            %    Usage: [H,E] = obj.getMTTFdata(TFHD);
            %           [H,E,R] = obj.getMTTF(TFHD);
            %   extracts arrays needed for estimation of MT transfer
            %   functions:  H(NSeg,2) == magnetic field FCs
            %               E(NSeg,Nch) = electric field (and optionally
            %                  vertical magnetic) field FCs; E(:,1) is Hz if this
            %                  is returned;
            %               R(NSeg,2) = reference fields for RR estimation
            %                  (optional)
            %    TFHD is TFHeader object, whioch defines local and (optionally) remote sites,
            %           and channels at these sites that will be used for
            %           processing.   TFHeader.ArrayHeader2TFHeader creates
            %           this header from TArrayHeader, using default
            %           assumptions about channels (i.e., use horizontal
            %           mags at local as input channels, at remote for
            %           reference, etc.
            
            %  find local site numbrt
            LocalInd = find(strcmp(TFHD.LocalSite.SiteID,obj.Header.SiteIDs));
            Hind = TFHD.ChIn+obj.Header.ih(LocalInd)-1;
            Eind = TFHD.ChOut+obj.Header.ih(LocalInd)-1;
            H = obj.OneBand.FC(Hind,:,:);
            [nch,nfc,nseg] = size(H);
            H = reshape(H,nch,nfc*nseg).';
            E = obj.OneBand.FC(Eind,:,:);
            [nch,nfc,nseg] = size(E);
            E = reshape(E,nch,nfc*nseg).';
            if strcmp(TFHD.Processing,'RR')
                %  find refertence site number if a character string is provide
                RemoteInd = find(strcmp(TFHD.RemoteSite.SiteID,obj.Header.SiteIDs));
                Rind = TFHD.ChRef + obj.Header.ih(RemoteInd)-1;
                R = obj.OneBand.FC(Rind,:);
                [nch,nfc,nseg] = size(R);
                R = reshape(R,nch,nfc*nseg).';
            end
        end
        %******************************************************************
        function result = get.NSites(obj)
            result = length(obj.Array);
        end
        %******************************************************************
        function result = get.NBands(obj)  
            [result,~] = size(obj.EstimationBands);
        end
    end
end