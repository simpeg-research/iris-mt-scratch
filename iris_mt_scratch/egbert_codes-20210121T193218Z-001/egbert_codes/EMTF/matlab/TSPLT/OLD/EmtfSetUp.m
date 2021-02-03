global blanks NfilesMax nchar current_dir ...
     blanks_dir ed dirnames

%  most recent data directory is stored in cdfile
cdfile = 'c:\bin_mt24\matlab\Tsplt\current_dir.mat';

%  position/size of window
  x0 = 10;
  y0 = 50;
  xl = 280;
  yl = 400;

%size/location of file name windows
  fwidth = 250;
  fheight = 17; 
  fleft = 20;
  fspace = 5; 
  df = fheight+fspace;
  ddf = df+fspace;
  NfilesMax =15; 
  fbot = 5;

%  to start with let's assume a fixed # of
%  characters in file names ...
  nchar = 12;
  blanks = []; 
  for k=1:nchar
    blanks = [ blanks ' ' ];
  end
  nchar_dir = 40;
  blanks_dir = []; 
  for k=1:nchar_dir
    blanks_dir = [ blanks_dir ' ' ];
  end

%  positions for all of the file name "windowlets"
  for k = NfilesMax:-1:1
     fpos = [ fpos ; ...
              [fleft fbot+(k-1)*df fwidth fheight ]]; 
  end

%  position and size for the main window
  rect = [ x0,y0,xl,yl];

% directory name window label position/size
  rect_dir1 = [ fleft fbot+NfilesMax*df+fspace ...
              fwidth*.1 fheight];

% directory window label position/size
  rect_dir2 = rect_dir1 + ...
            [ rect_dir1(3)+2 0 fwidth*.7-2 0]

%  option buttons at the top ... locations and sizes
  nb = 5;
  db = .3
  bsp = db*xl/((nb+1)^2);
  by0 = yl-25;
  bxl = xl/(nb+db);
  byl = 20; 
  bsp = fix(bsp);
  by0 = fix(by0);
  bxl = fix(bxl);
  byl = fix(byl);
%  button #1
  bx0 = bsp;
  rect_b1 = [ bx0 by0 bxl byl ];
%  button #2
  bx0 = bx0 + bxl + bsp;
  rect_b2 = [ bx0 by0 bxl byl ];
%  button #3
  bx0 = bx0 + bxl + bsp;
  rect_b3 = [ bx0 by0 bxl byl ];
%  button #4
  bx0 = bx0 + bxl + bsp;
  rect_b4 = [ bx0 by0 bxl byl ];
%  button #5
  bx0 = bx0 + bxl + bsp;
  rect_b5 = [ bx0 by0 bxl byl ];

%  initialize main figure
  hfig = figure('Position',rect,'Name','Tsplot :: File Selection',...
              'NumberTitle','Off');
  
  Nfiles = 0;
  filenames = zeros(NfilesMax,nchar);
  dirnames = zeros(NfilesMax,nchar_dir);
  ed = zeros(NfilesMax,1);
  for k=1:NfilesMax
    filenames(k,:) = blanks;
    dirnames(k,:) = blanks_dir;
    ed(k) = uicontrol(hfig,'Style','edit',...
                       'BackgroundColor',[.7,.7,.7],...
                       'ForegroundColor',[0 0 0],...
                       'String',char(filenames(k,:)),...
                       'Position',fpos(k,:),...
                       'UserData',k,...
                       'CallBack',...
                       '[filenames,Nfiles]=chngnm(filenames);');
  end

uicontrol(hfig,'Style','Text',...
               'String','Dir:',...
               'Position',rect_dir1);

%load in name of most recent data directory used
eval(['load ' cdfile]);

h_dir=uicontrol(hfig,'Style','edit',...
              'String',current_dir,...
              'Position',rect_dir2,...
              'CallBack',...
              ['current_dir=get(gco,''String'');'...
               'chngdir;set(gco,''String'',current_dir);']);


uicontrol(hfig,'Style','Pushbutton',...
              'Position',rect_b1,...
              'String','Browse',...
              'Callback','browse',...
              'BackgroundColor',[.7 .7 .9],...
              'ForegroundColor',[.5 .5 .5]);

uicontrol(hfig,'Style','Pushbutton',...
              'Position',rect_b2,...
              'String','Clear',...
              'Callback','clrlist',...
              'BackgroundColor',[.7 .7 .9],...
              'ForegroundColor',[0 0 0]);

uicontrol(hfig,'Style','Pushbutton',...
              'Position',rect_b3,...
              'String','Make *.cfg',...
              'Callback','MkCfg',...
              'BackgroundColor',[.7 .7 .9],...
              'ForegroundColor',[0 0 0]);

uicontrol(hfig,'Style','Pushbutton',...
              'Position',rect_b4,...
              'String','All Files',...
              'Callback','listall',...
              'BackgroundColor',[.7 .7 .9],...
              'ForegroundColor',[0 0 0]);

uicontrol(hfig,'Style','Pushbutton',...
              'Position',rect_b5,...
              'String','Quit',...
              'Callback','quitplt',...
              'BackgroundColor',[.7 .7 .9],...
              'ForegroundColor',[0 0 0]);
              
eval(['cd ' current_dir]);

current_dir

