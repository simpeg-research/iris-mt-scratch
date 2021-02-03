function [SIGMA_N] = VarInterp(sigma_N,periods,freqs_interp);

%  does linear interpolation of variance array onto frequencies
%     specified in freqs_interp
nm = size(sigma_N); nbt = nm(1);  nt = nm(2);
%  to simplify interpolation : pad both ends of period range ...
periods = [ periods(1)/10 ; periods ; periods(nbt)*10 ] ;
sigma_N = [ sigma_N(1,:) ; sigma_N ; sigma_N(nbt,:) ] ;
ratio = periods*freqs_interp < 1 ;
i1 = sum(ratio); i2 = i1 + 1;
logfreqs = - log10(periods);
logfreqs_int = log10(freqs_interp);
w2 = (logfreqs_int' - logfreqs(i1) ) ./ (logfreqs(i2) - logfreqs(i1));
w1 = (logfreqs(i2) - logfreqs_int' ) ./ (logfreqs(i2) - logfreqs(i1));
w1 = w1 * ones(1,nt) ; w2 = w2 * ones(1,nt);
SIGMA_N = sigma_N(i1,:) .* w1 + sigma_N(i2,:) .* w2 ;
