
%   include declarations of global variables
    glob_inc

%-----------------------------------------------------------------
%   Set up some defaults

    [Nochn,Nopoints] = size(data);
    WinMax = 1000;
    PointPerWindow   = 2000;
%   stride = fix(PointPerWindow/WinMax);
%   stride = max(1,stride);
   stride = 1;

%   data range
    chplt = ones(Nochn,1);
    chplt_old = ones(Nochn,1);
    for ic = 1:Nochn
      maxch(ic) = ceil(max(data(ic,:)));
      minch(ic) = floor(min(data(ic,:)));
      midch(ic) = (maxch(ic)+minch(ic))/2.;
      chplt(ic) = 1;
      chplt_old(ic) = 1;
    end
    minch0 = minch;
    maxch0 = maxch;

%   sfac gives constant scaling factor change for one click of + or - 
%   pushbutton
    sfac = 1.5;

    page = 1;
    xp = 1;
    nopage = ceil(Nopoints/PointPerWindow);
    centered = 0;

%   Intial window
   rect = [100,100,800,600]*.8;

%   colors for control buttons
   fgc = [0.6 0.6 0.7 ; 0 0 0 ];
   bgc = [.9 .9 1.] ;
   bgc2 = [.7,.7,.9];

   sound_load = 0;

%-----------------------------------------------------------------

%   main plotting window
    h_tsplt = figure('Name','MT Time Series Ploting', ...
                     'Interruptible','yes',...
                     'Position',rect);

%   FRAME FOR PLOTTING CONTROL

    xframe = 0.3;
    yframe = 1.0;
    ixf    = 0.;
    iyf    = 0.;

    uicontrol(h_tsplt,'Style','frame','Units','normalized',...
              'Position',[ixf iyf xframe yframe],...
              'BackgroundColor',bgc);

    uicontrol(h_tsplt,'Style','frame','Units','normalized',...
             'Position',[0.02 0.02 xframe-0.04 yframe-.04],...
             'BackgroundColor',bgc);

%    uicontrol(h_tsplt,'Style','frame','Units','normalized',...
%             'Position',[0.02 0.92 xframe-0.04 0.06],...
%             'BackgroundColor',bgc);
%
%    uicontrol(h_tsplt,'Style','text','String','Control Box',...
%             'Units','normalized','Position',[0.03 0.93 xframe-0.06 0.04],...
%             'HorizontalAlignment','Center',...
%             'BackgroundColor',bgc,...
%             'ForegroundColor',fgc(2,:));

    uicontrol(h_tsplt,'Style','frame','Units','normalized',...
             'Position',[0.032 0.915 .236 0.05],...
             'BackgroundColor',bgc);


    uicontrol(h_tsplt,'Style','text','String','#. Pts',...
             'Units','normalized','Position',[0.035 0.92 .08 0.04],...
             'HorizontalAlignment','Center',...
             'BackgroundColor',bgc2,...
             'ForegroundColor',fgc(2,:));

    NPtWin = uicontrol(h_tsplt,'Style','edit',...
             'String',num2str(PointPerWindow),...
             'Units','normalized',...
             'Position',[0.12 0.92 .145 0.04],...
             'BackgroundColor',bgc2,...
             'ForegroundColor',fgc(2,:),...
             'Callback','chnumpt');

    uicontrol(h_tsplt,'Style','Radio','String','Centered',...
             'Units','normalized',...
             'Position',[0.03 0.85 xframe-0.15 0.04 ], ...
             'BackgroundColor',bgc2,...
             'ForegroundColor',[0 0 0],...
             'Value',centered,...
             'CallBack',['centered=1-centered;' ...
                        'set(gco,''Value'',centered);' ...
                        'setrange(gco,[5,0])']);

    uicontrol(h_tsplt,'Style','Pushbutton',...
              'Units','normalized',...
              'Position',[xframe-.10 0.85 .07 .04],...
              'String','Replt',...
              'Callback','rpltpage',...
              'BackgroundColor',bgc2,...
              'ForegroundColor',fgc(2,:));

    ss = 0.;
    if Nochn < 10  ss = .1; end
    uicontrol(h_tsplt,'Style','Pushbutton','String','Reset',...
             'Units','normalized',...
             'Position',[0.14 .795-ss 0.07 0.04],...
             'UserData',[2,0],...
             'BackgroundColor',bgc,...
             'ForegroundColor',fgc(2,:),...
             'Callback','setrange(gco,get(gco,''UserData''));');

    uicontrol(h_tsplt,'Style','Pushbutton','String',' -  ',...
             'Units','normalized',...
             'Position',[0.09 .795-ss 0.040 0.04],...
             'UserData',[3,0],...
             'BackgroundColor',bgc,...
             'ForegroundColor',fgc(2,:),...
             'Callback','setrange(gco,get(gco,''UserData''));');

    uicontrol(h_tsplt,'Style','Pushbutton','String',' +  ',...
             'Units','normalized',...
             'Position',[0.22 .795-ss 0.040 0.04],...
             'UserData',[4,0],...
             'BackgroundColor',bgc,...
             'ForegroundColor',fgc(2,:),...
             'Callback','setrange(gco,get(gco,''UserData''));');

    uicontrol(h_tsplt,'Style','text','String','Min',...
             'Units','normalized',...
             'Position',[0.11 .745-ss 0.04 0.04],...
             'BackgroundColor',bgc,...
             'ForegroundColor',fgc(2,:));

    uicontrol(h_tsplt,'Style','text','String','Max',...
             'Units','normalized',...
             'Position',[0.21 .745-ss 0.04 0.04],...
             'BackgroundColor',bgc,...
             'ForegroundColor',fgc(2,:));

    iy = 0.71-ss;
    dy = .04 ;
    for ic = 1:Nochn
      uicontrol(h_tsplt,'Style','PushButton',...
             'String',ch_id(ic,1:2),...
             'Units','normalized','Position',[0.03 iy 0.05 dy],...
             'UserData',ic,...
             'BackgroundColor',bgc,...
             'ForegroundColor',fgc(2,:),...
             'CallBack','chonoff');

%     set min for plotting channel ic
      mCH(ic) = uicontrol(h_tsplt,'Style','edit',...
             'String',num2str(minch(ic)),...
             'Units','normalized',...
             'Position',[0.09 iy 0.08 dy],...
             'BackgroundColor',bgc2,...
             'ForegroundColor',fgc(2,:),...
             'UserData',[0,ic],...
             'Callback','setrange(gco,get(gco,''UserData''));');

%     set max for plotting channel ic
      MCH(ic) = uicontrol(h_tsplt,'Style','edit',...
             'String',num2str(maxch(ic)),...
             'Units','normalized',...
             'Position',[0.19 iy 0.08 dy],...
             'UserData',[1,ic],...
             'BackgroundColor',bgc2,...
             'ForegroundColor',fgc(2,:),...
             'Callback','setrange(gco,get(gco,''UserData''));');
      iy = iy - dy; 
    end

    uicontrol(h_tsplt,'Style','Pushbutton',...
              'Units','normalized',...
              'Position',[0.03 0.03 .05 .05],...
              'String','Prev',...
              'Callback','prevpage',...
              'BackgroundColor',bgc2,...
              'ForegroundColor',fgc(2,:));

    uicontrol(h_tsplt,'Style','Pushbutton', ...
              'Units','normalized',...
              'Position',[.09 0.03 .05 .05],...
              'String','Next',...
              'Callback','nextpage',...
              'BackgroundColor',bgc2,...
              'ForegroundColor',fgc(2,:));

    uicontrol('Style','Pushbutton',...
              'Units','normalized',...
              'Position',[0.22 0.03 .05 .05],...
              'String','Quit',...
              'Callback','delete(h_tsplt)',...
              'BackgroundColor',bgc2,...
              'ForegroundColor',fgc(2,:));

    uicontrol(gcf,'Style','text',...
             'String','Goto',...
             'Units','normalized',...
             'Position',[0.03 .09 0.05 0.04],...
             'BackgroundColor',bgc,...
             'ForegroundColor',fgc(2,:));

    h_gotopage =uicontrol(gcf,'Style','edit',...
             'String',num2str(page),...
             'Units','normalized',...
             'Position',[0.08 .09 0.05 0.04],...
             'BackgroundColor',bgc2,...
             'ForegroundColor',fgc(2,:),...
             'Callback','gotopage');

    ss = sprintf('pg# %d/%d',page,nopage);
    PAGE = uicontrol(gcf,'Style','text',...
           'String',ss,...
           'Units','normalized',...
           'Position',[0.13 .09 0.13 0.04],...
           'BackgroundColor',bgc,...
           'ForegroundColor',fgc(2,:));

     npts = min(PointPerWindow,Nopoints-xp+1);
     plotpage(npts,1);
