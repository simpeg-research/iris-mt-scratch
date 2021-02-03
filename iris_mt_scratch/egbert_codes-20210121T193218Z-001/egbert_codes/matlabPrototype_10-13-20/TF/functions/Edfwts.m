%******************************************************************
function w = Edfwts(X,R,EDFparam)
%    emulates edfwts ("effective dof") from tranmt
%     returns weights for reducing leverage

%optional argument for RR processing -- aligned array of RR FCs
RR = false;
if nargin >= 2
    if isempty(R)
        RR = false;
    else
        RR = true;
    end
end

[NSeg,NchIn] = size(X);
if(NchIn ~= 2)
    error('edfwts only works for 2 input channels')
end

if nargin < 3
    %  use default parameters (as in tranmt) to define EDFwts
    EDFparam = struct('edfl1',20,'alpha',.5,'c1',2.0,'c2',10.0,'p3',5);
end

%   eliminate any missing data -- weights returned for segments with some
%   missing data are 1
if RR
    indX = all(~isnan([X R]),2);
else
    indX = all(~isnan(X),2);
end
npts = sum(indX);
X = X(indX,:);
X = X.';
if RR
    R = R(indX,:);
    R = R.';
end

p1 = npts^EDFparam.alpha;
p2 = EDFparam.c2*p1;
p1 = EDFparam.c1*p1;

%    determine intial robust B-field cross-power matrix; this just uses
%    edfl1 -- cut off for estimating robust local magnetic covariance
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

if RR
    % now find additional segments with crazy remotes
    wtRef = ones(npts,1);
    edfRef = real(R(1,:).*conj(R(1,:))*h(1,1)+R(2,:).*conj(R(2,:)).*h(2,2)+...
        2*real(conj(R(2,:)).*R(1,:)*h(2,1)));
    wtRef(edfRef>p2) = 0;
    ind = edfRef<=p2 & edfRef>p1;
    wtRef(ind) = sqrt(p1./edfRef(ind));
    
    differentAmp = wtRef./wt > EDFparam.p3 | wt./wtRef > EDFparam.p3;
    wt = wt.*wtRef;
    wt(differentAmp)= 0;
end

w(indX) = wt;
end