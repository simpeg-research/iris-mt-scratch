classdef TFC1Dec < handle
    %  Class for STFT Fourier Coefficients for a single decimation
    %  level.  Multiple TS blocks are concatenated together
    
    properties
        %    this is just copied from the structures used before -- might
        %    modify
        Win   %  windowing object (TWindow class)
        Nch   %  number of channels
        NsegBlock   % number of segments in each block
        FC    %  array of complex FCs (Nch,Nfc,Nseg) -- note that only some 
              %   FCs are saved--the range of saved FCs is specified in Win
              %   object
        segNumber  %  segment number (iset) for each time segment
        freqs %  actual freq (Hz)
        Header   %   contains information about channels, site(s)
        Ordered=false %  set to true after sorting by segment numbers
        CompleteBlocks = false  %  set to true after reblocking  
    end
    properties (Dependent)
        Nfc   %  Number of FCs saved at this decimation level--derivable
        %  win object
        Nseg  %  total number of segments -- derivable from NsegBlock
        NBlock %  number of blocks -- derivable from length of NsegBlock
        blockStart  %   these are start points for each block
        firstSeg  %   these are segment numbers at start of each block
        lastSeg   %  segment numbers at end of each block
    end
    methods
        function obj = TFC1Dec()
        end
        function SetFC1Dec(obj,tsObj,winObj)
            obj.Win = winObj;
            obj.Nch = tsObj.NCh;
            %   Find number of segments in each block ...
            obj.NsegBlock = NumSegsBlock(obj.Win,tsObj);
            %   Allocate for FCs that will be saved, for each channel, FC
            %   in save band, and segment--concatenated over all blocks
            obj.FC = zeros(obj.Nch,obj.Nfc,obj.Nseg)+1i*zeros(obj.Nch,obj.Nfc,obj.Nseg);
            obj.segNumber = zeros(obj.Nseg,1);
            obj.Header = tsObj.Header ;  %   just copy header from TS object --
                         %   normally for a single site
        end
        %******************************************************************
        function objOut = copyMetadata(obj)
            %  copy everything except actual FCs
            objOut = TFC1Dec();
            objOut.Win = obj.Win;
            objOut.Nch = obj.Nch;
            objOut.NsegBlock = obj.NsegBlock;
            objOut.segNumber = obj.segNumber;
            objOut.freqs = obj.freqs;
            objOut.Header = obj.Header;
        end
        %******************************************************************
        function objOut = copy(obj)
            %   copy everything, including FCs
            objOut = obj.copyMetadata;
            objOut.FC = obj.FC;
        end
        %******************************************************************
        function zero(obj) 
            %   sets all FCs to zero -- in place; to make a copy with all
            %   zeros, copy first
            obj.FC = zeros(size(obj.FC));
        end
        %******************************************************************
        function FT(obj,tsObj)
            %  I am assuming that all time-series (decimated, HP filtered,
            %  etc.) will be handled through TS class
            
            ifc1 = obj.Win.FCsave(1);
            ifc2 = obj.Win.FCsave(2);
            nWin = obj.Win.Npts;
            obj.freqs = (ifc1-1:ifc2-1)/(nWin*obj.Win.window_dt);
            isegB1 = 1;
            %   loop over blocks
            for iblk = 1:tsObj.NBlock
                isegB2 = isegB1+obj.NsegBlock(iblk)-1;
                %   temporary data storage, one block, one channel
                 X = zeros(obj.NsegBlock(iblk),nWin);
                 %   sample number of block start date/time (relative to
                 %   clock_zero)
                 i0 = obj.Win.sampleNumber(tsObj.Blocks(iblk).startTime);
                 %   sample number of start of first set in block (relative 
                 %   to clock_zero)
                 [iseg1,i1] = obj.Win.firstSeg(tsObj.Blocks(iblk).startTime);
                 istart = i1-i0+1;   %  starting point in TS block for first set
                 for ich = 1:obj.Nch
                     %  make array of overlapping segments ...
                     iseg = 0;
                     for segStart = istart:obj.Win.segShift:tsObj.Blocks(iblk).npts-nWin+1
                         obj.segNumber(iseg+isegB1) = iseg+iseg1-1;
                         iseg = iseg+1;
                         X(iseg,:)= tsObj.Blocks(iblk).data(ich,segStart:segStart+nWin-1);
                     end
                     [X,Use] = obj.CheckMissing(X);  %   not sure how to implement
                     %       this ... for now this is trivial, just check
                     %       to see if there are too many missing in each
                     %       segement, set Use = T/F , and replace NaNs (or
                     %       missing value code) with zeros;  could
                     %       interpolate somehow.  I.e., replace
                     %       (somewhere, somehow) with something better.
                     
                     %   we assume that any filtering (in particular hp
                     %   filter), but also perhaps some pre-whitening will
                     %   be applied in the TS (or TSblock) class
                     %   Here, we just multiply by window
                     X  = X*spdiags(obj.Win.w',0,nWin,nWin);
                     Y  = fft(X,[],2);  % FFT of each segment ...
                     Y(~Use,:)  = NaN;  %  if the segment was not to be used
                     %      set all FCs for that segment to NaN
                     %    correct for channel response (could move this...)
                     chResp = tsObj.Header.Channels(ich).ChannelResponse;
                     obj.FC(ich,:,isegB1:isegB2) = ...
                          chResp.applyChannelResponse(Y(:,ifc1:ifc2).',obj.freqs);
                 end
                 isegB1 = isegB2+1;
            end      
        end
        %******************************************************************
        function [X,Use] = CheckMissing(obj,X)
            %   checks array X for number of missing data points in each
            %   segment; obj.Win.MissMax is used to decide if too many
            %   points are missing, in which case segment is marked with
            %   Use(iseg = false.   NaN's are replace by zeros if
            %   number missing are <= < MissMax
            %    This might be refined by using some sort of interpolation.
            Use = sum(isnan(X),2) <= obj.Win.MissMax;
            X(isnan(X))=0;
        end
            
        %******************************************************************
        function tsOut = FTinv(obj,tsIn,analytic)
            %   Usage:  FTinv(obj,analytic)
            %           second argument is optional (defaults to false)
            %           if analytic == true compute analytic signal
            %
            %  Convert TFC1Dec object back to time domain -- Assumes that a
            %  template tsObj (with correct header information is provided
            %  on input; tsObj is first copied into tsOut, then overwritten
            
            %   NOTE: as coded the TS object is for a single decimation
            %   level; would have to add TS for each decimation
            %   level+residual to get back to original TS object
            
            %  NOTE:  there is an issue here about interaction with
            %  decimation -- this could (at least as an option) return TS
            %  objects at the original undecimated sampling rate.   It is
            %  easier to do that here.  If you want to reconstruct the full
            %  TS, it will be necessary to get reconstructions at the same
            %  sampling rate.    (Note that they may not all have same
            %  start times, but this can be managed in the add method for
            %  TS objects)
            
            if nargin==2 
                analytic = false;
            end
            
            tsOut = tsIn.copy;   %  maybe just need to copy header?
            
            ifc1 = win.FCsave(1);
            ifc2 = win.FCsave(2);
            nWin = obj.Win.Npts;
            isegB1 = 1;
            %   loop over blocks
            for iblk = 1:obj.NBlock
                isegB2 = isegB1+obj.NsegBlock(iblk)-1;
                tsOut.Blocks(iblk) = TSblock();
                %   length of reconstructable TS:  ends are cut off due to
                %   windowing
                N = obj.Win.segShift*obj.NSegBlock(iblk)+obj.Win.overlap;
                tsOut.Blocks(iblk).data = zeros(obj.Nch,N);
                tsOut.Blocks(iblk).npts = N;
                tsOut.Blocks(iblk).startTime = obj.Win.segNum2date(obj.segNumber(isegB1));
                Y = zeros(obj.NsegBlock(iblk),nWin)+1i*zeros(obj.NsegBlock(iblk),nWin);
                x = zeros(1,N)+1i*zeros(1,N);
                w = zeros(1,N);
                % loop over channels
                for ich = 1:obj.Nch
                    Y(:,ifc1:ifc2)=squeeze(obj.FC(ich,:,isegB1:isegB2)).';
                    Y = 2*Y; %   this is a trick to account for negative frequenies,
                    %   and for computing Hilbert transform of real
                    %   part (when analtic is true)
                    X = ifft(Y,[],2);
                    for iseg = 1:obj.NsegBlk(iblk)
                        i1 = (iseg-1)*obj.Win.segShift+1;
                        i2 = i1+nWin-1;
                        x = x*0;
                        w = w*0;
                        if analytic
                            x(i1:i2) = x(i1:i2)+obj.Win.decT*X(iseg,:);
                        else
                            x(i1:i2) = x(i1:i2)+obj.Win.decT*real(X(iseg,:));
                        end
                        w(i1:i2)  = w(i1:i2)+obj.Win.w;
                        w = max(w,.01);
                        tsOut.Blocks(iblk).data(ich,:) = x./w;
                    end
                end
            end
        end
        %******************************************************************
        function objBand = extractBand(obj,iband)
            %   Usage: objBand = extractBand(obj,iband)
            %   create a new TFC1Dec object including only frequencies
            %   within the specified range given in iband; these should be
            %   frequency numbers in the FULL set of frequencies (i.e.,
            %   correspond to the numbering used in Win.FCsave -- where Win
            %   is the TWIndow object.   ELements of iband cab be computed
            %   from a specified range of frequencies (fband(1),fband(2))
            %   using the TWindow object
            objBand = obj.copyMetadata;
            %   find indicies within saved FCs
            i1 = max(1,iband(1) - obj.Win.FCsave(1)+1);
            i2 = min(obj.Nfc,iband(2) - obj.Win.FCsave(1)+1);
            %   copy appropriate band of frequencies
            objBand.FC = obj.FC(:,i1:i2,:);
            %   change frequencies in output to correct range
            objBand.freqs = obj.freqs(i1:i2);
            %   modify FCsave in Win object
            i1 = max(iband(1),obj.Win.FCsave(1));
            i2 = min(iband(2),obj.Win.FCsave(2));
            objBand.Win.FCsave = [i1,i2];
        end
        %******************************************************************
        function timeSort(obj)
            %   Usage: timeSort(obj)
            %     sort object so that time segments are ordered from
            %     earliest to last -- should generally be true, but being
            %     able to assume this will simplify assembling FCs from
            %     multiple sites into a single multi-channel object
            
            %   teat firat -- usually don't have to do anything
            if ~obj.Ordered
                if any(diff(obj.segNumber)<=0)
                    [segNumOrdered,I]=sort(obj.segNumber,'ascend');
                    obj.FC = obj.FC(:,:,I);
                    obj.segNumber = segNumOrdered;
                end
                %   now we are sure FCs are ordered by segment number
                obj.Ordered = true;
            end
        end
        %******************************************************************
        function result = sameSite(obj1,obj2)
            %  checks to see if two objects are consistent, corresponding
            %  to two runs from the "same site"
            result = isequal(obj1.Nch,obj2.Nch) && isequal(obj1.Win,obj2.Win) ...
                && isequal(obj1.freqs,obj2.freqs);
            %   should also check Header -- are channels in same order,
            %   site names identical?    Need to sort out what the nature
            %   of the Header is first!
        end
        %******************************************************************
        function objMerged = mergeRuns(objRuns)
            %   Usage: objMerged = mergeRuns(objRuns)
            %     merges an array of TFCDec1 objects (for a series of
            %     "runs")  into a single object, with all segments
            %     concatenated 
            nRuns = length(objRuns);
            FirstSegs = zeros(nRuns,1);
            LastSegs = zeros(nRuns,1);
            %  first check for consistency, and order; compare all objects
            %  to first in list
            if ~objRuns(1).Ordered
                objRuns(1).timeSort;
            end
            FirstSegs(1) = objRuns(1).segNumber(1);
            LastSegs(1) = objRuns(1).segNumber(end);
            NsegT = objRuns(1).Nseg;
            NBlockT = objRuns(1).NBlock;
            consistent = true;
            for iRun = 2:nRuns
                if ~objRuns(iRun).Ordered
                    objRuns(iRun).timeSort;
                end
                FirstSegs(iRun) = objRuns(iRun).segNumber(1);
                LastSegs(iRun) = objRuns(iRun).segNumber(end);
                consistent = consistent & sameSite(objRuns(1),objRuns(iRun));
                if ~consistent
                    error('set of runs are not consistent: cannot be merged')
                end
                NsegT = NsegT+objRuns(iRun).Nseg;
                NBlockT = NBlockT+objRuns(iRun).NBlock;
            end
            %   if we get here all runs are consistent and can be merged
            %       -- now check to see if segment numbers are
            [FirstSegsSorted,I]=sort(FirstSegs,'ascend');
            LastSegsSorted = LastSegs(I);
            if any(LastSegsSorted(1:end-1)-FirstSegsSorted(2:end)>=0)
                error('Segment numbers from different runs overlap: cannot be merged')
            end
            %  OK, now everything is consistent, merge using order
            %  determined from FirstSegs
            objMerged = objRuns(1).copyMetadata;
            objMerged.segNumber = zeros(NsegT,1);
            objMerged.NsegBlock = zeros(NBlockT,1);
            objMerged.FC = zeros(objMerged.Nch,objMerged.Nfc,NsegT);
            iSeg1 = 1;
            iBlock1 = 1;
            for k = 1:nRuns
                iSeg2 = iSeg1 + objRuns(I(k)).Nseg-1;
                iBlock2 = iBlock1 + objRuns(I(k)).NBlock-1;
                objMerged.segNumber(iSeg1:iSeg2) = objRuns(I(k)).segNumber;
                objMerged.FC(:,:,iSeg1:iSeg2) = objRuns(I(k)).FC;
                objMerged.NsegBlock(iBlock1:iBlock2) = objRuns(I(k)).NsegBlock;
                iSeg1 = iSeg2+1;
                iBlock1 = iBlock2+1;
            end
            %    merged object should already be complete and ordered, so
            %    set these properties to true
            objMerged.Ordered = true;
            objMerged.CompleteBlocks = true;
        end
        %******************************************************************
        function reblock(obj)
            %   Usage: obj.reblock
            %     reblocks so that all blocks are complete: no gaps in set
            %     numbers -- just need to reset obj.NsegBlock
            indBlockStart = [1 ; find(diff(obj.segNumber)>1)+1 ; obj.Nseg+1];
            obj.NsegBlock = diff(indBlockStart);
            obj.CompleteBlocks = true;
        end
        %******************************************************************
        function  [minSeg,maxSeg,IncludedBlocks] = mergedBlock(objSites,nextBlock)
            %  given array objSites(nSites) of TFC1Dec objects find one block for
            %  merged multi-site object.  Starting blocks for each site are given in
            %  array netxBlock; this should start with all of these set to 1  (if this
            %  argument is omitted, an array of ones is assumed)  This finds the first
            %  and last segment numbers in the merged block, and an array
            %  IncludedBlocks(nSites,2) for each site first element is the first block from
            %    this site that is included, and second the number of
            %    blocks from that site that are included in the merged
            %    bloc.  This will only work if all
            %  input TFC1Dec objects are Ordered , with CompleteBlocks.
            
            nSites = length(objSites);
            IncludedBlocks = zeros(nSites,2);
            if nargin == 1
                nextBlock = ones(nSites,1);    %  these are going to be the next block for each site -- start with the first
            end
            proceed = true;
            for iSite = 1:nSites
                proceed = proceed && objSites(iSite).Ordered && objSites(iSite).CompleteBlocks;
            end
            if ~proceed
                error('can only use mergedBlock when all site objects are Ordered and have CompleteBlocks')
            end
            
            %  find the starting segment number for the merged block
            minSeg = Inf;
            nBlocks = zeros(nSites,1);
            for iSite = 1:nSites
                nBlocks(iSite) = objSites(iSite).NBlock;
                IncludedBlocks(iSite,1) = nextBlock(iSite);
                if objSites(iSite).firstSeg(nextBlock(iSite))<minSeg
                    minSeg = objSites(iSite).firstSeg(nextBlock(iSite));
                    maxSeg = objSites(iSite).lastSeg(nextBlock(iSite));
                end
            end
            %   (minSeg,maxSeg) defines initial trial block -- might expand
            
            %  find all sites that overlap trial block -- update trial
            %  block and repeat, until there are no more sites/blocks to
            %  add
            Done = false(nSites,1);
            while any(~Done)
                useBlock = false(nSites,1);
                %   check to see if data from each site overlaps
                for iSite = 1:nSites
                    if  ~Done(iSite) && ...
                        objSites(iSite).firstSeg(nextBlock(iSite))>=minSeg && ...
                            objSites(iSite).firstSeg(nextBlock(iSite))<=maxSeg
                        %  this sites block overlaps with current trial block
                        useBlock(iSite) = true;  %
                        IncludedBlocks(iSite,2) = IncludedBlocks(iSite,2)+1;
                    end
                end
                
                % find (possibly new) max segment number
                for iSite = 1:nSites
                    if ~Done(iSite) && ...
                            useBlock(iSite) && objSites(iSite).lastSeg(nextBlock(iSite))>maxSeg
                        maxSeg = objSites(iSite).lastSeg(nextBlock(iSite));
                    end
                end
                %   for all sites for which "nextBlock: is used, increment nextBlock
                nextBlock(useBlock) = nextBlock(useBlock)+1;
                %  need to "remove" sites for which all blocks have been
                %  used already
            
                for iSite = 1:nSites
                    Done(iSite) = nextBlock(iSite) > nBlocks(iSite) || ...
                        objSites(iSite).firstSeg(nextBlock(iSite))>maxSeg;
                end
            end  % while notDone
        end
        %******************************************************************
        function objMerged = mergeSites(objSites)
            %   Usage: objMerged = mergeSites(objSites)
            %     objSites is an array of nSites TFC1Dec objects.  These
            %     are merged into a single object, with merged headers and
            %     all channels in a single FC array.   Individual blocks
            %     are Complete and Ordered; if any one site has data for a
            %     segment, that segment is included with missing values for
            %     any missing channels
            %
            %    Initially use this for two sites, local and remote.  The
            %    generality allows use for multi-site processing.
            
            nSites = length(objSites);
            %  check that all Window objects are identical
            proceed = true;
            for iSite = 2:nSites
                proceed = proceed && isequal(objSites(1).Win,objSites(iSite).Win);
            end
            if ~proceed
                error('Windowing not consistent for all sites in list')
            end
            %   now check consistency of frequencies
            for iSite = 2:nSites
                proceed = proceed && isequal(objSites(1).freqs,objSites(iSite).freqs);
            end
            if ~proceed
                error('Frequencies not consistent for all sites in list')
            end

            %   create empty output object
            objMerged = TFC1Dec();
            objMerged.Win = objSites(1).Win;
            objMerged.freqs = objSites(1).freqs;
            objMerged.Ordered = true;
            objMerged.CompleteBlocks = true;
            %  merge headers -- not doing this now
            
            %    number of channels will be total number of channels at all
            %    sites
            objMerged.Nch = 0;
            ich1 = zeros(nSites+1,1);
            ich1(1) = 1;   %   first channel for site 1
            for iSite = 1:nSites
                objMerged.Nch = objMerged.Nch+objSites(iSite).Nch;
                ich1(iSite+1) = objMerged.Nch+1 ;  %   first channel for iSite+1
            end
            
            %  Initialize nextBlock
            nextBlock = ones(nSites,1);
            moreBlocks2do = true;
            %   don't know how many blocks there will be in the merged
            %   object -- I am doing this crudely here -- max number of
            %   blocks is sum over number of blocks for all sites
            NBlocksAll = zeros(nSites,1);
            for iSite=1:nSites
                NBlocksAll(iSite) = objSites(iSite).NBlock;
            end
            maxBlocks = sum(NBlocksAll);
            minSeg =  zeros(maxBlocks,1);
            maxSeg = zeros(maxBlocks,1);
            IncludedBlocks = zeros(maxBlocks,nSites,2);
            iBlock=0;
            while moreBlocks2do
                %   find min, max segment numbers, blocks from each site
                %   to include in next merged block 
                iBlock = iBlock+1;
                [minSeg(iBlock),maxSeg(iBlock),IncludedBlocks(iBlock,:,:)]...
                    = mergedBlock(objSites,nextBlock);
                nextBlock = squeeze(IncludedBlocks(iBlock,:,1)+IncludedBlocks(iBlock,:,2));
                moreBlocks2do = any(nextBlock<=NBlocksAll);
            end
            objMerged.NsegBlock = zeros(iBlock,1);
            %  once NsegBlock is allocated dependent property NBlock defined
            for iBlock = 1:objMerged.NBlock   
                objMerged.NsegBlock(iBlock) = maxSeg(iBlock)-minSeg(iBlock)+1;
            end
            % and now so is Nseg ...  so can allocate main arrays for
            % merged object
            objMerged.segNumber = zeros(objMerged.Nseg,1);
            objMerged.FC = zeros(objMerged.Nch,objMerged.Nfc,objMerged.Nseg)./0;
             
            %  set segment numbers in merged object
            iseg1 = 1;
            for iBlock = 1:objMerged.NBlock
                iseg2 = iseg1+objMerged.NsegBlock(iBlock)-1;
                %   set numbers, consecutive within each  block
                objMerged.segNumber(iseg1:iseg2) = minSeg(iBlock):maxSeg(iBlock);
                iseg1 = iseg2+1;
            end
            
            %   copy FCs from each site into appropriate parts of merged FC
            %   array -- need to do this block by block for each site
            iseg1 = 1;
            for iBlock = 1:objMerged.NBlock  
                for iSite = 1:nSites
                    i1 = ich1(iSite);
                    i2 = ich1(iSite+1)-1;
                    k1 = IncludedBlocks(iBlock,iSite,1);
                    k2 = k1 + IncludedBlocks(iBlock,iSite,2)-1;
                    for k = k1:k2
                        j1Site = objSites(iSite).blockStart(k);
                        j2Site = j1Site+objSites(iSite).NsegBlock(k)-1;
                        j1Merged = iseg1+objSites(iSite).firstSeg(k)-...
                            objMerged.segNumber(iseg1);
                        j2Merged = j1Merged + objSites(iSite).NsegBlock(k)-1;
                        objMerged.FC(i1:i2,:,j1Merged:j2Merged) = ...
                            objSites(iSite).FC(:,:,j1Site:j2Site);
                    end
                end
                iseg1 = iseg1+objMerged.NsegBlock(iBlock);
            end
        end
        %******************************************************************
        function   value = get.blockStart(obj)
            %   these are start points for each block
            value = cumsum([1; obj.NsegBlock(1:end-1)]);
        end
        %******************************************************************
        function value = get.firstSeg(obj)
            %   these are segment numbers at start of each block
            value = obj.segNumber(obj.blockStart);
        end
        %******************************************************************
        function value = get.lastSeg(obj)
            value = obj.firstSeg+obj.NsegBlock-1;
        end
        %******************************************************************
        function value = get.Nseg(obj)
            value = sum(obj.NsegBlock);
        end
        %******************************************************************
        function value = get.Nfc(obj)
            value = obj.Win.FCsave(2)-obj.Win.FCsave(1)+1;
        end
        %******************************************************************
        function value = get.NBlock(obj)
            value = length(obj.NsegBlock);
        end
    end
end