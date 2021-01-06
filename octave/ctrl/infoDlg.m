% plain alert window
function infoDlg(text)
  h = dialog();
  textBox = uicontrol(h, 'style', 'text', 'string', text, "position",[100 100 400 300]);
  set(textBox, 'horizontalalignment', 'left');
  set(textBox, 'verticalalignment', 'top');

  % closing button
  uicontrol(h, 'style', 'pushbutton', 'string', 'OK', "position",[10 10 50 50], 'callback', @() close(h));
  drawnow();
  uiwait(h);
end