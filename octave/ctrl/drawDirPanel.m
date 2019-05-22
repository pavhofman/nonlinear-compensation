function dirStruct = drawDirPanel(fig, x, width, title, dirStruct, cmdFile)
  global CHANNEL_REL_HEIGHT;
  persistent STATUS_TXT_CNT = 5;
  global TXT_FIELD_HEIGHT;
  global DIR_PLAY;
  
  panel = uipanel(fig, 
            "title", title,
            "position", [x, 0.1, width, 0.9]);
  % from the top
  devPanelHeight = 2 * TXT_FIELD_HEIGHT + 0.05;
  maxFigY = 0.99;
  
  devPanelY = maxFigY - devPanelHeight;
  inDevPanel = uipanel(panel, 
            "title", 'IN',
            "position", [0, devPanelY, 0.5, devPanelHeight]);
  maxDevPanelY = 0.88;
  sourceTxt = uicontrol (inDevPanel,
            "style", "text",
            "units", "normalized",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.01, 0.01, 1, maxDevPanelY]
            );

  dirStruct.sourceTxt = sourceTxt;

  outDevPanel = uipanel(panel, 
            "title", 'OUT',
            "position", [0.5, devPanelY, 0.5, devPanelHeight]);
            
  sinkTxt = uicontrol (outDevPanel,
            "style", "text",
            "units", "normalized",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.01, 0.01, 1, maxDevPanelY]
            );
  dirStruct.sinkTxt = sinkTxt;

  modesHeight = TXT_FIELD_HEIGHT + 0.02;
  modesY = devPanelY - modesHeight;
  % mode radios
  global MODE_DUAL;
  global MODE_BAL;
  global MODE_SINGLE;
  
  % create a button group
  bGroup = uibuttongroup (panel, 
            'units', 'normalized',
            'selectionchangedfcn', {@clbkSetChMode, cmdFile}, 
            'Position', [0, modesY, 1, modesHeight]);
  dirStruct.chModeGroup = bGroup;

  dirStruct.modeRadios{MODE_DUAL} = uicontrol (bGroup, 'style', 'radiobutton',
            'string', 'DUAL [L] [R]',
            'units', 'normalized',
            'userdata', MODE_DUAL,
            'Position', [ 0 0 0.3 1]);
  
  if dirStruct.dir == DIR_PLAY
    radioTitle = 'BAL [-R] [R]';
  else
    radioTitle = 'BAL [R-L]/2 [R-L]/2';
  endif
  
  dirStruct.modeRadios{MODE_BAL} = uicontrol (bGroup, 'style', 'radiobutton',
            'string', radioTitle,
            'units', 'normalized',
            'userdata', MODE_BAL,
            'Position', [ 0.35 0 0.3 1]);
            
  if dirStruct.dir == DIR_PLAY
    radioTitle = 'SINGLE [0] [R]';
  else
    radioTitle = 'SUBTR [R-L] [R-L]';
  endif

  dirStruct.modeRadios{MODE_SINGLE} = uicontrol (bGroup, 'style', 'radiobutton',
            'string', radioTitle,
            'units', 'normalized',
            'userdata', MODE_SINGLE,
            'Position', [ 0.7 0 0.3 1]);
  
  
  % initializing status txt fields
  statusTxts = cell(STATUS_TXT_CNT, 1);  
  for i = 1:STATUS_TXT_CNT
    [statusTxts{i}, statusTxtY] = drawStatusTxt(i, panel, modesY - 0.03); 
  endfor
  dirStruct.statusTxts = statusTxts;

  % relative height of the channel block (plot, detailTxt)
  channelHeight = statusTxtY - 0.01;
  
  dirStruct = drawChannelPlot(1, 0.01, 0.12, channelHeight, 'Left', panel, dirStruct);
  dirStruct = drawChannelPlot(2, 0.87, 0.12, channelHeight, 'Right', panel, dirStruct);
  
  dirStruct.detailTxts{1} = drawDetailTxt(1, 0.14, 0.35, channelHeight, panel);
  dirStruct.detailTxts{2} = drawDetailTxt(2, 0.50, 0.35, channelHeight, panel);  
endfunction

function dirStruct = drawChannelPlot(channelID, x, width, height, title, panel, dirStruct)
  plotPanel = uipanel(panel, 
            "title", title, 
            "position", [x, 0, width, height]);
  dirStruct.plotPanels{channelID} = plotPanel;
  dirStruct.calPlots{channelID} = initPlot(plotPanel);  
endfunction

function detailTxt = drawDetailTxt(channelID, x, width, height, panel, dirStruct)
    detailTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [x, 0, width, height]);
endfunction


function [statusTxt, y] = drawStatusTxt(id, panel, topY)
  global TXT_FIELD_HEIGHT;
  
  y = topY - (TXT_FIELD_HEIGHT * (id - 1));
  statusTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "fontweight", "bold",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.01, y, 1, TXT_FIELD_HEIGHT]
            );
endfunction


function [plotStruct] = initPlot(plotPanel)
  axis = axes ('parent', plotPanel);
  x = [];
  % 3 lines - calibration levels, current levels, last levels
  lines = plot(axis, 0, 0, '>r', 'markerfacecolor', 'r', 1, 0, '<r', 'markerfacecolor', 'b', 0.5, 0, '<r', 'markerfacecolor', 'g');
  % fixed limit
  set(axis, 'ylim', [-20,0]);
  calLine = lines(1);
  curLine = lines(2);
  lastLine = lines(3);
  set(calLine, 'visible', 'off');
  set(curLine, 'visible', 'off');
  set(lastLine, 'visible', 'off');
  
  rangePatch = patch (axis, NA, NA, 'b');
  set(rangePatch, 'visible', 'off');
  
  set(axis,'Xtick',[])
  set(axis, "ygrid", "on");
  set(axis, "outerposition",  [0, 0, 1, 1])
  set(axis, "outerposition",  [0, 0, 1, 1])
  
  plotStruct = struct();
  plotStruct.axis = axis;
  % line with calibration level points
  plotStruct.calLine = calLine;
  % line with current level points
  plotStruct.curLine = curLine;
  % line with last level points before calibration
  plotStruct.lastLine = lastLine;
  % patch for calibration level range
  plotStruct.rangePatch = rangePatch;
endfunction


