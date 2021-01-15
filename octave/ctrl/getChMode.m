function chMode = getChMode()
  global adapterStruct;
  global MODE_DUAL_SE;
  global MODE_DUAL_BAL;

  chMode = ifelse(adapter.modeSE, MODE_DUAL_SE, MODE_DUAL_BAL);
end