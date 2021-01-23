function [lambda_sig] = eval_sig(K,I,nreplicates)
%USAGE: [lambda_sig] = eval_sig(K,I,nreplicates)
%  K = number of components
%  I = number of data
%  nreplicates = # of replicates 

lambda = [];
for k=1:nreplicates
   lambda = [lambda real(eval_syn(K,I))];
end
[lambda,ind] = sort(lambda);
n95 = fix(nreplicates*.95)
hist(lambda);
lambda_sig = lambda(n95);
end

