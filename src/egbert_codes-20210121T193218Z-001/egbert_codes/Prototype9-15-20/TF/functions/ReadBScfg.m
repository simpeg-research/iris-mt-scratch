       function bandLims = ReadBScfg(bsFile) 
            %   Reads standard "band set up" file, as used by tranmtlr, mmt, etc.
            %   Usage: [iBand]  = readBCcfg(bsFile);
          if exist(bsFile,'file')
            fid = fopen(bsFile,'r');
            nBands = fscanf(fid,'%d',1);
            iDec = zeros(nBands,1);
            bandLims = zeros(nBands,3);
            for k = 1:nBands
                bandLims(k,:) = fscanf(fid,'%d',3);
            end
          else
            error(['Can not find band setup file:  ', bsFile]); 
          end    
       end