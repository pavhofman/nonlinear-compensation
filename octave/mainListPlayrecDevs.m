% clearing initialised playrec
clear all;
more off;

devs = playrec('getDevices');

printf('Available output devices:\n');
devs = getPlayrecDevs(true);
for k=1:length(devs)
  printf(devs{k}.desc);
end

printf('\n\n');
printf('Available input devices:\n');
devs = getPlayrecDevs(false);
for k=1:length(devs)
  printf(devs{k}.desc);
end
