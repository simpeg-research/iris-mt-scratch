classdef ChannelResponse 
    %   this is a placeholder for the channel response class   -- the
    %   sinmplest think to implement is table look up, where all stages of
    %   the system response are concatenated, and provided as a file.
    %   Alternative implementations are of course possible, such as a
    %   series of stages, explicily implemented as part of the processing
    %   stream.  Each stage could be represented in a possibly different
    %   way (e.g., poles and zeros, table look up for coil calibration,
    %   etc.)   
    properties
        frequency  %   array of frequencies, low to high
        response   %   complex channel response (real, imaginary) -- this should
                   %   be system response: Out/In;  divide by complex
                   %   response to get the desired physical (input)
                   %   measurement
                   %  NOTE:  in my terminology this is the response of the
                   %  system, which we are trying to remove.  Thus, the
                   %  input to the systme is what we are trying to measure
                   %  (e.g., magnetic field in nT) and the output is what
                   %  is recorded (counts).   Thus if (as for NIMS) the
                   %  nominal system response is 100 counts/nT, what should be
                   % in the table is 100 (and then a call to
                   % applySystemResponse would divide the raw counts (what
                   % is in TS) by 100.   
        signConvention=1  %   what sign is used in representing TS at a single 
                          %  frequency as exp+-iwt ?   Note that when
                          %  using a standart FFT (such as implemented in
                          %  Matlab) the convention is +iwt  -- i.e., this
                          %  is the sign used in going from FD to TD (ifft)
        unitsIn        %   desired units -- for magnetic this will be nT;
                       %     forelectrics mV/km
        unitsOut       %   this is what comes out of the system, and is recorded
                       %     For this all in one table look up, this will
                       %     normally be the raw counts that are digitized
    end
    
    methods
        %    class constructor
        function obj = ChannelResponse()
        end
        %******************************************************************
        %    need to somehow load the response information for each
        %    channel -- here I am just assuming that I can load for one
        %    channel as a mat file, with variables names coinciding with 
        %    property names; something better is needed
        function obj =LoadTableFile(obj,fileName)
            load(fileName,'frequency','response','unitsIn','unitsOut')
            obj.frequency = frequency;
            obj.response = response;
            obj.unitsIn = unitsIn;
            obj.unitsOut = unitsOut;
        end
        %******************************************************************
        function FCout=applyChannelResponse(obj,FCin,FCfreqs)
            %   apply system response to FCs from one channel;
            %    in general FCin will be an array of size (Nfc,Nseg)
            %    FCfreqs(Nfc) contains the frequencies for all saved FCs
            %     just using matlab interpolation function (defalt linear)
            %   one possible propblem: 0 freqeuncy may be provided -- need
            %   to avoid creating NaNs!   
            minFreq = min(FCfreqs(FCfreqs~=0));
            FCfreqs(FCfreqs==0) = minFreq/10;
            respInterp = interp1(log10(obj.frequency),obj.response,log10(FCfreqs));
            Nfc = length(FCfreqs);
            %   use sparse diagonal matrix multiply to transform each FC
            %   for all segments
            FCout = spdiags(1./respInterp.',0,Nfc,Nfc)*FCin;
        end
    end
end