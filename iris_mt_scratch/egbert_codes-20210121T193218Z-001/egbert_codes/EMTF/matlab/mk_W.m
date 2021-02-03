%    mk_W ... makes robust weight matrix, given projection onto
%    span of MT signal space + estiamtes of noise variances for each channel
%
%    USAGE:  [W] = mk_W(P,X,sigma) ;

function [W] = mk_W(P,X,sigma)

nm = size(X);  nt = nm(1); ndat = nm(2);
R = X - P*X;
scl = 1./sqrt(sigma);
W = abs(R) * ( scl * ones(1,ndat)) ;
W = ???


end
