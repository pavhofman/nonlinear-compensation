% scheduler-enabled function for measuring VD and LPF transfer via regular joint-sides calibration
% Only one-sine (one fundamental) is supported!!
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = measureTransferSched(label= 1, schedTask = [])
  result = NA;
  persistent NAME = 'Measuring LPF & VD Transfer';
  
  % init section
  [START_LABEL, PASS_LABEL, WAIT_FOR_LP_LABEL, CAL_LP_LABEL, CAL_LP_FINISHED_LABEL, GEN_ORIG_F, SWITCH_TO_VD_LABEL,...
    GEN_LABEL, CAL_VD_LABEL, CAL_VD_FINISHED_LABEL, ALL_OFF_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
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
  global ABORT;

  global chMode;
  
  % current frequency of calibration
  % all set in first P1 branch
  persistent playFreqs = NA;
  persistent recFreqs = NA;
  persistent freqID = 1;
  persistent fs = NA;
  persistent origPlayFreq = NA;
  persistent origRecFreq = NA;

  persistent calFile = '';
  
  % fixed levels if no current PLAY level is known
  persistent DEFAULT_PLAY_LEVELS = {0.9, 0.9};
  % initialized in START_LABEL
  persistent playLevels;

  % max. allowed deviation in each direction from midAmpl
  % similar level of VD to LPF provides similar phaseshift of VD to when measured in splitCalibPlaySched. Here it is not so critical
  persistent MAX_AMPL_DIFF = db2mag(-80);

  % transfer measurement requires more averages to increase precision since it will not be performed often
  persistent TRANSF_CAL_RUNS = 30;

  global adapterStruct;

  persistent lpFundAmpl = NA;
  persistent wasAborted = false;
  
  while true
    switch(label)
    
      case START_LABEL
        
        global playInfo;
        global recInfo;

        clearOutBox();

        addTask(mfilename(), NAME);
        % init value
        wasAborted = false;

        % loading current values from analysis
        fs = recInfo.fs;

        % TODO - checks - only one fundament freq!!
        % if playback freq is known, use it (playback will be generating). If no (playback has no signal, rec fed by an external generator, use recInfo)
        if length(playInfo.measuredPeaks) >= PLAY_CH_ID && ~ isempty(playInfo.measuredPeaks{PLAY_CH_ID})
          origPlayFreq = playInfo.measuredPeaks{PLAY_CH_ID}(1, 1);
          % generated levels equal to current play level
          origPlayLevel = playInfo.measuredPeaks{PLAY_CH_ID}(1, 2);
          playLevels = {origPlayLevel, origPlayLevel};
        else
          origPlayFreq = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 1);
          playLevels = DEFAULT_PLAY_LEVELS;
        end
        
        origRecFreq = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 1);
        
        % LPF measurement starts at last measured freq. We need values for fundamental freq in order to determine lpFundAmpl to align VD to same value
        [playFreqs, recFreqs] = getMissingTransferFreqs(origPlayFreq, origRecFreq, fs, EXTRA_CIRCUIT_LP1, recInfo.nonInteger);
        freqID = 1;
        
        writeLog('DEBUG', 'Missing transfer recFreqs for %s: %s', EXTRA_CIRCUIT_LP1, disp(recFreqs));
        
        if isempty(recFreqs)
          % no need to measure LPF
          % checking VD freqs
          [playVDFreqs, recVDFreqs] = getMissingTransferFreqs(origPlayFreq, origRecFreq, fs, EXTRA_CIRCUIT_VD, recInfo.nonInteger);
          if  isempty(recVDFreqs)
            % all transfers available for VD too, ending
            % informing user that all recFreqs are already measured
            msg = sprintf('All LPF and VD frequencies already measured and still valid');
            writeLog('INFO', msg);
            printStr(msg);
            break;
          end

          % going to VD, but starting generating orig freq (f0) first to let stepper adjust to correct level
          label = GEN_ORIG_F;
          continue;
        end % empty LPF recFreqs
        
        % for restoration at the end
        keepInOutSwitches();
        % OUT must be off because the task will generate auxiliary signals
        % adapterStruct.out = false; % OUT off
        adapterStruct.in = false; % CALIB IN
        adapterStruct.vdLpf = true; % LPF
        adapterStruct.reqVDLevel = []; % no stepper adjustment
        adapterStruct.maxAmplDiff = [];
        waitForAdapterAdjust(sprintf('Set switches for LPF measurement with output channel %d and input channel %d', PLAY_CH_ID, ANALYSED_CH_ID),
          adapterStruct, PASS_LABEL, ABORT, ERROR, mfilename());
        return;

      case PASS_LABEL
        % setting pass status on both sides
        cmdIDPlay = writeCmd(PASS, cmdFilePlay);
        cmdIDRec = writeCmd(PASS, cmdFileRec);
        % we have to wait for command acceptance before issuing new commands (the cmd files could be deleted by new commands before they are consumed
        % waiting only for one of the pass commands, both sides run at same speed
        % after AUTO_TIMEOUT secs timeout call ERROR
        waitForCmdDone([cmdIDPlay, cmdIDRec], WAIT_FOR_LP_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case WAIT_FOR_LP_LABEL
        % Now switched to LPF + mode. We start the generator at first freq and wait for all the changes topropagate through the chain. 1 sec should be enough
        % The reason for waiting is if no freq change occured and it takes too long for the new playLevels amplitude to propagate, calibration will finish at the old levels of DUT, not of the measured transfer.
        if ~isempty(recFreqs)
          printStr(sprintf("Generating %dHz", recFreqs(1)));
          sendPlayGeneratorCmd(recFreqs(1), playLevels);
        end

        schedPause(1, CAL_LP_LABEL, mfilename());
        return;
        
      case {CAL_LP_LABEL, CAL_LP_FINISHED_LABEL}
        % calibrating LPF path at freq harmonics
        while freqID <= length(playFreqs)
          switch label
            case CAL_LP_LABEL
              % we can resend the first freq generator command even if it was already sent at WAIT_FOR_LP_LABEL section. It's better to have the sections as independent as possible
              printStr(sprintf("Generating %dHz", playFreqs(freqID)));
              cmdIDPlay = sendPlayGeneratorCmd(playFreqs(freqID), playLevels);

              printStr(sprintf("Joint-device calibrating/measuring LPF at %dHz", recFreqs(freqID)));
              % deleting the calib file should it exist - always clean calibration
              global recInfo;
              calFile = genCalFilename(recFreqs(freqID), fs, COMP_TYPE_JOINT, PLAY_CH_ID, ANALYSED_CH_ID,
                recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_LP1);
              deleteFile(calFile);

              % safety measure - requesting calibration only at current rec freq
              calFreqReqStr = getCalFreqReqStr({[recFreqs(freqID), NA, NA]});
              calCmd = sprintf("%s %s %s%d %s %s%s %s%d", CALIBRATE, calFreqReqStr, CMD_COMP_TYPE_PREFIX, COMP_TYPE_JOINT,
                getMatrixCellsToCmdStr(playLevels, CMD_PLAY_AMPLS_PREFIX), CMD_EXTRA_CIRCUIT_PREFIX, EXTRA_CIRCUIT_LP1, CMD_CALRUNS_PREFIX, TRANSF_CAL_RUNS);
              cmdIDRec = writeCmd(calCmd, cmdFileRec);

              waitForCmdDone([cmdIDPlay, cmdIDRec], CAL_LP_FINISHED_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
              return;
              
            case CAL_LP_FINISHED_LABEL
              % moving calfile for ANALYSED_CH_ID to transfer file
              moveCalToTransferFile(calFile, recFreqs(freqID), fs, PLAY_CH_ID, ANALYSED_CH_ID, EXTRA_CIRCUIT_LP1);

              % removing the other channel calfile - useless
              global recInfo;
              otherCalFile = genCalFilename(recFreqs(freqID), fs, COMP_TYPE_JOINT, PLAY_CH_ID, getTheOtherChannelID(ANALYSED_CH_ID),
                recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_LP1);
              deleteFile(otherCalFile);
              
              % next frequency
              ++freqID;
              
              label = CAL_LP_LABEL;
              continue;
            end
        end % LPF freqs
        label = GEN_ORIG_F;
        continue;
                
      case GEN_ORIG_F
        % returning back to orig freq
        sendPlayGeneratorCmd(origPlayFreq, playLevels);
        % wait a bit for the change to propagate (to see the origPlayFreq in capture analysis UI)
        schedPause(1, SWITCH_TO_VD_LABEL, mfilename());
        return;

      case SWITCH_TO_VD_LABEL
        % VD calibration
        % loading recFreqs for VD
        global recInfo;
        [playFreqs, recFreqs] = getMissingTransferFreqs(origPlayFreq, origRecFreq, fs, EXTRA_CIRCUIT_VD, recInfo.nonInteger);
        writeLog('DEBUG', 'Missing transfer recFreqs for %s: %s', EXTRA_CIRCUIT_VD, disp(recFreqs));
        freqID = 1;
        
        if isempty(playFreqs)
          label = ALL_OFF_LABEL;
          continue;
        end

        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        lpFundAmpl = loadRecAmplFromTransfer(origRecFreq, EXTRA_CIRCUIT_LP1);

        % adapterStruct.out = false;
        adapterStruct.in = false; % CALIB
        adapterStruct.vdLpf = false; % VD
        % LPF + transfer measurement - VD for splitting
        adapterStruct.vd = adapterStruct.vdForSplitting;
        adapterStruct.reqVDLevel = lpFundAmpl;
        % level needs to be set slightly more precisely than calibration request to account for possible tiny level drift before calibration
        adapterStruct.maxAmplDiff = MAX_AMPL_DIFF * 0.9;
        waitForAdapterAdjust(
          sprintf('Change switch to VD calibration. Adjust captured level to %s for channel %d', getAdapterLevelRangeStr(adapterStruct), ANALYSED_CH_ID),
          adapterStruct, GEN_LABEL, ABORT, ERROR, mfilename());
        return;

      case GEN_LABEL
        printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", recFreqs(freqID)));

        % Now switched to VD + mode. We start the generator at first freq and wait for all the changes to propagate through the chain. 1 sec should be enough
        % The reason for waiting is if no freq change occured and it takes too long for the new playLevels amplitude to propagate, calibration will finish at the old levels of DUT, not of the measured transfer.
        if ~isempty(playFreqs)
          printStr(sprintf("Generating %dHz", playFreqs(1)));
          sendPlayGeneratorCmd(playFreqs(1), playLevels);
        end

        % after switching to VD we have to wait for the new levels to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_VD_LABEL, mfilename());
        return;

      case {CAL_VD_LABEL, CAL_VD_FINISHED_LABEL}
        % calibrating VD path at freq harmonics
        while freqID <= length(playFreqs)
          switch label
            case CAL_VD_LABEL
              % we can resend the first freq generator command even if it was already sent at SWITCH_TO_VD_LABEL section. It's better to have the sections as independent as possible
              printStr(sprintf("Generating %dHz", playFreqs(freqID)));
              cmdIDPlay = sendPlayGeneratorCmd(playFreqs(freqID), playLevels);

              printStr(sprintf("Joint-device calibrating VD at %dHz", recFreqs(freqID)));
              if recFreqs(freqID) == origRecFreq
                % VD at fundament (origFreq) should be calibrated close to the LPF level
                % amplitude-constrained calibration
                calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl, origRecFreq, ANALYSED_CH_ID, MAX_AMPL_DIFF, true);
                calFreqReqStr = getCalFreqReqStr(calFreqReq);
                % much more time for manual level adjustment
                timeout = MANUAL_TIMEOUT;
                % zooming calibration levels + plotting the range so that user can adjust precisely                
                zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(lpFundAmpl, ANALYSED_CH_ID));
              else
                % harmonic recFreqs, level is not important, only waiting from stable frequency
                calFreqReqStr = getCalFreqReqStr({[recFreqs(freqID), NA, NA]});
                % regular (= short) timeout
                timeout = AUTO_TIMEOUT;
                closeCalibPlot();
              end
              % deleting the calib file should it exist - always clean calibration
              global recInfo;
              calFile = genCalFilename(recFreqs(freqID), fs, COMP_TYPE_JOINT, PLAY_CH_ID, ANALYSED_CH_ID,
                recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_VD);
              deleteFile(calFile);

              calCmd = sprintf("%s %s %s%d %s %s%s %s%d", CALIBRATE, calFreqReqStr, CMD_COMP_TYPE_PREFIX, COMP_TYPE_JOINT,
                getMatrixCellsToCmdStr(playLevels, CMD_PLAY_AMPLS_PREFIX), CMD_EXTRA_CIRCUIT_PREFIX, EXTRA_CIRCUIT_VD, CMD_CALRUNS_PREFIX, TRANSF_CAL_RUNS);

              cmdIDRec = writeCmd(calCmd, cmdFileRec);

              waitForCmdDone([cmdIDPlay, cmdIDRec], CAL_VD_FINISHED_LABEL, timeout, ERROR, mfilename());
              return;
              
            case CAL_VD_FINISHED_LABEL
              % moving calFile to transfers
              moveCalToTransferFile(calFile, recFreqs(freqID), fs, PLAY_CH_ID, ANALYSED_CH_ID, EXTRA_CIRCUIT_VD);

              % removing useless calfile for the other channel
              global recInfo;
              otherCalFile = genCalFilename(recFreqs(freqID), fs, COMP_TYPE_JOINT, PLAY_CH_ID, getTheOtherChannelID(ANALYSED_CH_ID),
                recInfo.playCalDevName, recInfo.recCalDevName, chMode, EXTRA_CIRCUIT_VD);
              deleteFile(otherCalFile);
              
              % next frequency
              ++freqID;
              label = CAL_VD_LABEL;
              continue;
          end
          
        end
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
        end

      case DONE_LABEL
        if ~isempty(getRunTaskIDFor(mfilename()))
          % called from waitForFunction scheduler (i.e. from split-calibration task) - not showing the final switchWindow
          label = FINISH_DONE_LABEL;
          continue;
        else
          % plus restoring IN/OUT switches
          resetAdapterStruct();
          waitForAdapterAdjust('Restore switches', adapterStruct, FINISH_DONE_LABEL, FINISH_DONE_LABEL, ERROR, mfilename());
          return;
        end

      case FINISH_DONE_LABEL
        % clearing the label
        adapterStruct.label = '';
        updateAdapterPanel();
        if wasAborted
          msg = 'Measuring transfer was aborted';
          result = false;
        else
          msg = 'Measuring transfer finished';
          result = true;
        end
        
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
        
    end
  end

  removeTask(mfilename(), NAME);
end

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
  deleteFile(calFile);
end

function ampl = loadRecAmplFromTransfer(freq, extraCircuit)
  global AMPL_IDX;
  
  transferFilename = getTransferFilename(freq, extraCircuit);
  load(transferFilename);
  % loading transfRec variable

  peaksRow = transfRec.peaksRow;
  ampl = peaksRow(1, AMPL_IDX);
end