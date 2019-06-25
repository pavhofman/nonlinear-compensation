% scheduler-enabled function for measuring VD and LPF transfer via regular joint-sides calibration
% Only one-sine (one fundamental) is supported!!
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = measureTransferSched(label= 1, schedItem = [])
  result = NA;
  persistent NAME = 'Measuring LP & VD Transfer';
  
  % init section
  [START_LABEL, MODE_LABEL, WAIT_FOR_LP_LABEL, CAL_LP_LABEL, CAL_LP_FINISHED_LABEL, PREPARE_VD_LABEL, CAL_VD_LABEL, CAL_VD_FINISHED_LABEL, ALL_OFF_LABEL, DONE_LABEL, ERROR] = enum();
  
  persistent AUTO_TIMEOUT = 10;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;
  
  % right ch goes through LP or VD, left input channel is direct
  % fixed for now!
  persistent analysedChID = 2;
  % ID of output channel used for split calibration
  persistent playChID = 2;
  
  global EXTRA_CIRCUIT_VD;
  global EXTRA_CIRCUIT_LP1;
  global EXTRA_TRANSFER_DIR;
  
  global cmdFileRec;
  global cmdFilePlay;
  global GENERATE;
  global PASS;
  global CALIBRATE;
  global COMPENSATE;
  global CMD_EXTRA_CIRCUIT_PREFIX;
  global CMD_CHANNEL_FUND_PREFIX;
  global CMD_COMP_TYPE_PREFIX;
  global CMD_CALRUNS_PREFIX;
  global CMD_PLAY_AMPLS_PREFIX;
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;
  global COMP_TYPE_REC_SIDE;
  
  global MODE_DUAL;
  global ABORT;
  
  % current frequency of calibration
  % all set in first P1 branch
  persistent curFreq = NA;
  persistent freqs = NA;
  persistent freqID = 1;
  persistent fs = NA;
  persistent origFreq = NA;
  
  persistent calFile = '';
  
  % measured at fixed levels
  persistent PLAY_LEVELS = {0.9, 0.9};
  
  persistent swStruct = initSwitchStruct();
  persistent lpFundAmpl = NA;
  
  persistent didMeasureLPF = false;
  persistent wasAborted = false;
  
  while true
    switch(label)
    
      case START_LABEL
        
        global playInfo;
        global recInfo;

        addTask(mfilename(), NAME);
        % init value
        wasAborted = false;

        % loading current values from analysis
        fs = recInfo.fs;
        % TODO - checks - only one fundament freq!!
        origFreq = recInfo.measuredPeaks{analysedChID}(1, 1);
        
        % LPF measurement starts at last measured freq. We need values for fundamental freq in order to determine lpFundAmpl to align VD to same value
        freqs = getMissingTransferFreqs(origFreq, fs, EXTRA_CIRCUIT_LP1);
        freqID = 1;
        
        writeLog('DEBUG', 'Missing transfer freqs for %s: %s', EXTRA_CIRCUIT_LP1, disp(freqs));
        
        if isempty(freqs)
          % no need to measure LP, going to VD
          label = PREPARE_VD_LABEL;
          didMeasureLPF = false;
          continue;
        else
          didMeasureLPF = true;
        endif
        
        swStruct.calibrate = true;
        % for now calibrating right output channel only
        swStruct.inputR = (playChID == 2);
        swStruct.vd = false;
        swStruct.analysedR = (analysedChID == 2);
        
        figResult = showSwitchWindow(sprintf('Set switches for LPF measurement with output channel %d and input channel %d', playChID, analysedChID), swStruct);
        if ~figResult
          label = ABORT;
          continue;
        endif

        clearOutBox();
        printStr(sprintf("Joint-device calibrating LP at harmonic frequencies of %dHz:", origFreq));
        
        % setting pass status on both sides
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
        % Now switched to LPF + mode. We start the generator at first freq and wait for all the changes topropagate through the chain. 1 sec should be enough
        % The reason for waiting is if no freq change occured and it takes too long for the new PLAY_LEVELS amplitude to propagate, calibration will finish at the old levels of DUT, not of the measured transfer.
        if ~isempty(freqs)
          printStr(sprintf("Generating %dHz", freqs(1)));
          sendPlayGeneratorCmd(freqs(1), PLAY_LEVELS);
        endif

        schedPause(1, CAL_LP_LABEL, mfilename());
        return;
        
      case {CAL_LP_LABEL, CAL_LP_FINISHED_LABEL}
        % calibrating LPF connection at freq harmonics
        while freqID <= length(freqs)
          curFreq = freqs(freqID);
          switch label
            case CAL_LP_LABEL
              % we can resend the first freq generator command even if it was already sent at WAIT_FOR_LP_LABEL section. It's better to have the sections as independent as possible
              printStr(sprintf("Generating %dHz", curFreq));
              cmdIDPlay = sendPlayGeneratorCmd(curFreq, PLAY_LEVELS);

              printStr(sprintf("Joint-device calibrating/measuring LP at %dHz", curFreq));
              % deleting the calib file should it exist - always clean calibration
              calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_LP1);
              deleteFile(calFile);

              % safety measure - requesting calibration only at curFreq (no level known, unfortunately)
              calFreqReqStr = getCalFreqReqStr({[curFreq, NA, NA]});
              calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(PLAY_LEVELS, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
              cmdIDRec = writeCmd(calCmd, cmdFileRec);

              waitForCmdDone([cmdIDPlay, cmdIDRec], CAL_LP_FINISHED_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
              return;
              
            case CAL_LP_FINISHED_LABEL
              % moving calfile for analysedChID to transfer file
              moveCalToTransferFile(calFile, curFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_LP1);

              % removing the other channel calfile - useless
              otherCalFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, getTheOtherChannelID(analysedChID), MODE_DUAL, EXTRA_CIRCUIT_LP1, EXTRA_TRANSFER_DIR);
              deleteFile(otherCalFile);
              
              % next frequency
              ++freqID;
              
              label = CAL_LP_LABEL;
              continue;
            endswitch
              
        endwhile
        % returning back to orig freq
        sendPlayGeneratorCmd(origFreq, PLAY_LEVELS);
        % wait a bit for the change to propagate (to see the origFreq in capture analysis UI)
        schedPause(1, PREPARE_VD_LABEL, mfilename());
        return;

      case PREPARE_VD_LABEL      
        % VD calibration
        % loading freqs for VD
        freqs = getMissingTransferFreqs(origFreq, fs, EXTRA_CIRCUIT_VD);
        writeLog('DEBUG', 'Missing transfer freqs for %s: %s', EXTRA_CIRCUIT_VD, disp(freqs));
        freqID = 1;
        
        if isempty(freqs)
          % all transfers available for VD, ending
          if ~didMeasureLPF
            % informing user that all freqs are already measured
            global MAX_TRANSFER_AGE_DAYS;
            msgbox(['All LPF and VD frequencies already measured and still valid (< ' num2str(MAX_TRANSFER_AGE_DAYS) ' days)']);
          endif
          label = ALL_OFF_LABEL;
          continue;
        endif

        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        lpFundAmpl = loadAmplFromTransfer(origFreq, EXTRA_CIRCUIT_LP1);

        swStruct.vd = true;
        figResult = showSwitchWindow({'Change switch to VD calibration', sprintf('For first freq. adjust level into the shown range for channel ', analysedChID)}, swStruct);
        if ~figResult
          label = ABORT;
          continue;
        endif
        

        clearOutBox();
        printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", origFreq));

        % Now switched to VD + mode. We start the generator at first freq and wait for all the changes topropagate through the chain. 1 sec should be enough
        % The reason for waiting is if no freq change occured and it takes too long for the new PLAY_LEVELS amplitude to propagate, calibration will finish at the old levels of DUT, not of the measured transfer.
        if ~isempty(freqs)
          printStr(sprintf("Generating %dHz", freqs(1)));
          sendPlayGeneratorCmd(freqs(1), PLAY_LEVELS);
        endif

        % after switching to VD we have to wait for the new levels to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_VD_LABEL, mfilename());
        return;

      case {CAL_VD_LABEL, CAL_VD_FINISHED_LABEL}
        % calibrating LP connection at freq harmonics
        while freqID <= length(freqs)
          curFreq = freqs(freqID);
          switch label
            case CAL_VD_LABEL
              % we can resend the first freq generator command even if it was already sent at PREPARE_VD_LABEL section. It's better to have the sections as independent as possible
              printStr(sprintf("Generating %dHz", curFreq));
              cmdIDPlay = sendPlayGeneratorCmd(curFreq, PLAY_LEVELS);

              printStr(sprintf("Joint-device calibrating VD at %dHz", curFreq));
              if curFreq == origFreq
                % VD at fundament (origFreq) must be calibrated at exactly the same level as LP so that the distortion characteristics of ADC are same
                
                % amplitude-constrained calibration

                % max. allowed deviation in each direction from midAmpl
                % similar level of VD to LPF provides similar phaseshift of VD to when measured in splitCalibPlaySched. Here it is not so critical
                calTolerance = db2mag(0.08);

                calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl, origFreq, analysedChID, calTolerance, true);
                calFreqReqStr = getCalFreqReqStr(calFreqReq);
                % much more time for manual level adjustment
                timeout = MANUAL_TIMEOUT;
                % zooming calibration levels + plotting the range so that user can adjust precisely                
                zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(lpFundAmpl, analysedChID));
              else
                % harmonic freqs, level is not important, only waiting from stable frequency
                calFreqReqStr = getCalFreqReqStr({[curFreq, NA, NA]});
                % regular (= short) timeout
                timeout = AUTO_TIMEOUT;
                closeCalibPlot();
              endif
              % deleting the calib file should it exist - always clean calibration
              calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_VD);
              deleteFile(calFile);

              calCmd = [CALIBRATE ' ' calFreqReqStr  ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(PLAY_LEVELS, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_VD];
              cmdIDRec = writeCmd(calCmd, cmdFileRec);

              waitForCmdDone([cmdIDPlay, cmdIDRec], CAL_VD_FINISHED_LABEL, timeout, ERROR, mfilename());
              return;
              
            case CAL_VD_FINISHED_LABEL
              % moving calFile to transfers
              moveCalToTransferFile(calFile, curFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_VD);

              % removing useless calfile for the other channel
              otherCalFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, getTheOtherChannelID(analysedChID), MODE_DUAL, EXTRA_CIRCUIT_VD);
              deleteFile(otherCalFile);
              
              % next frequency
              ++freqID;
              label = CAL_VD_LABEL;
              continue;
          endswitch
          
        endwhile
        label = ALL_OFF_LABEL;
        % goto label - next loop
        continue;

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
        if ~isempty(getRunTaskItemIDFor(mfilename()))
          % called from waitForFunction scheduler - not showing the final switchWindow
        else
          swStruct.calibrate = false;
          showSwitchWindow('Set switches for measuring DUT', swStruct);
        endif
        if wasAborted
          msg = 'Measuring transfer was aborted';
          result = false;
        else
          msg = 'Measuring transfer finished';
          result = true;
        endif
        
        printStr(msg);
        writeLog('INFO', msg);
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done, exiting measuring transfer';
        printStr(msg);
        writeLog('INFO', msg);
        % displaying message box
        errordlg(msg);
        % failed
        result = false;
        break;
        
    endswitch
  endwhile

  removeTask(mfilename(), NAME);
endfunction

function moveCalToTransferFile(calFile, freq, fs, playChID, analysedChID, extraCircuit)
  [peaksRow, distortFreqs] = loadCalRow(calFile);
  transfRec = struct();
  transfRec.timestamp = peaksRow(1);
  transfRec.freq = freq;
  
  transfRec.peaksRow = peaksRow;
  
  % while these values are not important for transfer, it is good to keep them
  transfRec.fs = fs;
  transfRec.playChID = playChID;
  transfRec.analysedChID = analysedChID;
  
  transferFile = getTransferFilename(freq, extraCircuit);
  writeLog('DEBUG', 'Exporting calFile %s to transfer file %s', calFile, transferFile);
  save(transferFile, 'transfRec');
  
  % deleting the calFile - useless now
  delete(calFile);
endfunction

function ampl = loadAmplFromTransfer(freq, extraCircuit)
  global AMPL_IDX;
  
  transferFilename = getTransferFilename(freq, extraCircuit);
  load(transferFilename);
  % loading transfRec variable

  peaksRow = transfRec.peaksRow;
  ampl = peaksRow(1, AMPL_IDX);
endfunction