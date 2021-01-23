% ***********************  NEW  VERSION **************************
%   Feb. 5 2000
% ***********************  NEW  VERSION **************************

ids = [];start_decs = []; chid = []; nch = [];orient = [];fids = [];

%  open FC files, read headers
for ista = 1:nsta
  fprintf(1,'%s %s \n','File ',cfile(ista,1:nchar(ista)))
  [nd,nf,nch1,chid1,orient1,drs,stdec,decs,fid,start_dec] ...
                    = fc_open(cfile(ista,1:nchar(ista)));
  if (fid < 0 ) 
     fprintf(1,'%s \n','File not found');
     break ; 
  end
  
  fids = [ fids fid ];
  start_decs = [start_decs ; start_dec ] ;
  chid = [ chid ;  chid1 ];
  nch = [nch  nch1 ];
  orient = [orient orient1(1,:) ];
end
  
if(fid > 0 )
  %   set up array of pointers to start of each frequency in each FC file
  [start_freqs] = mk_start_freqs(id,fids,nf,nch,start_decs);

  %   find set numbers available for all sites
  [isets,isets_pt] =  mk_isets(fids,start_decs,nch,nf,id);

  nsets = length(isets);
  ntime = fix(nsets/navg);
  N = navg*ntime;
  %  time expressed in days (1 Jan 0:00 UT = 1.0 )
  time = 1 + drs(id)*(isets(1:navg:N)+navg/2)*96/86400;

  %   compute average Xpowers, residual, etc. averaged over
  %   time window defined by navg 
  %   currently doesn't work with navg = 1 (because of the way "sum" works)
  %   list of x-powers to do computations for
  %  these are given by an array containing indices of cross-powers to
  %    save ... call xind
  %  zero arrays
if compXp
  for k=1:nxind
    eval( [ 's' num2str(xind(k,1)) num2str(xind(k,2)) ' = zeros(nbands,ntime);'] )
  end
end
 
   % RESIDUALS :::
   for k = 1:nres
      eval( [ res_names(k,:) ' = zeros(nbands,ntime);']);
   end

  % loop over bands ...
  for kb = 1:nbands
%    get FCs for band
     [fc] = fc_get(fids,start_freqs,nch,isets_pt,id,iband(:,kb));
     if any(scFac ~= 1)
        fc = diag(scFac)*fc;
     end
%    set up array TF for band
     U = [U1(kb,:).' U2(kb,:).' ];

%  TEST
%    data cleaning ... test version
   if ( clean )
      niter = 4; ch_groups = [1 2 ; 3 4 ; 6 7 ; 9 10 ];
      [fcc] = clean_fc(fc,U,ch_groups,niter);
   else
      fcc = fc;
   end

   if compXp
%    cross-power calculation
     for k=1:nxind
        temp1 = reshape(fcc(xind(k,1),1:N),navg,ntime);
        if(xind(k,2) == xind(k,1) )
           eval( [ 's' num2str(xind(k,1)) num2str(xind(k,2)) ...
                           '(kb,:) = real(sum(temp1.*conj(temp1)));']);
         else
            temp2 = reshape(fcc(xind(k,2),1:N),navg,ntime);
            eval( [ 's' num2str(xind(k,1)) num2str(xind(k,2)) ...
                           '(kb,:) = sum(temp1.*conj(temp2));']);
        end
      end
   end
%    residual calculation
     [Ncht,dum] = size(U);
     Pall = mk_P(U,SIGMA_N(kb,:)',[1:Ncht]);
     for k = 1:nres
        comp = res_ind(k,1);
        icomp_in = res_ind(k,3:2+res_ind(k,2));
        if(res_ind(k,2) ~= Ncht)
           P = mk_P(U,SIGMA_N(kb,:)',icomp_in);
        else
           P = Pall;
        end
        temp1=reshape(fc(comp,1:N)-P(comp,:)*fcc(icomp_in,1:N),navg,ntime);
        eval( [ res_names(k,:) '(kb,:) = real(sum(temp1.*conj(temp1) ) ) ;']);
     end
   end

  fclose(fids(ista));
end
