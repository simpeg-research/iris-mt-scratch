%  gets FCs for one frequency band, one set of files, all stations

function [fc] = fc_get(fids,start_freqs,nch,isets_pt,id,iband)

nn = size(isets_pt); nsets = nn(1); nsta = nn(2); ncht = sum(nch);
ibw = iband(2) - iband(1) + 1; nft = nsets*ibw;

fc = zeros(ncht,nft);
ch2 = 0;
for ista = 1:nsta
   ch1 = ch2+1; ch2 = ch2 + nch(ista);
   irecl = nch(ista)+1;
   for ib = iband(1):iband(2)
      ib1 = ib - iband(1) + 1;
      fseek(fids(ista),start_freqs(ib,ista),'bof');
      head = fread(fids(ista),irecl,'long');
      nsets = head(3);
      head = fread(fids(ista),irecl,'float');
      scales = head(1:nch(ista));
      scales = (scales/1000.);
      ifc = fread(fids(ista),[irecl,nsets],'long');
      fc(ch1:ch2,ib1:ibw:nft) =  ...
            unpack(ifc(2:nch(ista)+1,isets_pt(:,ista)),scales);
   end
end
