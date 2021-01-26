% scheduler-enabled function for split calibration of PLAY side
% Only one-sine (one fundamental) is supported!!
% calibrating at current freq. If some pre-measured VD and LPF transfer is missing, runs measureTransferSched task
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = splitCalibPlaySched(label = 1)
  result = NA;
  % init section
  [CHECKING_LABEL, START_LABEL, SWITCH_TO_LPF_LABEL, WAIT_FOR_LP_LABEL, CAL_LP_LABEL, MEASURE_LEVELS, SWITCH_TO_VD_LABEL, ADJUST_VD_SE, ...
      ADJUST_VD_BAL, WAIT_FOR_VD_LABEL, CAL_VD_LABEL, SPLIT_CAL_LABEL, COMP_PLAY_LABEL, ...
      CHECK_LOOPING, ALL_OFF_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Split-Calibrating PLAY Side';

  persistent AUTO_TIMEOUT = 20;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;

  % delay between split-calib runs in looping mode
  persistent LOOPING_DELAY = 3;

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

  global ABORT;

  global chMode;
  
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
        end
        
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
          end
          origPlayLevels{end + 1} = levelCh;
        end
        
        % playLevels are measured BEHIND equalizer in play process. When generating, one must take the equalizer into account to reach identical play levels
        % only values for first two channels to fit origPlayLevels
        playEqualizer = playInfo.equalizer(1:2);
        
        % checking if all transfer files are available

        % setting maxTransferAge for getMissingTransferFreqs (UGLY!) - not zero, but const MAX_TRANSFER_AGE
        global maxTransferAge;
        global MAX_TRANSFER_AGE;
        maxTransferAge = MAX_TRANSFER_AGE;

        [freqs1, freqs1] = getMissingTransferFreqs(origPlayFreq, origRecFreq, fs, EXTRA_CIRCUIT_LP1, recInfo.nonInteger);
        [freqs2, freqs2] = getMissingTransferFreqs(origPlayFreq, origRecFreq, fs, EXTRA_CIRCUIT_VD, recInfo.nonInteger);
        if ~isempty(freqs1) || ~isempty(freqs2)
          % some are missing, ask for measuring transfer. failed label = ABORT
          waitForTaskFinish('measureTransferSched', START_LABEL, ABORT, mfilename());
          return;
        else
          label = START_LABEL;
          % continue;
        end
        
      case START_LABEL
        clearOutBox();
        % for restoration at the end
        keepInOutSwitches();
        label = SWITCH_TO_LPF_LABEL;
        % continue;

      case SWITCH_TO_LPF_LABEL
        % OUT unchanged
        adapterStruct.in = false; % CALIB IN
        adapterStruct.vdLpf = true; % LPF
        adapterStruct.reqVDLevel = []; % no stepper adjustment
        adapterStruct.reqBalVDLevels = [];
        adapterStruct.maxAmplDiff = [];
        waitForAdapterAdjust(sprintf('Set switches for CH%d LPF calibration', ANALYSED_CH_ID), adapterStruct, WAIT_FOR_LP_LABEL, ABORT, ERROR, mfilename());
        return;

      case WAIT_FOR_LP_LABEL
        % after switching to LPF + mode we have to wait for the new distortions to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_LP_LABEL, mfilename());
        return;
        

      case CAL_LP_LABEL
        % calibrating LPF at origRecFreq
        printStr(sprintf("Joint-device calibrating/measuring LPF at %dHz", origRecFreq));
        % deleting the calib file should it exist - always clean calibration
        global recInfo;
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, ANALYSED_CH_ID,
          recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_LP1);
        deleteFile(calFile);
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, getTheOtherChannelID(ANALYSED_CH_ID),
          recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_LP1);
        deleteFile(calFile);
        
        % safety measure - requesting calibration only at curFreq
        calFreqReqStr = getCalFreqReqStr({[origRecFreq, NA, NA]});
        calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
        cmdIDRec = writeCmd(calCmd, cmdFileRec);
        % calibrating VD
        waitForCmdDone([cmdIDRec], MEASURE_LEVELS, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case MEASURE_LEVELS
        global recInfo;
        lpFundAmpl = loadCalFundAmpl(origRecFreq, fs, PLAY_CH_ID, ANALYSED_CH_ID, recInfo.playCalDevName, recInfo.recCalDevName, EXTRA_CIRCUIT_LP1);
        if adapterStruct.isSE
          % SE mode - VD must be set to measured amplitude, that is already stored in lpFundAmpl
          label = SWITCH_TO_VD_LABEL;
          % continue
        else
          % balanced mode requires measuring +/- level at first frequency to adjust VD
          % measureBalLevelsSched stores the measured results to adapterStruct.curBalLevels
          % (same format as adapterStruct.reqBalVDLevels)
          waitForTaskFinish('measureBalLevelsSched', SWITCH_TO_VD_LABEL, ABORT, mfilename());
          return;
        end

      case SWITCH_TO_VD_LABEL
        % level needs to be set slightly more precisely than calibration request to account for possible tiny level drift before calibration
        adapterStruct.maxAmplDiff = MAX_AMPL_DIFF * 0.5;

        adapterStruct.in = false; % CALIB
        adapterStruct.vdLpf = false; % VD
        % relays are set in ADJUST_VD_XXX steps
        if adapterStruct.isSE
          label = ADJUST_VD_SE;
        else
          label = ADJUST_VD_BAL;
        end
        % continue

      case ADJUST_VD_SE
        % LPF + transfer measurement use VD = vdForSplitting
        adapterStruct.vd = adapterStruct.vdForSplitting;
        adapterStruct.reqVDLevel = lpFundAmpl;
        waitForAdapterAdjust(
          sprintf('Change switch to VD calibration. For first freq adjust captured level to %s for channel %d', getAdapterLevelRangeStr(adapterStruct), ANALYSED_CH_ID),
          adapterStruct, WAIT_FOR_VD_LABEL, ABORT, ERROR, mfilename());
        return;

      case ADJUST_VD_BAL
        % curBalLevels set by measureBalLevelsSched
        adapterStruct.reqBalVDLevels = adapterStruct.curBalLevels;
        waitForTaskFinish('setBalVDLevelsSched', WAIT_FOR_VD_LABEL, ABORT, mfilename());
        return;

      case WAIT_FOR_VD_LABEL
        % TODO - really required?
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
        global recInfo;
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, ANALYSED_CH_ID,
          recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_VD);
        deleteFile(calFile);
        calFile = genCalFilename(origRecFreq, fs, COMP_TYPE_JOINT, PLAY_CH_ID, getTheOtherChannelID(ANALYSED_CH_ID),
          recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_VD);
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
        global playInfo;
        % split-calibration supports incremental mode on playback side
        playDistortPeaksCh = playInfo.distortPeaks{PLAY_CH_ID};
        calculateSplitCal(origRecFreq, fs, PLAY_CH_ID, ANALYSED_CH_ID, chMode, EXTRA_CIRCUIT_VD, EXTRA_CIRCUIT_LP1, recInfo.nonInteger, playDistortPeaksCh);

        % going to the next label. This could be processed in one label, but separating split calibration from play-side compensation makes the code cleaner
        label = COMP_PLAY_LABEL;
        % continue;

      case COMP_PLAY_LABEL
        printStr(sprintf('Compensating PLAY side'));
        cmdIDPlay = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_PLAY_SIDE)], cmdFilePlay);
        waitForCmdDone(cmdIDPlay, CHECK_LOOPING, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case CHECK_LOOPING
        global loopSplitCalib;
        if loopSplitCalib
          % waiting and repeating
          schedPause(LOOPING_DELAY, SWITCH_TO_LPF_LABEL, mfilename());
          return;
        else
          % done
          label = DONE_LABEL;
          % continue;
        end

      case ABORT
        wasAborted= true;
        label = ALL_OFF_LABEL;
        % continue;

      case ALL_OFF_LABEL
        cmdIDs = sendAllOffCmds();
        if ~isempty(cmdIDs)
          waitForCmdDone(cmdIDs, DONE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
          return;
        else
          label = DONE_LABEL;
          % continue;
        end

      case DONE_LABEL
        % plus restoring IN/OUT switches
        resetAdapterStruct();
        waitForAdapterAdjust('Restore switches', adapterStruct, FINISH_DONE_LABEL, FINISH_DONE_LABEL, ERROR, mfilename());
        return;

      case FINISH_DONE_LABEL
        % clearing the label
        adapterStruct.label = '';
        updateAdapterPanel();

        if wasAborted
          result = false;
        else
          printStr('Split Calibration finished');  
          result = true;
        end
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done, exiting splitting calibration of PLAY side';
        printStr(msg);
        writeLog('INFO', msg);
        errordlg(msg);
        result = false;
        break;        
    end
  end
  
  % just in case the task was aborted with calib plot zoomed in
  closeCalibPlot();
  removeTask(mfilename(), NAME);
  
end