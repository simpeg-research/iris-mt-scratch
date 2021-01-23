classdef TTF < handle
    %  simple TF class, supporting full covariance, arbitrary number of
    %  input/output channels (but for MT # input channels = Nin is always 2!)
    properties
        TF          %   array of transfer functions: TF(Nout,Nin,Nperiods)
        %  Example  Zxx = Z(1,1,Period) Zxy = Z(1,2,Period)
        %           Zyx = Z(2,1,Period) Zyy = Z(2,2,Period)
        T           %   list of periods
        Header      %   TF header contains local site header, remote site header
                    %  if appropriate, and information about estimation
                    %  approach?
        Cov_SS      %   inverse signal power matrix
        Cov_NN      %   noise covariance
        Ndf         %   number of samples used to estimate TF for each band,
                    %   and for each output channel (might be different for
                    %   different channels)
        R2           %   multiple coherence for each output channel/band
        FullCov = true   %  logical, true if full covariance is provided
    end
    
    properties (Dependent)
        StdErr      %   standard errors of TF components, same size and order as TF
        NBands
        freqs       %  inverse of period
        Nout
        Nin
    end
    
    methods
        function obj = TTF(NBands,Header)
            %  class constructor
            if nargin > 0
                if nargin == 2
                    Nout = Header.NChOut;
                    Nin = Header.NChIn;
                    %   arrays can be initialized
                    obj.TF = zeros(Nout,Nin,NBands);
                    obj.Ndf = zeros(Nout,NBands);
                    obj.T = zeros(NBands,1);
                    obj.Header = Header;
                    obj.Cov_SS = zeros(Nin,Nin,NBands);
                    obj.Cov_NN = zeros(Nout,Nout,NBands);
                    obj.R2 = zeros(Nout,NBands);
                else
                    error('Either 0 or 2 arguments required for TTF')
                end
            end
        end
        function setTF(obj,ib,TRegObj,T)
            %    this sets TF elements for one band, using contents of TRegression
            %    object.  This version assumes there are estimates for Nout
            %    output channels
            if isempty(obj.TF)
                error('Initialize TTF obect before calling setTF')
            end
            [nData,~] = size(TRegObj.Y);
            %   use TregObj to fill in full impedance, error bars for a
            if any(size(TRegObj.b)~=[obj.Nin obj.Nout])
                error('Regression object not consistent with declared dimensions of TF')
            else
                obj.TF(:,:,ib) = TRegObj.b.';
                obj.Cov_NN(:,:,ib) = TRegObj.Cov_NN;
                obj.Cov_SS(:,:,ib) = TRegObj.Cov_SS;
                obj.T(ib) = T;
                obj.R2(:,ib) = TRegObj.R2;
                obj.Ndf(1:obj.Nout,ib) = nData;
            end
        end
        %******************************************************************
        function setTFRow(obj,ib,ir,TRegObj,T)
            
            if ~obj.Initialized
                error('Initialize TTrFunGeneral obect before calling setTF')
            end
            if nargin < 6
                iSite = 1;
            end
            [nData,~] = size(TRegObj.Y);
            [n,m] = size(TRegObj.b);
            
            obj.FullCov(ib,iSite) = 0;
            if n==obj.Nin && m ==1
                obj.TF(ir,:,ib,iSite) = TRegObj.b;
                obj.R2(ir,ib,iSite)  = TRegObj.R2;
                obj.T(ib,iSite) = T;
                obj.Ndf(ir,ib,iSite) = nData;
            else
                error('Regression object not proper size for operation in setTFRow');
            end
        end
        %******************************************************************
        function value = get.StdErr(obj)
            value = zeros(size(obj.TF));
            for j = 1:obj.Nout
                for k =1:obj.Nin
                    value(j,k,:) = sqrt(obj.Cov_NN(j,j,:).*obj.Cov_SS(k,k,:));
                end
            end
        end
        %******************************************************************
        function value = get.NBands(obj)
            value = length(obj.T);
        end
        %******************************************************************
        function value = get.freqs(obj)
            value = 1./obj.T;
        end
        %******************************************************************
        function value = get.Nout(obj)
            [value,~,~] = size(obj.TF);
        end
        %******************************************************************
        function value = get.Nin(obj)
            [~,value,~] = size(obj.TF);
        end
    end
end %class