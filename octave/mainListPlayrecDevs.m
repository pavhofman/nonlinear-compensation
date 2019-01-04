% clearing initialised playrec
clear all;
more off;

devs = playrec('getDevices');

printf('Available output devices:\n');
printf('-1) No Device\n');
for k=1:length(devs)
    if(devs(k).outputChans)
        printf(' %2d) %s (%s) %d channels\n', ...
            devs(k).deviceID, devs(k).name, ...
            devs(k).hostAPI, devs(k).outputChans);
    end
end

printf('\n\n');
printf('Available input devices:\n');
printf('-1) No Device\n');
for k=1:length(devs)
    if(devs(k).inputChans)
        printf(' %2d) %s (%s) %d channels\n', ...
            devs(k).deviceID, devs(k).name, ...
            devs(k).hostAPI, devs(k).outputChans);
    end
end