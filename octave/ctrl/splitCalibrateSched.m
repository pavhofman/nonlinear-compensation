% scheduler-enabled function for complete split calibration
% Only one-sine (one fundamental) is supported!!
function splitCalibrateSched(label = 1)
  % init section
  [P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, ERROR] = enum();
  
  persistent AUTO_TIMEOUT = 5;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;
  
  % number of averaging calibration runs for calibrations yielding only fundamentals for transfer measuring
  % keeping same as regular full count for now
  persistent REDUCED_CALIB_RUNS = 10;
  
  % step above and below exact calibration level to also calibrate for interpolation
  persistent CAL_LEVEL_STEP = db2mag(0.05);
  
  % right ch goes through LP or VD, left input channel is direct
  % fixed for now!
  persistent analysedChID = 2;
  % ID of output channel used for split calibration
  persistent playChID = 2;
  
  persistent EXTRA_CIRCUIT_VD = 'vd';
  persistent EXTRA_CIRCUIT_LP1 = 'lp1';  
  
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
  
  persistent lpFundAmpl = NA;
  
  % current frequency of calibration
  % all set in first P1 branch
  persistent curFreq = NA;
  persistent fs = NA;
  persistent origFreq = NA;
  persistent origRecLevel = NA;
  persistent origPlayLevels = NA;
  
  persistent swStruct = initSwitchStruct();

  while true
    switch(label)
    
      case P1
        
        global playInfo;
        global recInfo;

        % loading current values from analysis
        fs = recInfo.fs;
        % TODO - checks - only one fundament freq!!
        origFreq = recInfo.measuredPeaks{analysedChID}(1, 1);
        origRecLevel = recInfo.measuredPeaks{analysedChID}(:, 2);
        % two channels, only first fundament freqs (the only freq!)
        origPlayLevels = {playInfo.measuredPeaks{1}(1, 2), playInfo.measuredPeaks{2}(1, 2)};
        
        % playLevels are measure BEHIND equalizer in play process. When generating, one must take the equalizer into account to reach identical play levels
        % only values for first two channels to fit origPlayLevels
        playEqualizer = playInfo.equalizer(1:2);

        % starting with origFreq
        curFreq = origFreq;
        
        swStruct.calibrate = true;
        % for now calibrating right output channel only
        swStruct.inputR = (playChID == 2);
        swStruct.vd = false;
        swStruct.analysedR = (analysedChID == 2);
        showSwitchWindow(sprintf('Set switches for LP calibration/measurement of input channel ', analysedChID), swStruct);

        clearOutBox();
        printStr(sprintf("Joint-device calibrating LP at all harmonic frequencies of %dHz:", curFreq));
        writeCmd(PASS, cmdFilePlay);
        cmdID = writeCmd(PASS, cmdFileRec);
        % we have to wait for command acceptance before issuing new commands (the cmd files could be deleted by new commands before they are consumed
        % waiting only for one of the pass commands, both sides run at same speed
        % after AUTO_TIMEOUT secs timeout call ERROR
        waitForCmdDone(cmdID, P2, AUTO_TIMEOUT, ERROR, mfilename());
        %waitForCmdDone(cmdID, P6, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case {P2 P3}
        % calibrating direct connection at freq harmonics
        while curFreq < fs/2
          switch(label)

            case P2            
              printStr(sprintf("Generating %dHz", curFreq));
              cmdID = sendGeneratorCmd(curFreq, origPlayLevels, playEqualizer);
              waitForCmdDone(cmdID, P3, AUTO_TIMEOUT, ERROR, mfilename());
              return;

            case P3
              printStr(sprintf("Joint-device calibrating/measuring LP at %dHz", curFreq));

              % deleting the calib file should it exist - always clean calibration
              calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_LP1);
              deleteFile(calFile);
              
              % safety measure - requesting calibration only at curFreq
              calFreqReqStr = getCalFreqReqStr({[curFreq, NA, NA]});
              calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
              if curFreq > origFreq
                % calibrating at harmonics freqs - only the fundaments data are used for measuring LPF transfer - can use fewer averaging calruns                
                calCmd = [calCmd ' ' CMD_CALRUNS_PREFIX num2str(REDUCED_CALIB_RUNS)];
              endif
              cmdID = writeCmd(calCmd, cmdFileRec);
              % next frequency
              curFreq += origFreq;
              waitForCmdDone(cmdID, P2, AUTO_TIMEOUT, ERROR, mfilename());
              return;            
            endswitch          
        endwhile
        % VD calibration
        swStruct.vd = true;
        showSwitchWindow({'Change switch to VD calibration', sprintf('For first freq. adjust level into the shown range for channel ', analysedChID)}, swStruct);

        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        lpFundAmpl = loadCalFundAmpl(origFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_LP1);

        curFreq = origFreq;
        clearOutBox();
        printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", curFreq));

        label = P4;
        % goto label - next loop
        continue;

      case {P4 P5}
        % calibrating LP connection at freq harmonics
        while curFreq < fs/2
          switch(label)
          
            case P4
              printStr(sprintf("Generating %dHz", curFreq));
              cmdID = sendGeneratorCmd(curFreq, origPlayLevels, playEqualizer);
              waitForCmdDone(cmdID, P5, AUTO_TIMEOUT, ERROR, mfilename());
              return;
              
            case P5
              printStr(sprintf("Joint-device calibrating VD at %dHz", curFreq));
              if curFreq == origFreq
                % VD at fundament (origFreq) must be calibrated at exactly the same level as LP so that the distortion characteristics of ADC are same
                % amplitude-constrained calibration
                calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl, origFreq, analysedChID);
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

              calCmd = [CALIBRATE ' ' calFreqReqStr  ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_VD];
              
              if curFreq > origFreq
                % calibrating at harmonics freqs - only the fundaments data are used for measuring VD transfer - can use fewer averaging calruns                
                calCmd = [calCmd ' ' CMD_CALRUNS_PREFIX num2str(REDUCED_CALIB_RUNS)];
              endif

              cmdID = writeCmd(calCmd, cmdFileRec);
              % next frequency
              curFreq += origFreq;
              waitForCmdDone(cmdID, P4, timeout, ERROR, mfilename());
              return;
            endswitch
        endwhile
        label = P6;
        % goto label - next loop
        continue;

      case P6
        clearOutBox();
        printStr(sprintf('Calculating split calibration'));
        calculateSplitCal(origFreq, fs, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_VD, EXTRA_CIRCUIT_LP1);
        
        printStr(sprintf("Generating orig %dHz for split REC side calibration", origFreq));
        cmdID = sendGeneratorCmd(origFreq, origPlayLevels, playEqualizer);
        waitForCmdDone(cmdID, P7, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case P7
        clearOutBox();
        printStr(sprintf('Compensating PLAY side first'));
        cmdID = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_PLAY_SIDE)], cmdFilePlay);
        waitForCmdDone(cmdID, P8, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case {P8, P9, P10}
        switch label
          case P8
            % deleting the calib file for direct channel should it exist - always clean calibration
            calFile = genCalFilename(origFreq, fs, COMP_TYPE_REC_SIDE, NA, getTheOtherChannelID(analysedChID), MODE_DUAL, '');
            deleteFile(calFile);

            % the newly created calfile for analysedChID contains calculated data, not deleting
            calFile = genCalFilename(origFreq, fs, COMP_TYPE_REC_SIDE, NA, analysedChID, MODE_DUAL, '');
            deleteFile(calFile);
            
            expl = 'upper limit';
            adjustment = CAL_LEVEL_STEP;
            
          case P9
            expl = 'lower limit';
            adjustment = 1/CAL_LEVEL_STEP;
            
          case P10
            % last run at exact value - for now
            expl = 'exact value';
            adjustment = 1;
            
        endswitch
        
        printStr(sprintf('Calibrating REC side at original recLevel of channel %d - %s', analysedChID, expl));
        
        % amplitude-constrained calibration
        % TODO - for now using lpFundAmpl instead of origRecLevel to allow easy switching between LP and VD for result checking
        % calFreqReq = getConstrainedLevelCalFreqReq(origRecLevel * adjustment, origFreq, analysedChID);
        calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl * adjustment, origFreq, analysedChID);
        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        % zooming calibration levels + plotting the range so that user can adjust precisely
        % target level = orig Rec level (not the increased range)
        % zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, analysedChID));
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(lpFundAmpl, analysedChID));
        
        cmdID = writeCmd([CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, label + 1, MANUAL_TIMEOUT, ERROR, mfilename());
        return;
        
      case P11
        clearOutBox();
        
        % all calibrations finished, closing the zoomed calib plot
        closeCalibPlot();
        
        printStr(sprintf('Compensating SPLIT REC side'));
        cmdID = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, P12, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case P12        
        printStr(sprintf('Generator Off'));
        cmdID = writeCmd([GENERATE ' ' 'off'], cmdFilePlay);
        waitForCmdDone(cmdID, P13, AUTO_TIMEOUT, ERROR, mfilename());
        return;

        case P13
        swStruct.calibrate = false;
        showSwitchWindow('Set switches for measuring DUT', swStruct');
        return;
        
      case ERROR
        printStr('Timeout waiting for command done, exiting callback');
        return;
    endswitch
  endwhile
  printStr('Calibration finished, both sides compensating, measuring');  
endfunction


function cmdID = sendGeneratorCmd(freq, origPlayLevels, playEqualizer)
  global cmdFilePlay;
  
  % frequency at same output levels
  genFund = cell();
  for channelID = 1:2
    % generator is BEFORE equalizer. Analyser which measures play levels is after equalizer
    % therefore generated ampls must be adjusted for the equalizer value
    genFundCh = [freq, origPlayLevels{channelID} / playEqualizer(channelID)];
    genFund{end + 1} = genFundCh;
  endfor
  
  cmdID = writeCmd(getGeneratorCmdStr(genFund), cmdFilePlay);
endfunction


function calFreqReq = getConstrainedLevelCalFreqReq(midAmpl, freq, analysedChID)
  % max. allowed deviation in each direction from midAmpl
  persistent calTolerance = db2mag(0.03);

  minAmpl = midAmpl/calTolerance;
  maxAmpl = midAmpl*calTolerance;
  
  freqReqLimitedAmpl = [freq, minAmpl, maxAmpl];
  freqReqAnyAmpl = [freq, NA, NA];
  
  calFreqReq = {freqReqAnyAmpl, freqReqLimitedAmpl};
  if analysedChID == 1
    calFreqReq = flip(calFreqReq);
  endif
endfunction


function targetLevels = getTargetLevelsForAnalysedCh(analysedAmpl, analysedChID)
  % the other CH is always NA - we do not care about zooming/plotting the auxiliary channel during split-calibration
  targetLevels = [NA, analysedAmpl]
  if analysedChID == 1
    targetLevels = flip(targetLevels);
  endif
endfunction

function lpFundAmpl = loadCalFundAmpl(freq, fs, playChID, analysedChID, extraCircuit)
  global COMP_TYPE_JOINT;
  global AMPL_IDX;  % = index of fundAmpl1
  
  [peaksRow, distortFreqs] = loadCalRow(freq, fs, COMP_TYPE_JOINT, playChID, analysedChID, extraCircuit);
  lpFundAmpl = peaksRow(1, AMPL_IDX);
endfunction