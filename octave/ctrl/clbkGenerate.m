function clbkGenerate(src, data, title, cmdFile)
  persistent CHANNELS = 2;
  persistent FREQS = 2;
  
  try
    values = inputdlg(getPrompt(CHANNELS, FREQS), title, getRowscols(CHANNELS, FREQS), getDefaults(CHANNELS, FREQS));
    
    % processing values
    if ~isempty(values)
      % pressed OK
      % pre-formatted cmd string overrides all
      if ~isempty(values{end})
        global GENERATE;
        cmd = [GENERATE ' ' values{end}];
      else
        genFunds = buildGenFunds(values, CHANNELS, FREQS);
        cmd = getGeneratorCmdStr(genFunds);
      endif
      % sending command      
      writeCmd(cmd, cmdFile, true);
    endif
  catch err
    warndlg(err.message);
  end_try_catch
endfunction

function prompt = getPrompt(channelCnt, freqCnt)
  prompt = cell();
  for channelID = 1:channelCnt
    for freqID = 1:freqCnt
      prompt{end + 1} = ['CH' num2str(channelID) ': Frequency ' num2str(freqID) ' (Hz)'];
      prompt{end + 1} = ['CH' num2str(channelID) ': Amplitude ' num2str(freqID) ' (<-1, 1>)'];
    endfor
  endfor
  prompt{end + 1} = 'Command String: e.g. CH1[2000,0.4;3000,0.5] [2000,-0.4;3000,-0.5]';
endfunction

function rowscols = getRowscols(channelCnt, freqCnt)
  persistent FIELD_LENGTH = 10;
  rowscols = [];
  for channelID = 1:channelCnt
    for freqID = 1:freqCnt
      rowscols = [rowscols; 1, FIELD_LENGTH; 1, FIELD_LENGTH];
    endfor
  endfor
  rowscols = [rowscols; 1, 40];
endfunction

function defaults = getDefaults(channelCnt, freqCnt)
  defaults = cell();
  for channelID = 1:channelCnt
    % only first channel is filled, rest will be duplicated in run_generator, unless zeros entered by user
    for freqID = 1:freqCnt
      if channelID == 1
        defaultValue = '0';
      else
        defaultValue = '';
      endif
      defaults{end + 1} = defaultValue;
      defaults{end + 1} = defaultValue;
    endfor
  endfor
  defaults{end + 1} = '';
endfunction