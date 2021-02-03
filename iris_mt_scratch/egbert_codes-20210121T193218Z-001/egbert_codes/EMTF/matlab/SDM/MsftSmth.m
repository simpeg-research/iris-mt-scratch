function misfit = MsftSmth(nu)

global alpha XX Xd Ruff X d


alpha = (XX + nu*Ruff)\Xd;
res = (X*alpha - d);
misfit = sum(sum(conj(res).*res));
