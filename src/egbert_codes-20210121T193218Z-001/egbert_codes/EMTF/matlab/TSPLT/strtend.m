function [ts_strt,ts_end] = strtend(istarts,npts,sampfreq);

nch = length(npts);

%  julian day of start for each channel
jday = [];
for ic = 1:nch
  jday = [jday julday(istarts(:,ic)) ];
end

%secs = seconds since start of minimum day ...
secs = istarts(6,:) + 60*(istarts(5,:)+...
      60*(istarts(4,:)+24*(jday-min(jday))));

% start and end times (sample numbers relative
% to earliest starting time) of all channels ... 
ts_strt = sampfreq*(secs - min(secs)) + 1;
ts_end = ts_strt + npts - 1;
end
   