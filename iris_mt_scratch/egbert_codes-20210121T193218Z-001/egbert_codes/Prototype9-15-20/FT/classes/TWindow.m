classdef TWindow
    %  TWindow class -- an array of these defines window amd timeing properties
    %     for each decimation level  
    %   Note that this combines parts of what were in "dec" and "win" --
    %     I think this makes more sense, as the HP filtering is an
    %     intrinsic part of the windowing -- together with tapering to zero
    %     at the ends of the window, this eliminates need for
    %     demean/detrend, allows full TS reconstruction in a simple way
    %   There will be one instance of this class for each "decimation"
    %   level; the full windowing is defined by an array of nDec TWindow
    %   objects.
    %   The object contains also time information -- the reference, or
    %   "clock_zero" time and the sample rate that the windowing is applied
    %   to.   This can vary from the original time series dt, if there is
    %   decimation between levels.   With this timing information methods
    %   in this class can define starting sample numbers for windows, asign
    %   set numbers to windows, and compute actual time for any set number.
    %   The set of TWIndow objects should be carried with the wFC file, and
    %   thus set numbers (used as a "local" time stamp) can be converted to
    %   actual time when needed.
    
    properties
        %    this is just copied from the structures used before -- might
        %    modify
        Npts   % window length
        overLap   %    window overlap   --  Npts - overlap is offset between succesive windows
        w         %   array of length Npts, window coefficients
        FCsave    %   Range of FCs to save
        MissMax   %  maximum number of missing points that can be filled (but now?)
        HPcoeffA   %   high-pass filter coefficients: B and A inputs to matlab 
        HPcoeffB   %   function "filter"
        LPfiltCoeff   % filter coefficients for moving average LP filter -- this LP
                   % filter might be applied to TS before decimation.  Also
                   % possible to use residual from HP filter as the LP
                   % filtered TS.   If LPfiltCoeff is used, the
                   % coefficients in this TWindow object are applied to
                   % the same input time series that the HP filter is
                   % applied to.  Thus, if the TWindow object is for the
                   % first decimation level, LPfiltCoeff are used to filter
                   % original time series, and then decimated to create TS
                   % for decimationlevel 2
        window_dt  %   sample rate that the windowing is applied to -- with 
                   %    decimation this can vary from original sample rate;
                   %    with no decimation it is original TS sample rate
        decT       %   total decimation to get to this level
        clock_zero   % need to know this to define where sets can start, and
                  %  to define set numbers
    end
    properties (Dependent)
        segShift;
        segShiftT;
    end
    methods
        function obj = TWindow()
            %class constructor:  for now just create empty object
        end
        %******************************************************************
        function obj = SetWin(obj,win,dec)
            %   most properties are set here from structure in one cell from old
            %   cfg file -- these might be standard
            obj.Npts = win.Npts;
            obj.overLap = win.overLap;
            obj.w = win.w;
            obj.FCsave = win.FCsave;
            obj.MissMax = win.MissMax;
            obj.HPcoeffA = dec.HPcoeffA;
            obj.HPcoeffB = dec.HPcoeffB;
            obj.LPfiltCoeff = dec.LPcoeff;
        end
        %******************************************************************
        function obj = SetTime(obj,window_dt,clock_zero,decTotal)
            %   set the time properties -- actual sample rate (allowing for
            %   possible decimation, and clock_zero)
            %  NOT USING THIS????
            obj.clock_zero = clock_zero;
            obj.window_dt = window_dt;
            obj.decT = decTotal;
        end
        %******************************************************************
        function i0 = sampleNumber(obj,Date)
            %   Usage: i0 = obj.sampleNumber(date)
            %   given a datetime object return the sample number (relative
            %   to clock_zero) for this TWindow object:  this is zero based
            %   -- first sample at time of clock zero is numbered 0.
            i0 = round((datenum(Date)-datenum(obj.clock_zero))*86400/obj.window_dt);
        end
        %******************************************************************
        function [iseg1,i1] = firstSeg(obj,Date)
            %   given a datetime object return the number of the first set
            %   that can begin after (or including) this date, and the
            %   sample number (relative to date).  Thus if date is
            %   start_date, i1 will be the sample number in the TS where
            %   the set starts, iset will be the set number.  (If the set
            %   can start at the very beginning, e.g., if date==clock_zero
            %   i1=0 (and if date==clock_zero, iset = 0 also)
            %  ALSO zero based
            iseg1  = ceil(obj.sampleNumber(Date)/obj.segShift);
            i1 = iseg1*obj.segShift;
        end
        %******************************************************************
        function [NsegBlock] = NumSegsBlock(WinObj,tsObj)
            %   given a TS object, count number of segments for this
            %   windowing that fit in each available block
            NsegBlock = zeros(tsObj.NBlock,1);
            for iblock = 1:tsObj.NBlock
                i0 = WinObj.sampleNumber(tsObj.Blocks(iblock).startTime);
                [~,i1]=WinObj.firstSeg(tsObj.Blocks(iblock).startTime);
                NsegBlock(iblock) = floor((tsObj.Blocks(iblock).npts-(i1-i0)...
                    -WinObj.overLap)/WinObj.segShift);
            end
        end
        %******************************************************************
        function [ISegs,I1] = FirstSegsBlock(obj,tsObj)
            %   given a TS object, find segment number for first set that
            %   fits into each block, and find starting sample numbers
            %   (relative to clock_zero) for each
            ISegs = zeros(tsObj.NBlock,1);
            I1 = ISegs;
            for iblock = 1:tsObj.NBlock
                [ISegs(iblock),I1(iblock)] = obj.firstSeg(tsObj.Blocks(iblock).startTime);
            end
        end
        %******************************************************************
        function [Date] = segNum2date(obj,iset)
            %   given a set number iset, return the date corresponding to
            %   the first sample in the set
            nSamples = (iset-1)*obj.segShift;
            dnum = datenum(obj.clock_zero)+nSamples*obj.window_dt/86400;
            Date = datetime(dnum,'ConvertFrom','datenum');
        end
        %******************************************************************
        function value = get.segShift(obj)
            value = obj.Npts-obj.overLap;
        end
        function value = get.segShiftT(obj)
            value = obj.segShift*obj.decT;
        end
    end
end