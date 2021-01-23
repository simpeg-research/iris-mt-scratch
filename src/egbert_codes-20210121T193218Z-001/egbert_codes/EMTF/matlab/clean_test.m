% QAD testing routine ... run stack_days first for a single day
%  to get FC files set up 

kb = 10
%get FCs for band
[fc] = fc_get(fids,start_freqs,nch,isets_pt,id,iband(:,kb));
%  groups for predictions
ch_groups = [ 1 2 ; 4 5 ; 6 7 ; 9 10 ];
niter = 4;
[fcc,temp,wttemp] = clean_fc(fc,U,ch_groups,niter) ;

%figure
%pcolor(log10(abs(fc)));shading flat
%figure
%pcolor(log10(abs(fcc)));shading flat
figure
z = abs((fcc-fc)./fcc);
z = ( z > 1 ) + ( z < 1 ) .* z; 
z = [ z; z(10,:) ];
pcolor(z); shading flat; colorbar ; caxis([0,1]);
colormap(jet);

