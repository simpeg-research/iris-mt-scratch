classdef TTS < handle
    properties
        clock_zero
        %   can we use some sort of Header object
        Header    %  this will be an object of TSiteHeader class -- this 
                   % carries system response (in array of  TChannelHeader
                   % objects)
        missVals = NaN   %  missing value code
        %     following are for the actual TS data

        Blocks   %  array of data blocks, objects of class TSblock ...
                 %     often jsut one, but this is allows
                 %   storing data from "burst" sampling; note that
                 %   individual blocks may have some missing data
                 %   each Block carries it's own startTime; all have same
                 %   number of channels, same sample rate
    end
    properties (Dependent)
        NBlock   % number of TS blocks
        NCh      %   get this from NCh of Blocks (which must be consistent)
        dt       %  same as NCh
    end
    
    methods
        function obj = TTS()
            %   basic class constructor ... need to make routines (in sub
            %   lasses?)  to load data from files, fill in/initialize needed
            %   properties, including channel responses
        end
        %******************************************************************
        function value = get.NBlock(obj)
            value = length(obj.Blocks);
        end
        %******************************************************************
        function value = get.NCh(obj)
            if ~isempty(obj.Blocks)
                if consistent(obj.Blocks)
                    value = obj.Blocks(1).NCh;
                else
                    error('Blocks not consistent: NCh')
                end
            end
        end
        %******************************************************************
        function value = get.dt(obj)
            if ~isempty(obj.Blocks)
                if consistent(obj.Blocks)
                    value = obj.Blocks(1).dt;
                else
                    error('Blocks not consistent: dt')
                end
            end
        end
        %******************************************************************
        function save(obj,filename)
            %   saves TS object as a mat file, with a standard name for the
            %   object
            %   Usage: save(obj,filename);
            tsObj = obj;
            save(filename, 'tsObj');
        end
        %   note: since we are allowing for multiple data blocks, most
        %   basic TS methods are defined in TSblock, and this only provides
        %   a loop iover blocks -- as for TSblock, many more useful methods
        %   could/should be defined
        %******************************************************************
        function objOut = copy(objIn)
            %   ccreate copy of input object
            objOut = TTS();
            objOut.Header = objIn.Header;
            objOut.clock_zero = objIn.clock_zero;
            Blk(objIn.NBlock) = TSblock();
            for iblk = 1:objIn.NBlock
                Blk(iblk) = objIn.Blocks(iblk).copy;
            end
            objOut.Blocks = Blk;
        end
        %******************************************************************
        function objOut = plus(obj1,obj2)
            %   add obj1 to obj2 -- keeping only the part of the TS blocks
            %   that overlaps
            %   NOTE this method overloads + in matlab, so can call this as
            %       objOut = obj1 + obj2;
            
            if obj1.dt ~= obj2.dt
                error('Cannot add TS blocks with different sampling rates')
            end
        
            objOut = obj1.copy;
            for iblk = 1:obj.NBlock
                objOut.Blocks(iblk) = obj1.Blocks(iblk)+obj2.Blocks(iblk);
            end
        end
        %******************************************************************
        function [tsHP] = hpFilter(obj,win)
            %   High pass filter all blocks; residual (low-pass filtered)
            %   TS blocks overwrite input in obj
            tsHP = obj.copy;
            for iblk = 1:obj.NBlock
                tsHP.Blocks(iblk) = obj.Blocks(iblk).hpFilter(win);
            end
        end
         %******************************************************************
        function [tsLP] = lpFilter(obj,win)
            %   High pass filter all blocks; residual (low-pass filtered)
            %   TS blocks overwrite input in obj
            tsLP = obj.copy;
            for iblk = 1:obj.NBlock
                tsLP.Blocks(iblk) = obj.Blocks(iblk).lpFilter(win);
            end
        end
        %******************************************************************
        function decimate(obj,decFac)
            %   Decimate all blocks, overwriting input object; as for
            %   TSblock code, this assumes that any needed anit-alias
            %   filtering has already been applied
            for iblk = 1:obj.NBlock
                obj.Blocks(iblk) = decimate(obj.Blocks(iblk),decFac);
            end
        end
    end
end