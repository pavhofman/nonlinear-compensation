#!/usr/bin/octave -qf

function [ wavPath, channel, showCharts ] = loadCalibArgv(arg_list)
  if (length(arg_list) < 1)
      printf('Usage: %s INPUT_FILE [channel:1|2] [|y|n]\n', program_name());
      exit();
  end

  % at least 2 secs of recording, stereo or mono
  wavPath = arg_list{1};


  % 1 = left, 2 = right
  if (length(arg_list) >= 2)
      channel = str2num(arg_list{2});
  else
      channel = 1;
  end


  % show or not to show charts
  if (length(arg_list) >= 3)
      show = arg_list{3};
  else
      # no charts
      show = '';
  end

  if (show == 'y')
    showCharts = true;
   else
    showCharts = false;
  endif

endfunction
