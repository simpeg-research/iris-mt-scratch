%    make default system response look up tables for NIMS ... starting out
%    very simply!
Dir = '/Users/garyegbert/Desktop/MTprocessing/NEW/test/SYS/';
logfrequency = -5:.2:0;
frequency = 10.^logfrequency.';
%   magnetics
response = 100*ones(size(frequency));
unitsIn = 'counts';
unitsOut = 'nT';
save('NIMSmagResponse.mat','frequency','response','unitsIn','unitsOut');
%  electric -- just assuming 100 m dipole lines for now ...  probably
%  should deal with diopole length separately!   Nominal response is
%  2.4e-6 mV/count -- so 2.4e-5 mv/km/count.  Invert to get counts/(mv/km)
response = (1./2.441412e-05)*ones(size(frequency));
unitsOut = 'mV/km';
save('NIMSelecResponse.mat','frequency','response','unitsIn','unitsOut');

%%    this is the unit response for use with synthetic data files
Dir = '/Users/garyegbert/Desktop/MTprocessing/NEW/test/';
logfrequency = -5:.2:0;
frequency = 10.^logfrequency.';
%   magnetics
response = ones(size(frequency));
unitsIn = 'counts';
unitsOut = 'nT';
save('SYNmagResponse.mat','frequency','response','unitsIn','unitsOut');
%  electric -- just assuming 100 m dipole lines for now ...  probably
%  should deal with diopole length separately!   Then nominal response is
%  2.4e-6, and unitsOut is mV
elecResponse = ones(size(frequency));
unitsOut = 'mV/km';
save('SYNelecResponse.mat','frequency','response','unitsIn','unitsOut');