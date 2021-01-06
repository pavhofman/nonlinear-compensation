function cmdID = sendPlayGeneratorCmd(freq, playLevels, playEqualizer = NA)
  global cmdFilePlay;
  
  % frequency at same output levels
  genFund = cell();
  for channelID = 1:2
    % generator is BEFORE equalizer. Analyser which measures play levels is after equalizer
    % therefore generated ampls must be adjusted for the equalizer value
    if ~isna(playEqualizer)
      levels = playLevels{channelID} / playEqualizer(channelID);
    else
      levels = playLevels{channelID};
    end
    genFundCh = [freq, levels];
    genFund{end + 1} = genFundCh;
  end
  
  cmdID = writeCmd(getGeneratorCmdStr(genFund), cmdFilePlay);
end
