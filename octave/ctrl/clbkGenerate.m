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
      end
      % sending command      
      writeCmd(cmd, cmdFile, true);
    end
  catch err
    warndlg(err.message);
  end
end

function prompt = getPrompt(channelCnt, freqCnt)
  prompt = cell();
  for channelID = 1:channelCnt
    for freqID = 1:freqCnt
      prompt{end + 1} = ['CH' num2str(channelID) ': Frequency ' num2str(freqID) ' (Hz)'];
      prompt{end + 1} = ['CH' num2str(channelID) ': Amplitude ' num2str(freqID) ' (<-1, 1>)'];
    end
  end
  prompt{end + 1} = 'Command String: e.g. #CH#[2000,0.4;3000,0.5] [2000,-0.4;3000,-0.5]';
end

function rowscols = getRowscols(channelCnt, freqCnt)
  persistent FIELD_LENGTH = 10;
  rowscols = [];
  for channelID = 1:channelCnt
    for freqID = 1:freqCnt
      rowscols = [rowscols; 1, FIELD_LENGTH; 1, FIELD_LENGTH];
    end
  end
  rowscols = [rowscols; 1, 40];
end

function defaults = getDefaults(channelCnt, freqCnt)
  defaults = cell();
  for channelID = 1:channelCnt
    % only first channel is filled, rest will be duplicated in run_generator, unless zeros entered by user
    for freqID = 1:freqCnt
      if channelID == 1
        defaultValue = '0';
      else
        defaultValue = '';
      end
      % freq
      defaults{end + 1} = defaultValue;
      % ampl
      defaults{end + 1} = defaultValue;
    end
  end
  defaults{end + 1} = '';

  % default - 1000Hz 0.9
  defaults{1} = '1000';
  defaults{2} = '0.9';
end