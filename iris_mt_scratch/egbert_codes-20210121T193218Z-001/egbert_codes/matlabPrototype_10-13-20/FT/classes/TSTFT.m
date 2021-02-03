classdef TSTFT < handle
    
    %   class for Short-Time Windowed FT : linked to a TS object, somehow!
    
    properties
        %   site/file information
        Header  %   TSite Header object,copied from TS object -- contains system
                %    response for each channel
        NBlock  %   Number of TS blocks
        NCh    %   number of data channels
        %  timing information -- I am just using datevec -- these could be
        %  datetime objects
        dt      %  sample rate in TS object
        clock_zero   % clock reference; this should be fixed for the survey,
                 % carried with the TS object ... zdroTime is carried in
                 
        %   propoerties that control the windowing and decimation 
        %NDec   %   number of decimation levels  -- store this in dec?
        Dec    %   object of class TDecimate: controls decimation
        Win    %   array of dec.NDec objects of class TWindow
        
        %   "Output" properties --
        FC     % arrays of TFC1Dec objects, one per decimation level, merged over all
        %          blocks
        res    %   residual  :  object of class TS, containing residual TS
        %     from final HPfilter (decimated if appropriate)
        
    end
    
    methods
        function obj = TSTFT()
          % basic class constructor ...
        end
         %******************************************************************
        function initWin(obj,cfgFile,clock_zero,dt)
            %   initialization of Win and Dec using old cfg file -- need 
            %     clock_zero to fully initialize Win; could set this later?
            %   need dt to initialize windows ...

            load(cfgFile,'dec','win')
            %  not sure how decimation fits in here -- moved hp
            %  filtering into TWindow class
            obj.Dec = TDecimate().SetDec(dec);
            temp = TWindow();
            windows(obj.Dec.NDec) = temp;
            decT = 1;
            for id = 1:obj.Dec.NDec
                windows(id) = windows(id).SetWin(win{id},dec{id});
                windows(id).clock_zero = clock_zero;
                windows(id).decT = decT;
                windows(id).window_dt = dt;
                dt = dt*obj.Dec.decFactor(id);
                decT = decT*obj.Dec.decFactor(id);
            end
            obj.Win = windows;
        end
        %******************************************************************
        function initTS(obj,tsObj)
            %   initializes WinFT object from TS object
            obj.NBlock = tsObj.NBlock;
            obj.clock_zero = tsObj.clock_zero;
            obj.NCh = tsObj.NCh;
            obj.dt = tsObj.dt;
            obj.Header = tsObj.Header;
            
            %  initialize FC objects for all decimation levels   ---
            %  need to account for decimation!   Probably this
            %  initialization belongs inside a decimation loop!
            FCs(obj.Dec.NDec)=TFC1Dec();
            for idec = 1:obj.Dec.NDec-1
                FCs(idec) = TFC1Dec();
                FCs(idec).SetFC1Dec(tsObj,obj.Win(idec));     
            end
            obj.FC = FCs;
        end
        %******************************************************************
        function TS2FC(obj,tsObj)
            %    this manages the filtering and decimation and does the
            %    actul FT.   This version uses the following sequence:
            %    ---> High-pass filter, overwriting input ts with residual (HP
            %          subtracted);  this is the LP filtered TS used for
            %          higher decimation levels
            %    ---> FT HP-filtered TS
            %    ---> possibly decimate residual (LP) TS; use this for next
            %         decimation level
          
            for idec = 1:obj.Dec.NDec
                %  hpfilter all blocks -- return two TS objects, tsHP is
                %  high-passed, residual (low-passed) overwrites tsObj
                tsHP = tsObj.hpFilter(obj.Win(idec));
                %  hp ts --> TFC1Dec object
                %    first create FC object for 1 decimation level
                obj.FC(idec).SetFC1Dec(tsHP,obj.Win(idec));
                %  then FT the HP filtered TS
                obj.FC(idec).FT(tsHP);
                %  Decimate residual (LP filtered) if approppriate
                if obj.Dec.decFactor(idec)>1
                    tsObj.decimate(obj.Dec.decFactor)
                end
            end
            %   lp TS gets stored as res
            obj.res = tsObj;
        end
        %******************************************************************
        function TS2FC_LP(obj,tsObj)
            %    this manages the filtering and decimation and does the
            %    actul FT.   This version uses the following sequence:
            %    ---> High-pass filter, but do not overwrite original TS 
            %          object
            %    ---> FT HP-filtered TS
            %    ---> low pass filter original TS object, and decimate
            %    ---> loop to next decimation level
            
            returnLP=false;
            for idec = 1:obj.Dec.NDec
                %  hpfilter all blocks -- but do not overwrite original TS
                %  object
                tsHP = tsObj.hpFilter(obj.Win(idec),returnLP);
                %  hp ts --> TFC1Dec object
                %    first create FC object for 1 decimation level
                obj.FC(idec).SetFC1Dec(tsHP,obj.Win(idec));
                %  then FT the HP filtered TS
                obj.FC(idec).FT(tsHP);
                %  Decimate residual (LP filtered) if approppriate
                %  (overwrite original ...)
                [tsLP] = lpFilter(tsObj,obj.Win(idec));
                tsObj = tsLP;
                if obj.Dec.decFactor(idec)>1
                    tsObj.decimate(obj.Dec.decFactor(idec))
                end
            end
            %   lp TS gets stored as res
            obj.res = tsObj;
        end
        %******************************************************************
        function tsOut = FC2TS(obj,analytic,addResid)
            % reconstructs time series from a WinFT object
            % Usage:   X = FC2TS(obj,analytic)
            %           second argument is optional (defaults to false)
            %           if analytic == true compute analytic signal,
            %           so obj.y is now a complex time series
            %    THIS IS NOT DEBUGGED -- and not really part of the current
            %    package; would only 
            if nargin < 3
                addResid = false;
                if nargin < 2
                    analytic = false;
                end
            end
 
            %  some initialization  .... ?????
            tsOut = TS();  %   really just need the Header (obj.Header) and 
            %   a few other things ...   need to add this still
            
            for idec = 1:obj.Dec.NDec
                %    need to do more when there is decimation -- can't add
                %    TS objects with different samplilng rates!   Could
                %    modify FTinv to generate TS at highter sample rate
                if idec == 1
                    tsOut = FTinv(obj.FC(1),tsOut,analytic);
                else
                    temp = TFinv(obj.FC(idec),tsOut,analytic);
                    tsOut = tsOut+temp;
                end
            end
            if addResid
                tsOut = tsOut+obj.res;
            end
        end
        %******************************************************************
        function objOut = copy(obj)
            %  copies public attributes 
            objOut = TSTFT();
            objOut.Header = obj.Header;
            objOut.Dec = obj.Dec;
            objOut.Win = obj.Win;
            objOut.NBlock = obj.NBlock;
            objOut.NCh = obj.NCh;  
            objOut.dt = obj.dt;
            objOut.clock_zero  = obj.clock_zero; 
            objOut.FC = obj.FC;   
            objOut.res =obj.res;
        end
        %******************************************************************
        function  zero(obj)
            %  zeros FC, residuals -- in place
            for idec = 1:obj.Dec.NDec
                obj.FC(idec).zero ;
            end
            obj.res.zero;
        end
        %******************************************************************
        function objSum = plus(obj1,obj2)
        %   sums FC fields in two compatible WinFT objects
        %    for now just assuming the objects are compatible ...
           objSum = copy(obj1);
           for id = 1:obj1.NDec
               objSum.FC{id}.X = obj1.FC{id}.X+obj2.FC{id}.X;
           end   
           objSum.res = obj1.res+obj2.res;
        end
        %******************************************************************
        function objBand = extractBand(obj,iBand)
        %   extracts an object from the WinFT object obj, corresponding to
        %   the frquency band defined by a set of decimation levels, and
        %   within each, frequencies
        %    iBand is a cell  array, one band for each decimation level,
        %    with each cell containing a structure giving the decimation 
        %    level and the range of frequencies to extract

           objBand = copy(obj);
           objBand.NDec = length(iBand);
           objBand.dec = cell(objBand.NDec,1);
           objBand.win = cell(objBand.NDec,1);
           objBand.i0 = zeros(objBand.NDec,1);
           objBand.FC = cell(objBand.NDec,1);
           for id = 1:objBand.NDec
               objBand.dec{id} = obj.dec{iBand{id}.idec};
               objBand.win{id} = obj.win{iBand{id}.idec};
               objBand.win{id}.FCsave = iBand{id}.iband;
               objBand.i0(id) = obj.i0(iBand{id}.idec);
               ifc1 = obj.win{iBand{id}.idec}.FCsave(1);
               i1 = max(1,iBand{id}.iband(1)-ifc1+1);
               ifc2 = obj.win{iBand{id}.idec}.FCsave(2);
               i2 = min(ifc2-ifc1+1,iBand{id}.iband(2)-ifc1+1);
               if ~isempty(obj.FC{iBand{id}.idec}.X)
                   objBand.FC{id}.X = obj.FC{iBand{id}.idec}.X(:,i1:i2,:);
                   objBand.FC{id}.segNumber = obj.FC{iBand{id}.idec}.segNumber;
                   objBand.FC{id}.sampNumber = obj.FC{iBand{id}.idec}.sampNumber;
                   objBand.FC{id}.freqs = obj.FC{iBand{id}.idec}.freqs(i1:i2);
               else
                   objBand.FC{id} = struct('X',[],'segNumber',[],'sampNumer',[],...
                       'freqs',[]);
               end
           end
        end
        
    end      
end