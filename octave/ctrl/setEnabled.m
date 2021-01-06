function changed = setEnabled(items, enable)
  changed = false;
  for id = 1:length(items)
    item = items(id);
    isEnabled = strcmp(get(item, 'enable'), 'on');
    if enable ~= isEnabled
      set(item, 'enable', ifelse(enable, 'on', 'off'));
      changed = true;
    end
  end
end