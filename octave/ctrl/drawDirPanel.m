function dirStruct = drawDirPanel(fig, x, y, width, height, title, dirStruct, cmdFile)
  persistent STATUS_TXT_CNT = 5;
  persistent TXT_FIELD_HEIGHT = 0.035;

  global DIR_PLAY;
  
  panel = uipanel(fig,
            "position", [x, y, width, height]);
  dirStruct.panel = panel;
  updatePanelTitle(dirStruct, NA);

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

  % initializing status txt fields
  statusTxts = cell(STATUS_TXT_CNT, 1);  
  for i = 1:STATUS_TXT_CNT
    [statusTxts{i}, statusTxtY] = drawStatusTxt(i, panel, devPanelY - 0.04, TXT_FIELD_HEIGHT);
  end
  dirStruct.statusTxts = statusTxts;

  % relative height of the channel block (plot, detailTxt)
  channelHeight = statusTxtY - 0.01;
  
  dirStruct = drawChannelPlot(1, 0.01, 0.12, channelHeight, 'Left', panel, dirStruct);
  dirStruct = drawChannelPlot(2, 0.87, 0.12, channelHeight, 'Right', panel, dirStruct);
  
  dirStruct.detailTxts{1} = drawDetailTxt(1, 0.14, 0.35, channelHeight, panel);
  dirStruct.detailTxts{2} = drawDetailTxt(2, 0.50, 0.35, channelHeight, panel);  
end

function dirStruct = drawChannelPlot(channelID, x, width, height, title, panel, dirStruct)
  plotPanel = uipanel(panel, 
            "title", title, 
            "position", [x, 0, width, height]);
  dirStruct.plotPanels{channelID} = plotPanel;
  dirStruct.calPlots{channelID} = initPlot(plotPanel);  
end

function detailTxt = drawDetailTxt(channelID, x, width, height, panel, dirStruct)
    detailTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [x, 0, width, height]);
end


function [statusTxt, y] = drawStatusTxt(id, panel, topY, fieldHeight)
  y = topY - (fieldHeight * (id - 1));
  statusTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "fontweight", "bold",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.01, y, 1, fieldHeight]
            );
end


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
end


