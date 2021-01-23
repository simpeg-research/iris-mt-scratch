classdef TSblock < handle
    %  Class for a single block of time series; just carries data and
    %  timing info; in general a TS object contains an array of TSblocks
    
    properties
        data  %  real, dimensioned (NCh,npts)
        startTime   %  should be a dateTime object

        dt        %  sample rate --- need this to compute block end time ...
                  %   probably a better way to do this!
    end
    properties (Dependent)
        endTime   %  datetime object for end of TS block
        NCh       %  number of channels
        npts      %  number of points in block
    end
    
    methods
        %  just create empty object -- not sure what methods should be
        %  specific to a single block -- probably filtering, decimation,
        %  and all things that only use data from a single block
        %  OR: maybe this can be the basic TS class, and TSmultiBlock can
        %   extend?
        function obj = TSblock()
        end
        %******************************************************************
        function result = consistent(obj)
            %   check that all elements of an array of blocks have same
            %   values for NCh, dt properties
            result = true;
            for k = 2:length(obj)
                result = result && obj(1).dt == obj(k).dt && ...
                    obj(1).NCh == obj(k).NCh;
            end
        end
        %******************************************************************
        function value = get.endTime(obj)
            dnum = datenum(obj.startTime)+(obj.npts-1)*obj.dt/86400;
            value = datetime(dnum,'ConvertFrom','datenum');
        end
        %******************************************************************
        function value = get.NCh(obj)
            [value,~] = size(obj.data);
        end
        %******************************************************************
        function value = get.npts(obj)
            [~,value] = size(obj.data);
        end
        %******************************************************************
        %   note that many basic routines would be useful and should be
        %   implemented.   I am just doing the minimal to start, things 
        %   required for the main algorithm steps
        %******************************************************************
        function objOut = copy(objIn)
            %   create copy of input object
            objOut = TSblock();
            objOut.startTime = objIn.startTime;
            objOut.dt = objIn.dt;
            objOut.data = objIn.data;
        end
        %******************************************************************
        function zero(obj)
            %   zeros data, leaving everything else along
            obj.data = zeros(size(obj.data));
        end
        %******************************************************************
        function dataMean = demean(obj)
            %   computes means for each channel and subtracts; returns
            %   mean values in dataMean
            %
            %   Usage: dataMean = demean(obj);
            %
            dataMean = zeros(obj.NCh,1);
            for ich = 1:obj.NCh
                temp = obj.data(ich,:);
                dataMean(ich) = mean(temp(~isnan(temp)));
                obj.data(ich,:) = obj.data(ich,:)-dataMean(ich);
            end
        end
        %******************************************************************
        function objOut = plus(obj1,obj2)
            %   add obj1 to obj2 -- keeping only the part of the TS block
            %   that overlaps
            %   NOTE this method overloads + in matlab, so can call this as
            %       objOut = obj1 + obj2;
            
            if obj1.dt ~= obj2.dt
                error('Cannot add TS blocks with different sampling rates')
            end
            
            %   compute difference (number of samples) between starts and
            %   ends of the two input objects
            startDiff = round(datenum(obj2.startTime)-datenum(obj1.startTime)*86400/obj1.dt);
            endDiff = round(datenum(obj2.endTime)-datenum(obj1.endTime)*86400/obj1.dt);
            objOut = obj1.copy;
            if startDiff >= 0
                %   second start is after first -- and defines first point
                %   to use in sum
                istart2 = 1;
                istart1 = 1+startDiff;
                objOut.startDate = obj2.startDate;
            else
                %   first start is after second, this is start for sum
                istart1 = 1;
                istart2  = 1-startDiff;
                objOut.startDate = obj1.startDate;
            end
            if endDiff >= 0
                %   second end is after first -- first end defines end of
                %   sum
                iend1 = obj1.npts;  % use to end of first TS
                iend2 = obj2.npts-endDiff;
            else
                %   first end is after second, second end defines end
                iend2 = obj2.npts;   % use to end of second TS
                iend1  = obj1.npts+EndDiff;
            end
            objOut.data = obj1.data(:,istart1:iend1)+obj2.data(:,istart2:iend2);
        end
        %******************************************************************
        function [tsHPblock] = hpFilter(obj,win,returnLP)
            %   High-pass filter one block of TS, return HP and residual
            %   (LP) filtered TS, overwriting input.
            %   Assuming that missval code is NaN
            %    crude treatment of missing 
            %   if optional argument returnLP is true, obj.data is replaced
            %   with residual (original TS minus HP filtered TS); defaults
            %   to true
            
            if nargin==2
                returnLP = true;
            end
   
            %   copy input to creat HP filtered output
            tsHPblock = obj.copy;
            
            %   fill missing values (somehow!) before filtering
            tsHPblock.fillMiss;
            
            %   remove mean to reduce end effects
            tsHPblock.demean;
            
            %  apply filter forward and backward -- zero phase shift
            tsHPblock.data = filter(win.HPcoeffB,win.HPcoeffA,tsHPblock.data,[],2);
            tsHPblock.data = filter(win.HPcoeffB,win.HPcoeffA,...
                tsHPblock.data(:,end:-1:1),[],2);
            tsHPblock.data = tsHPblock.data(:,end:-1:1);
            tsHPblock.data(isnan(obj.data)) = NaN;
            if returnLP
                obj.data = obj.data-tsHPblock.data;
            end
        end
        %******************************************************************
        function [tsLPblock] = lpfilter(obj,win)
        %  low-pass filter one block of TS using moving average filter,
        %  coefficients are provided in win.LPfiltCoeff,
        %   This assumes that this is a moving average filter; TS is padded
        %   at both ends, and output shifted to make the averaging
        %   effectively
        
            tsLPblock = obj.copy;
            %   LP filter is provided as for dnff in decset.cfg -- just
            %   second half of filter (including center point of odd-length
            %   total filter)
            nCoeff = length(win.LPfiltCoeff);
            f = sum(win.LPfiltCoeff(2:end));
            nPad = nCoeff-1;
            a = [win.LPfiltCoeff(end:-1:2) win.LPfiltCoeff];
            %   make padded array
            Pad = zeros(obj.NCh,nPad);
            Pad = Pad./Pad;
            temp = [Pad obj.data Pad];
            %  make array of ones (and zeros) to compute weights
            wt = ~isnan(temp);
            %    set missing (incluiding padding) to zero
            temp(isnan(temp)) = 0;
            %   LP filter
            temp = filter(a,1,temp,[],2);
            wt = filter(a,1,wt,[],2);
            wt = wt(:,2*nPad+1:end);
            tsLPblock.data = temp(:,2*nPad+1:end)./wt;
            %   if too many points in the average are missing, LP filtered
            %   data point is missing ...  this is what weights are for
            %   (and to avoid including zeros in the weighted average)
            tsLPblock.data(wt<f) = NaN;
        end
        %******************************************************************
        function fillMiss(obj)
            %   fill in missing data before filtering.   For now I just use
            %   mean  of all data in the block -- this can be refined!
            missFill = mean(obj.data,2,'omitnan');
            for ich = 1:obj.NCh
                obj.data(ich,isnan(obj.data(ich,:)))=missFill(ich);
            end
        end 
        %******************************************************************
        function  decimate(obj,decFactor)
            %   Decimates one block of TS, overwriting input; no filtering, assumes that
            %   any required LP (anti-alias) filtering is done before call
            %   to this routine.  SInce output starts at first point of
            %   input, startTime is unchanged
            obj.data = obj.data(:,1:decFactor:end);
            [~,obj.npts] = size(obj.data);
            obj.dt = obj.dt*decFactor;
        end
        
    end
end