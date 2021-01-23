function [S_UV] = UV_pwrM(S,var,U,V,Neig,ind);

%   THIS VERSION allows for bad data channels.
%  assumes U and V are ewxpressed in Noise units and normalized already

[nt,nb] = size(var);
S_UV = zeros(4,nb);
for ib = 1:nb
  siginv = diag(1./sqrt(var(ind,ib)));
  S1 = squeeze(S(ind,ind,ib));
  S1 = siginv*S1*siginv; 
  U1 = U(ind,:,ib);
  V1 = V(ind,1:Neig(ib),ib);
  W = [ U1 V1 ];
  W = W/(W'*W);
  temp = S1*W;
  S_UV(1:2+Neig(ib),ib) = real(sum(conj(W).*temp,1)');
end
