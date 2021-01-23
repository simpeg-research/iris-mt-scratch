classdef TTFZ < TTF
    %  subclass to support some more MT impedance specficic functions  --
    %  initially just apparent resistivity and pbase for diagonal elements
    %   + rotation/fixed coordinate system
    
    properties
        rho
        rho_se
        phi
        phi_se
    end
    methods
        
        function obj = TTFZ(NBands,Header)
            obj = obj@TTF;
            if nargin ==2
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
        %******************************************************************
        function ap_res(obj)
            %ap_res(...) : computes app. res., phase, errors, given imped., cov.
            %USAGE: [rho,rho_se,ph,ph_se] = ap_res(z,sig_s,sig_e,periods) ;
            % Z = array of impedances (from Z_***** file)
            % sig_s = inverse signal covariance matrix (from Z_****** file)
            % sig_e = residual covariance matrix (from Z_****** file)
            % periods = array of periods (sec)
            
            switch obj.Nout
                case 2
                    zRows = 1:2;
                case 3
                    zRows = 2:3;
                otherwise
                    error('ap_res only works for 2 or 3 output channels')
            end
                        
            rad_deg = 180/pi;
            %   off-diagonal impedances
            obj.rho = zeros(obj.NBands,2);
            obj.rho_se = zeros(obj.NBands,2);
            obj.phi = zeros(obj.NBands,2);
            obj.phi_se = zeros(obj.NBands,2);
            Zxy = squeeze(obj.TF(zRows(1),2,:));
            Zyx = squeeze(obj.TF(zRows(2),1,:));
            % standard deviation  of real and imaginary parts of impedance
            Zxy_se = squeeze(obj.StdErr(zRows(1),2,:))/sqrt(2);
            Zyx_se = squeeze(obj.StdErr(zRows(2),1,:))/sqrt(2);
            %   apparent resistivities
            rxy = obj.T(:).*(abs(Zxy).^2)/5.;
            ryx = obj.T(:).*(abs(Zyx).^2)/5.;
            
            rxy_se = 2*sqrt(obj.T(:).*rxy/5).*Zxy_se;
            ryx_se = 2*sqrt(obj.T(:).*ryx/5).*Zyx_se;
            obj.rho(:,:) = [rxy ryx];
            obj.rho_se(:,:) = [rxy_se ryx_se];
            %   phases
            pxy = rad_deg*atan(imag(Zxy)./real(Zxy));
            pyx = rad_deg*atan(imag(Zyx)./real(Zyx));
            obj.phi(:,:) = [pxy pyx];
            pxy_se = rad_deg*Zxy_se./abs(Zxy);
            pyx_se = rad_deg*Zyx_se./abs(Zyx);
            obj.phi_se(:,:) = [pxy_se pyx_se];
        end
    end
end