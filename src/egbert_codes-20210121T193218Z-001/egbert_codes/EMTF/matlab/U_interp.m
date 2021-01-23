function [U1,U2,SIGMA_N] = U_interp(u1,u2,sigma_N,periods,freqs_interp);

%  does linear interpolation of array TFs u1, u2 onto frequencies
%     specified in freqs_interp
%  NOTE : I assume that U1, U2 are converted to standard TFs
%   giving field components relative to a fixed site ...
nm = size(u1); nbt = nm(1);  nt = nm(2);
%  to simplify interpolation : pad both ends of period range ...
periods = [ periods(1)/10 ; periods ; periods(nbt)*10 ] ;
sigma_N = [ sigma_N(1,:) ; sigma_N ; sigma_N(nbt,:) ] ;
u1 = [ u1(1,:) ; u1 ; u1(nbt,:) ];
u2 = [ u2(1,:) ; u2 ; u2(nbt,:) ];
ratio = periods*freqs_interp < 1 ;
i1 = sum(ratio); i2 = i1 + 1;
logfreqs = - log10(periods);
logfreqs_int = log10(freqs_interp);
w2 = (logfreqs_int' - logfreqs(i1) ) ./ (logfreqs(i2) - logfreqs(i1));
w1 = (logfreqs(i2) - logfreqs_int' ) ./ (logfreqs(i2) - logfreqs(i1));
w1 = w1 * ones(1,nt) ; w2 = w2 * ones(1,nt);
U1 =  u1(i1,:) .* w1 + u1(i2,:) .*w2 ;
U2 =  u2(i1,:) .* w1 + u2(i2,:) .*w2 ;
SIGMA_N = sigma_N(i1,:) .* w1 + sigma_N(i2,:) .* w2 ;

end
