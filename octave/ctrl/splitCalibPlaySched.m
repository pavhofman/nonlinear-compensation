% scheduler-enabled function for split calibration of PLAY side
% Only one-sine (one fundamental) is supported!!
% calibrating at current freq. If some pre-measured VD and LPF transfer is missing, runs measureTransferSched task
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = splitCalibPlaySched(label = 1)
  result = NA;
  % init section
  [CHECKING_LABEL, START_LABEL, PASS_LABEL, ADAPTER_LPF, MODE_LABEL, WAIT_FOR_LP_LABEL, CAL_LP_LABEL, SWITCH_TO_VD_LABEL, WAIT_FOR_VD_LABEL, CAL_VD_LABEL, SPLIT_CAL_LABEL, COMP_PLAY_LABEL, ...
      ALL_OFF_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Split-Calibrating PLAY Side';

  persistent AUTO_TIMEOUT = 20;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;

  % analysed input ch goes through LPF or VD, the other input channel is direct
  global ANALYSED_CH_ID;
  % ID of output channel used for split calibration
  global PLAY_CH_ID;
  
  global EXTRA_CIRCUIT_VD;
  global EXTRA_CIRCUIT_LP1;
  
  global cmdFileRec;
  global cmdFilePlay;
  global PASS;
  global CALIBRATE;
  global COMPENSATE;
  global CMD_EXTRA_CIRCUIT_PREFIX;
  global CMD_CHANNEL_FUND_PREFIX;
  global CMD_COMP_TYPE_PREFIX;
  global CMD_PLAY_AMPLS_PREFIX;
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;

  global MODE_DUAL;
  global ABORT;
  
  persistent lpFundAmpl = NA;
  
  % current frequency of calibration
  % all set in first P1 branch
  persistent curFreq = NA;
  persistent fs = NA;
  persistent origPlayFreq = NA;
  persistent origRecFreq = NA;
  persistent origPlayLevels = NA;
  persistent playEqualizer = NA;

  % VD at fundament (origRecFreq) must be calibrated at exactly the same level as LPF so that the distortion characteristics of ADC are same
  % amplitude-constrained calibration
  % we need same ADC distortion profile for LPF and VD => the level must be as close as possible for best results
  persistent MAX_AMPL_DIFF = db2mag(-85);

  global adapterStruct;
  persistent wasAborted = false;

  while true
    switch(label)
    
      case CHECKING_LABEL
        
        global playInfo;
        global recInfo;
        
        addTask(mfilename(), NAME);
        % init value
        wasAborted = false;
        
        % loading current values from analysis
        fs = recInfo.fs;
        % TODO - checks - only one fundament freq!!
        % if playback freq is known, use it (playback will be generating). If no (playback has no signal, rec fed by an external generator, use recInfo)
        if length(playInfo.measuredPeaks) >= PLAY_CH_ID && ~ isempty(playInfo.measuredPeaks{PLAY_CH_ID})
          origPlayFreq = playInfo.measuredPeaks{PLAY_CH_ID}(1, 1);
        else
          origPlayFreq = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 1);
        endif
        
        origRecFreq = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 1);

        % two channels, only first fundament freqs (the only freq!)
        origPlayLevels = cell();
        for channelID = 1:length(playInfo.measuredPeaks)
          measuredPeaksCh = playInfo.measuredPeaks{channelID};
          if isempty(measuredPeaksCh)
            % no signal = zero amplitude
            levelCh = 0;
          else
            levelCh = measuredPeaksCh(1, 2);
          endif
          origPlayLevels{end + 1} = levelCh;
        endfor
        
        % playLevels are measured BEHIND equalizer in play process. When generating, one must take the equalizer into account to reach identical play levels
        % only values for first two channels to fit origPlayLevels
        playEqualizer = playInfo.equalizer(1:2);
        
        % checking if all transfer files are available
        [freqs1, freqs1] = getMissingTransferFreqs(origPlayFreq, origRecFreq, fs, EXTRA_CIRCUIT_LP1, recInfo.nonInteger);
        [freqs2, freqs2] = getMissingTransferFreqs(origPlayFreq, origRecFreq, fs, EXTRA_CIRCUIT_VD, recInfo.nonInteger);
        if ~isempty(freqs1) || ~isempty(freqs2)
          % some are missing, ask for measuring transfer. failed label = ABORT
          waitForTaskFinish('measureTransferSched', START_LABEL, ABORT, mfilename());
          return;
        else
          label = START_LABEL;
          continue;
        endif
        
      case START_LABEL
        clearOutBox();
        adapterStruct.out = false; % OUT off
        adapterStruct.in = false; % CALIB IN
        adapterStruct.lpf = true; % LPF
        adapterStruct.reqLevels = []; % no stepper adjustment
        adapterStruct.maxAmplDiff = [];
        waitForAdapterAdjust(sprintf('Set switches for CH%d LPF calibration', ANALYSED_CH_ID), adapterStruct, CAL_LP_LABEL, ABORT, ERROR, mfilename());
        return;

      case PASS_LABEL
        cmdIDPlay = writeCmd(PASS, cmdFilePlay);
        cmdIDRec = writeCmd(PASS, cmdFileRec);
        % we have to wait for command acceptance before issuing new commands (the cmd files could be deleted by new commands before they are consumed
        % waiting only for one of the pass commands, both sides run at same speed
        % after AUTO_TIMEOUT secs timeout call ERROR
        waitForCmdDone([cmdIDPlay, cmdIDRec], MODE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case MODE_LABEL
        
        global SET_MODE;
        global CMD_MODE_PREFIX;
        
        % setting MODE_DUAL on both sides
        cmdStr = [SET_MODE ' ' CMD_MODE_PREFIX num2str(MODE_DUAL)];
        cmdIDPlay = writeCmd(cmdStr, cmdFilePlay);
        cmdIDRec = writeCmd(cmdStr, cmdFileRec);
        waitForCmdDone([cmdIDPlay, cmdIDRec], WAIT_FOR_LP_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case WAIT_FOR_LP_LABEL
        % after switching to LPF + mode we have to wait for the new distortions to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_LP_LABEL, mfilename());
        return;
        

      case CAL_LP_LABEL
        % calibrating LPF at origRecFreq
        printStr(sprintf("Joint-device calibrating/measuring LPF at %dHz", origRecFreq));
        % deleting the calib file should it exist - always clean calibration
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, ANALYSED_CH_ID, MODE_DUAL, EXTRA_CIRCUIT_LP1);
        deleteFile(calFile);
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, getTheOtherChannelID(ANALYSED_CH_ID), MODE_DUAL, EXTRA_CIRCUIT_LP1);
        deleteFile(calFile);
        
        % safety measure - requesting calibration only at curFreq
        calFreqReqStr = getCalFreqReqStr({[origRecFreq, NA, NA]});
        calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
        cmdIDRec = writeCmd(calCmd, cmdFileRec);
        % calibrating VD
        waitForCmdDone([cmdIDRec], SWITCH_TO_VD_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case SWITCH_TO_VD_LABEL
        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        % persistent variable, also used in next step CAL_VD_LABEL
        lpFundAmpl = loadCalFundAmpl(origRecFreq, fs, PLAY_CH_ID, ANALYSED_CH_ID, EXTRA_CIRCUIT_LP1);

        adapterStruct.out = false;
        adapterStruct.in = false; % CALIB
        adapterStruct.lpf = false; % VD
        adapterStruct.reqLevels = lpFundAmpl;
        % level needs to be set slightly more precisely than calibration request to account for possible tiny level drift before calibration
        adapterStruct.maxAmplDiff = MAX_AMPL_DIFF * 0.9;
        waitForAdapterAdjust(
          sprintf('Change switch to VD calibration. For first freq adjust captured level to %s for channel %d', getAdapterLevelRangeStr(adapterStruct), ANALYSED_CH_ID),
          adapterStruct, WAIT_FOR_VD_LABEL, ABORT, ERROR, mfilename());
        return;

      case WAIT_FOR_VD_LABEL
        % after switching LPF -> VD we have to wait for the new distortions to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_VD_LABEL, mfilename());
        return;
        
      case CAL_VD_LABEL
        % VD calibration        
        printStr("Joint-device calibrating VD at %dHz:", origRecFreq);
        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl, origRecFreq, ANALYSED_CH_ID, MAX_AMPL_DIFF, true);
        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        % much more time for manual level adjustment
        timeout = MANUAL_TIMEOUT;
        % zooming calibration levels + plotting the range so that user can adjust precisely                
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(lpFundAmpl, ANALYSED_CH_ID));
        % deleting the calib file should it exist - always clean calibration
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, ANALYSED_CH_ID, MODE_DUAL, EXTRA_CIRCUIT_VD);
        deleteFile(calFile);
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, getTheOtherChannelID(ANALYSED_CH_ID), MODE_DUAL, EXTRA_CIRCUIT_VD);
        deleteFile(calFile);

        calCmd = [CALIBRATE ' ' calFreqReqStr  ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_VD];
              
        cmdIDRec = writeCmd(calCmd, cmdFileRec);
        % long waiting - manual level adjustment
        waitForCmdDone(cmdIDRec, SPLIT_CAL_LABEL, MANUAL_TIMEOUT, ERROR, mfilename());
        return;

      case SPLIT_CAL_LABEL
        % range calibrations finished, closing the zoomed calib plot
        closeCalibPlot();
        printStr(sprintf('Calculating split calibration'));

        global recInfo;
        calculateSplitCal(origRecFreq, fs, PLAY_CH_ID, ANALYSED_CH_ID, MODE_DUAL, EXTRA_CIRCUIT_VD, EXTRA_CIRCUIT_LP1, recInfo.nonInteger);

        % going to the next label. This could be processed in one label, but separating split calibration from play-side compensation makes the code cleaner
        label = COMP_PLAY_LABEL;
        continue;
        

      case COMP_PLAY_LABEL
        printStr(sprintf('Compensating PLAY side'));
        cmdIDPlay = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_PLAY_SIDE)], cmdFilePlay);
        waitForCmdDone(cmdIDPlay, ALL_OFF_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case ABORT
        wasAborted= true;
        label = ALL_OFF_LABEL;
        continue;

      case ALL_OFF_LABEL
        cmdIDs = sendAllOffCmds();
        if ~isempty(cmdIDs)
          waitForCmdDone(cmdIDs, DONE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
          return;
        else
          label = DONE_LABEL;
          continue;
        endif

      case DONE_LABEL
        resetAdapterStruct();
        waitForAdapterAdjust('Set switches for measuring DUT', adapterStruct, FINISH_DONE_LABEL, FINISH_DONE_LABEL, ERROR, mfilename());
        return;

      case FINISH_DONE_LABEL
        if wasAborted
          result = false;
        else
          printStr('Split Calibration finished');  
          result = true;
        endif
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done, exiting splitting calibration of PLAY side';
        printStr(msg);
        writeLog('INFO', msg);
        errordlg(msg);
        result = false;
        break;        
    endswitch
  endwhile
  
  % just in case the task was aborted with calib plot zoomed in
  closeCalibPlot();
  removeTask(mfilename(), NAME);
  
endfunction