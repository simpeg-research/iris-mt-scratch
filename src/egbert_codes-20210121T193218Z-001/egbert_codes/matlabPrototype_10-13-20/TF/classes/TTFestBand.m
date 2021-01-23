classdef TTFestBand < handle
    %  This is a simple but general robust transfer function esimation
    %  class:  robus estimation of transfer functions between NchIn input
    %  channels and NchOut output channels.    A reference (NChIN channels)
    %  can be provided as input, as can a set of weights for each
    %  segment x output channel
    %   All arrays can have NaNs, to indicate missing data
    
    %   The main thing that this does is manage several types of weights
    %    Namely: segment weights (as for example leverage downweitghting;
    %      same for all output channels; there is a routine here for
    %      computing these "edf weights" as in tranmt) and weights which
    %      are channel dependent  (but also depend on segments),   These
    %      would for instance be calculate from broadband coherence between
    %      X and Y
    
    properties
        X     %  (Nseg,NchIn) design matrix (input channels)
        Y     %  (Nseg,NchOut) predicted (output) channels
        R     %  (Nseg, NchIn)  matrix of reference variables
        NchIn   %  by default = 2 as we are doing MT/quasi-uniform sources
        NchOut   %   usually 1, 2, or 3
        Nseg
        WtSeg  %  (Nseg) weights for segments (e.g., edf, coherence of X/R)
        WtCh   %  (Nseg,NchOut)  weights for segments/Channels (eg coh of X/Y)
        Iter  %   Itercontrol object
        RegrEst   %   TRME object containing final iterative estimate
        SSorRR = 'SS'
        weights = 'none'
        
        EDFparam  %   strucure containing parameters used to control levergae
                  %   downweighting
   
    end
    
    methods
        function obj = TTFestBand(X,Y,R,wt)
            if nargin > 0
                if nargin ==1
                    error('TTFestBand: not enough input arguments')
                end
                if nargin>=2
                    [obj.Nseg,obj.NchIn] = size(X);
                    [n,obj.NchOut] = size(Y);
                    if(n ~= obj.Nseg)
                        error('TTFestBand: number of segments in X and Y must be equal');
                    end
                    obj.X = X;
                    obj.Y = Y;
                end
                if nargin>=3
                    if isempty(R)
                        obj.SSorRR = 'SS';
                    else
                        [m,n] = size(R);
                        if n~=obj.NchIn || m~= obj.Nseg
                            error('TTFestBand: R must be same size as X');
                        end
                        obj.R = R;
                        obj.SSorRR = 'RR';
                    end
                end
                if nargin==4
                    [m,n] = size(wt);
                    if m==obj.Nseg && n == 1
                        obj.WtSeg = wt;
                        obj.weights = 'Seg';
                    else
                        if n~=obj.NchOut || m== obj.Nseg
                            obj.WtCh = wt;
                            obj.weights = 'Ch';
                        else
                            error('TTFestBand: WtCh must be same size as Y');
                        end
                    end
                    
                end
            end
            obj.Iter = IterControl;
            obj.Iter.iterMax = 50;
            obj.Iter.rdscnd = false;
            obj.Iter.r0 = 1.5;
            %   these are default EDF weights used in tranmt
            obj.EDFparam = struct('edfl1',10,'alpha',.5,'c1',2.0,'c2',10.0);
        end
        %********************************************************************
        function Estimate(obj)
            
            obj.RegrEst = cell(obj.NchOut,1);
            switch obj.SSorRR
                case 'SS'
                    % eliminate all segments with any magnetics missing
                    indX = all(~isnan(obj.X),2);
                    %    assuming here that weights are never missing
                    %    (unless something else is)
                    switch obj.weights
                        case {'Seg','Both'}
                            indX = obj.WtSeg>0 & indX;
                             Wtt = obj.WtSeg(indX);
                        otherwise
                            Wtt = ones(sum(indX),1);
                    end 
                    Xt = obj.X(indX,:);
                    Yt = obj.Y(indX,:);
                   
                    for k=1:obj.NchIn
                        Xt(:,k) = Xt(:,k).*Wtt;
                    end
                    for k  = 1:obj.NchOut
                        Yt(:,k) = Yt(:,k).*Wtt;
                    end                  
                    %  now process channel-by-channel, omitting all missing/bad
                    %  segments for that channel
                    for ich = 1:obj.NchOut
                        indY = ~isnan(Yt(:,ich));
                        switch obj.weights
                            case {'Ch','Both'}
                                w = obj.WtCh(indX,ich);
                                indY = obj.WtCh(indX,ich) & indY;
                                w = w(indY);
                            otherwise
                                w = ones(sum(indY),1);     
                        end
                        n = sum(indY);
                        W = spdiags(w,0,n,n);
                        obj.RegrEst{ich} = TRME(W*Xt(indY,:),W*Yt(indY,ich).',obj.Iter);
                        obj.RegrEst{ich}.Estimate;
                    end
                case 'RR'
                    % eliminate all segments with any magnetics missing
                    indX = all(~isnan(obj.X),2) & all(~isnan(obj.R),2);
                    %    assuming here that weights are never missing
                    %    (unless something else is)
                    switch obj.weights
                        case {'Seg','Both'}
                            indX = obj.WtSeg>0 & indX;
                            Wtt = obj.WtSeg(indX);
                        otherwise
                            Wtt = ones(sum(indX),1);
                    end
                    Xt = obj.X(indX,:);
                    Yt = obj.Y(indX,:);
                    Rt = obj.R(indX,:);
                    for k=1:obj.NchIn
                        Xt(:,k) = Xt(:,k).*Wtt;
                        Rt(:,k) = Rt(:,k).*Wtt;
                    end
                    for k  = 1:obj.NchOut
                        Yt(:,k) = Yt(:,k).*Wtt;
                    end                  
                    %  now process channel-by-channel, omitting all missing/bad
                    %  segments for that channel
                    for ich = 1:obj.NchOut
                        indY = ~isnan(Yt(:,ich));
                        
                        switch obj.weights
                            case {'Ch','Both'}
                                w = obj.WtCh(indX,ich);
                                indY = obj.WtCh(indX,ich) & indY;
                                w = w(indY);
                            otherwise
                                w = ones(sum(indY),1);     
                        end
                        n = sum(indY);
                        W = spdiags(w,0,n,n);
                      obj.RegrEst{ich} = ...
                            TRME_RR(W*Xt(indY,:),W*Yt(indY,ich),W*Rt(indY,:),obj.Iter);   
                        obj.RegrEst{ich}.Estimate;
                    end   
            end
        end
        %******************************************************************
        function Edfwts(obj)
            %    emulates edfwts ("effective dof") from tranmt
            
            if(obj.NchIn ~= 2)
                error('edfwts only works for 2 input channels')
            end
            
            indX = all(~isnan(obj.X),2);
            npts = sum(indX);
            b = obj.X(indX,:);
            switch obj.weights
                case {'Seg','Both'}
                    for k = 1:obj.NchIn
                        b(:,k) = b(:,k).*obj.WtSeg(indX);
                    end
                case {'Ch'}
                    %  initialize for segment weights if not already in use
                    obj.WtSeg = ones(obj.Nseg,1);
                    obj.weights = 'Both';
                otherwise
                    %   no weights yet
                    obj.WtSeg = ones(obj.Nseg,1);
                    obj.weights = 'Seg';
            end
            b = b.';
            
            p1 = npts^obj.EDFparam.alpha;
            p2 = obj.EDFparam.c2*p1;
            p1 = obj.EDFparam.c1*p1;
            
            %    determine intial robust B-field cross-power matrix
            nuse = npts;
            nOmit = nuse;
            use = ones(npts,1);
            use = logical(use); %#ok<LOGL>
            while nOmit > 0
                s = b(:,use)*b(:,use)'/nuse;
                h = inv(s);
                edf = real(b(1,:).*conj(b(1,:))*h(1,1)+b(2,:).*conj(b(2,:)).*h(2,2)+...
                    2*real(conj(b(2,:)).*b(1,:)*h(2,1)));
                use = edf <= obj.EDFparam.edfl1;
                nOmit = nuse - sum(use);
                nuse = sum(use);
            end
            wt = ones(npts,1);
            wt(edf>p2) = 0;
            ind = edf<=p2 & edf>p1;
            wt(ind) = sqrt(p1./edf(ind));
            obj.WtSeg(indX) = obj.WtSeg(indX).*wt;
        end
    end
end
