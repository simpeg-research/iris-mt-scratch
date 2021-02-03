%******************************************************************
function w = Edfwts(X,EDFparam)
%    emulates edfwts ("effective dof") from tranmt
%     returns weights for reducing leverage

[NSeg,NchIn] = size(X);
if(NchIn ~= 2)
    error('edfwts only works for 2 input channels')
end

if nargin < 2
    %  use default parameters (as in tranmt) to define EDFwts
    EDFparam = struct('edfl1',10,'alpha',.5,'c1',2.0,'c2',10.0);
end

%   eliminate any missing data -- weights returned for segments with some
%   missing data are 1
indX = all(~isnan(X),2);
npts = sum(indX);
X = X(indX,:);
X = X.';

p1 = npts^EDFparam.alpha;
p2 = EDFparam.c2*p1;
p1 = EDFparam.c1*p1;

%    determine intial robust B-field cross-power matrix
nuse = npts;
nOmit = nuse;
use = ones(npts,1);
use = logical(use); %#ok<LOGL>
while nOmit > 0
    s = X(:,use)*X(:,use)'/nuse;
    h = inv(s);
    edf = real(X(1,:).*conj(X(1,:))*h(1,1)+X(2,:).*conj(X(2,:)).*h(2,2)+...
        2*real(conj(X(2,:)).*X(1,:)*h(2,1)));
    use = edf <= EDFparam.edfl1;
    nOmit = nuse - sum(use);
    nuse = sum(use);
end
wt = ones(npts,1);
wt(edf>p2) = 0;
ind = edf<=p2 & edf>p1;
wt(ind) = sqrt(p1./edf(ind));
w = ones(NSeg,1);
w(indX) = wt;
end