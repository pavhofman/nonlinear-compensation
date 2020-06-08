function availDevs = getPlayrecDevs(isPlayback)

  allDevs = playrec('getDevices');

  availDevs = cell();
  for idx=1:length(allDevs)
    if (isPlayback && allDevs(idx).outputChans) || (~isPlayback && allDevs(idx).inputChans)
      dev = struct();
      dev.id = allDevs(idx).deviceID;
      dev.desc = sprintf(' %2d) %s (%s) %d channels\n', allDevs(idx).deviceID, allDevs(idx).name, allDevs(idx).hostAPI, allDevs(idx).outputChans);

      availDevs(end + 1) = dev;
    end
  end
endfunction