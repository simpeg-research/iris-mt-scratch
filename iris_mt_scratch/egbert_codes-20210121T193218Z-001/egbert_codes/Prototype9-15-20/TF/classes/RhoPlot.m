%******************************************************************
classdef  RhoPlot < handle
    %   TF plotting object class; some methods are only relevant to
    %   specific types of TFs (or for derived parameters such as rho/phi)
    properties
        TF
    end
    
    methods
        function obj = RhoPlot(tf)
            if nargin == 1
                obj.TF = tf;
            end
        end
                
        function hfig = phasePlot(obj,pred)
            %   simple driver to plot phase only on a separate figures of
            %   fixed size
            hfig = figure('Position',[100,100,325,200],'PaperPosition',[1,1,3.25,2.],...
	            'Tag','Phase Plot');
 
            axRect =  [0.1446    0.2150    0.7604    0.7100];
            if nargin==2
                phaseSubPlot(obj,hfig,axRect,pred);
            else
                phaseSubPlot(obj,hfig,axRect);
            end
            
        end
        %******************************************************************
        %
        function H = rhoPhiPlot(obj,pred)
            %   simple driver to plot phase only on a separate figures of
            %   fixed size
            [rects] = setFigSize(obj);
            hfig = figure('Position',rects.Screen,'PaperPosition',rects.Paper,...
	            'Tag','rho-phi plot');
            
            if nargin==2
                hphi = phaseSubPlot(obj,hfig,rects.Phi,pred);
                hrho = rhoSubPlot(obj,hfig,rects.Rho,pred);
            else
                hphi = phaseSubPlot(obj,hfig,rects.Phi);
                hrho = rhoSubPlot(obj,hfig,rects.Rho);
                
            end
            H = struct('fig',hfig,'rho',hrho,'phi',hphi);
            
        end
        %******************************************************************
        %
        function [hfig,hax] = rhoPlot(obj,varargin)
            %   simple driver to plot rho only on a separate figures of
            %   fixed size
            AddPred = 0;
            inds = 1;
            if nargin > 1
                n = length(varargin);
                if mod(n,2)
                    error('Optional arguments must occur in pairs')
                end
                for k = 1:2:n
                    option = lower(varargin{k});
                    switch option
                        case 'pred'
                            AddPred = varargin{k+1};
                        case 'inds'
                            inds = varargin{k+1};
                    end
                end
            end
            [rects] = setFigSize(obj);
            yFac = (1- (rects.Phi(2)+rects.Phi(4)));
            yMarg = (rects.Rho(2)-(rects.Phi(2)+rects.Phi(4)))/yFac;
            rectScreen = rects.Screen;
            rectScreen(4) = rectScreen(4)*yFac;
            rectPaper = rects.Paper;
            rectPaper(4) = rectPaper(4)*yFac;
            rectRho = rects.Rho;
            rectRho(4) = rectRho(4)/yFac;
            rectRho(2) = yMarg;
            hfig = figure('Position',rectScreen,'PaperPosition',rectPaper,...
                'Tag','rho Plot');
            if AddPred
                hax = rhoSubPlot(obj,hfig,rectRho,pred);
            else
                if inds == 1
                    hax = rhoSubPlot(obj,hfig,rectRho);
                else
                    hax = rhoSubPlotS(obj,hfig,inds);
                end
            end
            grid on
            
        end
        %******************************************************************
        %
        function hax = phaseSubPlot(obj,hfig,axRect,pred)
            %   place a phase subplot on a figure, given figure handle and
            %   axis postion
            
            phi = obj.TF.phi;
            phi(phi<0) =phi(phi<0)+180;
            [Tmin,Tmax] = obj.setTlim;
            lims_ph = [Tmin,Tmax,0,90];
            xt = 10.^[-5:6]; %#ok<*NBRAK>
            xt = xt(xt>=Tmin&xt<=Tmax);
            [xb,yb] = err_log(obj.TF.T',phi(:,1),...
                obj.TF.phi_se(:,1),'XLOG',lims_ph);
            figure(hfig);
            hax = axes('Position',axRect);
            lines = semilogx(xb,yb,'b-',obj.TF.T,phi(:,1),'bo');
            set(lines,'LineWidth',1,'MarkerSize',7);
            hold on;
            [xb,yb] = err_log(obj.TF.T',phi(:,2),...
                obj.TF.phi_se(:,2),'XLOG',lims_ph);
            lines = semilogx(xb,yb,'r-',obj.TF.T,phi(:,2),'ro');
            set(lines,'LineWidth',1,'MarkerSize',7);
            if nargin==4
                plot(pred.TF.T,pred.TF.phi(:,1),'b-','linewidth',2);
                plot(pred.TF.T,pred.TF.phi(:,2),'r-','linewidth',2);
            end
            axis(lims_ph);
            title_pos_x = log(lims_ph(1)) + .1*(log(lims_ph(2)/lims_ph(1)));
            title_pos_x = ceil(exp(title_pos_x));
            title_pos_y = lims_ph(3) + .8* (lims_ph(4)-lims_ph(3));
            c_title = ['\phi :' obj.TF.Header.LocalSite.SiteID];
            text(title_pos_x,title_pos_y,c_title,'FontSize',14,...
                'FontWeight','demi');
            set(gca,'FontWeight','bold','FontSize',11,'Xtick',xt);
            xlabel('Period (s)');
            ylabel('Degrees');
            
        end
        %******************************************************************
        %
        function hax = rhoSubPlot(obj,hfig,axRect,pred)
            %   calls plotrhom, standard plotting routine; uses some other
            %   routines in EMTF/matlab/Zplt; this version is for putting multiple curves
            %   on the same plot
            
            % set plotting limits now that rho is known
            
            [lims] = obj.set_lims;
            lims_rho = lims(1:4);
            xt = 10.^[-5:6];
            xt = xt(xt>=lims(1)&xt<=lims(2));
            [xb,yb] = err_log(obj.TF.T',obj.TF.rho(:,1),...
                obj.TF.rho_se(:,1),'XLOG',lims_rho);
            figure(hfig)

            hax = axes('Position',axRect);
            lines = loglog(xb,yb,'b-',obj.TF.T',obj.TF.rho(:,1),'bo');
            set(lines,'LineWidth',1,'MarkerSize',7);
            hold on;
            [xb,yb] = err_log(obj.TF.T',obj.TF.rho(:,2),...
                obj.TF.rho_se(:,2),'XLOG',lims_rho);
            lines = loglog(xb,yb,'r-',obj.TF.T,obj.TF.rho(:,2),'ro');
            set(lines,'LineWidth',1,'MarkerSize',7);
            if nargin==4
                plot(pred.TF.T,pred.TF.rho(:,1),'b-','linewidth',1.5);
                plot(pred.TF.T,pred.TF.rho(:,2),'r-','linewidth',1.5);
            end
            axis(lims_rho);
            title_pos_x = log(lims_rho(1)) + .1*(log(lims_rho(2)/lims_rho(1)));
            title_pos_x = ceil(exp(title_pos_x));
            title_pos_y = lims_rho(3) + .2* (lims_rho(4)-lims_rho(3));
            c_title = ['\rho_a :' obj.TF.Header.LocalSite.SiteID];
            text(title_pos_x,title_pos_y,c_title,'FontSize',14,...
                'FontWeight','demi');
            set(gca,'FontWeight','bold','FontSize',11,'Xtick',xt);
            xlabel('Period (s)');
            ylabel('\Omega-m');
            
        end
        %******************************************************************
        function [Tmin,Tmax] = setTlim(obj)
            %   set nicer period limits for logartihmic period scale plots
            
            x_min = min(min(obj.TF.T));
            x_max = max(max(obj.TF.T));
            Tmin = 10^(floor(log10(x_min)*2)/2);
            if ((log10(x_min)-log10(Tmin)) < 0.15)
                Tmin = 10^(log10(Tmin)-0.3);
            end
            Tmax = 10^(ceil(log10(x_max)*2)/2);
            if ((log10(Tmax)-log10(x_max)) < 0.15)
                Tmax = 10^(log10(Tmax)+0.3);
            end
        end
        %******************************************************************
        function [lims,orient] = set_lims(obj)
            %  set default limits for plotting; QD, derived from ZPLT
            % use max/min limits of periods, rho to set limits
            [xx_min,xx_max] = setTlim(obj);
            y_min = min(min(min(obj.TF.rho)));
            y_min=max(y_min,1e-20);
            y_max = max(max(max(obj.TF.rho)));
            y_max = max(y_max,1e-20);
            yy_min = 10^(floor(log10(y_min)));
            if ((log10(y_min)-log10(yy_min)) < 0.15)
                yy_min = 10^(log10(yy_min)-0.3);
            end
            yy_max = 10^(ceil(log10(y_max)));
            if ((log10(yy_max)-log10(y_max)) < 0.15)
                yy_max = 10^(log10(yy_max)+0.3);
            end
            if abs(yy_max-yy_min)>1
                lims = [xx_min, xx_max, yy_min, yy_max,0,90];
            else
                lims = [xx_min, xx_max, 0.01, 1e4,0,90];
            end
            orient = 0.;
        end
        %******************************************************************
        function [rects] = setFigSize(obj)
            
            [lims] = set_lims(obj);
            size_fac = 50;
            paperSizeFac = .65;
            one_dec = 1.6;
            xdecs = log10(lims(2)) - log10(lims(1));
            one_dec = one_dec*4/xdecs;
            ydecs = log10(lims(4)) - log10(lims(3));
            paper_width = xdecs*one_dec;
            paper_height = ( ydecs + 3 ) * one_dec;
            paper_height = min([paper_height,9]);
            rectScreen = [0.5,0.5,paper_width,paper_height] * size_fac;
            rectPaper = [1.,1.,paper_width*paperSizeFac,...
                paper_height*paperSizeFac];
            
            rectRho = [.15,.15+2.3/(ydecs+3),.8,ydecs/(ydecs+3)*.8];
            rectPhi = [.15,.15,.8,2/(ydecs+3)*.8];
            rects = struct('Screen',rectScreen,'Paper',rectPaper,...
                'Rho',rectRho,'Phi',rectPhi);
        end
    end
end