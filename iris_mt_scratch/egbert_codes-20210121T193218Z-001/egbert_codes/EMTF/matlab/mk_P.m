%    mk_P ... makes projection operator, given two vectors which
%    span MT signal space + estiamtes of noise variances for each channel
%    uses only components in array icomp for the prediction ...
%    USAGE:  [P] = mk_P(U,sigma,icomp) ;

function [P] = mk_P(U,sigma,icomp)

nm = size(U);  nt = nm(1); npc = nm(2);
temp = U(icomp,:) .* ( (1./sigma(icomp)) * ones(1,npc) ) ;
P = U/(temp'*U(icomp,:));
P = P * temp' ; 
end
