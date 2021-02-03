%  makes an array of scales for each channel, including 1/sqrt(T) dependence
%    of impedances
indN = [1:2];
[TF] = eigTF(Sdms.U,Sdms.var,indN);
sqrtT = sqrt(Sdms.T);
scales = zeros(size(TF));
for k = 1:nt
   for l = 1:2
      if upper(char(chid(1,k)) ) == 'E'
         temp =  squeeze(TF(k,l,:)).*sqrtT;
         sc = median(abs(temp));
         scales(k,l,:) = sc.*(1./sqrtT);
      else
         temp =  TF(k,l,:);
         sc = median(abs(temp));
         scales(k,l,:) = sc*ones(1,1,nbt);
      end
   end
end

nu_comp = ones(2,nt-2);
for k=3:nt
   if upper(char(chid(1:2,k)')) == 'HX' | upper(char(chid(1:2,k)')) == 'HY'
      nu_comp(1,k-2) = 10;
      nu_comp(2,k-2) = 10;
   end
end
