function prDeviceName = getPlayrecDevName(deviceID)
  devs = playrec('getDevices');
  for id = 1:length(devs)
    if devs(id).deviceID == deviceID
      prDeviceName = devs(id).name;
      return;
    end
  end
  prDeviceName = 'Unknown';
end
