% scheduler-enabled function for measuring VD and LPF transfer via regular joint-sides calibration
% Only one-sine (one fundamental) is supported!!
function result = measureTransferSched(label = 1, schedItem = [])
  result = NA;
  persistent NAME = 'Measuring LP & VD Transfer';
  
  % init section
  [PASSING_LABEL, MODE_LABEL, WAIT_FOR_LP_LABEL, CAL_LP_LABEL, CAL_LP_FINISHED_LABEL, CAL_VD_LABEL, CAL_VD_FINISHED_LABEL, GEN_OFF_LABEL, DONE_LABEL, ERROR] = enum();
  
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
  
  % current frequency of calibration
  % all set in first P1 branch
  persistent curFreq = NA;
  persistent fs = NA;
  persistent origFreq = NA;
  
  % measured at fixed levels
  persistent PLAY_LEVELS = {0.9, 0.9};
  
  persistent swStruct = initSwitchStruct();
  persistent lpFundAmpl = NA;
  
  while true
    switch(label)
    
      case PASSING_LABEL
        
        global playInfo;
        global recInfo;

        addTaskName(NAME);

        % loading current values from analysis
        fs = recInfo.fs;
        % TODO - checks - only one fundament freq!!
        origFreq = recInfo.measuredPeaks{analysedChID}(1, 1);
        

        % LPF measurement starts at last measured freq. We need values for fundamental freq in order to determine lpFundAmpl to align VD to same value
        curFreq = origFreq;
        
        swStruct.calibrate = true;
        % for now calibrating right output channel only
        swStruct.inputR = (playChID == 2);
        swStruct.vd = false;
        swStruct.analysedR = (analysedChID == 2);
        
        figResult = showSwitchWindow(sprintf('Set switches for LP calibration/measurement of input channel ', analysedChID), swStruct);
        if ~figResult
          label = ERROR;
          continue;
        endif

        clearOutBox();
        printStr(sprintf("Joint-device calibrating LP at all harmonic frequencies of %dHz:", origFreq));
        
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
        % after switching to LPF + mode we have to wait for the new distortions to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_LP_LABEL, mfilename());
        return;
        
      case {CAL_LP_LABEL, CAL_LP_FINISHED_LABEL}
        % calibrating LPF connection at freq harmonics
        while curFreq < fs/2
          switch label
            case CAL_LP_LABEL
              printStr(sprintf("Generating %dHz", curFreq));
              cmdIDPlay = sendPlayGeneratorCmd(curFreq, PLAY_LEVELS);

              printStr(sprintf("Joint-device calibrating/measuring LP at %dHz", curFreq));
              % deleting the calib file should it exist - always clean calibration
              calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_LP1);
              deleteFile(calFile);

              % safety measure - requesting calibration only at curFreq
              calFreqReqStr = getCalFreqReqStr({[curFreq, NA, NA]});
              calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(PLAY_LEVELS, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
              cmdIDRec = writeCmd(calCmd, cmdFileRec);

              waitForCmdDone([cmdIDPlay, cmdIDRec], CAL_LP_FINISHED_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
              return;
              
            case CAL_LP_FINISHED_LABEL
              % moving calfile for analysedChID to transfer file
              moveCalToTransferFile(calFile, curFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_LP1);

              % removing the other channel calfile - useless
              calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, getTheOtherChannelID(analysedChID), MODE_DUAL, EXTRA_CIRCUIT_LP1, EXTRA_TRANSFER_DIR);
              deleteFile(calFile);
              
              % next frequency
              curFreq += origFreq;
              
              label = CAL_LP_LABEL;
              continue;
            endswitch
              
        endwhile
        % VD calibration
        swStruct.vd = true;
        figResult = showSwitchWindow({'Change switch to VD calibration', sprintf('For first freq. adjust level into the shown range for channel ', analysedChID)}, swStruct);
        if ~figResult
          label = ERROR;
          continue;
        endif
        
        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        lpFundAmpl = loadCalFundAmpl(origFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_LP1);

        % resetting curFreq to fundament
        curFreq = origFreq;
        clearOutBox();
        printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", origFreq));

        % after switching to VD we have to wait for the new distortions to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_VD_LABEL, mfilename());
        return;
        

      case {CAL_VD_LABEL, CAL_VD_FINISHED_LABEL}
        % calibrating LP connection at freq harmonics
        while curFreq < fs/2
          switch label
            case CAL_VD_LABEL
              printStr(sprintf("Generating %dHz", curFreq));
              cmdIDPlay = sendPlayGeneratorCmd(curFreq, PLAY_LEVELS);

              printStr(sprintf("Joint-device calibrating VD at %dHz", curFreq));
              if curFreq == origFreq
                % VD at fundament (origFreq) must be calibrated at exactly the same level as LP so that the distortion characteristics of ADC are same
                
                % amplitude-constrained calibration

                % max. allowed deviation in each direction from midAmpl
                % similar level of VD to LPF provides similar phaseshift of VD to when measured in splitCalibrateSched. Here it is not so critical
                calTolerance = db2mag(0.08);

                calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl, origFreq, analysedChID, calTolerance);
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
              calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, getTheOtherChannelID(analysedChID), MODE_DUAL, EXTRA_CIRCUIT_VD);
              deleteFile(calFile);
              
              % next frequency
              curFreq += origFreq;
              label = CAL_VD_LABEL;
              continue;
          endswitch
          
        endwhile
        label = GEN_OFF_LABEL;
        % goto label - next loop
        continue;

      case GEN_OFF_LABEL
        cmdID = sendStopGeneratorCmd();
        waitForCmdDone(cmdID, DONE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case DONE_LABEL
        if ~isempty(getRunTaskItemIDFor(mfilename()))
          % called from waitForFunction scheduler - not showing the final switchWindow
        else
          swStruct.calibrate = false;
          showSwitchWindow('Set switches for measuring DUT', swStruct');
        endif
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done or function aborted, exiting measuring transfer';
        printStr(msg);
        writeLog('INFO', msg);
        sendStopGeneratorCmd();
        % failed
        result = false;
        removeTaskName(NAME);
        return;
    endswitch
  endwhile
  msg = 'Measuring transfer finished';
  printStr(msg);
  writeLog('INFO', msg);
  % finished OK
  result = true;
  removeTaskName(NAME);
endfunction

function moveCalToTransferFile(calFile, freq, fs, playChID, analysedChID, extraCircuit)
  [peaksRow, distortFreqs] = loadCalRow(calFile);
  transfRec = struct();
  transfRec.timestamp = peaksRow(0);
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