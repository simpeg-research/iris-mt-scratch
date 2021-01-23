function [S_UV] = UV_pwr(S,var,U,V,Neig);

%  assumes U and V are ewxpressed in Noise units and normalized already

[nt,nb] = size(var);
S_UV = zeros(4,nb);
for ib = 1:nb
  siginv = diag(1./sqrt(var(:,ib)));
  S1 = squeeze(S(:,:,ib));
  S1 = siginv*S1*siginv; 
  U1 = U(:,:,ib);
  V1 = V(:,1:Neig(ib),ib);
  temp = S1*[ U1 V1];
  S_UV(1:2+Neig(ib),ib) = real(sum(conj([U1 V1]).*temp,1)');
end
