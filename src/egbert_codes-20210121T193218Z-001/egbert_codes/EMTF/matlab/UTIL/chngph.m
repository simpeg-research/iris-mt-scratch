%  multiplies complex vector by a phase factor
%  to minimize rms imaginary parts of selected components
%  routine determines phase factor automatically ...
%  Usage: u = chngph(u,ind);

function [u,ph] = chngph(u,ind)

x = [ real(u(ind)), imag(u(ind)) ];
S = x'*x;
[U,D] = eig(S);
[D,I] = sort(diag(D));
U1 = U(:,I(2));
U2 = U(:,I(1));
if nargout ==1
   % Note that there is a sign indeterminacy!!
   v = U1(1)-i*U1(2);
   u = v*u;
elseif nargout == 2
   ph = [atan2(U1(2),U1(1)); atan2(U2(2),U2(1))];
end
return
end 
